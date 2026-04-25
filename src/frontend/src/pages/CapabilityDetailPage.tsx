import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useNavigate, useParams } from "@tanstack/react-router";
import { ArrowLeft, ExternalLink, Shield } from "lucide-react";
import { useCapability } from "../hooks/useBackend";
import type { CapabilityInput, CapabilityOutput } from "../types";

const CATEGORY_COLORS: Record<string, string> = {
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
  Meta: "text-chart-4 border-chart-4/30",
};

// Type badge colors mapped per type
const TYPE_COLORS: Record<string, string> = {
  string: "text-chart-2 border-chart-2/20 bg-chart-2/5",
  number: "text-chart-5 border-chart-5/20 bg-chart-5/5",
  integer: "text-chart-5 border-chart-5/20 bg-chart-5/5",
  boolean: "text-chart-1 border-chart-1/20 bg-chart-1/5",
  array: "text-chart-3 border-chart-3/20 bg-chart-3/5",
  object: "text-chart-4 border-chart-4/20 bg-chart-4/5",
};

function TypeBadge({ type }: { type: string }) {
  const cls =
    TYPE_COLORS[type] ?? "text-muted-foreground border-border bg-secondary/40";
  return (
    <span
      className={`inline-flex items-center text-[10px] font-mono px-1.5 py-0.5 rounded border ${cls}`}
    >
      {type}
    </span>
  );
}

function SchemaLabel({ label }: { label: string }) {
  return (
    <h3 className="text-xs font-mono text-muted-foreground uppercase tracking-widest mb-3">
      {label}
    </h3>
  );
}

