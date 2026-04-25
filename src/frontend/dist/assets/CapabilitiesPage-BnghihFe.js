import { c as createLucideIcon, u as useCapabilities, r as reactExports, j as jsxRuntimeExports, S as Search, a as useNavigate } from "./index-BZePS1Zd.js";
import { B as Badge } from "./badge-Bs3SiHuZ.js";
import { S as Skeleton } from "./skeleton-P84x8m6O.js";
import { C as ChevronDown } from "./chevron-down-64yA3Omb.js";
import "./index-DYfQEczc.js";
import "./utils-2v2HxlWs.js";
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const __iconNode = [
  ["path", { d: "M5 12h14", key: "1ays0h" }],
  ["path", { d: "m12 5 7 7-7 7", key: "xquz4c" }]
];
const ArrowRight = createLucideIcon("arrow-right", __iconNode);
const CATEGORY_COLORS = {
  Web: "text-chart-1 border-chart-1/30",
  Documents: "text-chart-2 border-chart-2/30",
  Data: "text-chart-3 border-chart-3/30",
  Transform: "text-chart-4 border-chart-4/30",
  Search: "text-chart-5 border-chart-5/30",
  Storage: "text-accent border-accent/30",
  Compute: "text-primary border-primary/30",
  Files: "text-chart-1 border-chart-1/30",
  Validation: "text-destructive border-destructive/30",
  Formatting: "text-chart-2 border-chart-2/30",
  Decision: "text-chart-3 border-chart-3/30",
  Meta: "text-chart-4 border-chart-4/30"
};
const CATEGORIES = [
  "All",
  "Web",
  "Documents",
  "Data",
  "Transform",
  "Search",
  "Storage",
  "Compute",
  "Files",
  "Validation",
  "Formatting",
  "Decision",
  "Meta"
];
const SKELETON_KEYS = [
  "s1",
  "s2",
  "s3",
  "s4",
  "s5",
  "s6",
  "s7",
  "s8",
  "s9",
  "s10"
];
function CapabilityCard({ cap }) {
  const navigate = useNavigate();
  const colorClass = CATEGORY_COLORS[cap.category] ?? "text-muted-foreground border-border";
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "button",
    {
      type: "button",
      onClick: () => navigate({ to: "/capabilities/$name", params: { name: cap.name } }),
      "data-ocid": "capability-card",
      className: "group w-full text-left p-4 border-b border-border hover:bg-secondary/60 transition-smooth active:bg-secondary/80",
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-start justify-between gap-3 mb-1.5", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "font-mono text-sm text-foreground group-hover:text-accent transition-smooth", children: [
            cap.name,
            /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-muted-foreground/40", children: "()" })
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsx(
            ArrowRight,
            {
              size: 13,
              className: "shrink-0 text-muted-foreground/30 group-hover:text-accent group-hover:translate-x-0.5 transition-smooth mt-0.5"
            }
          )
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-2 mb-2", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(
            Badge,
            {
              variant: "outline",
              className: `text-[10px] px-1.5 py-0 font-mono border ${colorClass}`,
              children: cap.category
            }
          ),
          /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-[10px] font-mono text-muted-foreground/40", children: [
            cap.inputs.length,
            "in · ",
            cap.outputs.length,
            "out"
          ] })
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs text-muted-foreground font-body line-clamp-2", children: cap.description })
      ]
    }
  );
}
function CapabilityRow({ cap }) {
  const navigate = useNavigate();
  const colorClass = CATEGORY_COLORS[cap.category] ?? "text-muted-foreground border-border";
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "button",
    {
      type: "button",
      onClick: () => navigate({ to: "/capabilities/$name", params: { name: cap.name } }),
      "data-ocid": "capability-row",
      className: "group w-full text-left flex items-center gap-4 px-5 py-3 border-b border-border hover:bg-secondary/60 transition-smooth",
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "w-56 shrink-0 font-mono text-sm text-foreground truncate group-hover:text-accent transition-smooth", children: [
          cap.name,
          /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-muted-foreground/40", children: "()" })
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "w-36 shrink-0", children: /* @__PURE__ */ jsxRuntimeExports.jsx(
          Badge,
          {
            variant: "outline",
            className: `text-xs px-1.5 py-0 font-mono border ${colorClass}`,
            children: cap.category
          }
        ) }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "flex-1 min-w-0 text-xs text-muted-foreground font-body truncate", children: cap.description }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "shrink-0 text-xs text-muted-foreground/40 font-mono w-20 text-right", children: [
          cap.inputs.length,
          "in · ",
          cap.outputs.length,
          "out"
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx(
          ArrowRight,
          {
            size: 13,
            className: "shrink-0 text-muted-foreground/30 group-hover:text-accent group-hover:translate-x-0.5 transition-smooth"
          }
        )
      ]
    }
  );
}
function CapabilitiesPage() {
  const { data: capabilities, isPending: isLoading } = useCapabilities();
  const [search, setSearch] = reactExports.useState("");
  const [category, setCategory] = reactExports.useState("All");
  const [filterOpen, setFilterOpen] = reactExports.useState(false);
  const availableCategories = CATEGORIES.filter(
    (cat) => cat === "All" || (capabilities ?? []).some((c) => c.category === cat)
  );
  const filtered = (capabilities ?? []).filter((c) => {
    const q = search.toLowerCase();
    const matchSearch = !search || c.name.toLowerCase().includes(q) || c.description.toLowerCase().includes(q);
    const matchCat = category === "All" || c.category === category;
    return matchSearch && matchCat;
  });
  return /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex flex-col h-full", children: [
    /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "border-b border-border px-4 md:px-6 py-4 bg-card flex items-center justify-between gap-4 shrink-0", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx("h1", { className: "font-display text-sm font-semibold text-foreground", children: "Capabilities" }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs text-muted-foreground font-body mt-0.5 hidden sm:block", children: "Deterministic, schema-typed canister methods callable by any AI agent." })
      ] }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "font-mono text-xs text-muted-foreground shrink-0", children: isLoading ? "—" : `${(capabilities ?? []).length} total` })
    ] }),
    /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "border-b border-border px-4 md:px-6 py-3 bg-card shrink-0 hidden md:flex items-center gap-3 flex-wrap", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "relative flex-1 max-w-xs", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx(
          Search,
          {
            size: 12,
            className: "absolute left-2.5 top-1/2 -translate-y-1/2 text-muted-foreground pointer-events-none"
          }
        ),
        /* @__PURE__ */ jsxRuntimeExports.jsx(
          "input",
          {
            type: "text",
            placeholder: "Search by name or description…",
            value: search,
            onChange: (e) => setSearch(e.target.value),
            "data-ocid": "search-capabilities",
            className: "w-full pl-7 pr-3 py-1.5 text-xs bg-secondary/40 border border-input rounded font-body text-foreground placeholder:text-muted-foreground/40 focus:outline-none focus:ring-1 focus:ring-ring transition-smooth"
          }
        )
      ] }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "flex gap-1 flex-wrap", "data-ocid": "category-filter", children: availableCategories.map((cat) => /* @__PURE__ */ jsxRuntimeExports.jsx(
        "button",
        {
          type: "button",
          onClick: () => setCategory(cat),
          className: [
            "px-2 py-0.5 text-xs rounded border transition-smooth font-mono whitespace-nowrap",
            category === cat ? "border-accent/50 bg-accent/10 text-accent" : "border-border text-muted-foreground hover:text-foreground hover:border-border/80"
          ].join(" "),
          children: cat
        },
        cat
      )) })
    ] }),
    /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "border-b border-border px-4 py-3 bg-card shrink-0 md:hidden space-y-2", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "relative w-full", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx(
          Search,
          {
            size: 12,
            className: "absolute left-2.5 top-1/2 -translate-y-1/2 text-muted-foreground pointer-events-none"
          }
        ),
        /* @__PURE__ */ jsxRuntimeExports.jsx(
          "input",
          {
            type: "text",
            placeholder: "Search capabilities…",
            value: search,
            onChange: (e) => setSearch(e.target.value),
            "data-ocid": "search-capabilities-mobile",
            className: "w-full pl-7 pr-3 py-2 text-xs bg-secondary/40 border border-input rounded font-body text-foreground placeholder:text-muted-foreground/40 focus:outline-none focus:ring-1 focus:ring-ring transition-smooth"
          }
        )
      ] }),
      /* @__PURE__ */ jsxRuntimeExports.jsxs(
        "button",
        {
          type: "button",
          onClick: () => setFilterOpen((v) => !v),
          className: "flex items-center gap-1.5 text-xs font-mono text-muted-foreground hover:text-foreground transition-smooth",
          "data-ocid": "toggle-category-filter",
          children: [
            /* @__PURE__ */ jsxRuntimeExports.jsx(
              ChevronDown,
              {
                size: 12,
                className: `transition-transform duration-150 ${filterOpen ? "rotate-180" : ""}`
              }
            ),
            category === "All" ? "Filter by category" : `Category: ${category}`
          ]
        }
      ),
      filterOpen && /* @__PURE__ */ jsxRuntimeExports.jsx(
        "div",
        {
          className: "flex flex-wrap gap-1.5 pt-1",
          "data-ocid": "category-filter-mobile",
          children: availableCategories.map((cat) => /* @__PURE__ */ jsxRuntimeExports.jsx(
            "button",
            {
              type: "button",
              onClick: () => {
                setCategory(cat);
                setFilterOpen(false);
              },
              className: [
                "px-2 py-1 text-xs rounded border transition-smooth font-mono whitespace-nowrap min-h-[36px]",
                category === cat ? "border-accent/50 bg-accent/10 text-accent" : "border-border text-muted-foreground hover:text-foreground"
              ].join(" "),
              children: cat
            },
            cat
          ))
        }
      )
    ] }),
    /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "border-b border-border px-5 py-2 bg-secondary/20 shrink-0 hidden md:flex items-center gap-4", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "w-56 shrink-0 text-xs font-mono text-muted-foreground/60 uppercase tracking-widest", children: "Method" }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "w-36 shrink-0 text-xs font-mono text-muted-foreground/60 uppercase tracking-widest", children: "Category" }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "flex-1 text-xs font-mono text-muted-foreground/60 uppercase tracking-widest", children: "Description" }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "w-20 text-right text-xs font-mono text-muted-foreground/60 uppercase tracking-widest", children: "Schema" }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "w-4" })
    ] }),
    /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "flex-1 overflow-y-auto", "data-ocid": "capabilities-list", children: isLoading ? /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "p-4 md:p-5 space-y-2", children: SKELETON_KEYS.map((k) => /* @__PURE__ */ jsxRuntimeExports.jsx(Skeleton, { className: "h-10 w-full rounded" }, k)) }) : filtered.length === 0 ? /* @__PURE__ */ jsxRuntimeExports.jsxs(
      "div",
      {
        className: "flex flex-col items-center justify-center h-64 text-center p-6",
        "data-ocid": "capabilities-empty",
        children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "font-mono text-3xl text-muted-foreground/15 mb-3", children: "∅" }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-sm text-muted-foreground font-body", children: "No capabilities found" }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs text-muted-foreground/50 font-mono mt-1", children: "Try a different search or filter" })
        ]
      }
    ) : /* @__PURE__ */ jsxRuntimeExports.jsxs(jsxRuntimeExports.Fragment, { children: [
      /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "md:hidden", children: filtered.map((cap) => /* @__PURE__ */ jsxRuntimeExports.jsx(CapabilityCard, { cap }, cap.name)) }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "hidden md:block", children: filtered.map((cap) => /* @__PURE__ */ jsxRuntimeExports.jsx(CapabilityRow, { cap }, cap.name)) })
    ] }) }),
    /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "border-t border-border px-4 md:px-6 py-2 bg-card shrink-0", children: /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-xs text-muted-foreground font-mono", children: isLoading ? "Loading…" : `${filtered.length} of ${(capabilities ?? []).length} capabilities` }) })
  ] });
}
export {
  CapabilitiesPage as default
};
