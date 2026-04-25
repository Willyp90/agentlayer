import ApiKeyTypes "../types/api-keys";
import ApiKeyLib "../lib/api-keys";
import List "mo:core/List";
import Nat "mo:core/Nat";
import Time "mo:core/Time";
import Int "mo:core/Int";
import Text "mo:core/Text";

mixin (
  apiKeys : List.List<ApiKeyTypes.ApiKey>,
  apiKeyCounter : { var count : Nat },
  auditLog : List.List<ApiKeyTypes.AuditEvent>,
  auditEventCounter : { var count : Nat },
) {

  /// Generate a new API key for the authenticated caller.
  public shared ({ caller }) func generate_api_key(name : Text) : async { #ok : ApiKeyTypes.ApiKey; #err : Text } {
    if (caller.isAnonymous()) {
      return #err("Authentication required to generate an API key");
    };
    let ownerId = caller.toText();
    apiKeyCounter.count += 1;

    // Build a deterministic-but-unique key: "ak_" + hex(timestamp) + hex(counter)
    let now = Time.now();
    let keyId = "ak_" # hexEncodeNat(Int.abs(now)) # hexEncodeNat(apiKeyCounter.count);

    let key : ApiKeyTypes.ApiKey = {
      id = keyId;
      ownerId;
      name;
      createdAt = now;
      lastUsedAt = null;
      callCount = 0;
      active = true;
      totalCyclesUsed = 0;
    };
    apiKeys.add(key);
    keysAddAuditEvent("key_generated", keyId, ownerId, "Key generated with name: " # name);
    #ok(key);
  };

  /// Revoke an API key. Only the owner can revoke their key.
  public shared ({ caller }) func revoke_api_key(keyId : Text) : async { #ok : (); #err : Text } {
    let callerId = caller.toText();
    switch (apiKeys.findIndex(func(k : ApiKeyTypes.ApiKey) : Bool { k.id == keyId })) {
      case null { #err("API key not found") };
      case (?idx) {
        let key = apiKeys.at(idx);
        if (key.ownerId != callerId) {
          return #err("Unauthorized: you do not own this API key");
        };
        apiKeys.put(idx, { key with active = false });
        keysAddAuditEvent("key_revoked", keyId, callerId, "Key revoked");
        #ok(());
      };
    };
  };

  /// List all API keys owned by the caller (both active and revoked), newest first.
  public query ({ caller }) func list_my_api_keys() : async [ApiKeyTypes.ApiKey] {
    let callerId = caller.toText();
    let owned = apiKeys.filter(func(k : ApiKeyTypes.ApiKey) : Bool { k.ownerId == callerId });
    owned.toArray().reverse();
  };

  /// Returns per-key metrics for a key owned by the caller.
  public query ({ caller }) func get_api_key_stats(keyId : Text) : async { #ok : ApiKeyTypes.ApiKeyStats; #err : Text } {
    let callerId = caller.toText();
    switch (ApiKeyLib.getStats(apiKeys, keyId, callerId)) {
      case (?stats) #ok(stats);
      case null #err("API key not found or not owned by caller");
    };
  };

  /// Returns audit events for the caller (newest-first) with pagination.
  public query ({ caller }) func get_audit_log(limit : Nat, offset : Nat) : async [ApiKeyTypes.AuditEvent] {
    let callerId = caller.toText();
    let owned = auditLog.filter(func(e : ApiKeyTypes.AuditEvent) : Bool { e.userId == callerId });
    let arr = owned.toArray().reverse();
    let total = arr.size();
    if (offset >= total) return [];
    let endIdx = Nat.min(offset + limit, total);
    arr.sliceToArray(offset.toInt(), endIdx.toInt());
  };

  // ── private helpers ─────────────────────────────────────────────────────────

  func keysAddAuditEvent(eventType : Text, keyId : Text, userId : Text, details : Text) {
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

  func hexEncodeNat(n : Nat) : Text {
    if (n == 0) return "0";
    let chars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];
    var result = "";
    var remaining = n;
    while (remaining > 0) {
      let digit = remaining % 16;
      result := Text.fromChar(chars[digit]) # result;
      remaining := remaining / 16;
    };
    result;
  };

};
