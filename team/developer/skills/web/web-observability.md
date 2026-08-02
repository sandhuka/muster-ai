# Web Observability

## Purpose
Define how to operate the system once deployed: structured logging via pino with JSON output, correlation IDs propagated via AsyncLocalStorage, error tracking via Sentry with source maps and release tagging, the operational-vs-programmer error distinction, `error.tsx` placement strategy, Server Action error envelopes that don't leak internals, OpenTelemetry instrumentation, redaction policy. The difference between debugging at 2am and not. See the `web-architecture` skill for the Result-as-operational-error pattern. See the `web-modern-react` skill for error boundary semantics. See the `web-security` skill for the security overlap on redaction. See the `web-cicd` skill for tying release tags to deploys. Target: **pino 9+, Sentry SDK for Next.js 8+, OpenTelemetry SDK 1.x, Node.js 20+**.

## Operational vs Programmer Errors

The foundational distinction every observability decision flows from:

| Category | Examples | Handling | Surfacing |
|----------|----------|----------|-----------|
| **Operational** | Validation failure, not-found, unauthorized, rate-limited, third-party API timeout | Returned as typed Result envelopes | Logged at INFO/WARN; user gets actionable message |
| **Programmer** | Unhandled case, null deref, contract violation, unexpected exception | Thrown; caught by `error.tsx` boundary | Logged at ERROR; reported to Sentry; user gets generic "Something went wrong" |

Operational errors are *expected*. They're part of the contract. They get returned as `{ ok: false, error }` envelopes (per `web-architecture.md`). They never throw across the client boundary.

Programmer errors are *bugs*. They get thrown. The error boundary catches them, the logger captures structured details, Sentry gets the stack trace, the user sees a recovery action.

```ts
// Right — operational error returned, not thrown
export async function deleteInvoice(id: InvoiceId, deps = liveDeps): Promise<DeleteResult> {
  const session = await deps.session.read();
  if (!session) return { ok: false, error: "unauthorized" };

  const result = await deps.invoiceRepository.findById(id);
  if (!result.ok) {
    if (result.error.kind === "not-found") return { ok: false, error: "not-found" };
    deps.logger.error({ err: result.error }, "Repository failure in deleteInvoice");
    return { ok: false, error: "internal" };
  }
  // ...
}
```

Repository connection failures are operational at the repository layer (returned as `Result`), become programmer-error-class at the action layer if they're unexpected — log, return generic envelope, let observability surface the underlying failure.

## Structured Logging via pino

`console.log` is forbidden in production code paths. Use `pino` — fast, JSON-native, redaction-capable.

```ts
// lib/logger.ts
import pino from "pino";
import { env } from "./env";

export const logger = pino({
  level: env.LOG_LEVEL ?? (env.NODE_ENV === "production" ? "info" : "debug"),
  base: { service: "web", env: env.NODE_ENV },
  redact: {
    paths: [
      "password", "*.password",
      "token", "*.token",
      "authorization", "*.authorization",
      "cookie", "*.cookie",
      "*.secret", "secret",
      "*.apiKey", "apiKey",
      "creditCard", "*.creditCard",
      "ssn", "*.ssn",
      "headers.cookie", "headers.authorization",
      "req.body.password", "req.body.token",
    ],
    censor: "[REDACTED]",
  },
  formatters: {
    level: (label) => ({ level: label }),
  },
  timestamp: pino.stdTimeFunctions.isoTime,
});

export type Logger = typeof logger;
```

Rules:
- **JSON output**, always. Even in dev — log aggregators parse JSON; humans can pipe through `pino-pretty` for local dev.
- **Levels**: `trace`, `debug`, `info`, `warn`, `error`, `fatal`. `info` is the production default; `debug` for local dev. Verbose levels are noise in production.
- **Structured fields, not interpolated strings.** `logger.info({ userId, invoiceId }, "Invoice deleted")` — not `` `User ${userId} deleted invoice ${invoiceId}` ``. Aggregators index structured fields; interpolated strings become opaque.
- **`base` carries always-on metadata** — service name, environment, deploy SHA. Keeps logs joinable across services.
- **Never `console.log` from production code.** Lint rule (`no-console`) enforces.

## Correlation IDs via AsyncLocalStorage

A single request flows through a Server Action → multiple repository calls → maybe an external API → response. Without a correlation ID, those logs are scattered across the file. With one, they're joinable.

