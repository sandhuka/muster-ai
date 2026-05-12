# Web Screen Specification

## Purpose
Define the complete screen-spec template used to hand off web designs to the Developer agent. A screen spec is the single source of truth for implementing one route or modal: it wraps the wireframe, annotation table, route context, data sources, states, interactions, accessibility, responsive behavior, and component inventory into one in-repo markdown file. The spec is what the Developer reads to build the screen — it must leave zero ambiguity. See `team/ui-ux/skills/web-wireframe-methodology.md` for the wireframe format that lives inside this spec. See `team/ui-ux/skills/web-content-hierarchy.md` for the hierarchy exercise that precedes layout. See `team/ui-ux/skills/web-design-system.md` for the tokens and components the spec references. See `team/ui-ux/skills/web-responsive-patterns.md` for the responsive primitives the layout assumes. See `team/ui-ux/skills/web-interaction-patterns.md` for shared interaction patterns referenced by the spec. See `team/ui-ux/skills/web-accessibility.md` for design-side a11y requirements the spec encodes. See `team/developer/skills/web-architecture.md` for how the spec maps onto the Developer's layered architecture (Server Components, Server Actions, layered folders). See `team/developer/skills/web-nextjs-app-router.md` for the App Router primitives (`page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`, `not-found.tsx`, route groups, parallel/intercepting routes) that the Route Context section refers to. Target: **Next.js 15+ App Router, React 19+, TypeScript 5.5+, design specs committed to `knowledge-base/design-specs/`**.

## Apple's Detail Standard (Web Edition)

A web screen spec ships with the same standard as the iOS one: every pixel intentional, every element token-referenced, every state defined, every interaction has a response, every edge case has a design. The web *adds* concerns iOS doesn't have:

- The server/client boundary — the spec must say where rendering happens, because it determines what data flows where.
- The route surface — `page.tsx` vs. `layout.tsx` vs. `loading.tsx` vs. `error.tsx` vs. `not-found.tsx` are all decision points the spec resolves.
- The auth gate — every authenticated route declares whether `requireUser()` runs before render.
- SEO / metadata — public routes ship with title, description, social tags.
- Hover and focus — iOS has none of these; web has both, and they need explicit specification.
- Container-driven responsive behavior — components adapt to *space*, so the spec describes layout intent, not viewport pixels.

If the Developer has to guess any of these, the spec is incomplete.

## When to Write a Spec

| Surface | Spec required? |
|---------|---------------|
| New route (`app/<segment>/page.tsx`) | Yes |
| New modal / sheet / popover | Yes |
| New layout shared across routes (`app/<segment>/layout.tsx`) | Yes |
| New shared design-system component | No — that's a component spec, not a screen spec |
| Pure copy change to an existing screen | No — Content agent edits the existing spec's Copy section |
| Adding a new state to an existing screen (e.g., a permission-gated variant) | Edit existing spec; do not duplicate |

One spec per logical screen. A modal that opens on top of a screen is its own spec, cross-referenced from the parent screen's Interactions section.

## Screen Spec Template

