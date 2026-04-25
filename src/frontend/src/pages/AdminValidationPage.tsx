import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Link } from "@tanstack/react-router";
import {
  AlertCircle,
  AlertTriangle,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  ChevronUp,
  Clipboard,
  ClipboardCheck,
  Clock,
  Download,
  Filter,
  History,
  Loader2,
  Play,
  Shield,
  ShieldOff,
  XCircle,
} from "lucide-react";
import { useCallback, useState } from "react";
import {
  useAdminStatus,
  useCapabilityTestStatuses,
  useRunAllTests,
  useRunCapabilityTests,
  useTestHistory,
  useTestResults,
} from "../hooks/useBackend";
import type {
  CapabilityTestStatus,
  TestCategory,
  TestResult,
  TestRunMetadata,
  TestRunResult,
} from "../types";

// ── Export utilities ─────────────────────────────────────────────────────────

function tryParseJson(raw: string): unknown {
  try {
    return JSON.parse(raw);
  } catch {
    return raw;
  }
}

interface FailedTestExport {
  capability: string;
  testId: string;
  category: string;
  description: string;
  input: unknown;
  actualOutput: unknown;
  failureReason: string;
  actualSuccess: boolean;
  actualErrorCode: string | null;
}

interface ExportPayload {
  exportedAt: string;
  summary: {
    totalFailed: number;
    capabilities: string[];
  };
  failedTests: FailedTestExport[];
}

function buildExportPayload(results: TestResult[]): ExportPayload {
  const failed = results.filter((r) => !r.passed);
  const capabilitySet = [...new Set(failed.map((r) => r.capabilityName))];
  return {
    exportedAt: new Date().toISOString(),
    summary: {
      totalFailed: failed.length,
      capabilities: capabilitySet,
    },
    failedTests: failed.map((r) => ({
      capability: r.capabilityName,
      testId: r.testId,
      category: r.category,
      description: r.description,
      input: tryParseJson(r.inputJson),
      actualOutput: r.actualOutput ? tryParseJson(r.actualOutput) : null,
      failureReason: r.failureReason ?? "",
      actualSuccess: r.actualSuccess,
      actualErrorCode: r.actualErrorCode ?? null,
    })),
  };
}

function downloadJson(payload: ExportPayload, filename: string) {
  const blob = new Blob([JSON.stringify(payload, null, 2)], {
    type: "application/json",
  });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

function todayFilename() {
  const d = new Date();
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `agentlayer-failed-tests-${yyyy}-${mm}-${dd}.json`;
}

// ── Export button component ──────────────────────────────────────────────────

function ExportFailedButton({
  results,
  label = "Export Failed",
  compact = false,
}: {
  results: TestResult[];
  label?: string;
  compact?: boolean;
}) {
  const [copied, setCopied] = useState(false);
  const failed = results.filter((r) => !r.passed);
  const payload = buildExportPayload(results);

  const handleDownload = useCallback(() => {
    downloadJson(payload, todayFilename());
  }, [payload]);

  const handleCopy = useCallback(async () => {
    const text = JSON.stringify(payload, null, 2);
    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(text);
      } else {
        const el = document.createElement("textarea");
        el.value = text;
        el.style.cssText = "position:fixed;opacity:0;top:0;left:0";
        document.body.appendChild(el);
        el.select();
        document.execCommand("copy");
        document.body.removeChild(el);
      }
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {}
  }, [payload]);

  if (failed.length === 0) return null;

  return (
    <div className="flex items-center gap-1.5" data-ocid="export-failed-group">
      {/* Download */}
      <button
        type="button"
        onClick={handleDownload}
        data-ocid="btn-export-failed-download"
        className={`flex items-center gap-1.5 border border-destructive/30 text-destructive/80 hover:text-destructive hover:border-destructive/60 hover:bg-destructive/5 transition-smooth rounded font-mono font-medium ${
          compact ? "px-2 py-0.5 text-[10px]" : "px-2.5 py-1 text-[11px]"
        }`}
        title="Download failed tests as JSON"
      >
        <Download size={compact ? 10 : 11} />
        {!compact && <span>{label}</span>}
        {compact && <span>{label}</span>}
        <span
          className={`${
            compact ? "text-[9px]" : "text-[10px]"
          } opacity-60 font-normal`}
        >
          ({failed.length})
        </span>
      </button>

      {/* Copy */}
      <button
        type="button"
        onClick={handleCopy}
        data-ocid="btn-export-failed-copy"
        className={`flex items-center gap-1 border border-border text-muted-foreground hover:text-foreground hover:border-accent/40 hover:bg-muted/30 transition-smooth rounded font-mono ${
          compact ? "px-1.5 py-0.5 text-[10px]" : "px-2 py-1 text-[10px]"
        }`}
        title="Copy JSON to clipboard"
      >
        {copied ? (
          <>
            <ClipboardCheck
              size={compact ? 9 : 10}
              className="text-emerald-400"
            />
            <span className="text-emerald-400">Copied!</span>
          </>
        ) : (
          <>
            <Clipboard size={compact ? 9 : 10} />
            <span className="hidden sm:inline">Copy</span>
          </>
        )}
      </button>
    </div>
  );
}

