# Web Accessibility (Implementation)

## Purpose
Define accessibility implementation patterns for modern Next.js + React 19 web apps: semantic HTML, ARIA discipline, keyboard navigation, focus management, screen reader patterns, forms, dialogs, motion, color, testing. The UI/UX agent owns the design side (`team/ui-ux/skills/web/`); this skill is the developer-facing implementation. See `team/developer/skills/web-best-practices.md` for the WCAG 2.2 AA quality gate. See `team/developer/skills/web-testing.md` for axe automation in CI. See `team/developer/skills/web-modern-react.md` for form/error patterns. Target: **WCAG 2.2 AA floor, AAA where it matters; React 19+, Next.js 15+**.

## The Bar

WCAG 2.2 AA is the floor — non-negotiable. AAA where it materially helps the user (text contrast, error identification on critical flows). The Apple lens: accessibility isn't a checklist run before release — it's a constraint that shapes every component you write.

A keyboard-only user, a VoiceOver user, a low-vision user, and a sighted mouse user must all be able to complete every task in the app. If any of those is impossible, the feature isn't done.

## Semantic HTML First

Every accessibility win starts with the right element. Use the semantic element; reach for ARIA only when no semantic element fits.

| Need | Element | Why |
|------|---------|-----|
| Trigger an action | `<button>` | Built-in keyboard activation (Enter, Space), focus, role |
| Navigate to a URL | `<a href>` | Built-in keyboard activation, focus, role, browser context menu |
| Form field | `<input>`, `<textarea>`, `<select>` | Built-in label association, validation, keyboard, screen reader announcements |
| Group of form fields | `<fieldset>` + `<legend>` | Screen readers announce the legend with each field |
| Heading | `<h1>` through `<h6>` | Document outline; screen readers navigate by heading |
| List | `<ul>`, `<ol>`, `<dl>` | Announces "list, N items"; navigable by list |
| Section | `<section>`, `<article>`, `<aside>`, `<nav>` | Landmarks for navigation (skip to nav, main, etc.) |
| Main content | `<main>` | Exactly one per page; skip-to-main lands here |
| Tabular data | `<table>` with `<th scope>` | Announces column/row headers with each cell |
| Disclosure | `<details>` + `<summary>` | Built-in toggle, keyboard, screen reader pattern |
| Status updates | `<output>` (forms) or `aria-live` region | Announces dynamic content |

**`<div>` and `<span>` are layout, not semantics.** Reaching for them when something more meaningful fits is the single most common accessibility mistake.

```tsx
// Wrong
<div onClick={handleClick}>Save</div>

// Right
<button type="button" onClick={handleClick}>Save</button>
```

The wrong version isn't focusable, doesn't respond to Enter/Space, isn't announced as "button, Save," and lacks browser shortcuts. The right version gets all of that for free.

## ARIA: When Semantic Falls Short

ARIA is a fallback when no semantic element exists for the pattern (custom comboboxes, tab panels, tree views). Three rules:

1. **No ARIA is better than bad ARIA.** A wrong `role` actively misleads screen readers.
2. **Don't override semantic roles.** `<button role="link">` is wrong — change the element if the role is wrong.
3. **Build to the WAI-ARIA Authoring Practices** (`https://www.w3.org/WAI/ARIA/apg/`) for complex widgets. Don't invent.

Common ARIA used correctly:

```tsx
// Disclosure
<button aria-expanded={open} aria-controls="panel-1">Toggle</button>
<div id="panel-1" hidden={!open}>...</div>

// Form error association
<input aria-invalid={!!error} aria-describedby={error ? "email-error" : undefined} />
{error && <p id="email-error" role="alert">{error}</p>}

// Live region for dynamic status
<p aria-live="polite" role="status">{savedAt ? "Saved" : ""}</p>

// Hide decorative content from screen readers
<svg aria-hidden="true" focusable="false">...</svg>
```

When in doubt, ship semantic HTML and run axe; it'll surface gaps.

## Keyboard Navigation & Focus

Every interactive element must be reachable, operable, and visible to keyboard users. The browser does most of this for free with semantic elements; what you have to think about:

### Tab order

