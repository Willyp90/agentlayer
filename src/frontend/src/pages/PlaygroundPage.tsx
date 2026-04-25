import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";
import { useSearch } from "@tanstack/react-router";
import {
  BookOpen,
  ChevronDown,
  Clock,
  Eye,
  EyeOff,
  Key,
  Play,
  Shield,
  Sparkles,
  Terminal,
  X,
} from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
import { CapabilityForm } from "../components/CapabilityForm";
import { ExecutionOutput } from "../components/ExecutionOutput";
import { useCapabilities, useExecuteCapability } from "../hooks/useBackend";
import type { CapabilityInfo, ExecutionResult } from "../types";

// ── Shared constants ──────────────────────────────────────────────────────────

const SKELETON_ROWS = ["sk-a", "sk-b", "sk-c", "sk-d", "sk-e"];

// ── API Key Auth section ──────────────────────────────────────────────────────

function ApiKeySection({
  apiKey,
  onChange,
}: {
  apiKey: string;
  onChange: (v: string) => void;
}) {
  const [expanded, setExpanded] = useState(false);
  const [revealed, setRevealed] = useState(false);

  return (
    <div className="border-b border-border shrink-0 bg-secondary/10">
      <button
        type="button"
        onClick={() => setExpanded((v) => !v)}
        data-ocid="api-key-section-toggle"
        className="w-full flex items-center gap-2 px-4 py-2.5 hover:bg-secondary/30 transition-smooth"
      >
        <Key
          size={12}
          className={cn(
            "shrink-0",
            apiKey ? "text-accent" : "text-muted-foreground/50",
          )}
        />
        <span className="text-[10px] font-mono text-muted-foreground/70 uppercase tracking-wider flex-1 text-left">
          Agent Authentication (Optional)
        </span>
        {apiKey && (
          <Badge
            variant="outline"
            className="text-[9px] h-4 px-1.5 font-mono border-accent/40 text-accent bg-accent/8"
          >
            key set
          </Badge>
        )}
        <ChevronDown
          size={12}
          className={cn(
            "text-muted-foreground/40 transition-transform duration-150",
            expanded && "rotate-180",
          )}
        />
      </button>
      {expanded && (
        <div className="px-4 pb-3 space-y-2">
          <p className="text-[10px] font-body text-muted-foreground/60 leading-relaxed">
            Enter an API key to test agent/headless authentication. Leave blank
            to use your Internet Identity.
          </p>
          <div className="flex items-center gap-2">
            <div className="relative flex-1">
              <input
                type={revealed ? "text" : "password"}
                value={apiKey}
                onChange={(e) => onChange(e.target.value)}
                placeholder="al_••••••••••••••••••••••••••••••"
                data-ocid="input-api-key"
                className="w-full px-3 py-2 pr-9 text-xs font-mono bg-secondary/40 border border-input rounded focus:outline-none focus:ring-1 focus:ring-ring placeholder:text-muted-foreground/30 text-foreground"
              />
              <button
                type="button"
                onClick={() => setRevealed((v) => !v)}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground/40 hover:text-muted-foreground transition-colors duration-150"
                aria-label={revealed ? "Hide key" : "Show key"}
                data-ocid="btn-toggle-key-reveal"
              >
                {revealed ? <EyeOff size={12} /> : <Eye size={12} />}
              </button>
            </div>
            {apiKey && (
              <button
                type="button"
                onClick={() => onChange("")}
                className="p-1.5 rounded text-muted-foreground/40 hover:text-muted-foreground hover:bg-secondary/50 transition-smooth"
                aria-label="Clear API key"
                data-ocid="btn-clear-api-key"
              >
                <X size={12} />
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ── Auth badge for output ─────────────────────────────────────────────────────

function AuthBadge({ usedApiKey }: { usedApiKey: boolean }) {
  return (
    <Badge
      variant="outline"
      className={cn(
        "text-[9px] h-4 px-1.5 font-mono gap-1",
        usedApiKey
          ? "border-accent/40 text-accent bg-accent/8"
          : "border-border text-muted-foreground/60",
      )}
    >
      <Key size={8} />
      {usedApiKey ? "API Key" : "Internet Identity"}
    </Badge>
  );
}

// ── Capability info panel ─────────────────────────────────────────────────────

function CapabilityInfoPanel({
  cap,
  onLoadExample,
}: {
  cap: CapabilityInfo;
  onLoadExample: () => void;
}) {
  const [exampleOpen, setExampleOpen] = useState(false);

  let prettyExample = cap.exampleOutput;
  try {
    prettyExample = JSON.stringify(JSON.parse(cap.exampleOutput), null, 2);
  } catch {
    // keep as-is
  }

  return (
    <div className="border-b border-border bg-card/40 shrink-0">
      {/* Description row — always visible */}
      <div className="px-4 pt-3 pb-2 flex flex-col gap-2">
        <div className="flex items-start justify-between gap-3">
          <div className="flex-1 min-w-0">
            <p className="text-xs font-body text-muted-foreground leading-relaxed">
              {cap.description}
            </p>
          </div>
          {/* Constraints pill */}
          {cap.constraints.length > 0 && (
            <div
              className="hidden lg:flex items-center gap-1.5 shrink-0"
              title={cap.constraints.join(" · ")}
            >
              <Shield size={10} className="text-muted-foreground/40 shrink-0" />
              <span className="text-[10px] font-mono text-muted-foreground/40 max-w-[200px] truncate">
                {cap.constraints[0]}
                {cap.constraints.length > 1 &&
                  ` +${cap.constraints.length - 1}`}
              </span>
            </div>
          )}
        </div>

        {/* Action row */}
        <div className="flex items-center gap-2 flex-wrap">
          <button
            type="button"
            onClick={onLoadExample}
            data-ocid="btn-load-example"
            className="inline-flex items-center gap-1.5 px-2.5 py-1 text-[11px] font-mono border border-accent/30 text-accent rounded hover:bg-accent/10 transition-smooth"
          >
            <Sparkles size={10} />
            Load Example
          </button>
          <button
            type="button"
            onClick={() => setExampleOpen((v) => !v)}
            data-ocid="btn-toggle-example-output"
            className="inline-flex items-center gap-1.5 px-2.5 py-1 text-[11px] font-mono border border-border text-muted-foreground rounded hover:text-foreground hover:border-foreground/30 transition-smooth"
          >
            <BookOpen size={10} />
            Example Output
            <ChevronDown
              size={10}
              className={cn(
                "transition-transform duration-150",
                exampleOpen && "rotate-180",
              )}
            />
          </button>
        </div>
      </div>

      {/* Collapsible example output */}
      {exampleOpen && (
        <div className="px-4 pb-3 border-t border-border/60">
          <div className="mt-2 rounded border border-border bg-secondary/20 overflow-hidden">
            <div className="flex items-center gap-2 px-3 py-1.5 border-b border-border/60 bg-secondary/30">
              <span className="text-[10px] font-mono text-muted-foreground/60 uppercase tracking-wider">
                Expected output
              </span>
              <span className="text-[10px] font-mono text-muted-foreground/30 ml-auto">
                before execution
              </span>
            </div>
            <pre className="p-3 font-mono text-xs text-muted-foreground/80 overflow-x-auto leading-relaxed whitespace-pre-wrap break-all max-h-48 overflow-y-auto">
              {prettyExample}
            </pre>
          </div>
        </div>
      )}

      {/* Input/Output schema badges */}
      <div className="px-4 pb-2.5 flex gap-4 flex-wrap">
        {cap.inputs.length > 0 && (
          <div>
            <p className="text-[10px] font-mono text-muted-foreground/40 uppercase tracking-wider mb-1">
              Inputs
            </p>
            <div className="flex flex-wrap gap-1">
              {cap.inputs.map((inp) => (
                <span
                  key={inp.key}
                  className={cn(
                    "text-[10px] font-mono px-1.5 py-0.5 rounded border",
                    inp.required
                      ? "border-accent/25 bg-accent/8 text-accent/80"
                      : "border-border text-muted-foreground/60 bg-secondary/30",
                  )}
                  title={inp.description}
                >
                  {inp.key}
                  <span className="opacity-50">:{inp.inputType}</span>
                </span>
              ))}
            </div>
          </div>
        )}
        {cap.outputs.length > 0 && (
          <div>
            <p className="text-[10px] font-mono text-muted-foreground/40 uppercase tracking-wider mb-1">
              Outputs
            </p>
            <div className="flex flex-wrap gap-1">
              {cap.outputs.map((out) => (
                <span
                  key={out.key}
                  className="text-[10px] font-mono px-1.5 py-0.5 rounded border border-border text-muted-foreground/60 bg-secondary/30"
                  title={out.description}
                >
                  {out.key}
                  <span className="opacity-50">:{out.outputType}</span>
                </span>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Recent executions ─────────────────────────────────────────────────────────

interface RecentExecution {
  id: string;
  capability: string;
  success: boolean;
  timestamp: number;
  input: string;
  result: ExecutionResult;
  usedApiKey: boolean;
}

function RecentSidebar({
  recents,
  onReload,
}: {
  recents: RecentExecution[];
  onReload: (r: RecentExecution) => void;
}) {
  if (recents.length === 0) return null;
  return (
    <div className="w-56 shrink-0 border-l border-border flex flex-col hidden lg:flex">
      <div className="px-3 py-2 border-b border-border bg-secondary/20">
        <span className="text-[10px] font-mono text-muted-foreground uppercase tracking-wider">
          Recent
        </span>
      </div>
      <div className="flex-1 overflow-y-auto">
        {recents.map((r) => (
          <button
            key={r.id}
            type="button"
            onClick={() => onReload(r)}
            data-ocid={`recent-${r.id}`}
            className="w-full text-left px-3 py-2.5 border-b border-border/50 hover:bg-secondary/30 transition-smooth group"
          >
            <div className="flex items-center gap-1.5 mb-1">
              <Badge
                variant="outline"
                className={cn(
                  "text-[9px] h-3.5 px-1 py-0 font-mono",
                  r.success
                    ? "border-chart-2/40 text-chart-2 bg-chart-2/8"
                    : "border-destructive/40 text-destructive bg-destructive/8",
                )}
              >
                {r.success ? "ok" : "err"}
              </Badge>
              {r.usedApiKey && <Key size={8} className="text-accent/60" />}
            </div>
            <p className="text-[11px] font-mono text-foreground/80 truncate group-hover:text-foreground transition-smooth">
              {r.capability}()
            </p>
            <div className="flex items-center gap-1 mt-1">
              <Clock size={9} className="text-muted-foreground/40" />
              <span className="text-[10px] font-mono text-muted-foreground/40">
                {new Date(r.timestamp).toLocaleTimeString()}
              </span>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

function MobileRecentAccordion({
  recents,
  onReload,
}: {
  recents: RecentExecution[];
  onReload: (r: RecentExecution) => void;
}) {
  const [open, setOpen] = useState(false);
  if (recents.length === 0) return null;
  return (
    <div className="border-t border-border lg:hidden shrink-0">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="w-full flex items-center justify-between px-4 py-3 bg-card hover:bg-secondary/40 transition-smooth"
        data-ocid="recent-accordion-toggle"
      >
        <span className="text-xs font-mono text-muted-foreground uppercase tracking-wider">
          Recent Executions ({recents.length})
        </span>
        <ChevronDown
          size={12}
          className={`text-muted-foreground transition-transform duration-150 ${open ? "rotate-180" : ""}`}
        />
      </button>
      {open && (
        <div className="max-h-48 overflow-y-auto border-t border-border bg-card">
          {recents.map((r) => (
            <button
              key={r.id}
              type="button"
              onClick={() => onReload(r)}
              data-ocid={`recent-mobile-${r.id}`}
              className="w-full text-left px-4 py-3 border-b border-border/50 hover:bg-secondary/30 transition-smooth flex items-center gap-3 min-h-[44px]"
            >
              <Badge
                variant="outline"
                className={cn(
                  "text-[9px] h-5 px-1.5 font-mono shrink-0",
                  r.success
                    ? "border-chart-2/40 text-chart-2 bg-chart-2/8"
                    : "border-destructive/40 text-destructive bg-destructive/8",
                )}
              >
                {r.success ? "ok" : "err"}
              </Badge>
              <span className="font-mono text-sm text-foreground/80 truncate flex-1">
                {r.capability}()
              </span>
              <span className="text-xs font-mono text-muted-foreground/40 shrink-0">
                {new Date(r.timestamp).toLocaleTimeString()}
              </span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function MobileCapabilitySheet({
  open,
  onClose,
  capabilities,
  capsLoading,
  selectedCap,
  onSelect,
}: {
  open: boolean;
  onClose: () => void;
  capabilities: CapabilityInfo[];
  capsLoading: boolean;
  selectedCap: CapabilityInfo | null;
  onSelect: (cap: CapabilityInfo) => void;
}) {
  const [searchQuery, setSearchQuery] = useState("");

  const filtered = capabilities.filter(
    (c) =>
      !searchQuery ||
      c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.description.toLowerCase().includes(searchQuery.toLowerCase()),
  );

  const grouped = filtered.reduce<Record<string, CapabilityInfo[]>>(
    (acc, cap) => {
      const cat = cap.category;
      if (!acc[cat]) acc[cat] = [];
      acc[cat].push(cap);
      return acc;
    },
    {},
  );

  useEffect(() => {
    if (open) document.body.style.overflow = "hidden";
    else document.body.style.overflow = "";
    return () => {
      document.body.style.overflow = "";
    };
  }, [open]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 lg:hidden flex flex-col bg-background">
      <div className="flex items-center justify-between px-4 py-4 border-b border-border bg-card shrink-0">
        <span className="text-sm font-mono font-semibold text-foreground">
          Select Capability
        </span>
        <button
          type="button"
          onClick={() => {
            onClose();
            setSearchQuery("");
          }}
          className="w-10 h-10 flex items-center justify-center rounded text-muted-foreground hover:text-foreground hover:bg-secondary/50 transition-smooth"
          aria-label="Close"
          data-ocid="cap-sheet-close"
        >
          <X size={18} />
        </button>
      </div>
      <div className="px-4 py-3 border-b border-border bg-card shrink-0">
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search capabilities…"
          data-ocid="cap-search-mobile"
          className="w-full px-4 py-3 text-sm font-mono bg-secondary/40 border border-input rounded-lg focus:outline-none focus:ring-2 focus:ring-ring placeholder:text-muted-foreground/40"
        />
      </div>
      <div className="flex-1 overflow-y-auto">
        {capsLoading ? (
          <div className="p-4 space-y-3">
            {SKELETON_ROWS.map((k) => (
              <Skeleton key={k} className="h-12 w-full" />
            ))}
          </div>
        ) : Object.keys(grouped).length === 0 ? (
          <div className="p-6 text-sm text-muted-foreground font-mono text-center">
            No capabilities found
          </div>
        ) : (
          Object.entries(grouped).map(([category, caps]) => (
            <div key={category}>
              <div className="px-4 py-2 text-[10px] font-mono uppercase tracking-widest text-muted-foreground/50 bg-secondary/20 border-b border-border/50 sticky top-0">
                {category}
              </div>
              {caps.map((cap) => (
                <button
                  key={cap.name}
                  type="button"
                  onClick={() => {
                    onSelect(cap);
                    setSearchQuery("");
                  }}
                  data-ocid={`cap-option-mobile-${cap.name}`}
                  className={cn(
                    "w-full text-left px-4 py-4 border-b border-border/30 last:border-0 min-h-[56px] transition-smooth",
                    selectedCap?.name === cap.name
                      ? "bg-accent/10 text-accent"
                      : "hover:bg-secondary/40 text-foreground",
                  )}
                >
                  <span className="font-mono text-sm">{cap.name}()</span>
                </button>
              ))}
            </div>
          ))
        )}
      </div>
    </div>
  );
}

// ── Playground panel ──────────────────────────────────────────────────────────

function PrimitivesPanel() {
  const { data: capabilities, isPending: capsLoading } = useCapabilities();
  const execute = useExecuteCapability();

  const [selectedCap, setSelectedCap] = useState<CapabilityInfo | null>(null);
  const [inputJson, setInputJson] = useState("{}");
  const [inputMode, setInputMode] = useState<"form" | "json">("form");
  const [validationErrors, setValidationErrors] = useState<string[]>([]);
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [mobileSheetOpen, setMobileSheetOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [recents, setRecents] = useState<RecentExecution[]>([]);
  const [apiKey, setApiKey] = useState("");

  const dropRef = useRef<HTMLDivElement>(null);
  const outputRef = useRef<HTMLDivElement>(null);

  // Read ?capability= param on mount
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const capName = params.get("capability");
    if (capName && capabilities) {
      const found = capabilities.find((c) => c.name === capName);
      if (found) setSelectedCap(found);
    }
  }, [capabilities]);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (dropRef.current && !dropRef.current.contains(e.target as Node)) {
        setDropdownOpen(false);
        setSearchQuery("");
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const handleSelect = (cap: CapabilityInfo) => {
    setSelectedCap(cap);
    setInputJson(cap.exampleInput || "{}");
    setValidationErrors([]);
    setDropdownOpen(false);
    setMobileSheetOpen(false);
    setSearchQuery("");
  };

  const handleLoadExample = useCallback(() => {
    if (!selectedCap) return;
    setInputJson(selectedCap.exampleInput || "{}");
    setValidationErrors([]);
  }, [selectedCap]);

  const handleJsonChange = useCallback((v: string) => {
    setInputJson(v);
    setValidationErrors([]);
  }, []);

  const validateInput = (): boolean => {
    if (!selectedCap) return false;
    const errors: string[] = [];
    let parsed: Record<string, unknown> = {};
    try {
      parsed = JSON.parse(inputJson) as Record<string, unknown>;
    } catch {
      errors.push("Invalid JSON — check syntax");
      setValidationErrors(errors);
      return false;
    }
    for (const inp of selectedCap.inputs) {
      if (inp.required && !(inp.key in parsed)) {
        errors.push(`Missing required field: ${inp.key}`);
      } else if (inp.key in parsed) {
        const val = parsed[inp.key];
        if (inp.inputType === "boolean" && typeof val !== "boolean")
          errors.push(`${inp.key} must be boolean`);
        if (
          (inp.inputType === "number" || inp.inputType === "integer") &&
          typeof val !== "number"
        )
          errors.push(`${inp.key} must be a number`);
        if (inp.inputType === "string" && typeof val !== "string")
          errors.push(`${inp.key} must be a string`);
      }
    }
    setValidationErrors(errors);
    return errors.length === 0;
  };

  const handleRun = async () => {
    if (!selectedCap) return;
    if (!validateInput()) return;

    const result = await execute.mutateAsync({
      capability: selectedCap.name,
      input: inputJson,
      apiKey: apiKey.trim() || undefined,
    });

    const entry: RecentExecution = {
      id: result.executionId,
      capability: selectedCap.name,
      success: result.success,
      timestamp: Date.now(),
      input: inputJson,
      result,
      usedApiKey: !!apiKey.trim(),
    };
    setRecents((prev) => [entry, ...prev].slice(0, 5));

    const isMobile = window.innerWidth < 1024;
    if (isMobile && outputRef.current) {
      setTimeout(() => {
        outputRef.current?.scrollIntoView({
          behavior: "smooth",
          block: "start",
        });
      }, 100);
    }
  };

  const handleReload = (r: RecentExecution) => {
    const cap = capabilities?.find((c) => c.name === r.capability);
    if (cap) setSelectedCap(cap);
    setInputJson(r.input);
    setValidationErrors([]);
  };

  const filteredCaps = (capabilities ?? []).filter(
    (c) =>
      !searchQuery ||
      c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.description.toLowerCase().includes(searchQuery.toLowerCase()),
  );

  const grouped = filteredCaps.reduce<Record<string, CapabilityInfo[]>>(
    (acc, cap) => {
      const cat = cap.category;
      if (!acc[cat]) acc[cat] = [];
      acc[cat].push(cap);
      return acc;
    },
    {},
  );

  const lastResult = execute.data ?? null;
  const lastUsedApiKey = recents[0]?.usedApiKey ?? false;

  return (
    <>
      <MobileCapabilitySheet
        open={mobileSheetOpen}
        onClose={() => setMobileSheetOpen(false)}
        capabilities={capabilities ?? []}
        capsLoading={capsLoading}
        selectedCap={selectedCap}
        onSelect={handleSelect}
      />

      {/* Desktop capability selector */}
      <div className="hidden lg:flex items-center gap-2 px-4 py-2 border-b border-border bg-card/50 shrink-0">
        <div className="relative" ref={dropRef}>
          <button
            type="button"
            onClick={() => setDropdownOpen((v) => !v)}
            data-ocid="cap-selector"
            className="flex items-center gap-2 px-3 py-1.5 text-xs border border-input rounded bg-secondary/40 hover:bg-secondary text-foreground font-mono transition-smooth min-w-52"
          >
            <span className="flex-1 text-left truncate">
              {selectedCap ? (
                <>
                  <span className="text-accent">{selectedCap.name}</span>
                  <span className="text-muted-foreground">()</span>
                </>
              ) : (
                <span className="text-muted-foreground">
                  Select capability…
                </span>
              )}
            </span>
            <ChevronDown size={11} className="text-muted-foreground shrink-0" />
          </button>

          {dropdownOpen && (
            <div className="absolute top-full left-0 mt-1 w-80 max-h-80 border border-border rounded bg-popover shadow-xl z-50 flex flex-col">
              <div className="p-2 border-b border-border shrink-0">
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Search capabilities…"
                  data-ocid="cap-search"
                  className="w-full px-2.5 py-1.5 text-xs font-mono bg-secondary/40 border border-input rounded focus:outline-none focus:ring-1 focus:ring-ring placeholder:text-muted-foreground/40"
                  ref={(el) => el?.focus()}
                />
              </div>
              <div className="overflow-y-auto flex-1">
                {capsLoading ? (
                  <div className="p-3 space-y-2">
                    {SKELETON_ROWS.map((k) => (
                      <Skeleton key={k} className="h-7 w-full" />
                    ))}
                  </div>
                ) : Object.keys(grouped).length === 0 ? (
                  <div className="p-4 text-xs text-muted-foreground font-mono text-center">
                    No capabilities found
                  </div>
                ) : (
                  Object.entries(grouped).map(([category, caps]) => (
                    <div key={category}>
                      <div className="px-3 py-1.5 text-[10px] font-mono uppercase tracking-widest text-muted-foreground/50 bg-secondary/20 border-b border-border/50">
                        {category}
                      </div>
                      {caps.map((cap) => (
                        <button
                          key={cap.name}
                          type="button"
                          onClick={() => handleSelect(cap)}
                          data-ocid={`cap-option-${cap.name}`}
                          className={cn(
                            "w-full text-left px-3 py-2.5 text-xs transition-smooth border-b border-border/30 last:border-0",
                            selectedCap?.name === cap.name
                              ? "bg-accent/10 text-accent"
                              : "hover:bg-secondary/50 text-foreground",
                          )}
                        >
                          <span className="font-mono">{cap.name}()</span>
                        </button>
                      ))}
                    </div>
                  ))
                )}
              </div>
            </div>
          )}
        </div>

        <div className="flex-1" />

        <button
          type="button"
          onClick={validateInput}
          disabled={!selectedCap}
          data-ocid="btn-validate"
          className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-mono border border-border text-muted-foreground rounded hover:text-foreground hover:border-foreground/30 transition-smooth disabled:opacity-30 disabled:cursor-not-allowed"
        >
          Validate
        </button>
        <button
          type="button"
          onClick={handleRun}
          disabled={!selectedCap || execute.isPending}
          data-ocid="btn-run"
          className="flex items-center gap-1.5 px-4 py-1.5 text-xs font-mono bg-accent/10 border border-accent/30 text-accent rounded hover:bg-accent/20 transition-smooth disabled:opacity-40 disabled:cursor-not-allowed"
        >
          {execute.isPending ? (
            <>
              <span className="w-3 h-3 border border-accent/40 border-t-accent rounded-full animate-spin" />
              Running…
            </>
          ) : (
            <>
              <Play size={11} />
              Run
            </>
          )}
        </button>
      </div>

      {/* Mobile capability selector button */}
      <div className="lg:hidden px-4 py-2 border-b border-border bg-card/50 shrink-0">
        <button
          type="button"
          onClick={() => setMobileSheetOpen(true)}
          data-ocid="cap-selector-mobile"
          className="flex items-center gap-3 w-full min-h-[48px] px-4 py-3 text-sm border border-input rounded-lg bg-secondary/40 hover:bg-secondary text-foreground font-mono transition-smooth"
        >
          <span className="flex-1 text-left truncate">
            {selectedCap ? (
              <>
                <span className="text-accent">{selectedCap.name}</span>
                <span className="text-muted-foreground">()</span>
              </>
            ) : (
              <span className="text-muted-foreground">Select capability…</span>
            )}
          </span>
          <ChevronDown size={14} className="text-muted-foreground shrink-0" />
        </button>
      </div>

      {/* API Key section */}
      <ApiKeySection apiKey={apiKey} onChange={setApiKey} />

      {/* Capability info panel (description + load example + example output + schema) */}
      {selectedCap && (
        <CapabilityInfoPanel
          cap={selectedCap}
          onLoadExample={handleLoadExample}
        />
      )}

      {/* Main area */}
      <div className="flex flex-col lg:flex-row flex-1 overflow-hidden lg:overflow-hidden overflow-y-auto">
        <div
          className="flex flex-col lg:flex-1 lg:border-r border-b lg:border-b-0 border-border min-w-0 lg:min-h-0 lg:overflow-hidden"
          data-ocid="panel-input"
        >
          {selectedCap ? (
            <CapabilityForm
              capability={selectedCap}
              mode={inputMode}
              jsonValue={inputJson}
              onJsonChange={handleJsonChange}
              onModeChange={setInputMode}
              validationErrors={validationErrors}
            />
          ) : (
            <div className="flex items-center justify-center p-12 lg:flex-1 lg:h-full">
              <div className="text-center space-y-2" data-ocid="input-empty">
                <p className="text-sm font-mono text-muted-foreground/50">
                  Select a capability to begin
                </p>
                <p className="text-xs font-body text-muted-foreground/30">
                  or use <span className="font-mono">?capability=name</span> in
                  the URL
                </p>
              </div>
            </div>
          )}

          {selectedCap && (
            <div className="lg:hidden px-4 py-3 border-t border-border bg-card shrink-0 flex items-center gap-2">
              <button
                type="button"
                onClick={validateInput}
                disabled={!selectedCap}
                data-ocid="btn-validate-mobile"
                className="flex items-center justify-center gap-1.5 px-4 min-h-[48px] text-sm font-mono border border-border text-muted-foreground rounded-lg hover:text-foreground hover:border-foreground/30 transition-smooth disabled:opacity-30 disabled:cursor-not-allowed"
              >
                Validate
              </button>
              <button
                type="button"
                onClick={handleRun}
                disabled={!selectedCap || execute.isPending}
                data-ocid="btn-run-mobile"
                className="flex items-center justify-center gap-2 flex-1 min-h-[48px] text-sm font-mono bg-accent/10 border border-accent/30 text-accent rounded-lg hover:bg-accent/20 transition-smooth disabled:opacity-40 disabled:cursor-not-allowed"
              >
                {execute.isPending ? (
                  <>
                    <span className="w-4 h-4 border border-accent/40 border-t-accent rounded-full animate-spin" />
                    Running…
                  </>
                ) : (
                  <>
                    <Play size={14} />
                    Run
                  </>
                )}
              </button>
            </div>
          )}
        </div>

        <div
          ref={outputRef}
          className="flex flex-col lg:flex-1 min-w-0 lg:min-h-0 lg:overflow-hidden"
          data-ocid="panel-output"
        >
          {lastResult && (
            <div className="px-4 pt-3 pb-0 flex items-center gap-2 shrink-0">
              <AuthBadge usedApiKey={lastUsedApiKey} />
            </div>
          )}
          <ExecutionOutput
            result={lastResult}
            isPending={execute.isPending}
            isError={execute.isError}
            errorMessage={execute.error?.message}
          />
        </div>

        <RecentSidebar recents={recents} onReload={handleReload} />
      </div>

      <MobileRecentAccordion recents={recents} onReload={handleReload} />
    </>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function PlaygroundPage() {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const _search = useSearch({ from: "/playground" });

  return (
    <div className="flex flex-col h-full overflow-hidden">
      {/* Top bar with title */}
      <div className="border-b border-border px-4 py-2.5 bg-card shrink-0 flex items-center gap-3">
        <Terminal size={14} className="text-accent shrink-0" />
        <h1 className="font-display text-xs font-semibold text-muted-foreground uppercase tracking-widest">
          Playground
        </h1>
      </div>

      <PrimitivesPanel />
    </div>
  );
}