```markdown
# Screen: [Screen Name]

**Feature ID**: [F-XXX-N from product spec]
**Flow**: [Which user flow this screen belongs to]
**Surface type**: [route | modal | sheet | popover | panel]
**Entry points**: [How users arrive — e.g., "tab switch from /today, push from /onboarding/3"]
**Exit points**: [Where users can go — e.g., "back, sign out, push to /session/[id]"]

---

## Route Context
*Skip this section for non-route surfaces (modals, sheets, panels).*

- **Path**: `/app/today` (or `/(app)/today` if inside a route group)
- **Route group**: `(app)` — authenticated app group
- **Layout chain**: `app/layout.tsx` → `app/(app)/layout.tsx` → this `page.tsx`
- **Auth gate**: `requireUser()` runs in the `(app)/layout.tsx` — anonymous users redirect to `/sign-in`
- **Server vs Client default**: page is Server Component; interactive islands marked below
- **Static shell vs dynamic islands** (Partial Prerendering): page is **partially prerendered**. The static shell includes the page chrome, H1, week-strip skeleton, and streak label position. Dynamic islands wrapped in `<Suspense>`: the routine card (depends on session + algorithm output), the week-strip data, the streak count. The static shell ships from the CDN edge instantly; dynamic islands stream in as data resolves. **Use PPR when there's genuine static content the edge can cache; use fully dynamic rendering when every byte of the route is per-user (e.g., `/inbox`, `/settings`).** A static shell that's 80% session-personalized adds latency and saves nothing.
- **Loading**: handled by `app/(app)/today/loading.tsx` (Suspense boundary at route)
- **Error**: handled by `app/(app)/today/error.tsx`
- **Not-found**: N/A (no dynamic segment)
- **Metadata**:
  - Title: `"Today | Muster"`
  - Description: `"Your routine for today"`
  - OpenGraph: inherits from `app/layout.tsx`
- **Caching**: dynamic islands re-render per request; static shell is cached at the edge.
- **Revalidation**: `revalidatePath("/today")` triggered by `completeSession` action.

---

## Layout

### Wireframe — Mobile (375px)
[ASCII wireframe per `web-wireframe-methodology.md` conventions]

### Wireframe — Desktop (1280px)
[ASCII wireframe per `web-wireframe-methodology.md` conventions]

### Annotations
| # | Element | Type | Token / Component | State coverage | Notes |
|---|---------|------|-------------------|---------------|-------|
| 1 | … | … | … | … | … |

### Layout Structure (Component Tree)
- `<TodayPage>` — Server Component
  - `<PageHeader title="Today">` — shared shell component
  - `<Suspense fallback={<RoutineCardSkeleton />}>`
    - `<RoutineCard>` — Server Component (awaits its own data via `getRoutineForToday()`)
      - `<StartSessionButton routineId={…}>` — Client Component (interactive island)
  - `<Suspense fallback={<WeekStripSkeleton />}>`
    - `<WeekStrip>` — Server Component
  - `<StreakSummary>` — Server Component (cheap, no Suspense)

### Container Query Scopes
- `<RoutineCard>`: `@container/card`. At `@md` (≥480px) hero image moves to the right; at `@xs` (<320px) helper text truncates.
- `<WeekStrip>`: not container-queried — always horizontal flex with wrap.

### Scroll Behavior
- Page scrolls vertically.
- Top nav is `position: sticky`. On mobile, hides on scroll-down past 100px.
- Sidebar nav (desktop only): `position: sticky` within its column; does not scroll with main.
- Bottom nav (mobile only): `position: sticky`, visible at all scroll positions.
- No infinite scroll; no virtualization needed at expected list sizes.

---

## Content & Data

### Data Sources
| Field | Source | Layer | Cache strategy | Fallback |
|-------|--------|-------|----------------|----------|
| Routine for today | `getRoutineForToday(userId)` (server query) | Application | request-memoized via `cache()` | If null → empty state |
| Week strip status | `getWeekStatus(userId, weekStart)` | Application | request-memoized | Empty array → all "upcoming" |
| Streak count | `getStreakCount(userId)` | Application | request-memoized | 0 |
| Session start | `startSession(routineId)` (Server Action) | Application | — | Returns `{ ok: false, error }` envelope on failure |

### Copy
| Element | Copy | Char limit | Token | Owner |
|---------|------|-----------|-------|-------|
| Page title (visible H1) | "Today" | 10 | `text-h1` | UI/UX |
| Routine card title | `[from algorithm output]` | 40 | `text-h3` | Data — fallback "Your Routine" |
| Routine helper line | `[Content agent to provide]` | 80 | `text-body` `text-text-muted` | Content |
| Start session CTA | "Start session" | 20 | Button label | UI/UX |
| Empty state heading | `[Content agent to provide]` | 40 | `text-h2` | Content |
| Empty state body | `[Content agent to provide]` | 120 | `text-body` `text-text-muted` | Content |
| Empty state CTA | "Generate today's routine" | 30 | Button label | UI/UX |
| Streak label | `"{n}-day streak"` (templated) | 20 | `text-caption` | UI/UX |
| Error fallback heading | `[Content agent to provide]` | 40 | `text-h2` | Content |

---

## States

Every screen ships at least four states. Use "same as content" if accurate, but never omit.

### Loading (initial fetch)
- Implementation: `loading.tsx` at the route + per-Suspense skeletons inside.
- Skeleton layout: matches the content layout exactly — same boxes, same dimensions, neutral fill (`bg-surface-muted`), subtle shimmer animation (respects `prefers-reduced-motion`: shimmer disabled).
- Minimum display: 200ms (avoid skeleton flash on fast networks).
- Transition to content: token `--duration-short` crossfade.

### Content (default)
The primary wireframe above. Conditions: data loaded, user has at least one generated routine.

### Empty State Coverage (per origin)
Per `team/ui-ux/skills/web-empty-error-and-edge-states.md`, every screen with a list/table/feed must address all applicable empty origins explicitly. List which apply and what each does:

- **Never-had-content**: "No routine yet — generate today's to get started." → CTA: "Generate routine" (triggers `generateRoutine` action).
- **You-emptied-it**: N/A (routines aren't user-deletable from this screen; archived past routines live on `/history`).
- **No-search-results**: N/A (no search on this screen).
- **Filter-emptied-it**: N/A (no filters on this screen).
- **Permission-denied**: N/A (handled by layout-level `requireUser()` redirect).
- **Loading-failed**: see Error → recoverable transient.

For screens that *do* support search/filters/multi-user permissions, address each origin or mark explicitly N/A with a one-line reason. Silent omission is incomplete.

### Error State Coverage (per category)
Per `team/ui-ux/skills/web-empty-error-and-edge-states.md`, identify which error categories apply and how each is handled:

- **Validation** (form-level): N/A (no forms on this screen).
- **Recoverable transient** (network blip, timeout): inline error within the routine card; `text-danger`; retry button reuses `getRoutineForToday()`.
- **Recoverable persistent** (quota exceeded, expired session): banner at app shell (handled by `app/(app)/layout.tsx`); not redrawn here.
- **Irrecoverable** (404 on a dynamic route, deleted record, 403): not applicable on this static-path route. For routes with dynamic segments, handled by `not-found.tsx`.
- **Server-broken** (500/502/503): handled by `app/(app)/today/error.tsx`; shows brand-voiced message + `error.digest` reference + retry CTA.
- **Maintenance** (503 scheduled): handled by app-shell maintenance gate; not redrawn here.
- **Offline**: persistent banner at app shell + degraded view (cached routine if any, "last updated" timestamp).

### Tier variants
- **Free**: routine card shows preview of first exercise; "Start session" CTA replaced with "Upgrade to start" linking to `/upgrade`. Week strip hidden.
- **Premium**: full content state.

### Permission-gated variants
- **Anonymous**: redirect to `/sign-in?next=/today` at the layout level. Spec does not need to render this state.

---

## Interactions

### Click / Tap Targets
| Element | Action | Transition | Pending UI |
|---------|--------|-----------|-----------|
| "Start session" button | `startSession(routineId)` Server Action via `useTransition` | Push to `/session/[id]` on success | Button shows "Starting…", disabled |
| Day chip in week strip | Push to `/sessions/[date]` | Standard route push | None (instant) |
| "Upgrade to start" (free tier) | Push to `/upgrade?from=today` | Standard route push | None |
| Streak label | Push to `/progress` | Standard route push | None |

### Hover States (`@media (hover: hover)` only)
| Element | Hover treatment |
|---------|----------------|
| Routine card | Border shifts from `border` to `border-strong`; cursor `pointer` |
| Day chip (clickable) | Background shifts from `surface` to `surface-muted` |
| Buttons | Per `<Button>` component variants — handled by design system |

### Focus States
| Element | Focus-visible treatment |
|---------|------------------------|
| All interactive elements | 2px ring in `focus-ring` token, 2px offset from element, no outline replacement |
| Modal trigger → modal | Focus moves to first focusable element in modal on open; returns to trigger on close |

### Keyboard
- Tab order: top nav → page content (top to bottom, left to right) → bottom/sidebar nav.
- Skip-to-content link present (visible on focus, hidden by default).
- No custom keyboard shortcuts on this screen.

### Animations
- Card mount: fade in over `--duration-short` (200ms), `--ease-standard`.
- Skeleton-to-content: crossfade `--duration-short`.
- Modal / sheet open (when applicable): `--spring-snappy` from `team/ui-ux/skills/web-design-system.md` motion tokens — physical-feeling slide, not a cubic-bezier slide.
- Reduced motion (`prefers-reduced-motion: reduce`): no shimmer, instant crossfade, springs replaced with instant appearance. See `team/ui-ux/skills/web-accessibility.md` → Motion and Animation for the canonical alternatives table.
- See `team/ui-ux/skills/web-design-system.md` for the full motion-token reference (durations, easings, springs).

### Optimistic Updates
- "Mark complete" toggles on a session (different screen) use `useOptimistic`; this screen does not need any.

---

## Accessibility

### Semantic HTML
- Page wrapped in `<main>` (single per page).
- Hierarchy: H1 = "Today" (page title), H2 = section titles (none on this screen — content is the single primary section), H3 = card title.
- Week strip is `<nav aria-label="This week">` containing an unordered list of day links.
- Streak label is `<aside>` (complementary information).

### Landmark Roles
| Element | Role | Label |
|---------|------|-------|
| Top nav | `<header>` | (implicit) |
| Primary content | `<main>` | (implicit) |
| Week strip | `<nav>` | `aria-label="This week"` |
| Streak label | `<aside>` | (implicit) |
| Bottom/sidebar nav | `<nav>` | `aria-label="Primary"` |

### Reading Order (logical DOM order)
1. Skip-to-content link (visible on focus only)
2. Top nav (logo, profile)
3. H1 "Today"
4. Routine card → start session button
5. Week strip (Mon → Sun)
6. Streak summary
7. Bottom/sidebar nav

### Live Regions
- Action feedback (e.g., "Session started"): `aria-live="polite"` toast region rendered in root layout. Spec does not redefine.
- No `aria-live="assertive"` on this screen.

### Color Contrast
All text/background pairs verified against semantic tokens; spec defers to `team/ui-ux/skills/web-accessibility.md` for the contrast targets and audit process. Any unique pair not covered by tokens is called out here.

### Reduced Motion
- Skeleton shimmer: disabled.
- Card mount fade: replaced with instant appearance.
- Route transitions: no per-screen animation; default behavior.

### Touch Targets
All clickable elements at minimum 44×44 CSS pixels on touch viewports. Day chips (visually 32×32) have padded hit areas to 44×44.

---

## Responsive Behavior

### Critical Viewports
| Viewport | Dimensions | Required? | Notes |
|----------|-----------|-----------|-------|
| Phone portrait | 375 × 667 | Always | Contract — all elements present, single-column, bottom nav. |
| Phone landscape | 667 × 375 | Required *unless* explicitly N/A (mark with reason) | Short viewport (375px tall, ~110px when keyboard open) — verify forms, modals, hero CTAs survive. |
| iPad portrait | 768 × 1024 | When tablet support is in scope | Sidebar nav appears (`md`); bottom nav hides. |
| iPad landscape | 1024 × 768 | If iPad portrait is required | Two-column main becomes comfortable; container queries on cards expand. |
| Desktop | 1280 × 800 | Always | Page chrome at full width; comfortable multi-column layouts. |

For this screen, landscape phone is **N/A — N/A explanation here** (e.g., "form-only screen with on-screen keyboard; landscape forms route to `/onboarding/[step]/landscape-redirect` which presents the same step in a portrait-friendly modal"), or "verified — same layout, vertical rhythm tightened to `gap-3`."

### Page-Chrome Breakpoints
| Breakpoint | Change |
|------------|--------|
| `< md` | Bottom nav visible, top nav shows hamburger + logo only |
| `≥ md` | Sidebar nav visible, top nav shows logo + horizontal links, bottom nav hidden |

### Component-Driven Layout
- `<RoutineCard>` and `<WeekStrip>` are container-queried — they adapt to whatever column they're placed in. The spec does not pin them to viewport breakpoints.

### What's Verified at Each Viewport
- **Phone portrait (375 × 667)**: all states (content / loading / empty / error). Touch targets verified at 44×44 minimum.
- **Phone landscape (667 × 375)**: form-state survives with on-screen keyboard open (≥ 110px content visible above keyboard). Bottom sheets either swap to full-screen route or are explicitly noted as N/A. Hero CTAs reachable without scroll.
- **iPad portrait (768 × 1024)**: sidebar nav appears as designed; container queries on cards confirmed to adapt; touch targets remain at 44×44 (no hover-only affordances).
- **iPad landscape (1024 × 768)**: two-column main layout active; touch sizing preserved.
- **Desktop (1280 × 800)**: content + loading. Empty and error inherit layout.

---

## Performance

### LCP Element
- Routine card title (`text-h3`). Optimize by ensuring the routine query doesn't block initial paint — the `<Suspense>` boundary streams it; the rest of the page renders immediately.

### Suspense Boundaries
- One per Server Component that awaits data. Skeletons match content layout to avoid CLS.

### Dynamic Imports
- None on this screen — all components are above the fold or near-instantly visible.

### Images
- No images on the default content state. If a routine card preview thumbnail is added later, use `next/image` with explicit `width`/`height`, `priority` only on the LCP element.

### Web Vitals Targets
- LCP < 2.5s on 4G/Moto G4 baseline.
- INP < 200ms.
- CLS < 0.1 (skeleton-to-content sized identically).

---

## Component Inventory

| Component | Location | Status |
|-----------|----------|--------|
| `<Button>` | `components/ui/button.tsx` | exists |
| `<Card>` (used by RoutineCard) | `components/ui/card.tsx` | exists |
| `<DayChip>` | `components/ui/day-chip.tsx` | needs-component (request UIUX-COMP-014) |
| `<PageHeader>` | `components/shell/page-header.tsx` | exists |
| `<RoutineCard>` | `features/routines/components/routine-card.tsx` | new — feature-scoped, not design-system |
| `<WeekStrip>` | `features/routines/components/week-strip.tsx` | new — feature-scoped |
| `<StreakSummary>` | `features/streak/components/streak-summary.tsx` | new — feature-scoped |
| `<RoutineCardSkeleton>` | `features/routines/components/routine-card.skeleton.tsx` | new — paired with RoutineCard |

Component requests with status `needs-component` must have a corresponding entry in `knowledge-base/ui-component-requests.md` before this spec is filed.

---

## Open Questions
- [Tag the agent who can answer — e.g., "PM: Should the empty state show a video preview of routine generation, or a static illustration? Affects asset pipeline."]
- [e.g., "Content: Empty-state body copy budget is 120 chars — does the current draft fit?"]
```

