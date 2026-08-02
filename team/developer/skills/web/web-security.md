# Web Security (Everything Not-Auth)

## Purpose
Define security disciplines beyond authentication: security headers and CSP with per-request nonces, input validation as fail-closed defaults, output encoding rules, secrets management, rate limiting, file-upload hardening, webhook signature verification, dependency supply-chain security. See the `web-auth` skill for authentication and authorization (the gate at the top of every action). See the `web-architecture` skill for the `deps` pattern (rate limiter and object-store services follow it). See the `web-nextjs-app-router` skill for middleware integration. See the `web-best-practices` skill for the env-validation foundation. Target: **Next.js 15+, Node.js 20+**.

## Security Headers & CSP

A modern web app ships with a hardened header set. Default headers via `next.config.ts`; CSP — which needs per-request nonces for inline scripts — via middleware.

### Static headers in `next.config.ts`

```ts
// next.config.ts
import type { NextConfig } from "next";

const securityHeaders = [
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },                  // legacy browsers; CSP frame-ancestors is canonical
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=(), interest-cohort=()" },
  { key: "Cross-Origin-Opener-Policy", value: "same-origin" },
  { key: "Cross-Origin-Resource-Policy", value: "same-origin" },
];

const config: NextConfig = {
  async headers() {
    return [{ source: "/(.*)", headers: securityHeaders }];
  },
};

export default config;
```

Notes:
- **`Strict-Transport-Security`** with `preload` — submit your domain to the HSTS preload list once HTTPS is permanent.
- **`Permissions-Policy`** opts out of every powerful API by default; opt back in only what the app actually uses.
- **`Cross-Origin-*-Policy`** prevents Spectre-class side-channel attacks via cross-origin embedding.

### CSP with per-request nonces (via middleware)

Inline scripts and styles need either `unsafe-inline` (defeats the point of CSP) or per-request nonces (correct). Generate the nonce in middleware, attach it to the request, and inject it into script and style tags.

```ts
// middleware.ts
import { NextResponse, type NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");

  const csp = [
    `default-src 'self'`,
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    `style-src 'self' 'nonce-${nonce}'`,
    `img-src 'self' blob: data: https:`,
    `font-src 'self'`,
    `connect-src 'self' ${process.env.NEXT_PUBLIC_API_URL ?? ""}`,
    `frame-ancestors 'none'`,
    `form-action 'self'`,
    `base-uri 'self'`,
    `object-src 'none'`,
    `upgrade-insecure-requests`,
  ].join("; ");

  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
  requestHeaders.set("Content-Security-Policy", csp);

  const response = NextResponse.next({ request: { headers: requestHeaders } });
  response.headers.set("Content-Security-Policy", csp);
  return response;
}

export const config = {
  matcher: [{ source: "/((?!api|_next/static|_next/image|favicon.ico).*)", missing: [{ type: "header", key: "next-router-prefetch" }] }],
};
```

```tsx
// app/layout.tsx
import { headers } from "next/headers";

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const nonce = (await headers()).get("x-nonce") ?? "";
  return (
    <html lang="en">
      <head>
        <Script nonce={nonce} src="/analytics.js" strategy="afterInteractive" />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

CSP rules:
- **`'unsafe-inline'` is forbidden** in `script-src` and `style-src`. The whole point of CSP is to prevent inline injection — `'unsafe-inline'` allows it.
- **`'unsafe-eval'` is forbidden** unless a runtime dependency provably requires it (rare in modern Next.js).
- **`'strict-dynamic'`** lets nonced scripts load other scripts they trust — required for Next.js client bundles.
- **`frame-ancestors 'none'`** — never embeddable. Override per-deployment if intentional embedding is needed (admin panels in iframes, embeddable widgets).
- **`upgrade-insecure-requests`** — every `http:` request becomes `https:`.
- **Test in report-only mode first**: `Content-Security-Policy-Report-Only` with a `report-uri` to a logging endpoint. Tighten until reports stop, then switch to enforcing.

## Input Validation: Fail-Closed Defaults

The discipline established in `web-architecture.md` and `web-typescript-conventions.md` — Zod at every external boundary — has a security corollary: **validation failures default-deny**. The contract is "we either understand the input or we reject it," never "we kind of recognize it, so we'll guess."

```ts
// Wrong — fail-open: validation errors ignored, default applied
const filter = FilterSchema.safeParse(searchParams);
const status = filter.success ? filter.data.status : "all"; // attacker forces "all"

