import AdminTypes "../types/admin-test-engine";
import Common "../types/common";
import AdminLib "../lib/admin";
import TestEngine "../lib/test-engine";
import CapLib "../lib/capabilities";
import CapTypes "../types/capabilities";
import ExecTypes "../types/execution";
import Map "mo:core/Map";
import List "mo:core/List";
import Array "mo:core/Array";
import Text "mo:core/Text";
import Time "mo:core/Time";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

mixin (
  adminState : AdminLib.AdminState,
  testRuns : Map.Map<Text, AdminTypes.TestRunResult>,
  testRunHistory : List.List<AdminTypes.TestRunMetadata>,
  testRunCounter : { var count : Nat },
  executeCapFn : (Text, Text) -> async* ExecTypes.ExecutionResult,
) {

  /// Returns true if the caller is the admin.
  /// Also initialises admin on the first call (first caller becomes admin).
  /// NOTE: non-query because it may mutate state on first call.
  public shared ({ caller }) func get_admin_status() : async Bool {
    let callerText = caller.toText();
    ignore AdminLib.initAdmin(adminState, callerText);
    AdminLib.isAdmin(adminState, callerText);
  };

  /// Admin-only: generate and run tests for all 42 capabilities.
  public shared ({ caller }) func run_all_tests() : async AdminTypes.TestRunResult {
    if (not AdminLib.isAdmin(adminState, caller.toText())) {
      return emptyFailedRun("ACCESS_DENIED", null);
    };
    let startedAt = Time.now();
    let allCaps = CapLib.list(null);
    let allResults = List.empty<AdminTypes.TestResult>();
    for (cap in allCaps.values()) {
      let suite = TestEngine.generateTestSuite(cap);
      let results = await* TestEngine.runTests(suite, executeCapFn);
      allResults.addAll(results.values());
    };
    finishRun(startedAt, null, allResults.toArray());
  };

  /// Admin-only: generate and run tests for a single named capability.
  public shared ({ caller }) func run_capability_tests(capabilityName : Text) : async AdminTypes.TestRunResult {
    if (not AdminLib.isAdmin(adminState, caller.toText())) {
      return emptyFailedRun("ACCESS_DENIED", ?capabilityName);
    };
    let startedAt = Time.now();
    let capOpt = CapLib.describe(capabilityName);
    switch (capOpt) {
      case null {
        emptyFailedRun("CAPABILITY_NOT_FOUND", ?capabilityName);
      };
      case (?cap) {
        let suite = TestEngine.generateTestSuite(cap);
        let results = await* TestEngine.runTests(suite, executeCapFn);
        finishRun(startedAt, ?capabilityName, results);
      };
    };
  };

  /// Admin-only: retrieve a stored test run result by runId.
  public shared query ({ caller }) func get_test_results(runId : Text) : async ?AdminTypes.TestRunResult {
    if (not AdminLib.isAdmin(adminState, caller.toText())) return null;
    testRuns.get(runId);
  };

  /// Admin-only: list all past test run metadata, sorted by timestamp descending.
  public shared query ({ caller }) func get_test_history() : async [AdminTypes.TestRunMetadata] {
    if (not AdminLib.isAdmin(adminState, caller.toText())) return [];
    testRunHistory.reverse().toArray();
  };

  /// Admin-only: return current pass/fail status per capability (for dashboard).
  public shared query ({ caller }) func get_capability_test_statuses() : async [AdminTypes.CapabilityTestStatus] {
    if (not AdminLib.isAdmin(adminState, caller.toText())) return [];
    let allCaps = CapLib.list(null);
    let statuses = List.empty<AdminTypes.CapabilityTestStatus>();
    for (cap in allCaps.values()) {
        // Find the most recent run that covered this capability (history is newest-last)
        let latestMeta = testRunHistory.reverseValues().find(func(m : AdminTypes.TestRunMetadata) : Bool {
          switch (m.capabilityName) {
            case null true; // all-caps run covers every capability
            case (?n) n == cap.name;
          };
        });
        let status : AdminTypes.CapabilityTestStatus = switch (latestMeta) {
          case null {
            {
              capabilityName = cap.name;
              category = cap.category;
              lastRunAt = null;
              totalTests = 0;
              passed = 0;
              failed = 0;
              status = "never_run";
            };
          };
          case (?meta) {
            // Find detailed results for this capability in that run
            let runOpt = testRuns.get(meta.runId);
            switch (runOpt) {
              case null {
                {
                  capabilityName = cap.name;
                  category = cap.category;
                  lastRunAt = ?meta.startedAt;
                  totalTests = 0;
                  passed = 0;
                  failed = 0;
                  status = "never_run";
                };
              };
              case (?run) {
                let capResults = run.results.filter(
                  func(r) { r.capabilityName == cap.name },
                );
                let passedCount = capResults.foldLeft(
                  0,
                  func(acc, r) { if (r.passed) acc + 1 else acc },
                );
                let total = capResults.size();
                let failedCount = total - passedCount;
                let st = if (total == 0) "never_run"
                  else if (failedCount == 0) "pass"
                  else "fail";
                {
                  capabilityName = cap.name;
                  category = cap.category;
                  lastRunAt = ?meta.startedAt;
                  totalTests = total;
                  passed = passedCount;
                  failed = failedCount;
                  status = st;
                };
              };
            };
          };
        };
        statuses.add(status);
    };
    statuses.toArray();
  };

  // ── Private helpers ──────────────────────────────────────────────────────────

  func nextRunId() : Text {
    testRunCounter.count += 1;
    "run_" # testRunCounter.count.toText();
  };

  func emptyFailedRun(reason : Text, capabilityName : ?Text) : AdminTypes.TestRunResult {
    let now = Time.now();
    {
      runId = "error_" # reason;
      startedAt = now;
      completedAt = now;
      capabilityName;
      results = [];
      totalTests = 0;
      passed = 0;
      failed = 0;
    };
  };

  func finishRun(
    startedAt : Int,
    capabilityName : ?Text,
    results : [AdminTypes.TestResult],
  ) : AdminTypes.TestRunResult {
    let completedAt = Time.now();
    let runId = nextRunId();
    let passedCount = results.foldLeft(
      0, func(acc, r) { if (r.passed) acc + 1 else acc },
    );
    let total = results.size();
    let run : AdminTypes.TestRunResult = {
      runId;
      startedAt;
      completedAt;
      capabilityName;
      results;
      totalTests = total;
      passed = passedCount;
      failed = total - passedCount;
    };
    testRuns.add(runId, run);
    testRunHistory.add({
      runId;
      startedAt;
      completedAt;
      totalTests = total;
      passed = passedCount;
      failed = total - passedCount;
      capabilityName;
    });
    run;
  };
};