The DOM order is the tab order. Don't fight it with `tabIndex` values. Specifically:

- **`tabIndex={0}`** — only on custom interactive elements that don't have a native role (rare in modern apps).
- **`tabIndex={-1}`** — programmatically focusable but not in tab order (e.g., a section heading you focus after navigation).
- **`tabIndex={1+}`** — never. It overrides the natural order and creates focus chaos.

If the visual order doesn't match the DOM order (CSS reordering with flexbox/grid), reconsider — keyboard users will be confused.

### Focus rings

Visible by default. Suppress only via `:focus-visible` for mouse users.

```css
/* Show focus ring for keyboard users; not for mouse clicks */
:focus { outline: none; }
:focus-visible {
  outline: 2px solid var(--ring);
  outline-offset: 2px;
}
```

Tailwind: use `focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2`. Never `outline-none` without a `focus-visible` replacement — that strips keyboard accessibility silently.

### Focus management on navigation

When a route changes (Next.js client navigation), focus should land somewhere meaningful — usually the page heading.

```tsx
// app/(app)/dashboard/page.tsx
export default function DashboardPage() {
  const headingRef = useRef<HTMLHeadingElement>(null);
  useEffect(() => { headingRef.current?.focus(); }, []);
  return <h1 ref={headingRef} tabIndex={-1}>Dashboard</h1>;
}
```

Or use a route-level focus helper that fires on navigation. Without this, keyboard users land at the top of the page on navigation while their tab cursor sits where it was — disorienting.

### Skip links

The first focusable element on every page should be a "Skip to main content" link.

```tsx
// app/layout.tsx
<a href="#main" className="skip-link">Skip to main content</a>
{/* ...nav, sidebar... */}
<main id="main" tabIndex={-1}>{children}</main>

/* visually hide until focused */
.skip-link {
  position: absolute; left: -9999px;
}
.skip-link:focus {
  position: static; /* or fixed top-left with a visible style */
}
```

Skip links let keyboard users bypass repeated nav on every page.

## Forms Accessibility

Forms are where most accessibility breaks happen. The full pattern:

```tsx
"use client";
import { useId } from "react";

export function EmailField({ error, ...props }: { error?: string } & React.InputHTMLAttributes<HTMLInputElement>) {
  const id = useId();
  const errorId = `${id}-error`;
  const describeId = `${id}-describe`;

  return (
    <div>
      <label htmlFor={id}>Email address</label>
      <input
        id={id}
        type="email"
        autoComplete="email"
        required
        aria-invalid={!!error}
        aria-describedby={error ? errorId : describeId}
        {...props}
      />
      <p id={describeId} className="text-sm text-muted">We'll never share this.</p>
      {error && <p id={errorId} role="alert">{error}</p>}
    </div>
  );
}
```

Rules:
- **Every form field has a `<label htmlFor={id}>`.** Visible text label is best; if visually hidden by design, use `<span className="sr-only">` — never just `aria-label` for fields users can see.
- **`useId()`** for stable, hydration-safe IDs. Never hand-roll IDs that might collide.
- **`aria-invalid`** mirrors the validation state.
- **`aria-describedby`** points to instructional or error text. Errors announce immediately because of `role="alert"`.
- **`autoComplete`** values match the spec (`email`, `current-password`, `new-password`, `name`, `tel`, etc.). Browsers and password managers depend on these.
- **`required`** on the input + Zod validation server-side. The HTML attribute communicates required-ness to screen readers.
- **Errors live next to the field**, not in a banner at the top of the form. Screen readers focus the field and announce the error in context.

## Dialogs and Modal Patterns

A dialog (modal) requires careful focus and keyboard handling. Use `<dialog>` (HTML element) when possible — modern browsers ship correct semantics, focus trap, ESC handling.

```tsx
"use client";
import { useEffect, useRef } from "react";

export function ConfirmDialog({ open, onClose, children }: Props) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    if (open) ref.current?.showModal();
    else ref.current?.close();
  }, [open]);

  return (
    <dialog ref={ref} onClose={onClose} aria-labelledby="confirm-title">
      <h2 id="confirm-title">Confirm action</h2>
      {children}
    </dialog>
  );
}
```

