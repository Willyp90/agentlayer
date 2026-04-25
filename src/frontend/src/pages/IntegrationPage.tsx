import { Badge } from "@/components/ui/badge";
import {
  BookOpen,
  Check,
  Code2,
  Copy,
  Key,
  Shield,
  Terminal,
  Zap,
} from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

// ── Code block with copy ──────────────────────────────────────────────────────

function CodeBlock({
  code,
  language = "bash",
}: { code: string; language?: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(code);
    setCopied(true);
    toast.success("Copied to clipboard");
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div
      className="relative group rounded-md border border-border overflow-hidden"
      data-ocid="code-block"
    >
      <div className="flex items-center justify-between px-3 py-1.5 bg-secondary/60 border-b border-border">
        <span className="text-[10px] font-mono text-muted-foreground/60 uppercase tracking-wider">
          {language}
        </span>
        <button
          type="button"
          onClick={handleCopy}
          data-ocid="btn-copy-code"
          className="flex items-center gap-1 text-[10px] font-mono text-muted-foreground/50 hover:text-muted-foreground transition-colors duration-150"
          aria-label="Copy code"
        >
          {copied ? (
            <>
              <Check size={10} className="text-chart-2" />
              <span className="text-chart-2">Copied</span>
            </>
          ) : (
            <>
              <Copy size={10} />
              Copy
            </>
          )}
        </button>
      </div>
      <pre className="p-4 text-[12px] font-mono text-foreground bg-card overflow-x-auto leading-relaxed whitespace-pre">
        <code>{code}</code>
      </pre>
    </div>
  );
}

// ── Tabs ──────────────────────────────────────────────────────────────────────

interface Tab {
  id: string;
  label: string;
}