// ── Category badge labels ───────────────────────────────────────────────────
const CATEGORY_LABELS: Record<TestCategory, string> = {
  RequiredFieldsOnly: "req-fields",
  OptionalFieldIndividual: "opt-field",
  OptionalFieldCombination: "opt-combo",
  MissingRequiredField: "missing-req",
  InvalidType: "invalid-type",
  EdgeCase: "edge-case",
  OutputSchema: "output-schema",
  Determinism: "determinism",
  ErrorHandling: "error-handling",
};

const CATEGORY_COLORS: Record<TestCategory, string> = {
  RequiredFieldsOnly: "bg-accent/10 text-accent border-accent/20",
  OptionalFieldIndividual: "bg-primary/10 text-primary border-primary/20",
  OptionalFieldCombination: "bg-primary/10 text-primary border-primary/20",
  MissingRequiredField:
    "bg-destructive/10 text-destructive border-destructive/20",
  InvalidType: "bg-destructive/10 text-destructive border-destructive/20",
  EdgeCase: "bg-muted text-muted-foreground border-border",
  OutputSchema: "bg-accent/10 text-accent border-accent/20",
  Determinism: "bg-secondary text-secondary-foreground border-border",
  ErrorHandling: "bg-muted text-muted-foreground border-border",
};

// ── Status badge ────────────────────────────────────────────────────────────
type StatusVariant = CapabilityTestStatus["status"];

const STATUS_CONFIG: Record<
  StatusVariant,
  { label: string; className: string; icon: React.ReactNode }
> = {
  never_run: {
    label: "Never Run",
    className: "bg-muted text-muted-foreground border-border",
    icon: <Clock size={11} />,
  },
  all_pass: {
    label: "All Pass",
    className: "bg-emerald-500/10 text-emerald-400 border-emerald-500/20",
    icon: <CheckCircle2 size={11} />,
  },
  // Backend alias for all_pass
  pass: {
    label: "All Pass",
    className: "bg-emerald-500/10 text-emerald-400 border-emerald-500/20",
    icon: <CheckCircle2 size={11} />,
  },
  some_fail: {
    label: "Some Fail",
    className: "bg-amber-500/10 text-amber-400 border-amber-500/20",
    icon: <AlertTriangle size={11} />,
  },
  // Backend alias for some_fail
  fail: {
    label: "Some Fail",
    className: "bg-amber-500/10 text-amber-400 border-amber-500/20",
    icon: <AlertTriangle size={11} />,
  },
  all_fail: {
    label: "All Fail",
    className: "bg-destructive/10 text-destructive border-destructive/20",
    icon: <XCircle size={11} />,
  },
};

