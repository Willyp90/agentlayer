module {
  // Cross-cutting identity and time types
  public type UserId = Text; // Principal.toText()
  public type Timestamp = Int; // nanoseconds from Time.now()

  // Error representation used in execution results
  public type ExecError = {
    code : Text;
    message : Text;
  };
};
