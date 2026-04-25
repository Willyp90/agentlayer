# AgentLayer Production Readiness Audit

## Scope Reviewed

- Backend actor wiring and state ownership in `src/backend/main.mo`.
- Capability registry/execution path in `src/backend/lib/capabilities.mo` and `src/backend/lib/execution.mo`.
- Capability test engine and admin test APIs in `src/backend/lib/test-engine.mo` and `src/backend/mixins/admin-api.mo`.
- API key management and usage/audit tracking in `src/backend/mixins/api-keys-api.mo`, `src/backend/lib/api-keys.mo`, and `src/backend/mixins/execution-api.mo`.
- Frontend contract alignment and admin/usage/API key pages in `src/frontend/src/types.ts`, `src/frontend/src/hooks/useBackend.ts`, and key pages.
- Public API surface in `src/backend/dist/backend.did`.

## Goal Coverage Summary

### 1) Capability tester works and verifies capabilities correctly

Status: **Partially ready** (improved in this patch).

What was fixed:
- Test expectations for validation failures now align with actual backend error codes (`INVALID_INPUT`), preventing systematic false negatives in generated tests.
- Determinism tests now fail explicitly when the second run fails, rather than only comparing outputs.

Remaining gaps:
- Auto-generated test inputs still rely on heuristic defaults, so some capabilities with strict semantic constraints may fail tests for reasons unrelated to capability correctness.
- Output schema verification is key-presence based string matching, not structural JSON validation.
- No persisted baseline or regression gating by capability category/severity.

### 2) API usage tracking logic correctness

Status: **Mostly correct, with production hardening needed**.

Strengths:
- Usage attribution with API keys maps execution to key owner and increments call count.
- Cycle usage is recorded per key on successful dispatch completion.
- User-scoped usage summary and logs are available.

Risks / hardening needs:
- State is in-memory only (no stable persistence strategy shown for upgrades).
- Audit taxonomy is open text; lacks strict enum guardrails across frontend/backend.
- Aggregations are list/scan based and may degrade at larger log volumes.
- No explicit per-key rate limiting or abuse controls.

### 3) API endpoints readiness

Status: **Functionally broad, but not yet fully production hardened**.

Strengths:
- Core endpoint groups exist: capabilities, execution, usage/logs, API keys, admin tests.
- DID contract is generated and frontend hook coverage exists.

Gaps:
- No explicit versioning/deprecation strategy.
- Error code semantics are not uniformly centralized across all modules.
- Admin bootstrap (`first caller becomes admin`) is convenient for dev but risky for production deployments unless deployment process guarantees first-caller control.

## Prioritized Production Worklist

1. **Persistence & upgrade safety**
   - Introduce stable state serialization/migration for logs, keys, audits, test history, and caches.
2. **Capability test engine robustness**
   - Replace heuristic input generation with capability-provided fixture contracts or per-capability test vectors.
   - Upgrade output checks to parsed JSON schema validation.
3. **Security hardening**
   - Add API key scopes, rotation metadata, and optional expiration.
   - Add rate limiting/throttling and suspicious-activity heuristics.
4. **Observability**
   - Add structured metrics for endpoint latency/error cardinality and cache hit rate.
   - Add explicit health-check/smoke test endpoint strategy.
5. **Contract governance**
   - Add endpoint versioning policy and changelog discipline.

## Changes made in this patch

- Aligned capability test engine validation-error expectations to `INVALID_INPUT`.
- Improved determinism test behavior to fail when second execution fails.
- Aligned frontend TypeScript contracts with backend DID fields and audit event taxonomy (`key_used`, `totalCyclesUsed`, `cyclesUsed`, `apiKeyId`).

