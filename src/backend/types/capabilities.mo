module {
  // Schema for a single capability input parameter
  public type CapabilityInput = {
    key : Text;
    inputType : Text;
    required : Bool;
    description : Text;
  };

  // Schema for a single capability output field
  public type CapabilityOutput = {
    key : Text;
    outputType : Text;
    description : Text;
  };

  // Full capability metadata record
  public type CapabilityInfo = {
    name : Text;
    description : Text;
    category : Text;
    inputs : [CapabilityInput];
    outputs : [CapabilityOutput];
    constraints : [Text];
    exampleInput : Text;
    exampleOutput : Text;
  };
};
