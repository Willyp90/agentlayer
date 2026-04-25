import { c as createLucideIcon, q as useApiKeys, s as useGenerateApiKey, t as useRevokeApiKey, a as useNavigate, r as reactExports, j as jsxRuntimeExports, K as Key, R as React, X } from "./index-BZePS1Zd.js";
import { B as Badge } from "./badge-Bs3SiHuZ.js";
import { B as Button } from "./button-C9yg-6tA.js";
import { I as Input } from "./input-DurVsVjp.js";
import { S as Skeleton } from "./skeleton-P84x8m6O.js";
import { u as ue } from "./index-fmrAgBMw.js";
import { T as TriangleAlert } from "./triangle-alert-bjxhJeUs.js";
import { C as Check } from "./check-CK-oStBv.js";
import { C as Copy } from "./copy-Brb3v89n.js";
import { E as ExternalLink } from "./external-link-CZfckXfP.js";
import { C as Clock } from "./clock-Bdm87zxc.js";
import "./index-DYfQEczc.js";
import "./utils-2v2HxlWs.js";
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const __iconNode$1 = [
  ["path", { d: "M5 12h14", key: "1ays0h" }],
  ["path", { d: "M12 5v14", key: "s699le" }]
];
const Plus = createLucideIcon("plus", __iconNode$1);
/**
 * @license lucide-react v0.511.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */
