# Next.js App Router

## Purpose
Define App Router conventions: file-system routing, special files (page, layout, loading, error, not-found), dynamic and parallel/intercepting routes, route handlers, middleware, rendering modes, caching layers, revalidation, the Metadata API, and runtime selection. See the `web-architecture` skill for folder structure that hosts these routes. See the `web-modern-react` skill for Server Components, Server Actions, and Suspense semantics. See the `web-best-practices` skill for performance budgets enforced by routing decisions. Target: **Next.js 15+, React 19+**.

## Routing Model

App Router maps the file system to URLs. Folders become path segments, special files inside folders define rendering, layout, loading, and error states.

```
app/
  layout.tsx                  # Root layout (required, wraps every route)
  page.tsx                    # /
  loading.tsx                 # Suspense fallback for /
  error.tsx                   # Error boundary for /
  not-found.tsx               # 404 for /
  (marketing)/                # Route group — does NOT add a path segment
    pricing/page.tsx          # /pricing
    page.tsx                  # /
  (app)/
    layout.tsx                # Nested layout for everything below
    dashboard/page.tsx        # /dashboard
    invoicing/
      page.tsx                # /invoicing
      [invoiceId]/page.tsx    # /invoicing/inv_123
      [invoiceId]/loading.tsx
  api/
    webhooks/stripe/route.ts  # POST /api/webhooks/stripe
```

The folder structure mirrors product structure (per `web-architecture.md`); the App Router is just the URL shape that surfaces it.

## Special Files

| File | Purpose | Server/Client | Notes |
|------|---------|---------------|-------|
| `page.tsx` | Renders content for a route segment | Server Component (default) | The only file that *creates* a route. A folder with no `page.tsx` is invisible. |
| `layout.tsx` | Wraps `page.tsx` and nested layouts; preserves state across navigation | Server Component (default) | Shared chrome (header, sidebar). Must render `children`. |
| `template.tsx` | Like layout but **remounts** on navigation | Server Component (default) | Use only when you need fresh effects/state on every nav (rare). |
| `loading.tsx` | Auto-wraps the segment in `<Suspense>` with this as the fallback | Server Component (default) | Designed skeleton, not a spinner. |
| `error.tsx` | Auto-wraps the segment in an error boundary | **Client Component required** | Receives `error` and `reset` props. Must include `"use client"`. |
| `not-found.tsx` | Renders when `notFound()` is called or no route matches | Server Component (default) | Customize 404 per route segment. |
| `route.ts` | REST handler (GET/POST/PUT/PATCH/DELETE) | Server-only | For webhooks, third-party SDK callbacks, mobile clients. Mutations from the same web app go through Server Actions. |
| `middleware.ts` | Runs before route resolution, edge-runtime by default | — | One file at the project root. See "Middleware" below. |

### Layout rules

- **Layouts persist across navigation.** State, scroll position, and effects in a layout survive when navigating between sibling pages.
- **Layouts can fetch data.** Each layout fetches independently; results are deduped via React's per-request `cache()`.
- **Don't render the entire app inside a single layout.** Use route groups for layout boundaries by audience (marketing vs authenticated app).

### Page rules

- **Default export only** (Next.js convention — see `web-typescript-conventions.md`).
- **`params` and `searchParams` are Promises in Next.js 15+.** Must be awaited.

```tsx
// app/invoicing/[invoiceId]/page.tsx
type Props = { params: Promise<{ invoiceId: string }> };

export default async function InvoicePage({ params }: Props) {
  const { invoiceId } = await params; // unwrap the Promise
  const invoice = await fetchInvoice(InvoiceIdSchema.parse(invoiceId));
  return <InvoiceDetail invoice={invoice} />;
}
```

- **Validate route params at the boundary** with Zod. `params.invoiceId` is `string`; pass through `InvoiceIdSchema.parse` before using it as a domain `InvoiceId`.

### Error component rules

- **Must be a Client Component.** Error boundaries need to run on the client to catch render errors there.
- **Receives `error` and `reset` props.** `reset` re-attempts the segment.
- **Always include a recovery action.** "Try again" button calling `reset`, or a link back to a known-good route.

