module {
  public type ApiKey = {
    id : Text;
    ownerId : Text; // Principal.toText()
    name : Text;
    createdAt : Int; // nanoseconds
    lastUsedAt : ?Int;
    callCount : Nat;
    active : Bool;
    totalCyclesUsed : Nat; // cumulative cycles across all executions using this key
  };

  // Per-key stats returned by get_api_key_stats
  public type ApiKeyStats = {
    keyId : Text;
    callCount : Nat;
    lastUsedAt : ?Int;
    totalCyclesUsed : Nat;
    active : Bool;
  };

  // Audit event for key lifecycle and auth actions
  public type AuditEvent = {
    id : Text;
    eventType : Text; // 'key_generated' | 'key_revoked' | 'key_used' | 'auth_failed' | 'rate_limited'
    keyId : Text;
    userId : Text;
    timestamp : Int;
    details : Text;
  };
};
