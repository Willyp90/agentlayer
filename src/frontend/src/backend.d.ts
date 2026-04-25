import type { Principal } from "@icp-sdk/core/principal";
export interface Some<T> {
    __kind__: "Some";
    value: T;
}
export interface None {
    __kind__: "None";
}
export type Option<T> = Some<T> | None;
export interface CapabilityOutput {
    key: string;
    description: string;
    outputType: string;
}
export interface ExecutionResult {
    output?: string;
    error?: ExecError;
    executionId: string;
    latencyMs: bigint;
    cyclesUsed?: bigint;
    success: boolean;
}
export type Timestamp = bigint;
export interface TestRunResult {
    completedAt: Timestamp;
    startedAt: Timestamp;
    totalTests: bigint;
    results: Array<TestResult>;
    capabilityName?: string;
    failed: bigint;
    passed: bigint;
    runId: string;
}
export interface HttpRequestResult {
    status: bigint;
    body: Uint8Array;
    headers: Array<HttpHeader>;
}
export interface UsageSummary {
    totalCalls: bigint;
    callsThisMonth: bigint;
    perUser: Array<UserCount>;
    dailyCounts: Array<DailyCount>;
    perCapability: Array<CapabilityCount>;
}
export interface ExecutionLog {
    output?: string;
    apiKeyId?: string;
    errorMessage?: string;
    user: UserId;
    errorCode?: string;
    executionId: string;
    latencyMs: bigint;
    cyclesUsed?: bigint;
    timestamp: Timestamp;
    success: boolean;
    input: string;
    capability: string;
}
export interface TestRunMetadata {
    completedAt: Timestamp;
    startedAt: Timestamp;
    totalTests: bigint;
    capabilityName?: string;
    failed: bigint;
    passed: bigint;
    runId: string;
}
export interface CapabilityTestStatus {
    status: string;
    totalTests: bigint;
    lastRunAt?: Timestamp;
    category: string;
    capabilityName: string;
    failed: bigint;
    passed: bigint;
}
export interface CapabilityCount {
    name: string;
    count: bigint;
}
export interface HttpHeader {
    value: string;
    name: string;
}
export interface TestResult {
    inputJson: string;
    failureReason?: string;
    description: string;
    actualErrorCode?: string;
    latencyMs: bigint;
    category: TestCategory;
    actualSuccess: boolean;
    actualOutput?: string;
    testId: string;
    capabilityName: string;
    passed: boolean;
}
export type UserId = string;
export interface ExecError {
    code: string;
    message: string;
}
export interface UserCount {
    count: bigint;
    user: UserId;
}
export interface DailyCount {
    date: string;
    count: bigint;
}
export interface CapabilityInput {
    key: string;
    inputType: string;
    description: string;
    required: boolean;
}
export interface AuditEvent {
    id: string;
    userId: string;
    timestamp: bigint;
    details: string;
    keyId: string;
    eventType: string;
}
export interface ApiKeyStats {
    lastUsedAt?: bigint;
    active: boolean;
    totalCyclesUsed: bigint;
    callCount: bigint;
    keyId: string;
}
export interface ApiKey {
    id: string;
    lastUsedAt?: bigint;
    active: boolean;
    ownerId: string;
    name: string;
    createdAt: bigint;
    totalCyclesUsed: bigint;
    callCount: bigint;
}
export interface LogFilter {
    successOnly?: boolean;
    user?: string;
    offset?: bigint;
    limit?: bigint;
    failureOnly?: boolean;
    capability?: string;
}
export interface CapabilityInfo {
    constraints: Array<string>;
    exampleOutput: string;
    name: string;
    exampleInput: string;
    description: string;
    inputs: Array<CapabilityInput>;
    category: string;
    outputs: Array<CapabilityOutput>;
}
export interface TransformArgs {
    context: Uint8Array;
    response: HttpRequestResult;
}
export enum TestCategory {
    MissingRequiredField = "MissingRequiredField",
    OutputSchema = "OutputSchema",
    Determinism = "Determinism",
    EdgeCase = "EdgeCase",
    RequiredFieldsOnly = "RequiredFieldsOnly",
    ErrorHandling = "ErrorHandling",
    InvalidType = "InvalidType",
    OptionalFieldIndividual = "OptionalFieldIndividual",
    OptionalFieldCombination = "OptionalFieldCombination"
}
export interface backendInterface {
    describe_capability(name: string): Promise<CapabilityInfo | null>;
    execute_capability(capabilityName: string, inputJson: string, apiKey: string | null): Promise<ExecutionResult>;
    generate_api_key(name: string): Promise<{
        __kind__: "ok";
        ok: ApiKey;
    } | {
        __kind__: "err";
        err: string;
    }>;
    get_admin_status(): Promise<boolean>;
    get_api_key_stats(keyId: string): Promise<{
        __kind__: "ok";
        ok: ApiKeyStats;
    } | {
        __kind__: "err";
        err: string;
    }>;
    get_audit_log(limit: bigint, offset: bigint): Promise<Array<AuditEvent>>;
    get_capability_test_statuses(): Promise<Array<CapabilityTestStatus>>;
    get_execution_logs(filter: LogFilter): Promise<Array<ExecutionLog>>;
    get_integration_info(): Promise<{
        candid_example: string;
        key_location: string;
        http_method: string;
        key_param_name: string;
        rate_limit_info: string;
    }>;
    get_test_history(): Promise<Array<TestRunMetadata>>;
    get_test_results(runId: string): Promise<TestRunResult | null>;
    get_usage_summary(): Promise<UsageSummary>;
    list_capabilities(categoryFilter: string | null): Promise<Array<CapabilityInfo>>;
    list_my_api_keys(): Promise<Array<ApiKey>>;
    revoke_api_key(keyId: string): Promise<{
        __kind__: "ok";
        ok: null;
    } | {
        __kind__: "err";
        err: string;
    }>;
    run_all_tests(): Promise<TestRunResult>;
    run_capability_tests(capabilityName: string): Promise<TestRunResult>;
    transform_http_response(raw: TransformArgs): Promise<HttpRequestResult>;
}
