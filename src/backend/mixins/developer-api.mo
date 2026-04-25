mixin () {

  /// Returns structured integration info explaining how agents call this canister with API keys.
  public query func get_integration_info() : async {
    candid_example : Text;
    http_method : Text;
    key_param_name : Text;
    key_location : Text;
    rate_limit_info : Text;
  } {
    {
      candid_example = "(\"keyword_search\", \"{\\\"text\\\":\\\"hello world\\\",\\\"keyword\\\":\\\"hello\\\"}\", opt \"ak_your_api_key_here\")";
      http_method = "POST";
      key_param_name = "apiKey";
      key_location = "method_parameter";
      rate_limit_info = "API keys are limited to 120 execute_capability calls per rolling minute window";
    };
  };

};
