import { c as createLucideIcon, A as useAdminStatus, D as useCapabilityTestStatuses, E as useTestHistory, F as useRunAllTests, G as useRunCapabilityTests, r as reactExports, H as useTestResults, j as jsxRuntimeExports, L as Link, e as Shield, P as Play, y as CircleX, x as ChevronRight } from "./index-BZePS1Zd.js";
import { B as Button } from "./button-C9yg-6tA.js";
import { S as Skeleton } from "./skeleton-P84x8m6O.js";
import { L as LoaderCircle, C as CircleAlert, a as CircleCheck } from "./loader-circle-NET2nO5E.js";
import { C as ChevronUp, D as Download } from "./download-CfDMXayc.js";
import { C as ChevronDown } from "./chevron-down-64yA3Omb.js";
import { T as TriangleAlert } from "./triangle-alert-bjxhJeUs.js";
import { C as Clock } from "./clock-Bdm87zxc.js";
import "./index-DYfQEczc.js";
import "./utils-2v2HxlWs.js";
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const __iconNode$4 = [
  ["rect", { width: "8", height: "4", x: "8", y: "2", rx: "1", ry: "1", key: "tgr4d6" }],
  [
    "path",
    {
      d: "M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2",
      key: "116196"
    }
  ],
  ["path", { d: "m9 14 2 2 4-4", key: "df797q" }]
];
const ClipboardCheck = createLucideIcon("clipboard-check", __iconNode$4);
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const __iconNode$3 = [
  ["rect", { width: "8", height: "4", x: "8", y: "2", rx: "1", ry: "1", key: "tgr4d6" }],
  [
    "path",
    {
      d: "M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2",
      key: "116196"
    }
  ]
];
const Clipboard = createLucideIcon("clipboard", __iconNode$3);
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const __iconNode$2 = [
  [
    "path",
    {
      d: "M10 20a1 1 0 0 0 .553.895l2 1A1 1 0 0 0 14 21v-7a2 2 0 0 1 .517-1.341L21.74 4.67A1 1 0 0 0 21 3H3a1 1 0 0 0-.742 1.67l7.225 7.989A2 2 0 0 1 10 14z",
      key: "sc7q7i"
    }
  ]
];
const Funnel = createLucideIcon("funnel", __iconNode$2);
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const __iconNode$1 = [
  ["path", { d: "M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8", key: "1357e3" }],
  ["path", { d: "M3 3v5h5", key: "1xhq8a" }],
  ["path", { d: "M12 7v5l4 2", key: "1fdv2h" }]
];
const History = createLucideIcon("history", __iconNode$1);
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const __iconNode = [
  ["path", { d: "m2 2 20 20", key: "1ooewy" }],
  [
    "path",
    {
      d: "M5 5a1 1 0 0 0-1 1v7c0 5 3.5 7.5 7.67 8.94a1 1 0 0 0 .67.01c2.35-.82 4.48-1.97 5.9-3.71",
      key: "1jlk70"
    }
  ],
  [
    "path",
    {
      d: "M9.309 3.652A12.252 12.252 0 0 0 11.24 2.28a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1v7a9.784 9.784 0 0 1-.08 1.264",
      key: "18rp1v"
    }
  ]
];
const ShieldOff = createLucideIcon("shield-off", __iconNode);
function tryParseJson(raw) {
  try {
    return JSON.parse(raw);
  } catch {
    return raw;
  }
}
function buildExportPayload(results) {
  const failed = results.filter((r) => !r.passed);
  const capabilitySet = [...new Set(failed.map((r) => r.capabilityName))];
  return {
    exportedAt: (/* @__PURE__ */ new Date()).toISOString(),
    summary: {
      totalFailed: failed.length,
      capabilities: capabilitySet
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
      actualErrorCode: r.actualErrorCode ?? null
    }))
  };
}
function downloadJson(payload, filename) {
  const blob = new Blob([JSON.stringify(payload, null, 2)], {
    type: "application/json"
  });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
function todayFilename() {
  const d = /* @__PURE__ */ new Date();
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `agentlayer-failed-tests-${yyyy}-${mm}-${dd}.json`;
}
function ExportFailedButton({
  results,
  label = "Export Failed",
  compact = false
}) {
  const [copied, setCopied] = reactExports.useState(false);
  const failed = results.filter((r) => !r.passed);
  const payload = buildExportPayload(results);
  const handleDownload = reactExports.useCallback(() => {
    downloadJson(payload, todayFilename());
  }, [payload]);
  const handleCopy = reactExports.useCallback(async () => {
    var _a;
    const text = JSON.stringify(payload, null, 2);
    try {
      if ((_a = navigator.clipboard) == null ? void 0 : _a.writeText) {
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
      setTimeout(() => setCopied(false), 2e3);
    } catch {
    }
  }, [payload]);
  if (failed.length === 0) return null;
  return /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-1.5", "data-ocid": "export-failed-group", children: [
    /* @__PURE__ */ jsxRuntimeExports.jsxs(
      "button",
      {
        type: "button",
        onClick: handleDownload,
        "data-ocid": "btn-export-failed-download",
        className: `flex items-center gap-1.5 border border-destructive/30 text-destructive/80 hover:text-destructive hover:border-destructive/60 hover:bg-destructive/5 transition-smooth rounded font-mono font-medium ${compact ? "px-2 py-0.5 text-[10px]" : "px-2.5 py-1 text-[11px]"}`,
        title: "Download failed tests as JSON",
        children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(Download, { size: compact ? 10 : 11 }),
          !compact && /* @__PURE__ */ jsxRuntimeExports.jsx("span", { children: label }),
          compact && /* @__PURE__ */ jsxRuntimeExports.jsx("span", { children: label }),
          /* @__PURE__ */ jsxRuntimeExports.jsxs(
            "span",
            {
              className: `${compact ? "text-[9px]" : "text-[10px]"} opacity-60 font-normal`,
              children: [
                "(",
                failed.length,
                ")"
              ]
            }
          )
        ]
      }
    ),
    /* @__PURE__ */ jsxRuntimeExports.jsx(
      "button",
      {
        type: "button",
        onClick: handleCopy,
        "data-ocid": "btn-export-failed-copy",
        className: `flex items-center gap-1 border border-border text-muted-foreground hover:text-foreground hover:border-accent/40 hover:bg-muted/30 transition-smooth rounded font-mono ${compact ? "px-1.5 py-0.5 text-[10px]" : "px-2 py-1 text-[10px]"}`,
        title: "Copy JSON to clipboard",
        children: copied ? /* @__PURE__ */ jsxRuntimeExports.jsxs(jsxRuntimeExports.Fragment, { children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(
            ClipboardCheck,
            {
              size: compact ? 9 : 10,
              className: "text-emerald-400"
            }
          ),
          /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-emerald-400", children: "Copied!" })
        ] }) : /* @__PURE__ */ jsxRuntimeExports.jsxs(jsxRuntimeExports.Fragment, { children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(Clipboard, { size: compact ? 9 : 10 }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "hidden sm:inline", children: "Copy" })
        ] })
      }
    )
  ] });
}
const CATEGORY_LABELS = {
  RequiredFieldsOnly: "req-fields",
  OptionalFieldIndividual: "opt-field",
  OptionalFieldCombination: "opt-combo",
  MissingRequiredField: "missing-req",
  InvalidType: "invalid-type",
  EdgeCase: "edge-case",
  OutputSchema: "output-schema",
  Determinism: "determinism",
  ErrorHandling: "error-handling"
};
const CATEGORY_COLORS = {
  RequiredFieldsOnly: "bg-accent/10 text-accent border-accent/20",
  OptionalFieldIndividual: "bg-primary/10 text-primary border-primary/20",
  OptionalFieldCombination: "bg-primary/10 text-primary border-primary/20",
  MissingRequiredField: "bg-destructive/10 text-destructive border-destructive/20",
  InvalidType: "bg-destructive/10 text-destructive border-destructive/20",
  EdgeCase: "bg-muted text-muted-foreground border-border",
  OutputSchema: "bg-accent/10 text-accent border-accent/20",
  Determinism: "bg-secondary text-secondary-foreground border-border",
  ErrorHandling: "bg-muted text-muted-foreground border-border"
};
const STATUS_CONFIG = {
  never_run: {
    label: "Never Run",
    className: "bg-muted text-muted-foreground border-border",
    icon: /* @__PURE__ */ jsxRuntimeExports.jsx(Clock, { size: 11 })
  },
  all_pass: {
    label: "All Pass",
    className: "bg-emerald-500/10 text-emerald-400 border-emerald-500/20",
    icon: /* @__PURE__ */ jsxRuntimeExports.jsx(CircleCheck, { size: 11 })
  },
  // Backend alias for all_pass
  pass: {
    label: "All Pass",
    className: "bg-emerald-500/10 text-emerald-400 border-emerald-500/20",
    icon: /* @__PURE__ */ jsxRuntimeExports.jsx(CircleCheck, { size: 11 })
  },
  some_fail: {
    label: "Some Fail",
    className: "bg-amber-500/10 text-amber-400 border-amber-500/20",
    icon: /* @__PURE__ */ jsxRuntimeExports.jsx(TriangleAlert, { size: 11 })
  },
  // Backend alias for some_fail
  fail: {
    label: "Some Fail",
    className: "bg-amber-500/10 text-amber-400 border-amber-500/20",
    icon: /* @__PURE__ */ jsxRuntimeExports.jsx(TriangleAlert, { size: 11 })
  },
  all_fail: {
    label: "All Fail",
    className: "bg-destructive/10 text-destructive border-destructive/20",
    icon: /* @__PURE__ */ jsxRuntimeExports.jsx(CircleX, { size: 11 })
  }
};
function StatusBadge({ status }) {
  const config = STATUS_CONFIG[status] ?? STATUS_CONFIG.never_run;
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "span",
    {
      className: `inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-mono font-medium border ${config.className}`,
      children: [
        config.icon,
        config.label
      ]
    }
  );
}
function CategoryBadge({ category }) {
  return /* @__PURE__ */ jsxRuntimeExports.jsx(
    "span",
    {
      className: `inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-mono border ${CATEGORY_COLORS[category]}`,
      children: CATEGORY_LABELS[category]
    }
  );
}
function JsonBlock({ label, value }) {
  const [open, setOpen] = reactExports.useState(false);
  let pretty = value;
  try {
    pretty = JSON.stringify(JSON.parse(value), null, 2);
  } catch {
  }
  return /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "mt-2", children: [
    /* @__PURE__ */ jsxRuntimeExports.jsxs(
      "button",
      {
        type: "button",
        onClick: () => setOpen((p) => !p),
        className: "flex items-center gap-1.5 text-[10px] font-mono text-muted-foreground hover:text-foreground transition-colors",
        children: [
          open ? /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronDown, { size: 11 }) : /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronRight, { size: 11 }),
          label
        ]
      }
    ),
    open && /* @__PURE__ */ jsxRuntimeExports.jsx("pre", { className: "mt-1.5 code-block text-[10px] leading-relaxed max-h-40 overflow-auto whitespace-pre-wrap break-all", children: /* @__PURE__ */ jsxRuntimeExports.jsx("code", { children: pretty }) })
  ] });
}
function TestResultRow({ result }) {
  const [expanded, setExpanded] = reactExports.useState(false);
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "div",
    {
      className: `border border-border rounded text-xs transition-smooth ${result.passed ? "bg-card" : "bg-destructive/5 border-destructive/20"}`,
      "data-ocid": "test-result-row",
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs(
          "button",
          {
            type: "button",
            onClick: () => setExpanded((p) => !p),
            className: "w-full flex items-start gap-3 px-3 py-2.5 text-left",
            children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "mt-0.5 shrink-0", children: result.passed ? /* @__PURE__ */ jsxRuntimeExports.jsx(CircleCheck, { size: 14, className: "text-emerald-400" }) : /* @__PURE__ */ jsxRuntimeExports.jsx(CircleX, { size: 14, className: "text-destructive" }) }),
              /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "flex-1 min-w-0", children: [
                /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-foreground font-mono text-[11px] leading-snug block truncate", children: result.description }),
                !result.passed && result.failureReason && /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "mt-0.5 block text-destructive text-[10px] font-mono leading-snug", children: [
                  "↳ ",
                  result.failureReason
                ] })
              ] }),
              /* @__PURE__ */ jsxRuntimeExports.jsx(CategoryBadge, { category: result.category }),
              /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "shrink-0 text-muted-foreground font-mono text-[10px] ml-1", children: [
                Number(result.latencyMs),
                "ms"
              ] }),
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "shrink-0 ml-1 text-muted-foreground", children: expanded ? /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronDown, { size: 12 }) : /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronRight, { size: 12 }) })
            ]
          }
        ),
        expanded && /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "px-3 pb-3 border-t border-border/50", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(JsonBlock, { label: "Input", value: result.inputJson }),
          result.actualOutput && /* @__PURE__ */ jsxRuntimeExports.jsx(JsonBlock, { label: "Actual Output", value: result.actualOutput }),
          result.actualErrorCode && /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "mt-2 text-[10px] font-mono text-destructive", children: [
            "Error code: ",
            result.actualErrorCode
          ] })
        ] })
      ]
    }
  );
}
function TestResultsPanel({
  capabilityName,
  runId,
  onClose
}) {
  const [filter, setFilter] = reactExports.useState("all");
  const { data: run, isPending } = useTestResults(runId ?? null);
  const filtered = (run == null ? void 0 : run.results.filter((r) => {
    if (filter === "pass") return r.passed;
    if (filter === "fail") return !r.passed;
    return true;
  })) ?? [];
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "div",
    {
      className: "flex flex-col h-full bg-card border-l border-border",
      "data-ocid": "test-results-panel",
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center justify-between px-4 py-3 border-b border-border shrink-0", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "min-w-0", children: [
            /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "font-mono text-sm font-semibold text-foreground truncate", children: capabilityName }),
            run && /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "mt-0.5 flex items-center gap-3 text-[10px] text-muted-foreground font-mono", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-emerald-400", children: [
                Number(run.passed),
                " pass"
              ] }),
              /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-destructive", children: [
                Number(run.failed),
                " fail"
              ] }),
              /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { children: [
                Number(run.totalTests),
                " total"
              ] }),
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { children: new Date(
                Number(run.startedAt) / 1e6
              ).toLocaleTimeString() })
            ] })
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsx(
            "button",
            {
              type: "button",
              onClick: onClose,
              className: "ml-3 p-1.5 rounded text-muted-foreground hover:text-foreground hover:bg-secondary transition-smooth",
              "aria-label": "Close panel",
              children: /* @__PURE__ */ jsxRuntimeExports.jsx(CircleX, { size: 14 })
            }
          )
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs(
          "div",
          {
            className: "flex items-center gap-1.5 px-4 py-2 border-b border-border bg-muted/20 shrink-0",
            "data-ocid": "test-filter-bar",
            children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx(Funnel, { size: 11, className: "text-muted-foreground" }),
              ["all", "pass", "fail"].map((f) => /* @__PURE__ */ jsxRuntimeExports.jsx(
                "button",
                {
                  type: "button",
                  onClick: () => setFilter(f),
                  "data-ocid": `filter-${f}`,
                  className: `px-2.5 py-0.5 rounded text-[10px] font-mono transition-smooth ${filter === f ? "bg-accent text-accent-foreground" : "text-muted-foreground hover:text-foreground"}`,
                  children: f === "all" ? "All" : f === "pass" ? "Passed" : "Failed"
                },
                f
              )),
              run && /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "ml-auto", children: /* @__PURE__ */ jsxRuntimeExports.jsx(
                ExportFailedButton,
                {
                  results: run.results,
                  label: "Export Failed",
                  compact: true
                }
              ) })
            ]
          }
        ),
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "flex-1 overflow-y-auto p-3 space-y-1.5", children: isPending ? ["a", "b", "c", "d", "e", "f"].map((k) => /* @__PURE__ */ jsxRuntimeExports.jsx(Skeleton, { className: "h-10 rounded" }, `skel-result-${k}`)) : !run ? /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex flex-col items-center justify-center h-32 text-center text-muted-foreground", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(CircleAlert, { size: 20, className: "mb-2 opacity-40" }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs font-mono", children: "No results available" })
        ] }) : filtered.length === 0 ? /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex flex-col items-center justify-center h-32 text-center text-muted-foreground", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(CircleCheck, { size: 20, className: "mb-2 opacity-40" }),
          /* @__PURE__ */ jsxRuntimeExports.jsxs("p", { className: "text-xs font-mono", children: [
            "No ",
            filter,
            " tests"
          ] })
        ] }) : filtered.map((r) => /* @__PURE__ */ jsxRuntimeExports.jsx(TestResultRow, { result: r }, r.testId)) })
      ]
    }
  );
}
function TestHistoryPanel({
  history,
  onSelectRun,
  selectedRunId
}) {
  const [open, setOpen] = reactExports.useState(false);
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "div",
    {
      className: "border-t border-border bg-muted/10 shrink-0",
      "data-ocid": "test-history-panel",
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs(
          "button",
          {
            type: "button",
            onClick: () => setOpen((p) => !p),
            className: "w-full flex items-center gap-2 px-4 py-2.5 text-left hover:bg-muted/20 transition-smooth",
            children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx(History, { size: 13, className: "text-muted-foreground shrink-0" }),
              /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-xs font-mono text-muted-foreground flex-1", children: [
                "Test History (",
                history.length,
                ")"
              ] }),
              open ? /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronDown, { size: 13, className: "text-muted-foreground" }) : /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronUp, { size: 13, className: "text-muted-foreground" })
            ]
          }
        ),
        open && /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "max-h-52 overflow-y-auto border-t border-border", children: history.length === 0 ? /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "px-4 py-3 text-xs text-muted-foreground font-mono", children: "No history yet" }) : history.map((run) => /* @__PURE__ */ jsxRuntimeExports.jsxs(
          "button",
          {
            type: "button",
            onClick: () => onSelectRun(
              run.runId,
              run.capabilityName ?? "All Capabilities"
            ),
            "data-ocid": "history-run-item",
            className: `w-full flex items-center gap-3 px-4 py-2.5 text-left text-xs border-b border-border/50 last:border-0 hover:bg-secondary/50 transition-smooth ${selectedRunId === run.runId ? "bg-accent/5 border-accent/20" : ""}`,
            children: [
              /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex-1 min-w-0", children: [
                /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "font-mono text-foreground truncate text-[11px]", children: run.capabilityName ?? "All Capabilities" }),
                /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "text-muted-foreground text-[10px] mt-0.5", children: new Date(
                  Number(run.startedAt) / 1e6
                ).toLocaleString() })
              ] }),
              /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-2 shrink-0", children: [
                /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-emerald-400 font-mono text-[10px]", children: [
                  "✓",
                  Number(run.passed)
                ] }),
                /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-destructive font-mono text-[10px]", children: [
                  "✗",
                  Number(run.failed)
                ] })
              ] })
            ]
          },
          run.runId
        )) })
      ]
    }
  );
}
const STATUS_SORT_ORDER = {
  all_fail: 0,
  fail: 0,
  some_fail: 1,
  never_run: 2,
  all_pass: 3,
  pass: 3
};
function CapabilityRow({
  cap,
  isSelected,
  isRunning,
  onClick,
  onRunTests
}) {
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "button",
    {
      type: "button",
      className: `group w-full flex items-center gap-3 px-4 py-3 border-b border-border/50 cursor-pointer transition-smooth hover:bg-secondary/30 text-left ${isSelected ? "bg-accent/5 border-l-2 border-l-accent" : "border-l-2 border-l-transparent"}`,
      onClick,
      "data-ocid": "capability-row",
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex-1 min-w-0", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "font-mono text-[12px] text-foreground truncate", children: cap.capabilityName }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "mt-0.5 text-[10px] text-muted-foreground truncate", children: cap.category })
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "shrink-0 hidden sm:block", children: /* @__PURE__ */ jsxRuntimeExports.jsx(StatusBadge, { status: cap.status }) }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "shrink-0 flex items-center gap-2 text-[11px] font-mono hidden md:flex", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-emerald-400", children: Number(cap.passed) }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-muted-foreground", children: "/" }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-destructive", children: Number(cap.failed) })
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "shrink-0 hidden lg:block text-[10px] text-muted-foreground font-mono w-28 text-right", children: cap.lastRunAt ? new Date(Number(cap.lastRunAt) / 1e6).toLocaleTimeString() : "—" }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs(
          "button",
          {
            type: "button",
            onClick: onRunTests,
            disabled: isRunning,
            "data-ocid": "btn-run-capability-tests",
            className: `shrink-0 flex items-center gap-1.5 px-2.5 py-1 rounded text-[10px] font-mono border transition-smooth ${isRunning ? "text-muted-foreground border-border cursor-not-allowed" : "text-muted-foreground border-border hover:border-accent hover:text-accent"}`,
            "aria-label": `Run tests for ${cap.capabilityName}`,
            children: [
              isRunning ? /* @__PURE__ */ jsxRuntimeExports.jsx(LoaderCircle, { size: 11, className: "animate-spin" }) : /* @__PURE__ */ jsxRuntimeExports.jsx(Play, { size: 11 }),
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "hidden sm:inline", children: isRunning ? "Running…" : "Run" })
            ]
          }
        )
      ]
    }
  );
}
function AdminValidationPage() {
  var _a;
  const { data: isAdmin, isPending: adminPending } = useAdminStatus();
  const { data: statuses = [], isPending: statusesPending } = useCapabilityTestStatuses();
  const { data: history = [] } = useTestHistory();
  const runAllMutation = useRunAllTests();
  const runCapabilityMutation = useRunCapabilityTests();
  const [selectedCap, setSelectedCap] = reactExports.useState(null);
  const [selectedRunId, setSelectedRunId] = reactExports.useState(
    void 0
  );
  const [runningCap, setRunningCap] = reactExports.useState(null);
  const [sortField, setSortField] = reactExports.useState("status");
  const [sortDir, setSortDir] = reactExports.useState("asc");
  const latestGlobalRunId = ((_a = history.filter((h) => !h.capabilityName).sort((a, b) => Number(b.startedAt) - Number(a.startedAt))[0]) == null ? void 0 : _a.runId) ?? null;
  const { data: latestGlobalRun } = useTestResults(latestGlobalRunId);
  const totalPass = statuses.reduce((s, c) => s + Number(c.passed), 0);
  const totalFail = statuses.reduce((s, c) => s + Number(c.failed), 0);
  const neverRun = statuses.filter((c) => c.status === "never_run").length;
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
  const handleSort = (field) => {
    if (sortField === field) {
      setSortDir((d) => d === "asc" ? "desc" : "asc");
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
    } catch {
    }
  };
  const handleRunCapability = async (e, capName) => {
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
  const handleSelectCap = (cap) => {
    if (selectedCap === cap.capabilityName) {
      setSelectedCap(null);
      setSelectedRunId(void 0);
    } else {
      setSelectedCap(cap.capabilityName);
      const latestRun = history.filter((h) => h.capabilityName === cap.capabilityName).sort((a, b) => Number(b.startedAt) - Number(a.startedAt))[0];
      setSelectedRunId(latestRun == null ? void 0 : latestRun.runId);
    }
  };
  const handleSelectHistoryRun = (runId, capName) => {
    setSelectedCap(capName);
    setSelectedRunId(runId);
  };
  if (adminPending) {
    return /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "flex-1 flex items-center justify-center", children: /* @__PURE__ */ jsxRuntimeExports.jsx(LoaderCircle, { size: 20, className: "animate-spin text-muted-foreground" }) });
  }
  if (!isAdmin) {
    return /* @__PURE__ */ jsxRuntimeExports.jsxs(
      "div",
      {
        className: "flex-1 flex flex-col items-center justify-center gap-4 text-center px-4",
        "data-ocid": "access-denied-view",
        children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(ShieldOff, { size: 36, className: "text-muted-foreground opacity-40" }),
          /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { children: [
            /* @__PURE__ */ jsxRuntimeExports.jsx("h2", { className: "font-display text-lg font-semibold text-foreground", children: "Access Denied" }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "mt-1 text-sm text-muted-foreground font-body max-w-xs", children: "The Validation Dashboard is restricted to admin users only." })
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsx(
            Link,
            {
              to: "/capabilities",
              className: "btn-secondary text-sm",
              "data-ocid": "link-back-capabilities",
              children: "← Back to Capabilities"
            }
          )
        ]
      }
    );
  }
  const runAllRunning = runAllMutation.isPending;
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "div",
    {
      className: "flex flex-col h-full overflow-hidden",
      "data-ocid": "admin-validation-page",
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-4 px-4 py-3 bg-card border-b border-border shrink-0 flex-wrap gap-y-2", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-2.5", children: [
            /* @__PURE__ */ jsxRuntimeExports.jsx(Shield, { size: 16, className: "text-accent shrink-0" }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("h1", { className: "font-display text-sm font-semibold text-foreground tracking-tight", children: "Validation Dashboard" })
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-4 text-[11px] font-mono ml-2", children: [
            /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-muted-foreground", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-foreground font-semibold", children: statuses.length }),
              " ",
              "capabilities"
            ] }),
            /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-emerald-400", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "font-semibold", children: totalPass }),
              " passed"
            ] }),
            /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-destructive", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "font-semibold", children: totalFail }),
              " failed"
            ] }),
            neverRun > 0 && /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-muted-foreground", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "font-semibold", children: neverRun }),
              " never run"
            ] }),
            runAllRunning && /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { className: "text-accent flex items-center gap-1", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx(LoaderCircle, { size: 10, className: "animate-spin" }),
              "Running all tests…"
            ] })
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "ml-auto flex items-center gap-2", children: [
            latestGlobalRun && /* @__PURE__ */ jsxRuntimeExports.jsx(ExportFailedButton, { results: latestGlobalRun.results }),
            /* @__PURE__ */ jsxRuntimeExports.jsx(
              Button,
              {
                size: "sm",
                onClick: handleRunAll,
                disabled: runAllRunning,
                "data-ocid": "btn-run-all-tests",
                className: "font-mono text-xs gap-1.5",
                children: runAllRunning ? /* @__PURE__ */ jsxRuntimeExports.jsxs(jsxRuntimeExports.Fragment, { children: [
                  /* @__PURE__ */ jsxRuntimeExports.jsx(LoaderCircle, { size: 12, className: "animate-spin" }),
                  "Running…"
                ] }) : /* @__PURE__ */ jsxRuntimeExports.jsxs(jsxRuntimeExports.Fragment, { children: [
                  /* @__PURE__ */ jsxRuntimeExports.jsx(Play, { size: 12 }),
                  "Run All Tests"
                ] })
              }
            )
          ] })
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex flex-1 min-h-0 overflow-hidden", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsxs(
            "div",
            {
              className: `flex flex-col overflow-hidden transition-all duration-200 ${selectedCap ? "w-full lg:w-1/2 xl:w-[55%]" : "w-full"}`,
              children: [
                /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-3 px-4 py-2 bg-muted/20 border-b border-border shrink-0 text-[10px] font-mono text-muted-foreground", children: [
                  /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "flex-1 min-w-0", children: /* @__PURE__ */ jsxRuntimeExports.jsxs(
                    "button",
                    {
                      type: "button",
                      onClick: () => handleSort("name"),
                      className: "flex items-center gap-1 hover:text-foreground transition-smooth",
                      "data-ocid": "sort-by-name",
                      children: [
                        "CAPABILITY",
                        sortField === "name" && (sortDir === "asc" ? /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronUp, { size: 10 }) : /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronDown, { size: 10 }))
                      ]
                    }
                  ) }),
                  /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "shrink-0 hidden sm:block w-24", children: /* @__PURE__ */ jsxRuntimeExports.jsxs(
                    "button",
                    {
                      type: "button",
                      onClick: () => handleSort("status"),
                      className: "flex items-center gap-1 hover:text-foreground transition-smooth",
                      "data-ocid": "sort-by-status",
                      children: [
                        "STATUS",
                        sortField === "status" && (sortDir === "asc" ? /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronUp, { size: 10 }) : /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronDown, { size: 10 }))
                      ]
                    }
                  ) }),
                  /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "shrink-0 hidden md:block w-16 text-center", children: "P / F" }),
                  /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "shrink-0 hidden lg:block w-28 text-right", children: /* @__PURE__ */ jsxRuntimeExports.jsxs(
                    "button",
                    {
                      type: "button",
                      onClick: () => handleSort("lastRun"),
                      className: "flex items-center gap-1 hover:text-foreground transition-smooth ml-auto",
                      "data-ocid": "sort-by-last-run",
                      children: [
                        "LAST RUN",
                        sortField === "lastRun" && (sortDir === "asc" ? /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronUp, { size: 10 }) : /* @__PURE__ */ jsxRuntimeExports.jsx(ChevronDown, { size: 10 }))
                      ]
                    }
                  ) }),
                  /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "shrink-0 w-16" })
                ] }),
                /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "flex-1 overflow-y-auto", "data-ocid": "capability-list", children: statusesPending ? ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"].map((k) => /* @__PURE__ */ jsxRuntimeExports.jsxs(
                  "div",
                  {
                    className: "px-4 py-3 border-b border-border/50",
                    children: [
                      /* @__PURE__ */ jsxRuntimeExports.jsx(Skeleton, { className: "h-4 w-40 mb-1" }),
                      /* @__PURE__ */ jsxRuntimeExports.jsx(Skeleton, { className: "h-3 w-24" })
                    ]
                  },
                  `skel-cap-${k}`
                )) : sorted.length === 0 ? /* @__PURE__ */ jsxRuntimeExports.jsxs(
                  "div",
                  {
                    className: "flex flex-col items-center justify-center h-64 text-center px-6",
                    "data-ocid": "empty-state-no-tests",
                    children: [
                      /* @__PURE__ */ jsxRuntimeExports.jsx(
                        Shield,
                        {
                          size: 32,
                          className: "text-muted-foreground opacity-30 mb-3"
                        }
                      ),
                      /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-sm font-mono text-muted-foreground", children: "No tests run yet." }),
                      /* @__PURE__ */ jsxRuntimeExports.jsxs("p", { className: "text-xs text-muted-foreground/60 mt-1 max-w-64", children: [
                        "Click",
                        " ",
                        /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-accent font-semibold", children: "Run All Tests" }),
                        " ",
                        "to validate all 42 capabilities."
                      ] })
                    ]
                  }
                ) : sorted.map((cap) => /* @__PURE__ */ jsxRuntimeExports.jsx(
                  CapabilityRow,
                  {
                    cap,
                    isSelected: selectedCap === cap.capabilityName,
                    isRunning: runningCap === cap.capabilityName,
                    onClick: () => handleSelectCap(cap),
                    onRunTests: (e) => handleRunCapability(e, cap.capabilityName)
                  },
                  cap.capabilityName
                )) }),
                /* @__PURE__ */ jsxRuntimeExports.jsx(
                  TestHistoryPanel,
                  {
                    history,
                    onSelectRun: handleSelectHistoryRun,
                    selectedRunId
                  }
                )
              ]
            }
          ),
          selectedCap && /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "hidden lg:flex flex-col flex-1 min-w-0 overflow-hidden border-l border-border", children: /* @__PURE__ */ jsxRuntimeExports.jsx(
            TestResultsPanel,
            {
              capabilityName: selectedCap,
              runId: selectedRunId,
              onClose: () => {
                setSelectedCap(null);
                setSelectedRunId(void 0);
              }
            }
          ) })
        ] }),
        selectedCap && /* @__PURE__ */ jsxRuntimeExports.jsx(
          "div",
          {
            className: "lg:hidden fixed inset-0 z-50 flex flex-col bg-background",
            "data-ocid": "mobile-results-overlay",
            children: /* @__PURE__ */ jsxRuntimeExports.jsx(
              TestResultsPanel,
              {
                capabilityName: selectedCap,
                runId: selectedRunId,
                onClose: () => {
                  setSelectedCap(null);
                  setSelectedRunId(void 0);
                }
              }
            )
          }
        )
      ]
    }
  );
}
export {
  AdminValidationPage as default
};
