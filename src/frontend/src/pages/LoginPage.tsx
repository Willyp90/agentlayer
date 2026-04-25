import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import { Zap } from "lucide-react";
import { useState } from "react";

export default function LoginPage() {
  const { login } = useInternetIdentity();
  const [isLoggingIn, setIsLoggingIn] = useState(false);

  const handleLogin = async () => {
    setIsLoggingIn(true);
    try {
      await login();
    } catch (error: unknown) {
      console.error("Login error:", error);
    } finally {
      setIsLoggingIn(false);
    }
  };

  return (
    <div
      className="min-h-screen bg-background flex items-center justify-center"
      data-ocid="login-page"
    >
      {/* Subtle grid background */}
      <div
        className="absolute inset-0 pointer-events-none opacity-[0.03]"
        style={{
          backgroundImage:
            "linear-gradient(oklch(var(--border)) 1px, transparent 1px), linear-gradient(90deg, oklch(var(--border)) 1px, transparent 1px)",
          backgroundSize: "40px 40px",
        }}
      />

      <div className="relative w-full max-w-sm">
        {/* Card */}
        <div className="border border-border bg-card rounded p-8">
          {/* Logo mark */}
          <div className="flex items-center justify-center mb-8">
            <div className="flex items-center justify-center w-12 h-12 border border-border rounded bg-background">
              <Zap size={20} className="text-accent" />
            </div>
          </div>

          {/* Title */}
          <div className="text-center mb-2">
            <h1 className="font-display text-xl font-semibold tracking-tight text-foreground">
              AgentLayer
            </h1>
          </div>
          <p className="text-center text-sm text-muted-foreground mb-8 font-body">
            AI Agent Execution Layer
          </p>

          {/* Divider */}
          <div className="border-t border-border mb-8" />

          {/* Auth info */}
          <p className="text-xs text-muted-foreground font-body mb-4 text-center">
            Authenticate with Internet Identity to access the execution layer
          </p>

          {/* Login button */}
          <button
            type="button"
            onClick={handleLogin}
            disabled={isLoggingIn}
            data-ocid="btn-login-ii"
            className={[
              "w-full flex items-center justify-center gap-2 px-4 py-2.5",
              "border border-accent/40 rounded bg-accent/5 hover:bg-accent/10",
              "text-accent text-sm font-display font-medium tracking-tight",
              "transition-smooth disabled:opacity-40 disabled:cursor-not-allowed",
              "focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-accent",
            ].join(" ")}
          >
            {isLoggingIn ? (
              <>
                <span className="w-3.5 h-3.5 rounded-full border border-accent/40 border-t-accent animate-spin" />
                <span>Connecting…</span>
              </>
            ) : (
              <>
                <Zap size={14} />
                <span>Connect with Internet Identity</span>
              </>
            )}
          </button>

          {/* Fine print */}
          <p className="text-center text-xs text-muted-foreground/50 mt-6 font-body">
            Secured by the Internet Computer
          </p>
        </div>

        {/* Bottom label */}
        <p className="text-center text-xs text-muted-foreground/40 mt-6 font-mono">
          v1.0.0 · deterministic · stateless
        </p>
      </div>
    </div>
  );
}
