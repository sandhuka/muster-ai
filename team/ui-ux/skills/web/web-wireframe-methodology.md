# Web Wireframe Methodology

## Purpose
Define the wireframe format and production process for web screens: text-based ASCII layouts (version-controllable, reviewable, diffable), the two-viewport rule (mobile + one desktop), page-chrome notation, scroll-behavior annotation, state coverage, and the discipline that separates a wireframe from a finished spec. A wireframe is the spatial expression of a hierarchy decision — it is *never* the first artifact for a screen. See `team/ui-ux/skills/web-content-hierarchy.md` for the hierarchy exercise that must precede wireframing. See `team/ui-ux/skills/web-screen-specification.md` for the full screen spec that wraps a wireframe with annotations, data sources, states, and accessibility. See `team/ui-ux/skills/web-design-system.md` for the tokens wireframe annotations reference. See `team/ui-ux/skills/web-responsive-patterns.md` for the responsive primitives the layouts assume. Target: **product screens for web (Next.js App Router, React 19+), reviewable in pull requests, handed off to the Developer agent**.

## The Anchor: Monospace Forces Hierarchy Clarity

Wireframes exist to make the hierarchy decision visible — to commit, on the page, to *what each element is* and *where it sits* before any visual treatment muddies the picture. **Monospace ASCII is the right tool for this job because it removes every variable that lets a designer hide.** Figma's strength — fidelity — is the wireframing weakness. A high-fidelity mockup hides a flat hierarchy behind tasteful color and typography; a low-fidelity ASCII box can't. If the hierarchy is wrong, the wireframe will look wrong, immediately, to anyone who reads it.

This is the load-bearing insight. The format conventions, viewport rules, and annotation tables that follow are downstream of it. If the project has a hierarchy decision and the wireframe expresses it spatially, the wireframe is doing its job — even if the ASCII is rough. If the project has decoration but no hierarchy, no amount of polish saves the wireframe.

Image-based wireframes (Figma frames embedded as PNGs, Sketch exports) fail on every axis a product team cares about — but the most important failure is that *they let the hierarchy stay hidden*:

| Concern | Image wireframe | ASCII wireframe |
|---------|-----------------|-----------------|
| **Forces hierarchy clarity** | hides behind detail and color | impossible to hide — every element must be named |
| Reviewable in a PR | "open Figma to see context" | inline diff, comments next to lines |
| Diffable across versions | binary blobs | line-by-line diff |
| Searchable by future contributors | no | grep |
| Authored by Claude / scripts | no | yes |
| Stays in sync with the spec it describes | drifts independently | one file |
| Survives a tool migration | no | yes |

This is the same discipline the iOS UI/UX skills enforce — ASCII isn't a degraded substitute for Figma; it's the right tool for *this* job. Visual mockups still happen later — for cross-functional review, for marketing, for high-fidelity polish. They're downstream of the wireframe, not a replacement for it.

### When ASCII Is the Wrong Tool