function InputsTable({ inputs }: { inputs: CapabilityInput[] }) {
  if (inputs.length === 0) {
    return (
      <div className="border border-border rounded px-4 py-3 text-xs text-muted-foreground/50 font-mono">
        no inputs
      </div>
    );
  }
  return (
    <div className="border border-border rounded overflow-hidden">
      <table className="w-full text-xs">
        <thead>
          <tr className="border-b border-border bg-secondary/30">
            <th className="px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal w-40">
              field
            </th>
            <th className="px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal w-28">
              type
            </th>
            <th className="px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal w-24">
              required
            </th>
            <th className="px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal">
              description
            </th>
          </tr>
        </thead>
        <tbody>
          {inputs.map((inp) => (
            <tr
              key={inp.key}
              className="border-b border-border last:border-0 hover:bg-secondary/20 transition-smooth"
            >
              <td className="px-4 py-3 font-mono text-foreground">{inp.key}</td>
              <td className="px-4 py-3">
                <TypeBadge type={inp.inputType} />
              </td>
              <td className="px-4 py-3 font-mono">
                {inp.required ? (
                  <span className="text-[10px] px-1.5 py-0.5 rounded border border-destructive/30 text-destructive/80 bg-destructive/5 font-mono">
                    required
                  </span>
                ) : (
                  <span className="text-[10px] px-1.5 py-0.5 rounded border border-border text-muted-foreground/50 bg-secondary/30 font-mono">
                    optional
                  </span>
                )}
              </td>
              <td className="px-4 py-3 text-muted-foreground font-body leading-relaxed">
                {inp.description || (
                  <span className="text-muted-foreground/30">—</span>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function OutputsTable({ outputs }: { outputs: CapabilityOutput[] }) {
  if (outputs.length === 0) {
    return (
      <div className="border border-border rounded px-4 py-3 text-xs text-muted-foreground/50 font-mono">
        no outputs
      </div>
    );
  }
  return (
    <div className="border border-border rounded overflow-hidden">
      <table className="w-full text-xs">
        <thead>
          <tr className="border-b border-border bg-secondary/30">
            <th className="px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal w-40">
              field
            </th>
            <th className="px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal w-28">
              type
            </th>
            <th className="px-4 py-2.5 text-left font-mono text-muted-foreground/60 font-normal">
              description
            </th>
          </tr>
        </thead>
        <tbody>
          {outputs.map((out) => (
            <tr
              key={out.key}
              className="border-b border-border last:border-0 hover:bg-secondary/20 transition-smooth"
            >
              <td className="px-4 py-3 font-mono text-foreground">{out.key}</td>
              <td className="px-4 py-3">
                <TypeBadge type={out.outputType} />
              </td>
              <td className="px-4 py-3 text-muted-foreground font-body leading-relaxed">
                {out.description || (
                  <span className="text-muted-foreground/30">—</span>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function CodeBlock({ title, code }: { title: string; code: string }) {
  let pretty = code;
  try {
    pretty = JSON.stringify(JSON.parse(code), null, 2);
  } catch {
    // already formatted or not JSON
  }
  return (
    <div className="flex flex-col min-w-0">
      <div className="flex items-center gap-2 px-3 py-2 border border-border rounded-t bg-secondary/30 border-b-0">
        <span className="text-[10px] font-mono text-muted-foreground/70 uppercase tracking-wider">
          {title}
        </span>
      </div>
      <pre className="font-mono text-xs p-4 border border-border rounded-b bg-secondary/10 text-foreground overflow-x-auto leading-relaxed whitespace-pre-wrap break-all">
        {pretty}
      </pre>
    </div>
  );
}

const SKELETON_SECTION_KEYS = ["sk-a", "sk-b", "sk-c"] as const;

export default function CapabilityDetailPage() {
  const { name } = useParams({ from: "/capabilities/$name" });
  const { data: cap, isPending: isLoading } = useCapability(name);
  const navigate = useNavigate();

  const colorClass = cap
    ? (CATEGORY_COLORS[cap.category] ?? "text-muted-foreground border-border")
    : "";

  return (
    <div className="flex flex-col h-full">
      {/* Top bar */}
      <div className="border-b border-border px-6 py-3 bg-card flex items-center gap-3 shrink-0">
        <button
          type="button"
          onClick={() => navigate({ to: "/" })}
          data-ocid="back-to-capabilities"
          className="flex items-center gap-1.5 text-xs text-muted-foreground hover:text-foreground transition-smooth font-mono"
        >
          <ArrowLeft size={12} />
          capabilities
        </button>
        <span className="text-muted-foreground/30">/</span>
        {isLoading ? (
          <Skeleton className="h-4 w-32" />
        ) : (
          <span className="text-xs font-mono text-foreground">{name}()</span>
        )}
      </div>

      <div className="flex-1 overflow-y-auto">
        {isLoading ? (
          <div className="max-w-4xl mx-auto px-6 py-8 space-y-8">
            <div className="space-y-2">
              <Skeleton className="h-7 w-64" />
              <Skeleton className="h-4 w-96" />
            </div>
            {SKELETON_SECTION_KEYS.map((k) => (
              <div key={k} className="space-y-3">
                <Skeleton className="h-3 w-20" />
                <Skeleton className="h-24 w-full" />
              </div>
            ))}
          </div>
        ) : !cap ? (
          <div
            className="flex flex-col items-center justify-center h-64 text-center p-8"
            data-ocid="capability-not-found"
          >
            <div className="font-mono text-3xl text-muted-foreground/15 mb-3">
              404
            </div>
            <p className="text-sm text-muted-foreground font-body">
              Capability not found
            </p>
            <button
              type="button"
              onClick={() => navigate({ to: "/" })}
              className="mt-3 text-xs text-accent font-mono hover:underline"
            >
              ← back to list
            </button>
          </div>
        ) : (
          <div className="max-w-4xl mx-auto px-6 py-8 space-y-8">
            {/* Header */}
            <div>
              <div className="flex items-center gap-3 mb-3">
                <h1 className="font-display text-xl font-semibold text-foreground tracking-tight">
                  {cap.name}
                  <span className="text-muted-foreground/40">()</span>
                </h1>
                <Badge
                  variant="outline"
                  className={`font-mono text-xs border ${colorClass}`}
                >
                  {cap.category}
                </Badge>
                <Badge
                  variant="outline"
                  className="font-mono text-xs border border-border text-muted-foreground/50"
                >
                  v1.0.0
                </Badge>
              </div>

              {/* Description */}
              <p className="text-sm text-foreground/80 font-body leading-relaxed max-w-2xl">
                {cap.description}
              </p>

              {/* Constraints */}
              {cap.constraints.length > 0 && (
                <div className="mt-3 flex items-start gap-2">
                  <Shield
                    size={12}
                    className="text-muted-foreground/40 mt-0.5 shrink-0"
                  />
                  <p className="text-xs text-muted-foreground/60 font-body leading-relaxed">
                    {cap.constraints.join(" · ")}
                  </p>
                </div>
              )}

              {/* CTA */}
              <div className="mt-5">
                <Button
                  variant="outline"
                  size="sm"
                  data-ocid="open-in-playground"
                  onClick={() =>
                    navigate({
                      to: "/playground",
                      search: { capability: cap.name },
                    })
                  }
                  className="font-mono text-xs border-accent/40 text-accent hover:bg-accent/10 hover:text-accent gap-1.5"
                >
                  Open in Playground
                  <ExternalLink size={11} />
                </Button>
              </div>
            </div>

            {/* Divider */}
            <div className="border-t border-border" />

            {/* Inputs */}
            <section data-ocid="inputs-section">
              <SchemaLabel label={`Inputs (${cap.inputs.length})`} />
              <InputsTable inputs={cap.inputs} />
            </section>

            {/* Outputs */}
            <section data-ocid="outputs-section">
              <SchemaLabel label={`Outputs (${cap.outputs.length})`} />
              <OutputsTable outputs={cap.outputs} />
            </section>

            {/* Constraints detail */}
            {cap.constraints.length > 0 && (
              <section data-ocid="constraints-section">
                <SchemaLabel label="Constraints" />
                <ul className="space-y-2">
                  {cap.constraints.map((c) => (
                    <li
                      key={c}
                      className="flex items-start gap-2.5 text-xs text-muted-foreground font-body"
                    >
                      <span className="mt-0.5 text-muted-foreground/30 font-mono shrink-0">
                        —
                      </span>
                      {c}
                    </li>
                  ))}
                </ul>
              </section>
            )}

            {/* Example */}
            <section data-ocid="example-section">
              <SchemaLabel label="Example" />
              <p className="text-xs text-muted-foreground/60 font-body mb-4 leading-relaxed">
                A representative invocation — use "Load Example" in the
                playground to pre-fill these exact values.
              </p>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <CodeBlock title="Input" code={cap.exampleInput} />
                <CodeBlock title="Output" code={cap.exampleOutput} />
              </div>
            </section>

            {/* Bottom CTA */}
            <div className="border-t border-border pt-6 flex items-center gap-3">
              <Button
                variant="outline"
                size="sm"
                data-ocid="open-in-playground-bottom"
                onClick={() =>
                  navigate({
                    to: "/playground",
                    search: { capability: cap.name },
                  })
                }
                className="font-mono text-xs border-accent/40 text-accent hover:bg-accent/10 hover:text-accent gap-1.5"
              >
                Open in Playground
                <ExternalLink size={11} />
              </Button>
              <span className="text-xs text-muted-foreground/40 font-body">
                Test this capability live with the example above
              </span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
