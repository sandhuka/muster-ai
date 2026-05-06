# Web Responsive Patterns

## Purpose
Define how layouts adapt across viewports on the modern web: mobile-first methodology, container queries as the default (media queries as the exception), fluid type and spacing scales, intrinsic layout primitives, and the small set of patterns that cover 90% of responsive needs. This skill consumes the spacing and type tokens defined in `team/ui-ux/skills/web-design-system.md` — it never redefines them. See `team/ui-ux/skills/web-design-system.md` for the token system. See `team/ui-ux/skills/web-screen-specification.md` for how responsive behavior is documented in a spec. See `team/ui-ux/skills/web-accessibility.md` for tap-target sizing rules and reduced-motion fallbacks. See `team/developer/skills/web-modern-react.md` for component composition patterns the layouts use. Target: **modern evergreen browsers (2024+), Tailwind CSS 4+, CSS Grid + Subgrid, Container Queries (`@container`), `clamp()` and `min/max/clamp` for fluid sizing**.

## The Two Rules That Anchor Everything

**Rule 1 — Mobile-first, always.** Write base styles for the smallest viewport (≈360px wide). Larger viewports adapt by *adding* layout, not by *overriding* it. This is non-negotiable: 60%+ of product usage is on phones, and it's far easier to expand a working small layout than to retrofit a desktop layout into a phone.

**Rule 2 — Container queries by default, media queries by exception.** A component should respond to *the space it has been given*, not to *the size of the viewport*. A card placed in a sidebar should look like a sidebar card; the same card placed in a wide grid should look like a wide-grid card — without the component knowing or caring which page it's on. Media queries belong to the *shell* (page chrome, navigation placement, sidebar visibility). Container queries belong to the *components*.

If you find yourself reaching for `md:flex-row lg:grid-cols-3` inside a component, stop. That component now only works on the page it was designed for. Switch to `@container` so the same component composes correctly into any layout.

## Mobile-First as the Default

The order of every responsive declaration is: small first, then progressively additive.

```tsx
// Wrong — desktop-first, overrides cascade backward
<div className="grid grid-cols-3 gap-8 md:grid-cols-2 sm:grid-cols-1">

// Right — mobile-first, sizes add up the scale
<div className="grid grid-cols-1 gap-4 md:grid-cols-2 md:gap-6 lg:grid-cols-3 lg:gap-8">
```

What this discipline buys:

- **Specificity flows in one direction.** Reading top-to-bottom in a class string is the same as reading from small viewport to large.
- **The base styles work everywhere.** No required viewport for the layout to render correctly. A page that fails to receive any responsive overrides still works on every device.
- **Performance defaults to the constrained case.** Phone-sized layouts download fewer asset variants, render fewer columns, and parse less CSS upfront.

Apply this discipline at every level — page layouts, component variants, and even individual property values like `padding-inline: clamp(1rem, 4vw, 4rem)` (the small value comes first).

## Container Queries Are the Default

A modern component is a self-contained unit that adapts to the space it's placed in. Container queries make that possible. Use them anywhere a component might be reused at multiple sizes — which is *most* components.

```tsx
// components/ui/article-card.tsx
export function ArticleCard({ article }: { article: Article }) {
  return (
    <article className="@container">
      <div className="grid grid-cols-1 gap-3 @md:grid-cols-[1fr_2fr] @md:gap-6">
        <img
          src={article.imageUrl}
          alt=""
          className="aspect-video w-full rounded-card object-cover @md:aspect-square"
        />
        <div className="flex flex-col gap-2">
          <h3 className="text-h3 text-text">{article.title}</h3>
          <p className="text-body text-text-muted line-clamp-2 @md:line-clamp-4">
            {article.excerpt}
          </p>
        </div>
      </div>
    </article>
  );
}
```

This card is correct in three different layouts without any change:

| Container width | Layout result |
|-----------------|---------------|
| Narrow (placed in a sidebar, ~280px) | Image on top, video aspect, 2-line excerpt |
| Medium (placed in a 2-column grid, ~480px) | Image left, square aspect, 4-line excerpt |
| Wide (placed full-width on a marketing page, ~960px) | Same medium layout — wider container queries can refine further if needed |

Compare that to a viewport-keyed version (`md:grid-cols-[1fr_2fr]`), which would lay out the card the same way at a given viewport size *regardless* of where on the page it sits. A 280px sidebar at a 1280px viewport would still try to render a 2-column card. That's the bug container queries fix.

### Where Tailwind Container Queries Live

