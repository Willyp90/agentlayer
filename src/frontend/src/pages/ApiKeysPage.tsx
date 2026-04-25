import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import {
  useApiKeys,
  useGenerateApiKey,
  useRevokeApiKey,
} from "@/hooks/useBackend";
import type { ApiKey } from "@/types";
import { useNavigate } from "@tanstack/react-router";
import {
  AlertTriangle,
  Check,
  Clock,
  Copy,
  ExternalLink,
  Key,
  Plus,
  TrendingUp,
  X,
} from "lucide-react";
import React, { useState } from "react";
import { toast } from "sonner";

function relativeTime(ns: bigint): string {
  const ms = Number(ns / 1_000_000n);
  const diff = Date.now() - ms;
  const sec = Math.floor(diff / 1000);
  if (sec < 60) return "just now";
  const min = Math.floor(sec / 60);
  if (min < 60) return `${min}m ago`;
  const hr = Math.floor(min / 60);
  if (hr < 24) return `${hr}h ago`;
  const days = Math.floor(hr / 24);
  if (days < 30) return `${days}d ago`;
  const months = Math.floor(days / 30);
  return `${months}mo ago`;
}

function maskKey(id: string): string {
  if (id.length <= 10) return id;
  return `${id.slice(0, 10)}••••••••`;
}

/** Returns activity level based on last-used timestamp */
function getActivityLevel(
  key: ApiKey,
): "recent" | "stale" | "inactive" | "never" {
  if (!key.active) return "inactive";
  if (!key.lastUsedAt) return "never";
  const ms = Number(key.lastUsedAt / 1_000_000n);
  const hoursSince = (Date.now() - ms) / (1000 * 60 * 60);
  if (hoursSince < 24) return "recent";
  if (hoursSince < 168) return "stale"; // 7 days
  return "inactive";
}

function ActivityDot({
  level,
}: { level: ReturnType<typeof getActivityLevel> }) {
  const colors: Record<string, string> = {
    recent: "bg-emerald-400",
    stale: "bg-yellow-400",
    inactive: "bg-muted-foreground/30",
    never: "bg-muted-foreground/20",
  };
  return (
    <span
      className={`inline-block w-2 h-2 rounded-full shrink-0 ${colors[level]}`}
      title={
        level === "recent"
          ? "Used in last 24h"
          : level === "stale"
            ? "Used in last 7 days"
            : level === "never"
              ? "Never used"
              : "Revoked"
      }
    />
  );
}

interface RevokeState {
  keyId: string;
  confirming: boolean;
}

interface NewKeyReveal {
  key: ApiKey;
  copied: boolean;
}