const __iconNode = [
  ["path", { d: "M16 7h6v6", key: "box55l" }],
  ["path", { d: "m22 7-8.5 8.5-5-5L2 17", key: "1t1m79" }]
];
const TrendingUp = createLucideIcon("trending-up", __iconNode);
function relativeTime(ns) {
  const ms = Number(ns / 1000000n);
  const diff = Date.now() - ms;
  const sec = Math.floor(diff / 1e3);
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
function maskKey(id) {
  if (id.length <= 10) return id;
  return `${id.slice(0, 10)}••••••••`;
}
function getActivityLevel(key) {
  if (!key.active) return "inactive";
  if (!key.lastUsedAt) return "never";
  const ms = Number(key.lastUsedAt / 1000000n);
  const hoursSince = (Date.now() - ms) / (1e3 * 60 * 60);
  if (hoursSince < 24) return "recent";
  if (hoursSince < 168) return "stale";
  return "inactive";
}
function ActivityDot({
  level
}) {
  const colors = {
    recent: "bg-emerald-400",
    stale: "bg-yellow-400",
    inactive: "bg-muted-foreground/30",
    never: "bg-muted-foreground/20"
  };
  return /* @__PURE__ */ jsxRuntimeExports.jsx(
    "span",
    {
      className: `inline-block w-2 h-2 rounded-full shrink-0 ${colors[level]}`,
      title: level === "recent" ? "Used in last 24h" : level === "stale" ? "Used in last 7 days" : level === "never" ? "Never used" : "Revoked"
    }
  );
}
function ApiKeysPage() {
  const { data: keys, isLoading } = useApiKeys();
  const generateKey = useGenerateApiKey();
  const revokeKey = useRevokeApiKey();
  const navigate = useNavigate();
  const [showForm, setShowForm] = reactExports.useState(false);
  const [keyName, setKeyName] = reactExports.useState("");
  const [revokeState, setRevokeState] = reactExports.useState(null);
  const [newKeyReveal, setNewKeyReveal] = reactExports.useState(null);
  const handleGenerate = async () => {
    try {
      const key = await generateKey.mutateAsync({ name: keyName.trim() });
      setNewKeyReveal({ key, copied: false });
      setKeyName("");
      setShowForm(false);
    } catch (err) {
      ue.error(
        err instanceof Error ? err.message : "Failed to generate key"
      );
    }
  };
  const handleCopy = async () => {
    if (!newKeyReveal) return;
    const text = newKeyReveal.key.id;
    try {
      await navigator.clipboard.writeText(text);
    } catch {
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
    ue.success("Key copied to clipboard");
  };
  const handleRevoke = async (keyId) => {
    try {
      await revokeKey.mutateAsync({ keyId });
      setRevokeState(null);
      ue.success("Key revoked");
    } catch (err) {
      ue.error(err instanceof Error ? err.message : "Failed to revoke key");
    }
  };
  const handleCopyKeyId = async (keyId) => {
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
    ue.success("Key ID copied to clipboard");
  };
  const activeKeys = keys ?? [];
  const hasKeys = activeKeys.length > 0;
  return /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex-1 overflow-y-auto", children: [
    /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "border-b border-border bg-card px-4 md:px-6 py-4 flex items-start justify-between gap-4", children: [
      /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx("h1", { className: "text-base font-display font-semibold text-foreground tracking-tight", children: "API Keys" }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs("p", { className: "text-xs text-muted-foreground mt-0.5 font-body max-w-lg", children: [
          "Generate keys for agent/headless access. Pass as the",
          " ",
          /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono bg-secondary px-1 py-0.5 rounded text-[11px]", children: "apiKey" }),
          " ",
          "parameter in",
          " ",
          /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono bg-secondary px-1 py-0.5 rounded text-[11px]", children: "execute_capability" }),
          "."
        ] })
      ] }),
      !showForm && /* @__PURE__ */ jsxRuntimeExports.jsxs(
        Button,
        {
          size: "sm",
          onClick: () => setShowForm(true),
          "data-ocid": "btn-generate-key-open",
          className: "flex-shrink-0 gap-1.5 min-h-[44px] md:min-h-0",
          children: [
            /* @__PURE__ */ jsxRuntimeExports.jsx(Plus, { size: 14 }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "hidden sm:inline", children: "Generate New Key" }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "sm:hidden", children: "New Key" })
          ]
        }
      )
    ] }),
    /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "px-4 md:px-6 py-5 space-y-5", children: [
      showForm && /* @__PURE__ */ jsxRuntimeExports.jsxs(
        "div",
        {
          className: "border border-border rounded-md bg-card p-4 space-y-3",
          "data-ocid": "form-generate-key",
          children: [
            /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "text-xs font-display font-medium text-foreground", children: "New API Key" }),
            /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex flex-col sm:flex-row gap-2", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx(
                Input,
                {
                  placeholder: "e.g. My Agent Key",
                  value: keyName,
                  onChange: (e) => setKeyName(e.target.value),
                  className: "h-10 sm:h-8 text-sm font-mono w-full sm:max-w-xs",
                  "data-ocid": "input-key-name",
                  onKeyDown: (e) => e.key === "Enter" && handleGenerate(),
                  autoFocus: true
                }
              ),
              /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex gap-2", children: [
                /* @__PURE__ */ jsxRuntimeExports.jsx(
                  Button,
                  {
                    size: "sm",
                    onClick: handleGenerate,
                    disabled: generateKey.isPending,
                    "data-ocid": "btn-generate-key-confirm",
                    className: "flex-1 sm:flex-none min-h-[44px] sm:min-h-0",
                    children: generateKey.isPending ? "Generating…" : "Generate"
                  }
                ),
                /* @__PURE__ */ jsxRuntimeExports.jsx(
                  Button,
                  {
                    size: "sm",
                    variant: "ghost",
                    onClick: () => {
                      setShowForm(false);
                      setKeyName("");
                    },
                    "data-ocid": "btn-generate-key-cancel",
                    className: "flex-1 sm:flex-none min-h-[44px] sm:min-h-0",
                    children: "Cancel"
                  }
                )
              ] })
            ] }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs text-muted-foreground", children: "Name is optional — helps you identify which agent uses this key." })
          ]
        }
      ),
      !showForm && !hasKeys && !isLoading && /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "sm:hidden", children: /* @__PURE__ */ jsxRuntimeExports.jsxs(
        Button,
        {
          className: "w-full gap-1.5 min-h-[44px]",
          onClick: () => setShowForm(true),
          "data-ocid": "btn-generate-key-mobile-cta",
          children: [
            /* @__PURE__ */ jsxRuntimeExports.jsx(Plus, { size: 14 }),
            "Generate New Key"
          ]
        }
      ) }),
      newKeyReveal && /* @__PURE__ */ jsxRuntimeExports.jsxs(
        "div",
        {
          className: "border border-accent/40 rounded-md bg-accent/5 p-4 space-y-3",
          "data-ocid": "reveal-new-key",
          children: [
            /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-2 text-accent", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx(TriangleAlert, { size: 14 }),
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-xs font-display font-semibold", children: "Copy your key now — it will not be shown again." })
            ] }),
            /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex flex-col sm:flex-row items-stretch sm:items-center gap-2", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "flex-1 text-sm font-mono text-foreground bg-secondary border border-border rounded px-3 py-2 truncate select-all break-all", children: newKeyReveal.key.id }),
              /* @__PURE__ */ jsxRuntimeExports.jsxs(
                Button,
                {
                  size: "sm",
                  variant: "outline",
                  onClick: handleCopy,
                  "data-ocid": "btn-copy-key",
                  className: "flex-shrink-0 gap-1.5 min-h-[44px] sm:min-h-0",
                  children: [
                    newKeyReveal.copied ? /* @__PURE__ */ jsxRuntimeExports.jsx(Check, { size: 13 }) : /* @__PURE__ */ jsxRuntimeExports.jsx(Copy, { size: 13 }),
                    newKeyReveal.copied ? "Copied" : "Copy"
                  ]
                }
              )
            ] }),
            /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "text-xs text-muted-foreground font-body bg-secondary/30 rounded p-3 border border-border/50", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "font-mono text-accent", children: "Usage:" }),
              " Pass this key as the ",
              /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono", children: "apiKey" }),
              " parameter in",
              " ",
              /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono", children: "execute_capability" }),
              " calls. Test it now in the",
              " ",
              /* @__PURE__ */ jsxRuntimeExports.jsx(
                "button",
                {
                  type: "button",
                  onClick: () => navigate({
                    to: "/playground",
                    search: { capability: void 0 }
                  }),
                  className: "text-accent hover:underline font-mono",
                  children: "Playground"
                }
              ),
              "."
            ] }),
            /* @__PURE__ */ jsxRuntimeExports.jsx(
              Button,
              {
                size: "sm",
                variant: "ghost",
                onClick: () => setNewKeyReveal(null),
                "data-ocid": "btn-key-done",
                className: "text-muted-foreground hover:text-foreground w-full sm:w-auto min-h-[44px] sm:min-h-0",
                children: "Done, I've saved my key"
              }
            )
          ]
        }
      ),
      isLoading ? /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "space-y-2", "data-ocid": "keys-loading", children: [1, 2, 3].map((i) => /* @__PURE__ */ jsxRuntimeExports.jsx(Skeleton, { className: "h-16 w-full rounded-md" }, i)) }) : !hasKeys ? /* @__PURE__ */ jsxRuntimeExports.jsx(EmptyState, { onGenerate: () => setShowForm(true) }) : /* @__PURE__ */ jsxRuntimeExports.jsxs(jsxRuntimeExports.Fragment, { children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "hidden md:block", children: /* @__PURE__ */ jsxRuntimeExports.jsx(
          KeysTable,
          {
            keys: activeKeys,
            revokeState,
            setRevokeState,
            onRevoke: handleRevoke,
            revoking: revokeKey.isPending,
            onCopyKeyId: handleCopyKeyId,
            onViewLogs: (keyId) => navigate({
              to: "/logs",
              search: { keyId }
            })
          }
        ) }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "md:hidden space-y-3", "data-ocid": "keys-cards", children: activeKeys.map((key) => /* @__PURE__ */ jsxRuntimeExports.jsx(
          KeyCard,
          {
            apiKey: key,
            revokeState,
            setRevokeState,
            onRevoke: handleRevoke,
            revoking: revokeKey.isPending,
            onCopyKeyId: handleCopyKeyId,
            onViewLogs: (keyId) => navigate({
              to: "/logs",
              search: { keyId }
            })
          },
          key.id
        )) })
      ] })
    ] })
  ] });
}
function KeyCard({
  apiKey,
  revokeState,
  setRevokeState,
  onRevoke,
  revoking,
  onCopyKeyId,
  onViewLogs
}) {
  const isRevoking = (revokeState == null ? void 0 : revokeState.keyId) === apiKey.id && revokeState.confirming;
  const activity = getActivityLevel(apiKey);
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "div",
    {
      className: "border border-border rounded-md bg-card overflow-hidden",
      "data-ocid": `key-card-${apiKey.id}`,
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "p-4 space-y-3", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center justify-between gap-2", children: [
            /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-2 min-w-0", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx(ActivityDot, { level: activity }),
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-sm font-body text-foreground truncate", children: apiKey.name || /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-muted-foreground italic text-xs", children: "Unnamed Key" }) })
            ] }),
            apiKey.active ? /* @__PURE__ */ jsxRuntimeExports.jsx(
              Badge,
              {
                variant: "outline",
                className: "text-[10px] border-emerald-500/40 text-emerald-400 bg-emerald-500/10 font-mono shrink-0",
                "data-ocid": `badge-active-${apiKey.id}`,
                children: "active"
              }
            ) : /* @__PURE__ */ jsxRuntimeExports.jsx(
              Badge,
              {
                variant: "outline",
                className: "text-[10px] border-destructive/40 text-destructive bg-destructive/10 font-mono shrink-0",
                "data-ocid": `badge-revoked-${apiKey.id}`,
                children: "revoked"
              }
            )
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "font-mono text-xs text-muted-foreground bg-secondary/50 rounded px-3 py-2", children: maskKey(apiKey.id) }),
          /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "grid grid-cols-2 gap-2 text-[11px] font-mono text-muted-foreground", children: [
            /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-1", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx(TrendingUp, { size: 10, className: "text-muted-foreground/40" }),
              /* @__PURE__ */ jsxRuntimeExports.jsxs("span", { children: [
                apiKey.callCount.toString(),
                " call",
                apiKey.callCount !== 1n ? "s" : ""
              ] })
            ] }),
            /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-1", children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx(Clock, { size: 10, className: "text-muted-foreground/40" }),
              /* @__PURE__ */ jsxRuntimeExports.jsx("span", { children: apiKey.lastUsedAt ? relativeTime(apiKey.lastUsedAt) : "Never used" })
            ] })
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "text-[10px] font-mono text-muted-foreground/50", children: [
            "Created ",
            relativeTime(apiKey.createdAt)
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsxs("p", { className: "text-[10px] font-body text-muted-foreground/50 leading-relaxed", children: [
            "Pass this key as the ",
            /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono", children: "apiKey" }),
            " ",
            "parameter in ",
            /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono", children: "execute_capability" }),
            "."
          ] }),
          /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-3 flex-wrap", children: [
            /* @__PURE__ */ jsxRuntimeExports.jsxs(
              "button",
              {
                type: "button",
                onClick: () => onCopyKeyId(apiKey.id),
                "data-ocid": `btn-copy-key-id-${apiKey.id}`,
                className: "flex items-center gap-1 text-xs font-mono text-muted-foreground hover:text-foreground transition-colors duration-150 min-h-[44px]",
                children: [
                  /* @__PURE__ */ jsxRuntimeExports.jsx(Copy, { size: 11 }),
                  "Copy ID"
                ]
              }
            ),
            /* @__PURE__ */ jsxRuntimeExports.jsxs(
              "button",
              {
                type: "button",
                onClick: () => onViewLogs(apiKey.id),
                "data-ocid": `btn-view-logs-${apiKey.id}`,
                className: "flex items-center gap-1 text-xs font-mono text-muted-foreground hover:text-accent transition-colors duration-150 min-h-[44px]",
                children: [
                  /* @__PURE__ */ jsxRuntimeExports.jsx(ExternalLink, { size: 11 }),
                  "View in Logs"
                ]
              }
            ),
            apiKey.active && !isRevoking && /* @__PURE__ */ jsxRuntimeExports.jsx(
              "button",
              {
                type: "button",
                onClick: () => setRevokeState({ keyId: apiKey.id, confirming: true }),
                "data-ocid": `btn-revoke-${apiKey.id}`,
                className: "text-xs text-muted-foreground hover:text-destructive transition-colors duration-150 font-body min-h-[44px] ml-auto",
                children: "Revoke"
              }
            )
          ] })
        ] }),
        isRevoking && /* @__PURE__ */ jsxRuntimeExports.jsxs(
          "div",
          {
            className: "border-t border-border bg-destructive/5 p-4",
            "data-ocid": `confirm-revoke-${apiKey.id}`,
            children: [
              /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-start gap-2 mb-3", children: [
                /* @__PURE__ */ jsxRuntimeExports.jsx(
                  TriangleAlert,
                  {
                    size: 13,
                    className: "text-destructive flex-shrink-0 mt-0.5"
                  }
                ),
                /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-xs text-foreground font-body", children: "Revoke this key? Agents using it will lose access immediately." })
              ] }),
              /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex gap-2", children: [
                /* @__PURE__ */ jsxRuntimeExports.jsx(
                  Button,
                  {
                    size: "sm",
                    variant: "destructive",
                    onClick: () => onRevoke(apiKey.id),
                    disabled: revoking,
                    "data-ocid": `btn-revoke-confirm-${apiKey.id}`,
                    className: "flex-1 min-h-[44px]",
                    children: revoking ? "Revoking…" : "Confirm Revoke"
                  }
                ),
                /* @__PURE__ */ jsxRuntimeExports.jsxs(
                  Button,
                  {
                    size: "sm",
                    variant: "ghost",
                    onClick: () => setRevokeState(null),
                    "data-ocid": `btn-revoke-cancel-${apiKey.id}`,
                    className: "flex-1 min-h-[44px]",
                    children: [
                      /* @__PURE__ */ jsxRuntimeExports.jsx(X, { size: 12 }),
                      "Cancel"
                    ]
                  }
                )
              ] })
            ]
          }
        )
      ]
    }
  );
}
function EmptyState({ onGenerate }) {
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "div",
    {
      className: "flex flex-col items-center justify-center py-16 md:py-20 text-center",
      "data-ocid": "empty-api-keys",
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "w-10 h-10 rounded-full bg-secondary flex items-center justify-center mb-4", children: /* @__PURE__ */ jsxRuntimeExports.jsx(Key, { size: 18, className: "text-muted-foreground" }) }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("h3", { className: "text-sm font-display font-semibold text-foreground mb-1.5", children: "No API keys yet" }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("p", { className: "text-xs text-muted-foreground mb-5 max-w-xs", children: "Generate your first key to enable agent/headless access to your capabilities." }),
        /* @__PURE__ */ jsxRuntimeExports.jsxs(
          Button,
          {
            size: "sm",
            onClick: onGenerate,
            "data-ocid": "btn-empty-generate-key",
            className: "gap-1.5 w-full sm:w-auto min-h-[44px]",
            children: [
              /* @__PURE__ */ jsxRuntimeExports.jsx(Plus, { size: 14 }),
              "Generate New Key"
            ]
          }
        )
      ]
    }
  );
}
function KeysTable({
  keys,
  revokeState,
  setRevokeState,
  onRevoke,
  revoking,
  onCopyKeyId,
  onViewLogs
}) {
  return /* @__PURE__ */ jsxRuntimeExports.jsxs(
    "div",
    {
      className: "border border-border rounded-md overflow-hidden",
      "data-ocid": "keys-table",
      children: [
        /* @__PURE__ */ jsxRuntimeExports.jsxs("table", { className: "w-full text-xs", children: [
          /* @__PURE__ */ jsxRuntimeExports.jsx("thead", { children: /* @__PURE__ */ jsxRuntimeExports.jsxs("tr", { className: "border-b border-border bg-secondary/50", children: [
            /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "text-left px-4 py-2.5 font-display font-medium text-muted-foreground", children: "Name" }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "text-left px-4 py-2.5 font-display font-medium text-muted-foreground", children: "Key" }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "text-left px-4 py-2.5 font-display font-medium text-muted-foreground", children: "Status" }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "text-left px-4 py-2.5 font-display font-medium text-muted-foreground", children: "Created" }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "text-left px-4 py-2.5 font-display font-medium text-muted-foreground", children: "Last Used" }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "text-right px-4 py-2.5 font-display font-medium text-muted-foreground", children: "Calls" }),
            /* @__PURE__ */ jsxRuntimeExports.jsx("th", { className: "text-right px-4 py-2.5 font-display font-medium text-muted-foreground", children: "Actions" })
          ] }) }),
          /* @__PURE__ */ jsxRuntimeExports.jsx("tbody", { children: keys.map((key) => {
            const isRevoking = (revokeState == null ? void 0 : revokeState.keyId) === key.id && revokeState.confirming;
            const activity = getActivityLevel(key);
            return /* @__PURE__ */ jsxRuntimeExports.jsxs(React.Fragment, { children: [
              /* @__PURE__ */ jsxRuntimeExports.jsxs(
                "tr",
                {
                  className: "border-b border-border last:border-0 hover:bg-secondary/30 transition-colors duration-100",
                  "data-ocid": `key-row-${key.id}`,
                  children: [
                    /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3 font-body text-foreground", children: /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center gap-2", children: [
                      /* @__PURE__ */ jsxRuntimeExports.jsx(ActivityDot, { level: activity }),
                      key.name || /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-muted-foreground italic", children: "Unnamed Key" })
                    ] }) }),
                    /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3 font-mono text-muted-foreground", children: maskKey(key.id) }),
                    /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3", children: key.active ? /* @__PURE__ */ jsxRuntimeExports.jsx(
                      Badge,
                      {
                        variant: "outline",
                        className: "text-[10px] border-emerald-500/40 text-emerald-400 bg-emerald-500/10 font-mono",
                        "data-ocid": `badge-active-${key.id}`,
                        children: "active"
                      }
                    ) : /* @__PURE__ */ jsxRuntimeExports.jsx(
                      Badge,
                      {
                        variant: "outline",
                        className: "text-[10px] border-destructive/40 text-destructive bg-destructive/10 font-mono",
                        "data-ocid": `badge-revoked-${key.id}`,
                        children: "revoked"
                      }
                    ) }),
                    /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3 text-muted-foreground font-mono", children: relativeTime(key.createdAt) }),
                    /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3 text-muted-foreground font-mono", children: key.lastUsedAt ? relativeTime(key.lastUsedAt) : "Never" }),
                    /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3 text-right font-mono text-foreground tabular-nums", children: key.callCount.toString() }),
                    /* @__PURE__ */ jsxRuntimeExports.jsx("td", { className: "px-4 py-3", children: /* @__PURE__ */ jsxRuntimeExports.jsxs("div", { className: "flex items-center justify-end gap-3", children: [
                      /* @__PURE__ */ jsxRuntimeExports.jsxs(
                        "button",
                        {
                          type: "button",
                          onClick: () => onCopyKeyId(key.id),
                          "data-ocid": `btn-copy-key-id-${key.id}`,
                          className: "flex items-center gap-1 text-muted-foreground hover:text-foreground transition-colors duration-150",
                          title: "Copy Key ID",
                          children: [
                            /* @__PURE__ */ jsxRuntimeExports.jsx(Copy, { size: 11 }),
                            /* @__PURE__ */ jsxRuntimeExports.jsx("span", { children: "Copy" })
                          ]
                        }
                      ),
                      /* @__PURE__ */ jsxRuntimeExports.jsxs(
                        "button",
                        {
                          type: "button",
                          onClick: () => onViewLogs(key.id),
                          "data-ocid": `btn-view-logs-${key.id}`,
                          className: "flex items-center gap-1 text-muted-foreground hover:text-accent transition-colors duration-150",
                          title: "View in Logs",
                          children: [
                            /* @__PURE__ */ jsxRuntimeExports.jsx(ExternalLink, { size: 11 }),
                            /* @__PURE__ */ jsxRuntimeExports.jsx("span", { children: "Logs" })
                          ]
                        }
                      ),
                      key.active && !isRevoking && /* @__PURE__ */ jsxRuntimeExports.jsx(
                        "button",
                        {
                          type: "button",
                          onClick: () => setRevokeState({ keyId: key.id, confirming: true }),
                          "data-ocid": `btn-revoke-${key.id}`,
                          className: "text-muted-foreground hover:text-destructive transition-colors duration-150",
                          children: "Revoke"
                        }
                      )
                    ] }) })
                  ]
                }
              ),
              isRevoking && /* @__PURE__ */ jsxRuntimeExports.jsx("tr", { className: "border-b border-border last:border-0 bg-destructive/5", children: /* @__PURE__ */ jsxRuntimeExports.jsx("td", { colSpan: 7, className: "px-4 py-3", children: /* @__PURE__ */ jsxRuntimeExports.jsxs(
                "div",
                {
                  className: "flex items-center gap-3",
                  "data-ocid": `confirm-revoke-${key.id}`,
                  children: [
                    /* @__PURE__ */ jsxRuntimeExports.jsx(
                      TriangleAlert,
                      {
                        size: 13,
                        className: "text-destructive flex-shrink-0"
                      }
                    ),
                    /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-xs text-foreground font-body flex-1", children: "Revoke this key? Agents using it will lose access immediately." }),
                    /* @__PURE__ */ jsxRuntimeExports.jsx(
                      Button,
                      {
                        size: "sm",
                        variant: "destructive",
                        onClick: () => onRevoke(key.id),
                        disabled: revoking,
                        "data-ocid": `btn-revoke-confirm-${key.id}`,
                        className: "h-7 text-xs",
                        children: revoking ? "Revoking…" : "Confirm Revoke"
                      }
                    ),
                    /* @__PURE__ */ jsxRuntimeExports.jsxs(
                      Button,
                      {
                        size: "sm",
                        variant: "ghost",
                        onClick: () => setRevokeState(null),
                        "data-ocid": `btn-revoke-cancel-${key.id}`,
                        className: "h-7 text-xs",
                        children: [
                          /* @__PURE__ */ jsxRuntimeExports.jsx(X, { size: 12 }),
                          "Cancel"
                        ]
                      }
                    )
                  ]
                }
              ) }) })
            ] }, key.id);
          }) })
        ] }),
        /* @__PURE__ */ jsxRuntimeExports.jsx("div", { className: "px-4 py-3 bg-secondary/20 border-t border-border", children: /* @__PURE__ */ jsxRuntimeExports.jsxs("p", { className: "text-[10px] font-body text-muted-foreground/60", children: [
          "Pass the key ID as the ",
          /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono", children: "apiKey" }),
          " ",
          "parameter in ",
          /* @__PURE__ */ jsxRuntimeExports.jsx("code", { className: "font-mono", children: "execute_capability" }),
          " ",
          "calls.",
          " ",
          /* @__PURE__ */ jsxRuntimeExports.jsx("span", { className: "text-muted-foreground/40", children: "Activity dots: green = last 24h · yellow = last 7 days · gray = never/inactive" })
        ] }) })
      ]
    }
  );
}
export {
  ApiKeysPage as default
};