```tsx
"use client";

export default function InvoicingError({
  error,
  reset,
}: { error: Error; reset: () => void }) {
  return (
    <div role="alert">
      <h2>Couldn't load invoices</h2>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
```

## Route Groups and Dynamic Segments

| Pattern | URL effect | Use for |
|---------|-----------|---------|
| `(name)/` | None — purely organizational | Grouping routes with shared layout (e.g., `(marketing)`, `(app)`) |
| `[name]/` | Single dynamic segment | `[invoiceId]/`, `[slug]/` |
| `[...name]/` | Catch-all | `[...path]/` matches every nested segment |
| `[[...name]]/` | Optional catch-all | Matches the parent route too (param is empty array) |

Dynamic segments arrive as strings; always validate with Zod before treating as branded domain types.

```tsx
// app/(app)/invoicing/[invoiceId]/page.tsx
const { invoiceId: rawId } = await params;
const invoiceId = InvoiceIdSchema.parse(rawId); // throws → handled by error.tsx
```

## Parallel and Intercepting Routes

Niche patterns. Reach for them when they fit the use case, not as a default.

### Parallel routes (`@slot`)

Render multiple pages in parallel inside the same layout — each "slot" is a named children prop on the layout.

```
app/
  dashboard/
    layout.tsx       # receives { children, analytics, audit }
    @analytics/page.tsx
    @audit/page.tsx
    page.tsx
```

Use case: dashboards with independent panels that fetch and stream in parallel.

### Intercepting routes (`(.)`, `(..)`, `(...)`)

Render a route's content inside a different layout — most commonly modal-style detail views over a list.

```
app/
  invoicing/
    page.tsx                    # /invoicing (list)
    [invoiceId]/page.tsx        # /invoicing/inv_123 (detail page)
    @modal/(.)[invoiceId]/page.tsx  # /invoicing/inv_123 rendered as modal over list
```

Use case: clicking a list item opens a modal showing detail; sharing the URL opens the detail page directly. Same route, two presentations.

Don't use intercepting routes for non-modal navigation.

## Route Handlers (`route.ts`)

Server Actions handle mutations from the web app itself. Route handlers exist for genuine REST surfaces:

- Webhooks (Stripe, Vercel, third-party).
- Third-party SDK callbacks (OAuth redirects).
- Mobile or external clients sharing the API.
- Public read endpoints intended for non-browser consumption.

```ts
// app/api/webhooks/stripe/route.ts
import { headers } from "next/headers";
import { handleStripeWebhook, type Deps } from "@/features/billing/webhook";
import { liveDeps } from "@/lib/deps";

export async function POST(request: Request) {
  const signature = (await headers()).get("stripe-signature");
  const body = await request.text();
  const result = await handleStripeWebhook(
    { body, signature },
    liveDeps satisfies Pick<Deps, "stripeClient" | "invoiceRepository">,
  );
  return result.ok
    ? new Response(null, { status: 204 })
    : new Response(result.error, { status: 400 });
}
```

Rules:
- **Same `deps` parameter convention as Server Actions** — see `web-architecture.md`.
- **Return `Response` objects**, not throws.
- **Validate request body with Zod** before any domain call.
- **Never expose internal errors in responses.** Map domain errors to safe public messages.

## Middleware (`middleware.ts`)

A single file at the project root, edge-runtime by default. Runs before any route resolution.

```ts
// middleware.ts
import { NextResponse, type NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  if (request.nextUrl.pathname.startsWith("/admin")) {
    const session = request.cookies.get("session");
    if (!session) {
      return NextResponse.redirect(new URL("/login", request.url));
    }
  }
  return NextResponse.next();
}

export const config = {
  matcher: ["/admin/:path*", "/api/admin/:path*"],
};
```

Rules:
- **Use `matcher` to scope middleware** — running on every request including static assets is wasteful.
- **Edge runtime by default.** Avoid Node-only APIs (`fs`, native modules) here.
- **Keep middleware thin.** Auth gate, header injection, redirect logic — not business logic.
- **No DB calls.** Middleware runs on every matched request; a DB roundtrip there will tank latency.

## Rendering Modes

App Router has four rendering modes; the right one depends on data shape and freshness needs.

