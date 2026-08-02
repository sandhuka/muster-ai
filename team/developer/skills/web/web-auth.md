# Web Authentication & Authorization

## Purpose
Define authentication and authorization as a unified concern: every Server Action and Route Handler is an RPC endpoint and starts with explicit auth gating; Server Components read session through a cached `getSession()`; middleware does cheap pre-route redirects; authorization happens at the action and component boundary, not in middleware. See the `web-architecture` skill for the `deps` parameter pattern (auth integrates as a `deps.session` interface). See the `web-security` skill for everything not-auth (CSP, rate limiting, output encoding). See the `web-modern-react` skill for Server Actions. Target: **Next.js 15+, React 19+, Auth.js v5+**.

## The Mental Model

**Server Actions are RPC endpoints, not local functions.** A Server Action exported from a feature file is callable by anyone with the action's URL — including a logged-out attacker hitting it directly with `curl`. Treat every action and route handler as a public network surface and gate it explicitly.

```ts
// Wrong — looks like a local function call site, but it's a public endpoint
"use server";
export async function deleteInvoice(id: InvoiceId, deps = liveDeps) {
  await deps.invoiceRepository.delete(id); // any unauthenticated user can call this
}

// Right — auth gate is the first line, no exceptions
"use server";
export async function deleteInvoice(id: InvoiceId, deps = liveDeps) {
  const user = await requireUser(deps);
  await requireRole(user, "admin");
  await deps.invoiceRepository.delete(id);
}
```

This is the single most important auth discipline. Every Server Action's first executable line is `requireUser()` or an explicit public marker (`@public` JSDoc tag for actions intended to be reachable while logged out — sign-up, password reset). Reviewers reject any action that doesn't follow the rule.

## Session Reading (`getSession`)

In Server Components, read session via a cached helper that reads cookies once per request.

```ts
// lib/auth/session.ts
import { cache } from "react";
import { cookies } from "next/headers";
import { auth } from "./auth-config";
import type { Session } from "./types";

// React's `cache()` dedupes per request — getSession() called multiple
// times in the same render tree only does the work once.
export const getSession = cache(async (): Promise<Session | null> => {
  const cookieStore = await cookies();
  const token = cookieStore.get("session")?.value;
  if (!token) return null;
  return auth.verify(token);
});
```

```tsx
// app/(app)/dashboard/page.tsx (Server Component)
import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth/session";

export default async function DashboardPage() {
  const session = await getSession();
  if (!session) redirect("/login");
  return <Dashboard userId={session.userId} />;
}
```

Rules:
- **`cache()` from React, not from `next/cache`.** Per-request memoization. The whole render tree shares one session read.
- **Server Components call `getSession()` directly** — they're server-side, the seam is unnecessary here.
- **Server Actions and Route Handlers go through `deps.session`** — the seam matters there because actions get tested with substituted deps.

## The `Deps` Integration

Auth integrates with the dependency-injection pattern from `web-architecture.md` so actions stay testable.

```ts
// lib/auth/types.ts
export interface Session {
  userId: UserId;
  roles: ReadonlyArray<Role>;
  expiresAt: Date;
}

export interface SessionService {
  read(): Promise<Session | null>;
}

// lib/auth/live-session.ts
import { getSession } from "./session";
import type { SessionService } from "./types";

export const liveSessionService: SessionService = {
  read: getSession,
};

// lib/deps.ts (extends what's in web-architecture.md)
import { liveSessionService } from "./auth/live-session";
import type { SessionService } from "./auth/types";

export interface Deps {
  // ...existing entries...
  session: SessionService;
}

export const liveDeps: Deps = {
  // ...existing...
  session: liveSessionService,
};
```

```ts
// lib/auth/require.ts
import type { Session, SessionService } from "./types";

export class UnauthorizedError extends Error {
  constructor() { super("Unauthorized"); this.name = "UnauthorizedError"; }
}

export class ForbiddenError extends Error {
  constructor(public readonly missingRole?: string) {
    super(`Forbidden${missingRole ? `: requires ${missingRole}` : ""}`);
    this.name = "ForbiddenError";
  }
}

export async function requireUser(deps: { session: SessionService }): Promise<Session> {
  const session = await deps.session.read();
  if (!session || session.expiresAt < new Date()) throw new UnauthorizedError();
  return session;
}

export async function requireRole(session: Session, role: Role): Promise<void> {
  if (!session.roles.includes(role)) throw new ForbiddenError(role);
}
```