`AsyncLocalStorage` propagates the request-scoped ID without passing it through every function signature.

```ts
// lib/request-context.ts
import { AsyncLocalStorage } from "node:async_hooks";

export interface RequestContext {
  requestId: string;
  userId?: string;
  startedAt: number;
}

const storage = new AsyncLocalStorage<RequestContext>();

export function runWithContext<T>(context: RequestContext, fn: () => Promise<T>): Promise<T> {
  return storage.run(context, fn);
}

export function getContext(): RequestContext | undefined {
  return storage.getStore();
}
```

```ts
// lib/logger.ts (extends prior)
import { logger as base } from "./logger-base";
import { getContext } from "./request-context";

function withContext(level: pino.Level) {
  return (obj: object | string, msg?: string) => {
    const ctx = getContext();
    const merged = typeof obj === "string"
      ? { msg: obj, requestId: ctx?.requestId, userId: ctx?.userId }
      : { ...obj, requestId: ctx?.requestId, userId: ctx?.userId };
    base[level](merged, msg);
  };
}

export const logger = {
  trace: withContext("trace"),
  debug: withContext("debug"),
  info: withContext("info"),
  warn: withContext("warn"),
  error: withContext("error"),
  fatal: withContext("fatal"),
};
```

```ts
// middleware.ts (excerpted — runs the request inside the context)
import { runWithContext } from "@/lib/request-context";
import { randomUUID } from "node:crypto";

export async function middleware(request: NextRequest) {
  const requestId = request.headers.get("x-request-id") ?? randomUUID();
  // ... existing CSP, auth, etc.
  // Note: AsyncLocalStorage doesn't traverse the middleware → handler boundary
  // in Vercel's runtime model. Use a top-of-action wrapper instead.
}
```

For Server Actions, the practical wrapper:

```ts
// lib/with-context.ts
import { runWithContext, type RequestContext } from "./request-context";
import { headers } from "next/headers";
import { randomUUID } from "node:crypto";

export async function withRequestContext<T>(fn: () => Promise<T>): Promise<T> {
  const h = await headers();
  const context: RequestContext = {
    requestId: h.get("x-request-id") ?? randomUUID(),
    startedAt: Date.now(),
  };
  return runWithContext(context, fn);
}
```

```ts
// features/invoicing/actions.ts
"use server";
export async function createInvoice(formData: FormData, deps = liveDeps) {
  return withRequestContext(async () => {
    deps.logger.info({ event: "createInvoice.start" });
    // ... action body ...
    deps.logger.info({ event: "createInvoice.complete", invoiceId });
    return result;
  });
}
```

Rules:
- **Request ID is generated at the edge** (middleware sets `x-request-id` on every request) and propagated to logs via `AsyncLocalStorage`.
- **Wrap every Server Action and Route Handler entry point in `withRequestContext`.** A consistent pattern — every action's first inner call.
- **Pass `requestId` to external API calls** as `X-Request-Id` so upstream services can correlate.
- **Pass `requestId` to the client** in the response so support tickets can include it.

## Error Tracking via Sentry

Sentry is the default error tracker. Setup needs source maps for usable stack traces and release tagging for deploy correlation.

```ts
// sentry.client.config.ts
import * as Sentry from "@sentry/nextjs";
import { env } from "@/lib/env";

Sentry.init({
  dsn: env.NEXT_PUBLIC_SENTRY_DSN,
  environment: env.NODE_ENV,
  release: env.VERCEL_GIT_COMMIT_SHA ?? "dev",
  tracesSampleRate: env.NODE_ENV === "production" ? 0.1 : 1.0,
  replaysSessionSampleRate: 0.0,
  replaysOnErrorSampleRate: 1.0,
  integrations: [Sentry.replayIntegration({ maskAllText: true, blockAllMedia: true })],
});
```

```ts
// sentry.server.config.ts
import * as Sentry from "@sentry/nextjs";
import { env } from "@/lib/env";

Sentry.init({
  dsn: env.SENTRY_DSN,
  environment: env.NODE_ENV,
  release: env.VERCEL_GIT_COMMIT_SHA ?? "dev",
  tracesSampleRate: env.NODE_ENV === "production" ? 0.1 : 1.0,
  beforeSend(event) {
    // Strip request bodies, cookies, auth headers from breadcrumbs
    if (event.request?.cookies) delete event.request.cookies;
    if (event.request?.headers) {
      const { authorization, cookie, ...rest } = event.request.headers as Record<string, string>;
      event.request.headers = rest;
    }
    return event;
  },
});
```

