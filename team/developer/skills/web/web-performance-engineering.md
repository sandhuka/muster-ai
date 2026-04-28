# Web Performance Engineering

## Purpose
Define the diagnostic workflows behind the Core Web Vitals budgets that `web-best-practices.md` only states. Bundle analysis with CI regression detection, client-component minimization with concrete refactorings, `dynamic()` import patterns, request-waterfall elimination, React DevTools Profiler workflow, `next/font` and `next/image` discipline on the LCP element, third-party script isolation. The targets live in `web-best-practices.md`; this skill is how to hit them. See `team/developer/skills/web-best-practices.md` for the budgets. See `team/developer/skills/web-modern-react.md` for effects discipline, Suspense, React Compiler. See `team/developer/skills/web-state-management.md` for re-render prevention via selectors. See `team/developer/skills/web-nextjs-app-router.md` for built-in optimizations. See `team/developer/skills/web-cicd.md` for Lighthouse CI wiring. Target: **Next.js 15+, React 19+**.

## The Workflow Mindset

Performance is diagnosed, not guessed. A failing metric points to a class of cause; the workflow narrows to the actual cause; the fix is targeted. The skill is organized by **symptom** because that's the entry point — Lighthouse flagged INP at 380ms; what now?

The four classes of performance problem:

| Symptom | Most likely cause | Tools |
|---------|------------------|-------|
| LCP too high (>2.5s) | Server response slow, image not optimized, render-blocking resource | Lighthouse, WebPageTest, `next/image` audit |
| INP too high (>200ms) | Long tasks on main thread, third-party scripts, unmemoized client component re-renders | React DevTools Profiler, performance trace, third-party audit |
| CLS too high (>0.1) | Images without dimensions, fonts loading FOUT, late-injected content | Lighthouse layout shift sources, font config audit |
| Bundle too big (>150KB gzipped per route) | Misplaced `"use client"`, heavy client libraries, unused exports | `@next/bundle-analyzer`, source-map-explorer |

Walk the workflow for the failing class; don't optimize symptoms you don't have.

## Bundle Analysis with CI Regression Detection

`web-best-practices.md` says "bundle delta within budget." The mechanism:

```ts
// next.config.ts
import withBundleAnalyzer from "@next/bundle-analyzer";

const config: NextConfig = { /* ... */ };

export default withBundleAnalyzer({
  enabled: process.env.ANALYZE === "true",
})(config);
```

```bash
# Generate the analyzer report
ANALYZE=true pnpm build
# Open .next/analyze/client.html — visual treemap of every bundle
```

CI regression detection — store a baseline, fail PRs that exceed deltas:

```yaml
# .github/workflows/bundle-check.yml (excerpt — full pipeline in web-cicd.md)
- name: Build with bundle stats
  run: pnpm build
- name: Compare against baseline
  uses: ./scripts/bundle-diff
  with:
    baseline: bundle-baseline.json
    threshold-bytes: 10240  # 10 KB delta per route
```

```ts
// scripts/bundle-diff.ts (excerpt)
const baseline = JSON.parse(fs.readFileSync("bundle-baseline.json", "utf8"));
const current = readBuildManifest();

for (const route of Object.keys(current)) {
  const delta = current[route].size - (baseline[route]?.size ?? 0);
  if (delta > THRESHOLD) {
    console.error(`Route ${route}: +${humanBytes(delta)} (limit: ${humanBytes(THRESHOLD)})`);
    process.exit(1);
  }
}
```

Rules:
- **`bundle-baseline.json` is committed.** Updates require an explicit PR and review — opt-in growth, not silent drift.
- **Threshold per route, not global.** Some routes are heavier by nature (admin dashboards with charts); the budget is per-route.
- **Build runs against production config.** Dev bundles include source maps, dev tools, hot reload — not the bundle being measured.
- **Treemap reviewed when budget exceeds.** Visual identification of what grew is faster than reading numbers.

## Client-Component Minimization (the highest-leverage move)

The single highest-leverage perf intervention: **push `"use client"` from page-level to leaf-level.** Most LLM-generated code marks a page client because *one* button needs interactivity, then every child is forced to client-render.

### The before-state

