import { Badge } from "@/components/ui/badge";
import { Check, Copy } from "lucide-react";
import { useState } from "react";
import type { ExecutionResult } from "../types";

interface Props {
  result: ExecutionResult | null;
  isPending: boolean;
  isError: boolean;
  errorMessage?: string;
}

function useClipboard() {
  const [copied, setCopied] = useState(false);
  const copy = async (text: string) => {
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };
  return { copied, copy };
}

function formatTimestamp(ns: bigint): string {
  const ms = Number(ns / 1_000_000n);
  return new Date(ms).toISOString().replace("T", " ").replace("Z", " UTC");
}

function SyntaxJson({ raw }: { raw: string }) {
  // Very lightweight JSON colorization via spans
  const lines = raw.split("\n");
  return (
    <div className="font-mono text-sm leading-relaxed">
      {lines.map((line, i) => {
        // color keys, strings, numbers, booleans, null
        const colored = line
          .replace(
            /("(?:[^"\\]|\\.)*")(\s*:)/g,
            '<span class="text-chart-1">$1</span>$2',
          )
          .replace(
            /:\s*("(?:[^"\\]|\\.)*")/g,
            ': <span class="text-chart-2">$1</span>',
          )
          .replace(
            /:\s*(\b\d+\.?\d*\b)/g,
            ': <span class="text-chart-4">$1</span>',
          )
          .replace(
            /:\s*(true|false|null)\b/g,
            ': <span class="text-accent">$1</span>',
          );
        return (
          <div
            key={`line-${line.substring(0, 20).replace(/\s+/g, "-")}-${i}`}
            className="flex"
          >
            <span className="select-none w-8 shrink-0 text-right pr-3 text-muted-foreground/30">
              {i + 1}
            </span>
            {/* biome-ignore lint/security/noDangerouslySetInnerHtml: controlled JSON colorization */}
            <span dangerouslySetInnerHTML={{ __html: colored }} />
          </div>
        );
      })}
    </div>
  );
}

export function ExecutionOutput({
  result,
  isPending,
  isError,
  errorMessage,
}: Props) {
  const [prettyMode, setPrettyMode] = useState(true);
  const { copied, copy } = useClipboard();

  const rawOutput = result
    ? JSON.stringify(
        {
          success: result.success,
          output: result.output ? JSON.parse(result.output) : null,
          error: result.error,
        },
        null,
        2,
      )
    : null;

  const displayText = rawOutput
    ? prettyMode
      ? rawOutput
      : JSON.stringify(JSON.parse(rawOutput))
    : null;

  return (
    <div className="flex flex-col lg:h-full lg:overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-border bg-secondary/20 shrink-0">
        <div className="flex items-center gap-3">
          <span className="text-sm font-mono text-muted-foreground">
            Output
          </span>
          {result && (
            <Badge
              variant="outline"
              className={
                result.success
                  ? "text-xs h-5 px-2 py-0 font-mono border-chart-2/40 text-chart-2 bg-chart-2/10"
                  : "text-xs h-5 px-2 py-0 font-mono border-destructive/40 text-destructive bg-destructive/10"
              }
              data-ocid="output-status"
            >
              {result.success ? "success" : "failed"}
            </Badge>
          )}
        </div>
        <div className="flex items-center gap-1">
          <button
            type="button"
            onClick={() => setPrettyMode((v) => !v)}
            data-ocid="btn-toggle-pretty"
            className="px-3 py-2 min-h-[36px] text-xs font-mono text-muted-foreground hover:text-foreground hover:bg-secondary/50 rounded transition-smooth"
          >
            {prettyMode ? "pretty" : "raw"}
          </button>
          {displayText && (
            <button
              type="button"
              onClick={() => copy(displayText)}
              data-ocid="btn-copy-output"
              className="w-9 h-9 flex items-center justify-center rounded text-muted-foreground hover:text-foreground hover:bg-secondary/50 transition-smooth"
              aria-label="Copy output"
            >
              {copied ? (
                <Check size={15} className="text-accent" />
              ) : (
                <Copy size={15} />
              )}
            </button>
          )}
        </div>
      </div>

      {/* Metadata bar — stacks vertically on mobile */}
      {result && (
        <div
          className="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-4 px-4 py-2.5 border-b border-border/50 bg-card shrink-0"
          data-ocid="output-meta"
        >
          <div className="flex items-center gap-3">
            <span className="text-xs font-mono text-muted-foreground/70 tabular-nums font-semibold">
              {result.latencyMs.toString()}ms
            </span>
            <span className="text-xs font-mono text-muted-foreground/50 truncate max-w-[240px] sm:max-w-[180px]">
              {result.executionId}
            </span>
          </div>
          {"timestamp" in result && (
            <span className="text-xs font-mono text-muted-foreground/40 sm:ml-auto">
              {formatTimestamp(
                (result as ExecutionResult & { timestamp: bigint }).timestamp,
              )}
            </span>
          )}
        </div>
      )}

      {/* Body */}
      <div
        className="lg:flex-1 lg:overflow-auto p-4 min-h-[200px]"
        data-ocid="output-area"
      >
        {isPending ? (
          <div className="flex items-center gap-3 text-muted-foreground py-4">
            <span className="w-4 h-4 border border-accent/40 border-t-accent rounded-full animate-spin" />
            <span className="text-sm font-mono">Executing…</span>
          </div>
        ) : isError ? (
          <div className="rounded-lg border border-destructive/30 bg-destructive/5 p-4">
            <p className="text-sm font-mono text-destructive whitespace-pre-wrap">
              {errorMessage ?? "Execution failed"}
            </p>
          </div>
        ) : result && !result.success && result.error ? (
          <div className="rounded-lg border border-destructive/30 bg-destructive/5 p-4 space-y-3">
            <div className="flex items-center gap-2">
              <Badge
                variant="outline"
                className="text-xs font-mono border-destructive/40 text-destructive bg-transparent"
              >
                {result.error.code}
              </Badge>
            </div>
            <p className="text-sm font-mono text-destructive/80">
              {result.error.message}
            </p>
          </div>
        ) : displayText ? (
          prettyMode ? (
            <SyntaxJson raw={displayText} />
          ) : (
            <pre className="text-sm font-mono text-foreground whitespace-pre-wrap break-all">
              {displayText}
            </pre>
          )
        ) : (
          <div
            className="flex items-center justify-center py-12 lg:h-full"
            data-ocid="output-empty"
          >
            <p className="text-sm text-muted-foreground font-mono">
              Output appears here after execution
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