A small set of screens are intrinsically non-rectangular and don't fit ASCII conventions: canvas-based tools (a drawing app's canvas), video / map / 3D viewers (the primary surface is media, not laid-out elements), and interactive playgrounds (a code editor's central pane). For these:

- The *page chrome* (toolbars, panels, buttons around the canvas) is wireframed as ASCII normally.
- The *canvas surface itself* is described prose-first: what occupies it, what gestures it supports, what changes on interaction. Optionally a single annotated image (committed to the spec folder) for the canvas state.
- The annotation table covers every chrome element and every canvas-level interaction.

Don't try to ASCII-draw the inside of a video player or a map. Acknowledge the surface and move on.

## What the Examples Look Like (Good vs. Bad)

A clear hierarchy in ASCII looks like:

```
┌────────────────────────────────┐
│  Today                         │  ← H1, primary
│                                │
│  ┌──────────────────────────┐  │
│  │  Routine title           │  │  ← hero card, primary
│  │  Helper context          │  │
│  │                          │  │
│  │  ▶ Start session         │  │  ← single primary CTA
│  └──────────────────────────┘  │
│                                │
│  Streak: 14 days               │  ← caption, tertiary
└────────────────────────────────┘
```

A flat hierarchy looks like:

```
┌────────────────────────────────┐
│ Logo            Settings  Help │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐   │  ← four equal cards, no anchor
│ │Card│ │Card│ │Card│ │Card│   │
│ └────┘ └────┘ └────┘ └────┘   │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐   │  ← four more equal cards
│ │Card│ │Card│ │Card│ │Card│   │
│ └────┘ └────┘ └────┘ └────┘   │
│ Banner: Upgrade to Pro!        │  ← banner competes with cards
│ Banner: New feature available  │  ← second banner competes too
└────────────────────────────────┘
```

The flat-hierarchy wireframe is the visible failure: nothing is primary, eight cards compete equally, two banners compete with the cards, no element answers "what should the user do?" The fix is upstream — the hierarchy exercise (`team/ui-ux/skills/web-content-hierarchy.md`) wasn't done. Demote six cards, kill one banner, promote one card to a hero.

A decorated wireframe looks like:

```
╔════════════════════════════════╗
║ ✨ Logo ✨    [Settings] ★Help ║  ← decoration without hierarchy
║ ┌── HERO ──┐ ┌── ALSO HERO ──┐║  ← labeled "hero" twice
║ │ ╭ ✨ ╮   │ │  💎 Premium   │║
║ │ ╰─────╯  │ │  ↓ Try Now ↓  │║
║ └──────────┘ └───────────────┘║
║ ┌── SECONDARY ──┐ ┌── ALSO ──┐║  ← labeled "secondary" twice
║ │ Important     │ │ Also imp │║
║ └───────────────┘ └──────────┘║
╚════════════════════════════════╝
```

Two heroes is no hero. Decoration (`✨`, `★`, `💎`, double-line borders) compensates for missing hierarchy and makes it worse — the eye has even more competing attractors. The fix: pick the one hero. Strip the decoration. The clean wireframe is the strong wireframe.

## When the Wireframe is Ready to Start

Three preconditions, in order. Skipping any of them produces a wireframe that has to be redone.

1. **Hierarchy decided.** The output of `team/ui-ux/skills/web-content-hierarchy.md` — primary, secondary, tertiary, hidden — exists for the screen. The wireframe expresses this ranking spatially.
2. **Page-chrome decided.** Whether the screen has a top nav, sidebar, footer, or none. This is page-shell territory, decided once per app surface (marketing pages, app pages, onboarding) — not per screen.
3. **Critical-viewport set decided.** For most product screens, this is two viewports: 375px (smallest target — iPhone SE / 11) and 1280px (standard desktop). Onboarding-only or marketing-only screens may differ. Document the set; don't wireframe four sizes by default.

If any precondition is missing, fix that first. Wireframing without hierarchy is decoration; wireframing without a viewport target is an exercise in stalling.

## The Two-Viewport Rule

A web wireframe documents two viewports: **the smallest target and one desktop.** That's it. If the design is correct at both endpoints, the responsive primitives in `web-responsive-patterns.md` (auto-fit grids, container queries, fluid sizing) handle everything in between.

| Viewport | Width | Why |
|----------|-------|-----|
| **Mobile** | 375px | The contract. Smallest device the product supports; the layout must be correct here without any responsive adaptation having loaded. |
| **Desktop** | 1280px | The most common laptop size. Confirms the layout expands gracefully and uses the additional space deliberately. |

When you might add a third viewport:

- The page chrome changes between phone and desktop in a non-obvious way that needs to be specified (e.g., a sidebar appears at `md` 768px). Add a 768px wireframe for the sidebar transition only — not for content layout.
- The page is a marketing page where designed art-direction differs significantly across breakpoints. This is rare for product UI and shouldn't be the default.

When you should *not* add more viewports: "to be thorough." Two viewports + the responsive primitives is the contract. More viewports means more drift, more revision, and false precision. The Developer agent reads the responsive skill to handle the in-between sizes.

## ASCII Wireframe Format

Use box-drawing characters and consistent column widths. Width tracks the viewport — 32 columns for mobile (375px ≈ ~32 monospace cols at the typical reading scale), 80 columns for desktop. The numbers don't have to be exact; the relative proportions matter.

### Mobile (375px) — 32 columns

```
┌──────────────────────────────┐
│ ☰  Logo              👤 Acct │  ← top nav (sticky)
├──────────────────────────────┤
│                              │
│  Today                       │  ← H1 (text-h1, primary)
│                              │
│  ┌────────────────────────┐  │
│  │                        │  │  ← hero card (primary)
│  │  Routine title         │  │
│  │  Helper context line   │  │
│  │                        │  │
│  │  ▶ Start session       │  │  ← primary CTA
│  │                        │  │
│  └────────────────────────┘  │
│                              │
│  This week                   │  ← H2 (text-h2, secondary)
│                              │
│  ┌────────┐ ┌────────┐       │
│  │ Mon ✓  │ │ Tue    │       │  ← day chips (secondary)
│  └────────┘ └────────┘       │
│  ┌────────┐ ┌────────┐       │
│  │ Wed    │ │ Thu    │       │
│  └────────┘ └────────┘       │
│                              │
│  Streak: 14 days             │  ← caption (tertiary)
│                              │
├──────────────────────────────┤
│  Today  Plan  Progress  Me   │  ← bottom nav (sticky)
└──────────────────────────────┘
```

### Desktop (1280px) — 80 columns

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Logo               Today  Plan  Progress                          👤 Account │  ← top nav (sticky)
├────────────────┬─────────────────────────────────────────────────────────────┤
│                │                                                             │
│  ▸ Today       │  Today                                                      │
│    Plan        │                                                             │
│    Progress    │  ┌──────────────────────────┐ ┌──────────────────────────┐  │
│    Settings    │  │                          │ │                          │  │
│                │  │  Routine title           │ │  This week               │  │
│  ──────────    │  │  Helper context line     │ │                          │  │
│                │  │                          │ │  Mon ✓  Tue   Wed        │  │
│  Streak        │  │  ▶ Start session         │ │  Thu    Fri   Sat   Sun  │  │
│  14 days       │  │                          │ │                          │  │
│                │  └──────────────────────────┘ └──────────────────────────┘  │
│                │                                                             │
│                │  ┌────────────────────────────────────────────────────────┐ │
│                │  │  Recent activity                                       │ │
│                │  │  ─────────────────                                     │ │
│                │  │  Tue  – Session completed  (24m)                       │ │
│                │  │  Mon  – Session completed  (28m)                       │ │
│                │  │  Sun  – Skipped — see why                              │ │
│                │  └────────────────────────────────────────────────────────┘ │
│                │                                                             │
└────────────────┴─────────────────────────────────────────────────────────────┘
   sidebar (fixed)            main (scrolls)
```

### Notation Conventions

| Symbol | Meaning |
|--------|---------|
| `┌─┐ │ │ └─┘` | Container (card, section) |
| `▶` | Primary CTA |
| `▸` | Active nav item |
| `☰` | Hamburger / menu trigger |
| `✓` | Completed state |
| `▼` | Disclosure / dropdown trigger |
| `◯` `●` | Radio off / on |
| `☐` `☑` | Checkbox off / on |
| `~~~~` | Skeleton placeholder (loading) |
| `[label]` | Form input (single line) |
| `[label………]` | Textarea (multi-line) |
| `← arrow comment` | Inline annotation pointing to the line |

These are conventions, not enforced syntax. The point is consistency within a project, not adherence to a global notation. The annotation table below is where the precise meaning lives.

## Annotation Table

Every wireframe ships with a numbered annotation table. The wireframe shows *where*; the table specifies *what*.

```markdown
### Annotations

| # | Element | Type | Token | State coverage | Notes |
|---|---------|------|-------|---------------|-------|
| 1 | Top nav | Sticky bar | `bg-surface`, `border-border` | persistent | Hides on scroll-down past 100px on mobile only |
| 2 | "Today" heading | Text | `text-h1`, `text-text` | persistent | — |
| 3 | Routine card | Container | `bg-surface-raised`, `rounded-card`, `border-border` | content / loading skeleton / empty | Empty: shows generation CTA |
| 4 | "Start session" button | Primary CTA | `<Button intent="primary" size="lg">` | enabled / disabled when generating | Disabled state shown as ghost |
| 5 | Day chip | Pill | `<DayChip>` (request UIUX-COMP-014) | active (today) / completed / upcoming / missed | Component request open |
| 6 | Streak caption | Text | `text-caption`, `text-text-muted` | hidden if streak == 0 | — |
| 7 | Bottom nav (mobile) / Sidebar nav (desktop) | Nav | `<AppNav>` | persistent, indicates current route | Same component, different layout root |
```

The annotation table is the contract with the Developer. Wireframe ambiguity dies here. Every numbered element gets a row; if a wireframe has more elements than annotations, finish the table.

## Page Chrome Notation

Page chrome — the parts of the screen that aren't the screen-specific content — has its own conventions. Decide once per app surface, then refer to it.

| Chrome element | Decisions to lock |
|----------------|-------------------|
| **Top nav** | Sticky? Hides on scroll? Background (transparent vs surface)? Mobile collapse to hamburger at which breakpoint? |
| **Sidebar** | Fixed or scrolling with content? Collapsible? At which breakpoint does it appear? Width? |
| **Footer** | Always present or only on marketing pages? Sticky-to-bottom on short pages? Multi-column on desktop? |
| **Bottom nav (mobile)** | Mutually exclusive with top nav for primary navigation? Visible on which routes (often hidden during onboarding and active sessions)? |
| **Modals / sheets** | Phone treatment is bottom sheet; desktop is centered dialog. See `team/ui-ux/skills/web-interaction-patterns.md`. |

Document the chrome decisions in the spec's Navigation Context section (template in `web-screen-specification.md`), not redrawn in every wireframe. The wireframe just shows the chrome's spatial relationship to the content for orientation.

## Scroll Behavior Notation

Web scroll behavior is more varied than iOS — fixed/sticky elements, modal vs page scroll, sidebar that scrolls independently of main, etc. Annotate scroll explicitly:

```markdown
### Scroll Behavior
- Page scroll: vertical, on the main column.
- Top nav: sticky on desktop; hides-on-scroll-down / shows-on-scroll-up on mobile.
- Sidebar nav (desktop): fixed; does not scroll with main.
- Bottom nav (mobile): sticky; visible at all scroll positions.
- "This week" card: not pinned; scrolls with content.
- Modals / sheets: trap scroll inside the modal; background does not scroll.
```

Three discipline rules:

- **Use `position: sticky`, not `position: fixed`,** for elements that should follow scroll within a container. `fixed` is reserved for genuinely viewport-anchored elements (toasts, FABs, mobile bottom nav).
- **Document scroll trapping** for modals and sheets explicitly. Implementation lives in the interaction-patterns skill, but the wireframe declares intent.
- **No infinite scroll for primary content** unless the design explicitly calls for it. Pagination or "load more" controls are usually correct; infinite scroll breaks the back button, scroll position restoration, and footer reachability.

## States in Wireframes

Every screen needs at least four states wireframed (or noted as "same as default"):

| State | When |
|-------|------|
| **Content (default)** | The happy path — data loaded, normal user, populated. The primary wireframe. |
| **Loading** | Initial fetch, skeleton placeholders preserving layout. Not a spinner over the page. |
| **Empty** | Data fetched but nothing to show. One sentence + one CTA — never a wall of explanation. |
| **Error** | Data fetch failed. Recoverable: retry CTA. Non-recoverable: clear message + escape route. |

Optional, when applicable:

- **Permission-gated state** (free vs. paid, anonymous vs. logged-in)
- **Form states** (untouched, validating, submitted, server error)
- **Read-only state** (admin viewing another user's screen)

Wireframe each state inline in the spec, not as a separate file. A state that's "same as content with the X panel hidden" can be noted in one line — but it must be acknowledged.

## What Goes in the Wireframe vs. What Goes in the Spec

The wireframe is one section of the screen spec, not the whole spec. Resist putting everything into the ASCII drawing.

| Belongs in the wireframe | Belongs in the surrounding spec |
|--------------------------|---------------------------------|
| Spatial relationships of elements | Token names for each element |
| Approximate proportion (small / medium / hero) | Exact size tokens (`text-h1`, `h-12`) |
| Containment (what's inside what) | Component names from the design system |
| Scroll boundaries | Scroll behavior details (sticky vs fixed, trap vs page) |
| Two viewports (mobile + desktop) | Responsive behavior in between (defer to `web-responsive-patterns.md`) |
| State labels (default / loading / empty / error) | State definitions (when each applies, transitions) |
| Placeholder text length | Final copy (Content agent's deliverable) |

A wireframe with token names, hex colors, and exact spacings inside the ASCII is doing the spec's job badly. Keep them separated.

## The Wireframe Completeness Checklist

Before filing the wireframe section of a screen spec for review:

- [ ] **Hierarchy exercise complete** — primary/secondary/tertiary called out before wireframing started
- [ ] **Two viewports** — mobile (375px) and desktop (1280px) both wireframed
- [ ] **Page chrome shown** — top nav, sidebar, footer, bottom nav as applicable
- [ ] **Annotation table** — every visual element has a numbered row
- [ ] **Scroll behavior** — sticky/fixed/scrolls explicitly noted for every chrome and major section
- [ ] **States covered** — content + loading + empty + error all present (or noted as identical)
- [ ] **Tokens referenced** — annotation rows use semantic token names from `web-design-system.md`, never raw values
- [ ] **Component references** — design-system components named (`<Button intent="primary">`); new components flagged with a request ID
- [ ] **Placeholder copy** — copy is placeholder with character limits, not final (Content agent owns final)
- [ ] **Touch targets verified** — every tap target on mobile is at least 44×44 (annotated if visually smaller)
- [ ] **Three-second test passed** — looking at the wireframe for three seconds, the screen's purpose is clear
- [ ] **Squint test passed** — the primary content is identifiable when blurred / scaled down (proves hierarchy)

If any checkbox isn't ticked, the wireframe isn't ready for handoff.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **Image wireframes pasted as screenshots.** A PNG export of a Figma frame committed to the repo. | Not reviewable in PRs, not diffable, drifts from the spec, can't be authored or modified by anyone without the source tool. | ASCII wireframe in the markdown spec. Visual fidelity comes later in mockups. |
| **Wireframing before hierarchy.** Drawing boxes to "see what feels right." | Decoration is determining hierarchy. The wireframe will need to be redone after hierarchy gets clarified. | Run the content-hierarchy exercise first. The wireframe is the spatial expression of that decision. |
| **Wireframing four viewports.** Mobile, tablet, small laptop, large desktop. | False precision — two of them are the same layout, one is the same with subtle padding shifts. The team starts maintaining four sources of truth. | Two viewports (mobile + desktop). Use responsive primitives to handle the rest. |
| **Final copy in the wireframe.** "Welcome back, Kanwar! Today's routine includes a 24-minute mobility session focusing on hip flexors." | Final copy belongs to the Content agent and shouldn't be in a wireframe under review for layout. The wireframe gets revised every time copy gets revised. | Placeholder text with character limits — `[Heading: 30 char max]`, or `Lorem ipsum sized to budget`. |
| **Hex colors and pixel values inside the ASCII.** `Background: #F5F5F7, padding: 24px`. | The ASCII is for spatial relationships; tokens belong in the annotation table. Mixing them clutters the wireframe and creates two sources of truth for the tokens. | Annotation table references tokens. ASCII shows shape only. |
| **No empty / error / loading states.** Only the content state wireframed. | Empty and error are the states users hit when something goes wrong — designing them as an afterthought guarantees a poor experience. | Wireframe all four states (content / loading / empty / error). At minimum, note "same as content" if accurate. |
| **Tertiary content cluttering the wireframe.** Six secondary cards, four banners, two sidebars all visible. | The wireframe communicates "this is what the screen looks like" — if the wireframe is cluttered, the screen will be cluttered. | Cut tertiary content to "behind progressive disclosure" or to "below the fold and acknowledged in the annotation table." |
| **Wireframe disconnected from spec.** A `wireframe.md` file separate from a `spec.md` file. | Two files, two truths, eventual divergence. | One spec file per screen, with the wireframe inline as a section. |
| **Marketing-style hero treatments inside product UI wireframes.** Big art-directed compositions for in-product screens. | Marketing patterns and product patterns are different — applying marketing density to product screens results in noisy, slow, conversion-shaped UI. | Product wireframes follow `web-content-hierarchy.md` rules; marketing wireframes can take more visual liberty. Different lanes. |
| **`position: fixed` for everything sticky.** Top nav, sidebar, footer all `fixed`. | `fixed` removes the element from the document flow entirely — content under it gets covered, focus and scroll restoration break, nested scroll containers don't behave correctly. | `position: sticky` is correct for everything that should follow scroll within a container. `fixed` only for genuinely viewport-anchored items (toasts, FABs). |
| **Modal designs that don't acknowledge the responsive shape.** A centered desktop modal sketched once and assumed to "shrink" on mobile. | Modals on phones should be bottom sheets, not shrunken centered dialogs. The shapes are different patterns, not the same pattern at different sizes. | Wireframe both — bottom sheet on mobile, centered dialog on desktop. Note the breakpoint where the shape switches. |

## Principles

1. **Wireframes are spatial decisions, not visual ones.** Color, weight, exact size — none of these go in a wireframe. The wireframe answers "where does it sit?" and "what's it next to?" Visual treatment is downstream.

2. **Two viewports, not four.** Mobile (375px) and desktop (1280px) is the contract. Responsive primitives handle the rest. False precision from four wireframes per screen creates more work than it prevents.

3. **Hierarchy precedes wireframe.** A wireframe is the spatial expression of a hierarchy decision that has already been made. Wireframing as a way to "discover" hierarchy means revising the wireframe later, when the hierarchy gets named.

4. **Text-based, in-repo, in-PR.** Wireframes diff, search, and ship like code. The discipline of monospace boxes forces clarity that visual fidelity can hide. Higher-fidelity mockups happen later, downstream of the wireframe.

5. **States are part of the wireframe.** The wireframe isn't done until empty, loading, error, and any tier or permission variants are addressed. The "happy path only" wireframe is half a deliverable.

6. **The annotation table is the contract.** The ASCII shows shape; the table specifies tokens, components, states, and notes. Both are required; neither is optional.

7. **The wireframe lives in the spec.** Not a separate file. The screen specification (`web-screen-specification.md`) wraps the wireframe with everything else the Developer needs. One file, one truth.
