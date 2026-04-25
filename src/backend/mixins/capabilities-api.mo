import CapTypes "../types/capabilities";
import CapLib "../lib/capabilities";

mixin () {

  /// Returns the full capability list, optionally filtered by category.
  public query func list_capabilities(categoryFilter : ?Text) : async [CapTypes.CapabilityInfo] {
    CapLib.list(categoryFilter);
  };

  /// Returns full details for a single capability by name.
  public query func describe_capability(name : Text) : async ?CapTypes.CapabilityInfo {
    CapLib.describe(name);
  };

};