```ts
// next.config.ts (excerpt — automated source map upload)
import { withSentryConfig } from "@sentry/nextjs";

export default withSentryConfig(config, {
  silent: true,
  org: env.SENTRY_ORG,
  project: env.SENTRY_PROJECT,
  authToken: process.env.SENTRY_AUTH_TOKEN,
  widenClientFileUpload: true,
  hideSourceMaps: true,
  disableLogger: true,
});
```

Rules:
- **Source maps uploaded on every production build.** Without source maps, stack traces show minified bundle paths — useless. The `@sentry/nextjs` plugin handles upload automatically when configured.
- **Release tagged with the commit SHA.** Sentry groups errors by release; tagging with `VERCEL_GIT_COMMIT_SHA` lets you see "this error appeared in deploy abc123."
- **`tracesSampleRate: 0.1`** in production for performance traces. 100% adds significant overhead and Sentry storage cost; 10% gives statistically useful data.
- **`beforeSend` redacts cookies and authorization headers.** Sentry captures request data; this filter prevents secrets and PII leaking into the error tracker.
- **Session replay opt-in** (`replaysOnErrorSampleRate: 1.0`) for error sessions only. `maskAllText: true` and `blockAllMedia: true` are non-negotiable for privacy.

### Manual capture for unexpected operational errors

When an action's "should never happen" branch fires (e.g., DB connection failure under normal traffic), capture explicitly:

```ts
import * as Sentry from "@sentry/nextjs";

if (!result.ok && result.error.kind === "connection-failed") {
  Sentry.captureException(result.error.cause, {
    tags: { feature: "invoicing", operation: "delete" },
    extra: { invoiceId: id },
  });
  return { ok: false, error: "internal" };
}
```

The action returns the typed envelope to the user; Sentry gets the underlying cause for the on-call engineer.

## `error.tsx` Placement Strategy

Per-route error boundaries near the failure source, not one global catch-all.

### Wrong: only a global error boundary

```tsx
// app/error.tsx
"use client";
export default function GlobalError({ reset }: { error: Error; reset: () => void }) {
  return <div>Something went wrong. <button onClick={reset}>Try again</button></div>;
}
```

A user's invoice list fails to load → the entire page shows "Something went wrong." No context. No useful recovery. The header, sidebar, navigation all gone.

### Right: per-route boundaries close to the failure

```tsx
// app/(app)/invoicing/error.tsx
"use client";
import { useEffect } from "react";
import * as Sentry from "@sentry/nextjs";

export default function InvoicingError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => {
    Sentry.captureException(error, { tags: { route: "invoicing" } });
  }, [error]);

  return (
    <div role="alert" className="p-4">
      <h2 className="text-lg font-semibold">Couldn't load invoices</h2>
      <p className="mt-2 text-sm text-muted">If this keeps happening, contact support and reference {error.digest ?? "—"}.</p>
      <button onClick={reset} className="mt-4">Try again</button>
    </div>
  );
}
```

The page chrome (sidebar, header, nav) survives. Only the invoicing section shows the error. The user's reference (`error.digest`) maps to the Sentry event.

Rules:
- **Place `error.tsx` at the boundary that makes sense for recovery.** A failed load of one feature doesn't kill the whole page; a failed load of a critical sub-component doesn't kill the surrounding feature.
- **`error.digest`** is the Next.js-generated correlation hash — show it to the user, log it server-side, support tickets can find the exact event.
- **Always include a recovery action.** "Try again" calling `reset`; or a link back to a known-good route.
- **Capture to Sentry inside the boundary**, not just from a global handler — boundary-specific tagging makes triage faster.
- **A global `app/error.tsx` is a final safety net**, not the primary boundary. Most routes should have closer boundaries.

## Server Action Error Envelopes

Server Actions return discriminated unions; the client renders the typed error. The action must not leak internal details:

```ts
// Wrong — leaks the Zod error internals
export async function createInvoice(formData: FormData, deps = liveDeps) {
  const parsed = CreateInvoiceSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) {
    return { ok: false, errors: parsed.error.format() }; // includes path, internal field types
  }
  // ...
}

// Right — typed user-safe envelope
type CreateInvoiceResult =
  | { ok: true; invoice: Invoice }
  | { ok: false; error: "validation" | "unauthorized" | "rate-limited" | "internal"; fields?: Record<string, string> };

export async function createInvoice(formData: FormData, deps = liveDeps): Promise<CreateInvoiceResult> {
  const session = await deps.session.read();
  if (!session) return { ok: false, error: "unauthorized" };

  const parsed = CreateInvoiceSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) {
    return { ok: false, error: "validation", fields: zodErrorToFieldMap(parsed.error) };
  }

  try {
    const invoice = makeInvoice(parsed.data, { now: deps.now() });
    const saved = await deps.invoiceRepository.save(invoice);
    if (!saved.ok) {
      deps.logger.error({ err: saved.error, userId: session.userId }, "Failed to save invoice");
      return { ok: false, error: "internal" };
    }
    deps.logger.info({ event: "invoice.created", invoiceId: invoice.id });
    return { ok: true, invoice };
  } catch (cause) {
    Sentry.captureException(cause, { tags: { action: "createInvoice" }, extra: { userId: session.userId } });
    return { ok: false, error: "internal" };
  }
}
```

```ts
// lib/zod-error-map.ts — translate Zod errors to user-safe messages
export function zodErrorToFieldMap(error: ZodError): Record<string, string> {
  const map: Record<string, string> = {};
  for (const issue of error.issues) {
    const path = issue.path.join(".");
    map[path] = USER_SAFE_MESSAGES[issue.code] ?? "Invalid value";
  }
  return map;
}
```

Rules:
- **Don't return the raw Zod error** — `error.format()` and `error.flatten()` include internal schema structure.
- **Map field-level errors via a lookup**, not by surfacing the raw Zod message. "Required" / "Invalid email" — a small set of user-facing strings.
- **Generic `"internal"` envelope on unexpected failures** — never expose stack traces, DB constraint names, or third-party error messages.
- **Log internal details server-side** with structured fields. The client gets a generic envelope; on-call sees the structured log + Sentry event.

## OpenTelemetry on Vercel

Distributed tracing makes "this request spent 850ms in DB and 200ms in Stripe" visible. Vercel has native OTel support; turn it on.

```ts
// instrumentation.ts (Next.js convention)
import { registerOTel } from "@vercel/otel";

export function register() {
  registerOTel({
    serviceName: "web",
    instrumentationConfig: {
      fetch: { propagateContextUrls: ["*"] },
    },
  });
}
```

```ts
// lib/tracing.ts — manual spans for non-fetch work
import { trace } from "@opentelemetry/api";

const tracer = trace.getTracer("web");

export function withSpan<T>(name: string, fn: () => Promise<T>): Promise<T> {
  return tracer.startActiveSpan(name, async (span) => {
    try {
      const result = await fn();
      span.setStatus({ code: 1 }); // OK
      return result;
    } catch (e) {
      span.recordException(e as Error);
      span.setStatus({ code: 2, message: String(e) }); // ERROR
      throw e;
    } finally {
      span.end();
    }
  });
}
```

```ts
// usage
import { withSpan } from "@/lib/tracing";

await withSpan("invoicing.calculateOverdueTotals", async () => {
  // ... expensive computation ...
});
```

Rules:
- **`registerOTel` in `instrumentation.ts`** instruments `fetch`, the Vercel runtime, and the Node runtime automatically. Most distributed-trace value comes from this alone.
- **Manual spans** for non-fetch work that's slow enough to matter — image processing, complex computations, batch DB operations. Skip for fast operations; spans have overhead.
- **Trace context propagates via fetch headers** automatically when `propagateContextUrls` is set. Upstream services can join their traces.
- **Sample at 10% in production** (config in Sentry/Vercel dashboard) — same as Sentry traces. 100% sampling is noisy and expensive.

## Redaction Policy

What must never enter logs, errors, or traces:

| Category | Examples | Rule |
|----------|----------|------|
| Authentication | Session tokens, API keys, OAuth tokens, passwords | Always redacted at logger level via `pino` `redact.paths` |
| PII | Email (sometimes), full names (sometimes), phone, address, SSN, payment info | Redacted unless the field is an explicit log target with a documented privacy review |
| Request bodies | Form data, JSON payloads | Never log full bodies; log specific extracted fields |
| Response bodies | Generated content, internal data | Never log unless explicitly safe |
| Internal IDs that map to PII | Customer IDs that index sensitive data | OK to log internally; never expose in errors shown to other users |