If a custom modal is unavoidable (animation requirements, library constraints):

- **Trap focus inside the modal.** Tab from the last focusable wraps to the first; Shift+Tab from the first wraps to the last.
- **Return focus to the trigger** when the modal closes.
- **ESC closes.** Always.
- **Click outside closes** (optional — not for destructive confirmations).
- **`role="dialog"` + `aria-modal="true"` + `aria-labelledby`** pointing to the dialog's heading.
- **Inert the rest of the page.** `inert` attribute on the page background makes everything outside the modal unfocusable and uninteractive.

Use `radix-ui` or `react-aria` for these — they get the focus trap right. Hand-rolled focus traps are reliably broken.

## Disclosure Patterns

Show/hide content (accordion, dropdown, expandable section).

```tsx
<button
  aria-expanded={open}
  aria-controls="panel-1"
  onClick={() => setOpen((v) => !v)}
>
  Show details
</button>
{open && <div id="panel-1">...</div>}
```

For native disclosure, prefer `<details>` + `<summary>`:

```html
<details>
  <summary>Show details</summary>
  <p>...</p>
</details>
```

Built-in keyboard, screen reader, and toggle behavior — no JS required.

## Live Regions

Announce dynamic updates (toast notifications, async status changes, validation results) without moving focus.

```tsx
<div aria-live="polite" role="status">{message}</div>      // non-urgent
<div aria-live="assertive" role="alert">{errorMessage}</div> // urgent / errors
```

Rules:
- **`polite` for non-urgent updates** (saved confirmation, search results loaded).
- **`assertive` for errors and critical updates** — interrupts current screen reader speech.
- **The region must exist on first render**, even if empty. Adding the live region dynamically doesn't trigger announcements.
- **One toast region per page** — multiple regions compete and create noise.

## Color Contrast & Visual Design

Color contrast targets:

| Content | Minimum (AA) | Enhanced (AAA) |
|---------|--------------|----------------|
| Body text (small) | 4.5:1 | 7:1 |
| Large text (18pt+ or 14pt+ bold) | 3:1 | 4.5:1 |
| Non-text UI (focus rings, borders, icons) | 3:1 | — |

Tailwind tokens should encode these; if `text-foreground on bg-background` doesn't meet 4.5:1, the design system has a bug — fix at the token level, not per-component.

**Never communicate state with color alone.** A red border on an invalid field needs `aria-invalid` + an error message. Color blindness affects 1 in 12 men; everyone benefits from redundant cues.

## Motion & Reduced Motion

Some users get motion sickness from animations and transitions. Respect their preference:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

Or, in a Tailwind project, use `motion-safe:` and `motion-reduce:` modifiers.

```tsx
<div className="transition-transform duration-200 motion-reduce:transition-none">
```

Rules:
- **Respect `prefers-reduced-motion: reduce`.** Don't override it.
- **Default durations 150-250ms** for normal transitions. Longer only for full-page transitions.
- **Auto-playing video and parallax backgrounds** must respect the preference (or be opt-in).
- **Carousel auto-advance** must be pausable, and pauses by default if the user has reduced motion enabled.

## Headings & Document Structure

Headings are a navigation system, not a styling tool.

- **Exactly one `<h1>` per page**, conveying the page's purpose.
- **Don't skip levels.** `<h1>` → `<h2>` → `<h3>`. An `<h1>` followed by `<h4>` confuses screen reader navigation.
- **Heading text must be meaningful out of context.** Screen reader users may read the headings list — "Section 1" and "Section 2" tell them nothing.
- **Style is independent of level.** Use `text-2xl` etc. for visual hierarchy; the heading level is for document structure.

## Images

```tsx
import Image from "next/image";

// Decorative — empty alt
<Image src="/decoration.svg" alt="" width={48} height={48} />

// Informational — describe the content
<Image src="/team.jpg" alt="Three people in a meeting around a whiteboard" width={800} height={400} />

// Functional — describe the action
<a href="/profile"><Image src="/avatar.jpg" alt="View profile" width={32} height={32} /></a>
```

