import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import { useQueryClient } from "@tanstack/react-query";
import { Link, useRouterState } from "@tanstack/react-router";
import {
  Activity,
  BarChart3,
  BookOpen,
  ChevronLeft,
  ChevronRight,
  Code2,
  FlaskConical,
  Key,
  LogOut,
  Menu,
  Shield,
  Terminal,
  X,
  Zap,
} from "lucide-react";
import type React from "react";
import { useEffect, useRef, useState } from "react";
import { useAdminStatus } from "../hooks/useBackend";

interface NavItem {
  to: string;
  icon: React.ReactNode;
  label: string;
  ocid: string;
  adminOnly?: boolean;
}

export const NAV_ITEMS: NavItem[] = [
  {
    to: "/",
    icon: <Code2 size={16} />,
    label: "Capabilities",
    ocid: "nav-capabilities",
  },
  {
    to: "/playground",
    icon: <Terminal size={16} />,
    label: "Playground",
    ocid: "nav-playground",
  },
  {
    to: "/logs",
    icon: <Activity size={16} />,
    label: "Logs",
    ocid: "nav-logs",
  },
  {
    to: "/usage",
    icon: <BarChart3 size={16} />,
    label: "Usage",
    ocid: "nav-usage",
  },
  {
    to: "/api-keys",
    icon: <Key size={16} />,
    label: "API Keys",
    ocid: "nav-api-keys",
  },
  {
    to: "/audit-log",
    icon: <Shield size={16} />,
    label: "Audit Log",
    ocid: "nav-audit-log",
  },
  {
    to: "/integration",
    icon: <BookOpen size={16} />,
    label: "Integration",
    ocid: "nav-integration",
  },
  {
    to: "/validation",
    icon: <FlaskConical size={16} />,
    label: "Validation",
    ocid: "nav-validation",
    adminOnly: true,
  },
];

function getStoredCollapsed(): boolean {
  try {
    return localStorage.getItem("sidebar-collapsed") === "true";
  } catch {
    return false;
  }
}

interface SidebarContentProps {
  collapsed: boolean;
  currentPath: string;
  principalShort: string;
  isAdmin: boolean;
  onNavClick?: () => void;
  onToggleCollapse?: () => void;
  showCollapseBtn?: boolean;
}

