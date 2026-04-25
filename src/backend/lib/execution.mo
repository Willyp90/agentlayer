import ExecTypes "../types/execution";
import CapTypes "../types/capabilities";
import CapLib "../lib/capabilities";
import Map "mo:core/Map";
import List "mo:core/List";
import Array "mo:core/Array";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Nat "mo:core/Nat";
import Int "mo:core/Int";
import Time "mo:core/Time";
import Order "mo:core/Order";
import ExperimentalCycles "mo:core/Cycles";

module {

  // ── execution ──────────────────────────────────────────────────────────────

  /// Dispatches a validated capability call and returns a structured ExecutionResult.
  /// cyclesBefore is captured by the caller; this function captures cyclesAfter internally.
  public func run(
    info : CapTypes.CapabilityInfo,
    inputJson : Text,
    _caller : Text,
    execId : Text,
    startNs : Int,
    objectStore : Map.Map<Text, Text>,
    httpCacheMap : Map.Map<Text, CapLib.CacheEntry>,
    transformFn : CapLib.TransformFn,
    cyclesBefore : Nat,
  ) : async* ExecTypes.ExecutionResult {
    // Dispatch to the capability handler in CapLib
    let result = await* CapLib.dispatch(info.name, inputJson, objectStore, httpCacheMap, transformFn);
    let endNs = Time.now();
    let diffNs = endNs - startNs;
    let latencyMs : Nat = if (diffNs > 0) Int.abs(diffNs) / 1_000_000 else 0;
    let cyclesAfter = ExperimentalCycles.balance();
    let cyclesUsed : ?Nat = ?(if (cyclesBefore >= cyclesAfter) cyclesBefore - cyclesAfter else 0);

    if (result.success) {
      {
        success = true;
        output = result.output;
        error = null;
        executionId = execId;
        latencyMs;
        cyclesUsed;
      };
    } else {
      {
        success = false;
        output = null;
        error = ?{
          code = switch (result.errorCode) { case (?c) c; case null "EXECUTION_ERROR" };
          message = switch (result.errorMessage) { case (?m) m; case null "Unknown error" };
        };
        executionId = execId;
        latencyMs;
        cyclesUsed;
      };
    };
  };

  // ── log building ───────────────────────────────────────────────────────────

  /// Builds a log entry from a completed execution.
  public func buildLog(
    result : ExecTypes.ExecutionResult,
    caller : Text,
    capabilityName : Text,
    inputJson : Text,
    timestamp : Int,
    apiKeyId : ?Text,
  ) : ExecTypes.ExecutionLog {
    {
      executionId = result.executionId;
      user = caller;
      capability = capabilityName;
      input = inputJson;
      output = result.output;
      success = result.success;
      errorCode = switch (result.error) { case (?e) ?e.code; case null null };
      errorMessage = switch (result.error) { case (?e) ?e.message; case null null };
      timestamp;
      latencyMs = result.latencyMs;
      cyclesUsed = result.cyclesUsed;
      apiKeyId;
    };
  };

  // ── log filtering ──────────────────────────────────────────────────────────

  /// Applies filters and pagination to a log list, returning newest-first slice.
  public func filterLogs(
    logs : List.List<ExecTypes.ExecutionLog>,
    filter : ExecTypes.LogFilter,
  ) : [ExecTypes.ExecutionLog] {
    let all = logs.toArray();
    let reversed = all.reverse();

    let filtered = reversed.filter(func(log : ExecTypes.ExecutionLog) : Bool {
      let capOk = switch (filter.capability) {
        case (?cap) log.capability == cap;
        case null true;
      };
      let successOk = switch (filter.successOnly) {
        case (?true) log.success;
        case _ true;
      };
      let failureOk = switch (filter.failureOnly) {
        case (?true) not log.success;
        case _ true;
      };
      let userOk = switch (filter.user) {
        case (?u) log.user == u;
        case null true;
      };
      capOk and successOk and failureOk and userOk;
    });

    let offset = switch (filter.offset) { case (?o) o; case null 0 };
    let limit = switch (filter.limit) { case (?l) l; case null 100 };
    let total = filtered.size();
    if (offset >= total) return [];
    let end = Nat.min(offset + limit, total);
    filtered.sliceToArray(offset.toInt(), end.toInt());
  };

  // ── usage statistics ───────────────────────────────────────────────────────

  /// Computes aggregated usage statistics, optionally scoped to a single user.
  public func computeUsage(
    logs : List.List<ExecTypes.ExecutionLog>,
    userFilter : ?Text,
  ) : ExecTypes.UsageSummary {
    let raw = logs.toArray();
    let all = switch (userFilter) {
      case (?u) raw.filter(func(log : ExecTypes.ExecutionLog) : Bool { log.user == u });
      case null raw;
    };
    let totalCalls = all.size();

    let nowNs = Time.now();
    let thirtyDaysNs : Int = 30 * 24 * 60 * 60 * 1_000_000_000;
    let monthStart = nowNs - thirtyDaysNs;

    var callsThisMonth = 0;
    let capMap = Map.empty<Text, Nat>();
    let userMap = Map.empty<Text, Nat>();
    let dayMap = Map.empty<Text, Nat>();

    for (log in all.values()) {
      if (log.timestamp >= monthStart) callsThisMonth += 1;

      let prevCap = switch (capMap.get(log.capability)) { case (?n) n; case null 0 };
      capMap.add(log.capability, prevCap + 1);

      let prevUser = switch (userMap.get(log.user)) { case (?n) n; case null 0 };
      userMap.add(log.user, prevUser + 1);

      if (log.timestamp >= monthStart) {
        let dayKey = timestampToDate(log.timestamp);
        let prevDay = switch (dayMap.get(dayKey)) { case (?n) n; case null 0 };
        dayMap.add(dayKey, prevDay + 1);
      };
    };

    let capEntries = capMap.toArray();
    let sortedCap = capEntries.sort(func((_, a) : (Text, Nat), (_, b) : (Text, Nat)) : Order.Order {
      if (b > a) #less else if (b < a) #greater else #equal
    });
    let top10Cap = sortedCap.sliceToArray(0, Nat.min(10, sortedCap.size()).toInt());
    let perCapability = top10Cap.map(func((name, count)) { { name; count } });

    let userEntries = userMap.toArray();
    let sortedUser = userEntries.sort(func((_, a) : (Text, Nat), (_, b) : (Text, Nat)) : Order.Order {
      if (b > a) #less else if (b < a) #greater else #equal
    });
    let top10User = sortedUser.sliceToArray(0, Nat.min(10, sortedUser.size()).toInt());
    let perUser = top10User.map(func((user, count)) { { user; count } });

    let dayEntries = dayMap.toArray();
    let sortedDays = dayEntries.sort(func((a, _) : (Text, Nat), (b, _) : (Text, Nat)) : Order.Order { Text.compare(a, b) });
    let dailyCounts = sortedDays.map(func((date, count)) { { date; count } });

    { totalCalls; callsThisMonth; perCapability; perUser; dailyCounts };
  };

  // ── ID generation ──────────────────────────────────────────────────────────

  /// Generates a short unique execution ID from a monotonic counter.
  public func newExecId(counter : Nat) : Text {
    "exec-" # counter.toText();
  };

  // ── time utilities ─────────────────────────────────────────────────────────

  func timestampToDate(ns : Int) : Text {
    let secs : Int = ns / 1_000_000_000;
    let days : Int = secs / 86400;
    // Gregorian calendar from days since 1970-01-01
    let z = days + 719468;
    let era : Int = (if (z >= 0) z else z - 146096) / 146097;
    let doe : Int = z - era * 146097;
    let yoe : Int = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let y : Int = yoe + era * 400;
    let doy : Int = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp : Int = (5 * doy + 2) / 153;
    let d : Int = doy - (153 * mp + 2) / 5 + 1;
    let m : Int = mp + (if (mp < 10) 3 else -9);
    let finalY : Int = y + (if (m <= 2) 1 else 0);
    padLeft(finalY.toText(), 4) # "-" # padLeft(m.toText(), 2) # "-" # padLeft(d.toText(), 2);
  };

  func padLeft(s : Text, width : Nat) : Text {
    if (s.size() >= width) return s;
    Text.fromIter(Iter.repeat('0', width - s.size())) # s;
  };
};
