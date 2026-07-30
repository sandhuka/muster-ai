# Web Best Practices (Modern React + Next.js)

## Purpose
Define the foundational philosophy, stack defaults, environment management, modern API defaults, performance budgets, and quality gates for web development. This is the "if in doubt, this is the right call" file. See the `web-architecture` skill for layered architecture and folder structure (the foundation this skill builds on). See the `web-typescript-conventions` skill for TypeScript-specific rules. See the `web-modern-react` skill for RSC and Server Action API patterns. See the `web-state-management` skill for state discipline. See Developer's `web-accessibility` skill for accessibility implementation. Target: **Next.js 15+, React 19+, TypeScript 5.5+, Node.js 20+**.

## What "World-class Web" Means

The bar is "Would Apple ship this?" If a recommendation feels Stack Overflow-popular but architecturally lazy, reject it. The framework's job is not to teach the most common React patterns — it's to teach the right ones, even when they're less common.

Concretely:

- **Server-first by default.** RSC is the default; Client Components are interactivity islands. Code must justify being on the client, not the other way around.
- **Type safety as design tool.** Strict TS, branded IDs, discriminated unions, exhaustive switches. The compiler is your first reviewer.
- **Validation at every external edge.** Form data, request bodies, third-party API responses, any DB row whose schema isn't fully typed. Zod at the seam — never trust the inside what the outside sent.
- **Composition over configuration.** Small components that compose beat one component with thirty props. Same applies to functions, hooks, and modules.
- **Modern APIs only.** No `useEffect` for derived state. No class components. No `getServerSideProps`. No legacy patterns recommended out of caution — teach the modern correct pattern.
- **Performance is a default, not an optimization.** Core Web Vitals targets are explicit. Bundle budgets are enforced. Slow code is a bug.
- **Accessibility is a constraint, not a checklist.** Semantic HTML first, ARIA when semantics fall short, keyboard-first interactions, focus management default. WCAG 2.2 AA floor.
- **Tests test behavior, not implementation.** Refactors that don't change behavior shouldn't break tests. If they do, the tests are wrong.

## Stack Defaults

When in doubt, these are the picks. Override only with documented reason in `decision-log.md`.

| Concern | Default | Why |
|---------|---------|-----|
| Language | TypeScript (strict mode) | Compiler-as-reviewer; matches Swift's role on iOS |
| Framework | React 19+ | Dominant ecosystem, RSC and Server Actions are the modern model |
| Meta-framework | Next.js 15+ (App Router) | Best RSC implementation, file-based routing, Server Actions, streaming |
| Styling | Tailwind CSS | Atomic, zero runtime cost, design-token-friendly |
| Component primitives | shadcn/ui-style (copy-paste, not packaged) | Owned by your codebase, no library lock-in, customize at source |
| Server state | TanStack Query (when client-fetched) | Cache, revalidation, optimistic updates done right |
| Client state | Zustand for global, `useState`/`useReducer` for local | Minimal API, no provider trees, no boilerplate |
| Form handling | `react-hook-form` + Zod resolver | Uncontrolled (perf), schema-driven validation |
| Validation | Zod | Inference, parsing, branding — one library for every boundary |
| Testing | Vitest + React Testing Library + Playwright | Fast unit, behavior-focused component, real-browser E2E |
| Runtime | Node.js 20+ | Mature, predictable, broadest compatibility. Bun is a documented optional swap |
| Package manager | pnpm | Disk-efficient, strict-by-default symlinks, faster than npm |
| Deployment | Vercel | Native Next.js support, edge-by-default, preview deploys per branch |
| Error tracking | Sentry | Source maps, RSC support, performance traces |
| Analytics | Vercel Analytics + Web Vitals | Privacy-respecting, no cookie banner needed for first-party |

Project-specific deviations (e.g., self-hosting on Cloudflare for cost) get logged in `decision-log.md` with rationale and impact.

## Environment Management

All environment-specific values live in `.env.<environment>` files, validated at build time, accessed via a typed config module.

