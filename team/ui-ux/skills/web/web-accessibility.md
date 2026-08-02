# Web Accessibility (Design Side)

## Purpose
Define the accessibility decisions that belong to *design* — color contrast at the token layer, focus-ring specification, motion design and reduced-motion alternatives, target sizing, design-time review process, and the heading/landmark intent that the implementation enforces. This skill is the design-side counterpart to Developer's `web-accessibility` skill (which covers semantic HTML, ARIA, focus management code, axe testing, and the implementation mechanics). Design decides intent; the developer implements mechanism. Both are required; neither is sufficient on its own. See the `web-design-system` skill for the token system that encodes most of these decisions. See the `web-screen-specification` skill for how a11y intent is documented in the spec. See the `web-content-hierarchy` skill for the heading-tree discipline. See the `web-interaction-patterns` skill for motion tokens and reduced-motion patterns. Target: **WCAG 2.2 AA as the floor — never the ceiling. EAA-compliant by default for European product surfaces. Modern web (React 19+, Next.js 15+, Tailwind v4)**.

## The Anchor: Accessibility Is a Design Constraint

Accessibility on the web typically fails at design time, not at implementation time. The developer can't add color contrast that wasn't in the tokens. The developer can't swap a hover-only affordance for a persistent one without redesigning. The developer can't conjure a reduced-motion alternative that the designer didn't specify. Every "we'll add a11y later" project ships with accessibility debt baked into the tokens, the components, and the screens.

**Design accessibility into the system, not into individual screens.** When tokens guarantee 4.5:1 contrast, every screen that uses tokens passes contrast. When components ship with focus rings, every interactive element has one. When the design system says "all controls 44×44 minimum," the components enforce it. This is the only path to consistent accessibility at scale.

WCAG 2.2 AA is the floor. The Apple-quality bar is higher: aim for AAA on text where the design allows, design for keyboard-only and screen-reader-only users as primary scenarios, and treat reduced-motion as a default condition (~17% of users have it set on macOS), not an edge case.

## Color Contrast (At the Token Layer)

Contrast is a token decision. If the tokens hit the targets, every consumer of the tokens does too — automatically.

### Targets

| Surface | WCAG 2.2 floor | Apple-quality target |
|---------|---------------|---------------------|
| Body text on its background | **4.5:1** (AA) | **7:1** (AAA) where design allows |
| Large text (≥ 18pt or 14pt bold) on background | **3:1** (AA) | **4.5:1** (AA on small text) |
| UI components (icons, borders, focus rings, form-control outlines) | **3:1** | **3:1** strict |
| Disabled text | No floor | Verify *meaning* is communicated by something other than contrast — disabled state is a distinct token (`opacity-50`) plus, on real disabled controls, `aria-disabled` |

### Verification at Token Definition

Every text/background pair in the semantic-token catalog (`web-design-system.md`) must be verified against these targets *before* shipping the token. Tools: WebAIM Contrast Checker (browser), axe DevTools (in dev), Stark plugin (Figma). Verify in *both* light and dark themes — the tokens redefine on theme switch and contrast must hold in both.

The token catalog should ship with a verification table:

| Token pair | Light contrast | Dark contrast | Result |
|-----------|---------------|--------------|--------|
| `text` on `surface` | 12.6:1 | 14.2:1 | AAA |
| `text-muted` on `surface` | 5.8:1 | 6.4:1 | AA (target AAA) |
| `text` on `surface-muted` | 11.4:1 | 13.0:1 | AAA |
| `text-on-accent` on `accent` | 4.9:1 | 4.9:1 | AA |
| `accent` on `surface` (link color) | 4.7:1 | 5.2:1 | AA |
| `text-danger` on `surface` | 5.1:1 | 5.6:1 | AA |
| `border` on `surface` (UI component) | 3.2:1 | 3.4:1 | AA (UI floor) |
| `border-strong` on `surface` | 4.4:1 | 4.6:1 | AA+ |
| `focus-ring` on `surface` | 4.7:1 | 5.2:1 | AA+ |