| Mode | Trigger | Use when |
|------|---------|----------|
| Static (default) | Page has no dynamic data fetching, no dynamic functions | Marketing pages, docs, anything that can be pre-rendered at build |
| Dynamic | Page reads `cookies()`, `headers()`, `searchParams`, or fetches with `cache: "no-store"` | Authenticated dashboards, personalized content |
| Streaming | Suspense boundaries split the response | Slow data that shouldn't block the shell |
| Partial Prerendering (PPR) | Static shell + dynamic islands within the same response (Next.js 15+) | Best of static performance with dynamic data — when supported by your hosting |

### Static rendering for dynamic routes

When a route uses `[param]` but you can enumerate the values at build, use `generateStaticParams`:

```tsx
// app/blog/[slug]/page.tsx
export async function generateStaticParams() {
  const posts = await listPosts();
  return posts.map((post) => ({ slug: post.slug }));
}

export const dynamicParams = false; // 404 for any slug not pre-rendered
```

### Forcing dynamic rendering

```tsx
export const dynamic = "force-dynamic";
```

Use sparingly. The default heuristic (Next.js detects dynamic-API usage) is usually correct.

## Caching Layers

Next.js 15 has four caching layers. Understand them or wreck performance and correctness.

| Layer | Scope | Default | When to invalidate |
|-------|-------|---------|--------------------|
| Request Memoization | Per-request, per-server-instance | Always on | Automatic per request |
| Data Cache | Persistent across deploys | Off in Next.js 15 (was on in 14) | `revalidatePath` / `revalidateTag` / `revalidate` option |
| Full Route Cache | Persistent on disk | On for static routes | `revalidatePath` / `revalidateTag` |
| Router Cache | Client-side, in-memory | On | Automatic on navigation; `router.refresh()` for explicit |

### `fetch` cache directives

Every `fetch` in a Server Component or query has explicit cache semantics:

```ts
// Always fresh (uncached)
fetch(url, { cache: "no-store" });

// Cache, revalidate every 60 seconds
fetch(url, { next: { revalidate: 60 } });

// Cache, invalidate via tag
fetch(url, { next: { tags: ["invoices"] } });
```

In Next.js 15, the default for `fetch` is `cache: "no-store"` — opt into caching with `revalidate` or `tags`. This reverses the Next.js 14 default and forces explicit decisions.

### Revalidation

`revalidatePath` and `revalidateTag` are the explicit invalidation primitives. Server Actions trigger them after mutations:

```ts
"use server";
import { revalidatePath, revalidateTag } from "next/cache";

export async function createInvoice(/* ... */) {
  // ...persist...
  revalidatePath("/invoicing");
  revalidateTag("invoices");
  return { ok: true, invoice };
}
```

### Cache rules

- **Tag your cached fetches with a domain noun.** `tags: ["invoices"]`, `tags: ["customers"]`, not `tags: ["data"]`.
- **One tag per logical aggregate.** A list view tags `"invoices"`; the detail page tags `"invoices"` AND `"invoice:${id}"`.
- **Server Actions invalidate after mutate.** Every mutation that affects a cached resource calls `revalidateTag` or `revalidatePath`.
- **Don't cache user-personalized fetches.** Or scope the cache key to the user.
- **`unstable_cache()` for non-`fetch` cacheables.** DB queries get the same cache layer if you opt in.

## Metadata API (SEO)

Static metadata via export, dynamic via function. Both type-safe.

```tsx
// app/invoicing/page.tsx — static
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Invoicing",
  description: "Manage invoices and customers.",
};
```

```tsx
// app/blog/[slug]/page.tsx — dynamic
import type { Metadata } from "next";

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPost(slug);
  return {
    title: post.title,
    description: post.excerpt,
    openGraph: { images: [post.coverUrl] },
  };
}
```

Rules:
- **Every public route has metadata.** Title, description minimum.
- **OpenGraph and Twitter card tags for shareable routes.**
- **`generateMetadata` runs in parallel with the page** — both can `await` the same data; per-request memoization dedupes.
- **Use the `template` field** in root layout's metadata for site-wide title suffix: `{ title: { default: "App", template: "%s | App" } }`.

## Built-in Optimizations

### `next/image`

Always. For every image. The pixel measurements aren't optional — they prevent CLS.