// Right — fail-closed: validation errors abort the request
const filter = FilterSchema.safeParse(searchParams);
if (!filter.success) {
  notFound(); // or return { ok: false, error: "invalid-input" }
}
```

Rules:
- **Validate every external input** with a Zod schema: `searchParams`, `params`, `formData`, request bodies, third-party API responses, DB rows when types are loose.
- **Validation failure is not user-correctable in security-sensitive paths**. A user typing a wrong value gets a UX error; an attacker probing with a malformed payload gets a 400 or 404.
- **`safeParse` everywhere external**, `parse` only for internal invariants where a failure is a programmer error.
- **Trust the inside, distrust the edge**. Once data crosses through a schema, the rest of the function trusts it — that's the whole point of the boundary.

## Output Encoding

Output encoding matters wherever user-controlled data enters HTML, URLs, or attribute values.

### `dangerouslySetInnerHTML` policy

The default is **forbidden**. The exceptions:

- Server-rendered Markdown that's been sanitized via `rehype-sanitize` or `DOMPurify` (server-side build).
- Trusted internal content (e.g., generated SVG sprites from a build step).

```tsx
// Wrong — rendering user-supplied HTML
<div dangerouslySetInnerHTML={{ __html: userPost.body }} />

// Right — sanitize first, fixed allowlist
import { sanitize } from "@/lib/sanitize-html";
<div dangerouslySetInnerHTML={{ __html: sanitize(userPost.body) }} />
```

```ts
// lib/sanitize-html.ts
import DOMPurify from "isomorphic-dompurify";

const ALLOWED_TAGS = ["p", "br", "strong", "em", "a", "ul", "ol", "li", "blockquote", "code", "pre"];
const ALLOWED_ATTR = ["href", "target", "rel"];

export function sanitize(html: string): string {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS,
    ALLOWED_ATTR,
    ALLOW_DATA_ATTR: false,
    FORBID_ATTR: ["style", "onclick", "onerror", "onload"],
  });
}
```

### URL sanitization for user-controlled `href` / `src`

User-supplied URLs in anchor tags, image sources, or video sources can carry `javascript:` or `data:` schemes. Validate the scheme.

```ts
// lib/safe-url.ts
const SAFE_SCHEMES = new Set(["http:", "https:", "mailto:"]);

export function safeHref(input: string): string | null {
  try {
    const url = new URL(input, "https://placeholder.invalid"); // resolve relative
    if (input.startsWith("/")) return input; // relative path is fine
    if (SAFE_SCHEMES.has(url.protocol)) return url.href;
    return null;
  } catch {
    return null;
  }
}
```

```tsx
const href = safeHref(userLink);
{href && <a href={href} rel="noopener noreferrer">Link</a>}
```

`rel="noopener noreferrer"` on every external link — prevents the target page from accessing `window.opener`.

### SSRF guards on server-side `fetch`

A Server Action that fetches a URL the user supplies (avatar imports, link previews, webhook tests) is an SSRF surface. The attacker supplies `http://169.254.169.254/latest/meta-data/` (AWS metadata service) or `http://localhost:6379` (internal Redis).

```ts
// lib/safe-fetch.ts
import { lookup } from "node:dns/promises";
import { isIP } from "node:net";

const PRIVATE_RANGES = [
  /^10\./, /^127\./, /^169\.254\./,
  /^172\.(1[6-9]|2\d|3[01])\./, /^192\.168\./, /^::1$/, /^fc00:/, /^fe80:/,
];

export async function safeFetch(input: string, init?: RequestInit): Promise<Response> {
  const url = new URL(input);
  if (!["http:", "https:"].includes(url.protocol)) {
    throw new Error("disallowed-scheme");
  }
  const host = url.hostname;
  const ip = isIP(host) ? host : (await lookup(host)).address;
  if (PRIVATE_RANGES.some((r) => r.test(ip))) {
    throw new Error("disallowed-host");
  }
  return fetch(input, { ...init, redirect: "manual" }); // manual to re-check on redirect
}
```

Rules:
- **Allowlist hostnames** when possible. Any user-supplied URL feature should declare an allowlist (e.g., "images from `*.cloudinary.com` only"). Block-list approaches fail; allow-list approaches scale.
- **Never follow redirects automatically** when the original URL was user-supplied — the redirect target wasn't validated.
- **Don't expose response details** when the fetch fails. "Couldn't reach that URL" is enough; don't leak that the host resolved to `127.0.0.1`.