If a row fails, fix the token before shipping. Don't carve exceptions for "just this one screen" — that's how design systems lose their accessibility guarantee.

### Don't Communicate by Color Alone

Color is one channel of information; users with color blindness, low vision, or in bright sunlight may not perceive it. **Every state communicated by color must also be communicated by shape, position, icon, or text.**

| Wrong | Right |
|-------|-------|
| Required field marked only with red label | Required field marked with `*` next to the label (and red color, but not only red) |
| Status pill: green for "Active," red for "Suspended," gray for "Pending" | Same colors, but each pill also includes an icon (✓, ⊘, ⏱) and the status word |
| Charts with red and green lines, no other distinction | Color + line style (solid/dashed) + direct labels |
| Form errors only marked by red border | Red border + error icon + error message text |

This is a design call. Audit every state in the design that uses color — if removing the color makes the state ambiguous, add another channel.

## Focus Rings (Specified, Not Default)

Focus rings are the keyboard user's cursor. They must be visible, consistent, and never removed. Specify the focus-ring treatment once, at the token + component level, and every interactive element gets it for free.

### The Specification

```css
/* From tokens.css */
--color-focus-ring: var(--color-accent-500);  /* same as accent for the brand */
```

```css
/* Applied via Tailwind utilities on every interactive component */
focus-visible:outline-none
focus-visible:ring-2
focus-visible:ring-focus-ring
focus-visible:ring-offset-2
focus-visible:ring-offset-surface
```

The result: a 2px ring in the focus-ring color, 2px offset from the element edge, on a surface-colored background (which makes the ring stand out from the element itself). The ring appears only on keyboard focus (`:focus-visible`), not on mouse click — which is correct. Mouse users don't need the ring; keyboard users absolutely do.

### Rules

- **Never `outline: none` without a replacement.** Removing the browser's default outline without providing a `:focus-visible` replacement is the single most common a11y regression on the web.
- **`:focus-visible`, not `:focus`.** `:focus-visible` shows the ring only when the user is keyboard-navigating. `:focus` shows it on every click and is what gives focus rings a bad reputation. Modern browsers all support `:focus-visible`.
- **Offset matters.** A 2px ring touching the element edge looks like a thicker border, not a focus indicator. The 2px offset (`ring-offset-2`) makes the ring distinct.
- **Contrast: 3:1 against the surface.** Focus ring is a UI component for contrast purposes — verified in the token table.
- **Visible on both themes.** A focus ring that's brand-blue on a white surface is fine; the same blue on a deep-blue dark surface might fail. Verify in both.

### Skip-to-Content Link

Every page has a skip-to-content link as the first focusable element. Visually hidden until focused, then it appears at the top of the viewport with the focus ring. Activating it skips past the navigation to `<main>`. This is a design element — specify its appearance and position in the design system.

```tsx
// Pattern (mechanism in Developer's `web-accessibility` skill)
<a
  href="#main"
  className="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 focus:z-50 focus:rounded-control focus:bg-surface-raised focus:px-3 focus:py-2 focus:text-text focus:ring-2 focus:ring-focus-ring"
>
  Skip to content
</a>
```

## Forced Colors and Contrast Preferences

Two user modes the token system *cannot* serve, because they override the token system entirely:

| Mode | What it is | Who uses it |
|------|-----------|------------|
| **Forced colors** (Windows High Contrast Mode, `@media (forced-colors: active)`) | The OS substitutes a small palette of system colors (`CanvasText`, `ButtonText`, `LinkText`, `Highlight`, `ButtonFace`) for everything. Background images, gradients, and shadows are removed. | Common on enterprise Windows, low-vision users, and anyone who prefers extreme contrast. At least as common as `prefers-reduced-motion` is on macOS. |
| **`prefers-contrast: more` / `less`** | The user requested higher or lower contrast. Browsers may also expose `prefers-contrast: custom`. | Low-vision users and users in challenging lighting (sunlight). |