In Tailwind v4, the `@container` plugin is built in. Mark a parent with `@container`, then use container-prefixed variants (`@sm:`, `@md:`, `@lg:`) on descendants. Use *named* containers (`@container/card`) when nesting:

```tsx
<section className="@container/section">
  <div className="@md/section:grid @md/section:grid-cols-2">
    <ArticleCard /> {/* its own @container */}
  </div>
</section>
```

The component's container scope and the section's container scope don't interfere.

### When Media Queries Are Still Right

| Decision | Tool |
|----------|------|
| Should the page have a sidebar at all? | Media query (`md:flex-row`) — this is page chrome, not component layout |
| Should the navigation collapse to a hamburger? | Media query — top-level shell decision |
| Should this component card be 1-col or 2-col? | Container query — depends on where it's placed |
| Should the body font size scale with viewport? | Neither — use `clamp()` (see fluid scales below) |
| Should an animation respect motion preferences? | Media query (`@media (prefers-reduced-motion)`) — user preference, not layout |
| Should a hover state apply only on real pointers? | Media query (`@media (hover: hover)`) — input capability |
| Should the dark theme apply? | Class/attribute swap (see web-design-system.md) — not a query |

Rule: media queries answer "what kind of device or user is this?" and "what does the page shell look like?" Container queries answer "how much space does this component have?"

## The Breakpoint Set

Keep the breakpoint set small. Apple's iOS ships across many viewports with effectively two device-class breaks (compact vs. regular). Web products rarely need more than four:

| Token | Min width | Use |
|-------|-----------|-----|
| `sm` | 640px | Bigger phones / small tablets in portrait — sometimes nothing changes here |
| `md` | 768px | Tablets in portrait, smaller laptops opened narrowly — sidebar may appear |
| `lg` | 1024px | Standard desktop / laptop — full multi-column layouts come into play |
| `xl` | 1280px | Large desktop — opportunity for max-width containers, denser grids |

These match Tailwind's defaults and are intentional: they cover the device population without inventing custom intermediate breakpoints. **Do not add custom breakpoints** like `between-md-and-lg: 896px`. If a layout needs to gracefully bridge two breakpoints, use fluid sizing (next section), not a third breakpoint.

For container queries, define a parallel set scoped to component sizes:

| Token | Min container width | Typical use |
|-------|---------------------|-------------|
| `@xs` | 240px | Compact card in a sidebar — minimal layout |
| `@sm` | 320px | Card in a 3-column grid on a phone — modest expansion |
| `@md` | 480px | Card in a 2-column grid or wide sidebar — multi-element layout |
| `@lg` | 640px | Card spanning a full row — full information density |

The goal is the smallest set that captures meaningful layout breaks. Three or four is almost always enough.

## Fluid Scales (`clamp()` over Breakpoint Steps)

For type and spacing that should *gracefully* scale across viewport sizes — instead of jumping at each breakpoint — use `clamp(min, preferred, max)`. This is the modern correct pattern and replaces the older approach of declaring a different `font-size` at every breakpoint.

```css
/* Tier 1 primitive in tokens.css — fluid type scale */
:root {
  --text-display: clamp(2.5rem, 1.5rem + 4vw, 4.5rem);   /* 40 → 72 */
  --text-h1:      clamp(1.75rem, 1.4rem + 1.5vw, 2.5rem); /* 28 → 40 */
  --text-h2:      clamp(1.25rem, 1.1rem + 0.7vw, 1.75rem); /* 20 → 28 */
  --text-body:    1rem;        /* 16 — body stays fixed */
  --text-caption: 0.8125rem;   /* 13 — caption stays fixed */
}
```

Two non-obvious choices:

- **Body and caption stay fixed.** Body text should always be 16px because that's the WCAG-baseline minimum browsers ship for accessibility (zooming respects this). Scaling body text with viewport breaks user font-size preferences and accessibility zoom. Only display-class type scales.
- **The `preferred` value (`1.5rem + 4vw`) blends a constant and a viewport-relative term.** The constant prevents the text from collapsing to nothing on tiny viewports; the `vw` term lets it grow gracefully. Pure-`vw` sizing is fragile.

Spacing follows the same pattern for layout-level tokens:

```css
--space-page-gutter:     clamp(1rem, 0.5rem + 2vw, 3rem);   /* 16 → 48 */
--space-section-gap:     clamp(2rem, 1rem + 4vw, 6rem);     /* 32 → 96 */
```

