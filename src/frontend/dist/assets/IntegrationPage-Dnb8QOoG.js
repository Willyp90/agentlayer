import { r as reactExports, j as jsxRuntimeExports, B as BookOpen, Z as Zap, K as Key, T as Terminal, z as CodeXml, e as Shield } from "./index-BZePS1Zd.js";
import { B as Badge } from "./badge-Bs3SiHuZ.js";
import { u as ue } from "./index-fmrAgBMw.js";
import { C as Check } from "./check-CK-oStBv.js";
import { C as Copy } from "./copy-Brb3v89n.js";
import "./index-DYfQEczc.js";
import "./utils-2v2HxlWs.js";
function CodeBlock({
  code,
  language = "bash"
}) {
  const [copied, setCopied] = reactExports.useState(false);
  const handleCopy = () => {
    navigator.clipboard.writeText(code);
    setCopied(true);
    ue.success("Copied to clipboard");
    setTimeout(() => setCopied(false), 2e3);
  };
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "div",
    {
      className: "relative group rounded-md border border-border overflow-hidden",
      "data-ocid": "code-block",
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center justify-between px-3 py-1.5 bg-secondary/60 border-b border-border", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-[10px] font-mono text-muted-foreground/60 uppercase tracking-wider", children: language }),
          /* @__PURE__ */ jsxRuntimeExports.jsx(
            "button",
            {
              type: "button",
              onClick: handleCopy,
              "data-ocid": "btn-copy-code",
              className: "flex items-center gap-1 text-[10px] font-mono text-muted-foreground/50 hover:text-muted-foreground transition-colors duration-150",
              "aria-label": "Copy code",
              children: copied ? /* @__PURE__ */ jsxRuntimeExports.jsxs(jsxRuntimeExports.Fragment, { children: [
                /* @__PURE__ */ jsxRuntimeExports.jsx(Check, { size: 10, className: "text-chart-2" }),
                /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-chart-2", children: "Copied" })
              ] }) : /* @__PURE__ */ jsxRuntimeExports.jsxs(jsxRuntimeExports.Fragment, { children: [
                /* @__PURE__ */ jsxRuntimeExports.jsx(Copy, { size: 10 }),
                "Copy"
              ] })
            }
          )
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("pre", { className: "p-4 text-[12px] font-mono text-foreground bg-card overflow-x-auto leading-relaxed whitespace-pre", children: /* @__PURE__ */ jsxRuntimeExports.jsx("code", { children: code }) })
      ]
    }
  );
}
function Tabs({
  tabs,
  active,
  onChange
}) {
  return /* @__PURE__ */ jsxRuntimeExports.jsx(
    "div",
    {
      className: "flex items-center gap-1 border-b border-border mb-4",
      "data-ocid": "integration-tabs",
      children: tabs.map((tab) => /* @__PURE__ */ jsxRuntimeExports.jsx(
        "button",
        {
          type: "button",
          onClick: () => onChange(tab.id),
          "data-ocid": `tab-${tab.id}`,
          className: [
            "px-3 py-2 text-xs font-mono transition-smooth border-b-2 -mb-px",
            active === tab.id ? "border-accent text-accent" : "border-transparent text-muted-foreground hover:text-foreground"
          ].join(" "),
          children: tab.label
        },
        tab.id
      ))
    }
  );
}
function Section({
  icon,
  title,
  children
}) {
  return /* @__PURE__ */ jsxRuntimeExports.jsxs("section", { className: "space-y-4", children: [
    /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-2 pb-2 border-b border-border", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-accent", children: icon }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("h2", { className: "text-sm font-display font-semibold text-foreground", children: title })
    ] }),
    children
  ] });
}
const DFX_CAPABILITY = `dfx canister call <CANISTER_ID> execute_capability \\
  '("fetch_url", "{\\"url\\":\\"https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd\\"}", opt "YOUR_API_KEY")'`;
const JS_EXAMPLE = `import { HttpAgent, Actor } from "@dfinity/agent";
import { idlFactory } from "./declarations/backend";

// Create agent — no Internet Identity required for API key auth
const agent = new HttpAgent({ host: "https://ic0.app" });

const backend = Actor.createActor(idlFactory, {
  agent,
  canisterId: "<CANISTER_ID>",
});

// Execute a capability with your API key
const result = await backend.execute_capability(
  "fetch_url",
  JSON.stringify({ url: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd" }),
  ["YOUR_API_KEY"],  // opt Text — pass as single-element array
);

if (result.success) {
  const output = JSON.parse(result.output);
  console.log(output);
} else {
  console.error(result.error.message);
}`;
const CURL_EXAMPLE = `# Encode your Candid call (use didc or dfx encode)
# execute_capability("fetch_url", "{...}", opt "YOUR_API_KEY")

curl -X POST \\
  "https://<CANISTER_ID>.raw.ic0.app/api/v2/canister/<CANISTER_ID>/call" \\
  -H "Content-Type: application/cbor" \\
  --data-binary @candid-encoded-body.bin`;