```tsx
import Image from "next/image";

<Image src="/hero.png" alt="Product hero" width={1200} height={600} priority />
```

- **Always specify `width` and `height`** (or `fill` with a sized parent).
- **`priority` for above-the-fold images** (LCP candidate).
- **`alt` is required** — empty string for decorative-only images, never omitted.

### `next/font`

Self-host fonts to eliminate layout shift and external requests.

```tsx
// app/layout.tsx
import { Inter } from "next/font/google";

const inter = Inter({ subsets: ["latin"], display: "swap" });

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.className}>
      <body>{children}</body>
    </html>
  );
}
```

`next/font` inlines the font, generates `font-display: swap`, and prevents FOUT.

### `next/script`

Defer non-critical scripts to avoid blocking the main thread.

```tsx
import Script from "next/script";

<Script src="https://analytics.example.com/script.js" strategy="lazyOnload" />
```

- **`strategy="lazyOnload"`** for analytics, support widgets, anything non-essential.
- **`strategy="afterInteractive"`** when the script must run soon but not before hydration.
- **Never** use a plain `<script src>` for third-party JS — it blocks parsing.

### `next/link`

Always for in-app navigation. Prefetches by default; never disable prefetch unless profiling shows cost.

```tsx
import Link from "next/link";

<Link href={`/invoicing/${invoice.id}`}>{invoice.id}</Link>
```

## Edge vs Node Runtime

Per route or middleware:

```ts
export const runtime = "edge";   // or "nodejs" (default for routes)
```

| Runtime | Use when |
|---------|----------|
| Edge | Latency-critical (auth, geo redirects, AB testing), small response, no Node-only APIs |
| Node (default) | Default for everything else — DB drivers, native modules, large dependencies |

Middleware is edge by default and should usually stay there. Route handlers default to Node and stay there unless there's a measured latency win.

## Anti-Patterns

1. **`getServerSideProps` / `getStaticProps`.** These are Pages Router. Don't use them in App Router code; use Server Component data fetching instead.
2. **API routes for in-app mutations.** Use Server Actions. Reserve route handlers for webhooks and external callers.
3. **`useEffect` in a Server Component.** Server Components don't run client effects; the Client Component boundary is `"use client"`.
4. **Reading `params` or `searchParams` synchronously.** They're Promises in Next.js 15+; await them.
5. **Top-level `cache: "force-cache"` on personalized data.** Personalized data needs scoped cache keys or no cache.
6. **Catching navigation errors with try/catch.** Navigation throws are React's signal — let them bubble to error boundaries.
7. **Heavy work in middleware.** Middleware runs on every matched request; no DB, no large computation.
8. **`router.push` in event handlers when `Link` would do.** `Link` prefetches; programmatic navigation skips that.
9. **Forgetting `revalidatePath`/`revalidateTag` after a mutation.** Stale UI after a successful action is a bug.
10. **One giant root layout.** Use route groups for scope (`(marketing)`, `(app)`) and nested layouts for shared sub-chrome.
11. **`<img>` instead of `next/image`.** Bundle bloat, CLS, no automatic optimization.
12. **`<a>` instead of `<Link>` for in-app routes.** Full page reload, no prefetch.

## Principles

1. **The file system is the routing API.** Folders are paths, special files are conventions. Reaching for custom routing config is a smell.

2. **Server Actions for in-app mutations, route handlers for external surfaces.** The line is whether the caller is your own React code (action) or someone else's HTTP client (handler).

3. **Cache decisions are explicit, not inherited.** Every fetch declares cache behavior; every Server Action declares what to invalidate. The caching graph is in the code, not in someone's head.

4. **Validate every param at the boundary.** `params` and `searchParams` are strings — they cross into branded domain types only after Zod parses them.

5. **Designed loading and error states everywhere.** Skeletons, not spinners. Error boundaries with recovery actions. The page is never blank, never broken.

6. **Static when you can, dynamic when you must, streaming when you should.** Most pages should be mostly static. Dynamic-by-default is a cost paid on every request.

7. **Trust the optimizations.** `next/image`, `next/font`, `next/link`, `next/script` exist because hand-rolling them is wrong. Use them; don't reinvent.
