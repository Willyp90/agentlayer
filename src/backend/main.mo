import ExecTypes "types/execution";
import ApiKeyTypes "types/api-keys";
import AdminTestTypes "types/admin-test-engine";
import CapLib "lib/capabilities";
import ExecLib "lib/execution";
import AdminLib "lib/admin";
import Map "mo:core/Map";
import List "mo:core/List";
import ExperimentalCycles "mo:core/Cycles";
import CapabilitiesApi "mixins/capabilities-api";
import ExecutionApi "mixins/execution-api";
import ApiKeysApi "mixins/api-keys-api";
import DeveloperApi "mixins/developer-api";
import AdminApi "mixins/admin-api";





actor {
  // ── Stable snapshots for upgrade safety ────────────────────────────────────
  stable var stableLogs : [ExecTypes.ExecutionLog] = [];
  stable var stableExecCount : Nat = 0;
  stable var stableObjectStore : [(Text, Text)] = [];
  stable var stableApiKeys : [ApiKeyTypes.ApiKey] = [];
  stable var stableApiKeyCount : Nat = 0;
  stable var stableHttpCache : [(Text, CapLib.CacheEntry)] = [];
  stable var stableAuditLog : [ApiKeyTypes.AuditEvent] = [];
  stable var stableAuditEventCount : Nat = 0;
  stable var stableAdminId : ?Text = null;
  stable var stableTestRuns : [(Text, AdminTestTypes.TestRunResult)] = [];
  stable var stableTestRunHistory : [AdminTestTypes.TestRunMetadata] = [];
  stable var stableTestRunCount : Nat = 0;
  stable var stableRateLimitBuckets : [(Text, Nat)] = [];

  // Execution logs (append-only, newest-last)
  let logs = List.empty<ExecTypes.ExecutionLog>();

  // Monotonic counter for generating unique execution IDs
  let execCounter = { var count : Nat = 0 };

  // In-memory object store for storage capabilities
  let objectStore = Map.empty<Text, Text>();

  // API keys store
  let apiKeysList = List.empty<ApiKeyTypes.ApiKey>();

  // Monotonic counter for API key generation (collision avoidance)
  let apiKeyCounter = { var count : Nat = 0 };

  // HTTP response cache for fetch_url: keyed by URL+method+body
  let httpCacheMap = Map.empty<Text, CapLib.CacheEntry>();

  // Audit log for key lifecycle and auth events
  let auditLog = List.empty<ApiKeyTypes.AuditEvent>();

  // Monotonic counter for audit event ID generation
  let auditEventCounter = { var count : Nat = 0 };

  // Admin state: holds the single adminId (first authenticated user)
  let adminState = AdminLib.newState();

  // Test run storage: runId → TestRunResult
  let testRuns = Map.empty<Text, AdminTestTypes.TestRunResult>();

  // Ordered history of test run metadata (newest appended last)
  let testRunHistory = List.empty<AdminTestTypes.TestRunMetadata>();

  // Monotonic counter for test run ID generation
  let testRunCounter = { var count : Nat = 0 };

  // API key rate-limit buckets: keyId:window -> count
  let keyRateLimitBuckets = Map.empty<Text, Nat>();

  // ── HTTP transform function for IC outcalls ──────────────────────────────
  // Strips variable/non-deterministic headers so the IC subnet can reach consensus.
  public query func transform_http_response(raw : CapLib.TransformArgs) : async CapLib.HttpRequestResult {
    let stripped = raw.response.headers.filter(func(h : CapLib.HttpHeader) : Bool {
      let lower = h.name.toLower();
      lower != "date" and lower != "x-request-id" and lower != "x-amzn-requestid"
      and lower != "x-cache" and lower != "cf-ray" and lower != "age"
      and lower != "x-response-time" and lower != "x-runtime"
    });
    {
      status = raw.response.status;
      body = raw.response.body;
      headers = stripped;
    };
  };

  include CapabilitiesApi();
  include ExecutionApi(logs, execCounter, objectStore, httpCacheMap, transform_http_response, apiKeysList, auditLog, auditEventCounter, keyRateLimitBuckets);
  include ApiKeysApi(apiKeysList, apiKeyCounter, auditLog, auditEventCounter);
  include DeveloperApi();

  // Local async* wrapper so AdminApi can call capability execution without a shared boundary.
  func runCapabilityForTest(capabilityName : Text, inputJson : Text) : async* ExecTypes.ExecutionResult {
    let infoOpt = CapLib.describe(capabilityName);
    switch (infoOpt) {
      case null {
        {
          success = false;
          output = null;
          error = ?{ code = "CAPABILITY_NOT_FOUND"; message = "Unknown capability: " # capabilityName };
          executionId = "test-0";
          latencyMs = 0;
          cyclesUsed = null;
        };
      };
      case (?info) {
        await* ExecLib.run(info, inputJson, "test-runner", "test-0", 0, objectStore, httpCacheMap, transform_http_response, ExperimentalCycles.balance());
      };
    };
  };

  include AdminApi(adminState, testRuns, testRunHistory, testRunCounter, runCapabilityForTest);

  system func preupgrade() {
    stableLogs := logs.toArray();
    stableExecCount := execCounter.count;
    stableObjectStore := objectStore.toArray();
    stableApiKeys := apiKeysList.toArray();
    stableApiKeyCount := apiKeyCounter.count;
    stableHttpCache := httpCacheMap.toArray();
    stableAuditLog := auditLog.toArray();
    stableAuditEventCount := auditEventCounter.count;
    stableAdminId := AdminLib.getAdminId(adminState);
    stableTestRuns := testRuns.toArray();
    stableTestRunHistory := testRunHistory.toArray();
    stableTestRunCount := testRunCounter.count;
    stableRateLimitBuckets := keyRateLimitBuckets.toArray();
  };

  system func postupgrade() {
    logs.addAll(stableLogs.values());
    execCounter.count := stableExecCount;

    for ((k, v) in stableObjectStore.values()) {
      objectStore.add(k, v);
    };

    apiKeysList.addAll(stableApiKeys.values());
    apiKeyCounter.count := stableApiKeyCount;

    for ((k, v) in stableHttpCache.values()) {
      httpCacheMap.add(k, v);
    };

    auditLog.addAll(stableAuditLog.values());
    auditEventCounter.count := stableAuditEventCount;

    adminState.adminId := stableAdminId;

    for ((k, v) in stableTestRuns.values()) {
      testRuns.add(k, v);
    };
    testRunHistory.addAll(stableTestRunHistory.values());
    testRunCounter.count := stableTestRunCount;

    for ((k, v) in stableRateLimitBuckets.values()) {
      keyRateLimitBuckets.add(k, v);
    };
  };
};