```tsx
// app/(app)/dashboard/page.tsx (Wrong — page is client)
"use client";
import { useState } from "react";
import { fetchDashboardData } from "@/features/dashboard/api";
import { Header } from "@/components/header";

export default function DashboardPage() {
  const [data, setData] = useState(null);
  const [refreshing, setRefreshing] = useState(false);

  // ... fetches data via useEffect, has refresh button ...
  return (
    <main>
      <Header />
      <h1>Dashboard</h1>
      <DashboardSummary data={data} />
      <button onClick={() => refresh()}>Refresh</button>
    </main>
  );
}
```

Costs paid:
- Page renders client-side; data fetched after JS loads (slow LCP).
- Every imported child component runs in client mode (large bundle).
- `useEffect`-fetch causes a waterfall (LCP delayed further).
- SEO and initial-paint suffer.

### The after-state

```tsx
// app/(app)/dashboard/page.tsx (Right — Server Component, data fetched server-side)
import { fetchDashboardData } from "@/features/dashboard/queries";
import { DashboardSummary } from "@/features/dashboard/components/dashboard-summary";
import { RefreshButton } from "@/features/dashboard/components/refresh-button";
import { Header } from "@/components/header";

export default async function DashboardPage() {
  const data = await fetchDashboardData();
  return (
    <main>
      <Header />
      <h1>Dashboard</h1>
      <DashboardSummary data={data} />
      <RefreshButton /> {/* the only client island */}
    </main>
  );
}
```

```tsx
// features/dashboard/components/refresh-button.tsx (Client Component — minimal scope)
"use client";
import { useTransition } from "react";
import { useRouter } from "next/navigation";

export function RefreshButton() {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  return (
    <button disabled={pending} onClick={() => startTransition(() => router.refresh())}>
      {pending ? "Refreshing…" : "Refresh"}
    </button>
  );
}
```

What changed:
- The page renders on the server; HTML arrives with data (fast LCP).
- `DashboardSummary` and `Header` render server-side; zero JS shipped for them.
- Only `RefreshButton` ships JS — a few hundred bytes instead of kilobytes.
- The waterfall disappears; data is fetched on the server in parallel with rendering.

### The refactoring procedure

When you see a page-level `"use client"`:

1. **Identify the actual interactive elements.** Buttons, inputs, anything with event handlers. Often 1-3 small pieces.
2. **Extract each into its own Client Component file.** Add `"use client"` only at the top of those files.
3. **Remove `"use client"` from the page.**
4. **Move data fetching to the page (or a `queries.ts` file).** Use Server Component `async` rendering.
5. **Replace `useEffect` data fetches with server `await`.** The data is in the props/render tree from the start.
6. **Verify in the bundle analyzer**: the route's client bundle should drop substantially.

This refactor often cuts route bundles by 40-70%.

## `dynamic()` for Non-Critical Client Code

Heavy client-only components — rich text editors, code highlighters, charting libraries, modal dialogs — should not be in the initial bundle.

```tsx
// features/posts/components/post-editor.tsx
import dynamic from "next/dynamic";

// Heavy editor only loads when user clicks "Edit"
const RichTextEditor = dynamic(() => import("./rich-text-editor"), {
  loading: () => <EditorSkeleton />,
  ssr: false,  // Editor uses browser APIs; skip SSR
});

export function PostEditor({ post }: Props) {
  const [editing, setEditing] = useState(false);
  if (!editing) return <PreviewMode post={post} onEdit={() => setEditing(true)} />;
  return <RichTextEditor initial={post.body} />;
}
```

When to reach for `dynamic()`:

| Component type | Use `dynamic()` |
|----------------|----------------|
| Modal/dialog rendered on user action | Yes — defer until the trigger fires |
| Rich text editor, code highlighter, chart library, map | Yes — substantial bundles, not always needed |
| Feature flag-gated client component | Yes — load only when flag is on |
| Above-the-fold core component | No — would delay LCP |
| Sub-100KB client component | Probably not — overhead of the dynamic wrapper isn't worth it |

