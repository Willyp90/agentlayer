import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import {
  CheckCircle,
  Layers,
  Link2,
  Play,
  Search,
  XCircle,
  Zap,
} from "lucide-react";
import { useState } from "react";

// ── CTA Button ──────────────────────────────────────────────────────────────
function GetStartedButton() {
  const { login } = useInternetIdentity();
  const [isLoggingIn, setIsLoggingIn] = useState(false);

  const handleLogin = async () => {
    setIsLoggingIn(true);
    try {
      await login();
    } catch (err: unknown) {
      console.error("Login error:", err);
    } finally {
      setIsLoggingIn(false);
    }
  };

  return (
    <button
      type="button"
      onClick={handleLogin}
      disabled={isLoggingIn}
      data-ocid="btn-hero-cta"
      className="inline-flex items-center gap-2 bg-accent text-accent-foreground border border-accent px-6 py-3 font-mono text-sm font-semibold uppercase tracking-wider hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed rounded-sm"
    >
      {isLoggingIn ? (
        <>
          <span className="w-3.5 h-3.5 rounded-full border border-accent-foreground/40 border-t-accent-foreground animate-spin" />
          Connecting…
        </>
      ) : (
        <>
          <Zap size={14} />
          Get Started
        </>
      )}
    </button>
  );
}

// ── JSON Code Block ──────────────────────────────────────────────────────────
function CodeBlock({ data }: { data: Record<string, unknown> }) {
  const json = JSON.stringify(data, null, 2);

  // Syntax highlight: keys in accent, strings in foreground, numbers in muted
  const highlighted = json
    .replace(/("[\w_]+")\s*:/g, '<span class="text-accent">$1</span>:')
    .replace(/:\s*("([^"]*)")/g, ': <span class="text-foreground/80">$1</span>')
    .replace(
      /:\s*(\d+(\.\d+)?)/g,
      ': <span class="text-foreground/70">$1</span>',
    )
    .replace(/:\s*(true|false)/g, ': <span class="text-accent/70">$1</span>');

  return (
    <pre
      className="code-block text-xs leading-relaxed overflow-x-auto"
      // biome-ignore lint/security/noDangerouslySetInnerHtml: syntax highlighting
      dangerouslySetInnerHTML={{ __html: highlighted }}
    />
  );
}

// ── Section: Hero ────────────────────────────────────────────────────────────
function HeroSection() {
  return (
    <section className="section-base" data-ocid="section-hero">
      <div className="landing-container pt-24 pb-20 md:pt-28 md:pb-24">
        <div className="max-w-4xl">
          {/* Category tag */}
          <div className="inline-flex items-center gap-2 border border-border bg-card px-3 py-1 rounded-sm mb-8">
            <span className="w-1.5 h-1.5 rounded-full bg-accent" />
            <span className="font-mono text-xs text-muted-foreground tracking-widest uppercase">
              Execution Layer
            </span>
          </div>

          {/* Headline */}
          <h1 className="font-mono text-4xl md:text-6xl font-bold tracking-tight text-foreground leading-[1.1] mb-6">
            Deterministic <span className="text-accent">primitives</span>
            <br />
            for AI agents
          </h1>

          {/* Subheadline */}
          <p className="font-body text-lg md:text-xl text-muted-foreground leading-relaxed max-w-2xl mb-10">
            AI agents break when tools are inconsistent. Replace fragile,
            monolithic tools with atomic, deterministic primitives — strict
            contracts, same input same output every time. Compose them on demand
            to build any workflow.
          </p>

          {/* CTA row */}
          <div className="flex flex-wrap items-center gap-4 mb-10">
            <GetStartedButton />
            <a
              href="#how-it-works"
              className="font-mono text-sm text-muted-foreground hover:text-foreground transition-colors border-b border-transparent hover:border-muted-foreground"
            >
              See how it works →
            </a>
          </div>

          {/* Trust signal */}
          <div className="inline-flex items-center gap-2" data-ocid="badge-icp">
            <span className="font-mono text-xs text-muted-foreground/50 tracking-wide">
              ⬡ Powered by Internet Computer
            </span>
          </div>
        </div>
      </div>
    </section>
  );
}