Component-internal spacing (button padding, input height) does *not* scale fluidly — controls have target physical sizes for touch and accessibility. Only page-level rhythm scales.

### Container Query Units: Component-Fluid Scaling

When type or spacing inside a component should scale with *the component's container* rather than the viewport, use container query units (`cqi` for inline-size, `cqw` for width, `cqh` for height). These pair with `@container` to make a component's internals adapt to wherever it's placed:

```css
.card {
  container-type: inline-size;
}
.card-title {
  /* Title scales with the card's width — not the viewport's */
  font-size: clamp(1rem, 0.8rem + 1.2cqi, 1.5rem);
}
```

A card placed in a narrow sidebar gets a smaller title; the same card placed full-width gets a larger one — without any breakpoint. This is the modern correct expression of fluid sizing inside container-queried components. Browser support since 2023 across all evergreens. Use sparingly: most type should reference the design-system scale, not roll its own per-component sizing. Reach for `cqi`/`cqw`/`cqh` when a single component genuinely needs to look right at radically different sizes.

## Intrinsic Layout Primitives

Modern CSS layout has a small set of *intrinsically responsive* primitives that handle the majority of responsive needs without any media or container query at all. These compose into nearly any layout.

### Stack — vertical rhythm
```tsx
<div className="flex flex-col gap-4">{children}</div>
```
A flex column with consistent gap. Default for "things stacked vertically with breathing room." Use the spacing token (`gap-4`, `gap-section-gap`) — never raw px.

### Cluster — wrapping horizontal group
```tsx
<div className="flex flex-wrap items-center gap-2">{children}</div>
```
For tag groups, button rows, breadcrumbs — anything that should sit in a row but wrap when there's not enough space. No breakpoint needed; the wrap is intrinsic.

### Auto-Grid — columns that adjust to available width
```tsx
<div className="grid gap-6 [grid-template-columns:repeat(auto-fit,minmax(min(16rem,100%),1fr))]">
  {cards}
</div>
```
This grid creates as many columns as fit at a minimum 16rem wide, expanding each to fill leftover space. The inner `min(16rem, 100%)` handles the edge case where the container is narrower than 16rem (prevents overflow on tiny viewports). One declaration; works from 320px to 2000px without a single breakpoint.

For most card grids, this is what you want. Only fall back to explicit `grid-cols-1 md:grid-cols-2 lg:grid-cols-3` when the design *requires* a specific column count at a specific viewport.

### Sidebar — fixed sidebar with fluid content
```tsx
<div className="grid gap-6 md:[grid-template-columns:16rem_1fr]">
  <Sidebar />
  <Main />
</div>
```
Sidebar is a fixed width; main fills the remaining space. The single media query is page-chrome territory (whether to show a sidebar at all), which is a legitimate media-query use.

### Switcher — switch between row and column based on container size
```tsx
<div className="@container">
  <div className="flex flex-col gap-4 @md:flex-row @md:items-center">
    {children}
  </div>
</div>
```
The classic "stacks on phone, side-by-side on tablet" — but driven by container width, so it works anywhere the component is placed.

### Center — content with maximum readable width
```tsx
<div className="mx-auto max-w-prose px-page-gutter">{children}</div>
```
`max-w-prose` (~65ch) gives prose a comfortable reading measure. `px-page-gutter` adds breathing room from the viewport edges. No breakpoints needed.

### Cover — full-viewport hero with centered content
```tsx
<section className="grid min-h-svh place-items-center px-page-gutter">
  {children}
</section>
```
Note `min-h-svh` (small viewport height) instead of `min-h-screen` (`100vh`). On mobile, `100vh` includes the dynamic browser chrome and causes content to clip when the URL bar collapses. `svh` / `dvh` / `lvh` are the modern correct units; `100vh` is a legacy mobile-Safari trap.

## Common Responsive Patterns

These are the patterns most product screens reach for. Each is solved with intrinsic layout where possible.

### The Card Grid
Default to auto-grid (no breakpoints). Only step to explicit columns when the design needs exactly N columns at a viewport.
```tsx
<div className="grid gap-6 [grid-template-columns:repeat(auto-fit,minmax(min(18rem,100%),1fr))]">
  {items.map((item) => <Card key={item.id} item={item} />)}
</div>
```

### The Two-Column Form
Use a container-queried switcher. The same form composes correctly in a modal (narrow), a settings panel (medium), and a full page (wide).
```tsx
<form className="@container">
  <div className="grid gap-4 @md:grid-cols-2">
    <Field label="First name" />
    <Field label="Last name" />
    <Field label="Email" className="@md:col-span-2" />
  </div>
</form>
```