## Spec Quality Checklist

Before filing the spec for Developer handoff, every box must be checked:

- [ ] **Route Context** complete (path, route group, layout chain, auth gate, server/client default, loading/error/not-found, metadata, caching, revalidation)
- [ ] **Two wireframes** (mobile 375px + desktop 1280px) per `web-wireframe-methodology.md`
- [ ] **Annotation table** has a row for every visual element in both wireframes
- [ ] **Layout structure** describes the React component tree, identifies Server vs. Client islands
- [ ] **Container query scopes** named for any container-queried components
- [ ] **Scroll behavior** explicitly noted (sticky vs fixed vs scrolls)
- [ ] **Data sources table** lists every dynamic field, source function, layer, cache strategy, fallback
- [ ] **Copy table** lists every text element with character limit, token, and owner — final copy from Content or placeholder
- [ ] **States** covered: loading, content, empty, error, plus tier and permission variants where applicable
- [ ] **Interactions table** specifies action, transition, and pending UI for every interactive element
- [ ] **Hover states** explicitly noted (with `@media (hover: hover)` scoping)
- [ ] **Focus states** specified (focus-ring token + offset, focus order on modal open/close)
- [ ] **Keyboard order** documented; skip-to-content noted; custom shortcuts listed (or "none")
- [ ] **Animations** listed with token-named easing/duration; reduced-motion alternatives explicit
- [ ] **Semantic HTML** structure noted (landmark roles, heading hierarchy, list semantics)
- [ ] **Live region** behavior documented (or "none")
- [ ] **Touch targets** confirmed at 44×44 minimum on touch viewports
- [ ] **Critical viewports** named: 375 portrait + 667 × 375 landscape (or N/A with reason) + 768 / 1024 iPad if in scope + 1280 desktop
- [ ] **PPR decision marked**: static-shell-vs-dynamic-island scope listed in Route Context, or "fully dynamic — every byte is per-user" with reason
- [ ] **Forced-colors verified**: Windows High Contrast Mode tested (DevTools emulate `forced-colors: active`); every interactive element distinguishable without color
- [ ] **Empty-state coverage per origin**: never-had / you-emptied / no-search / filter-emptied / permission-denied — each addressed or marked N/A with reason
- [ ] **Error categories applicable identified**: validation / recoverable transient / recoverable persistent / irrecoverable / server-broken / maintenance / offline — each addressed or marked N/A
- [ ] **Conditional UI passkey configured** for any sign-in / sign-up surface: email field has `autocomplete="username webauthn"`; passkey-as-button is fallback only
- [ ] **LCP element** identified, Suspense boundaries placed, image sources specified
- [ ] **Component inventory** complete; missing components have open requests
- [ ] **Open questions** section explicitly addresses every undecided point — no `[TBD]` left elsewhere
- [ ] **Tokens only** — no raw hex, no pixel values, no default-Tailwind palette utilities anywhere in the spec
- [ ] **Three-second test passed** on the wireframes
- [ ] **Squint test passed** on the wireframes

