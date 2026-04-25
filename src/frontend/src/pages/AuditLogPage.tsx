import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuditLog } from "@/hooks/useBackend";
import type { AuditEvent, AuditEventType } from "@/types";
import {
  AlertTriangle,
  ChevronLeft,
  ChevronRight,
  Key,
  Shield,
  Terminal,
  XCircle,
} from "lucide-react";
import { useState } from "react";

// ── Event type config ─────────────────────────────────────────────────────────

const EVENT_CONFIG: Record<
  AuditEventType,
  { label: string; className: string; icon: React.ReactNode }
> = {
  key_used: {
    label: "key used",
    className: "border-accent/30 text-accent bg-accent/8",
    icon: <Terminal size={10} />,
  },
  key_generated: {
    label: "key generated",
    className: "border-blue-400/30 text-blue-400 bg-blue-400/8",
    icon: <Key size={10} />,
  },
  key_revoked: {
    label: "key revoked",
    className: "border-destructive/30 text-destructive bg-destructive/8",
    icon: <XCircle size={10} />,
  },
  auth_failed: {
    label: "auth failed",
    className: "border-yellow-400/30 text-yellow-400 bg-yellow-400/8",
    icon: <AlertTriangle size={10} />,
  },
  rate_limited: {
    label: "rate limited",
    className: "border-orange-400/30 text-orange-400 bg-orange-400/8",
    icon: <AlertTriangle size={10} />,
  },
};

const ALL_EVENT_TYPES: AuditEventType[] = [
  "key_used",
  "key_generated",
  "key_revoked",
  "auth_failed",
  "rate_limited",
];

// ── Utils ─────────────────────────────────────────────────────────────────────

