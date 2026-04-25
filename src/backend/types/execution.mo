import Common "common";

module {
  // Returned by every execute_capability call
  public type ExecutionResult = {
    success : Bool;
    output : ?Text; // JSON-serialized output or null
    error : ?Common.ExecError; // null when success=true
    executionId : Text;
    latencyMs : Nat;
    cyclesUsed : ?Nat; // cycles consumed by this execution (null for cached/fast calls)
  };

  // Stored record for every execution (monitoring + audit)
  public type ExecutionLog = {
    executionId : Text;
    user : Common.UserId;
    capability : Text;
    input : Text; // raw JSON input
    output : ?Text;
    success : Bool;
    errorCode : ?Text;
    errorMessage : ?Text;
    timestamp : Common.Timestamp;
    latencyMs : Nat;
    cyclesUsed : ?Nat; // cycles consumed; null if not metered
    apiKeyId : ?Text; // which API key was used, if any
  };

  // Filter options for log queries
  public type LogFilter = {
    capability : ?Text;
    successOnly : ?Bool;
    failureOnly : ?Bool;
    limit : ?Nat;
    offset : ?Nat;
    user : ?Text; // filter logs to a specific principal text
  };

  // Per-capability call count pair
  public type CapabilityCount = {
    name : Text;
    count : Nat;
  };

  // Per-user call count pair
  public type UserCount = {
    user : Common.UserId;
    count : Nat;
  };

  // Daily aggregated count pair
  public type DailyCount = {
    date : Text; // "YYYY-MM-DD"
    count : Nat;
  };

  // Aggregate usage statistics
  public type UsageSummary = {
    totalCalls : Nat;
    callsThisMonth : Nat;
    perCapability : [CapabilityCount];
    perUser : [UserCount];
    dailyCounts : [DailyCount];
  };
};