export default function ApiKeysPage() {
  const { data: keys, isLoading } = useApiKeys();
  const generateKey = useGenerateApiKey();
  const revokeKey = useRevokeApiKey();
  const navigate = useNavigate();

  const [showForm, setShowForm] = useState(false);
  const [keyName, setKeyName] = useState("");
  const [revokeState, setRevokeState] = useState<RevokeState | null>(null);
  const [newKeyReveal, setNewKeyReveal] = useState<NewKeyReveal | null>(null);

  const handleGenerate = async () => {
    try {
      const key = await generateKey.mutateAsync({ name: keyName.trim() });
      setNewKeyReveal({ key, copied: false });
      setKeyName("");
      setShowForm(false);
    } catch (err) {
      toast.error(
        err instanceof Error ? err.message : "Failed to generate key",
      );
    }
  };

  const handleCopy = async () => {
    if (!newKeyReveal) return;
    const text = newKeyReveal.key.id;
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      // Fallback for browsers that block clipboard API
      const el = document.createElement("textarea");
      el.value = text;
      el.style.cssText = "position:fixed;top:-9999px;left:-9999px;opacity:0;";
      document.body.appendChild(el);
      el.focus();
      el.select();
      document.execCommand("copy");
      document.body.removeChild(el);
    }
    setNewKeyReveal({ ...newKeyReveal, copied: true });
    toast.success("Key copied to clipboard");
  };

  const handleRevoke = async (keyId: string) => {
    try {
      await revokeKey.mutateAsync({ keyId });
      setRevokeState(null);
      toast.success("Key revoked");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to revoke key");
    }
  };

  const handleCopyKeyId = async (keyId: string) => {
    try {
      await navigator.clipboard.writeText(keyId);
    } catch {
      const el = document.createElement("textarea");
      el.value = keyId;
      el.style.cssText = "position:fixed;top:-9999px;left:-9999px;opacity:0;";
      document.body.appendChild(el);
      el.focus();
      el.select();
      document.execCommand("copy");
      document.body.removeChild(el);
    }
    toast.success("Key ID copied to clipboard");
  };

  const activeKeys = keys ?? [];
  const hasKeys = activeKeys.length > 0;

  return (
    <div className="flex-1 overflow-y-auto">
      {/* Page header */}
      <div className="border-b border-border bg-card px-4 md:px-6 py-4 flex items-start justify-between gap-4">
        <div>
          <h1 className="text-base font-display font-semibold text-foreground tracking-tight">
            API Keys
          </h1>
          <p className="text-xs text-muted-foreground mt-0.5 font-body max-w-lg">
            Generate keys for agent/headless access. Pass as the{" "}
            <code className="font-mono bg-secondary px-1 py-0.5 rounded text-[11px]">
              apiKey
            </code>{" "}
            parameter in{" "}
            <code className="font-mono bg-secondary px-1 py-0.5 rounded text-[11px]">
              execute_capability
            </code>
            .
          </p>
        </div>
        {!showForm && (
          <Button
            size="sm"
            onClick={() => setShowForm(true)}
            data-ocid="btn-generate-key-open"
            className="flex-shrink-0 gap-1.5 min-h-[44px] md:min-h-0"
          >
            <Plus size={14} />
            <span className="hidden sm:inline">Generate New Key</span>
            <span className="sm:hidden">New Key</span>
          </Button>
        )}
      </div>

      <div className="px-4 md:px-6 py-5 space-y-5">
        {/* Inline generate form */}
        {showForm && (
          <div
            className="border border-border rounded-md bg-card p-4 space-y-3"
            data-ocid="form-generate-key"
          >
            <div className="text-xs font-display font-medium text-foreground">
              New API Key
            </div>
            <div className="flex flex-col sm:flex-row gap-2">
              <Input
                placeholder="e.g. My Agent Key"
                value={keyName}
                onChange={(e) => setKeyName(e.target.value)}
                className="h-10 sm:h-8 text-sm font-mono w-full sm:max-w-xs"
                data-ocid="input-key-name"
                onKeyDown={(e) => e.key === "Enter" && handleGenerate()}
                autoFocus
              />
              <div className="flex gap-2">
                <Button
                  size="sm"
                  onClick={handleGenerate}
                  disabled={generateKey.isPending}
                  data-ocid="btn-generate-key-confirm"
                  className="flex-1 sm:flex-none min-h-[44px] sm:min-h-0"
                >
                  {generateKey.isPending ? "Generating…" : "Generate"}
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => {
                    setShowForm(false);
                    setKeyName("");
                  }}
                  data-ocid="btn-generate-key-cancel"
                  className="flex-1 sm:flex-none min-h-[44px] sm:min-h-0"
                >
                  Cancel
                </Button>
              </div>
            </div>
            <p className="text-xs text-muted-foreground">
              Name is optional — helps you identify which agent uses this key.
            </p>
          </div>
        )}

        {/* Mobile "Generate" CTA (when no form is open) */}
        {!showForm && !hasKeys && !isLoading && (
          <div className="sm:hidden">
            <Button
              className="w-full gap-1.5 min-h-[44px]"
              onClick={() => setShowForm(true)}
              data-ocid="btn-generate-key-mobile-cta"
            >
              <Plus size={14} />
              Generate New Key
            </Button>
          </div>
        )}

        {/* New key reveal banner */}
        {newKeyReveal && (
          <div
            className="border border-accent/40 rounded-md bg-accent/5 p-4 space-y-3"
            data-ocid="reveal-new-key"
          >
            <div className="flex items-center gap-2 text-accent">
              <AlertTriangle size={14} />
              <span className="text-xs font-display font-semibold">
                Copy your key now — it will not be shown again.
              </span>
            </div>
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
              <code className="flex-1 text-sm font-mono text-foreground bg-secondary border border-border rounded px-3 py-2 truncate select-all break-all">
                {newKeyReveal.key.id}
              </code>
              <Button
                size="sm"
                variant="outline"
                onClick={handleCopy}
                data-ocid="btn-copy-key"
                className="flex-shrink-0 gap-1.5 min-h-[44px] sm:min-h-0"
              >
                {newKeyReveal.copied ? <Check size={13} /> : <Copy size={13} />}
                {newKeyReveal.copied ? "Copied" : "Copy"}
              </Button>
            </div>
            <div className="text-xs text-muted-foreground font-body bg-secondary/30 rounded p-3 border border-border/50">
              <span className="font-mono text-accent">Usage:</span> Pass this
              key as the <code className="font-mono">apiKey</code> parameter in{" "}
              <code className="font-mono">execute_capability</code> calls. Test
              it now in the{" "}
              <button
                type="button"
                onClick={() =>
                  navigate({
                    to: "/playground",
                    search: { capability: undefined },
                  })
                }
                className="text-accent hover:underline font-mono"
              >
                Playground
              </button>
              .
            </div>
            <Button
              size="sm"
              variant="ghost"
              onClick={() => setNewKeyReveal(null)}
              data-ocid="btn-key-done"
              className="text-muted-foreground hover:text-foreground w-full sm:w-auto min-h-[44px] sm:min-h-0"
            >
              Done, I've saved my key
            </Button>
          </div>
        )}

        {/* Keys */}
        {isLoading ? (
          <div className="space-y-2" data-ocid="keys-loading">
            {[1, 2, 3].map((i) => (
              <Skeleton key={i} className="h-16 w-full rounded-md" />
            ))}
          </div>
        ) : !hasKeys ? (
          <EmptyState onGenerate={() => setShowForm(true)} />
        ) : (
          <>
            {/* Desktop table */}
            <div className="hidden md:block">
              <KeysTable
                keys={activeKeys}
                revokeState={revokeState}
                setRevokeState={setRevokeState}
                onRevoke={handleRevoke}
                revoking={revokeKey.isPending}
                onCopyKeyId={handleCopyKeyId}
                onViewLogs={(keyId) =>
                  navigate({
                    to: "/logs",
                    search: { keyId } as Record<string, unknown>,
                  })
                }
              />
            </div>
            {/* Mobile card list */}
            <div className="md:hidden space-y-3" data-ocid="keys-cards">
              {activeKeys.map((key) => (
                <KeyCard
                  key={key.id}
                  apiKey={key}
                  revokeState={revokeState}
                  setRevokeState={setRevokeState}
                  onRevoke={handleRevoke}
                  revoking={revokeKey.isPending}
                  onCopyKeyId={handleCopyKeyId}
                  onViewLogs={(keyId) =>
                    navigate({
                      to: "/logs",
                      search: { keyId } as Record<string, unknown>,
                    })
                  }
                />
              ))}
            </div>
          </>
        )}
      </div>
    </div>
  );
}