### The Responsive Navigation
This is page chrome — media queries are correct here. Two patterns dominate:

1. **Horizontal nav collapses to overlay menu** below a breakpoint. Implementation belongs in a `<NavBar>` component using a Radix or `react-aria` `Dialog` for the mobile overlay.
2. **Sidebar nav collapses to a top bar** below a breakpoint. Same component with a different layout root.

Both are appropriate uses of media queries because the navigation *is* the shell.

### The Responsive Modal / Sheet
Modals on phones should be bottom sheets (full-width, slide up from the bottom); on tablets and desktops they should be centered dialogs. The pattern uses a media query (this is page chrome) and is detailed in `team/ui-ux/skills/web-interaction-patterns.md`.

### The Responsive Image
```tsx
<img
  src={primary}
  srcSet={`${small} 480w, ${medium} 800w, ${large} 1200w`}
  sizes="(min-width: 768px) 50vw, 100vw"
  alt={altText}
  className="aspect-video w-full rounded-card object-cover"
/>
```
For Next.js, prefer `<Image />` (`next/image`) which handles `srcSet`, `sizes`, lazy loading, and modern formats automatically. Spec out the `sizes` attribute — it's not optional and getting it wrong silently downloads the wrong asset.

### The Responsive Table
Tables don't gracefully shrink. The right answer depends on the data:

| Table type | Phone treatment |
|------------|----------------|
| Reference data (price list, comparison) | Horizontal scroll within the container. Don't reflow. |
| Listed records (orders, transactions) | Reflow into a stack of cards on narrow viewports — each row becomes a card showing the same fields. |
| Spreadsheet / dense data (analytics) | Acknowledge tablet+ as the floor. Show a phone-friendly summary on small viewports with a "View full data" link. |

Don't try to make every column reflow at every breakpoint — the result is unreadable.

## Touch and Pointer Targets

Touch targets have a physical floor regardless of viewport: **44×44 CSS pixels minimum** on any touch-capable device. The full target-sizing rules — hit-area extension when the visual is smaller, the `(pointer: fine)` exception for mouse-only contexts, and the WCAG 2.5.5 framing — live in `team/ui-ux/skills/web-accessibility.md` → Touch and Target Sizing as the source of truth. The responsive-layout implication is the one worth restating: **the floor doesn't change with viewport.** A button is 44×44 on a 1280px desktop with touch input (iPad, touch-screen laptop) just as it is on a 375px phone. Layout decisions don't override the floor; the design-system control sizing enforces it.

## Orientation & Tablet Adaptation

Two device classes need explicit attention beyond the "mobile portrait + desktop" wireframing default: **mobile in landscape** (short viewport, often used for video / active-session screens) and **tablets** (touch input at desktop-scale viewports, including iPad split-screen and Stage Manager).

### Mobile Landscape

A phone rotated to landscape is wide (667–932px) and *short* (375–430px tall) — and the on-screen keyboard halves the available height the moment any input is focused. This is a different design surface from portrait mobile, not a wider variant of it.

| Concern | Portrait (375 × 667) | Landscape (667 × 375) |
|---------|---------------------|----------------------|
| Form with on-screen keyboard | ~280px content visible above keyboard | ~110px visible — most forms become unusable as designed |
| Bottom sheet | Covers ~70% of viewport — comfortable | Would cover 100% — defeats the "sheet" affordance |
| Hero with `min-h-svh` | Feels right | Cramped — primary CTA risks being cut off |
| Centered dialog (modal) | Already overlay-style on phone | Closer to desktop dialog shape — centered modal often correct |
| Active session / video / map / fullscreen tool | Awkward | Often the *preferred* mode |

Rules:

- **Forms in landscape:** keep single-column, tighten vertical rhythm one notch (e.g., `gap-3` instead of `gap-4`). If the form is multi-step, use the *route* as the step boundary (one field per route, full screen), not a scroll within a step.
- **Bottom sheets in landscape:** swap to full-screen route or centered modal. A "sheet" that covers the entire viewport isn't a sheet — pick a different surface.
- **Heroes and viewport-relative units:** design hero content that survives at 375px of vertical space. If the design needs ≥ 600px tall to feel right, it's wrong on phone-landscape — demote secondary content or split into multiple sections.
- **Active-session / video / map / canvas screens:** these often *want* landscape. Design them landscape-first if landscape is the primary use mode; the portrait variant is the fallback, not the reverse.