Rules:
- **`ssr: false`** when the component uses browser APIs (window, document, third-party libs that don't SSR).
- **`loading` fallback** preserves layout, prevents CLS during the dynamic load.
- **Don't `dynamic()` a Server Component.** The pattern is for client-only code-splitting; Server Components are split by route automatically.

## Request Waterfall Elimination

The classic Server Component anti-pattern: sequential `await`s that could run in parallel.

### The waterfall

```tsx
// Wrong — three round-trips, one after another
export default async function ProjectPage({ params }: Props) {
  const { projectId } = await params;
  const project = await fetchProject(projectId);          // 200ms
  const owner = await fetchUser(project.ownerId);         // 200ms (waits for project)
  const members = await fetchMembers(project.id);         // 200ms (waits for project)
  // Total: 600ms
  return <ProjectDetail project={project} owner={owner} members={members} />;
}
```

### Fix 1: `Promise.all` for independent fetches

```tsx
// Right — owner and members fetch in parallel after project resolves
export default async function ProjectPage({ params }: Props) {
  const { projectId } = await params;
  const project = await fetchProject(projectId);          // 200ms
  const [owner, members] = await Promise.all([
    fetchUser(project.ownerId),
    fetchMembers(project.id),
  ]);                                                      // 200ms (parallel)
  // Total: 400ms
  return <ProjectDetail project={project} owner={owner} members={members} />;
}
```

### Fix 2: Parallel Suspense for independent UI sections

When sections of the page are genuinely independent, stream them:

```tsx
// Even better — sections stream as data arrives; don't block each other
import { Suspense } from "react";

export default async function ProjectPage({ params }: Props) {
  const { projectId } = await params;
  return (
    <main>
      <Suspense fallback={<ProjectHeaderSkeleton />}>
        <ProjectHeader projectId={projectId} />
      </Suspense>
      <Suspense fallback={<MembersSkeleton />}>
        <Members projectId={projectId} />
      </Suspense>
      <Suspense fallback={<ActivitySkeleton />}>
        <Activity projectId={projectId} />
      </Suspense>
    </main>
  );
}
```

Each `<Suspense>` boundary fetches independently. The header arrives first (fast); members and activity stream in as their data resolves. The user sees content immediately instead of waiting for the slowest query.

### Fix 3: Push the data fetch up to a higher boundary

When two child components need the same data, fetch it once at the parent rather than twice in each:

```tsx
// Wrong — siblings each fetch the same data
function CustomerHeader({ customerId }) { const customer = await fetchCustomer(customerId); /* ... */ }
function CustomerActions({ customerId }) { const customer = await fetchCustomer(customerId); /* ... */ }

// Right — parent fetches once, passes down
async function CustomerSection({ customerId }) {
  const customer = await fetchCustomer(customerId);
  return <><CustomerHeader customer={customer} /><CustomerActions customer={customer} /></>;
}
```

Note: Next.js dedupes `fetch()` calls per request automatically (request memoization). For DB queries, this dedupe doesn't apply — you get N round-trips for N calls. Push the fetch up.

## React DevTools Profiler Workflow

When INP is bad and you suspect re-render storms in client components:

1. **Open React DevTools → Profiler tab.**
2. **Click "Start profiling," reproduce the slow interaction, click "Stop."**
3. **Switch to "Ranked" view.** Components are sorted by render time. The biggest bars are the bottlenecks.
4. **Click a slow component → Why did this render?** Tells you whether it was a state change, prop change, parent re-render, or hook value change.
5. **Identify the trigger.** Usually one of:
   - **Parent re-renders unnecessarily** → memoize the parent or split it.
   - **Context value changes shape on every render** → wrap context value in `useMemo` (or use Zustand instead).
   - **Inline objects/functions create new references** → React Compiler should fix this; if not, manual `useMemo`/`useCallback` on the specific value.
   - **Whole Zustand store consumed instead of selector** → switch to `useStore((s) => s.x)` per `web-state-management.md`.

```tsx
// Common cause #1: full Zustand store consumed
// Wrong
const state = useStore();  // re-renders on any store update
return <div>{state.theme}</div>;

// Right
const theme = useStore((s) => s.theme);  // re-renders only when theme changes
return <div>{theme}</div>;
```

```tsx
// Common cause #2: inline object as prop, child memoized
// Wrong — inline object means new reference every render
<Child config={{ size: "large" }} />

// Right (with React Compiler) — compiler handles it
// Right (without React Compiler)
const config = useMemo(() => ({ size: "large" }), []);
<Child config={config} />
```

The Profiler turns "INP is bad" into "this specific tree re-renders 12 times per keystroke because…" — that's the difference between guesswork and a fix.

## `next/font` and `next/image` on the LCP Element

LCP is the largest visible element rendered above the fold. Usually a hero image or the first big heading. Two specific disciplines:

### Identify the LCP element

In Lighthouse → Performance → Largest Contentful Paint → "Element" — the exact DOM node Lighthouse measured. Next step depends on what kind of element it is.

### If LCP is an image

```tsx
import Image from "next/image";

// Right — explicit width/height prevents CLS, priority loads ahead of other resources
<Image
  src="/hero.png"
  alt="Product hero"
  width={1200}
  height={600}
  priority
  sizes="(max-width: 768px) 100vw, 1200px"
/>
```

Rules:
- **`priority`** on the LCP image only. Browser preloads it; LCP improves materially.
- **Never `priority` on multiple images per page.** Defeats the purpose; preload bandwidth is finite.
- **`sizes` declared** so the browser picks the right responsive variant. Without it, the largest variant always loads.
- **`width` and `height` always set** (or use `fill` with a sized parent). CLS is non-negotiable.
- **WebP or AVIF format** for the source. Half the bytes for the same quality.

### If LCP is text

The font is on the critical path. Use `next/font` with subsetting and `display: swap`:

```tsx
// app/layout.tsx
import { Inter } from "next/font/google";

const inter = Inter({
  subsets: ["latin"],            // only Latin glyphs — much smaller payload
  display: "swap",               // text shows immediately in fallback, swaps when font loads
  variable: "--font-inter",
  preload: true,
});

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.variable}>
      <body className="font-sans">{children}</body>
    </html>
  );
}
```

Rules:
- **`subsets`** to the minimum required scripts. The default `["latin"]` is right for most apps; add others (`"latin-ext"`, `"cyrillic"`) only when content demands.
- **`display: "swap"`** to prevent FOIT (flash of invisible text). FOUT (flash of unstyled text) is the lesser evil.
- **`preload: true`** for above-the-fold fonts; `preload: false` for fonts only used below the fold (e.g., a code-block monospace).
- **Self-hosted via `next/font`**, never `<link href="https://fonts.googleapis.com/...">`. The third-party request is render-blocking and slower than self-hosting.

## Third-Party Script Isolation

Third-party scripts (analytics, support widgets, ad pixels, A/B testing libraries, session replay) are the #1 cause of poor INP scores. Each runs JS on the main thread; cumulative effect is interaction blocked.

Strategies, in order of effectiveness:

### 1. Don't add it (the best optimization)

Audit every third-party script regularly:
- Does this still serve a real purpose?
- Can the team replace it with first-party tracking (Vercel Analytics, server-side analytics)?
- Is the data being acted on, or just collected?

The cleanest perf win is removing scripts no one uses.

### 2. Defer with `next/script`

```tsx
import Script from "next/script";

<Script src="https://analytics.example.com/script.js" strategy="lazyOnload" />
```

`strategy` options:
- **`beforeInteractive`** — blocks; never use for non-essential scripts.
- **`afterInteractive`** (default) — runs after hydration, before idle.
- **`lazyOnload`** — runs after the browser idle. Right for analytics, support widgets, anything non-essential.
- **`worker`** — Partytown integration; runs on a Web Worker.

Default to **`lazyOnload`** for non-critical scripts.

### 3. Worker-isolate via Partytown

For scripts that absolutely must run but pollute the main thread (Google Tag Manager, third-party A/B testing, heavy ad pixels), Partytown moves them to a Web Worker:

```tsx
// app/layout.tsx
import { Partytown } from "@builder.io/partytown/react";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <Partytown debug={false} forward={["dataLayer.push"]} />
        <Script
          src="https://www.googletagmanager.com/gtag/js"
          strategy="worker"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

Trade-offs:
- Some scripts don't run correctly in a Worker (anything that touches DOM directly).
- Setup complexity.
- Reach for it when `lazyOnload` isn't enough.

### 4. Defer until interaction

For scripts that only matter after the user does something (chat widget, video player), don't load until the trigger:

```tsx
"use client";
import { useState } from "react";
import dynamic from "next/dynamic";

const ChatWidget = dynamic(() => import("./chat-widget"), { ssr: false });

export function SupportButton() {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button onClick={() => setOpen(true)}>Need help?</button>
      {open && <ChatWidget />}
    </>
  );
}
```

The chat widget's tens of KB of JS load only when the user clicks. INP for the rest of the page stays clean.

## Symptom-to-Workflow Quick Reference

| Symptom | First check | Then |
|---------|-------------|------|
| **LCP > 2.5s** | Lighthouse "Largest Contentful Paint" element. Image? Text? | Image: add `priority`, check format/size. Text: `next/font` with `display: swap`. Server-side delay: check DB query timings (see `web-data-layer.md`). |
| **INP > 200ms** | Performance trace during the slow interaction. Long tasks? | Long task in app code → React Profiler → identify re-render storm. Long task in third-party → `lazyOnload` or remove. |
| **CLS > 0.1** | Lighthouse "Layout Shift" sources. | Images without dimensions → `next/image` with `width`/`height`. Fonts FOIT → `display: swap`. Late-injected content → reserve space with `min-height`. |
| **Bundle > 150KB** | `ANALYZE=true pnpm build`, open treemap. | Misplaced `"use client"` → push to leaves. Heavy library → `dynamic()` import. Unused export → tree-shake or remove. |

## Anti-Patterns

1. **Reflexive `useMemo` / `useCallback`.** Without measurement, these add overhead with no benefit. With React Compiler enabled, they're nearly always redundant. Profile first.
2. **`"use client"` at the page level.** Forces every child client-rendered. Push the directive to the smallest interactive island.
3. **`useEffect` for data fetching in client components.** Use Server Components or TanStack Query. Effect-based fetching causes waterfalls and blank screens.
4. **Sequential `await` for independent data.** `Promise.all` parallel-fetches; parallel Suspense streams.
5. **Multiple `priority` images on one page.** Preload bandwidth is finite; only the LCP image gets `priority`.
6. **Importing a large library to use one function.** `import { debounce } from "lodash"` pulls all of lodash. Use `lodash/debounce` or write the four-line `debounce` inline.
7. **Third-party scripts loaded with default strategy.** Anything non-critical → `lazyOnload`. Anything that pollutes main thread → Partytown or remove.
8. **Optimization without measurement.** Adding `useMemo` "just in case," dynamic-importing components that aren't heavy, code-splitting routes already split. Optimization without a profile is technical debt.
9. **Ignoring CI bundle alerts.** PR adds 25KB to a route, baseline bumped without review. Bundle baseline must be updated explicitly with rationale.
10. **Web fonts from Google CDN.** Render-blocking, slower than self-hosting. `next/font` self-hosts and inlines.
11. **Animations without `will-change` or `transform` discipline.** Animating `top`/`left` triggers layout; `transform`/`opacity` are GPU-accelerated. Use the cheap properties.
12. **`React.memo` everywhere.** Memo has cost (memoization comparison runs on every render). Apply only when the Profiler shows the wrap is worth it.

## Principles

1. **Diagnose, don't guess.** A failing metric points to a class of cause; tools narrow to the actual cause; the fix is targeted. Adding `useMemo` because INP is bad is guessing.

2. **The default is server.** Most performance wins come from rendering on the server and shipping less JS. Client components are interactivity islands; everything else stays server.

3. **Bundle budget is a line, not a goal.** Write code that doesn't grow the bundle by default; the budget catches regressions. Don't optimize a route that's well under budget — work on the ones over.

4. **Measure before micro-optimizing.** `useMemo`, `useCallback`, `React.memo` only when profiling shows they earn their keep. With React Compiler enabled, mostly redundant.

5. **Third-party scripts are the leading INP killer.** Audit, defer, isolate, or remove. Default to `lazyOnload`; reach for Partytown when defer isn't enough.

6. **The LCP element gets special attention.** `priority` on its image, `next/font` with `display: swap` for its text, no render-blocking scripts above it. Everything else can wait.

7. **Streaming is the shape of perceived performance.** Independent sections in independent Suspense boundaries arrive as their data resolves. The user sees the page progressively, not all-at-once-after-the-slowest.