The token-layer contrast verification (above) handles `prefers-contrast: more` automatically *if* the tokens are at AAA on text where possible. Forced-colors is the harder case: the token system is overridden, and the design must survive without it.

### Designing for Forced-Colors

The fix is not to fight forced-colors mode — it's to ensure the product still works. See the `web-design-system` skill → Forced Colors for the implementation pattern. The design-side rules:

- **Don't communicate state via background-color or background-image alone.** A button that's "primary" only because of its blue background disappears when the OS forces a flat background. Pair color with a visible border, an icon, or text weight.
- **Borders are visible by default.** A button distinguished only by background color disappears in forced-colors; one with `1px solid` border survives.
- **Icons must be inline SVG**, not `background-image`. Background-image icons disappear in forced-colors.
- **Focus indicators are preserved by the OS** — but make sure your `:focus-visible` ring uses `currentColor` or a system color (`Highlight`) within forced-colors mode so it remains visible.
- **Test the design in forced-colors before shipping.** DevTools → Rendering → Emulate `forced-colors: active`. Or boot a Windows VM with HCM enabled. Run the keyboard walkthrough; confirm every interactive element is still distinguishable.

This is design-side work because it's about what the design relies on (color alone vs. color + shape + text). Implementation alone can't fix a design that communicates only via background.

## Touch and Target Sizing

Tap targets have a physical floor that doesn't change with viewport.

| Surface | Floor |
|---------|-------|
| **Touch device** (`pointer: coarse`) | 44×44 CSS px (WCAG 2.5.5 minimum), 48×48 recommended |
| **Pointer device** (`pointer: fine` only) | 24×24 acceptable for dense UIs (toolbars, data grids) |
| **Inline link in body text** | No size floor — surrounding text provides context, but adjacent links must have ≥ 24px between targets |

If the visual element is smaller than the target floor (e.g., a 24×24 icon button on touch), the *hit area* must extend to the floor via padding, an absolutely-positioned `::before` overlay, or a wrapping element with the right `min-h` / `min-w`. The visual stays small; the target meets the floor.

This is a design specification — every component spec must call out the visual size *and* the hit area separately when they differ.

## Motion and Animation

### `prefers-reduced-motion` Is the Default Mode for ~17% of macOS Users

Treat reduced-motion as a primary user mode, not an edge case. Every animated element ships with a reduced-motion alternative *as part of the design*, not as a developer's afterthought.

| Decoration motion | Default | Reduced-motion |
|-------------------|---------|---------------|
| Skeleton shimmer | Subtle pulse | Disabled (static skeleton) |
| Hover lift / shadow grow | 200ms ease | Disabled (instant or no change) |
| Mount fade-in | 200ms fade | Instant |
| Card transitions on hover | 200ms scale + shadow | Disabled |
| Marquee, parallax, autoplay video | As designed | Disabled entirely |

| Functional motion | Default | Reduced-motion |
|-------------------|---------|---------------|
| Modal open / close | 200ms slide + fade | Instant or 100ms crossfade |
| Toast slide-in | 200ms slide from edge | 100ms fade |
| Tab switch | 100ms crossfade | Instant |
| Route transition (View Transitions) | As designed | Instant |
| Drag-and-drop snap | Spring | Linear, fast |

Specify both the default and the reduced-motion variant in the screen spec (the `web-screen-specification` skill → Interactions → Animations).

### Motion Tokens

All motion uses the design-system tokens (`--duration-instant`, `--duration-short`, `--duration-medium`, `--ease-standard`, `--ease-emphasized`). Magic numbers are forbidden — they're a tell that motion was decided ad-hoc rather than systematically. The motion vocabulary should fit on a notecard.

### Vestibular Safety

Avoid:
- Large parallax scroll effects (vestibular triggers).
- Auto-playing video or carousels (no consent).
- Rapid flashing > 3 times per second (seizure risk — WCAG 2.3.1).
- Continuous looping motion in the user's peripheral vision (skeleton shimmer is borderline; subtle is fine, aggressive is not).

