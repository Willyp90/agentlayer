// TypeScript types matching backend contracts

export interface CapabilityInput {
  key: string;
  inputType: string;
  required: boolean;
  description: string;
}

export interface CapabilityOutput {
  key: string;
  outputType: string;
  description: string;
}

export interface CapabilityInfo {
  name: string;
  description: string;
  category: string;
  inputs: CapabilityInput[];
  outputs: CapabilityOutput[];
  constraints: string[];
  exampleInput: string;
  exampleOutput: string;
}

export interface ExecError {
  code: string;
  message: string;
}

export interface ExecutionResult {
  success: boolean;
  output?: string;
  error?: ExecError;
  executionId: string;
  latencyMs: bigint;
  cyclesUsed?: bigint;
}

export interface ExecutionLog {
  executionId: string;
  user: string;
  capability: string;
  input: string;
  output?: string;
  success: boolean;
  errorCode?: string;
  errorMessage?: string;
  timestamp: bigint;
  latencyMs: bigint;
  cyclesUsed?: bigint;
  apiKeyId?: string;
}

export interface LogFilter {
  capability?: string;
  successOnly?: boolean;
  failureOnly?: boolean;
  limit?: number;
  offset?: number;
}

export interface CapabilityCount {
  name: string;
  count: bigint;
}

export interface UserCount {
  user: string;
  count: bigint;
}

export interface DailyCount {
  date: string;
  count: bigint;
}

export interface UsageSummary {
  totalCalls: bigint;
  callsThisMonth: bigint;
  perCapability: CapabilityCount[];
  perUser: UserCount[];
  dailyCounts: DailyCount[];
}

export interface ApiKey {
  id: string;
  ownerId: string;
  name: string;
  createdAt: bigint;
  lastUsedAt?: bigint;
  callCount: bigint;
  active: boolean;
  totalCyclesUsed: bigint;
}

// ── Audit Events ──────────────────────────────────────────────────────────────

export type AuditEventType =
  | "key_generated"
  | "key_revoked"
  | "key_used"
  | "auth_failed";

export interface AuditEvent {
  id: string;
  eventType: AuditEventType;
  keyId: string;
  userId: string;
  timestamp: bigint;
  details: string;
}

// ── Admin Validation System ────────────────────────────────────────────────────

export type TestCategory =
  | "RequiredFieldsOnly"
  | "OptionalFieldIndividual"
  | "OptionalFieldCombination"
  | "MissingRequiredField"
  | "InvalidType"
  | "EdgeCase"
  | "OutputSchema"
  | "Determinism"
  | "ErrorHandling";

export interface TestCase {
  id: string;
  capabilityName: string;
  category: TestCategory;
  description: string;
  inputJson: string;
  expectSuccess: boolean;
  expectErrorCode?: string;
  expectedOutputKeys: string[];
}

export interface TestResult {
  testId: string;
  capabilityName: string;
  category: TestCategory;
  description: string;
  inputJson: string;
  passed: boolean;
  failureReason?: string;
  actualSuccess: boolean;
  actualOutput?: string;
  actualErrorCode?: string;
  latencyMs: bigint;
}

export interface TestRunMetadata {
  runId: string;
  startedAt: bigint;
  completedAt: bigint;
  totalTests: bigint;
  passed: bigint;
  failed: bigint;
  capabilityName?: string;
}

export interface TestRunResult {
  runId: string;
  startedAt: bigint;
  completedAt: bigint;
  capabilityName?: string;
  results: TestResult[];
  totalTests: bigint;
  passed: bigint;
  failed: bigint;
}

export interface CapabilityTestStatus {
  capabilityName: string;
  category: string;
  lastRunAt?: bigint;
  totalTests: bigint;
  passed: bigint;
  failed: bigint;
  status: "never_run" | "all_pass" | "some_fail" | "all_fail" | "pass" | "fail";
}
