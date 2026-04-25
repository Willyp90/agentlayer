import type { DailyCount } from "@/types";
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

interface DailyChartProps {
  data: DailyCount[];
}

interface ChartDataPoint {
  date: string;
  calls: number;
}

interface TooltipPayloadEntry {
  value: number;
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: TooltipPayloadEntry[];
  label?: string;
}

function CustomTooltip({ active, payload, label }: CustomTooltipProps) {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-card border border-border rounded px-3 py-2 shadow-lg">
      <p className="font-mono text-xs text-muted-foreground mb-0.5">{label}</p>
      <p className="font-mono text-sm text-foreground tabular-nums">
        {payload[0].value.toLocaleString()} calls
      </p>
    </div>
  );
}

export function DailyChart({ data }: DailyChartProps) {
  const chartData: ChartDataPoint[] = data.slice(-30).map((d) => ({
    date: d.date,
    calls: Number(d.count),
  }));

  // Format date labels — show only every 5th to avoid crowding
  const formatXAxis = (tick: string): string => {
    const parts = tick.split("-");
    if (parts.length < 3) return tick;
    return `${parts[1]}/${parts[2]}`;
  };

  return (
    <ResponsiveContainer width="100%" height={180}>
      <AreaChart
        data={chartData}
        margin={{ top: 4, right: 4, left: -20, bottom: 0 }}
      >
        <defs>
          <linearGradient id="callsGradient" x1="0" y1="0" x2="0" y2="1">
            <stop
              offset="5%"
              stopColor="oklch(var(--accent))"
              stopOpacity={0.3}
            />
            <stop
              offset="95%"
              stopColor="oklch(var(--accent))"
              stopOpacity={0}
            />
          </linearGradient>
        </defs>
        <CartesianGrid
          strokeDasharray="3 3"
          stroke="oklch(var(--border))"
          vertical={false}
        />
        <XAxis
          dataKey="date"
          tickFormatter={formatXAxis}
          tick={{
            fontSize: 10,
            fontFamily: "var(--font-mono)",
            fill: "oklch(var(--muted-foreground))",
          }}
          axisLine={false}
          tickLine={false}
          interval="preserveStartEnd"
        />
        <YAxis
          tick={{
            fontSize: 10,
            fontFamily: "var(--font-mono)",
            fill: "oklch(var(--muted-foreground))",
          }}
          axisLine={false}
          tickLine={false}
          allowDecimals={false}
        />
        <Tooltip
          content={<CustomTooltip />}
          cursor={{ stroke: "oklch(var(--border))", strokeWidth: 1 }}
        />
        <Area
          type="monotone"
          dataKey="calls"
          stroke="oklch(var(--accent))"
          strokeWidth={1.5}
          fill="url(#callsGradient)"
          dot={false}
          activeDot={{ r: 3, fill: "oklch(var(--accent))", strokeWidth: 0 }}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