```ts
// lib/logger.ts — extends prior with broader redact paths
redact: {
  paths: [
    // Auth
    "*.password", "*.token", "*.authorization", "*.cookie",
    "*.secret", "*.apiKey", "*.refreshToken", "*.accessToken",
    "headers.cookie", "headers.authorization",
    // PII
    "*.email", "*.phone", "*.ssn", "*.taxId",
    "*.creditCard", "*.cvv", "*.bankAccount",
    "*.firstName", "*.lastName", "*.fullName",
    "*.address", "*.dateOfBirth",
    // Request bodies
    "req.body", "request.body", "body",
  ],
  censor: "[REDACTED]",
}
```

Rules:
- **Redact at the logger level**, not at the call site. Forgetting to redact is too easy; the logger is the choke point.
- **Sentry `beforeSend` mirrors the redaction.** Errors include request data — strip the same paths.
- **Email addresses are PII in most jurisdictions** (GDPR, CCPA). Default to redacted; opt in with explicit fields if a specific log truly needs it.
- **Internal IDs are safe**; the IDs they map to may not be. `userId: "u_123"` is fine to log; `email: "user@example.com"` is not.
- **Privacy review for new log targets.** Before adding a new field to logs (especially user-supplied content), review whether it's PII or could carry it.

## Anti-Patterns

1. **`console.log` in production code paths.** Lint-blocked. Use the structured logger.
2. **Throwing operational errors from Server Actions.** Validation failures, not-found, unauthorized — these return as typed envelopes, not throws. Throws are programmer errors.
3. **Global `app/error.tsx` as the only error boundary.** Per-route boundaries close to the failure preserve page chrome and provide useful recovery. Global is the final fallback.
4. **Leaking Zod errors to the client.** Map to user-safe messages via a lookup; never `error.format()` to the response.
5. **Logging full request bodies.** Bodies contain user input that may include PII or credentials. Log specific extracted fields.
6. **Production deploys without source maps.** Stack traces become useless. The `@sentry/nextjs` plugin uploads automatically — wire it.
7. **No release tagging.** Errors can't be correlated to specific deploys. `release: VERCEL_GIT_COMMIT_SHA`.
8. **`tracesSampleRate: 1.0` in production.** 100% sampling is overhead and storage cost. 10% gives the same statistical signal.
9. **Unmasked session replay.** `maskAllText: true` and `blockAllMedia: true` are not optional — replay can include payment forms, personal messages, sensitive data.
10. **Skipping `beforeSend` redaction in Sentry.** Request cookies and authorization headers leak into Sentry by default. Strip them.
11. **String-interpolated log messages.** `` `User ${id} did ${thing}` `` is opaque to aggregators. Structured fields: `{ userId, event: "did-thing" }`.
12. **No correlation ID.** Logs from a single request scatter across files; debugging takes hours instead of minutes. AsyncLocalStorage propagates the ID.
13. **Catching errors silently.** A `try { ... } catch {}` with no log, no rethrow, no Sentry capture. Bugs vanish; debugging is impossible. Always at minimum log; usually capture and rethrow.

## Principles

1. **Operational vs programmer errors are different shapes.** Operational return as typed envelopes. Programmer throw, get caught by error boundaries, report to Sentry. Mixing them is the canonical observability anti-pattern.

2. **Logs are structured, not strings.** JSON output, indexed fields, correlation IDs. The aggregator finds what you need; the human reads through `pino-pretty` in dev.

3. **Correlate everything.** Request IDs propagate from edge to logs to traces to Sentry to the user. A support ticket with a request ID resolves in minutes; without one, in hours.

4. **Per-route error boundaries.** A failure in one feature doesn't kill the whole page. Recovery is local. Page chrome survives.

5. **Source maps are non-optional.** A stack trace without source maps is hieroglyphics. The build step uploads them; the deploy tags the release.

6. **Redaction is at the choke point.** Loggers and Sentry filters strip secrets and PII universally. Per-call-site redaction misses one inevitably.

7. **Sample tracing in production.** 10% is enough for statistical significance. 100% is overhead and cost. Sentry and OTel both default to sane sampling when configured.