If any box is unchecked, the spec is not ready for handoff.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **Wireframe without a spec wrapper.** A `wireframe.md` file with ASCII and nothing else. | The Developer has nowhere to look for tokens, data sources, states, or interactions — those decisions get made ad-hoc in code. | Always wrap the wireframe in a screen spec. The wireframe is one section of the spec, not the deliverable. |
| **Spec without route context.** "It's a page somewhere." | The Developer has to make architectural decisions (route group, layout, auth gate, loading/error files) without designer input. | Fill the Route Context section completely for every route-level spec. |
| **Spec that ignores the server/client boundary.** No mention of Server vs. Client Components. | The Developer guesses, often defaulting too far client-side. The page becomes a client tree wrapping a tiny server fetch. | Mark Client islands explicitly in the layout structure. Default everything else to Server. |
| **Final copy in the spec without Content agent involvement.** UI/UX writes the empty-state body copy. | Copy ownership is fragmented; brand voice drifts; revisions go to the wrong agent. | Mark copy cells as "[Content agent to provide]" with character limits. Final copy lands in revisions. |
| **Hex colors and pixel values in the spec.** `background: #F5F5F7`, `padding: 24px`. | Bypasses the token system; the spec becomes a second source of truth that drifts from `tokens.css`. | Reference semantic tokens by name. If no token fits, it's the signal to add one — not to inline a value. |
| **States as an afterthought.** Only the content state is wireframed; loading is "use a spinner," empty is "we'll figure it out." | Empty and error are the screens users hit when things go wrong; designing them late guarantees a poor experience. | All four states wireframed (or noted as "same as content"). Skeleton matches content layout. |
| **No accessibility section.** "The Developer will handle a11y." | A11y is a design decision before it's an implementation decision. Tab order, focus on modal open, live regions, semantic structure — these are spec-level calls. | Fill the Accessibility section. Defer implementation details to `team/developer/skills/web-accessibility.md`, but make the design intent explicit. |
| **Responsive behavior described in pixels.** "At 768px, the sidebar appears. At 1024px, the grid becomes 3 columns. At 1280px, padding increases by 8px." | Over-specifies what responsive primitives handle automatically; under-specifies the page-chrome decisions that actually matter. | Name the page-chrome breakpoints (when sidebar appears, when nav collapses) and mark which components are container-queried. Defer the rest to `web-responsive-patterns.md`. |
| **Component inventory missing requests.** A new component is named in the layout but has no entry in `ui-component-requests.md`. | The Developer can't build the screen; the request isn't visible to the Founder. Sprint stalls. | Every `needs-component` row must have a request open before the spec is filed. |
| **Reusing one spec for two screens.** "Today and Plan are similar — one spec covers both." | They diverge as soon as someone edits one of them; the spec stops describing either accurately. | One spec per logical screen. Shared concerns (layout, components) live in their own specs and are referenced. |
| **Spec that grows with revisions instead of being rewritten.** "Old layout for v1, new layout for v2, …" sections accumulate. | The spec becomes archaeology. Future readers can't tell what's current. | The spec is current truth only (Rule 15 — durability discipline). History lives in git and the handoff revision log. |

