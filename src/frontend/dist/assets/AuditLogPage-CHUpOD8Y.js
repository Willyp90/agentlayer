import { r as reactExports, w as useAuditLog, j as jsxRuntimeExports, e as Shield, C as ChevronLeft, x as ChevronRight, y as CircleX, K as Key, T as Terminal } from "./index-BZePS1Zd.js";
import { B as Badge } from "./badge-Bs3SiHuZ.js";
import { S as Skeleton } from "./skeleton-P84x8m6O.js";
import { T as TriangleAlert } from "./triangle-alert-bjxhJeUs.js";
import "./index-DYfQEczc.js";
import "./utils-2v2HxlWs.js";
const EVENT_CONFIG = {
  capability_called: {
    label: "capability",
    className: "border-accent/30 text-accent bg-accent/8",
    icon: /* @__PURE__ */ jsxRuntimeExports.jsx(Terminal, { size: 10 })
  },
  key_generated: {
    label: "key generated",
    className: "border-blue-400/30 text-blue-400 bg-blue-400/8",
    icon: /* @__PURE__ */ jsxRuntimeExports.jsx(Key, { size: 10 })
  },
  key_revoked: {
    label: "key revoked",
    className: "border-destructive/30 text-destructive bg-destructive/8",
    icon: /* @__PURE__ */ jsxRuntimeExports.jsx(CircleX, { size: 10 })
  },
  auth_failed: {
    label: "auth failed",
    className: "border-yellow-400/30 text-yellow-400 bg-yellow-400/8",
    icon: /* @__PURE__ */ jsxRuntimeExports.jsx(TriangleAlert, { size: 10 })
  }
};
const ALL_EVENT_TYPES = [
  "capability_called",
  "key_generated",
  "key_revoked",
  "auth_failed"
];
function formatTimestamp(ns) {
  const ms = Number(ns / 1000000n);
  return new Date(ms).toLocaleString(void 0, {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit"
  });
}
function relativeTime(ns) {
  const ms = Number(ns / 1000000n);
  const diff = Date.now() - ms;
  const sec = Math.floor(diff / 1e3);
  if (sec < 60) return `${sec}s ago`;
  const min = Math.floor(sec / 60);
  if (min < 60) return `${min}m ago`;
  const hr = Math.floor(min / 60);
  if (hr < 24) return `${hr}h ago`;
  return `${Math.floor(hr / 24)}d ago`;
}
function maskId(id) {
  if (id.length <= 8) return id;
  return `${id.slice(0, 8)}…`;
}
function EventTypeBadge({ type }) {
  const cfg = EVENT_CONFIG[type];
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    Badge,
    {
      variant: "outline",
      className: `text-[10px] h-5 px-1.5 font-mono gap-1 ${cfg.className}`,
      children: [
        cfg.icon,
        cfg.label
      ]
    }
  );
}
function EventTableRow({ event }) {
  const isFailure = event.eventType === "auth_failed" || event.eventType === "key_revoked";
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "tr",
    {
      className: "border-b border-border/50 last:border-0 hover:bg-secondary/20 transition-colors duration-100",
      "data-ocid": `audit-row-${event.id}`,
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3 font-mono text-[11px] text-muted-foreground whitespace-nowrap", children: /* @__PURE__ */ jsxRuntimeExports.jsx("span", { title: formatTimestamp(event.timestamp), children: relativeTime(event.timestamp) }) }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3", children: /* @__PURE__ */ jsxRuntimeExports.jsx(EventTypeBadge, { type: event.eventType }) }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3 font-mono text-[11px] text-muted-foreground", children: maskId(event.userId) }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3", children: /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-1.5", children: [
          isFailure && /* @__PURE__ */ jsxRuntimeExports.jsx(CircleX, { size: 11, className: "text-destructive shrink-0" }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-[11px] font-body text-muted-foreground truncate max-w-[400px]", children: event.details })
        ] }) })
      ]
    }
  );
}
function EventCard({ event }) {
  const isFailure = event.eventType === "auth_failed" || event.eventType === "key_revoked";
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "div",
    {
      className: "border border-border rounded-md bg-card p-3 space-y-2",
      "data-ocid": `audit-card-${event.id}`,
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center justify-between gap-2", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(EventTypeBadge, { type: event.eventType }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-[10px] font-mono text-muted-foreground/60", children: relativeTime(event.timestamp) })
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-start gap-1.5", children: [
          isFailure && /* @__PURE__ */ jsxRuntimeExports.jsx(CircleX, { size: 11, className: "text-destructive shrink-0 mt-0.5" }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-[11px] font-body text-muted-foreground leading-relaxed break-words min-w-0", children: event.details })
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "text-[10px] font-mono text-muted-foreground/40", children: [
          maskId(event.userId),
          " · ",
          formatTimestamp(event.timestamp)
        ] })
      ]
    }
  );
}
const PAGE_SIZE = 25;
function AuditLogPage() {
  const [page, setPage] = reactExports.useState(0);
  const [typeFilter, setTypeFilter] = reactExports.useState("all");
  const { data: events, isPending } = useAuditLog(PAGE_SIZE, page * PAGE_SIZE);
  const filtered = typeFilter === "all" ? events ?? [] : (events ?? []).filter((e) => e.eventType === typeFilter);
  const hasNext = ((events == null ? void 0 : events.length) ?? 0) === PAGE_SIZE;
  const hasPrev = page > 0;
  return /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex-1 overflow-y-auto", children: [
    /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "border-b border-border bg-card px-4 md:px-6 py-4", children: /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-start justify-between gap-4 flex-wrap", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-2 mb-0.5", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(Shield, { size: 14, className: "text-accent" }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("h1", { className: "text-base font-display font-semibold text-foreground tracking-tight", children: "Audit Log" })
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs text-muted-foreground font-body max-w-lg", children: "Execution history and authentication events. All activity logged against your principal." })
      ] }),
      /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-2 shrink-0", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx(
          "label",
          {
            htmlFor: "audit-type-filter",
            className: "text-[10px] font-mono text-muted-foreground/60 uppercase tracking-wider",
            children: "Filter"
          }
        ),
        /* @__PURE__ */ jsxRuntimeExports.jsxs(
          "select",
          {
            id: "audit-type-filter",
            value: typeFilter,
            onChange: (e) => {
              setTypeFilter(e.target.value);
              setPage(0);
            },
            "data-ocid": "audit-type-filter",
            className: "px-2.5 py-1.5 text-xs bg-secondary/40 border border-input rounded font-mono text-foreground focus:outline-none focus:ring-1 focus:ring-ring transition-smooth",
            children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx("option", { value: "all", children: "All events" }),
              ALL_EVENT_TYPES.map((t) => /* @__PURE__ */ jsxRuntimeExports.jsx("option", { value: t, children: EVENT_CONFIG[t].label }, t))
            ]
          }
        )
      ] })
    ] }) }),
    /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "px-4 md:px-6 py-5 space-y-4", children: [
      isPending && /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "space-y-2", "data-ocid": "audit-loading", children: [1, 2, 3, 4, 5].map((i) => /* @__PURE__ */ jsxRuntimeExports.jsx(Skeleton, { className: "h-12 w-full rounded" }, i)) }),
      !isPending && filtered.length === 0 && /* @__PURE__ */ jsxRuntimeExports.jsxs(
        "div",
        {
          className: "flex flex-col items-center justify-center py-20 text-center",
          "data-ocid": "audit-empty",
          children: [
            /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "w-10 h-10 rounded-full bg-secondary flex items-center justify-center mb-4", children: /* @__PURE__ */ jsxRuntimeExports.jsx(Shield, { size: 18, className: "text-muted-foreground/40" }) }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("h3", { className: "text-sm font-display font-semibold text-foreground mb-1.5", children: "No audit events yet" }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs text-muted-foreground max-w-xs font-body", children: typeFilter === "all" ? "Generate or use an API key to see events here." : `No "${EVENT_CONFIG[typeFilter].label}" events found. Try a different filter.` })
          ]
        }
      ),
      !isPending && filtered.length > 0 && /* @__PURE__ */ jsxRuntimeExports.jsxs(jsxRuntimeExports.Fragment, { children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx(
          "div",
          {
            className: "hidden md:block border border-border rounded-md overflow-hidden",
            "data-ocid": "audit-table",
            children: /* @__PURE__ */ jsxRuntimeExports.jsxs("table", { className: "w-full text-xs", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx("thead", { children: /* @__PURE__ */ jsxRuntimeExports.jsxs("tr", { className: "border-b border-border bg-secondary/50", children: [
                /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "text-left px-4 py-2.5 font-display font-medium text-muted-foreground whitespace-nowrap", children: "Time" }),
                /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "text-left px-4 py-2.5 font-display font-medium text-muted-foreground", children: "Event" }),
                /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "text-left px-4 py-2.5 font-display font-medium text-muted-foreground", children: "Principal" }),
                /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "text-left px-4 py-2.5 font-display font-medium text-muted-foreground", children: "Details" })
              ] }) }),
              /* @__PURE__ */ jsxRuntimeExports.jsx("tbody", { children: filtered.map((event) => /* @__PURE__ */ jsxRuntimeExports.jsx(EventTableRow, { event }, event.id)) })
            ] })
          }
        ),
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "md:hidden space-y-2", "data-ocid": "audit-cards", children: filtered.map((event) => /* @__PURE__ */ jsxRuntimeExports.jsx(EventCard, { event }, event.id)) }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center justify-between pt-2", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-[11px] font-mono text-muted-foreground/60", children: [
            "Page ",
            page + 1,
            " · ",
            filtered.length,
            " event",
            filtered.length !== 1 ? "s" : ""
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-1", children: [
            /* @__PURE__ */ jsxRuntimeExports.jsxs(
              "button",
              {
                type: "button",
                onClick: () => setPage((p) => p - 1),
                disabled: !hasPrev,
                "data-ocid": "btn-audit-prev",
                className: "flex items-center gap-1 px-2.5 py-1.5 text-xs font-mono border border-border rounded hover:bg-secondary/50 transition-smooth disabled:opacity-30 disabled:cursor-not-allowed",
                children: [
                  /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronLeft, { size: 12 }),
                  "Prev"
                ]
              }
            ),
            /* @__PURE__ */ jsxRuntimeExports.jsxs(
              "button",
              {
                type: "button",
                onClick: () => setPage((p) => p + 1),
                disabled: !hasNext,
                "data-ocid": "btn-audit-next",
                className: "flex items-center gap-1 px-2.5 py-1.5 text-xs font-mono border border-border rounded hover:bg-secondary/50 transition-smooth disabled:opacity-30 disabled:cursor-not-allowed",
                children: [
                  "Next",
                  /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronRight, { size: 12 })
                ]
              }
            )
          ] })
        ] })
      ] })
    ] })
  ] });
}
export {
  AuditLogPage as default
};