// ── Section: Problem / Solution ─────────────────────────────────────────────
function ProblemSolutionSection() {
  const problems = [
    "Inconsistent tool schemas across providers",
    "Fragile workflows that break on schema changes",
    "Hard to debug — no standardized error handling",
    "Limited flexibility — agents can only use what exists",
  ];

  const solutions = [
    "Atomic primitives with strict JSON contracts",
    "Deterministic execution — same input, same output",
    "Standardized error and success responses",
    "Compose any workflow dynamically at runtime",
  ];

  return (
    <section className="section-alt" data-ocid="section-problem-solution">
      <div className="landing-container">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Problem */}
          <div className="bg-card border border-border rounded-sm p-6 md:p-8">
            <div className="flex items-center gap-2 mb-6">
              <XCircle size={16} className="text-destructive flex-shrink-0" />
              <h2 className="font-mono text-lg font-semibold tracking-tight text-foreground">
                The Problem
              </h2>
            </div>
            <ul className="space-y-4">
              {problems.map((p) => (
                <li key={p} className="flex items-start gap-3">
                  <span className="w-1 h-1 rounded-full bg-destructive mt-2.5 flex-shrink-0" />
                  <span className="font-body text-sm text-muted-foreground leading-relaxed">
                    {p}
                  </span>
                </li>
              ))}
            </ul>
          </div>

          {/* Solution */}
          <div className="bg-card border border-border rounded-sm p-6 md:p-8">
            <div className="flex items-center gap-2 mb-6">
              <CheckCircle
                size={16}
                className="text-[oklch(0.7_0.18_145)] flex-shrink-0"
              />
              <h2 className="font-mono text-lg font-semibold tracking-tight text-foreground">
                The Solution
              </h2>
            </div>
            <ul className="space-y-4">
              {solutions.map((s) => (
                <li key={s} className="flex items-start gap-3">
                  <span className="w-1 h-1 rounded-full bg-[oklch(0.7_0.18_145)] mt-2.5 flex-shrink-0" />
                  <span className="font-body text-sm text-muted-foreground leading-relaxed">
                    {s}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </section>
  );
}

// ── Section: How It Works ───────────────────────────────────────────────────
const HOW_STEPS = [
  {
    num: "01",
    icon: Search,
    title: "Search Capabilities",
    desc: "Browse 42 atomic primitives by category or search by name.",
  },
  {
    num: "02",
    icon: Play,
    title: "Execute Primitives",
    desc: "Call any primitive with a structured JSON input, get a structured output.",
  },
  {
    num: "03",
    icon: Link2,
    title: "Connect Outputs",
    desc: "Pipe outputs from one primitive as inputs to the next.",
  },
  {
    num: "04",
    icon: Layers,
    title: "Build Any Workflow",
    desc: "Agents compose primitives dynamically at runtime — no pre-built sequences needed.",
  },
];

function HowItWorksSection() {
  return (
    <section
      className="section-base"
      id="how-it-works"
      data-ocid="section-how-it-works"
    >
      <div className="landing-container">
        <div className="mb-12">
          <h2 className="font-mono text-2xl md:text-3xl font-bold tracking-tight text-foreground mb-3">
            How It Works
          </h2>
          <p className="font-body text-muted-foreground">
            Four steps from discovery to dynamic workflow construction.
          </p>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {HOW_STEPS.map(({ num, icon: Icon, title, desc }, i) => (
            <div
              key={num}
              className="bg-card border border-border rounded-sm p-6 relative"
              data-ocid={`step-${i + 1}`}
            >
              {/* Step number */}
              <div className="font-mono text-4xl font-bold text-accent/20 mb-4 leading-none">
                {num}
              </div>
              <div className="flex items-center gap-2 mb-3">
                <Icon size={14} className="text-accent flex-shrink-0" />
                <h3 className="font-mono text-sm font-semibold tracking-tight text-foreground">
                  {title}
                </h3>
              </div>
              <p className="font-body text-xs text-muted-foreground leading-relaxed">
                {desc}
              </p>
              {/* Connector line (desktop, not last) */}
              {i < HOW_STEPS.length - 1 && (
                <div className="hidden lg:block absolute top-1/2 -right-2 w-4 h-px bg-border" />
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ── Section: Benefits Grid ───────────────────────────────────────────────────
const BENEFITS = [
  {
    title: "Reliability",
    desc: "Strict input/output contracts mean consistent behavior across every call.",
  },
  {
    title: "Flexibility",
    desc: "42 atomic building blocks combine into infinite workflows.",
  },
  {
    title: "Composability",
    desc: "Outputs feed directly into inputs. Agents chain as needed.",
  },
  {
    title: "Debuggability",
    desc: "Every execution logs inputs, outputs, errors, and latency.",
  },
  {
    title: "Scalability",
    desc: "New capabilities added without changing system contracts.",
  },
];

function BenefitsSection() {
  return (
    <section className="section-alt" data-ocid="section-benefits">
      <div className="landing-container">
        <div className="mb-12">
          <h2 className="font-mono text-2xl md:text-3xl font-bold tracking-tight text-foreground mb-3">
            Why Primitives
          </h2>
          <p className="font-body text-muted-foreground">
            The execution properties that make agents reliable.
          </p>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {BENEFITS.map(({ title, desc }) => (
            <div
              key={title}
              className="bg-background border border-border rounded-sm p-6"
              data-ocid={`benefit-${title.toLowerCase()}`}
            >
              <div className="font-mono text-xs text-accent uppercase tracking-widest mb-3">
                {title}
              </div>
              <p className="font-body text-sm text-muted-foreground leading-relaxed">
                {desc}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ── Section: Primitives Showcase ────────────────────────────────────────────
const PRIMITIVES = [
  {
    name: "fetch_url",
    desc: "Fetch any HTTP URL and return the response body and status.",
    input: {
      url: "https://api.example.com/data",
      method: "GET",
      max_response_bytes: 5000,
    },
    output: {
      success: true,
      output: { status: 200, body: '{"price":70234}', cache_hit: false },
    },
  },
  {
    name: "parse_json",
    desc: "Parse a JSON string and validate its structure.",
    input: {
      json_string: '{"user":"alice","score":98}',
      validate: true,
    },
    output: {
      success: true,
      output: {
        parsed: { user: "alice", score: 98 },
        valid: true,
        key_count: 2,
      },
    },
  },
  {
    name: "extract_fields",
    desc: "Extract specific fields from a structured object.",
    input: {
      data: { user: "alice", score: 98, rank: 1 },
      fields: ["user", "score"],
    },
    output: {
      success: true,
      output: { extracted: { user: "alice", score: 98 }, found: 2, missing: 0 },
    },
  },
  {
    name: "compute_math",
    desc: "Evaluate a mathematical expression with optional variables.",
    input: {
      expression: "(score * weight) / 100",
      variables: { score: 98, weight: 0.85 },
    },
    output: {
      success: true,
      output: { result: 0.833, expression: "(score * weight) / 100" },
    },
  },
];

function PrimitivesShowcaseSection() {
  return (
    <section className="section-base" data-ocid="section-primitives">
      <div className="landing-container">
        <div className="mb-12">
          <h2 className="font-mono text-2xl md:text-3xl font-bold tracking-tight text-foreground mb-3">
            Example Primitives
          </h2>
          <p className="font-body text-muted-foreground">
            Every primitive has a strict input contract and a predictable
            output.
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {PRIMITIVES.map(({ name, desc, input, output }) => (
            <div
              key={name}
              className="bg-card border border-border rounded-sm p-6"
              data-ocid={`primitive-${name}`}
            >
              {/* Name + description */}
              <div className="flex items-start justify-between gap-4 mb-4">
                <div>
                  <div className="font-mono text-sm font-semibold text-accent mb-1">
                    {name}
                  </div>
                  <p className="font-body text-xs text-muted-foreground leading-relaxed">
                    {desc}
                  </p>
                </div>
              </div>

              <div className="border-t border-border pt-4 space-y-3">
                {/* Input */}
                <div>
                  <div className="font-mono text-xs text-muted-foreground/60 uppercase tracking-widest mb-1.5">
                    Input
                  </div>
                  <CodeBlock data={input as Record<string, unknown>} />
                </div>
                {/* Output */}
                <div>
                  <div className="font-mono text-xs text-muted-foreground/60 uppercase tracking-widest mb-1.5">
                    Output
                  </div>
                  <CodeBlock data={output as Record<string, unknown>} />
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ── Section: Developer Experience ───────────────────────────────────────────
const DX_CARDS = [
  {
    icon: "[ ]",
    title: "Capability Explorer",
    desc: "Browse all 42 primitives with full input/output schemas, constraints, and usage examples.",
  },
  {
    icon: "> _",
    title: "Live Playground",
    desc: "Test any primitive directly in the browser. See real outputs before integrating.",
  },
  {
    icon: "{ }",
    title: "Execution Logs",
    desc: "Every call is logged with full inputs, outputs, errors, and cycle cost for auditability.",
  },
];

function DeveloperExperienceSection() {
  return (
    <section className="section-alt" data-ocid="section-dx">
      <div className="landing-container">
        <div className="mb-12">
          <h2 className="font-mono text-2xl md:text-3xl font-bold tracking-tight text-foreground mb-3">
            Built for Developers
          </h2>
          <p className="font-body text-muted-foreground">
            Tools to explore, test, and integrate without guesswork.
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {DX_CARDS.map(({ icon, title, desc }) => (
            <div
              key={title}
              className="bg-background border border-border rounded-sm p-6"
              data-ocid={`dx-${title.toLowerCase().replace(/\s+/g, "-")}`}
            >
              <div className="font-mono text-lg text-accent/60 mb-4 leading-none tracking-tighter">
                {icon}
              </div>
              <h3 className="font-mono text-sm font-semibold tracking-tight text-foreground mb-2">
                {title}
              </h3>
              <p className="font-body text-sm text-muted-foreground leading-relaxed">
                {desc}
              </p>
            </div>
          ))}
        </div>

        {/* CTA row */}
        <div className="mt-12 border-t border-border pt-10 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
          <div>
            <p className="font-mono text-sm text-foreground mb-1">
              Ready to build?
            </p>
            <p className="font-body text-xs text-muted-foreground">
              Authenticate with Internet Identity and start executing primitives
              in seconds.
            </p>
          </div>
          <GetStartedButton />
        </div>
      </div>
    </section>
  );
}

// ── Section: Footer ──────────────────────────────────────────────────────────
function FooterSection() {
  const year = new Date().getFullYear();
  const hostname =
    typeof window !== "undefined" ? window.location.hostname : "";

  return (
    <footer className="bg-card border-t border-border" data-ocid="footer">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          {/* Left: brand */}
          <div>
            <div className="flex items-center gap-2 mb-1">
              <Zap size={14} className="text-accent" />
              <span className="font-mono text-sm font-semibold text-foreground">
                AgentLayer
              </span>
            </div>
            <p className="font-body text-xs text-muted-foreground">
              Deterministic execution layer for AI agents
            </p>
          </div>

          {/* Center: ICP */}
          <div className="font-mono text-xs text-muted-foreground/50 tracking-wide">
            ⬡ Powered by Internet Computer
          </div>

          {/* Right: copyright */}
          <div className="font-body text-xs text-muted-foreground/50">
            © {year} AgentLayer. All rights reserved.
            <br />
            <a
              href={`https://caffeine.ai?utm_source=caffeine-footer&utm_medium=referral&utm_content=${encodeURIComponent(hostname)}`}
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-muted-foreground transition-colors"
            >
              Built with caffeine.ai
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}

// ── Landing Page ─────────────────────────────────────────────────────────────
export default function LandingPage() {
  return (
    <div
      className="min-h-screen bg-background flex flex-col"
      data-ocid="landing-page"
    >
      <HeroSection />
      <ProblemSolutionSection />
      <HowItWorksSection />
      <BenefitsSection />
      <PrimitivesShowcaseSection />
      <DeveloperExperienceSection />
      <FooterSection />
    </div>
  );
}