## Output

A completed screen spec is committed to `knowledge-base/design-specs/<screen-name>.md` (one file per screen). It is referenced from the corresponding handoff entry in `knowledge-base/agent-requests.md` and from the active sprint task that produced it. Component requests embedded in the spec must have matching open entries in `knowledge-base/ui-component-requests.md`.

## Principles

1. **The spec is the contract.** It says what the screen is, what data it consumes, what it does, how it adapts, and how it stays accessible. The Developer reads it once and builds. **If the Developer needs to ask a clarifying question, the spec failed.** That bar is what makes this skill load-bearing — additive completeness ("we covered all the sections") is not enough. The discipline is what gets *cut*: every line in a spec is a line the Developer reads, so each must earn its place by removing ambiguity, not by demonstrating thoroughness.

2. **The spec keeps pace with the platform.** When the platform ships a new primitive that affects design intent — Partial Prerendering, View Transitions, intercepting routes, container queries, conditional-UI passkeys, locale routing, forced-colors — the spec template absorbs it as a new decision the spec must surface. A template that's a year behind the platform is a template that produces year-behind designs. Audit the template against the current platform capabilities at every wave.

3. **Wireframe + tokens + states + interactions + accessibility, in one file.** Splitting these across multiple files guarantees drift. The spec is one markdown document, version-controlled, reviewable in PRs, owned by UI/UX.