`requireUser()` and `requireRole()` throw — these are programmer-facing in the sense that a missing auth gate is a contract violation, not a user-facing error to surface. Server Actions catch the `UnauthorizedError`/`ForbiddenError` and return a typed envelope to the client (see "Server Action error envelope" below).

## Authentication Setup (Auth.js v5)

Auth.js v5 (NextAuth's rewrite) is the default. It handles OAuth providers, credentials flows, JWT or database sessions, and session cookies.

```ts
// lib/auth/auth-config.ts
import NextAuth from "next-auth";
import GitHub from "next-auth/providers/github";
import { DrizzleAdapter } from "@auth/drizzle-adapter";
import { db } from "@/lib/db";

export const { handlers, signIn, signOut, auth } = NextAuth({
  adapter: DrizzleAdapter(db),
  providers: [GitHub({ clientId: env.GITHUB_ID, clientSecret: env.GITHUB_SECRET })],
  session: { strategy: "database" }, // or "jwt" for stateless
  callbacks: {
    session: ({ session, user }) => ({
      ...session,
      userId: user.id,
      roles: user.roles ?? [],
    }),
  },
});
```

```ts
// app/api/auth/[...nextauth]/route.ts
import { handlers } from "@/lib/auth/auth-config";
export const { GET, POST } = handlers;
```

Defaults:
- **Database session strategy** for new projects unless statelessness is genuinely required. Database sessions support remote sign-out; JWT sessions don't until they expire.
- **JWT strategy** only when there's no database, edge-runtime constraints prevent DB calls, or session count is enormous.
- **OAuth providers** (GitHub, Google, Apple Sign-in) before credentials. Credentials flow needs hashing, password reset, email verification — all of which Auth.js handles, but OAuth is one fewer attack surface.
- **`AUTH_SECRET`** in env, validated by Zod (per `web-best-practices.md`). 32+ characters, rotated quarterly.

## Custom Session-Cookie Alternative

When Auth.js doesn't fit (extreme bundle constraints, custom protocol, mobile API sharing), the framework's documented alternative is a hand-rolled session cookie:

```ts
// lib/auth/cookie.ts
import { SignJWT, jwtVerify } from "jose";
import { cookies } from "next/headers";
import { z } from "zod";

const SessionPayload = z.object({
  userId: z.string().brand<"UserId">(),
  roles: z.array(z.string()),
  exp: z.number(),
});

const SECRET = new TextEncoder().encode(env.AUTH_SECRET);

export async function setSessionCookie(payload: { userId: UserId; roles: Role[] }) {
  const token = await new SignJWT({ ...payload })
    .setProtectedHeader({ alg: "HS256" })
    .setExpirationTime("7d")
    .sign(SECRET);

  (await cookies()).set("session", token, {
    httpOnly: true,        // not readable by JS
    secure: true,          // HTTPS only
    sameSite: "lax",       // CSRF protection (with Server Actions)
    path: "/",
    maxAge: 7 * 24 * 60 * 60,
  });
}

export async function readSessionCookie(): Promise<Session | null> {
  const token = (await cookies()).get("session")?.value;
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, SECRET);
    const parsed = SessionPayload.safeParse(payload);
    if (!parsed.success) return null;
    return {
      userId: parsed.data.userId as UserId,
      roles: parsed.data.roles as Role[],
      expiresAt: new Date(parsed.data.exp * 1000),
    };
  } catch {
    return null;
  }
}
```

Cookie attributes that matter:
- **`httpOnly`** — JS can't read; XSS can't exfiltrate session.
- **`secure`** — HTTPS only.
- **`sameSite: "lax"`** — sent on same-site navigation, blocked on cross-site POST. Foundational CSRF protection.
- **No `domain` attribute by default** — scope to current host; broader scoping is a security regression.

## Middleware: Pre-Route Redirects

Middleware does cheap auth checks for redirect-on-unauthenticated routes. Not real authorization — just "is there a session at all."

```ts
// middleware.ts
import { NextResponse, type NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const session = request.cookies.get("session");
  const pathname = request.nextUrl.pathname;

  // Public paths
  if (pathname.startsWith("/login") || pathname.startsWith("/sign-up")) {
    if (session) return NextResponse.redirect(new URL("/dashboard", request.url));
    return NextResponse.next();
  }

  // Protected paths
  if (!session) {
    return NextResponse.redirect(new URL("/login", request.url));
  }
  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};
```

Rules:
- **Middleware checks cookie presence, not validity.** Validating signatures requires reading `AUTH_SECRET` and doing crypto — duplicating work that pages and actions will do anyway. The cheap "is there a cookie at all" check filters obvious unauthenticated requests; pages and actions verify the signature.
- **Don't put authorization logic in middleware.** Role checks, permission lookups, ownership tests all happen at the action or component layer where the actual business decision lives.
- **No DB calls in middleware.** Edge runtime, runs on every matched request, latency-critical.

## Authorization at the Action and Component Boundary

The real authorization decision — "is this user allowed to do this thing?" — happens where the action runs.

### In Server Actions

```ts
"use server";
import { requireUser, requireRole, ForbiddenError } from "@/lib/auth/require";
import { liveDeps, type Deps } from "@/lib/deps";

type DeleteResult =
  | { ok: true }
  | { ok: false; error: "unauthorized" | "forbidden" | "not-found" };

export async function deleteInvoice(
  invoiceId: InvoiceId,
  deps: Pick<Deps, "session" | "invoiceRepository"> = liveDeps,
): Promise<DeleteResult> {
  const session = await deps.session.read();
  if (!session) return { ok: false, error: "unauthorized" };

  const invoice = await deps.invoiceRepository.findById(invoiceId);
  if (!invoice) return { ok: false, error: "not-found" };

  // Ownership check + role check
  const allowed = invoice.ownerId === session.userId || session.roles.includes("admin");
  if (!allowed) return { ok: false, error: "forbidden" };

  await deps.invoiceRepository.delete(invoiceId);
  return { ok: true };
}
```

Rules:
- **Auth gate is the first thing the action does**, before any other read or write.
- **Return typed errors** in the action's discriminated union. Don't throw to the client — surface errors as actionable.
- **Ownership checks belong here**, not in middleware. The action sees the actual entity and the actual user — that's where ownership is decidable.
- **Don't throw `UnauthorizedError`/`ForbiddenError` across the client boundary.** Map them to envelope errors at the action's edge:

```ts
export async function deleteInvoice(/* ... */): Promise<DeleteResult> {
  try {
    const session = await requireUser(deps);
    // ...
    return { ok: true };
  } catch (e) {
    if (e instanceof UnauthorizedError) return { ok: false, error: "unauthorized" };
    if (e instanceof ForbiddenError) return { ok: false, error: "forbidden" };
    throw e; // unexpected — programmer error, let error.tsx catch
  }
}
```

### In Route Handlers

Same discipline, with HTTP response envelopes:

```ts
// app/api/webhooks/stripe/route.ts
export async function POST(request: Request) {
  const session = await getSession();
  if (!session) return new Response("Unauthorized", { status: 401 });
  if (!session.roles.includes("admin")) return new Response("Forbidden", { status: 403 });
  // ...
}
```

Webhooks usually don't have a session — they verify a signature instead (see `web-security.md`). The auth check above applies to public REST surfaces shared with non-browser clients.

### In Server Components

```tsx
// app/(app)/admin/users/page.tsx
import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth/session";
import { forbidden } from "next/navigation"; // Next.js 15+

export default async function AdminUsersPage() {
  const session = await getSession();
  if (!session) redirect("/login");
  if (!session.roles.includes("admin")) forbidden();
  return <UserList />;
}
```

`forbidden()` (Next.js 15+) renders the nearest `forbidden.tsx`; `notFound()` for missing entities; `redirect()` for "go elsewhere." Each maps to a distinct user-facing meaning.

## RBAC in the Domain

Permission rules are business logic — they live in domain, not scattered across actions.

```ts
// features/invoicing/permissions.ts
import type { Invoice } from "./domain";
import type { Session } from "@/lib/auth/types";

export function canDeleteInvoice(session: Session, invoice: Invoice): boolean {
  return invoice.ownerId === session.userId || session.roles.includes("admin");
}

export function canEditInvoice(session: Session, invoice: Invoice): boolean {
  if (invoice.status === "paid") return false; // immutable once paid
  return invoice.ownerId === session.userId || session.roles.includes("admin");
}
```

```ts
// features/invoicing/actions.ts
import { canDeleteInvoice } from "./permissions";

export async function deleteInvoice(/* ... */): Promise<DeleteResult> {
  const session = await requireUser(deps);
  const invoice = await deps.invoiceRepository.findById(invoiceId);
  if (!invoice) return { ok: false, error: "not-found" };
  if (!canDeleteInvoice(session, invoice)) return { ok: false, error: "forbidden" };
  // ...
}
```

Rules:
- **Permissions are pure functions** — `(session, entity) => boolean` or `(session, entity) => Result<void, Reason>`.
- **They live next to the domain** they protect. `features/invoicing/permissions.ts` not `lib/permissions.ts`.
- **They're testable as pure functions** — `expect(canDeleteInvoice(adminSession, paidInvoice)).toBe(true)` runs without any setup.
- **Components consume them too** — `if (canEditInvoice(session, invoice)) <EditButton />` — UI hides what users can't do, which is UX, not security. The action still re-checks (defense in depth).

## CSRF and Same-Origin Protection

Next.js 15 builds in same-origin verification for Server Actions: a Server Action invocation rejected if the `Origin` header doesn't match the host. This handles the bulk of CSRF for action-based mutations.

What's still your responsibility:
- **Route Handlers**: verify origin or use signed payloads (webhooks → signature verification, not origin).
- **Cross-origin embedding**: if your app is iframed elsewhere, configure framer policies (CSP `frame-ancestors`) — see `web-security.md`.
- **State-changing GET endpoints**: don't have any. State changes are POST/PUT/DELETE/PATCH.

```ts
// app/api/admin/wipe/route.ts
export async function POST(request: Request) {
  const origin = request.headers.get("origin");
  const host = request.headers.get("host");
  if (origin !== `https://${host}`) {
    return new Response("Forbidden", { status: 403 });
  }
  // ...
}
```

## Testing Auth

The `deps.session` seam makes auth-gated actions testable without HTTP cookies, real JWTs, or browser interactions.

```ts
// features/invoicing/actions.test.ts
import { describe, it, expect, vi } from "vitest";
import { deleteInvoice } from "./actions";
import type { Deps } from "@/lib/deps";
import type { Session } from "@/lib/auth/types";
import { makeInvoice } from "./test-builders";