When in doubt, design without the motion. Apple's products use motion sparingly and deliberately; web products tend to over-animate.

## Reading Order and Heading Intent

The DOM order is the reading order for assistive technology. CSS can rearrange the visual layout (with `order`, `flex-direction: row-reverse`, `grid-area` placement), but the source order is what gets read aloud.

**Source order must match the intended reading order.** When the visual layout reorders elements (e.g., a sidebar visually-left is described "after" the main content in source), the spec must call this out. The developer should never reorder source to satisfy visual without the designer's input.

### Landmarks Beyond Header / Main / Nav / Aside / Footer

The five core landmarks (`<header>`, `<main>`, `<nav>`, `<aside>`, `<footer>`) cover most page chrome. Two underused ones worth knowing:

- **`<search>`** (HTML 2023+, supported in modern browsers and SR mappings) wraps a search form or search interface. Replaces `<form role="search">` for the modern pattern; assistive tech can list it as a "search landmark." Use whenever a screen has a search interface.
- **`<section>` with `aria-labelledby`** for sub-regions of `<main>` that have a heading and are independently meaningful. Don't `<section>`-bomb every container; reserve for genuine regions.

### Pointer Cancellation (WCAG 2.5.2)

For long-press, drag-and-drop, and multi-touch interactions: the action must be **cancellable** by moving away before release. The user starts an action, realizes it's wrong mid-gesture, and moves the pointer/finger off the target — the action must not fire. This is WCAG 2.5.2 (Pointer Cancellation, Level A).

Implementation: bind actions to `pointerup` on the *original* target only when the up event happens *over* that target. If the user lifts their finger after dragging away, no action. Most native and Radix components handle this; custom drag-and-drop or long-press handlers must implement it explicitly.

This is a design requirement: every long-press, drag, or tap action declared in the screen spec must include the cancellation behavior.

### Heading Tree

The heading tree is the screen reader's table of contents. Specify it in the screen spec:

- One `<h1>` per page (the page's primary subject).
- `<h2>` for major sections (3–5 typical).
- `<h3>` for subsections of `<h2>`.
- Don't skip levels (no `<h1>` then `<h3>`).
- Headings render at any visual size — use the right level and override the visual via tokens (`text-h1` token on an `<h2>` is acceptable when needed, but verify the hierarchy is right).

A page that reads as "Today / Recent activity / Settings" via headings should not read as "Today / Settings / Recent activity" if you only listened to the headings — that mismatch signals broken hierarchy or wrong markup.

## Form Accessibility (Design Side)

Implementation lives in Developer's `web-accessibility` skill. The design-side decisions:

| Decision | Specification |
|----------|--------------|
| Label position | Above the field. Always. Placeholder is *not* a label. |
| Required indicator | Small `*` next to the label. Don't write "(required)" as text. Use `*` only if the form has a mix of required and optional. |
| Error placement | Directly below the field, in `text-caption text-danger`. Linked via `aria-describedby` (developer's job). Visible *and* announced. |
| Error trigger | On blur or on submit. Never on every keystroke (see the `web-interaction-patterns` skill → Forms). |
| Helper text | Below the field, in `text-caption text-text-muted`. Non-error guidance. |
| Field grouping | Use `<fieldset>` + `<legend>` for related groups (address, payment card). Visually styled, semantically required. |
| Autocomplete hints | Specify in the spec: which fields have which `autocomplete` attribute. Browsers and password managers depend on these. |

## Dialog and Modal Accessibility

The design specifies the *intent*; the developer implements the focus trap, ARIA roles, and Escape handling. Design-side decisions:

| Decision | Specification |
|----------|--------------|
| What gets focus on open? | Usually the first focusable element. For destructive dialogs, focus the *cancel* button (so an accidental Enter doesn't confirm). |
| What gets focus on close? | The element that opened the dialog. (Developer enforces.) |
| Can it close on backdrop click? | Yes for non-destructive (default Radix `Dialog` behavior). No for destructive ("type to confirm" dialogs). |
| Can it close on Escape? | Same rule. |
| Title visible? | Yes, with a real heading. If visually hidden, mark with `sr-only` but the dialog still needs a `aria-labelledby` reference. |

## Live Regions

When the UI changes without a navigation event (toast, inline message, async update), assistive technology needs a hint to announce it. The design specifies the *politeness*:

| Politeness | Use |
|------------|-----|
| `aria-live="polite"` (default) | Toasts, inline form success/error, autosave indicators. Announces when the user is between activities. |
| `aria-live="assertive"` | Critical interruptions only — payment errors, account-suspended notices, "your session has expired." Announces immediately. Use sparingly. |

Almost every announcement is `polite`. `assertive` should be flagged in design review whenever it appears.

## Designing for Keyboard Users

Every flow must be completable on the keyboard alone. This is a design verification step, not a developer concern.

Walk through each screen using only Tab, Shift+Tab, Enter, Space, Escape, and arrow keys (where applicable):

- Can you reach every interactive element?
- Is the focus indicator always visible?
- Is the order logical (matches the visual reading order)?
- Are custom widgets (combobox, date picker, drag-and-drop, tabs) keyboard-operable per their ARIA pattern?
- Can you escape a modal, popover, or menu?
- Can you submit a form and interpret errors without a mouse?

If any answer is no, the design is incomplete — not the implementation.

## Designing for Screen-Reader Users

Walk through each screen with VoiceOver (macOS), NVDA (Windows), or TalkBack (Android):

- Is the page title announced first?
- Do landmarks (`<main>`, `<nav>`, `<aside>`, `<header>`, `<footer>`) let the user jump to the right region?
- Is the heading tree correct?
- Are interactive elements announced with their role and state ("button, expanded," "link, visited")?
- Are form labels and errors announced with the field?
- Are dynamic updates announced via live regions?

This is a design exercise: if the screen reader produces a confusing narrative, fix the design (semantic structure, labeling, region titles), not just the markup.

## Design Review Checklist

Before any screen ships, run this checklist *as a designer* — independent of the developer's axe-core / Playwright a11y tests.

- [ ] **Tokens verified** — every text/background pair in this screen meets the contrast target (verified at the token level, spot-checked here)
- [ ] **No color-only signals** — every state communicated by color also communicated by shape/icon/text
- [ ] **Focus rings present** — every interactive element has a visible focus ring (verified by Tab-walking the screen)
- [ ] **Skip-to-content link** — present, visible on focus
- [ ] **Touch targets ≥ 44×44** — verified at the smallest viewport on every tap target (or hit area extended via padding)
- [ ] **Reduced-motion alternative** — every animation has its reduced-motion variant specified
- [ ] **No rapid flashing** — no element flashes more than 3 times per second
- [ ] **Heading tree** — `<h1>` is the page title; `<h2>`/`<h3>` follow without skipping levels
- [ ] **DOM order** — source order matches visual reading order (call out exceptions)
- [ ] **Form labels above** — no placeholder-as-label, no missing labels, required `*` only if mixed-required
- [ ] **Error messages** — specific, actionable, below the field, in `text-danger`
- [ ] **Dialog focus on open/close** — first-focus and return-focus targets specified
- [ ] **Live region politeness** — `polite` for non-interrupting, `assertive` only when justified and called out
- [ ] **Keyboard walkthrough** — every flow completable with keyboard alone
- [ ] **Screen-reader walkthrough** — narrative is sensible (run with VoiceOver / NVDA / TalkBack)
- [ ] **Both themes verified** — contrast holds in light and dark; focus rings visible in both

If any box is unchecked, the design is incomplete.

## What Lives Where (Design vs. Implementation)

| Concern | Design owns (this skill) | Implementation owns (Developer's `web-accessibility` skill) |
|---------|-------------------------|-------------------------------------------------------------------|
| Color contrast | Token-level verification, "no color-only" rule | — |
| Focus ring | Spec (token, offset, when visible) | `:focus-visible` mechanics, removing default outline correctly |
| Touch target size | Spec the minimum, hit-area design when visual is smaller | `min-h` / `min-w` enforcement, padding strategy |
| Motion / reduced-motion | Token vocabulary, per-screen alternatives in spec | `@media (prefers-reduced-motion)` mechanics, animation libraries' a11y modes |
| Reading order | Intent (DOM = reading order) | Source ordering, `tabindex` discipline (default 0/-1 only) |
| Heading tree | Hierarchy decision (which is `<h1>`, `<h2>`) | Markup uses real `<h*>` elements, not styled divs |
| Form fields | Label position, error placement, helper text design | `<label htmlFor>`, `aria-invalid`, `aria-describedby`, `useId` |
| Dialogs | Focus-on-open/close intent, dismissibility | Radix `Dialog` mechanics, focus trap |
| Live regions | Politeness selection (`polite` vs `assertive`) | `aria-live` attributes, region rendering |
| Skip-to-content | Visual treatment when focused | `<a href="#main">` mechanics |
| Keyboard navigation | Walkthrough verification, custom-widget pattern selection | ARIA authoring practices implementation, library choice |
| Screen-reader narrative | Walkthrough verification, semantic structure intent | Element selection (`<button>` vs `<a>`), `aria-label` decisions |
| Testing | Design review checklist | axe-core in CI, Playwright a11y, manual VoiceOver/NVDA |

Both sides are required. A design spec without these decisions is incomplete; an implementation without the spec to follow guesses and gets it wrong.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **Removing focus outlines without replacement.** `outline: none;` with no `:focus-visible` ring. | Keyboard users have no cursor. The most common a11y failure on the web. | Always pair `outline: none` with a `:focus-visible:ring-2 ring-focus-ring` replacement. Treat it as a non-negotiable token-level rule. |
| **`user-scalable=no` / `maximum-scale=1.0` in viewport meta.** The page disables zoom. | Removes zoom for low-vision users. Direct WCAG violation. Common on "polished" mobile sites that want to prevent accidental zoom. | Omit. Allow user-scalable. Accidental zoom is fine; preventing it is hostile. |
| **`aria-label` on every element ("aria-label-bombing").** `<button aria-label="Save">Save</button>`, decorative icons with elaborate labels, redundant ARIA on already-labeled elements. | The aria-label *overrides* the visible text — so the visible "Save" is replaced by the aria-label "Save," but if they ever drift the SR user gets a different word than the sighted user. Decorative icons get announced as content. Common LLM output that hurts SR experience. | Don't use aria-label when a visible label exists. Use it for icon-only buttons (where there's no text) and for genuinely landmark-level labels. Decorative SVGs get `aria-hidden="true"`. |
| **Disabled state via `opacity` only.** A button at 50% opacity is "disabled." | Collides with focus-visible (the focus ring is also opacity'd out); fails contrast for disabled-but-meaningful text; encourages skipping `aria-disabled`. | Use distinct `disabled-fg` / `disabled-bg` tokens (see the `web-design-system` skill). Pair with `aria-disabled="true"` so SR users hear the state. |
| **Color-only state signals.** Required fields red-only, status indicators color-only. | Color-blind, low-vision, and high-glare users miss the state. | Add a second channel — icon, shape, position, or text. |
| **Decorative motion on by default with no reduced-motion handler.** Skeleton shimmer, hover lifts, mount animations all assume motion is fine. | ~17% of macOS users have reduced-motion enabled. They get unintended motion. | Specify reduced-motion alternatives in the spec and enforce in components. |
| **Touch targets visually-small with no hit-area extension.** A 24×24 icon button on touch. | Misses WCAG 2.5.5; users miss taps; the product feels imprecise. | Extend hit area to 44×44 minimum via padding or absolute overlay. Visual stays small. |
| **Placeholder as label.** Field with no visible label. | Fails on accessibility, autofill, and review-after-typing. | Label above the field; placeholder for example values only. |
| **Headings used for visual styling.** `<h2>` chosen because "I want a 24px size." | Breaks the heading tree, hurts screen-reader navigation. | Pick the right heading level for the *content hierarchy*; style separately via tokens. |
| **`aria-live="assertive"` for non-critical updates.** Every toast set to assertive. | Constant interruptions for screen-reader users. | Default to `polite`. `assertive` only for genuine interruptions (errors that block the task). |
| **Dialogs that close on backdrop click for destructive actions.** "Delete account" dialog dismisses if you click outside. | Easy to dismiss accidentally; no explicit choice required. | Destructive dialogs require explicit click on a button. Disable backdrop-click-to-close. |
| **Tooltips on touch devices.** Information conveyed only on hover. | Touch users have no hover; they get nothing. | Pair icons with text labels; use persistent affordances; reserve tooltips for pointer devices and never make them load-bearing. |
| **Hover-only interactivity.** Cards or rows that look like static containers until hovered; row actions that appear only on hover. | Touch users have no hover and never discover the controls. Pointer users have to investigate to learn what's interactive. The static state lies about what's clickable. | Static state must already communicate interactivity (border, cursor, persistent action affordance). Hover refines; it never reveals. Show row actions persistently on `(pointer: coarse)`; only conditionally on `(hover: hover)` if dense layouts demand it. |
| **Skip-to-content link missing.** Users tab through navigation on every page. | Keyboard users repeat the same nav-traversal on every page. | First focusable element on every page is a skip-to-content link, visible on focus. |
| **Designing only at the desktop default font size.** Everything assumes browser default 16px. | Users who zoom or set a larger default see broken layouts. | Verify the screen at 200% zoom. Layouts must reflow, not clip. |
| **Verifying contrast only in one theme.** Light theme passes; dark theme is "we'll check later." | Token system redefines on theme; failures are silent. | Verify every token pair in both themes, in the token verification table. |

## Principles

1. **Design accessibility into the system, not into screens.** Tokens guarantee contrast. Components ship with focus rings. Patterns enforce minimum sizes. Per-screen accessibility is the cleanup; system-level accessibility is the discipline.

2. **WCAG 2.2 AA is the floor.** AAA on text where the design allows. Reduced-motion as a primary user mode. Keyboard and screen-reader users designed for as primary scenarios, not edge cases.

3. **Every state communicated by color is also communicated by something else.** Shape, icon, position, text. Color is one channel; assistive users may not perceive it.

4. **Focus rings are the keyboard cursor — never remove them.** Always paired with `:focus-visible`, always 2px+offset, always token-color, always verified for contrast in both themes.

5. **Touch targets have a physical floor.** 44×44 minimum on touch, regardless of visual size. Hit area extends past visual when the visual is smaller. This is a design specification, not implementation trivia.

6. **Motion respects preference and vestibular safety.** Reduced-motion alternatives specified for every animation. No flashing > 3Hz. No load-bearing parallax. The motion vocabulary fits on a notecard.

7. **Source order is reading order.** When visual layout reorders elements, source order stays correct or the divergence is explicitly flagged in the spec for justification.

8. **Walk the screen as a keyboard user, then as a screen-reader user.** The design isn't done until both walkthroughs produce a sensible experience. The developer's axe tests catch implementation bugs; only design review catches design bugs.

9. **200% zoom and reflow are non-negotiable (WCAG 1.4.10).** The design must reflow at 200% browser zoom without horizontal scroll, content clipping, or feature loss. Verify in DevTools at 200% before shipping. This is a Level AA requirement, often overlooked because designers test at 100% only. Disabling zoom via `user-scalable=no` is hostile and a direct violation.

10. **Forced-colors mode is a primary user mode, not an edge case.** Windows High Contrast Mode users override the token system entirely. The design must survive that override — borders for distinction (not just background-color), inline SVG icons (not background-image), focus indicators that the OS preserves. Audit every screen in forced-colors before shipping.