```
.env.local         # Local dev secrets, GITIGNORED
.env.development   # Non-secret dev config, committed
.env.production    # Non-secret prod config, committed
.env.example       # Template with placeholder values, committed
```

Validate at app boot:

```ts
// lib/env.ts
import { z } from "zod";

const Env = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]),
  DATABASE_URL: z.string().url(),
  AUTH_SECRET: z.string().min(32),
  STRIPE_SECRET_KEY: z.string().startsWith("sk_"),
  NEXT_PUBLIC_APP_URL: z.string().url(),
});

export const env = Env.parse(process.env);
```

Rules:
- **Validate at boot, not at use.** A misconfigured environment fails before the first request, not deep in a handler.
- **`NEXT_PUBLIC_*` is the only public prefix.** Anything else stays server-only. The compiler can't enforce this — code review must.
- **Never default secrets to test values.** A missing `STRIPE_SECRET_KEY` should crash boot, not silently use `sk_test_dev`.
- **One typed `env` export, used everywhere.** No raw `process.env.X` in feature code. Lint rule: `no-process-env`.
- **`.env.local` is the only `.env.*` file gitignored.** Non-secret config (URLs, feature flags) ships in the repo. Secrets live in the deployment platform's secret manager (Vercel env settings, Doppler, etc.) — never in any `.env` file in source control.
- **Never log `env` values**, even at startup. The shape can leak in stack traces; the values shouldn't.

## Modern API Defaults

When two ways exist to do something, the modern way is the right way. Don't recommend the legacy pattern out of caution.

| Don't | Do |
|-------|-----|
| `useEffect(() => setX(derive(y)), [y])` | `const x = derive(y)` (derive during render) |
| Class components | Function components |
| `getServerSideProps` / `getStaticProps` | Server Components + `async` data fetching |
| API routes (Pages Router) for mutations | Server Actions |
| `useState` for server data | TanStack Query (server cache) |
| `useState` for global client state | Zustand |
| `Date.now()` / `new Date()` in components | `now()` from `lib/time.ts` (testable) |
| `JSON.parse(JSON.stringify(...))` for cloning | `structuredClone(...)` |
| `Array.prototype.indexOf(...) !== -1` | `Array.prototype.includes(...)` |
| `axios` for fetching | Native `fetch` (Node 20+) |
| `moment.js` | `date-fns` or native `Intl.DateTimeFormat` |
| CSS-in-JS runtime (Emotion, styled-components) | Tailwind (compile-time, zero runtime) |
| `useMemo` / `useCallback` reflexively | Only when React Profiler shows cost |
| `forwardRef` everywhere | React 19+: refs are props on function components |
| `useReducer` for everything stateful | `useState` first; reach for `useReducer` only at 3+ related state pieces |
| `throw` from a Server Action | Return `{ ok: false, errors }` discriminated union |

## Performance Defaults

Core Web Vitals are non-negotiable. Targets:

| Metric | Target | Hard ceiling (CI fails) |
|--------|--------|-------------------------|
| LCP (Largest Contentful Paint) | <2.0s | 2.5s |
| INP (Interaction to Next Paint) | <150ms | 200ms |
| CLS (Cumulative Layout Shift) | <0.05 | 0.10 |
| TTFB (Time to First Byte) | <600ms | 800ms |
| Initial JS bundle (per route) | <100KB gzipped | 150KB |

Defaults that get you most of the way:

- **Server-render by default.** RSC ships zero JS for non-interactive code.
- **Streaming with Suspense.** Don't block the page on the slowest data.
- **Image optimization.** `next/image` for every image. Explicit `width`/`height` to prevent CLS.
- **Route-level code splitting.** App Router does this automatically; don't fight it.
- **`loading.tsx` for every route.** No blank screens during streaming.
- **`prefetch` on hover/viewport.** `next/link` does this by default; don't disable.
- **No CSS-in-JS at runtime.** Tailwind compiles to static CSS.
- **No client-side data libraries (lodash, ramda) in client bundles.** Native `Array`/`Object` methods or per-function imports.
- **Critical fonts via `next/font`.** Self-hosted, preloaded, no FOUT.
- **Defer non-critical scripts.** `next/script` with `strategy="lazyOnload"` for analytics, support widgets.