Rules:
- **`alt` is required** — empty for decorative, meaningful for informational. Never omitted.
- **Don't repeat content already in adjacent text.** If a caption already says "Team meeting," the alt should describe what's IN the image, not duplicate the caption.
- **Background images must not carry meaning.** If they do, they need to be `<img>` with alt text. CSS `background-image` is invisible to screen readers.

## Testing Accessibility

Two layers, both required:

### Automated (axe via Playwright in CI)

```ts
// e2e/accessibility.spec.ts
import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

test.describe("Accessibility", () => {
  ["/", "/sign-up", "/dashboard", "/invoicing"].forEach((path) => {
    test(`${path} has no axe violations`, async ({ page }) => {
      await page.goto(path);
      const results = await new AxeBuilder({ page })
        .withTags(["wcag2a", "wcag2aa", "wcag22aa"])
        .analyze();
      expect(results.violations).toEqual([]);
    });
  });
});
```

axe catches roughly 30-50% of accessibility issues — the deterministic ones. The rest require manual testing.

### Manual (per major change)

- **Keyboard-only navigation**: Tab through every interactive element. Can you reach everything? Activate everything? Is the focus ring always visible? Does Tab order make sense?
- **Screen reader smoke test**: VoiceOver (macOS) or NVDA (Windows). Navigate by headings, by landmarks, by form fields. Does it announce the right things?
- **Browser zoom to 200%**: Does the layout still work? Does any content disappear or get cut off?
- **High contrast / dark mode**: Are focus rings visible? Are disabled states distinguishable?
- **Motion off**: Set `prefers-reduced-motion: reduce` in dev tools. Are animations actually disabled?

## Anti-Patterns

1. **`<div onClick>` for buttons.** No keyboard, no role, no focus ring. Use `<button>`.
2. **`<a href="#">` for actions.** Hash navigation, not a button. Use `<button>` for actions, `<a>` for navigation.
3. **`outline-none` without `:focus-visible` replacement.** Strips keyboard accessibility silently. Always provide a visible focus indicator.
4. **`aria-label` on a visible-text button.** The visible text IS the label; `aria-label` overrides it and makes screen reader output diverge from sighted output.
5. **Ignoring the heading hierarchy.** Skipping levels, multiple `<h1>`s, using headings for visual styling.
6. **Color-only state.** Red border without an error message, green checkmark without text. Color blindness, screen readers, and printouts all break.
7. **Custom comboboxes without WAI-ARIA.** Hand-rolled autocomplete that doesn't follow the combobox pattern is reliably broken. Use `react-aria` / `radix-ui` / `cmdk`.
8. **Dialogs without focus trap or return focus.** Keyboard users escape the modal accidentally; sighted-only users don't notice.
9. **Toast regions added dynamically.** The live region must exist before the message arrives; otherwise the announcement is missed.
10. **Empty `alt=""` for informational images, or omitting `alt` entirely.** Empty for decorative, meaningful for informational. Omitted is a lint error.
11. **Disabled buttons with no explanation.** A disabled button needs an accessible reason — `aria-describedby` pointing to a hint, or a tooltip on focus.
12. **`tabIndex={1}` (or higher).** Hijacks tab order. Use DOM order; if the visual order doesn't match, restructure.

## Principles

1. **Semantic HTML first.** Every accessibility win starts with using the right element. ARIA is a fallback for the patterns HTML doesn't cover.

2. **Accessibility is a constraint, not a checklist.** It shapes every component as you write it, not a pass run before release. Designing for keyboard-first and screen-reader-first naturally produces good UX for everyone.

3. **No ARIA is better than bad ARIA.** A wrong `role` actively misleads. If you don't know the right ARIA pattern, ship the semantic element and let axe surface gaps.

4. **Focus is sacred.** Visible by default, never stripped without `:focus-visible` replacement, managed deliberately on navigation and dialog open/close.

5. **Forms are where accessibility wins or loses.** Labels, error association, autocomplete, validation announcements — get every form right and most of the accessibility battle is won.

6. **Test with axe AND your hands.** axe catches the deterministic 30-50%. The rest needs manual keyboard and screen reader testing. Both are required.

7. **WCAG 2.2 AA is the floor.** Aim higher where it materially helps users. The Apple bar is "every user can complete every task" — that's a higher standard than any single guideline document.
