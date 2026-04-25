import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { useNavigate } from "@tanstack/react-router";
import { ArrowRight, ChevronDown, Search } from "lucide-react";
import { useState } from "react";
import { useCapabilities } from "../hooks/useBackend";
import type { CapabilityInfo } from "../types";

const CATEGORY_COLORS: Record<string, string> = {
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
  Meta: "text-chart-4 border-chart-4/30",
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
  "Meta",
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
  "s10",
] as const;

// ── Mobile card view ──────────────────────────────────────────────────────────

function CapabilityCard({ cap }: { cap: CapabilityInfo }) {
  const navigate = useNavigate();
  const colorClass =
    CATEGORY_COLORS[cap.category] ?? "text-muted-foreground border-border";

  return (
    <button
      type="button"
      onClick={() =>
        navigate({ to: "/capabilities/$name", params: { name: cap.name } })
      }
      data-ocid="capability-card"
      className="group w-full text-left p-4 border-b border-border hover:bg-secondary/60 transition-smooth active:bg-secondary/80"
    >
      <div className="flex items-start justify-between gap-3 mb-1.5">
        <span className="font-mono text-sm text-foreground group-hover:text-accent transition-smooth">
          {cap.name}
          <span className="text-muted-foreground/40">()</span>
        </span>
        <ArrowRight
          size={13}
          className="shrink-0 text-muted-foreground/30 group-hover:text-accent group-hover:translate-x-0.5 transition-smooth mt-0.5"
        />
      </div>
      <div className="flex items-center gap-2 mb-2">
        <Badge
          variant="outline"
          className={`text-[10px] px-1.5 py-0 font-mono border ${colorClass}`}
        >
          {cap.category}
        </Badge>
        <span className="text-[10px] font-mono text-muted-foreground/40">
          {cap.inputs.length}in · {cap.outputs.length}out
        </span>
      </div>
      <p className="text-xs text-muted-foreground font-body line-clamp-2">
        {cap.description}
      </p>
    </button>
  );
}

// ── Desktop row view ──────────────────────────────────────────────────────────

