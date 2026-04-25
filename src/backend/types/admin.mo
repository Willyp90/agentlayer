import Common "common";
import Execution "execution";

module {
  // ── Admin identity ──────────────────────────────────────────────────────────

  /// Persisted admin state.
  /// adminId is null until the first authenticated user claims the admin role.
  public type AdminState = {
    adminId : ?Common.UserId;
    initialized : Bool;
  };

  // ── Test classification ─────────────────────────────────────────────────────

  /// Categories a test case can belong to.
  public type TestCategory = {
    #required_field;
    #optional_field;
    #optional_combination;
    #missing_required;
    #invalid_type;
    #edge_case;
    #determinism;
    #error_handling;
    #output_schema;
  };

  /// What a test expects to observe when executed.
  public type TestExpectedBehavior = {
    /// Whether the capability call should return success = true.
    expectedSuccess : Bool;
    /// Keys that MUST be present in the output JSON (if any).
    expectedOutputKeys : [Text];
    /// If non-null, the actual error code must match this value.
    expectedErrorCode : ?Text;
    /// When true the output field in the execution result must be null.
    expectedOutputNull : Bool;
  };

  // ── Test case definition ────────────────────────────────────────────────────

  /// A single, self-contained test case for one capability.
  public type TestCase = {
    id : Text;
    capabilityName : Text;
    testName : Text;
    category : TestCategory;
    /// JSON-serialized input to pass to the capability.
    inputJson : Text;
    expectedBehavior : TestExpectedBehavior;
  };

  // ── Test result ─────────────────────────────────────────────────────────────

  /// The outcome of executing a single TestCase.
  public type TestResult = {
    testCaseId : Text;
    testName : Text;
    capabilityName : Text;
    passed : Bool;
    inputJson : Text;
    expectedBehavior : TestExpectedBehavior;
    /// Raw JSON output returned by the capability (null when the execution
    /// produced no output or the execution itself failed to run).
    actualOutput : ?Text;
    actualSuccess : Bool;
    actualError : ?Common.ExecError;
    latencyMs : Int;
    /// Human-readable explanation of why the test failed (null when passed).
    failureReason : ?Text;
  };

  // ── Test run metadata ───────────────────────────────────────────────────────

  /// Summary counters produced at the end of a test run.
  public type TestRunMetadata = {
    runId : Text;
    timestamp : Common.Timestamp;
    totalTests : Nat;
    passCount : Nat;
    failCount : Nat;
    /// null means the run covered all capabilities; non-null means a single
    /// capability was targeted.
    capabilityName : ?Text;
  };

  // ── Per-capability dashboard status ────────────────────────────────────────

  /// Rolled-up test health for a single capability.
  public type TestStatus = {
    #never_run;
    #all_pass;
    #some_fail;
    #all_fail;
  };

  public type CapabilityTestStatus = {
    capabilityName : Text;
    lastRunTimestamp : ?Common.Timestamp;
    passCount : Nat;
    failCount : Nat;
    status : TestStatus;
  };

  // ── Test run result ─────────────────────────────────────────────────────────

  public type TestRunStatus = {
    #running;
    #complete;
    #failed_to_run;
  };

  /// The full result of a test run, combining metadata with individual results.
  public type TestRunResult = {
    runId : Text;
    metadata : TestRunMetadata;
    results : [TestResult];
    status : TestRunStatus;
  };
};