### Tablet (iPad and Android tablets)

The breakpoints `md` (768px) and `lg` (1024px) line up with iPad portrait and landscape — but tablets aren't just "small desktops." They are *touch input at desktop-scale viewports*, and that combination has design implications the breakpoint alone doesn't capture:

- **No hover-only affordances**, even when the layout looks desktop-like. iPad has a pointer (Apple Pencil, Magic Trackpad) but the modal interaction is touch. Anything that depends on hover-to-discover fails.
- **Touch targets stay at 44×44**, even when the layout has room for desktop-density toolbars. The rule is: tablet = touch input + desktop space, not desktop input + desktop space.
- **Sidebar nav is correct on iPad portrait at 768px** — a full sidebar (not collapsed-icon) fits comfortably and matches OS-native iPad apps.
- **Cursor styles still apply.** iPad Magic Keyboard / trackpad shows a system cursor; `cursor: pointer` on interactive elements is still correct.

Detect the device class explicitly with `(pointer: coarse) and (min-width: 48rem)`:

```css
/* Tablet-class device: touch input at tablet-or-larger viewport */
@media (pointer: coarse) and (min-width: 48rem) {
  /* Touch-sized affordances at desktop-scale layouts */
}
```

Most rules don't need this query — touch-target floors and "no hover-only affordances" already apply globally. Reach for it only when the design genuinely needs to differentiate (e.g., showing keyboard-shortcut hints only on `pointer: fine` devices).

### iPad Split-Screen and Stage Manager