function makeAuthDeps(session: Session | null) {
  const findById = vi.fn();
  const remove = vi.fn().mockResolvedValue(undefined);
  return {
    deps: {
      session: { read: vi.fn().mockResolvedValue(session) },
      invoiceRepository: { findById, save: vi.fn(), list: vi.fn(), delete: remove },
    } satisfies Pick<Deps, "session" | "invoiceRepository">,
    findById,
    remove,
  };
}

describe("deleteInvoice", () => {
  it("returns unauthorized when no session", async () => {
    const { deps, remove } = makeAuthDeps(null);
    const result = await deleteInvoice("inv_1" as InvoiceId, deps);
    expect(result).toEqual({ ok: false, error: "unauthorized" });
    expect(remove).not.toHaveBeenCalled();
  });

  it("returns forbidden when session user doesn't own invoice and isn't admin", async () => {
    const session: Session = { userId: "u_1" as UserId, roles: ["user"], expiresAt: new Date("2030-01-01") };
    const invoice = makeInvoice({ ownerId: "u_2" as UserId });
    const { deps } = makeAuthDeps(session);
    deps.invoiceRepository.findById = vi.fn().mockResolvedValue(invoice);
    const result = await deleteInvoice(invoice.id, deps);
    expect(result).toEqual({ ok: false, error: "forbidden" });
  });

  it("succeeds when session user owns the invoice", async () => {
    const session: Session = { userId: "u_1" as UserId, roles: ["user"], expiresAt: new Date("2030-01-01") };
    const invoice = makeInvoice({ ownerId: "u_1" as UserId });
    const { deps, remove } = makeAuthDeps(session);
    deps.invoiceRepository.findById = vi.fn().mockResolvedValue(invoice);
    const result = await deleteInvoice(invoice.id, deps);
    expect(result).toEqual({ ok: true });
    expect(remove).toHaveBeenCalledWith(invoice.id);
  });
});
```

Three branches per gated action: unauthorized, forbidden, ok. `unauthorized` requires no DB setup; `forbidden` requires the entity but not write; `ok` requires both.

## Anti-Patterns

1. **Server Action without an auth gate.** Every action's first executable line is `requireUser()` (or an explicit `@public` JSDoc tag with a code-review-approved reason). No exceptions.
2. **Authorization in middleware.** Middleware runs without DB access; it can't make ownership or permission decisions correctly. Authentication-presence in middleware is fine; authorization isn't.
3. **Throwing `UnauthorizedError` to the client.** Map to typed envelope errors at the action's edge. Throws across the client boundary become `error.tsx` red walls — wrong UX for "log in again."
4. **Reading session inside domain code.** Domain functions are pure. Session is an input passed by the action — domain doesn't reach for it.
5. **Skipping the ownership check because role-based gating "should be enough."** Roles answer "is this user allowed to do this kind of thing"; ownership answers "is this user allowed to do this thing to this thing." Most apps need both.
6. **`localStorage` for session tokens.** XSS exfiltrates them. `httpOnly` cookies only.
7. **Long-lived JWTs without remote sign-out.** A 30-day JWT can't be invalidated server-side. Use database sessions or short-lived JWTs with a refresh-token rotation (Auth.js handles this).
8. **Permission checks duplicated between component and action without a shared function.** Drift across the two surfaces silently grants or denies. Extract to `permissions.ts` and call from both.
9. **`session.role === "admin"` instead of `session.roles.includes("admin")`.** Roles are an array; users can have multiple. Modeling as a single field is a permission system that won't scale past launch.
10. **Auth-gating the wrong thing.** Gating page rendering but not the underlying Server Action lets attackers call the action directly. Gate the surface that performs the side effect, not just the UI that triggers it.
11. **Trusting a header (`X-User-Id`) from the client.** The session is the authority; headers from the browser are not. (Service-to-service contexts with signed JWTs are the exception.)
12. **No expiration on sessions.** Sessions expire — `expiresAt` is checked on every read. "Remember me" is a renewal mechanism, not an exemption.

## Principles

1. **Server Actions are RPC endpoints.** Treat every action as a public network surface. The first executable line is the auth gate.

2. **Authentication is presence; authorization is the decision.** Middleware checks presence cheaply. The action checks the actual permission against the actual entity. Never confuse the two.

3. **Permissions are pure functions in domain.** `(session, entity) => boolean`. Testable without setup, callable from components and actions consistently.

4. **The `deps.session` seam mirrors `deps.invoiceRepository`.** Auth is just another infrastructure dependency, injected the same way DB and time are. Tests substitute fake sessions; production uses the live reader.

5. **Defense in depth: gate the action, hide the UI.** UI hides what users can't do (good UX). The action re-checks (real security). Either alone is incomplete.

6. **Sessions expire, secrets rotate.** No `expiresAt: never`. `AUTH_SECRET` rotated quarterly. Long-lived stateless JWTs are a liability without a revocation mechanism.

7. **Database sessions by default, JWT only when justified.** Database sessions support remote sign-out, "log out all devices," and revocation. JWTs trade those for stateless verification — make the trade deliberately, not by default.
