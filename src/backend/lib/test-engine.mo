import Types "../types/admin-test-engine";
import CapTypes "../types/capabilities";
import ExecTypes "../types/execution";
import Array "mo:core/Array";
import List "mo:core/List";
import Text "mo:core/Text";
import Nat "mo:core/Nat";
import Time "mo:core/Time";
import Int "mo:core/Int";

module {

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Generate a comprehensive test suite for a single capability based on its schema.
  public func generateTestSuite(cap : CapTypes.CapabilityInfo) : [Types.TestCase] {
    let cases = List.empty<Types.TestCase>();

    // 1. Required-fields-only test (happy path)
    cases.add({
      id = cap.name # "::required_only";
      capabilityName = cap.name;
      category = #RequiredFieldsOnly;
      description = "Execute with all required fields and no optional fields";
      inputJson = buildRequiredInput(cap);
      expectSuccess = true;
      expectErrorCode = null;
      expectedOutputKeys = cap.outputs.map<CapTypes.CapabilityOutput, Text>(func(o) { o.key });
    });

    // 2. Example input test — use the documented example
    if (cap.exampleInput != "{}") {
      cases.add({
        id = cap.name # "::example_input";
        capabilityName = cap.name;
        category = #RequiredFieldsOnly;
        description = "Execute with the documented example input";
        inputJson = cap.exampleInput;
        expectSuccess = true;
        expectErrorCode = null;
        expectedOutputKeys = [];
      });
    };

    // 3. Optional field tests (one per optional field)
    let optionals = cap.inputs.filter(func(i) { not i.required });
    for (optField in optionals.values()) {
      cases.add({
        id = cap.name # "::optional_" # optField.key;
        capabilityName = cap.name;
        category = #OptionalFieldIndividual;
        description = "Execute with required fields plus optional field: " # optField.key;
        inputJson = buildInputWithOptional(cap, optField);
        expectSuccess = true;
        expectErrorCode = null;
        expectedOutputKeys = [];
      });
    };

    // 4. Missing required field tests
    let required = cap.inputs.filter(func(i) { i.required });
    for (reqField in required.values()) {
      cases.add({
        id = cap.name # "::missing_" # reqField.key;
        capabilityName = cap.name;
        category = #MissingRequiredField;
        description = "Execute with required field '" # reqField.key # "' omitted — expect validation error";
        inputJson = buildInputMissingRequired(cap, reqField);
        expectSuccess = false;
        expectErrorCode = ?("VALIDATION_ERROR");
        expectedOutputKeys = [];
      });
    };

    // 5. Missing-required for empty-input case (no fields at all)
    if (required.size() > 0) {
      cases.add({
        id = cap.name # "::empty_input";
        capabilityName = cap.name;
        category = #MissingRequiredField;
        description = "Execute with completely empty JSON object — expect validation error";
        inputJson = "{}";
        expectSuccess = false;
        expectErrorCode = ?("VALIDATION_ERROR");
        expectedOutputKeys = [];
      });
    };

    // 6. Wrong type test for first required field
    if (required.size() > 0) {
      let firstReq = required[0];
      cases.add({
        id = cap.name # "::wrong_type_" # firstReq.key;
        capabilityName = cap.name;
        category = #InvalidType;
        description = "Pass wrong type for required field '" # firstReq.key # "' — expect validation error";
        inputJson = buildInputWrongType(cap, firstReq);
        expectSuccess = false;
        expectErrorCode = ?("VALIDATION_ERROR");
        expectedOutputKeys = [];
      });
    };

    // 7. Edge case: empty string for first string required field
    let firstStringReq = cap.inputs.find(func(i) { i.required and i.inputType == "string" });
    switch (firstStringReq) {
      case (?f) {
        cases.add({
          id = cap.name # "::empty_string_" # f.key;
          capabilityName = cap.name;
          category = #EdgeCase;
          description = "Pass empty string for required string field '" # f.key # "' — expect validation error";
          inputJson = buildInputWithValue(cap, f, "\"\"");
          expectSuccess = false;
          expectErrorCode = ?("VALIDATION_ERROR");
          expectedOutputKeys = [];
        });
      };
      case null {};
    };

    // 8. Determinism test (same input run twice should give same output)
    cases.add({
      id = cap.name # "::determinism";
      capabilityName = cap.name;
      category = #Determinism;
      description = "Run same input twice and verify identical outputs";
      inputJson = buildRequiredInput(cap);
      expectSuccess = true;
      expectErrorCode = null;
      expectedOutputKeys = [];
    });

    // 9. Output schema test
    cases.add({
      id = cap.name # "::output_schema";
      capabilityName = cap.name;
      category = #OutputSchema;
      description = "Verify output contains all documented output keys";
      inputJson = buildRequiredInput(cap);
      expectSuccess = true;
      expectErrorCode = null;
      expectedOutputKeys = cap.outputs.map<CapTypes.CapabilityOutput, Text>(func(o) { o.key });
    });

    cases.toArray();
  };

  /// Execute all test cases and return results.
  public func runTests(
    tests : [Types.TestCase],
    executeCapability : (Text, Text) -> async* ExecTypes.ExecutionResult,
  ) : async* [Types.TestResult] {
    let results = List.empty<Types.TestResult>();
    for (tc in tests.values()) {
      let startNs = Time.now();
      let result = await* executeCapability(tc.capabilityName, tc.inputJson);
      let endNs = Time.now();
      let latencyMs = Int.abs(endNs - startNs) / 1_000_000;

      // For determinism tests, run a second time
      let secondResult : ?ExecTypes.ExecutionResult = if (tc.category == #Determinism) {
        ?(await* executeCapability(tc.capabilityName, tc.inputJson));
      } else {
        null;
      };

      results.add(evaluateResult(tc, result, secondResult));
    };
    results.toArray();
  };

  // ── Internal helpers (exported for testing) ──────────────────────────────────

  /// Build input JSON with all required fields populated with sensible default values.
  public func buildRequiredInput(cap : CapTypes.CapabilityInfo) : Text {
    let required = cap.inputs.filter(func(i) { i.required });
    buildJsonObject(required);
  };

  /// Build input JSON with all required fields plus one specific optional field.
  public func buildInputWithOptional(
    cap : CapTypes.CapabilityInfo,
    optionalField : CapTypes.CapabilityInput,
  ) : Text {
    let required = cap.inputs.filter(func(i) { i.required });
    let fields = required.concat([optionalField]);
    buildJsonObject(fields);
  };

  /// Build input JSON that omits the specified required field (to trigger validation_error).
  public func buildInputMissingRequired(
    cap : CapTypes.CapabilityInfo,
    missingField : CapTypes.CapabilityInput,
  ) : Text {
    let remaining = cap.inputs.filter(
      func(i) { i.required and i.key != missingField.key },
    );
    buildJsonObject(remaining);
  };

  /// Build input JSON where one required field has the wrong type.
  public func buildInputWrongType(
    cap : CapTypes.CapabilityInfo,
    targetField : CapTypes.CapabilityInput,
  ) : Text {
    let required = cap.inputs.filter(func(i) { i.required });
    let parts = List.empty<Text>();
    for (f in required.values()) {
      let value = if (f.key == targetField.key) {
        wrongTypeValueForField(f);
      } else {
        defaultValueForField(f);
      };
      parts.add("\"" # f.key # "\": " # value);
    };
    "{" # parts.values().join(", ") # "}";
  };

  /// Build input JSON overriding a specific field with a custom value.
  public func buildInputWithValue(
    cap : CapTypes.CapabilityInfo,
    targetField : CapTypes.CapabilityInput,
    value : Text,
  ) : Text {
    let required = cap.inputs.filter(func(i) { i.required });
    let parts = List.empty<Text>();
    for (f in required.values()) {
      let v = if (f.key == targetField.key) value else defaultValueForField(f);
      parts.add("\"" # f.key # "\": " # v);
    };
    "{" # parts.values().join(", ") # "}";
  };

  /// Generate a sensible value for a field based on its type and name.
  public func defaultValueForField(field : CapTypes.CapabilityInput) : Text {
    let k = field.key;
    let t = field.inputType;
    // Field-name specific defaults for better test coverage
    if (k == "url") return "\"https://httpbin.org/get\"";
    if (k == "expression") return "\"2 + 2\"";
    if (k == "content" and t == "string") return "\"Hello world! This is test content.\"";
    if (k == "query") return "\"world\"";
    if (k == "pattern") return "\"\\\\d+\"";
    if (k == "substring") return "\"test\"";
    if (k == "key") return "\"test_key_001\"";
    if (k == "value" and t == "string") return "\"test_value\"";
    if (k == "object1") return "\"{\\\\\"a\\\\\": 1}\"";
    if (k == "object2") return "\"{\\\\\"b\\\\\": 2}\"";
    if (k == "field") return "\"name\"";
    if (k == "operator") return "\"eq\"";
    if (k == "threshold") return "\"50\"";
    if (k == "value_if_true") return "\"yes\"";
    if (k == "value_if_false") return "\"no\"";
    if (k == "condition") return "\"true\"";
    if (k == "value1") return "\"10\"";
    if (k == "value2") return "\"20\"";
    if (k == "from_format") return "\"json\"";
    if (k == "to_format") return "\"csv\"";
    if (k == "name") return "\"fetch_url\"";
    // Type-based defaults
    switch (t) {
      case "string" "\"sample text\"";
      case "number" "10";
      case "boolean" "true";
      case "array"   "[\"item1\", \"item2\"]";
      case "object"  "{\"key\": \"value\"}";
      case _ "\"sample\"";
    };
  };

  /// Generate a wrong-type value for a field (e.g. number where string expected).
  public func wrongTypeValueForField(field : CapTypes.CapabilityInput) : Text {
    switch (field.inputType) {
      case "string"  "12345";      // number where string expected
      case "number"  "\"not_a_number\"";
      case "boolean" "\"not_a_boolean\"";
      case "array"   "\"not_an_array\"";
      case "object"  "\"not_an_object\"";
      case _         "null";
    };
  };

  /// Check if a JSON text contains a given key (e.g. "key":).
  /// Used for output key validation — fast and simple.
  public func jsonHasKey(jsonText : Text, key : Text) : Bool {
    jsonText.contains(#text ("\"" # key # "\""));
  };

  /// Parse the top-level keys from a JSON object text.
  /// Returns null if text is not a JSON object.
  /// Uses simple string-contains matching — adequate for well-formed output JSON.
  public func parseTopLevelKeys(jsonText : Text) : ?[Text] {
    let trimmed = jsonText.trim(#char ' ').trim(#char '\n').trim(#char '\r');
    if (not trimmed.startsWith(#text "{")) return null;
    // Return a sentinel — key existence is checked via jsonHasKey for simplicity
    ?[];
  };

  /// Compare two JSON texts for structural equality (text comparison after normalization).
  public func jsonEqual(a : Text, b : Text) : Bool {
    normalizeJson(a) == normalizeJson(b);
  };

  /// Verify that an ExecutionResult matches the expected test behavior.
  public func evaluateResult(
    testCase : Types.TestCase,
    result : ExecTypes.ExecutionResult,
    secondResult : ?ExecTypes.ExecutionResult,
  ) : Types.TestResult {
    var passed = true;
    var failureReason : ?Text = null;

    // Check success/failure expectation
    if (result.success != testCase.expectSuccess) {
      passed := false;
      if (testCase.expectSuccess) {
        let errMsg = switch (result.error) {
          case (?e) e.code # ": " # e.message;
          case null "unknown error";
        };
        failureReason := ?("Expected success=true but got success=false. Error: " # errMsg);
      } else {
        failureReason := ?("Expected success=false but capability succeeded");
      };
    };

    // Check error code if expected
    if (passed and not testCase.expectSuccess) {
      switch (testCase.expectErrorCode) {
        case (?expectedCode) {
          let actualCode = switch (result.error) {
            case (?e) ?e.code;
            case null null;
          };
          switch (actualCode) {
            case (?code) {
              if (code != expectedCode) {
                passed := false;
                failureReason := ?("Expected error code '" # expectedCode # "' but got '" # code # "'");
              };
            };
            case null {
              passed := false;
              failureReason := ?("Expected error code '" # expectedCode # "' but no error was returned");
            };
          };
        };
        case null {};
      };
    };

    // Check output keys if expected
    if (passed and testCase.expectSuccess and testCase.expectedOutputKeys.size() > 0) {
      switch (result.output) {
        case (?outputText) {
          for (expectedKey in testCase.expectedOutputKeys.values()) {
            if (not jsonHasKey(outputText, expectedKey)) {
              passed := false;
              failureReason := ?("Output missing expected key: '" # expectedKey # "'");
            };
          };
        };
        case null {
          passed := false;
          failureReason := ?("Expected output but got null");
        };
      };
    };

    // Check determinism: second run must match first
    if (passed and testCase.category == #Determinism) {
      switch (secondResult) {
        case (?second) {
          let out1 = switch (result.output) { case (?o) o; case null "" };
          let out2 = switch (second.output) { case (?o) o; case null "" };
          if (not jsonEqual(out1, out2)) {
            passed := false;
            failureReason := ?("Non-deterministic output: first run and second run produced different results");
          };
        };
        case null {};
      };
    };

    {
      testId = testCase.id;
      capabilityName = testCase.capabilityName;
      category = testCase.category;
      description = testCase.description;
      inputJson = testCase.inputJson;
      passed;
      failureReason;
      actualSuccess = result.success;
      actualOutput = result.output;
      actualErrorCode = switch (result.error) {
        case (?e) ?e.code;
        case null null;
      };
      latencyMs = result.latencyMs;
    };
  };

  // ── Private helpers ──────────────────────────────────────────────────────────

  func buildJsonObject(fields : [CapTypes.CapabilityInput]) : Text {
    let parts = List.empty<Text>();
    for (f in fields.values()) {
      parts.add("\"" # f.key # "\": " # defaultValueForField(f));
    };
    "{" # parts.values().join(", ") # "}";
  };

  func normalizeJson(s : Text) : Text {
    // Remove all whitespace outside of strings for comparison
    let chars = s.toArray();
    let result = List.empty<Char>();
    var inStr = false;
    var escape = false;
    for (c in chars.values()) {
      if (escape) {
        result.add(c);
        escape := false;
      } else if (inStr) {
        if (c == '\\') escape := true;
        if (c == '\"') inStr := false;
        result.add(c);
      } else {
        if (c == '\"') {
          inStr := true;
          result.add(c);
        } else if (c != ' ' and c != '\n' and c != '\r' and c != '\t') {
          result.add(c);
        };
      };
    };
    Text.fromArray(result.toArray());
  };
};
