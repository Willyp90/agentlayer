import ExecTypes "../types/execution";
import ApiKeyTypes "../types/api-keys";
import ExecLib "../lib/execution";
import CapLib "../lib/capabilities";
import ApiKeyLib "../lib/api-keys";
import Map "mo:core/Map";
import List "mo:core/List";
import Time "mo:core/Time";
import Int "mo:core/Int";
import ExperimentalCycles "mo:core/Cycles";

mixin (
  logs : List.List<ExecTypes.ExecutionLog>,
  execCounter : { var count : Nat },
  objectStore : Map.Map<Text, Text>,
  httpCacheMap : Map.Map<Text, CapLib.CacheEntry>,
  transformFn : CapLib.TransformFn,
  apiKeys : List.List<ApiKeyTypes.ApiKey>,
  auditLog : List.List<ApiKeyTypes.AuditEvent>,
  auditEventCounter : { var count : Nat },
  keyRateLimitBuckets : Map.Map<Text, Nat>,
) {
  let apiKeyRateLimitPerMinute : Nat = 120;

  /// Validates input, executes the named capability, records a log entry, and returns the result.
  /// If apiKey is provided, it is validated and usage is attributed to the key owner's principal.
  public shared ({ caller }) func execute_capability(
    capabilityName : Text,
    inputJson : Text,
    apiKey : ?Text,
  ) : async ExecTypes.ExecutionResult {
    let startNs = Time.now();
    execCounter.count += 1;
    let execId = ExecLib.newExecId(execCounter.count);

    // Resolve userId: either from API key or from caller principal
    let userId : Text = switch (apiKey) {
      case (?keyId) {
        switch (ApiKeyLib.validate(apiKeys, keyId)) {
          case null {
            // Record auth_failed audit event
            execAddAuditEvent("auth_failed", keyId, caller.toText(), "Invalid or revoked API key used for " # capabilityName);
            let latencyMs : Nat = Int.abs(Time.now() - startNs) / 1_000_000;
            let result : ExecTypes.ExecutionResult = {
              success = false;
              output = null;
              error = ?{ code = "INVALID_API_KEY"; message = "Invalid or revoked API key" };
              executionId = execId;
              latencyMs;
              cyclesUsed = null;
            };
            logs.add(ExecLib.buildLog(result, "anonymous", capabilityName, inputJson, startNs, ?keyId));
            return result;
          };
          case (?ownerId) {
            if (isRateLimited(keyId, startNs)) {
              execAddAuditEvent("rate_limited", keyId, ownerId, "Rate limit exceeded for execute_capability: " # capabilityName);
              let latencyMs : Nat = Int.abs(Time.now() - startNs) / 1_000_000;
              let result : ExecTypes.ExecutionResult = {
                success = false;
                output = null;
                error = ?{ code = "RATE_LIMITED"; message = "API key has exceeded the per-minute request limit" };
                executionId = execId;
                latencyMs;
                cyclesUsed = null;
              };
              logs.add(ExecLib.buildLog(result, ownerId, capabilityName, inputJson, startNs, ?keyId));
              return result;
            };
            ApiKeyLib.recordUsage(apiKeys, keyId, startNs);
            execAddAuditEvent("key_used", keyId, ownerId, "execute_capability: " # capabilityName);
            ownerId;
          };
        };
      };
      case null { caller.toText() };
    };

    // Look up capability
    let infoOpt = CapLib.describe(capabilityName);
    switch (infoOpt) {
      case null {
        let latencyMs : Nat = Int.abs(Time.now() - startNs) / 1_000_000;
        let result : ExecTypes.ExecutionResult = {
          success = false;
          output = null;
          error = ?{ code = "CAPABILITY_NOT_FOUND"; message = "Unknown capability: " # capabilityName };
          executionId = execId;
          latencyMs;
          cyclesUsed = null;
        };
        let log = ExecLib.buildLog(result, userId, capabilityName, inputJson, startNs, apiKey);
        logs.add(log);
        result;
      };
      case (?info) {
        // Validate input against schema
        let validationError = CapLib.validateInput(info, inputJson);
        switch (validationError) {
          case (?errMsg) {
            let latencyMs : Nat = Int.abs(Time.now() - startNs) / 1_000_000;
            let result : ExecTypes.ExecutionResult = {
              success = false;
              output = null;
              error = ?{ code = "INVALID_INPUT"; message = errMsg };
              executionId = execId;
              latencyMs;
              cyclesUsed = null;
            };
            let log = ExecLib.buildLog(result, userId, capabilityName, inputJson, startNs, apiKey);
            logs.add(log);
            result;
          };
          case null {
            // Capture cycles before execution
            let cyclesBefore = ExperimentalCycles.balance();
            // Execute the capability
            let result = await* ExecLib.run(info, inputJson, userId, execId, startNs, objectStore, httpCacheMap, transformFn, cyclesBefore);
            // Update per-key cycle totals
            switch (apiKey) {
              case (?keyId) {
                let used = switch (result.cyclesUsed) { case (?c) c; case null 0 };
                if (used > 0) ApiKeyLib.recordCycles(apiKeys, keyId, used);
              };
              case null {};
            };
            let log = ExecLib.buildLog(result, userId, capabilityName, inputJson, startNs, apiKey);
            logs.add(log);
            result;
          };
        };
      };
    };
  };

  /// Returns a paginated, filtered view of execution logs for the calling user only (newest-first).
  public shared query ({ caller }) func get_execution_logs(
    filter : ExecTypes.LogFilter,
  ) : async [ExecTypes.ExecutionLog] {
    let userFilter : ExecTypes.LogFilter = { filter with user = ?caller.toText() };
    ExecLib.filterLogs(logs, userFilter);
  };

  /// Returns aggregated usage statistics for the calling user only.
  public shared query ({ caller }) func get_usage_summary() : async ExecTypes.UsageSummary {
    ExecLib.computeUsage(logs, ?caller.toText());
  };

  // ── private audit helpers ────────────────────────────────────────────────────

  func execAddAuditEvent(eventType : Text, keyId : Text, userId : Text, details : Text) {
    auditEventCounter.count += 1;
    let event : ApiKeyTypes.AuditEvent = {
      id = "ae-" # auditEventCounter.count.toText();
      eventType;
      keyId;
      userId;
      timestamp = Time.now();
      details;
    };
    auditLog.add(event);
  };

  func isRateLimited(keyId : Text, nowNs : Int) : Bool {
    let currentWindow = nowNs / 60_000_000_000;
    let bucketKey = keyId # ":" # currentWindow.toText();
    let currentCount = switch (keyRateLimitBuckets.get(bucketKey)) {
      case (?n) n;
      case null 0;
    };
    if (currentCount >= apiKeyRateLimitPerMinute) {
      true;
    } else {
      keyRateLimitBuckets.add(bucketKey, currentCount + 1);
      false;
    };
  };

};
