import Common "common";

module {
  // ── Test case types ─────────────────────────────────────────────────────────

  // Category of test to run
  public type TestCategory = {
    #RequiredFieldsOnly;
    #OptionalFieldIndividual;
    #OptionalFieldCombination;
    #MissingRequiredField;
    #InvalidType;
    #EdgeCase;
    #Determinism;
    #ErrorHandling;
    #OutputSchema;
  };

  // A single auto-generated test case
  public type TestCase = {
    id : Text;                        // unique test ID, e.g. "read_document::required_only"
    capabilityName : Text;
    category : TestCategory;
    description : Text;               // human-readable description of what's being tested
    inputJson : Text;                 // input to pass to the capability
    expectSuccess : Bool;             // whether we expect success=true
    expectErrorCode : ?Text;          // if expectSuccess=false, the expected error code (null = any error)
    expectedOutputKeys : [Text];      // if non-empty, output must contain exactly these top-level keys
  };

  // Result of a single test case execution
  public type TestResult = {
    testId : Text;
    capabilityName : Text;
    category : TestCategory;
    description : Text;
    inputJson : Text;
    passed : Bool;
    failureReason : ?Text;            // null when passed=true
    actualSuccess : Bool;
    actualOutput : ?Text;
    actualErrorCode : ?Text;
    latencyMs : Nat;
  };

  // ── Test run types ───────────────────────────────────────────────────────────

  // Summary metadata for a test run (stored in history list)
  public type TestRunMetadata = {
    runId : Text;
    startedAt : Common.Timestamp;
    completedAt : Common.Timestamp;
    totalTests : Nat;
    passed : Nat;
    failed : Nat;
    capabilityName : ?Text;           // null = all capabilities
  };

  // Full test run result (stored by runId)
  public type TestRunResult = {
    runId : Text;
    startedAt : Common.Timestamp;
    completedAt : Common.Timestamp;
    capabilityName : ?Text;
    results : [TestResult];
    totalTests : Nat;
    passed : Nat;
    failed : Nat;
  };

  // Per-capability status for the dashboard overview
  public type CapabilityTestStatus = {
    capabilityName : Text;
    category : Text;
    lastRunAt : ?Common.Timestamp;
    totalTests : Nat;
    passed : Nat;
    failed : Nat;
    status : Text;                    // "pass" | "fail" | "never_run"
  };
};