function StatusBadge({ status }: { status: StatusVariant }) {
  const config = STATUS_CONFIG[status] ?? STATUS_CONFIG.never_run;
  return (
    <span
      className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-mono font-medium border ${config.className}`}
    >
      {config.icon}
      {config.label}
    </span>
  );
}

function CategoryBadge({ category }: { category: TestCategory }) {
  return (
    <span
      className={`inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-mono border ${CATEGORY_COLORS[category]}`}
    >
      {CATEGORY_LABELS[category]}
    </span>
  );
}

// ── Collapsible JSON block ──────────────────────────────────────────────────
function JsonBlock({ label, value }: { label: string; value: string }) {
  const [open, setOpen] = useState(false);
  let pretty = value;
  try {
    pretty = JSON.stringify(JSON.parse(value), null, 2);
  } catch {}

  return (
    <div className="mt-2">
      <button
        type="button"
        onClick={() => setOpen((p) => !p)}
        className="flex items-center gap-1.5 text-[10px] font-mono text-muted-foreground hover:text-foreground transition-colors"
      >
        {open ? <ChevronDown size={11} /> : <ChevronRight size={11} />}
        {label}
      </button>
      {open && (
        <pre className="mt-1.5 code-block text-[10px] leading-relaxed max-h-40 overflow-auto whitespace-pre-wrap break-all">
          <code>{pretty}</code>
        </pre>
      )}
    </div>
  );
}

// ── Individual test result row ──────────────────────────────────────────────
function TestResultRow({ result }: { result: TestResult }) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div
      className={`border border-border rounded text-xs transition-smooth ${
        result.passed ? "bg-card" : "bg-destructive/5 border-destructive/20"
      }`}
      data-ocid="test-result-row"
    >
      <button
        type="button"
        onClick={() => setExpanded((p) => !p)}
        className="w-full flex items-start gap-3 px-3 py-2.5 text-left"
      >
        <span className="mt-0.5 shrink-0">
          {result.passed ? (
            <CheckCircle2 size={14} className="text-emerald-400" />
          ) : (
            <XCircle size={14} className="text-destructive" />
          )}
        </span>
        <span className="flex-1 min-w-0">
          <span className="text-foreground font-mono text-[11px] leading-snug block truncate">
            {result.description}
          </span>
          {!result.passed && result.failureReason && (
            <span className="mt-0.5 block text-destructive text-[10px] font-mono leading-snug">
              ↳ {result.failureReason}
            </span>
          )}
        </span>
        <CategoryBadge category={result.category} />
        <span className="shrink-0 text-muted-foreground font-mono text-[10px] ml-1">
          {Number(result.latencyMs)}ms
        </span>
        <span className="shrink-0 ml-1 text-muted-foreground">
          {expanded ? <ChevronDown size={12} /> : <ChevronRight size={12} />}
        </span>
      </button>

      {expanded && (
        <div className="px-3 pb-3 border-t border-border/50">
          <JsonBlock label="Input" value={result.inputJson} />
          {result.actualOutput && (
            <JsonBlock label="Actual Output" value={result.actualOutput} />
          )}
          {result.actualErrorCode && (
            <div className="mt-2 text-[10px] font-mono text-destructive">
              Error code: {result.actualErrorCode}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// ── Test Results Panel ──────────────────────────────────────────────────────
type TestFilter = "all" | "pass" | "fail";

function TestResultsPanel({
  capabilityName,
  runId,
  onClose,
}: {
  capabilityName: string;
  runId?: string;
  onClose: () => void;
}) {
  const [filter, setFilter] = useState<TestFilter>("all");
  const { data: run, isPending } = useTestResults(runId ?? null);

  const filtered =
    run?.results.filter((r) => {
      if (filter === "pass") return r.passed;
      if (filter === "fail") return !r.passed;
      return true;
    }) ?? [];

  return (
    <div
      className="flex flex-col h-full bg-card border-l border-border"
      data-ocid="test-results-panel"
    >
      {/* Panel header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-border shrink-0">
        <div className="min-w-0">
          <div className="font-mono text-sm font-semibold text-foreground truncate">
            {capabilityName}
          </div>
          {run && (
            <div className="mt-0.5 flex items-center gap-3 text-[10px] text-muted-foreground font-mono">
              <span className="text-emerald-400">
                {Number(run.passed)} pass
              </span>
              <span className="text-destructive">
                {Number(run.failed)} fail
              </span>
              <span>{Number(run.totalTests)} total</span>
              <span>
                {new Date(
                  Number(run.startedAt) / 1_000_000,
                ).toLocaleTimeString()}
              </span>
            </div>
          )}
        </div>
        <button
          type="button"
          onClick={onClose}
          className="ml-3 p-1.5 rounded text-muted-foreground hover:text-foreground hover:bg-secondary transition-smooth"
          aria-label="Close panel"
        >
          <XCircle size={14} />
        </button>
      </div>

      {/* Filter bar */}
      <div
        className="flex items-center gap-1.5 px-4 py-2 border-b border-border bg-muted/20 shrink-0"
        data-ocid="test-filter-bar"
      >
        <Filter size={11} className="text-muted-foreground" />
        {(["all", "pass", "fail"] as TestFilter[]).map((f) => (
          <button
            key={f}
            type="button"
            onClick={() => setFilter(f)}
            data-ocid={`filter-${f}`}
            className={`px-2.5 py-0.5 rounded text-[10px] font-mono transition-smooth ${
              filter === f
                ? "bg-accent text-accent-foreground"
                : "text-muted-foreground hover:text-foreground"
            }`}
          >
            {f === "all" ? "All" : f === "pass" ? "Passed" : "Failed"}
          </button>
        ))}
        {run && (
          <div className="ml-auto">
            <ExportFailedButton
              results={run.results}
              label="Export Failed"
              compact
            />
          </div>
        )}
      </div>

      {/* Results list */}
      <div className="flex-1 overflow-y-auto p-3 space-y-1.5">
        {isPending ? (
          ["a", "b", "c", "d", "e", "f"].map((k) => (
            <Skeleton key={`skel-result-${k}`} className="h-10 rounded" />
          ))
        ) : !run ? (
          <div className="flex flex-col items-center justify-center h-32 text-center text-muted-foreground">
            <AlertCircle size={20} className="mb-2 opacity-40" />
            <p className="text-xs font-mono">No results available</p>
          </div>
        ) : filtered.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-32 text-center text-muted-foreground">
            <CheckCircle2 size={20} className="mb-2 opacity-40" />
            <p className="text-xs font-mono">No {filter} tests</p>
          </div>
        ) : (
          filtered.map((r) => <TestResultRow key={r.testId} result={r} />)
        )}
      </div>
    </div>
  );
}

// ── Test History Section ────────────────────────────────────────────────────
function TestHistoryPanel({
  history,
  onSelectRun,
  selectedRunId,
}: {
  history: TestRunMetadata[];
  onSelectRun: (runId: string, capName: string) => void;
  selectedRunId?: string;
}) {
  const [open, setOpen] = useState(false);

  return (
    <div
      className="border-t border-border bg-muted/10 shrink-0"
      data-ocid="test-history-panel"
    >
      <button
        type="button"
        onClick={() => setOpen((p) => !p)}
        className="w-full flex items-center gap-2 px-4 py-2.5 text-left hover:bg-muted/20 transition-smooth"
      >
        <History size={13} className="text-muted-foreground shrink-0" />
        <span className="text-xs font-mono text-muted-foreground flex-1">
          Test History ({history.length})
        </span>
        {open ? (
          <ChevronDown size={13} className="text-muted-foreground" />
        ) : (
          <ChevronUp size={13} className="text-muted-foreground" />
        )}
      </button>
      {open && (
        <div className="max-h-52 overflow-y-auto border-t border-border">
          {history.length === 0 ? (
            <div className="px-4 py-3 text-xs text-muted-foreground font-mono">
              No history yet
            </div>
          ) : (
            history.map((run) => (
              <button
                key={run.runId}
                type="button"
                onClick={() =>
                  onSelectRun(
                    run.runId,
                    run.capabilityName ?? "All Capabilities",
                  )
                }
                data-ocid="history-run-item"
                className={`w-full flex items-center gap-3 px-4 py-2.5 text-left text-xs border-b border-border/50 last:border-0 hover:bg-secondary/50 transition-smooth ${
                  selectedRunId === run.runId
                    ? "bg-accent/5 border-accent/20"
                    : ""
                }`}
              >
                <div className="flex-1 min-w-0">
                  <div className="font-mono text-foreground truncate text-[11px]">
                    {run.capabilityName ?? "All Capabilities"}
                  </div>
                  <div className="text-muted-foreground text-[10px] mt-0.5">
                    {new Date(
                      Number(run.startedAt) / 1_000_000,
                    ).toLocaleString()}
                  </div>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <span className="text-emerald-400 font-mono text-[10px]">
                    ✓{Number(run.passed)}
                  </span>
                  <span className="text-destructive font-mono text-[10px]">
                    ✗{Number(run.failed)}
                  </span>
                </div>
              </button>
            ))
          )}
        </div>
      )}
    </div>
  );
}

// ── Capability row ──────────────────────────────────────────────────────────
type SortField = "status" | "name" | "lastRun";
type SortDir = "asc" | "desc";

const STATUS_SORT_ORDER: Record<StatusVariant, number> = {
  all_fail: 0,
  fail: 0,
  some_fail: 1,
  never_run: 2,
  all_pass: 3,
  pass: 3,
};

function CapabilityRow({
  cap,
  isSelected,
  isRunning,
  onClick,
  onRunTests,
}: {
  cap: CapabilityTestStatus;
  isSelected: boolean;
  isRunning: boolean;
  onClick: () => void;
  onRunTests: (e: React.MouseEvent) => void;
}) {
  return (
    <button
      type="button"
      className={`group w-full flex items-center gap-3 px-4 py-3 border-b border-border/50 cursor-pointer transition-smooth hover:bg-secondary/30 text-left ${
        isSelected
          ? "bg-accent/5 border-l-2 border-l-accent"
          : "border-l-2 border-l-transparent"
      }`}
      onClick={onClick}
      data-ocid="capability-row"
    >
      {/* Name + category */}
      <div className="flex-1 min-w-0">
        <div className="font-mono text-[12px] text-foreground truncate">
          {cap.capabilityName}
        </div>
        <div className="mt-0.5 text-[10px] text-muted-foreground truncate">
          {cap.category}
        </div>
      </div>

      {/* Status */}
      <div className="shrink-0 hidden sm:block">
        <StatusBadge status={cap.status} />
      </div>

      {/* Pass / Fail counts */}
      <div className="shrink-0 flex items-center gap-2 text-[11px] font-mono hidden md:flex">
        <span className="text-emerald-400">{Number(cap.passed)}</span>
        <span className="text-muted-foreground">/</span>
        <span className="text-destructive">{Number(cap.failed)}</span>
      </div>

      {/* Last run */}
      <div className="shrink-0 hidden lg:block text-[10px] text-muted-foreground font-mono w-28 text-right">
        {cap.lastRunAt
          ? new Date(Number(cap.lastRunAt) / 1_000_000).toLocaleTimeString()
          : "—"}
      </div>

      {/* Run button */}
      <button
        type="button"
        onClick={onRunTests}
        disabled={isRunning}
        data-ocid="btn-run-capability-tests"
        className={`shrink-0 flex items-center gap-1.5 px-2.5 py-1 rounded text-[10px] font-mono border transition-smooth ${
          isRunning
            ? "text-muted-foreground border-border cursor-not-allowed"
            : "text-muted-foreground border-border hover:border-accent hover:text-accent"
        }`}
        aria-label={`Run tests for ${cap.capabilityName}`}
      >
        {isRunning ? (
          <Loader2 size={11} className="animate-spin" />
        ) : (
          <Play size={11} />
        )}
        <span className="hidden sm:inline">
          {isRunning ? "Running…" : "Run"}
        </span>
      </button>
    </button>
  );
}

// ── Main page ───────────────────────────────────────────────────────────────
export default function AdminValidationPage() {
  const { data: isAdmin, isPending: adminPending } = useAdminStatus();
  const { data: statuses = [], isPending: statusesPending } =
    useCapabilityTestStatuses();
  const { data: history = [] } = useTestHistory();
  const runAllMutation = useRunAllTests();
  const runCapabilityMutation = useRunCapabilityTests();

  const [selectedCap, setSelectedCap] = useState<string | null>(null);
  const [selectedRunId, setSelectedRunId] = useState<string | undefined>(
    undefined,
  );
  const [runningCap, setRunningCap] = useState<string | null>(null);
  const [sortField, setSortField] = useState<SortField>("status");
  const [sortDir, setSortDir] = useState<SortDir>("asc");

  // Most recent "run all" for global export — prefer history entry with no capabilityName
  const latestGlobalRunId =
    history
      .filter((h) => !h.capabilityName)
      .sort((a, b) => Number(b.startedAt) - Number(a.startedAt))[0]?.runId ??
    null;
  const { data: latestGlobalRun } = useTestResults(latestGlobalRunId);

  // Derived summary stats
  const totalPass = statuses.reduce((s, c) => s + Number(c.passed), 0);
  const totalFail = statuses.reduce((s, c) => s + Number(c.failed), 0);
  const neverRun = statuses.filter((c) => c.status === "never_run").length;

  // Sort capabilities
  const sorted = [...statuses].sort((a, b) => {
    let cmp = 0;
    if (sortField === "status") {
      cmp = STATUS_SORT_ORDER[a.status] - STATUS_SORT_ORDER[b.status];
    } else if (sortField === "name") {
      cmp = a.capabilityName.localeCompare(b.capabilityName);
    } else if (sortField === "lastRun") {
      const at = Number(a.lastRunAt ?? 0);
      const bt = Number(b.lastRunAt ?? 0);
      cmp = at - bt;
    }
    return sortDir === "asc" ? cmp : -cmp;
  });

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortField(field);
      setSortDir("asc");
    }
  };

  const handleRunAll = async () => {
    try {
      const result = await runAllMutation.mutateAsync();
      setSelectedCap("All Capabilities");
      setSelectedRunId(result.runId);
    } catch {}
  };

  const handleRunCapability = async (e: React.MouseEvent, capName: string) => {
    e.stopPropagation();
    setRunningCap(capName);
    try {
      const result = await runCapabilityMutation.mutateAsync(capName);
      setSelectedCap(capName);
      setSelectedRunId(result.runId);
    } catch {
    } finally {
      setRunningCap(null);
    }
  };

  const handleSelectCap = (cap: CapabilityTestStatus) => {
    if (selectedCap === cap.capabilityName) {
      setSelectedCap(null);
      setSelectedRunId(undefined);
    } else {
      setSelectedCap(cap.capabilityName);
      // Find latest run for this cap from history
      const latestRun = history
        .filter((h) => h.capabilityName === cap.capabilityName)
        .sort((a, b) => Number(b.startedAt) - Number(a.startedAt))[0];
      setSelectedRunId(latestRun?.runId);
    }
  };

  const handleSelectHistoryRun = (runId: string, capName: string) => {
    setSelectedCap(capName);
    setSelectedRunId(runId);
  };

  // Loading state
  if (adminPending) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <Loader2 size={20} className="animate-spin text-muted-foreground" />
      </div>
    );
  }

  // Access denied
  if (!isAdmin) {
    return (
      <div
        className="flex-1 flex flex-col items-center justify-center gap-4 text-center px-4"
        data-ocid="access-denied-view"
      >
        <ShieldOff size={36} className="text-muted-foreground opacity-40" />
        <div>
          <h2 className="font-display text-lg font-semibold text-foreground">
            Access Denied
          </h2>
          <p className="mt-1 text-sm text-muted-foreground font-body max-w-xs">
            The Validation Dashboard is restricted to admin users only.
          </p>
        </div>
        <Link
          to="/capabilities"
          className="btn-secondary text-sm"
          data-ocid="link-back-capabilities"
        >
          ← Back to Capabilities
        </Link>
      </div>
    );
  }

  const runAllRunning = runAllMutation.isPending;

  return (
    <div
      className="flex flex-col h-full overflow-hidden"
      data-ocid="admin-validation-page"
    >
      {/* ── Section 1: Header bar ─────────────────────────────────────────── */}
      <div className="flex items-center gap-4 px-4 py-3 bg-card border-b border-border shrink-0 flex-wrap gap-y-2">
        <div className="flex items-center gap-2.5">
          <Shield size={16} className="text-accent shrink-0" />
          <h1 className="font-display text-sm font-semibold text-foreground tracking-tight">
            Validation Dashboard
          </h1>
        </div>

        {/* Summary stats */}
        <div className="flex items-center gap-4 text-[11px] font-mono ml-2">
          <span className="text-muted-foreground">
            <span className="text-foreground font-semibold">
              {statuses.length}
            </span>{" "}
            capabilities
          </span>
          <span className="text-emerald-400">
            <span className="font-semibold">{totalPass}</span> passed
          </span>
          <span className="text-destructive">
            <span className="font-semibold">{totalFail}</span> failed
          </span>
          {neverRun > 0 && (
            <span className="text-muted-foreground">
              <span className="font-semibold">{neverRun}</span> never run
            </span>
          )}
          {runAllRunning && (
            <span className="text-accent flex items-center gap-1">
              <Loader2 size={10} className="animate-spin" />
              Running all tests…
            </span>
          )}
        </div>

        {/* Run All button + Export */}
        <div className="ml-auto flex items-center gap-2">
          {latestGlobalRun && (
            <ExportFailedButton results={latestGlobalRun.results} />
          )}
          <Button
            size="sm"
            onClick={handleRunAll}
            disabled={runAllRunning}
            data-ocid="btn-run-all-tests"
            className="font-mono text-xs gap-1.5"
          >
            {runAllRunning ? (
              <>
                <Loader2 size={12} className="animate-spin" />
                Running…
              </>
            ) : (
              <>
                <Play size={12} />
                Run All Tests
              </>
            )}
          </Button>
        </div>
      </div>

      {/* ── Body: capability list + results panel ─────────────────────────── */}
      <div className="flex flex-1 min-h-0 overflow-hidden">
        {/* Capability list */}
        <div
          className={`flex flex-col overflow-hidden transition-all duration-200 ${
            selectedCap ? "w-full lg:w-1/2 xl:w-[55%]" : "w-full"
          }`}
        >
          {/* Table header */}
          <div className="flex items-center gap-3 px-4 py-2 bg-muted/20 border-b border-border shrink-0 text-[10px] font-mono text-muted-foreground">
            <div className="flex-1 min-w-0">
              <button
                type="button"
                onClick={() => handleSort("name")}
                className="flex items-center gap-1 hover:text-foreground transition-smooth"
                data-ocid="sort-by-name"
              >
                CAPABILITY
                {sortField === "name" &&
                  (sortDir === "asc" ? (
                    <ChevronUp size={10} />
                  ) : (
                    <ChevronDown size={10} />
                  ))}
              </button>
            </div>
            <div className="shrink-0 hidden sm:block w-24">
              <button
                type="button"
                onClick={() => handleSort("status")}
                className="flex items-center gap-1 hover:text-foreground transition-smooth"
                data-ocid="sort-by-status"
              >
                STATUS
                {sortField === "status" &&
                  (sortDir === "asc" ? (
                    <ChevronUp size={10} />
                  ) : (
                    <ChevronDown size={10} />
                  ))}
              </button>
            </div>
            <div className="shrink-0 hidden md:block w-16 text-center">
              P / F
            </div>
            <div className="shrink-0 hidden lg:block w-28 text-right">
              <button
                type="button"
                onClick={() => handleSort("lastRun")}
                className="flex items-center gap-1 hover:text-foreground transition-smooth ml-auto"
                data-ocid="sort-by-last-run"
              >
                LAST RUN
                {sortField === "lastRun" &&
                  (sortDir === "asc" ? (
                    <ChevronUp size={10} />
                  ) : (
                    <ChevronDown size={10} />
                  ))}
              </button>
            </div>
            <div className="shrink-0 w-16" />
          </div>

          {/* Capability rows */}
          <div className="flex-1 overflow-y-auto" data-ocid="capability-list">
            {statusesPending ? (
              ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"].map((k) => (
                <div
                  key={`skel-cap-${k}`}
                  className="px-4 py-3 border-b border-border/50"
                >
                  <Skeleton className="h-4 w-40 mb-1" />
                  <Skeleton className="h-3 w-24" />
                </div>
              ))
            ) : sorted.length === 0 ? (
              <div
                className="flex flex-col items-center justify-center h-64 text-center px-6"
                data-ocid="empty-state-no-tests"
              >
                <Shield
                  size={32}
                  className="text-muted-foreground opacity-30 mb-3"
                />
                <p className="text-sm font-mono text-muted-foreground">
                  No tests run yet.
                </p>
                <p className="text-xs text-muted-foreground/60 mt-1 max-w-64">
                  Click{" "}
                  <span className="text-accent font-semibold">
                    Run All Tests
                  </span>{" "}
                  to validate all 42 capabilities.
                </p>
              </div>
            ) : (
              sorted.map((cap) => (
                <CapabilityRow
                  key={cap.capabilityName}
                  cap={cap}
                  isSelected={selectedCap === cap.capabilityName}
                  isRunning={runningCap === cap.capabilityName}
                  onClick={() => handleSelectCap(cap)}
                  onRunTests={(e) => handleRunCapability(e, cap.capabilityName)}
                />
              ))
            )}
          </div>

          {/* ── Section 4: Test History ──────────────────────────────────── */}
          <TestHistoryPanel
            history={history}
            onSelectRun={handleSelectHistoryRun}
            selectedRunId={selectedRunId}
          />
        </div>

        {/* ── Section 3: Test Results Panel ─────────────────────────────── */}
        {selectedCap && (
          <div className="hidden lg:flex flex-col flex-1 min-w-0 overflow-hidden border-l border-border">
            <TestResultsPanel
              capabilityName={selectedCap}
              runId={selectedRunId}
              onClose={() => {
                setSelectedCap(null);
                setSelectedRunId(undefined);
              }}
            />
          </div>
        )}
      </div>

      {/* Mobile: Results panel as overlay */}
      {selectedCap && (
        <div
          className="lg:hidden fixed inset-0 z-50 flex flex-col bg-background"
          data-ocid="mobile-results-overlay"
        >
          <TestResultsPanel
            capabilityName={selectedCap}
            runId={selectedRunId}
            onClose={() => {
              setSelectedCap(null);
              setSelectedRunId(undefined);
            }}
          />
        </div>
      )}
    </div>
  );
}
