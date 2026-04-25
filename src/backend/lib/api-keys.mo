import ApiKeyTypes "../types/api-keys";
import List "mo:core/List";

module {

  /// Returns the ownerId if the key exists, is active, and matches keyId. Returns null otherwise.
  public func validate(
    apiKeys : List.List<ApiKeyTypes.ApiKey>,
    keyId : Text,
  ) : ?Text {
    switch (apiKeys.find(func(k : ApiKeyTypes.ApiKey) : Bool { k.id == keyId and k.active })) {
      case (?key) ?key.ownerId;
      case null null;
    };
  };

  /// Increments the callCount and updates lastUsedAt for the given key.
  public func recordUsage(
    apiKeys : List.List<ApiKeyTypes.ApiKey>,
    keyId : Text,
    timestamp : Int,
  ) {
    apiKeys.mapInPlace(func(k : ApiKeyTypes.ApiKey) : ApiKeyTypes.ApiKey {
      if (k.id == keyId) {
        { k with callCount = k.callCount + 1; lastUsedAt = ?timestamp };
      } else {
        k;
      };
    });
  };

  /// Adds cyclesUsed to the totalCyclesUsed accumulator for the given key.
  public func recordCycles(
    apiKeys : List.List<ApiKeyTypes.ApiKey>,
    keyId : Text,
    cyclesUsed : Nat,
  ) {
    apiKeys.mapInPlace(func(k : ApiKeyTypes.ApiKey) : ApiKeyTypes.ApiKey {
      if (k.id == keyId) {
        { k with totalCyclesUsed = k.totalCyclesUsed + cyclesUsed };
      } else {
        k;
      };
    });
  };

  /// Returns per-key stats for a given key ID. Caller must own the key.
  public func getStats(
    apiKeys : List.List<ApiKeyTypes.ApiKey>,
    keyId : Text,
    ownerId : Text,
  ) : ?ApiKeyTypes.ApiKeyStats {
    switch (apiKeys.find(func(k : ApiKeyTypes.ApiKey) : Bool { k.id == keyId and k.ownerId == ownerId })) {
      case (?key) ?{
        keyId = key.id;
        callCount = key.callCount;
        lastUsedAt = key.lastUsedAt;
        totalCyclesUsed = key.totalCyclesUsed;
        active = key.active;
      };
      case null null;
    };
  };

};