## Secrets Discipline

Builds on `web-best-practices.md`'s env-validation foundation.

Rules:
- **`NEXT_PUBLIC_*` is the only public prefix.** Anything else is server-only. Never tempted to make a secret "just slightly public" by prefixing with `NEXT_PUBLIC_`.
- **Vercel env scoping**: separate Production, Preview, and Development scopes. Production secrets never appear in preview deploys; preview secrets never appear in dev. Set per-scope in the Vercel dashboard.
- **No secrets in `.env.production` or any committed `.env.*` file.** Committed `.env` files contain non-secret config (URLs, public flags). Secrets live in the deployment platform's secret manager.
- **Rotate quarterly** at minimum. Critical secrets (`AUTH_SECRET`, payment processor keys) on incident or quarterly, whichever comes first. Document the rotation procedure in a runbook.
- **Validate secret shape at boot**, per `web-best-practices.md`. `STRIPE_SECRET_KEY` starts with `sk_`; `AUTH_SECRET` is 32+ characters. Misshapen secrets fail boot loudly, never silently fall through to dev defaults.
- **Never log secrets**, even at startup. The logger redacts known secret keys (`AUTH_SECRET`, `STRIPE_SECRET_KEY`, `*_TOKEN`, `*_KEY`) — see `web-observability.md` for the redaction policy.
- **Use short-lived tokens where possible.** OAuth tokens, signed URLs, scoped credentials beat long-lived keys.

## Rate Limiting

Server Actions and Route Handlers are RPC endpoints — they need rate limits. Without them, a single attacker burns through all your DB connections, all your Stripe quota, all your function-execution budget.

Anchor on Upstash (Redis-as-a-service, edge-compatible) via `@upstash/ratelimit`. Integrate via the `deps` pattern.

```ts
// lib/rate-limit.ts
import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

const redis = Redis.fromEnv();

export interface RateLimiter {
  check(key: string, options?: { limit?: number; window?: string }): Promise<{ success: boolean; reset: number }>;
}

export const liveRateLimiter: RateLimiter = {
  async check(key, { limit = 10, window = "10 s" } = {}) {
    const limiter = new Ratelimit({
      redis,
      limiter: Ratelimit.slidingWindow(limit, window as "10 s"),
      analytics: true,
      prefix: "rl",
    });
    const result = await limiter.limit(key);
    return { success: result.success, reset: result.reset };
  },
};
```

```ts
// lib/deps.ts (extends prior)
export interface Deps {
  // ...
  rateLimiter: RateLimiter;
}
```

```ts
// features/billing/actions.ts
"use server";
import { headers } from "next/headers";

export async function startCheckout(/* ... */): Promise<CheckoutResult> {
  const session = await requireUser(deps);
  const ip = (await headers()).get("x-forwarded-for") ?? "unknown";
  const key = `checkout:${session.userId}:${ip}`;

  const { success, reset } = await deps.rateLimiter.check(key, { limit: 5, window: "1 m" });
  if (!success) return { ok: false, error: "rate-limited", retryAt: reset };

  // ...proceed with checkout...
}
```

Rules:
- **Compose keys from user ID + IP**, not either alone. User-only lets attackers bypass by signing up many accounts; IP-only punishes shared NATs.
- **Tighter limits on costly or sensitive actions**: 5/min for checkout or password reset; 60/min for general reads.
- **Return `retryAt` to the client** so UIs can render "try again in 23s" instead of a generic error.
- **Public endpoints (no session) get IP-only rate limiting** — sign-up, password reset, webhook test endpoints.
- **Test rate-limited paths** by substituting a `RateLimiter` fake in `deps`. The architecture's DI seam works the same for rate limits as for DB.

## File-Upload Hardening

The naïve pattern — POST file bytes to a Server Action, action saves to disk or forwards to S3 — is wrong on multiple axes:

- **Function execution time**: large uploads exceed function timeout (10s on Vercel hobby, 60s on pro).
- **Function size**: serverless functions have payload size limits (4.5MB on Vercel by default).
- **Cold starts**: every byte transferred costs cold-start time.
- **Memory**: holding the whole file in memory triggers OOM on larger uploads.

The right pattern: **client uploads directly to object storage via signed URL**. The Server Action's job is to authorize and issue the signed URL, not to handle bytes.