function CapabilityRow({ cap }: { cap: CapabilityInfo }) {
  const navigate = useNavigate();
  const colorClass =
    CATEGORY_COLORS[cap.category] ?? "text-muted-foreground border-border";

  return (
    <button
      type="button"
      onClick={() =>
        navigate({ to: "/capabilities/$name", params: { name: cap.name } })
      }
      data-ocid="capability-row"
      className="group w-full text-left flex items-center gap-4 px-5 py-3 border-b border-border hover:bg-secondary/60 transition-smooth"
    >
      <span className="w-56 shrink-0 font-mono text-sm text-foreground truncate group-hover:text-accent transition-smooth">
        {cap.name}
        <span className="text-muted-foreground/40">()</span>
      </span>
      <span className="w-36 shrink-0">
        <Badge
          variant="outline"
          className={`text-xs px-1.5 py-0 font-mono border ${colorClass}`}
        >
          {cap.category}
        </Badge>
      </span>
      <span className="flex-1 min-w-0 text-xs text-muted-foreground font-body truncate">
        {cap.description}
      </span>
      <span className="shrink-0 text-xs text-muted-foreground/40 font-mono w-20 text-right">
        {cap.inputs.length}in · {cap.outputs.length}out
      </span>
      <ArrowRight
        size={13}
        className="shrink-0 text-muted-foreground/30 group-hover:text-accent group-hover:translate-x-0.5 transition-smooth"
      />
    </button>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function CapabilitiesPage() {
  const { data: capabilities, isPending: isLoading } = useCapabilities();
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("All");
  const [filterOpen, setFilterOpen] = useState(false);

  const availableCategories = CATEGORIES.filter(
    (cat) =>
      cat === "All" || (capabilities ?? []).some((c) => c.category === cat),
  );

  const filtered = (capabilities ?? []).filter((c) => {
    const q = search.toLowerCase();
    const matchSearch =
      !search ||
      c.name.toLowerCase().includes(q) ||
      c.description.toLowerCase().includes(q);
    const matchCat = category === "All" || c.category === category;
    return matchSearch && matchCat;
  });

  return (
    <div className="flex flex-col h-full">
      {/* Page header */}
      <div className="border-b border-border px-4 md:px-6 py-4 bg-card flex items-center justify-between gap-4 shrink-0">
        <div>
          <h1 className="font-display text-sm font-semibold text-foreground">
            Capabilities
          </h1>
          <p className="text-xs text-muted-foreground font-body mt-0.5 hidden sm:block">
            Deterministic, schema-typed canister methods callable by any AI
            agent.
          </p>
        </div>
        <span className="font-mono text-xs text-muted-foreground shrink-0">
          {isLoading ? "—" : `${(capabilities ?? []).length} total`}
        </span>
      </div>

      {/* Toolbar — desktop */}
      <div className="border-b border-border px-4 md:px-6 py-3 bg-card shrink-0 hidden md:flex items-center gap-3 flex-wrap">
        <div className="relative flex-1 max-w-xs">
          <Search
            size={12}
            className="absolute left-2.5 top-1/2 -translate-y-1/2 text-muted-foreground pointer-events-none"
          />
          <input
            type="text"
            placeholder="Search by name or description…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            data-ocid="search-capabilities"
            className="w-full pl-7 pr-3 py-1.5 text-xs bg-secondary/40 border border-input rounded font-body text-foreground placeholder:text-muted-foreground/40 focus:outline-none focus:ring-1 focus:ring-ring transition-smooth"
          />
        </div>
        <div className="flex gap-1 flex-wrap" data-ocid="category-filter">
          {availableCategories.map((cat) => (
            <button
              key={cat}
              type="button"
              onClick={() => setCategory(cat)}
              className={[
                "px-2 py-0.5 text-xs rounded border transition-smooth font-mono whitespace-nowrap",
                category === cat
                  ? "border-accent/50 bg-accent/10 text-accent"
                  : "border-border text-muted-foreground hover:text-foreground hover:border-border/80",
              ].join(" ")}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {/* Toolbar — mobile */}
      <div className="border-b border-border px-4 py-3 bg-card shrink-0 md:hidden space-y-2">
        <div className="relative w-full">
          <Search
            size={12}
            className="absolute left-2.5 top-1/2 -translate-y-1/2 text-muted-foreground pointer-events-none"
          />
          <input
            type="text"
            placeholder="Search capabilities…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            data-ocid="search-capabilities-mobile"
            className="w-full pl-7 pr-3 py-2 text-xs bg-secondary/40 border border-input rounded font-body text-foreground placeholder:text-muted-foreground/40 focus:outline-none focus:ring-1 focus:ring-ring transition-smooth"
          />
        </div>
        <button
          type="button"
          onClick={() => setFilterOpen((v) => !v)}
          className="flex items-center gap-1.5 text-xs font-mono text-muted-foreground hover:text-foreground transition-smooth"
          data-ocid="toggle-category-filter"
        >
          <ChevronDown
            size={12}
            className={`transition-transform duration-150 ${filterOpen ? "rotate-180" : ""}`}
          />
          {category === "All" ? "Filter by category" : `Category: ${category}`}
        </button>
        {filterOpen && (
          <div
            className="flex flex-wrap gap-1.5 pt-1"
            data-ocid="category-filter-mobile"
          >
            {availableCategories.map((cat) => (
              <button
                key={cat}
                type="button"
                onClick={() => {
                  setCategory(cat);
                  setFilterOpen(false);
                }}
                className={[
                  "px-2 py-1 text-xs rounded border transition-smooth font-mono whitespace-nowrap min-h-[36px]",
                  category === cat
                    ? "border-accent/50 bg-accent/10 text-accent"
                    : "border-border text-muted-foreground hover:text-foreground",
                ].join(" ")}
              >
                {cat}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Desktop table header */}
      <div className="border-b border-border px-5 py-2 bg-secondary/20 shrink-0 hidden md:flex items-center gap-4">
        <span className="w-56 shrink-0 text-xs font-mono text-muted-foreground/60 uppercase tracking-widest">
          Method
        </span>
        <span className="w-36 shrink-0 text-xs font-mono text-muted-foreground/60 uppercase tracking-widest">
          Category
        </span>
        <span className="flex-1 text-xs font-mono text-muted-foreground/60 uppercase tracking-widest">
          Description
        </span>
        <span className="w-20 text-right text-xs font-mono text-muted-foreground/60 uppercase tracking-widest">
          Schema
        </span>
        <span className="w-4" />
      </div>

      {/* List */}
      <div className="flex-1 overflow-y-auto" data-ocid="capabilities-list">
        {isLoading ? (
          <div className="p-4 md:p-5 space-y-2">
            {SKELETON_KEYS.map((k) => (
              <Skeleton key={k} className="h-10 w-full rounded" />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div
            className="flex flex-col items-center justify-center h-64 text-center p-6"
            data-ocid="capabilities-empty"
          >
            <div className="font-mono text-3xl text-muted-foreground/15 mb-3">
              ∅
            </div>
            <p className="text-sm text-muted-foreground font-body">
              No capabilities found
            </p>
            <p className="text-xs text-muted-foreground/50 font-mono mt-1">
              Try a different search or filter
            </p>
          </div>
        ) : (
          <>
            {/* Mobile cards */}
            <div className="md:hidden">
              {filtered.map((cap) => (
                <CapabilityCard key={cap.name} cap={cap} />
              ))}
            </div>
            {/* Desktop rows */}
            <div className="hidden md:block">
              {filtered.map((cap) => (
                <CapabilityRow key={cap.name} cap={cap} />
              ))}
            </div>
          </>
        )}
      </div>

      {/* Footer count */}
      <div className="border-t border-border px-4 md:px-6 py-2 bg-card shrink-0">
        <span className="text-xs text-muted-foreground font-mono">
          {isLoading
            ? "Loading…"
            : `${filtered.length} of ${(capabilities ?? []).length} capabilities`}
        </span>
      </div>
    </div>
  );
}