iPadOS lets users place an app at 1/2 or 1/3 width — meaning a "tablet device" can present a viewport as narrow as 320px. Container queries handle the *components* correctly here (they adapt to the column they're in), but **page chrome is media-query-driven and can be wrong.**

Mitigation: page-chrome breakpoints use the same `md` / `lg` thresholds whether the device is a phone or a half-screen iPad. If the layout breaks at 600px regardless of device, fix it for the breakpoint — not for the device class. The point is that container queries are doing more work than they appear to here, and the design must not rely on "this is a tablet, so the layout will be wide."

### Orientation Transitions

When the device rotates, the layout reflows. **Don't animate the rotation.** Let the browser's reflow happen instantly. Custom orientation animations (rotating cards, parallax during rotation) are vestibular triggers and feel broken to most users.

Lock orientation only when the design genuinely demands it — fullscreen video, a game, a one-handed-by-design mode. For product UI, orientation is the user's choice; respect it.

## Designing the Spec

When specifying a screen for the Developer (see `team/ui-ux/skills/web-screen-specification.md`), describe responsive behavior in terms of *layout intent*, not viewport pixels:

- **Wrong**: "At 768px, the sidebar appears. At 1024px, the grid becomes 3 columns."
- **Right**: "The sidebar is shown at the `md` breakpoint. The card grid uses auto-fit at minimum 16rem; let it find its column count organically."

The spec should call out:

1. **Page-shell breakpoints** (when sidebar appears, when nav collapses) — by token name.
2. **Container-driven components** — list which components use `@container` and what the breakpoint set is.
3. **Touch targets** — confirm minimum 44×44 on every tap target at the smallest viewport.
4. **Critical viewports to verify**:
   - **375 × 667** — phone portrait (smallest target). Always required.
   - **667 × 375** — phone landscape. Required unless the screen is explicitly portrait-only (mark "N/A — portrait only" with a one-line reason; silent skipping is not allowed).
   - **768 × 1024** — iPad portrait. Required for any product expected to be used on tablets.
   - **1024 × 768** — iPad landscape. Required if iPad portrait is required.
   - **1280 × 800** — standard desktop. Always required.
   - Anything beyond (Pro Max widths, ultrawide monitors, foldables) is a polish exercise, not a contract.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **Desktop-first responsive declarations.** `grid-cols-3 md:grid-cols-2 sm:grid-cols-1`. | Reverse-cascade is harder to reason about; the small viewport (which most users have) is now the override case rather than the default. | Mobile-first: `grid-cols-1 md:grid-cols-2 lg:grid-cols-3`. |
| **Component-level media queries.** `<Card className="md:flex-row md:gap-6">`. | The card is now coupled to viewport width regardless of where it's placed. Drop it in a sidebar at desktop and it still tries to render the desktop layout. | Wrap the card in `@container` and use `@md:flex-row` instead. |
| **A custom breakpoint between two existing ones.** "We need 896px to handle the medium-large laptop." | Introduces a layout that exists for one device and confuses every future change. | Use fluid sizing (`clamp()`) to bridge between the two breakpoints, or pick the closer existing breakpoint. |
| **`100vh` / `min-h-screen` for full-viewport sections.** | On mobile Safari, `100vh` includes the dynamic browser chrome — content clips when the URL bar collapses. | Use `100svh` / `min-h-svh` (small viewport height) or `100dvh` (dynamic) depending on intent. |
| **Fluid type on body or caption sizes.** `font-size: clamp(0.875rem, 0.5rem + 1vw, 1rem)` on body text. | Breaks browser font-size accessibility settings and zoom. Body text must respect the user's chosen base size. | Body and caption are fixed (`1rem`, `0.8125rem`). Only display-class sizes scale. |
| **Manual breakpoint stepping for what `auto-fit` solves.** A card grid that's `grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5`. | Five breakpoints, five layouts to verify, none robust to a sidebar appearing. | Use auto-fit with `minmax(min(18rem, 100%), 1fr)` — one declaration, intrinsically responsive. |
| **`hidden md:block` to swap two versions of the same content.** Two near-duplicate component trees, one hidden at each breakpoint. | Doubles the DOM, doubles the maintenance, and search engines / screen readers see both. | Render the same component once and let it adapt via container queries or fluid sizing. |
| **Using the viewport for "is this a touch device?"** `if (window.innerWidth < 768) usePhoneLayout()`. | Viewport width is not input capability. A 1280px laptop with touch screen exists. A 600px window on a desktop exists. | Detect input capability via `@media (pointer: fine)` / `(hover: hover)`, not viewport. |
| **Touch targets below 44×44 on phones.** Icon buttons that visually look 24×24. | Fails WCAG 2.5.5; users miss the tap and feel the product is unrefined. | Pad the hit area to 44×44 minimum even when the visual is smaller. |
| **Letting tables horizontally scroll without acknowledging it.** A table at 1200px that just clips on a phone. | Users don't realize there's more content; the design feels broken. | Either reflow into cards (records) or explicitly design the horizontal-scroll affordance (reference data) with a visible scrollbar / shadow gradient. |
| **Designing only at 1440px and "letting CSS figure it out."** | The design hasn't been made for the device most users have. Designs will silently break in ways the team doesn't see until production. | Design at 375px first (smallest target), then 1280px. Verify both. The desktop is a courtesy; the phone is the product. |
| **Hamburger menu on desktop when the nav fits horizontally.** A 5-link top nav collapsed to a hamburger at 1280px because "it looks cleaner." | Hides discoverable destinations to save pixels you don't need. The pattern is a phone affordance imported to desktop without justification. Ubiquitous SaaS regression. | Show the nav. Hamburger is mobile-only — the breakpoint where it appears is the breakpoint where the horizontal nav genuinely no longer fits, not a stylistic choice. |

## Principles

1. **Mobile-first is non-negotiable.** Most product usage is on phones. The base layout must work at 375px without any responsive adaptation having loaded. Larger viewports add layout — they don't fix it.

2. **Components respond to space, not viewport.** Container queries by default, media queries only for shell-level concerns (nav, sidebar, page chrome). A component that only works on its original page is a component that owes the codebase a refactor.

3. **Layout intrinsically responsive beats layout with breakpoints.** `auto-fit` grids, flex-wrap clusters, `clamp()` sizing, intrinsic units (`min-content`, `fr`, `minmax`) — reach for these first. A breakpoint is the *fallback* when intrinsic layout can't express the design.

4. **The breakpoint set is small.** Four viewport breakpoints, four container-query breakpoints, no custom intermediates. Sparseness is what keeps the layout system understandable as the product grows.

5. **Fluid scales for layout, fixed sizes for controls and body text.** Page rhythm (gutters, section gaps) and display type scale with viewport. Body text, control heights, and tap targets stay at fixed accessible minimums.

6. **Modern viewport units only.** `svh`, `dvh`, `lvh` — not `100vh`. The legacy `vh` is a known mobile-Safari trap; treating it as deprecated is the modern-correct stance.

7. **Touch targets have a physical floor.** 44×44 CSS pixels minimum, 48×48 recommended, regardless of viewport or visual size. Pad hit areas; never sacrifice the floor for visual density on touch.

8. **Verify at the smallest target first.** The smallest device the product supports is the contract. Desktop is the polish layer on top of that contract. A design that's never been opened at 375px hasn't been designed yet.
