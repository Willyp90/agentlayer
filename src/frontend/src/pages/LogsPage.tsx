import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { useCapabilities, useExecutionLogs } from "@/hooks/useBackend";
import type { ExecutionLog } from "@/types";
import { format, formatDistanceToNow } from "date-fns";
import {
  ChevronDown,
  ChevronUp,
  ChevronsUpDown,
  ClipboardCopy,
  Download,
  Filter,
  SlidersHorizontal,
} from "lucide-react";
import React, { useCallback, useMemo, useState } from "react";

type SortField = "timestamp" | "latency" | "capability";
type SortDir = "asc" | "desc";

function truncate(s: string, len: number) {
  return s.length <= len ? s : `${s.slice(0, len)}…`;
}

function nsToMs(ns: bigint) {
  return Number(ns / 1_000_000n);
}

function nsToDate(ns: bigint) {
  return new Date(Number(ns / 1_000_000n));
}

function exportCSV(logs: ExecutionLog[]) {
  const header =
    "execution_id,capability,user,success,timestamp,latency_ms,error_code,error_message";
  const rows = logs.map((l) => {
    const ts = nsToDate(l.timestamp).toISOString();
    const ms = nsToMs(l.latencyMs);
    const cells = [
      `"${l.executionId}"`,
      `"${l.capability}"`,
      `"${l.user}"`,
      l.success ? "true" : "false",
      ts,
      ms,
      l.errorCode ? `"${l.errorCode}"` : "",
      l.errorMessage ? `"${l.errorMessage.replace(/"/g, '""')}"` : "",
    ];
    return cells.join(",");
  });
  const csv = [header, ...rows].join("\n");
  const blob = new Blob([csv], { type: "text/csv" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `execution-logs-${Date.now()}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

const SKELETON_ROW_IDS = [
  "sk-row-a",
  "sk-row-b",
  "sk-row-c",
  "sk-row-d",
  "sk-row-e",
  "sk-row-f",
  "sk-row-g",
  "sk-row-h",
] as const;

function SkeletonRows() {
  return (
    <>
      {SKELETON_ROW_IDS.map((id) => (
        <tr key={id} className="border-b border-border">
          <td className="px-3 py-2">
            <Skeleton className="h-3 w-28" />
          </td>
          <td className="px-3 py-2">
            <Skeleton className="h-3 w-32" />
          </td>
          <td className="px-3 py-2 hidden md:table-cell">
            <Skeleton className="h-3 w-24" />
          </td>
          <td className="px-3 py-2">
            <Skeleton className="h-4 w-10 rounded-full" />
          </td>
          <td className="px-3 py-2 hidden sm:table-cell">
            <Skeleton className="h-3 w-20" />
          </td>
          <td className="px-3 py-2 flex justify-end">
            <Skeleton className="h-3 w-10" />
          </td>
        </tr>
      ))}
    </>
  );
}

function SortIcon({
  field,
  active,
  dir,
}: { field: SortField; active: SortField; dir: SortDir }) {
  if (active !== field)
    return <ChevronsUpDown className="inline w-3 h-3 ml-1 opacity-30" />;
  return dir === "asc" ? (
    <ChevronUp className="inline w-3 h-3 ml-1 opacity-80" />
  ) : (
    <ChevronDown className="inline w-3 h-3 ml-1 opacity-80" />
  );
}

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);
  const handleCopy = useCallback(async () => {
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      const el = document.createElement("textarea");
      el.value = text;
      el.style.cssText = "position:fixed;top:-9999px;left:-9999px;opacity:0;";
      document.body.appendChild(el);
      el.focus();
      el.select();
      document.execCommand("copy");
      document.body.removeChild(el);
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  }, [text]);
  return (
    <button
      type="button"
      onClick={handleCopy}
      aria-label="Copy to clipboard"
      className="flex items-center gap-1 text-muted-foreground hover:text-foreground transition-colors duration-200"
    >
      <ClipboardCopy className="w-3 h-3" />
      {copied && <span className="text-[10px]">copied</span>}
    </button>
  );
}

function prettyJSON(raw: string | null | undefined): string | null {
  if (!raw) return null;
  try {
    return JSON.stringify(JSON.parse(raw), null, 2);
  } catch {
    return raw;
  }
}

// ── Desktop expanded row ──────────────────────────────────────────────────────

function ExpandedRow({ log, colSpan }: { log: ExecutionLog; colSpan: number }) {
  const prettyInput = prettyJSON(log.input);
  const prettyOutput = prettyJSON(log.output);
  const ts = nsToDate(log.timestamp);

  return (
    <tr className="bg-card border-b border-border">
      <td colSpan={colSpan} className="px-4 py-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
          <div className="space-y-3">
            <div>
              <span className="text-muted-foreground uppercase tracking-widest text-[10px] font-mono">
                Execution ID
              </span>
              <p className="font-mono text-foreground mt-0.5 break-all select-all text-[11px]">
                {log.executionId}
              </p>
            </div>
            <div>
              <span className="text-muted-foreground uppercase tracking-widest text-[10px] font-mono">
                User Principal
              </span>
              <p className="font-mono text-foreground mt-0.5 break-all select-all text-[11px]">
                {log.user}
              </p>
            </div>
            <div>
              <span className="text-muted-foreground uppercase tracking-widest text-[10px] font-mono">
                Capability
              </span>
              <p className="font-mono text-foreground mt-0.5 text-[11px]">
                {log.capability}
              </p>
            </div>
            <div className="flex gap-6 flex-wrap">
              <div>
                <span className="text-muted-foreground uppercase tracking-widest text-[10px] font-mono">
                  Timestamp
                </span>
                <p className="font-mono text-foreground mt-0.5 text-[11px]">
                  {format(ts, "yyyy-MM-dd HH:mm:ss.SSS")}
                </p>
              </div>
              <div>
                <span className="text-muted-foreground uppercase tracking-widest text-[10px] font-mono">
                  Latency
                </span>
                <p className="font-mono text-foreground mt-0.5 text-[11px]">
                  {nsToMs(log.latencyMs).toLocaleString()} ms
                </p>
              </div>
            </div>
            {!log.success && (log.errorCode || log.errorMessage) && (
              <div>
                <span className="text-muted-foreground uppercase tracking-widest text-[10px] font-mono">
                  Error
                </span>
                <p className="font-mono text-destructive mt-0.5 text-[11px]">
                  {log.errorCode && `[${log.errorCode}] `}
                  {log.errorMessage}
                </p>
              </div>
            )}
          </div>
          <div className="space-y-3">
            <div>
              <div className="flex items-center justify-between mb-1">
                <span className="text-muted-foreground uppercase tracking-widest text-[10px] font-mono">
                  Input
                </span>
                {prettyInput && <CopyButton text={prettyInput} />}
              </div>
              <pre className="font-mono text-[11px] leading-relaxed bg-background border border-border rounded p-2 overflow-x-auto max-h-40 text-foreground">
                {prettyInput ?? (
                  <span className="text-muted-foreground">null</span>
                )}
              </pre>
            </div>
            <div>
              <div className="flex items-center justify-between mb-1">
                <span className="text-muted-foreground uppercase tracking-widest text-[10px] font-mono">
                  {log.success ? "Output" : "Error Detail"}
                </span>
                {prettyOutput && <CopyButton text={prettyOutput} />}
              </div>
              <pre className="font-mono text-[11px] leading-relaxed bg-background border border-border rounded p-2 overflow-x-auto max-h-40 text-foreground">
                {prettyOutput ?? (
                  <span className="text-muted-foreground">null</span>
                )}
              </pre>
            </div>
          </div>
        </div>
      </td>
    </tr>
  );
}

// ── Mobile log card ───────────────────────────────────────────────────────────

function MobileLogCard({
  log,
  expanded,
  onToggle,
}: {
  log: ExecutionLog;
  expanded: boolean;
  onToggle: () => void;
}) {
  const ts = nsToDate(log.timestamp);
  const prettyInput = prettyJSON(log.input);
  const prettyOutput = prettyJSON(log.output);

  return (
    <div className="border-b border-border">
      <button
        type="button"
        onClick={onToggle}
        className={`w-full text-left px-4 py-3 transition-colors duration-150 ${expanded ? "bg-card" : "hover:bg-muted/40"}`}
        data-ocid="logs-mobile-card"
      >
        <div className="flex items-center justify-between gap-2 mb-1.5">
          <span className="font-mono text-[10px] text-muted-foreground">
            {formatDistanceToNow(ts, { addSuffix: true })}
          </span>
          <div className="flex items-center gap-2">
            <Badge
              variant="outline"
              className={`font-mono text-[10px] px-1.5 py-0 h-4 rounded-sm ${
                log.success
                  ? "border-chart-2/40 text-chart-2 bg-chart-2/10"
                  : "border-destructive/40 text-destructive bg-destructive/10"
              }`}
            >
              {log.success ? "ok" : "err"}
            </Badge>
            <span className="font-mono text-[10px] text-muted-foreground bg-secondary px-1.5 py-0.5 rounded">
              {nsToMs(log.latencyMs).toLocaleString()}ms
            </span>
            <ChevronDown
              size={12}
              className={`text-muted-foreground transition-transform duration-150 ${expanded ? "rotate-180" : ""}`}
            />
          </div>
        </div>
        <div className="font-mono text-xs text-foreground">
          {log.capability}
        </div>
        <div className="font-mono text-[10px] text-muted-foreground mt-0.5">
          {truncate(log.executionId, 16)}
        </div>
      </button>
      {expanded && (
        <div className="px-4 pb-4 bg-card space-y-3 text-xs">
          <div>
            <span className="text-muted-foreground uppercase tracking-widest text-[10px] font-mono">
              User
            </span>
            <p className="font-mono text-foreground mt-0.5 break-all text-[11px]">
              {log.user}
            </p>
          </div>
          {!log.success && (log.errorCode || log.errorMessage) && (
            <div>
              <span className="text-muted-foreground uppercase tracking-widest text-[10px] font-mono">
                Error
              </span>
              <p className="font-mono text-destructive mt-0.5 text-[11px]">
                {log.errorCode && `[${log.errorCode}] `}
                {log.errorMessage}
              </p>
            </div>
          )}
          <div>
            <div className="flex items-center justify-between mb-1">
              <span className="text-muted-foreground uppercase tracking-widest text-[10px] font-mono">
                Input
              </span>
              {prettyInput && <CopyButton text={prettyInput} />}
            </div>
            <pre className="font-mono text-[11px] bg-background border border-border rounded p-2 overflow-x-auto max-h-32 text-foreground">
              {prettyInput ?? (
                <span className="text-muted-foreground">null</span>
              )}
            </pre>
          </div>
          <div>
            <div className="flex items-center justify-between mb-1">
              <span className="text-muted-foreground uppercase tracking-widest text-[10px] font-mono">
                {log.success ? "Output" : "Error Detail"}
              </span>
              {prettyOutput && <CopyButton text={prettyOutput} />}
            </div>
            <pre className="font-mono text-[11px] bg-background border border-border rounded p-2 overflow-x-auto max-h-32 text-foreground">
              {prettyOutput ?? (
                <span className="text-muted-foreground">null</span>
              )}
            </pre>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Main page ─────────────────────────────────────────────────────────────────

const PAGE_SIZE = 50;

export default function LogsPage() {
  const [capabilityFilter, setCapabilityFilter] = useState<string>("all");
  const [statusFilter, setStatusFilter] = useState<
    "all" | "success" | "failed"
  >("all");
  const [search, setSearch] = useState("");
  const [sortField, setSortField] = useState<SortField>("timestamp");
  const [sortDir, setSortDir] = useState<SortDir>("desc");
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [filtersOpen, setFiltersOpen] = useState(false);

  const { data: capabilities } = useCapabilities();

  const filter = useMemo(
    () => ({
      capability: capabilityFilter !== "all" ? capabilityFilter : undefined,
      successOnly: statusFilter === "success" ? true : undefined,
      failureOnly: statusFilter === "failed" ? true : undefined,
      limit: PAGE_SIZE,
      offset: page * PAGE_SIZE,
    }),
    [capabilityFilter, statusFilter, page],
  );

  const { data: logs, isLoading } = useExecutionLogs(filter);

  const filtered = useMemo(() => {
    const src = logs ?? [];
    const q = search.trim().toLowerCase();
    const searched = q
      ? src.filter(
          (l) =>
            l.executionId.toLowerCase().includes(q) ||
            l.capability.toLowerCase().includes(q),
        )
      : src;

    return [...searched].sort((a, b) => {
      let cmp = 0;
      if (sortField === "timestamp")
        cmp =
          a.timestamp > b.timestamp ? 1 : a.timestamp < b.timestamp ? -1 : 0;
      else if (sortField === "latency")
        cmp =
          a.latencyMs > b.latencyMs ? 1 : a.latencyMs < b.latencyMs ? -1 : 0;
      else if (sortField === "capability")
        cmp = a.capability.localeCompare(b.capability);
      return sortDir === "asc" ? cmp : -cmp;
    });
  }, [logs, search, sortField, sortDir]);

  function toggleSort(field: SortField) {
    if (sortField === field) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortField(field);
      setSortDir("desc");
    }
  }

  function toggleRow(id: string) {
    setExpandedId((prev) => (prev === id ? null : id));
  }

  const hasPrev = page > 0;
  const hasNext = (logs?.length ?? 0) === PAGE_SIZE;
  const activeFilters =
    (capabilityFilter !== "all" ? 1 : 0) + (statusFilter !== "all" ? 1 : 0);

  return (
    <div className="flex flex-col h-full min-h-0" data-ocid="logs-page">
      {/* Desktop filter bar */}
      <div className="border-b border-border bg-card px-4 py-2.5 hidden md:flex items-center gap-3 shrink-0 flex-wrap">
        <h1 className="font-mono text-xs font-semibold text-foreground tracking-tight shrink-0">
          Your Executions
        </h1>
        {!isLoading && (
          <span className="font-mono text-xs text-muted-foreground shrink-0">
            ({filtered.length})
          </span>
        )}
        <div className="flex-1" />
        <Input
          placeholder="Search ID or capability…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="h-7 text-xs font-mono w-52 bg-background"
          data-ocid="logs-search"
        />
        <Select value={capabilityFilter} onValueChange={setCapabilityFilter}>
          <SelectTrigger
            className="h-7 text-xs font-mono w-44 bg-background"
            data-ocid="logs-capability-filter"
          >
            <SelectValue placeholder="All capabilities" />
          </SelectTrigger>
          <SelectContent className="font-mono text-xs">
            <SelectItem value="all">All capabilities</SelectItem>
            {capabilities?.map((c) => (
              <SelectItem key={c.name} value={c.name}>
                {c.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select
          value={statusFilter}
          onValueChange={(v) =>
            setStatusFilter(v as "all" | "success" | "failed")
          }
        >
          <SelectTrigger
            className="h-7 text-xs font-mono w-28 bg-background"
            data-ocid="logs-status-filter"
          >
            <SelectValue />
          </SelectTrigger>
          <SelectContent className="font-mono text-xs">
            <SelectItem value="all">All</SelectItem>
            <SelectItem value="success">Success</SelectItem>
            <SelectItem value="failed">Failed</SelectItem>
          </SelectContent>
        </Select>
        <Button
          variant="outline"
          size="sm"
          className="h-7 text-xs font-mono gap-1.5 shrink-0"
          onClick={() => exportCSV(filtered)}
          disabled={filtered.length === 0}
          data-ocid="logs-export-csv"
        >
          <Download className="w-3 h-3" />
          Export CSV
        </Button>
      </div>

      {/* Mobile header + filter toggle */}
      <div className="border-b border-border bg-card px-4 py-3 md:hidden shrink-0 space-y-2">
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <h1 className="font-mono text-xs font-semibold text-foreground tracking-tight">
              Your Executions
            </h1>
            {!isLoading && (
              <span className="font-mono text-xs text-muted-foreground">
                ({filtered.length})
              </span>
            )}
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => setFiltersOpen((v) => !v)}
              data-ocid="logs-filter-toggle"
              className="flex items-center gap-1.5 px-2.5 py-1.5 text-xs font-mono border border-border rounded text-muted-foreground hover:text-foreground hover:border-foreground/30 transition-smooth min-h-[44px]"
            >
              <SlidersHorizontal size={12} />
              Filters
              {activeFilters > 0 && (
                <span className="w-4 h-4 rounded-full bg-accent text-background text-[9px] flex items-center justify-center font-mono">
                  {activeFilters}
                </span>
              )}
            </button>
            <Button
              variant="outline"
              size="sm"
              className="h-9 text-xs font-mono gap-1.5 shrink-0"
              onClick={() => exportCSV(filtered)}
              disabled={filtered.length === 0}
              data-ocid="logs-export-csv-mobile"
            >
              <Download className="w-3 h-3" />
            </Button>
          </div>
        </div>
        <Input
          placeholder="Search ID or capability…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="h-9 text-xs font-mono w-full bg-background"
          data-ocid="logs-search-mobile"
        />
        {filtersOpen && (
          <div className="flex flex-col gap-2 pt-1">
            <Select
              value={capabilityFilter}
              onValueChange={setCapabilityFilter}
            >
              <SelectTrigger
                className="h-9 text-xs font-mono w-full bg-background"
                data-ocid="logs-capability-filter-mobile"
              >
                <SelectValue placeholder="All capabilities" />
              </SelectTrigger>
              <SelectContent className="font-mono text-xs">
                <SelectItem value="all">All capabilities</SelectItem>
                {capabilities?.map((c) => (
                  <SelectItem key={c.name} value={c.name}>
                    {c.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Select
              value={statusFilter}
              onValueChange={(v) =>
                setStatusFilter(v as "all" | "success" | "failed")
              }
            >
              <SelectTrigger
                className="h-9 text-xs font-mono w-full bg-background"
                data-ocid="logs-status-filter-mobile"
              >
                <SelectValue />
              </SelectTrigger>
              <SelectContent className="font-mono text-xs">
                <SelectItem value="all">All statuses</SelectItem>
                <SelectItem value="success">Success only</SelectItem>
                <SelectItem value="failed">Failed only</SelectItem>
              </SelectContent>
            </Select>
          </div>
        )}
      </div>

      {/* Desktop table */}
      <div className="flex-1 overflow-auto min-h-0 hidden md:block">
        <table className="w-full text-xs border-collapse">
          <thead className="sticky top-0 z-10 bg-card border-b border-border">
            <tr>
              <th className="px-3 py-2 text-left font-mono text-[10px] uppercase tracking-widest text-muted-foreground font-normal w-36">
                Execution ID
              </th>
              <th className="px-3 py-2 text-left font-mono text-[10px] uppercase tracking-widest text-muted-foreground font-normal">
                <button
                  type="button"
                  className="flex items-center gap-0.5 hover:text-foreground transition-colors duration-150 select-none"
                  onClick={() => toggleSort("capability")}
                  data-ocid="logs-sort-capability"
                >
                  Capability
                  <SortIcon
                    field="capability"
                    active={sortField}
                    dir={sortDir}
                  />
                </button>
              </th>
              <th className="px-3 py-2 text-left font-mono text-[10px] uppercase tracking-widest text-muted-foreground font-normal w-32">
                User
              </th>
              <th className="px-3 py-2 text-left font-mono text-[10px] uppercase tracking-widest text-muted-foreground font-normal w-16">
                Status
              </th>
              <th className="px-3 py-2 text-left font-mono text-[10px] uppercase tracking-widest text-muted-foreground font-normal w-36">
                <button
                  type="button"
                  className="flex items-center gap-0.5 hover:text-foreground transition-colors duration-150 select-none"
                  onClick={() => toggleSort("timestamp")}
                  data-ocid="logs-sort-timestamp"
                >
                  Timestamp
                  <SortIcon
                    field="timestamp"
                    active={sortField}
                    dir={sortDir}
                  />
                </button>
              </th>
              <th className="px-3 py-2 text-right font-mono text-[10px] uppercase tracking-widest text-muted-foreground font-normal w-20">
                <button
                  type="button"
                  className="flex items-center justify-end gap-0.5 w-full hover:text-foreground transition-colors duration-150 select-none"
                  onClick={() => toggleSort("latency")}
                  data-ocid="logs-sort-latency"
                >
                  Latency
                  <SortIcon field="latency" active={sortField} dir={sortDir} />
                </button>
              </th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <SkeletonRows />
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-4 py-20 text-center">
                  <div
                    className="flex flex-col items-center gap-3"
                    data-ocid="logs-empty-state"
                  >
                    <span className="font-mono text-3xl text-muted-foreground/20">
                      [ ]
                    </span>
                    <p className="font-mono text-xs text-muted-foreground">
                      No executions yet — run a capability in the Playground
                    </p>
                  </div>
                </td>
              </tr>
            ) : (
              filtered.map((log) => {
                const ts = nsToDate(log.timestamp);
                const isExpanded = expandedId === log.executionId;
                return (
                  <React.Fragment key={log.executionId}>
                    <tr
                      className={`border-b border-border cursor-pointer transition-colors duration-150 ${
                        isExpanded ? "bg-card" : "hover:bg-muted/40"
                      }`}
                      onClick={() => toggleRow(log.executionId)}
                      onKeyDown={(e) =>
                        e.key === "Enter" && toggleRow(log.executionId)
                      }
                      tabIndex={0}
                      data-ocid="logs-row"
                    >
                      <td className="px-3 py-2 font-mono text-[11px] text-muted-foreground">
                        {truncate(log.executionId, 12)}
                      </td>
                      <td className="px-3 py-2 font-mono text-[11px] text-foreground">
                        {log.capability}
                      </td>
                      <td className="px-3 py-2 font-mono text-[11px] text-muted-foreground">
                        {truncate(log.user, 14)}
                      </td>
                      <td className="px-3 py-2">
                        {log.success ? (
                          <Badge
                            variant="outline"
                            className="font-mono text-[10px] px-1.5 py-0 h-4 border-chart-2/40 text-chart-2 bg-chart-2/10 rounded-sm"
                          >
                            ok
                          </Badge>
                        ) : (
                          <Badge
                            variant="outline"
                            className="font-mono text-[10px] px-1.5 py-0 h-4 border-destructive/40 text-destructive bg-destructive/10 rounded-sm"
                          >
                            err
                          </Badge>
                        )}
                      </td>
                      <td
                        className="px-3 py-2 font-mono text-[11px] text-muted-foreground"
                        title={format(ts, "yyyy-MM-dd HH:mm:ss.SSS z")}
                      >
                        {formatDistanceToNow(ts, { addSuffix: true })}
                      </td>
                      <td className="px-3 py-2 font-mono text-[11px] text-muted-foreground text-right">
                        {nsToMs(log.latencyMs).toLocaleString()}
                        <span className="text-muted-foreground/40 ml-0.5 text-[10px]">
                          ms
                        </span>
                      </td>
                    </tr>
                    {isExpanded && (
                      <ExpandedRow
                        key={`${log.executionId}-expanded`}
                        log={log}
                        colSpan={6}
                      />
                    )}
                  </React.Fragment>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Mobile card list */}
      <div
        className="flex-1 overflow-auto min-h-0 md:hidden"
        data-ocid="logs-mobile-list"
      >
        {isLoading ? (
          <div className="p-4 space-y-2">
            {SKELETON_ROW_IDS.map((id) => (
              <Skeleton key={id} className="h-16 w-full rounded" />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div
            className="flex flex-col items-center justify-center h-64 text-center p-6"
            data-ocid="logs-empty-state-mobile"
          >
            <span className="font-mono text-3xl text-muted-foreground/20 mb-3">
              [ ]
            </span>
            <p className="font-mono text-xs text-muted-foreground">
              No executions yet — run a capability in the Playground
            </p>
          </div>
        ) : (
          filtered.map((log) => (
            <MobileLogCard
              key={log.executionId}
              log={log}
              expanded={expandedId === log.executionId}
              onToggle={() => toggleRow(log.executionId)}
            />
          ))
        )}
      </div>

      {/* Pagination */}
      {!isLoading && (logs?.length ?? 0) > 0 && (
        <div className="border-t border-border bg-card px-4 py-2 flex items-center justify-between shrink-0">
          <span className="font-mono text-[10px] text-muted-foreground">
            Page {page + 1} · {filtered.length} row
            {filtered.length !== 1 ? "s" : ""}
          </span>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              className="h-7 text-[10px] font-mono px-2 min-h-[44px] md:min-h-0"
              disabled={!hasPrev}
              onClick={() => setPage((p) => p - 1)}
              data-ocid="logs-prev-page"
            >
              ← prev
            </Button>
            <Button
              variant="outline"
              size="sm"
              className="h-7 text-[10px] font-mono px-2 min-h-[44px] md:min-h-0"
              disabled={!hasNext}
              onClick={() => setPage((p) => p + 1)}
              data-ocid="logs-next-page"
            >
              next →
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
