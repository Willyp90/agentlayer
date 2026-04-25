import { DailyChart } from "@/components/DailyChart";
import { Skeleton } from "@/components/ui/skeleton";
import type React from "react";
import { useUsageSummary } from "../hooks/useBackend";
import type { CapabilityCount } from "../types";

function formatBigInt(n: bigint | undefined): string {
  if (n === undefined) return "0";
  return Number(n).toLocaleString();
}

function computePct(count: bigint, total: bigint): number {
  if (total <= 0n) return 0;
  return Math.round(Number((count * 1000n) / total) / 10);
}

const SKELETON_STATS = ["s1", "s2", "s3"] as const;
const SKELETON_ROWS = ["r1", "r2", "r3", "r4", "r5"] as const;

interface StatCardProps {
  label: string;
  value: string;
  accent?: boolean;
}

function StatCard({ label, value, accent }: StatCardProps) {
  return (
    <div
      className={`border border-border rounded p-3 md:p-4 bg-card flex flex-col gap-1.5 md:gap-2 ${
        accent ? "border-accent/40 bg-accent/5" : ""
      }`}
    >
      <span className="text-[10px] font-mono text-muted-foreground uppercase tracking-[0.12em] leading-tight">
        {label}
      </span>
      <span
        className={`font-mono text-xl md:text-2xl font-semibold tabular-nums leading-none ${
          accent ? "text-accent" : "text-foreground"
        }`}
      >
        {value}
      </span>
    </div>
  );
}

interface RankBarProps {
  pct: number;
}

function RankBar({ pct }: RankBarProps) {
  return (
    <div className="flex items-center justify-end gap-2">
      <div className="w-12 md:w-20 h-1 bg-secondary rounded-full overflow-hidden">
        <div
          className="h-full bg-accent rounded-full transition-all duration-500"
          style={{ width: `${pct}%` }}
        />
      </div>
      <span className="font-mono text-[11px] text-muted-foreground w-7 md:w-8 text-right tabular-nums">
        {pct}%
      </span>
    </div>
  );
}

interface CapabilityTableProps {
  rows: CapabilityCount[];
  total: bigint;
  isLoading: boolean;
}

function CapabilityTable({ rows, total, isLoading }: CapabilityTableProps) {
  return (
    <div className="border border-border rounded overflow-hidden overflow-x-auto">
      <table className="w-full text-[12px] min-w-[320px]">
        <thead>
          <tr className="border-b border-border bg-secondary/30">
            <th className="px-3 py-2 text-left font-mono text-muted-foreground w-8">
              #
            </th>
            <th className="px-3 py-2 text-left font-mono text-muted-foreground">
              capability
            </th>
            <th className="px-3 py-2 text-right font-mono text-muted-foreground">
              calls
            </th>
            <th className="px-3 py-2 text-right font-mono text-muted-foreground w-28 md:w-36">
              share
            </th>
          </tr>
        </thead>
        <tbody>
          {isLoading
            ? SKELETON_ROWS.map((k) => (
                <tr key={k} className="border-b border-border last:border-0">
                  <td colSpan={4} className="px-3 py-2">
                    <Skeleton className="h-5 w-full" />
                  </td>
                </tr>
              ))
            : rows.slice(0, 5).map((c, i) => {
                const pct = computePct(c.count, total);
                return (
                  <tr
                    key={c.name}
                    className="border-b border-border last:border-0 hover:bg-secondary/20 transition-colors"
                  >
                    <td className="px-3 py-2.5 font-mono text-muted-foreground tabular-nums">
                      {i + 1}
                    </td>
                    <td className="px-3 py-2.5 font-mono text-foreground max-w-[120px] md:max-w-none">
                      <span className="truncate block">{c.name}()</span>
                    </td>
                    <td className="px-3 py-2.5 font-mono text-foreground text-right tabular-nums">
                      {Number(c.count).toLocaleString()}
                    </td>
                    <td className="px-3 py-2.5">
                      <RankBar pct={pct} />
                    </td>
                  </tr>
                );
              })}
          {!isLoading && rows.length === 0 && (
            <tr>
              <td
                colSpan={4}
                className="px-3 py-6 text-center text-muted-foreground font-mono text-xs"
                data-ocid="usage-cap-empty"
              >
                no data yet
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="text-[10px] font-mono text-muted-foreground uppercase tracking-[0.14em] mb-3">
      {children}
    </h2>
  );
}

export default function UsagePage() {
  const { data: summary, isLoading, dataUpdatedAt } = useUsageSummary();

  const total = summary?.totalCalls ?? 0n;
  const thisMonth = summary?.callsThisMonth ?? 0n;
  const capabilityCount = summary?.perCapability.length ?? 0;

  const lastUpdated = dataUpdatedAt
    ? new Date(dataUpdatedAt).toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
      })
    : null;

  return (
    <div className="flex flex-col h-full overflow-auto" data-ocid="usage-page">
      {/* Page header */}
      <div className="border-b border-border px-4 md:px-6 py-3 bg-card flex items-center justify-between shrink-0">
        <div className="flex items-center gap-3 flex-wrap">
          <h1 className="font-mono text-sm font-semibold text-foreground tracking-tight">
            Your Usage
          </h1>
          <span className="text-[10px] font-mono text-muted-foreground bg-secondary px-2 py-0.5 rounded border border-border hidden sm:inline">
            read-only · refreshes every 30s
          </span>
        </div>
        {lastUpdated && (
          <span className="text-[10px] font-mono text-muted-foreground hidden sm:block">
            updated {lastUpdated}
          </span>
        )}
      </div>

      <div className="p-4 md:p-6 space-y-6 md:space-y-8 max-w-6xl w-full">
        {/* Overview stats — 2 cols on mobile, 3 on md+ */}
        <section>
          <SectionLabel>Overview</SectionLabel>
          <div
            className="grid grid-cols-2 gap-3 md:grid-cols-3"
            data-ocid="usage-stats"
          >
            {isLoading ? (
              SKELETON_STATS.map((k) => (
                <Skeleton
                  key={k}
                  className="h-[72px] md:h-[76px] w-full rounded"
                />
              ))
            ) : (
              <>
                <StatCard
                  label="Your Total Calls"
                  value={formatBigInt(total)}
                  accent
                />
                <StatCard label="This Month" value={formatBigInt(thisMonth)} />
                <StatCard
                  label="Capabilities Used"
                  value={capabilityCount.toString()}
                />
              </>
            )}
          </div>
        </section>

        {/* Daily chart — full width */}
        <section>
          <SectionLabel>Daily Call Volume — last 30 days</SectionLabel>
          {isLoading ? (
            <Skeleton className="h-[160px] md:h-[180px] w-full rounded" />
          ) : (summary?.dailyCounts ?? []).length === 0 ? (
            <div
              className="border border-border rounded p-8 text-center"
              data-ocid="usage-daily-empty"
            >
              <p className="text-xs text-muted-foreground font-mono">
                no daily data yet
              </p>
            </div>
          ) : (
            <div
              className="border border-border rounded bg-card p-3 md:p-4 w-full overflow-hidden"
              data-ocid="usage-daily-chart"
            >
              <DailyChart data={summary?.dailyCounts ?? []} />
            </div>
          )}
        </section>

        {/* Top capabilities table */}
        <section>
          <SectionLabel>Top 5 Capabilities</SectionLabel>
          <CapabilityTable
            rows={summary?.perCapability ?? []}
            total={total}
            isLoading={isLoading}
          />
        </section>
      </div>
    </div>
  );
}