Performance regressions block PRs. Lighthouse CI in the PR workflow; bundle analyzer in CI; fail at the hard ceiling.

## Visual & Interaction Defaults

Web has WCAG and product taste in place of Apple's HIG. The Muster default for tasteful web:

- **Type scale**: 6-step (xs/sm/base/lg/xl/2xl), no arbitrary `text-[13.5px]`.
- **Spacing scale**: Tailwind's default (4/8/12/16/24/32/48/64). No `p-[7px]`.
- **Color**: semantic tokens (`bg-surface`, `text-on-surface`), not raw Tailwind colors in feature code. Tokens map to design system in `tailwind.config.ts`.
- **Motion**: respect `prefers-reduced-motion`. Default durations 150-250ms; longer only for full-page transitions.
- **Focus rings**: visible by default. Suppress only via `:focus-visible` for mouse users.
- **Touch targets**: 44x44px minimum (iOS HIG match), 48x48px on mobile contexts.
- **Loading states**: skeletons or progressive disclosure, never spinners over a blank page.
- **Empty states**: every list view has a designed empty state. Not "No results." — what should the user do next?
- **Error states**: typed (network / validation / permission / unknown), each with a recovery action.

## Quality Gates

A PR is shippable when all of these pass. CI enforces the mechanical ones; reviewers enforce the rest.

1. **Zero TypeScript errors** (`tsc --noEmit`). No `any`, no `// @ts-ignore`, no `as` outside type-narrowing utilities.
2. **Lints clean** (`eslint .` — zero warnings). Warnings degrade to noise; treat them as errors.
3. **Tests pass** (`vitest run` + Playwright). New behavior requires new tests; bug fixes require regression tests.
4. **Lighthouse meets budget** for affected routes (CI enforces hard ceilings above).
5. **Accessibility scan clean** (axe via Playwright). Zero serious violations.
6. **Bundle delta within budget** (analyzer on PR). Routes growing >10KB without explicit approval get rejected.
7. **Server Actions take a `deps` parameter** defaulting to `liveDeps`. See `web-architecture.md`.
8. **Zod validation at every external boundary** (forms, request bodies, third-party API responses).
9. **No `console.log` in production code paths.** Use the typed logger from `lib/logger.ts`. Lint rule: `no-console` (allow `error`/`warn`).
10. **Feature folder structure matches `web-architecture.md`.** No drift, no `components/` pile, no cross-feature imports.

## Principles

1. **The default is correct, not popular.** When the most-Googled answer is bad architecture, recommend the right one. Apple's engineering culture doesn't ship "popular" — it ships right.

2. **Type safety is a design tool.** Strict TS, branded types, discriminated unions, Zod at boundaries. The compiler should reject the wrong thing before runtime gets a chance.

3. **Server is the default.** Every Client Component must justify its directive. Bundle size, time-to-interactive, and SEO are all downstream of this single discipline.

4. **Validate at the edge, trust the inside.** Data crossing into your domain is parsed once at the boundary. Inside, types are honest and code can rely on them.

5. **Composition over configuration.** Small components that compose beat one component with thirty props. Same for functions, hooks, modules. Configuration sprawl is a refactor signal.

6. **Performance is a default, not an optimization.** Web Vitals targets are explicit and enforced. Slow code is a bug. Optimize architecturally before reaching for `useMemo`.

7. **Accessibility is a constraint, not a checklist.** WCAG 2.2 AA is the floor. Semantic HTML is the foundation. ARIA is a fallback when semantics fall short, not a primary tool.

8. **Modern APIs only.** Don't recommend the legacy pattern out of caution. Teach the modern correct one — even when it's less common.