function SidebarContent({
  collapsed,
  currentPath,
  principalShort,
  isAdmin,
  onNavClick,
  onToggleCollapse,
  showCollapseBtn = false,
}: SidebarContentProps) {
  const { clear } = useInternetIdentity();
  const queryClient = useQueryClient();

  const handleLogout = async () => {
    await clear();
    queryClient.clear();
  };

  const visibleItems = NAV_ITEMS.filter((item) => !item.adminOnly || isAdmin);

  return (
    <div className="flex flex-col h-full">
      {/* Logo */}
      <div className="flex items-center gap-2.5 px-4 h-12 border-b border-border shrink-0">
        <Zap size={16} className="text-accent shrink-0" />
        {!collapsed && (
          <span className="font-display text-sm font-semibold tracking-tight text-foreground truncate">
            AgentLayer
          </span>
        )}
      </div>

      {/* Nav */}
      <nav className="flex-1 py-2 overflow-y-auto" data-ocid="sidebar-nav">
        {visibleItems.map((item) => {
          const isActive =
            item.to === "/"
              ? currentPath === "/"
              : currentPath.startsWith(item.to);
          return (
            <div key={item.to} className="relative group/tip">
              <Link
                to={item.to}
                data-ocid={item.ocid}
                onClick={onNavClick}
                className={[
                  "flex items-center gap-2.5 py-2 mx-2 rounded text-sm transition-smooth",
                  collapsed ? "px-3 justify-center" : "px-4",
                  "hover:bg-secondary hover:text-foreground",
                  isActive
                    ? "bg-accent/10 text-accent border border-accent/20"
                    : "text-muted-foreground border border-transparent",
                ].join(" ")}
              >
                {item.icon}
                {!collapsed && <span className="font-body">{item.label}</span>}
              </Link>
              {/* Tooltip when collapsed */}
              {collapsed && (
                <div className="pointer-events-none absolute left-full top-1/2 -translate-y-1/2 ml-2 z-50 opacity-0 group-hover/tip:opacity-100 transition-opacity duration-150">
                  <div className="bg-popover border border-border rounded px-2 py-1 text-xs font-mono text-foreground whitespace-nowrap shadow-lg">
                    {item.label}
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="border-t border-border px-3 py-3 shrink-0">
        {collapsed ? (
          <div className="flex flex-col items-center gap-2">
            <button
              type="button"
              onClick={handleLogout}
              data-ocid="btn-logout"
              className="p-1.5 rounded text-muted-foreground hover:text-foreground hover:bg-secondary transition-smooth"
              aria-label="Logout"
            >
              <LogOut size={14} />
            </button>
          </div>
        ) : (
          <>
            <div className="flex items-center justify-between gap-2">
              <div className="min-w-0">
                <div className="text-xs text-muted-foreground font-mono truncate">
                  {principalShort}
                </div>
                <div className="text-xs text-muted-foreground/60 mt-0.5">
                  Internet Identity
                </div>
              </div>
              <button
                type="button"
                onClick={handleLogout}
                data-ocid="btn-logout"
                className="flex-shrink-0 p-1.5 rounded text-muted-foreground hover:text-foreground hover:bg-secondary transition-smooth"
                aria-label="Logout"
              >
                <LogOut size={14} />
              </button>
            </div>
            <div className="mt-3 pt-3 border-t border-border/50">
              <p className="text-[10px] text-muted-foreground/40 font-body leading-relaxed">
                Need help?{" "}
                <a
                  href={`https://caffeine.ai?utm_source=caffeine-footer&utm_medium=referral&utm_content=${encodeURIComponent(typeof window !== "undefined" ? window.location.hostname : "")}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-muted-foreground/60 hover:text-muted-foreground underline transition-colors duration-150"
                >
                  Contact Caffeine support
                </a>
              </p>
            </div>
          </>
        )}

        {/* Desktop collapse toggle */}
        {showCollapseBtn && onToggleCollapse && (
          <button
            type="button"
            onClick={onToggleCollapse}
            data-ocid="btn-sidebar-collapse"
            className={`mt-2 flex items-center justify-center w-full py-1.5 rounded text-muted-foreground hover:text-foreground hover:bg-secondary transition-smooth ${collapsed ? "" : "gap-1.5"}`}
            aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
          >
            {collapsed ? (
              <ChevronRight size={13} />
            ) : (
              <>
                <ChevronLeft size={13} />
                <span className="text-[10px] font-mono">Collapse</span>
              </>
            )}
          </button>
        )}
      </div>
    </div>
  );
}

interface LayoutProps {
  children: React.ReactNode;
}

export function Layout({ children }: LayoutProps) {
  const { identity } = useInternetIdentity();
  const queryClient = useQueryClient();
  const routerState = useRouterState();
  const currentPath = routerState.location.pathname;
  const { data: isAdmin = false } = useAdminStatus();

  const [collapsed, setCollapsed] = useState(getStoredCollapsed);
  const [mobileOpen, setMobileOpen] = useState(false);

  const principalShort = identity
    ? `${identity.getPrincipal().toString().slice(0, 8)}…`
    : "";

  // Force a fresh admin status check every time the authenticated principal changes (login/re-login)
  const prevPrincipalRef = useRef<string>("");
  const principalText = identity?.getPrincipal()?.toText() ?? "anonymous";
  if (prevPrincipalRef.current !== principalText) {
    prevPrincipalRef.current = principalText;
    queryClient.invalidateQueries({ queryKey: ["admin_status"] });
  }

  const toggleCollapse = () => {
    setCollapsed((prev) => {
      const next = !prev;
      try {
        localStorage.setItem("sidebar-collapsed", String(next));
      } catch {}
      return next;
    });
  };

  // Close mobile drawer on route change
  const prevPath = useRef(currentPath);
  if (prevPath.current !== currentPath) {
    prevPath.current = currentPath;
    if (mobileOpen) setMobileOpen(false);
  }

  // Prevent body scroll when drawer is open
  useEffect(() => {
    if (mobileOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [mobileOpen]);

  return (
    <div className="flex h-screen bg-background text-foreground overflow-hidden">
      {/* Desktop sidebar */}
      <aside
        className={[
          "hidden lg:flex flex-col flex-shrink-0 border-r border-border bg-card",
          "transition-all duration-200 ease-in-out overflow-hidden",
          collapsed ? "w-14" : "w-56",
        ].join(" ")}
        data-ocid="sidebar-desktop"
      >
        <SidebarContent
          collapsed={collapsed}
          currentPath={currentPath}
          principalShort={principalShort}
          isAdmin={isAdmin}
          onToggleCollapse={toggleCollapse}
          showCollapseBtn
        />
      </aside>

      {/* Mobile drawer backdrop */}
      {mobileOpen && (
        <div
          className="fixed inset-0 z-40 bg-background/80 backdrop-blur-sm lg:hidden"
          onClick={() => setMobileOpen(false)}
          onKeyDown={(e) => e.key === "Escape" && setMobileOpen(false)}
          role="button"
          tabIndex={-1}
          aria-hidden="true"
          data-ocid="sidebar-backdrop"
        />
      )}

      {/* Mobile drawer */}
      <aside
        className={[
          "fixed inset-y-0 left-0 z-50 w-64 flex flex-col bg-card border-r border-border lg:hidden",
          "transition-transform duration-200 ease-in-out",
          mobileOpen ? "translate-x-0" : "-translate-x-full",
        ].join(" ")}
        data-ocid="sidebar-mobile"
      >
        <button
          type="button"
          onClick={() => setMobileOpen(false)}
          className="absolute top-3 right-3 p-1.5 rounded text-muted-foreground hover:text-foreground hover:bg-secondary transition-smooth"
          aria-label="Close menu"
          data-ocid="btn-close-drawer"
        >
          <X size={14} />
        </button>
        <SidebarContent
          collapsed={false}
          currentPath={currentPath}
          principalShort={principalShort}
          isAdmin={isAdmin}
          onNavClick={() => setMobileOpen(false)}
        />
      </aside>

      {/* Main area */}
      <div className="flex flex-col flex-1 min-w-0 overflow-hidden">
        {/* Mobile top bar */}
        <div className="lg:hidden flex items-center h-12 px-4 border-b border-border bg-card shrink-0">
          <button
            type="button"
            onClick={() => setMobileOpen(true)}
            data-ocid="btn-hamburger"
            className="p-2 -ml-2 rounded text-muted-foreground hover:text-foreground hover:bg-secondary transition-smooth min-h-[44px] min-w-[44px] flex items-center justify-center"
            aria-label="Open menu"
          >
            <Menu size={18} />
          </button>
          <div className="flex-1 flex justify-center">
            <div className="flex items-center gap-2">
              <Zap size={14} className="text-accent" />
              <span className="font-display text-sm font-semibold tracking-tight text-foreground">
                AgentLayer
              </span>
            </div>
          </div>
          <div className="text-xs font-mono text-muted-foreground truncate max-w-[80px]">
            {principalShort}
          </div>
        </div>

        {/* Page content */}
        <main className="flex-1 overflow-hidden flex flex-col min-w-0">
          {children}
        </main>
      </div>
    </div>
  );
}