4. **Server-first, client-as-island, static-where-possible.** The spec marks the server/client boundary explicitly. Default to Server Components; Client Components are interactive islands inside server-rendered shells. With Partial Prerendering, mark the static shell vs. dynamic islands too — that decision affects perceived performance and is design-level, not implementation-level.

5. **Tokens, never values.** Every color, every spacing, every type size, every radius — referenced by token name. Raw values in a spec are defects, regardless of how convenient they feel in the moment.

6. **Two viewports are wireframed; landscape and tablet are verified, not redrawn.** Wireframes ship at 375 portrait and 1280 desktop only — that's the contract with `web-wireframe-methodology.md`. Mobile landscape (667×375), iPad portrait (768×1024), and iPad landscape (1024×768) are *verified* in the Responsive Behavior section against the responsive primitives — not given their own ASCII wireframes. Adding a wireframe per viewport produces drift; verifying-against-primitives produces accuracy. The container-queried primitives in `team/ui-ux/skills/web-responsive-patterns.md` handle the in-betweens by construction.

7. **Accessibility is a design decision, not an implementation chore.** Reading order, landmark roles, focus management, live region behavior, reduced-motion alternatives, forced-colors handling — these are spec-level calls that the Developer implements. The split between this skill and `team/developer/skills/web-accessibility.md` is intent (here) vs. mechanism (there).

8. **States are part of the design.** Loading, empty, error, tier and permission variants — each is wireframed or explicitly marked as identical. Empty has at least five distinct origins (see `team/ui-ux/skills/web-empty-error-and-edge-states.md`); a single empty-state component for all of them is a defect. A spec that only addresses the happy path is half a deliverable.

9. **Owner per cell — push it everywhere.** Copy belongs to Content. Components belong to UI/UX (with Founder approval for new requests). Data shapes and route mechanics belong to Developer. The spec assigns ownership per row in *every* applicable table — copy table, data sources table, component inventory, interactions table. There is no "we'll figure it out." When responsibility is unassigned, work falls between agents and the gap shows up in the shipped product.

10. **The spec is current truth only.** Per the Muster durability discipline, the spec describes the screen as it currently is. No "previously" sections, no revision-history annotations inline, no decision-archaeology. History lives in git, in the handoff revision log, and in `decision-log.md`. A spec that grows revisions instead of being rewritten becomes archaeology.
