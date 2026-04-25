import Common "../types/common";

module {

  // ── Admin state type ─────────────────────────────────────────────────────────

  /// Mutable admin state container — owner holds a single optional UserId.
  public type AdminState = { var adminId : ?Common.UserId };

  /// Create a new empty AdminState.
  public func newState() : AdminState {
    { var adminId = null };
  };

  // ── Admin role management ────────────────────────────────────────────────────

  /// Sets adminId to caller if not yet set.
  /// Returns true if caller is now (or already was) the admin.
  public func initAdmin(state : AdminState, caller : Common.UserId) : Bool {
    switch (state.adminId) {
      case null {
        state.adminId := ?caller;
        true;
      };
      case (?existing) {
        existing == caller;
      };
    };
  };

  /// Returns true iff caller is the current admin.
  public func isAdmin(state : AdminState, caller : Common.UserId) : Bool {
    switch (state.adminId) {
      case null false;
      case (?existing) existing == caller;
    };
  };

  /// Returns the current adminId (null if admin has not yet been set).
  public func getAdminId(state : AdminState) : ?Common.UserId {
    state.adminId;
  };
};
