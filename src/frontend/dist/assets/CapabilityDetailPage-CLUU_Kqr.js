import { c as createLucideIcon, b as useParams, d as useCapability, a as useNavigate, j as jsxRuntimeExports, e as Shield } from "./index-BZePS1Zd.js";
import { B as Badge } from "./badge-Bs3SiHuZ.js";
import { B as Button } from "./button-C9yg-6tA.js";
import { S as Skeleton } from "./skeleton-P84x8m6O.js";
import { E as ExternalLink } from "./external-link-CZfckXfP.js";
import "./index-DYfQEczc.js";
import "./utils-2v2HxlWs.js";
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const __iconNode = [
  ["path", { d: "m12 19-7-7 7-7", key: "1l729n" }],
  ["path", { d: "M19 12H5", key: "x3x0zl" }]
];
const ArrowLeft = createLucideIcon("arrow-left", __iconNode);
const CATEGORY_COLORS = {
  Web: "text-chart-1 border-chart-1/30",
  "Documents/Text": "text-chart-2 border-chart-2/30",
  "Data/Parsing": "text-chart-3 border-chart-3/30",
  "Data Transformation": "text-chart-4 border-chart-4/30",
  Search: "text-chart-5 border-chart-5/30",
  Storage: "text-accent border-accent/30",
  Compute: "text-primary border-primary/30",
  "File Ops": "text-chart-1 border-chart-1/30",
  Validation: "text-destructive border-destructive/30",
  Formatting: "text-chart-2 border-chart-2/30",
  Decision: "text-chart-3 border-chart-3/30",
  Meta: "text-chart-4 border-chart-4/30"
};
const TYPE_COLORS = {
  string: "text-chart-2 border-chart-2/20 bg-chart-2/5",
  number: "text-chart-5 border-chart-5/20 bg-chart-5/5",
  integer: "text-chart-5 border-chart-5/20 bg-chart-5/5",
  boolean: "text-chart-1 border-chart-1/20 bg-chart-1/5",
  array: "text-chart-3 border-chart-3/20 bg-chart-3/5",
  object: "text-chart-4 border-chart-4/20 bg-chart-4/5"
};
function TypeBadge({ type }) {
  const cls = TYPE_COLORS[type] ?? "text-muted-foreground border-border bg-secondary/40";
  return /* @__PURE__ */ jsxRuntimeExports.jsx(
    "span",
    {
      className: `inline-flex items-center text-[10px] font-mono px-1.5 py-0.5 rounded border ${cls}`,
      children: type
    }
  );
}
function SchemaLabel({ label }) {
  return /* @__PURE__ */ jsxRuntimeExports.jsx("h3", { className: "text-xs font-mono text-muted-foreground uppercase tracking-widest mb-3", children: label });
}
function InputsTable({ inputs }) {
  if (inputs.length === 0) {
    return /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "border border-border rounded px-4 py-3 text-xs text-muted-foreground/50 font-mono", children: "no inputs" });
  }
  return /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "border border-border rounded overflow-hidden", children: /* @__PURE__ */ jsxRuntimeExports.jsxs("table", { className: "w-full text-xs", children: [
    /* @__PURE__ */ jsxRuntimeExports.jsx("thead", { children: /* @__PURE__ */ jsxRuntimeExports.jsxs("tr", { className: "border-b border-border bg-secondary/30", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal w-40", children: "field" }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal w-28", children: "type" }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal w-24", children: "required" }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal", children: "description" })
    ] }) }),
    /* @__PURE__ */ jsxRuntimeExports.jsx("tbody", { children: inputs.map((inp) => /* @__PURE__ */ jsxRuntimeExports.jsxs(
      "tr",
      {
        className: "border-b border-border last:border-0 hover:bg-secondary/20 transition-smooth",
        children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3 font-mono text-foreground", children: inp.key }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3", children: /* @__PURE__ */ jsxRuntimeExports.jsx(TypeBadge, { type: inp.inputType }) }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3 font-mono", children: inp.required ? /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-[10px] px-1.5 py-0.5 rounded border border-destructive/30 text-destructive/80 bg-destructive/5 font-mono", children: "required" }) : /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-[10px] px-1.5 py-0.5 rounded border border-border text-muted-foreground/50 bg-secondary/30 font-mono", children: "optional" }) }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3 text-muted-foreground font-body leading-relaxed", children: inp.description || /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-muted-foreground/30", children: "—" }) })
        ]
      },
      inp.key
    )) })
  ] }) });
}
function OutputsTable({ outputs }) {
  if (outputs.length === 0) {
    return /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "border border-border rounded px-4 py-3 text-xs text-muted-foreground/50 font-mono", children: "no outputs" });
  }
  return /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "border border-border rounded overflow-hidden", children: /* @__PURE__ */ jsxRuntimeExports.jsxs("table", { className: "w-full text-xs", children: [
    /* @__PURE__ */ jsxRuntimeExports.jsx("thead", { children: /* @__PURE__ */ jsxRuntimeExports.jsxs("tr", { className: "border-b border-border bg-secondary/30", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal w-40", children: "field" }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal w-28", children: "type" }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal", children: "description" })
    ] }) }),
    /* @__PURE__ */ jsxRuntimeExports.jsx("tbody", { children: outputs.map((out) => /* @__PURE__ */ jsxRuntimeExports.jsxs(
      "tr",
      {
        className: "border-b border-border last:border-0 hover:bg-secondary/20 transition-smooth",
        children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3 font-mono text-foreground", children: out.key }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3", children: /* @__PURE__ */ jsxRuntimeExports.jsx(TypeBadge, { type: out.outputType }) }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3 text-muted-foreground font-body leading-relaxed", children: out.description || /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-muted-foreground/30", children: "—" }) })
        ]
      },
      out.key
    )) })
  ] }) });
}
function CodeBlock({ title, code }) {
  let pretty = code;
  try {
    pretty = JSON.stringify(JSON.parse(code), null, 2);
  } catch {
  }
  return /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex flex-col min-w-0", children: [
    /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "flex items-center gap-2 px-3 py-2 border border-border rounded-t bg-secondary/30 border-b-0", children: /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-[10px] font-mono text-muted-foreground/70 uppercase tracking-wider", children: title }) }),
    /* @__PURE__ */ jsxRuntimeExports.jsx("pre", { className: "font-mono text-xs p-4 border border-border rounded-b bg-secondary/10 text-foreground overflow-x-auto leading-relaxed whitespace-pre-wrap break-all", children: pretty })
  ] });
}
const SKELETON_SECTION_KEYS = ["sk-a", "sk-b", "sk-c"];
function CapabilityDetailPage() {
  const { name } = useParams({ from: "/capabilities/$name" });
  const { data: cap, isPending: isLoading } = useCapability(name);
  const navigate = useNavigate();
  const colorClass = cap ? CATEGORY_COLORS[cap.category] ?? "text-muted-foreground border-border" : "";
  return /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex flex-col h-full", children: [
    /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "border-b border-border px-6 py-3 bg-card flex items-center gap-3 shrink-0", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsxs(
        "button",
        {
          type: "button",
          onClick: () => navigate({ to: "/" }),
          "data-ocid": "back-to-capabilities",
          className: "flex items-center gap-1.5 text-xs text-muted-foreground hover:text-foreground transition-smooth font-mono",
          children: [
            /* @__PURE__ */ jsxRuntimeExports.jsx(ArrowLeft, { size: 12 }),
            "capabilities"
          ]
        }
      ),
      /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-muted-foreground/30", children: "/" }),
      isLoading ? /* @__PURE__ */ jsxRuntimeExports.jsx(Skeleton, { className: "h-4 w-32" }) : /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-xs font-mono text-foreground", children: [
        name,
        "()"
      ] })
    ] }),
    /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "flex-1 overflow-y-auto", children: isLoading ? /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "max-w-4xl mx-auto px-6 py-8 space-y-8", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "space-y-2", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx(Skeleton, { className: "h-7 w-64" }),
        /* @__PURE__ */ jsxRuntimeExports.jsx(Skeleton, { className: "h-4 w-96" })
      ] }),
      SKELETON_SECTION_KEYS.map((k) => /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "space-y-3", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx(Skeleton, { className: "h-3 w-20" }),
        /* @__PURE__ */ jsxRuntimeExports.jsx(Skeleton, { className: "h-24 w-full" })
      ] }, k))
    ] }) : !cap ? /* @__PURE__ */ jsxRuntimeExports.jsxs(
      "div",
      {
        className: "flex flex-col items-center justify-center h-64 text-center p-8",
        "data-ocid": "capability-not-found",
        children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "font-mono text-3xl text-muted-foreground/15 mb-3", children: "404" }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-sm text-muted-foreground font-body", children: "Capability not found" }),
          /* @__PURE__ */ jsxRuntimeExports.jsx(
            "button",
            {
              type: "button",
              onClick: () => navigate({ to: "/" }),
              className: "mt-3 text-xs text-accent font-mono hover:underline",
              children: "← back to list"
            }
          )
        ]
      }
    ) : /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "max-w-4xl mx-auto px-6 py-8 space-y-8", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-3 mb-3", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsxs("h1", { className: "font-display text-xl font-semibold text-foreground tracking-tight", children: [
            cap.name,
            /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-muted-foreground/40", children: "()" })
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsx(
            Badge,
            {
              variant: "outline",
              className: `font-mono text-xs border ${colorClass}`,
              children: cap.category
            }
          ),
          /* @__PURE__ */ jsxRuntimeExports.jsx(
            Badge,
            {
              variant: "outline",
              className: "font-mono text-xs border border-border text-muted-foreground/50",
              children: "v1.0.0"
            }
          )
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-sm text-foreground/80 font-body leading-relaxed max-w-2xl", children: cap.description }),
        cap.constraints.length > 0 && /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "mt-3 flex items-start gap-2", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(
            Shield,
            {
              size: 12,
              className: "text-muted-foreground/40 mt-0.5 shrink-0"
            }
          ),
          /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs text-muted-foreground/60 font-body leading-relaxed", children: cap.constraints.join(" · ") })
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "mt-5", children: /* @__PURE__ */ jsxRuntimeExports.jsxs(
          Button,
          {
            variant: "outline",
            size: "sm",
            "data-ocid": "open-in-playground",
            onClick: () => navigate({
              to: "/playground",
              search: { capability: cap.name }
            }),
            className: "font-mono text-xs border-accent/40 text-accent hover:bg-accent/10 hover:text-accent gap-1.5",
            children: [
              "Open in Playground",
              /* @__PURE__ */ jsxRuntimeExports.jsx(ExternalLink, { size: 11 })
            ]
          }
        ) })
      ] }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "border-t border-border" }),
      /* @__PURE__ */ jsxRuntimeExports.jsxs("section", { "data-ocid": "inputs-section", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx(SchemaLabel, { label: `Inputs (${cap.inputs.length})` }),
        /* @__PURE__ */ jsxRuntimeExports.jsx(InputsTable, { inputs: cap.inputs })
      ] }),
      /* @__PURE__ */ jsxRuntimeExports.jsxs("section", { "data-ocid": "outputs-section", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx(SchemaLabel, { label: `Outputs (${cap.outputs.length})` }),
        /* @__PURE__ */ jsxRuntimeExports.jsx(OutputsTable, { outputs: cap.outputs })
      ] }),
      cap.constraints.length > 0 && /* @__PURE__ */ jsxRuntimeExports.jsxs("section", { "data-ocid": "constraints-section", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx(SchemaLabel, { label: "Constraints" }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("ul", { className: "space-y-2", children: cap.constraints.map((c) => /* @__PURE__ */ jsxRuntimeExports.jsxs(
          "li",
          {
            className: "flex items-start gap-2.5 text-xs text-muted-foreground font-body",
            children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "mt-0.5 text-muted-foreground/30 font-mono shrink-0", children: "—" }),
              c
            ]
          },
          c
        )) })
      ] }),
      /* @__PURE__ */ jsxRuntimeExports.jsxs("section", { "data-ocid": "example-section", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx(SchemaLabel, { label: "Example" }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs text-muted-foreground/60 font-body mb-4 leading-relaxed", children: 'A representative invocation — use "Load Example" in the playground to pre-fill these exact values.' }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "grid grid-cols-1 md:grid-cols-2 gap-4", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(CodeBlock, { title: "Input", code: cap.exampleInput }),
          /* @__PURE__ */ jsxRuntimeExports.jsx(CodeBlock, { title: "Output", code: cap.exampleOutput })
        ] })
      ] }),
      /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "border-t border-border pt-6 flex items-center gap-3", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs(
          Button,
          {
            variant: "outline",
            size: "sm",
            "data-ocid": "open-in-playground-bottom",
            onClick: () => navigate({
              to: "/playground",
              search: { capability: cap.name }
            }),
            className: "font-mono text-xs border-accent/40 text-accent hover:bg-accent/10 hover:text-accent gap-1.5",
            children: [
              "Open in Playground",
              /* @__PURE__ */ jsxRuntimeExports.jsx(ExternalLink, { size: 11 })
            ]
          }
        ),
        /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-xs text-muted-foreground/40 font-body", children: "Test this capability live with the example above" })
      ] })
    ] }) })
  ] });
}
export {
  CapabilityDetailPage as default
};