// ── Mobile key card ───────────────────────────────────────────────────────────

interface KeyCardProps {
  apiKey: ApiKey;
  revokeState: RevokeState | null;
  setRevokeState: (s: RevokeState | null) => void;
  onRevoke: (keyId: string) => void;
  revoking: boolean;
  onCopyKeyId: (keyId: string) => void;
  onViewLogs: (keyId: string) => void;
}

function KeyCard({
  apiKey,
  revokeState,
  setRevokeState,
  onRevoke,
  revoking,
  onCopyKeyId,
  onViewLogs,
}: KeyCardProps) {
  const isRevoking = revokeState?.keyId === apiKey.id && revokeState.confirming;
  const activity = getActivityLevel(apiKey);

  return (
    <div
      className="border border-border rounded-md bg-card overflow-hidden"
      data-ocid={`key-card-${apiKey.id}`}
    >
      <div className="p-4 space-y-3">
        {/* Name + status */}
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2 min-w-0">
            <ActivityDot level={activity} />
            <span className="text-sm font-body text-foreground truncate">
              {apiKey.name || (
                <span className="text-muted-foreground italic text-xs">
                  Unnamed Key
                </span>
              )}
            </span>
          </div>
          {apiKey.active ? (
            <Badge
              variant="outline"
              className="text-[10px] border-emerald-500/40 text-emerald-400 bg-emerald-500/10 font-mono shrink-0"
              data-ocid={`badge-active-${apiKey.id}`}
            >
              active
            </Badge>
          ) : (
            <Badge
              variant="outline"
              className="text-[10px] border-destructive/40 text-destructive bg-destructive/10 font-mono shrink-0"
              data-ocid={`badge-revoked-${apiKey.id}`}
            >
              revoked
            </Badge>
          )}
        </div>

        {/* Key ID */}
        <div className="font-mono text-xs text-muted-foreground bg-secondary/50 rounded px-3 py-2">
          {maskKey(apiKey.id)}
        </div>

        {/* Stats row */}
        <div className="grid grid-cols-2 gap-2 text-[11px] font-mono text-muted-foreground">
          <div className="flex items-center gap-1">
            <TrendingUp size={10} className="text-muted-foreground/40" />
            <span>
              {apiKey.callCount.toString()} call
              {apiKey.callCount !== 1n ? "s" : ""}
            </span>
          </div>
          <div className="flex items-center gap-1">
            <Clock size={10} className="text-muted-foreground/40" />
            <span>
              {apiKey.lastUsedAt
                ? relativeTime(apiKey.lastUsedAt)
                : "Never used"}
            </span>
          </div>
        </div>

        <div className="text-[10px] font-mono text-muted-foreground/50">
          Created {relativeTime(apiKey.createdAt)}
        </div>

        {/* Usage hint */}
        <p className="text-[10px] font-body text-muted-foreground/50 leading-relaxed">
          Pass this key as the <code className="font-mono">apiKey</code>{" "}
          parameter in <code className="font-mono">execute_capability</code>.
        </p>

        {/* Actions */}
        <div className="flex items-center gap-3 flex-wrap">
          <button
            type="button"
            onClick={() => onCopyKeyId(apiKey.id)}
            data-ocid={`btn-copy-key-id-${apiKey.id}`}
            className="flex items-center gap-1 text-xs font-mono text-muted-foreground hover:text-foreground transition-colors duration-150 min-h-[44px]"
          >
            <Copy size={11} />
            Copy ID
          </button>
          <button
            type="button"
            onClick={() => onViewLogs(apiKey.id)}
            data-ocid={`btn-view-logs-${apiKey.id}`}
            className="flex items-center gap-1 text-xs font-mono text-muted-foreground hover:text-accent transition-colors duration-150 min-h-[44px]"
          >
            <ExternalLink size={11} />
            View in Logs
          </button>
          {apiKey.active && !isRevoking && (
            <button
              type="button"
              onClick={() =>
                setRevokeState({ keyId: apiKey.id, confirming: true })
              }
              data-ocid={`btn-revoke-${apiKey.id}`}
              className="text-xs text-muted-foreground hover:text-destructive transition-colors duration-150 font-body min-h-[44px] ml-auto"
            >
              Revoke
            </button>
          )}
        </div>
      </div>

      {/* Revoke confirmation */}
      {isRevoking && (
        <div
          className="border-t border-border bg-destructive/5 p-4"
          data-ocid={`confirm-revoke-${apiKey.id}`}
        >
          <div className="flex items-start gap-2 mb-3">
            <AlertTriangle
              size={13}
              className="text-destructive flex-shrink-0 mt-0.5"
            />
            <span className="text-xs text-foreground font-body">
              Revoke this key? Agents using it will lose access immediately.
            </span>
          </div>
          <div className="flex gap-2">
            <Button
              size="sm"
              variant="destructive"
              onClick={() => onRevoke(apiKey.id)}
              disabled={revoking}
              data-ocid={`btn-revoke-confirm-${apiKey.id}`}
              className="flex-1 min-h-[44px]"
            >
              {revoking ? "Revoking…" : "Confirm Revoke"}
            </Button>
            <Button
              size="sm"
              variant="ghost"
              onClick={() => setRevokeState(null)}
              data-ocid={`btn-revoke-cancel-${apiKey.id}`}
              className="flex-1 min-h-[44px]"
            >
              <X size={12} />
              Cancel
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────

function EmptyState({ onGenerate }: { onGenerate: () => void }) {
  return (
    <div
      className="flex flex-col items-center justify-center py-16 md:py-20 text-center"
      data-ocid="empty-api-keys"
    >
      <div className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center mb-4">
        <Key size={18} className="text-muted-foreground" />
      </div>
      <h3 className="text-sm font-display font-semibold text-foreground mb-1.5">
        No API keys yet
      </h3>
      <p className="text-xs text-muted-foreground mb-5 max-w-xs">
        Generate your first key to enable agent/headless access to your
        capabilities.
      </p>
      <Button
        size="sm"
        onClick={onGenerate}
        data-ocid="btn-empty-generate-key"
        className="gap-1.5 w-full sm:w-auto min-h-[44px]"
      >
        <Plus size={14} />
        Generate New Key
      </Button>
    </div>
  );
}

// ── Desktop table ─────────────────────────────────────────────────────────────

interface KeysTableProps {
  keys: ApiKey[];
  revokeState: RevokeState | null;
  setRevokeState: (s: RevokeState | null) => void;
  onRevoke: (keyId: string) => void;
  revoking: boolean;
  onCopyKeyId: (keyId: string) => void;
  onViewLogs: (keyId: string) => void;
}

function KeysTable({
  keys,
  revokeState,
  setRevokeState,
  onRevoke,
  revoking,
  onCopyKeyId,
  onViewLogs,
}: KeysTableProps) {
  return (
    <div
      className="border border-border rounded-md overflow-hidden"
      data-ocid="keys-table"
    >
      <table className="w-full text-xs">
        <thead>
          <tr className="border-b border-border bg-secondary/50">
            <th className="text-left px-4 py-2.5 font-display font-medium text-muted-foreground">
              Name
            </th>
            <th className="text-left px-4 py-2.5 font-display font-medium text-muted-foreground">
              Key
            </th>
            <th className="text-left px-4 py-2.5 font-display font-medium text-muted-foreground">
              Status
            </th>
            <th className="text-left px-4 py-2.5 font-display font-medium text-muted-foreground">
              Created
            </th>
            <th className="text-left px-4 py-2.5 font-display font-medium text-muted-foreground">
              Last Used
            </th>
            <th className="text-right px-4 py-2.5 font-display font-medium text-muted-foreground">
              Calls
            </th>
            <th className="text-right px-4 py-2.5 font-display font-medium text-muted-foreground">
              Actions
            </th>
          </tr>
        </thead>
        <tbody>
          {keys.map((key) => {
            const isRevoking =
              revokeState?.keyId === key.id && revokeState.confirming;
            const activity = getActivityLevel(key);
            return (
              <React.Fragment key={key.id}>
                <tr
                  className="border-b border-border last:border-0 hover:bg-secondary/30 transition-colors duration-100"
                  data-ocid={`key-row-${key.id}`}
                >
                  <td className="px-4 py-3 font-body text-foreground">
                    <div className="flex items-center gap-2">
                      <ActivityDot level={activity} />
                      {key.name || (
                        <span className="text-muted-foreground italic">
                          Unnamed Key
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3 font-mono text-muted-foreground">
                    {maskKey(key.id)}
                  </td>
                  <td className="px-4 py-3">
                    {key.active ? (
                      <Badge
                        variant="outline"
                        className="text-[10px] border-emerald-500/40 text-emerald-400 bg-emerald-500/10 font-mono"
                        data-ocid={`badge-active-${key.id}`}
                      >
                        active
                      </Badge>
                    ) : (
                      <Badge
                        variant="outline"
                        className="text-[10px] border-destructive/40 text-destructive bg-destructive/10 font-mono"
                        data-ocid={`badge-revoked-${key.id}`}
                      >
                        revoked
                      </Badge>
                    )}
                  </td>
                  <td className="px-4 py-3 text-muted-foreground font-mono">
                    {relativeTime(key.createdAt)}
                  </td>
                  <td className="px-4 py-3 text-muted-foreground font-mono">
                    {key.lastUsedAt ? relativeTime(key.lastUsedAt) : "Never"}
                  </td>
                  <td className="px-4 py-3 text-right font-mono text-foreground tabular-nums">
                    {key.callCount.toString()}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center justify-end gap-3">
                      <button
                        type="button"
                        onClick={() => onCopyKeyId(key.id)}
                        data-ocid={`btn-copy-key-id-${key.id}`}
                        className="flex items-center gap-1 text-muted-foreground hover:text-foreground transition-colors duration-150"
                        title="Copy Key ID"
                      >
                        <Copy size={11} />
                        <span>Copy</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => onViewLogs(key.id)}
                        data-ocid={`btn-view-logs-${key.id}`}
                        className="flex items-center gap-1 text-muted-foreground hover:text-accent transition-colors duration-150"
                        title="View in Logs"
                      >
                        <ExternalLink size={11} />
                        <span>Logs</span>
                      </button>
                      {key.active && !isRevoking && (
                        <button
                          type="button"
                          onClick={() =>
                            setRevokeState({ keyId: key.id, confirming: true })
                          }
                          data-ocid={`btn-revoke-${key.id}`}
                          className="text-muted-foreground hover:text-destructive transition-colors duration-150"
                        >
                          Revoke
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
                {isRevoking && (
                  <tr className="border-b border-border last:border-0 bg-destructive/5">
                    <td colSpan={7} className="px-4 py-3">
                      <div
                        className="flex items-center gap-3"
                        data-ocid={`confirm-revoke-${key.id}`}
                      >
                        <AlertTriangle
                          size={13}
                          className="text-destructive flex-shrink-0"
                        />
                        <span className="text-xs text-foreground font-body flex-1">
                          Revoke this key? Agents using it will lose access
                          immediately.
                        </span>
                        <Button
                          size="sm"
                          variant="destructive"
                          onClick={() => onRevoke(key.id)}
                          disabled={revoking}
                          data-ocid={`btn-revoke-confirm-${key.id}`}
                          className="h-7 text-xs"
                        >
                          {revoking ? "Revoking…" : "Confirm Revoke"}
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => setRevokeState(null)}
                          data-ocid={`btn-revoke-cancel-${key.id}`}
                          className="h-7 text-xs"
                        >
                          <X size={12} />
                          Cancel
                        </Button>
                      </div>
                    </td>
                  </tr>
                )}
              </React.Fragment>
            );
          })}
        </tbody>
      </table>

      {/* Usage hint below table */}
      <div className="px-4 py-3 bg-secondary/20 border-t border-border">
        <p className="text-[10px] font-body text-muted-foreground/60">
          Pass the key ID as the <code className="font-mono">apiKey</code>{" "}
          parameter in <code className="font-mono">execute_capability</code>{" "}
          calls.{" "}
          <span className="text-muted-foreground/40">
            Activity dots: green = last 24h · yellow = last 7 days · gray =
            never/inactive
          </span>
        </p>
      </div>
    </div>
  );
}
