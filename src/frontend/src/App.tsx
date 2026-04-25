import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import {
  Navigate,
  Outlet,
  RouterProvider,
  createRootRoute,
  createRoute,
  createRouter,
} from "@tanstack/react-router";
import { Suspense, lazy } from "react";
import { Layout } from "./components/Layout";
import LandingPage from "./pages/LandingPage";

const CapabilitiesPage = lazy(() => import("./pages/CapabilitiesPage"));
const CapabilityDetailPage = lazy(() => import("./pages/CapabilityDetailPage"));
const PlaygroundPage = lazy(() => import("./pages/PlaygroundPage"));
const LogsPage = lazy(() => import("./pages/LogsPage"));
const UsagePage = lazy(() => import("./pages/UsagePage"));
const ApiKeysPage = lazy(() => import("./pages/ApiKeysPage"));
const AuditLogPage = lazy(() => import("./pages/AuditLogPage"));
const IntegrationPage = lazy(() => import("./pages/IntegrationPage"));
const AdminValidationPage = lazy(() => import("./pages/AdminValidationPage"));

// ── Loading fallback ─────────────────────────────────────────────────────────
function PageLoader() {
  return (
    <div className="flex-1 flex items-center justify-center">
      <span className="text-xs text-muted-foreground font-mono animate-pulse">
        loading…
      </span>
    </div>
  );
}

// ── Root: split public vs. authenticated ────────────────────────────────────
function RootLayout() {
  const { identity, isLoginSuccess } = useInternetIdentity();
  const isAuthenticated = !!identity || isLoginSuccess;

  if (!isAuthenticated) {
    return <LandingPage />;
  }

  return (
    <Layout>
      <Suspense fallback={<PageLoader />}>
        <Outlet />
      </Suspense>
    </Layout>
  );
}

// ── Home redirect: authenticated → /capabilities ────────────────────────────
function HomeRedirect() {
  const { identity, isLoginSuccess } = useInternetIdentity();
  const isAuthenticated = !!identity || isLoginSuccess;

  if (isAuthenticated) {
    return <Navigate to="/capabilities" replace />;
  }
  // Unauthenticated users are handled by RootLayout rendering LandingPage
  return null;
}

// ── Routes ───────────────────────────────────────────────────────────────────
const rootRoute = createRootRoute({ component: RootLayout });

const homeRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/",
  component: HomeRedirect,
});

const capabilitiesRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/capabilities",
  component: CapabilitiesPage,
});

const capabilityDetailRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/capabilities/$name",
  component: CapabilityDetailPage,
});

const playgroundRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/playground",
  validateSearch: (search: Record<string, unknown>) => ({
    capability:
      typeof search.capability === "string" ? search.capability : undefined,
  }),
  component: PlaygroundPage,
});

const logsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/logs",
  component: LogsPage,
});

const usageRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/usage",
  component: UsagePage,
});

const apiKeysRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/api-keys",
  component: ApiKeysPage,
});

const auditLogRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/audit-log",
  component: AuditLogPage,
});

const integrationRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/integration",
  component: IntegrationPage,
});

const validationRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/validation",
  component: AdminValidationPage,
});

const routeTree = rootRoute.addChildren([
  homeRoute,
  capabilitiesRoute,
  capabilityDetailRoute,
  playgroundRoute,
  logsRoute,
  usageRoute,
  apiKeysRoute,
  auditLogRoute,
  integrationRoute,
  validationRoute,
]);

const router = createRouter({ routeTree });

declare module "@tanstack/react-router" {
  interface Register {
    router: typeof router;
  }
}

export default function App() {
  return <RouterProvider router={router} />;
}
