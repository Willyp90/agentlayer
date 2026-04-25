import { useActor, useInternetIdentity } from "@caffeineai/core-infrastructure";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createActor } from "../backend";
import type {
  LogFilter as BackendLogFilter,
  backendInterface,
} from "../backend";
import type {
  ApiKey,
  AuditEvent,
  AuditEventType,
  CapabilityInfo,
  CapabilityTestStatus,
  ExecutionLog,
  ExecutionResult,
  LogFilter,
  TestRunMetadata,
  TestRunResult,
  UsageSummary,
} from "../types";

function useBackendActor() {
  return useActor(createActor) as {
    actor: backendInterface | null;
    isFetching: boolean;
  };
}

export function useCapabilities() {
  const { actor, isFetching } = useBackendActor();
  return useQuery<CapabilityInfo[]>({
    queryKey: ["capabilities"],
    queryFn: async () => {
      if (!actor) return [];
      const result = await actor.list_capabilities(null);
      return Array.isArray(result) ? (result as CapabilityInfo[]) : [];
    },
    enabled: !!actor && !isFetching,
    retry: 2,
    retryDelay: 1000,
  });
}

export function useCapability(name: string) {
  const { actor, isFetching } = useBackendActor();
  return useQuery<CapabilityInfo | null>({
    queryKey: ["capability", name],
    queryFn: async () => {
      if (!actor) return null;
      return actor.describe_capability(name) as Promise<CapabilityInfo | null>;
    },
    enabled: !!actor && !isFetching && !!name,
  });
}

export function useExecuteCapability() {
  const { actor } = useBackendActor();
  const queryClient = useQueryClient();

  return useMutation<
    ExecutionResult,
    Error,
    { capability: string; input: string; apiKey?: string }
  >({
    mutationFn: async ({ capability, input, apiKey }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.execute_capability(
        capability,
        input,
        apiKey ?? null,
      ) as Promise<ExecutionResult>;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["execution_logs"] });
      queryClient.invalidateQueries({ queryKey: ["usage_summary"] });
    },
  });
}

export function useExecutionLogs(filter?: LogFilter) {
  const { actor, isFetching } = useBackendActor();
  return useQuery<ExecutionLog[]>({
    queryKey: ["execution_logs", filter],
    queryFn: async () => {
      if (!actor) return [];
      const backendFilter: BackendLogFilter = {
        capability: filter?.capability,
        successOnly: filter?.successOnly,
        failureOnly: filter?.failureOnly,
        limit: filter?.limit !== undefined ? BigInt(filter.limit) : undefined,
        offset:
          filter?.offset !== undefined ? BigInt(filter.offset) : undefined,
      };
      return actor.get_execution_logs(backendFilter) as Promise<ExecutionLog[]>;
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 10_000,
  });
}

export function useUsageSummary() {
  const { actor, isFetching } = useBackendActor();
  return useQuery<UsageSummary | null>({
    queryKey: ["usage_summary"],
    queryFn: async () => {
      if (!actor) return null;
      return actor.get_usage_summary() as unknown as Promise<UsageSummary>;
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 30_000,
  });
}

export function useApiKeys() {
  const { actor, isFetching } = useBackendActor();
  return useQuery<ApiKey[]>({
    queryKey: ["api_keys"],
    queryFn: async () => {
      if (!actor) return [];
      return actor.list_my_api_keys() as Promise<ApiKey[]>;
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 30_000,
  });
}

export function useGenerateApiKey() {
  const { actor } = useBackendActor();
  const queryClient = useQueryClient();

  return useMutation<ApiKey, Error, { name: string }>({
    mutationFn: async ({ name }) => {
      if (!actor) throw new Error("Actor not available");
      const result = await actor.generate_api_key(name);
      if (result.__kind__ === "err") throw new Error(result.err);
      return result.ok as ApiKey;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["api_keys"] });
      queryClient.invalidateQueries({ queryKey: ["audit_log"] });
    },
  });
}

export function useRevokeApiKey() {
  const { actor } = useBackendActor();
  const queryClient = useQueryClient();

  return useMutation<void, Error, { keyId: string }>({
    mutationFn: async ({ keyId }) => {
      if (!actor) throw new Error("Actor not available");
      const result = await actor.revoke_api_key(keyId);
      if (result.__kind__ === "err") throw new Error(result.err);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["api_keys"] });
      queryClient.invalidateQueries({ queryKey: ["audit_log"] });
    },
  });
}

// ── Audit Log ──────────────────────────────────────────────────────────────────

export function useAuditLog(limit = 50, offset = 0) {
  const { actor, isFetching } = useBackendActor();

  return useQuery<AuditEvent[]>({
    queryKey: ["audit_log", limit, offset],
    queryFn: async () => {
      if (!actor) return [];
      const events = await actor.get_audit_log(BigInt(limit), BigInt(offset));
      return events.map((e) => ({
        id: e.id,
        eventType: e.eventType as AuditEventType,
        keyId: e.keyId,
        userId: e.userId,
        timestamp: e.timestamp,
        details: e.details,
      }));
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 15_000,
  });
}

// ── Admin Validation ───────────────────────────────────────────────────────────

export function useAdminStatus() {
  const { actor, isFetching } = useBackendActor();
  const { identity } = useInternetIdentity();
  const principalString = identity?.getPrincipal()?.toText() ?? "anonymous";
  return useQuery<boolean>({
    queryKey: ["admin_status", principalString],
    queryFn: async () => {
      if (!actor) return false;
      return actor.get_admin_status();
    },
    enabled: !!actor && !isFetching,
    staleTime: 0,
    gcTime: 0,
  });
}

export function useRunAllTests() {
  const { actor } = useBackendActor();
  const queryClient = useQueryClient();

  return useMutation<TestRunResult, Error>({
    mutationFn: async () => {
      if (!actor) throw new Error("Actor not available");
      return actor.run_all_tests() as Promise<TestRunResult>;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["test_statuses"] });
      queryClient.invalidateQueries({ queryKey: ["test_history"] });
    },
  });
}

export function useRunCapabilityTests() {
  const { actor } = useBackendActor();
  const queryClient = useQueryClient();

  return useMutation<TestRunResult, Error, string>({
    mutationFn: async (capabilityName: string) => {
      if (!actor) throw new Error("Actor not available");
      return actor.run_capability_tests(
        capabilityName,
      ) as Promise<TestRunResult>;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["test_statuses"] });
      queryClient.invalidateQueries({ queryKey: ["test_history"] });
    },
  });
}

export function useTestResults(runId: string | null) {
  const { actor, isFetching } = useBackendActor();
  return useQuery<TestRunResult | null>({
    queryKey: ["test_results", runId],
    queryFn: async () => {
      if (!actor || !runId) return null;
      return actor.get_test_results(runId) as Promise<TestRunResult | null>;
    },
    enabled: !!actor && !isFetching && !!runId,
  });
}

export function useTestHistory() {
  const { actor, isFetching } = useBackendActor();
  return useQuery<TestRunMetadata[]>({
    queryKey: ["test_history"],
    queryFn: async () => {
      if (!actor) return [];
      return actor.get_test_history() as Promise<TestRunMetadata[]>;
    },
    enabled: !!actor && !isFetching,
  });
}

export function useCapabilityTestStatuses() {
  const { actor, isFetching } = useBackendActor();
  return useQuery<CapabilityTestStatus[]>({
    queryKey: ["test_statuses"],
    queryFn: async () => {
      if (!actor) return [];
      return actor.get_capability_test_statuses() as Promise<
        CapabilityTestStatus[]
      >;
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 30_000,
  });
}