function Tabs({
  tabs,
  active,
  onChange,
}: {
  tabs: Tab[];
  active: string;
  onChange: (id: string) => void;
}) {
  return (
    <div
      className="flex items-center gap-1 border-b border-border mb-4"
      data-ocid="integration-tabs"
    >
      {tabs.map((tab) => (
        <button
          key={tab.id}
          type="button"
          onClick={() => onChange(tab.id)}
          data-ocid={`tab-${tab.id}`}
          className={[
            "px-3 py-2 text-xs font-mono transition-smooth border-b-2 -mb-px",
            active === tab.id
              ? "border-accent text-accent"
              : "border-transparent text-muted-foreground hover:text-foreground",
          ].join(" ")}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}

// ── Section ───────────────────────────────────────────────────────────────────

function Section({
  icon,
  title,
  children,
}: {
  icon: React.ReactNode;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="space-y-4">
      <div className="flex items-center gap-2 pb-2 border-b border-border">
        <span className="text-accent">{icon}</span>
        <h2 className="text-sm font-display font-semibold text-foreground">
          {title}
        </h2>
      </div>
      {children}
    </section>
  );
}

// ── Code examples ─────────────────────────────────────────────────────────────

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

// ── Page ──────────────────────────────────────────────────────────────────────

const CODE_TABS: Tab[] = [
  { id: "dfx", label: "dfx (CLI)" },
  { id: "js", label: "JavaScript" },
  { id: "curl", label: "curl" },
];

export default function IntegrationPage() {
  const [capTab, setCapTab] = useState("dfx");

  return (
    <div className="flex-1 overflow-y-auto">
      {/* Header */}
      <div className="border-b border-border bg-card px-4 md:px-6 py-4">
        <div className="flex items-center gap-2 mb-0.5">
          <BookOpen size={14} className="text-accent" />
          <h1 className="text-base font-display font-semibold text-foreground tracking-tight">
            Integration Guide
          </h1>
        </div>
        <p className="text-xs text-muted-foreground font-body max-w-lg">
          Everything you need to call AgentLayer capabilities from agents,
          scripts, or any HTTP client — without requiring a browser or Internet
          Identity.
        </p>
      </div>

      <div className="px-4 md:px-6 py-6 space-y-10 max-w-3xl">
        {/* Section 1: Auth flow */}
        <Section
          icon={<Key size={14} />}
          title="How Agent Authentication Works"
        >
          <div className="space-y-4">
            <p className="text-xs font-body text-muted-foreground leading-relaxed">
              AgentLayer uses a two-layer authentication model:
            </p>
            <ol className="space-y-3">
              {[
                {
                  step: "1",
                  title: "Developer logs in with Internet Identity",
                  desc: "Your browser session is authenticated via the IC's built-in identity provider.",
                },
                {
                  step: "2",
                  title: "Generate an API key",
                  desc: "From the API Keys page, generate a named key. The full key ID is shown once — save it.",
                },
                {
                  step: "3",
                  title: "Agent passes API key in calls",
                  desc: "Your agent, script, or cron job uses the API key as the optional third parameter of execute_capability. No browser needed.",
                },
              ].map(({ step, title, desc }) => (
                <li key={step} className="flex items-start gap-3">
                  <span className="w-5 h-5 shrink-0 flex items-center justify-center rounded-full bg-accent/10 border border-accent/30 text-accent text-[10px] font-mono mt-0.5">
                    {step}
                  </span>
                  <div>
                    <p className="text-xs font-display font-medium text-foreground mb-0.5">
                      {title}
                    </p>
                    <p className="text-[11px] font-body text-muted-foreground leading-relaxed">
                      {desc}
                    </p>
                  </div>
                </li>
              ))}
            </ol>
            <div className="flex items-center gap-2 p-3 rounded border border-border bg-secondary/20">
              <Zap size={12} className="text-accent shrink-0" />
              <p className="text-[11px] font-body text-muted-foreground leading-relaxed">
                All API keys are scoped to your principal. Usage is tracked per
                key, so you can identify which agent made which calls.
              </p>
            </div>
          </div>
        </Section>

        {/* Section 2: execute_capability signature */}
        <Section icon={<Terminal size={14} />} title="Calling Capabilities">
          <div className="space-y-3">
            <p className="text-xs font-body text-muted-foreground leading-relaxed">
              Every capability is available via the{" "}
              <code className="font-mono bg-secondary px-1 py-0.5 rounded text-[11px]">
                execute_capability
              </code>{" "}
              canister method. The{" "}
              <code className="font-mono bg-secondary px-1 py-0.5 rounded text-[11px]">
                apiKey
              </code>{" "}
              parameter is optional — omit it for Internet Identity sessions.
            </p>
            <CodeBlock
              language="candid (method signature)"
              code={`execute_capability : (
  capabilityName : Text,   // e.g. "fetch_url", "parse_json", "compute_math"
  inputJson      : Text,   // JSON string matching the capability's input schema
  apiKey         : opt Text // Optional — your API key for agent/headless auth
) -> ExecutionResult`}
            />
            <div className="flex flex-wrap gap-2">
              {[
                "42 capabilities",
                "all deterministic",
                "stateless execution",
              ].map((tag) => (
                <Badge
                  key={tag}
                  variant="outline"
                  className="text-[10px] font-mono border-border text-muted-foreground"
                >
                  {tag}
                </Badge>
              ))}
            </div>
          </div>
        </Section>

        {/* Section 3: Code examples for capabilities */}
        <Section icon={<Code2 size={14} />} title="Code Examples">
          <Tabs tabs={CODE_TABS} active={capTab} onChange={setCapTab} />
          {capTab === "dfx" && (
            <div className="space-y-3">
              <p className="text-[11px] font-body text-muted-foreground">
                Use the{" "}
                <code className="font-mono bg-secondary px-1 py-0.5 rounded">
                  dfx canister call
                </code>{" "}
                command with your deployed canister ID:
              </p>
              <CodeBlock code={DFX_CAPABILITY} language="bash" />
            </div>
          )}
          {capTab === "js" && (
            <div className="space-y-3">
              <p className="text-[11px] font-body text-muted-foreground">
                Use the{" "}
                <code className="font-mono bg-secondary px-1 py-0.5 rounded">
                  @dfinity/agent
                </code>{" "}
                library. Pass the API key as a single-element array (Candid{" "}
                <code className="font-mono bg-secondary px-1 py-0.5 rounded">
                  opt Text
                </code>
                ):
              </p>
              <CodeBlock code={JS_EXAMPLE} language="typescript" />
            </div>
          )}
          {capTab === "curl" && (
            <div className="space-y-3">
              <p className="text-[11px] font-body text-muted-foreground">
                Direct HTTP calls require Candid-encoded bodies. Use{" "}
                <code className="font-mono bg-secondary px-1 py-0.5 rounded">
                  didc
                </code>{" "}
                or{" "}
                <code className="font-mono bg-secondary px-1 py-0.5 rounded">
                  dfx encode
                </code>{" "}
                to prepare the binary payload:
              </p>
              <CodeBlock code={CURL_EXAMPLE} language="bash" />
              <p className="text-[11px] font-body text-muted-foreground/60">
                For most integrations, the JavaScript or dfx approaches are
                significantly easier than raw HTTP calls.
              </p>
            </div>
          )}
        </Section>

        {/* Section 4: Response format */}
        <Section icon={<Zap size={14} />} title="Execution Response Format">
          <div className="space-y-3">
            <p className="text-xs font-body text-muted-foreground leading-relaxed">
              Every{" "}
              <code className="font-mono bg-secondary px-1 py-0.5 rounded text-[11px]">
                execute_capability
              </code>{" "}
              call returns the same standardized contract:
            </p>
            <CodeBlock code={RESPONSE_CONTRACT} language="json" />
            <div className="space-y-1.5 text-[11px] font-body text-muted-foreground">
              {[
                {
                  field: "success",
                  desc: "Always check this first before parsing output",
                },
                {
                  field: "output",
                  desc: "JSON string — parse it to get the capability's result",
                },
                {
                  field: "error",
                  desc: "Only present when success is false — contains code and message",
                },
                {
                  field: "executionId",
                  desc: "Use this for tracing in the Logs and Audit Log pages",
                },
                {
                  field: "latencyMs",
                  desc: "Execution time including any HTTP outcalls",
                },
              ].map(({ field, desc }) => (
                <div key={field} className="flex items-start gap-2">
                  <code className="font-mono bg-secondary px-1 py-0.5 rounded text-[10px] text-accent shrink-0 mt-0.5">
                    {field}
                  </code>
                  <span className="leading-relaxed">{desc}</span>
                </div>
              ))}
            </div>
          </div>
        </Section>

        {/* Section 5: Rate limits */}
        <Section icon={<Shield size={14} />} title="Rate Limits & Quotas">
          <div className="space-y-3">
            <div className="flex items-start gap-3 p-4 rounded border border-border bg-secondary/20">
              <Zap size={13} className="text-accent shrink-0 mt-0.5" />
              <div className="space-y-1">
                <p className="text-xs font-display font-medium text-foreground">
                  No rate limits are enforced currently.
                </p>
                <p className="text-[11px] font-body text-muted-foreground leading-relaxed">
                  All API keys have unlimited access. Usage is tracked per key
                  and visible in the API Keys page. Rate limiting and
                  usage-based billing are planned for a future release.
                </p>
              </div>
            </div>
            <div className="space-y-2">
              {[
                "Each capability call costs cycles proportional to its computation",
                "fetch_url HTTP outcalls cost ~21.5B cycles per request (~$0.02)",
                "Cached responses (within TTL) cost 0 cycles",
                "Cycle costs are visible in the execution response and logs",
              ].map((item) => (
                <div key={item} className="flex items-start gap-2">
                  <Check size={11} className="text-chart-2 shrink-0 mt-0.5" />
                  <span className="text-[11px] font-body text-muted-foreground leading-relaxed">
                    {item}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </Section>
      </div>
    </div>
  );
}