function formatTimestamp(ns: bigint): string {
  const ms = Number(ns / 1_000_000n);
  return new Date(ms).toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

function relativeTime(ns: bigint): string {
  const ms = Number(ns / 1_000_000n);
  const diff = Date.now() - ms;
  const sec = Math.floor(diff / 1000);
  if (sec < 60) return `${sec}s ago`;
  const min = Math.floor(sec / 60);
  if (min < 60) return `${min}m ago`;
  const hr = Math.floor(min / 60);
  if (hr < 24) return `${hr}h ago`;
  return `${Math.floor(hr / 24)}d ago`;
}

function maskId(id: string): string {
  if (id.length <= 8) return id;
  return `${id.slice(0, 8)}…`;
}

// ── Event type badge ─────────────────────────────────────────────────────────

function EventTypeBadge({ type }: { type: AuditEventType }) {
  const cfg = EVENT_CONFIG[type];
  return (
    <Badge
      variant="outline"
      className={`text-[10px] h-5 px-1.5 font-mono gap-1 ${cfg.className}`}
    >
      {cfg.icon}
      {cfg.label}
    </Badge>
  );
}

// ── Desktop table row ─────────────────────────────────────────────────────────

function EventTableRow({ event }: { event: AuditEvent }) {
  const isFailure =
    event.eventType === "auth_failed" ||
    event.eventType === "key_revoked" ||
    event.eventType === "rate_limited";
  return (
    <tr
      className="border-b border-border/50 last:border-0 hover:bg-secondary/20 transition-colors duration-100"
      data-ocid={`audit-row-${event.id}`}
    >
      <td className="px-4 py-3 font-mono text-[11px] text-muted-foreground whitespace-nowrap">
        <span title={formatTimestamp(event.timestamp)}>
          {relativeTime(event.timestamp)}
        </span>
      </td>
      <td className="px-4 py-3">
        <EventTypeBadge type={event.eventType} />
      </td>
      <td className="px-4 py-3 font-mono text-[11px] text-muted-foreground">
        {maskId(event.userId)}
      </td>
      <td className="px-4 py-3">
        <div className="flex items-center gap-1.5">
          {isFailure && (
            <XCircle size={11} className="text-destructive shrink-0" />
          )}
          <span className="text-[11px] font-body text-muted-foreground truncate max-w-[400px]">
            {event.details}
          </span>
        </div>
      </td>
    </tr>
  );
}

// ── Mobile event card ─────────────────────────────────────────────────────────

function EventCard({ event }: { event: AuditEvent }) {
  const isFailure =
    event.eventType === "auth_failed" ||
    event.eventType === "key_revoked" ||
    event.eventType === "rate_limited";
  return (
    <div
      className="border border-border rounded-md bg-card p-3 space-y-2"
      data-ocid={`audit-card-${event.id}`}
    >
      <div className="flex items-center justify-between gap-2">
        <EventTypeBadge type={event.eventType} />
        <span className="text-[10px] font-mono text-muted-foreground/60">
          {relativeTime(event.timestamp)}
        </span>
      </div>
      <div className="flex items-start gap-1.5">
        {isFailure && (
          <XCircle size={11} className="text-destructive shrink-0 mt-0.5" />
        )}
        <p className="text-[11px] font-body text-muted-foreground leading-relaxed break-words min-w-0">
          {event.details}
        </p>
      </div>
      <div className="text-[10px] font-mono text-muted-foreground/40">
        {maskId(event.userId)} · {formatTimestamp(event.timestamp)}
      </div>
    </div>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

const PAGE_SIZE = 25;

export default function AuditLogPage() {
  const [page, setPage] = useState(0);
  const [typeFilter, setTypeFilter] = useState<AuditEventType | "all">("all");

  const { data: events, isPending } = useAuditLog(PAGE_SIZE, page * PAGE_SIZE);

  const filtered =
    typeFilter === "all"
      ? (events ?? [])
      : (events ?? []).filter((e) => e.eventType === typeFilter);

  const hasNext = (events?.length ?? 0) === PAGE_SIZE;
  const hasPrev = page > 0;

  return (
    <div className="flex-1 overflow-y-auto">
      {/* Header */}
      <div className="border-b border-border bg-card px-4 md:px-6 py-4">
        <div className="flex items-start justify-between gap-4 flex-wrap">
          <div>
            <div className="flex items-center gap-2 mb-0.5">
              <Shield size={14} className="text-accent" />
              <h1 className="text-base font-display font-semibold text-foreground tracking-tight">
                Audit Log
              </h1>
            </div>
            <p className="text-xs text-muted-foreground font-body max-w-lg">
              Execution history and authentication events. All activity logged
              against your principal.
            </p>
          </div>

          {/* Filter */}
          <div className="flex items-center gap-2 shrink-0">
            <label
              htmlFor="audit-type-filter"
              className="text-[10px] font-mono text-muted-foreground/60 uppercase tracking-wider"
            >
              Filter
            </label>
            <select
              id="audit-type-filter"
              value={typeFilter}
              onChange={(e) => {
                setTypeFilter(e.target.value as AuditEventType | "all");
                setPage(0);
              }}
              data-ocid="audit-type-filter"
              className="px-2.5 py-1.5 text-xs bg-secondary/40 border border-input rounded font-mono text-foreground focus:outline-none focus:ring-1 focus:ring-ring transition-smooth"
            >
              <option value="all">All events</option>
              {ALL_EVENT_TYPES.map((t) => (
                <option key={t} value={t}>
                  {EVENT_CONFIG[t].label}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      <div className="px-4 md:px-6 py-5 space-y-4">
        {/* Loading */}
        {isPending && (
          <div className="space-y-2" data-ocid="audit-loading">
            {[1, 2, 3, 4, 5].map((i) => (
              <Skeleton key={i} className="h-12 w-full rounded" />
            ))}
          </div>
        )}

        {/* Empty state */}
        {!isPending && filtered.length === 0 && (
          <div
            className="flex flex-col items-center justify-center py-20 text-center"
            data-ocid="audit-empty"
          >
            <div className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center mb-4">
              <Shield size={18} className="text-muted-foreground/40" />
            </div>
            <h3 className="text-sm font-display font-semibold text-foreground mb-1.5">
              No audit events yet
            </h3>
            <p className="text-xs text-muted-foreground max-w-xs font-body">
              {typeFilter === "all"
                ? "Generate or use an API key to see events here."
                : `No "${EVENT_CONFIG[typeFilter].label}" events found. Try a different filter.`}
            </p>
          </div>
        )}

        {/* Desktop table */}
        {!isPending && filtered.length > 0 && (
          <>
            <div
              className="hidden md:block border border-border rounded-md overflow-hidden"
              data-ocid="audit-table"
            >
              <table className="w-full text-xs">
                <thead>
                  <tr className="border-b border-border bg-secondary/50">
                    <th className="text-left px-4 py-2.5 font-display font-medium text-muted-foreground whitespace-nowrap">
                      Time
                    </th>
                    <th className="text-left px-4 py-2.5 font-display font-medium text-muted-foreground">
                      Event
                    </th>
                    <th className="text-left px-4 py-2.5 font-display font-medium text-muted-foreground">
                      Principal
                    </th>
                    <th className="text-left px-4 py-2.5 font-display font-medium text-muted-foreground">
                      Details
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((event) => (
                    <EventTableRow key={event.id} event={event} />
                  ))}
                </tbody>
              </table>
            </div>

            {/* Mobile cards */}
            <div className="md:hidden space-y-2" data-ocid="audit-cards">
              {filtered.map((event) => (
                <EventCard key={event.id} event={event} />
              ))}
            </div>

            {/* Pagination */}
            <div className="flex items-center justify-between pt-2">
              <span className="text-[11px] font-mono text-muted-foreground/60">
                Page {page + 1} · {filtered.length} event
                {filtered.length !== 1 ? "s" : ""}
              </span>
              <div className="flex items-center gap-1">
                <button
                  type="button"
                  onClick={() => setPage((p) => p - 1)}
                  disabled={!hasPrev}
                  data-ocid="btn-audit-prev"
                  className="flex items-center gap-1 px-2.5 py-1.5 text-xs font-mono border border-border rounded hover:bg-secondary/50 transition-smooth disabled:opacity-30 disabled:cursor-not-allowed"
                >
                  <ChevronLeft size={12} />
                  Prev
                </button>
                <button
                  type="button"
                  onClick={() => setPage((p) => p + 1)}
                  disabled={!hasNext}
                  data-ocid="btn-audit-next"
                  className="flex items-center gap-1 px-2.5 py-1.5 text-xs font-mono border border-border rounded hover:bg-secondary/50 transition-smooth disabled:opacity-30 disabled:cursor-not-allowed"
                >
                  Next
                  <ChevronRight size={12} />
                </button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