const RESPONSE_CONTRACT = `{
  "success": true,          // boolean — did the execution succeed?
  "output": "{ ... }",     // string (JSON) — the capability's output
  "error": null,            // { code: string, message: string } | null
  "executionId": "exec_7f3a...",  // unique execution ID for tracing
  "latencyMs": 142          // execution time in milliseconds
}`;
const CODE_TABS = [
  { id: "dfx", label: "dfx (CLI)" },
  { id: "js", label: "JavaScript" },
  { id: "curl", label: "curl" }
];
function IntegrationPage() {
  const [capTab, setCapTab] = reactExports.useState("dfx");
  return /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex-1 overflow-y-auto", children: [
    /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "border-b border-border bg-card px-4 md:px-6 py-4", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-2 mb-0.5", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx(BookOpen, { size: 14, className: "text-accent" }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("h1", { className: "text-base font-display font-semibold text-foreground tracking-tight", children: "Integration Guide" })
      ] }),
      /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs text-muted-foreground font-body max-w-lg", children: "Everything you need to call AgentLayer capabilities from agents, scripts, or any HTTP client — without requiring a browser or Internet Identity." })
    ] }),
    /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "px-4 md:px-6 py-6 space-y-10 max-w-3xl", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsx(
        Section,
        {
          icon: /* @__PURE__ */ jsxRuntimeExports.jsx(Key, { size: 14 }),
          title: "How Agent Authentication Works",
          children: /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "space-y-4", children: [
            /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs font-body text-muted-foreground leading-relaxed", children: "AgentLayer uses a two-layer authentication model:" }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("ol", { className: "space-y-3", children: [
              {
                step: "1",
                title: "Developer logs in with Internet Identity",
                desc: "Your browser session is authenticated via the IC's built-in identity provider."
              },
              {
                step: "2",
                title: "Generate an API key",
                desc: "From the API Keys page, generate a named key. The full key ID is shown once — save it."
              },
              {
                step: "3",
                title: "Agent passes API key in calls",
                desc: "Your agent, script, or cron job uses the API key as the optional third parameter of execute_capability. No browser needed."
              }
            ].map(({ step, title, desc }) => /* @__PURE__ */ jsxRuntimeExports.jsxs("li", { className: "flex items-start gap-3", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "w-5 h-5 shrink-0 flex items-center justify-center rounded-full bg-accent/10 border border-accent/30 text-accent text-[10px] font-mono mt-0.5", children: step }),
              /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { children: [
                /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs font-display font-medium text-foreground mb-0.5", children: title }),
                /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-[11px] font-body text-muted-foreground leading-relaxed", children: desc })
              ] })
            ] }, step)) }),
            /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-2 p-3 rounded border border-border bg-secondary/20", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx(Zap, { size: 12, className: "text-accent shrink-0" }),
              /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-[11px] font-body text-muted-foreground leading-relaxed", children: "All API keys are scoped to your principal. Usage is tracked per key, so you can identify which agent made which calls." })
            ] })
          ] })
        }
      ),
      /* @__PURE__ */ jsxRuntimeExports.jsx(Section, { icon: /* @__PURE__ */ jsxRuntimeExports.jsx(Terminal, { size: 14 }), title: "Calling Capabilities", children: /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "space-y-3", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("p", { className: "text-xs font-body text-muted-foreground leading-relaxed", children: [
          "Every capability is available via the",
          " ",
          /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono bg-secondary px-1 py-0.5 rounded text-[11px]", children: "execute_capability" }),
          " ",
          "canister method. The",
          " ",
          /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono bg-secondary px-1 py-0.5 rounded text-[11px]", children: "apiKey" }),
          " ",
          "parameter is optional — omit it for Internet Identity sessions."
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx(
          CodeBlock,
          {
            language: "candid (method signature)",
            code: `execute_capability : (
  capabilityName : Text,   // e.g. "fetch_url", "parse_json", "compute_math"
  inputJson      : Text,   // JSON string matching the capability's input schema
  apiKey         : opt Text // Optional — your API key for agent/headless auth
) -> ExecutionResult`
          }
        ),
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "flex flex-wrap gap-2", children: [
          "42 capabilities",
          "all deterministic",
          "stateless execution"
        ].map((tag) => /* @__PURE__ */ jsxRuntimeExports.jsx(
          Badge,
          {
            variant: "outline",
            className: "text-[10px] font-mono border-border text-muted-foreground",
            children: tag
          },
          tag
        )) })
      ] }) }),
      /* @__PURE__ */ jsxRuntimeExports.jsxs(Section, { icon: /* @__PURE__ */ jsxRuntimeExports.jsx(CodeXml, { size: 14 }), title: "Code Examples", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx(Tabs, { tabs: CODE_TABS, active: capTab, onChange: setCapTab }),
        capTab === "dfx" && /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "space-y-3", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsxs("p", { className: "text-[11px] font-body text-muted-foreground", children: [
            "Use the",
            " ",
            /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono bg-secondary px-1 py-0.5 rounded", children: "dfx canister call" }),
            " ",
            "command with your deployed canister ID:"
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsx(CodeBlock, { code: DFX_CAPABILITY, language: "bash" })
        ] }),
        capTab === "js" && /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "space-y-3", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsxs("p", { className: "text-[11px] font-body text-muted-foreground", children: [
            "Use the",
            " ",
            /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono bg-secondary px-1 py-0.5 rounded", children: "@dfinity/agent" }),
            " ",
            "library. Pass the API key as a single-element array (Candid",
            " ",
            /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono bg-secondary px-1 py-0.5 rounded", children: "opt Text" }),
            "):"
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsx(CodeBlock, { code: JS_EXAMPLE, language: "typescript" })
        ] }),
        capTab === "curl" && /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "space-y-3", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsxs("p", { className: "text-[11px] font-body text-muted-foreground", children: [
            "Direct HTTP calls require Candid-encoded bodies. Use",
            " ",
            /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono bg-secondary px-1 py-0.5 rounded", children: "didc" }),
            " ",
            "or",
            " ",
            /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono bg-secondary px-1 py-0.5 rounded", children: "dfx encode" }),
            " ",
            "to prepare the binary payload:"
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsx(CodeBlock, { code: CURL_EXAMPLE, language: "bash" }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-[11px] font-body text-muted-foreground/60", children: "For most integrations, the JavaScript or dfx approaches are significantly easier than raw HTTP calls." })
        ] })
      ] }),
      /* @__PURE__ */ jsxRuntimeExports.jsx(Section, { icon: /* @__PURE__ */ jsxRuntimeExports.jsx(Zap, { size: 14 }), title: "Execution Response Format", children: /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "space-y-3", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("p", { className: "text-xs font-body text-muted-foreground leading-relaxed", children: [
          "Every",
          " ",
          /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono bg-secondary px-1 py-0.5 rounded text-[11px]", children: "execute_capability" }),
          " ",
          "call returns the same standardized contract:"
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx(CodeBlock, { code: RESPONSE_CONTRACT, language: "json" }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "space-y-1.5 text-[11px] font-body text-muted-foreground", children: [
          {
            field: "success",
            desc: "Always check this first before parsing output"
          },
          {
            field: "output",
            desc: "JSON string — parse it to get the capability's result"
          },
          {
            field: "error",
            desc: "Only present when success is false — contains code and message"
          },
          {
            field: "executionId",
            desc: "Use this for tracing in the Logs and Audit Log pages"
          },
          {
            field: "latencyMs",
            desc: "Execution time including any HTTP outcalls"
          }
        ].map(({ field, desc }) => /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-start gap-2", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono bg-secondary px-1 py-0.5 rounded text-[10px] text-accent shrink-0 mt-0.5", children: field }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "leading-relaxed", children: desc })
        ] }, field)) })
      ] }) }),
      /* @__PURE__ */ jsxRuntimeExports.jsx(Section, { icon: /* @__PURE__ */ jsxRuntimeExports.jsx(Shield, { size: 14 }), title: "Rate Limits & Quotas", children: /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "space-y-3", children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-start gap-3 p-4 rounded border border-border bg-secondary/20", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(Zap, { size: 13, className: "text-accent shrink-0 mt-0.5" }),
          /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "space-y-1", children: [
            /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs font-display font-medium text-foreground", children: "No rate limits are enforced currently." }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-[11px] font-body text-muted-foreground leading-relaxed", children: "All API keys have unlimited access. Usage is tracked per key and visible in the API Keys page. Rate limiting and usage-based billing are planned for a future release." })
          ] })
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "space-y-2", children: [
          "Each capability call costs cycles proportional to its computation",
          "fetch_url HTTP outcalls cost ~21.5B cycles per request (~$0.02)",
          "Cached responses (within TTL) cost 0 cycles",
          "Cycle costs are visible in the execution response and logs"
        ].map((item) => /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-start gap-2", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx(Check, { size: 11, className: "text-chart-2 shrink-0 mt-0.5" }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-[11px] font-body text-muted-foreground leading-relaxed", children: item })
        ] }, item)) })
      ] }) })
    ] })
  ] });
}
export {
  IntegrationPage as default
};
