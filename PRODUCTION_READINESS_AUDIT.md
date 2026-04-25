# AgentLayer Production Readiness Audit (April 25, 2026)

## 1) System Map

### Backend endpoint inventory (from DID + mixins)

| Endpoint | Source mixin | Auth model | Frontend usage |
|---|---|---|---|
| `list_capabilities` | `mixins/capabilities-api.mo` | Public | `useCapabilities` on Capabilities + Playground pages |
| `describe_capability` | `mixins/capabilities-api.mo` | Public | `useCapability` on capability detail page |
| `execute_capability` | `mixins/execution-api.mo` | Caller principal or API key owner attribution | Playground execution |
| `get_execution_logs` | `mixins/execution-api.mo` | Caller-scoped | Logs page |
| `get_usage_summary` | `mixins/execution-api.mo` | Caller-scoped | Usage page |
| `generate_api_key` | `mixins/api-keys-api.mo` | Authenticated caller only | API Keys page |
| `revoke_api_key` | `mixins/api-keys-api.mo` | Owner-only | API Keys page |
| `list_my_api_keys` | `mixins/api-keys-api.mo` | Caller-scoped | API Keys page |
| `get_api_key_stats` | `mixins/api-keys-api.mo` | Owner-only | **Not currently consumed by frontend** |
| `get_audit_log` | `mixins/api-keys-api.mo` | Caller-scoped | Audit Log page |
| `get_integration_info` | `mixins/developer-api.mo` | Public query | **Not currently consumed (Integration page uses static docs)** |
| `get_admin_status` | `mixins/admin-api.mo` | Caller compared with bootstrap admin | Layout + Admin Validation gate |
| `run_all_tests` | `mixins/admin-api.mo` | Admin-only | Admin Validation page |
| `run_capability_tests` | `mixins/admin-api.mo` | Admin-only | Admin Validation page |
| `get_test_results` | `mixins/admin-api.mo` | Admin-only | Admin Validation page |
| `get_test_history` | `mixins/admin-api.mo` | Admin-only | Admin Validation page |
| `get_capability_test_statuses` | `mixins/admin-api.mo` | Admin-only | Admin Validation page |
| `transform_http_response` | `main.mo` | Internal/system support | Not directly used by frontend |

### Contract mismatches / dead-surface notes

- `get_api_key_stats` and `get_integration_info` are exposed but not wired through frontend hooks/pages.
- Audit event taxonomy is backend `Text`; frontend enforces a narrow union type (now expanded to include `rate_limited`).

## 2) Findings (Prioritized)

### P0

1. **Admin bootstrap could be captured by anonymous caller.**
   - Root cause: `get_admin_status` always called `initAdmin` with caller text, including anonymous principal.
   - Risk: admin lock-in to anonymous identity, effectively denying legitimate admin operations.
   - Fix: reject anonymous caller from bootstrap path (`false` response, no mutation).

2. **No upgrade persistence for critical runtime state.**
   - Root cause: logs, keys, audit data, caches, and counters were held only in in-memory structures.
   - Risk: data loss across upgrade/redeploy, broken observability/accounting continuity.
   - Fix: added `stable var` snapshots and `preupgrade`/`postupgrade` hydration for execution logs, object store, API keys, audit log, admin state, test runs/history, counters, and key rate-limit buckets.

### P1

1. **API key abuse posture lacked any throttling.**
   - Root cause: no server-side request cap in `execute_capability` for API-key traffic.
   - Risk: runaway automated usage / accidental burst / spend risk.
   - Fix: per-key per-minute rate limiter (`120/min`) with `RATE_LIMITED` execution error and `rate_limited` audit events.

2. **Capability test engine missed required categories from quality bar.**
   - Root cause: no optional-combination scenario or malformed-JSON error-handling test generation.
   - Risk: false confidence in capability validation/error semantics.
   - Fix: added `OptionalFieldCombination` and `ErrorHandling` malformed JSON test generation.

### P2

1. **API key naming validation too permissive.**
   - Root cause: no trim/empty/length checks on key name.
   - Risk: poor audit readability and UX inconsistencies.
   - Fix: trim + reject empty names + enforce 64-char max.

## 3) Implemented Changes (file-by-file)

- `src/backend/mixins/admin-api.mo`
  - Blocked anonymous admin bootstrap.
- `src/backend/main.mo`
  - Added stable snapshots and upgrade hooks for production-safe state continuity.
  - Added in-memory key rate-limit bucket map and passed it into execution mixin.
- `src/backend/mixins/execution-api.mo`
  - Added API key rate limiting with consistent error + audit + execution log behavior.
- `src/backend/mixins/api-keys-api.mo`
  - Added API key name validation/normalization.
- `src/backend/lib/test-engine.mo`
  - Added optional field combination test generation.
  - Added malformed JSON error-handling test generation.
- `src/backend/types/api-keys.mo`
  - Documented expanded audit event taxonomy to include `rate_limited`.
- `src/backend/mixins/developer-api.mo`
  - Updated integration rate-limit descriptor to reflect real behavior.
- `src/frontend/src/types.ts`
  - Added `rate_limited` to `AuditEventType` union.
- `src/frontend/src/pages/AuditLogPage.tsx`
  - Added rendering/filtering for `rate_limited` audit events.

## 4) Verification commands

- `cd src/backend && mops check --fix`
- `cd src/backend && mops build`
- `pnpm bindgen`
- `cd src/frontend && pnpm install --prefer-offline`
- `cd src/frontend && pnpm typecheck`
- `cd src/frontend && pnpm build`

## 5) Residual Risk / Follow-ups

1. **Determinism checks are output-text normalized comparisons, not semantic AST JSON compare.**
2. **No long-window key scope/expiry model yet** (current hardening adds throttling only).
3. **Rate limiter buckets currently persist unless manually pruned** (functional but can grow under very high key churn).
4. **`get_api_key_stats` and `get_integration_info` remain unconsumed in UI** (not unsafe, but dead-surface debt).

## 6) Current readiness verdict

**CONDITIONALLY_READY**

The system is materially safer than baseline (admin bootstrap hardening, upgrade persistence, API-key throttling, broader capability test coverage), but still needs additional operational hardening (schema-level output assertions, richer key governance/scopes/expiry, and scalable pruning/indexing strategies) before a strict `READY` designation.