```ts
// lib/object-store.ts
import { put, type PutBlobResult } from "@vercel/blob";

export interface ObjectStore {
  signUploadUrl(key: string, options: { contentType: string; maxSize: number }): Promise<{ url: string; key: string }>;
}

// Live impl uses Vercel Blob, AWS S3 (with @aws-sdk/s3-request-presigner), or Cloudflare R2.
```

```ts
// features/uploads/actions.ts
"use server";
import { z } from "zod";

const RequestUploadSchema = z.object({
  filename: z.string().min(1).max(255).regex(/^[\w.\-]+$/),
  contentType: z.enum(["image/jpeg", "image/png", "image/webp"]),
  sizeBytes: z.number().int().positive().max(10 * 1024 * 1024), // 10MB cap
});

export async function requestUploadUrl(
  input: unknown,
  deps = liveDeps,
): Promise<RequestUploadResult> {
  const session = await requireUser(deps);
  const parsed = RequestUploadSchema.safeParse(input);
  if (!parsed.success) return { ok: false, error: "invalid-input" };

  const { success } = await deps.rateLimiter.check(`upload:${session.userId}`, { limit: 20, window: "1 m" });
  if (!success) return { ok: false, error: "rate-limited" };

  const key = `uploads/${session.userId}/${randomId()}-${parsed.data.filename}`;
  const { url } = await deps.objectStore.signUploadUrl(key, {
    contentType: parsed.data.contentType,
    maxSize: parsed.data.sizeBytes,
  });
  return { ok: true, uploadUrl: url, key };
}
```

The client `PUT`s the file to `uploadUrl` directly. The bytes never touch your function.

Rules:
- **Allowlist content types and extensions.** Server-validate against the allowlist; don't trust the client's `Content-Type` header alone (signed URLs let object stores enforce it server-side).
- **Cap file size in the schema AND in the signed URL.** Defense in depth; the client could ignore the schema cap.
- **MIME-sniff post-upload** before serving. A file claiming `image/png` might actually be a polyglot; confirm via magic bytes (file-type library) before treating as an image.
- **Strip metadata from images** when privacy matters (EXIF can include GPS, device info).
- **Serve uploaded files via the object store's CDN with signed read URLs** — never proxy through your function.
- **Scan for malware** on user-uploaded executables (rare in web apps, real for some products) via ClamAV or a managed service before exposing.

## Webhook Signature Verification

Webhooks (Stripe, GitHub, Vercel, Auth0 callbacks, etc.) are unauthenticated by default — anyone can hit your `/api/webhooks/stripe` endpoint. The protection is a signed payload: the sender hashes the body with a shared secret; you verify the hash before any side effect.

```ts
// app/api/webhooks/stripe/route.ts
import Stripe from "stripe";
import { handleStripeEvent } from "@/features/billing/webhook";
import { liveDeps } from "@/lib/deps";

const stripe = new Stripe(env.STRIPE_SECRET_KEY);

export async function POST(request: Request) {
  const signature = request.headers.get("stripe-signature");
  if (!signature) return new Response("Missing signature", { status: 400 });

  const body = await request.text(); // raw body for signature verification
  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, signature, env.STRIPE_WEBHOOK_SECRET);
  } catch {
    return new Response("Invalid signature", { status: 400 });
  }

  const result = await handleStripeEvent(event, liveDeps);
  return result.ok
    ? new Response(null, { status: 204 })
    : new Response(null, { status: 500 }); // Stripe will retry on 5xx
}
```

Rules:
- **Verify before any read or write.** A failing signature check exits before anything else runs.
- **Use the raw body**, not parsed JSON — most signature schemes hash the bytes as sent. `request.text()` then verify, then parse if needed.
- **Idempotency keys**: webhooks retry. The handler stores a record of processed event IDs and short-circuits duplicates. (`event.id` for Stripe, `delivery-id` for GitHub.)
- **Generic 200/204 on success, 4xx on signature failure, 5xx on internal failure** — the sender retries 5xx, doesn't retry 4xx.
- **Don't return error details** in the response body. The webhook sender doesn't need them; an attacker probing might.
- **Test webhooks locally** with the sender's CLI (`stripe listen`, `gh webhook forward`) — never disable signature verification "for dev." Dev is where sloppy patterns become production.

## Dependency Supply-Chain Security

Most modern attacks are supply-chain, not direct application exploits. The discipline:

- **Renovate** (or Dependabot) configured to open PRs for dependency updates. Auto-merge patch-version updates after CI passes; manual review for minors and majors.
- **`pnpm-lock.yaml` committed**. Locked versions across all installs. PRs that change the lockfile without changing `package.json` are suspicious — investigate.
- **`pnpm audit` in CI**. Fails the build on critical or high vulnerabilities. Acceptable to suppress with `pnpm audit --audit-level=critical` if low/medium noise is overwhelming, but high-and-above always block.
- **GitHub Secret Scanning + push protection enabled** on the repo. Stops accidental commits of API keys.
- **GitHub Dependabot Alerts** for vulnerabilities in dependencies — separate signal from `pnpm audit`, complements it.
- **Vet before adopting new dependencies**: maintainer activity, download stats, license, security history. A new dependency is a permanent blast-radius increase.
- **Pin versions exactly** in `package.json` for security-critical deps (auth, crypto, payment libs). `^1.2.3` permits silent updates; `1.2.3` doesn't.
- **Avoid postinstall scripts.** `pnpm config set ignore-scripts true` and explicitly enable scripts for trusted packages — postinstall is a common supply-chain attack vector.

```json
// renovate.json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended", ":dependencyDashboard"],
  "lockFileMaintenance": { "enabled": true, "schedule": ["before 4am on monday"] },
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "automerge": true,
      "automergeType": "branch"
    },
    {
      "matchPackagePatterns": ["^@auth/", "^next-auth", "stripe", "jose"],
      "groupName": "security-critical",
      "automerge": false,
      "schedule": ["at any time"]
    }
  ]
}
```

## Anti-Patterns

1. **`'unsafe-inline'` in CSP.** Defeats the entire policy. Use nonces or hashes.
2. **No CSP at all.** Leaves the app open to every XSS variant. CSP with report-only mode beats nothing.
3. **Returning the raw Zod error message to the client.** Field paths and validation messages can leak internal schema structure. Map to user-safe messages at the boundary.
4. **`dangerouslySetInnerHTML` without sanitization.** XSS injection vector. Sanitize via `DOMPurify` or `rehype-sanitize`, allowlist tags and attributes.
5. **Following redirects on user-supplied URLs.** `redirect: "manual"` and re-validate the target against the SSRF allowlist.
6. **Storing secrets in committed `.env` files or in code.** Even temporarily. Git history is forever; rotate any leaked secret immediately.
7. **Server Actions that bypass rate limits because "they're internal."** They aren't — they're public RPC endpoints. Every action that performs costly work or sensitive operations gets rate-limited.
8. **Streaming upload bytes through a Server Action.** Use signed URLs to object storage; bytes never touch your function.
9. **Trusting the client's `Content-Type` header.** Server-validate with magic-byte sniffing; the header is a hint, not a contract.
10. **Skipping signature verification on webhooks "for dev."** Sloppy dev patterns become production. Use the sender's CLI to forward signed events to localhost.
11. **Catching webhook errors and returning 200.** Mask the failure, retry stops, the event is lost. Return 5xx; let the sender retry.
12. **Generic "error" messages to the client when an actual security violation occurred.** A failed signature, a rate-limit trip, a denied permission, a malformed input — each is a distinct response code (400, 403, 429). Logging captures details; the client gets the response code.
13. **`pnpm install` in CI without `--frozen-lockfile`.** Allows unexpected version drift. Lock the lockfile.
14. **Postinstall scripts left enabled by default.** `ignore-scripts: true` in `.npmrc` and explicit allow-list for trusted packages.

## Principles

1. **Default deny.** Validation failure rejects, doesn't fall through. Permission unset means forbidden, not allowed. Unknown content type means rejected, not stored.

2. **Belt and suspenders.** CSP + `httpOnly` cookies + auth gates + rate limits + signed URLs. Each individual control fails sometimes; the combination is what survives an attacker who finds one weak spot.

3. **Validate at every boundary.** Trust nothing from the network. Schema-parse every external input — `searchParams`, `formData`, request bodies, third-party API responses. Once parsed, types are honest and code can rely on them.

4. **Sign or reject.** Webhooks, signed URLs, JWTs — anything coming from outside is signed and verified. Unsigned input from outside is treated as untrusted, validated, rate-limited.

5. **Keep secrets in the secret manager.** Never in code, never in committed `.env` files, never in logs. Validated at boot, scoped per environment, rotated on schedule.

6. **The blast radius of a dependency is permanent.** Vet before adopting. Renovate after. Audit always. A new dependency is a security commitment, not a convenience.

7. **Production is the test environment for security.** Patterns that look "dev only" — disabled signature verification, verbose error messages, secrets in test files — leak. Hold the production discipline in dev too.
