# Web Design System

## Purpose
Define the load-bearing design-system architecture for modern web product work: a two-tier token system (primitives → semantic), Tailwind v4 as the CSS runtime, shadcn-style components owned by the codebase, dark/light theming that falls out of the token layer, and the rules for when to add a new token vs. reuse an existing one. This is the anchor skill for every other UI/UX web skill — responsive patterns, screen specs, interaction patterns, and design-side accessibility all reference the tokens defined here. See `team/ui-ux/skills/web-responsive-patterns.md` for layout primitives that consume these tokens. See `team/ui-ux/skills/web-screen-specification.md` for the handoff format that references these tokens. See `team/ui-ux/skills/web-accessibility.md` for design-side accessibility (color contrast at the token layer, focus-ring spec, motion tokens). See `team/developer/skills/web-architecture.md` for the folder layout that hosts `components/ui/`. See `team/developer/skills/web-modern-react.md` for composition patterns the components implement. Target: **Tailwind CSS 4+, shadcn/ui (Radix-based), React 19+, TypeScript 5.5+**.

## The One Rule That Anchors Everything

**No UI code references a primitive value.** Not a hex color, not a px value, not a font-family string, not a `blue-500`. Every UI surface — every component, every page, every spec — references a *semantic* token whose meaning is durable across rebrands, theme changes, and accessibility revisions.

If a designer can't change every "container background" in the product by editing one line, the token system has failed. If an engineer reaches for `bg-zinc-50` because "the surface token doesn't quite match," the answer is to fix the token, not to bypass it. Apple-quality systems don't have escape hatches; they have well-named primitives.

This rule is the difference between a design system and a stylesheet. Hold it.

## Two-Tier Token Architecture

Every token in the system lives at one of two tiers. UI code only ever references Tier 2.

| Tier | Name | Examples | Who references it |
|------|------|----------|------|
| 1 | **Primitives** (the palette) | `--color-blue-500`, `--space-4`, `--font-sans`, `--radius-md` | The semantic-token layer only. Never a component, never a screen spec, never a Tailwind utility in JSX. |
| 2 | **Semantic tokens** (the meaning) | `--color-surface`, `--color-text-on-surface`, `--color-accent`, `--color-danger`, `--space-page-gutter`, `--radius-control` | Everything in `components/ui/`, every screen spec, every utility class authored in JSX. |

The flow is one-directional: primitives feed semantic tokens; UI consumes semantic tokens. A rebrand swaps primitive values; a theme change swaps which primitives a semantic token points to. Component code is untouched in both cases.

```css
/* src/styles/tokens.css */
@layer tokens {
  :root {
    /* ── Tier 1: Primitives ─────────────────────────── */
    /* OKLCH for perceptual uniformity and P3 gamut. */
    --color-neutral-0:   oklch(100% 0 0);
    --color-neutral-50:  oklch(98% 0.005 240);
    --color-neutral-100: oklch(96% 0.01 240);
    --color-neutral-900: oklch(20% 0.02 240);
    --color-neutral-950: oklch(14% 0.02 240);
    --color-accent-500:  oklch(64% 0.18 250);
    --color-danger-500:  oklch(60% 0.22 25);

    --space-1: 0.25rem;
    --space-2: 0.5rem;
    --space-3: 0.75rem;
    --space-4: 1rem;
    --space-6: 1.5rem;
    --space-8: 2rem;
    --space-12: 3rem;

    --radius-sm: 0.25rem;
    --radius-md: 0.5rem;
    --radius-lg: 0.75rem;
    --radius-full: 9999px;

    --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
    --font-mono: "JetBrains Mono", ui-monospace, monospace;

    /* ── Tier 2: Semantic (light theme) ─────────────── */
    --color-surface:           var(--color-neutral-0);
    --color-surface-muted:     var(--color-neutral-50);
    --color-surface-raised:    var(--color-neutral-0);
    --color-border:            color-mix(in oklch, var(--color-neutral-900) 10%, transparent);
    --color-border-strong:     color-mix(in oklch, var(--color-neutral-900) 20%, transparent);
    --color-text:              var(--color-neutral-900);
    --color-text-muted:        color-mix(in oklch, var(--color-neutral-900) 65%, transparent);
    --color-text-on-accent:    var(--color-neutral-0);
    --color-accent:            var(--color-accent-500);
    --color-accent-hover:      oklch(from var(--color-accent-500) calc(l - 0.05) c h);
    --color-danger:            var(--color-danger-500);
    --color-focus-ring:        var(--color-accent-500);

    --space-page-gutter:       var(--space-4);
    --space-section-gap:       var(--space-12);
    --space-control-padding-x: var(--space-3);
    --space-control-padding-y: var(--space-2);

    --radius-control:          var(--radius-md);
    --radius-card:             var(--radius-lg);
    --radius-pill:             var(--radius-full);
  }

  :root[data-theme="dark"] {
    --color-surface:        var(--color-neutral-950);
    --color-surface-muted:  var(--color-neutral-900);
    --color-surface-raised: oklch(18% 0.02 240);
    --color-border:         color-mix(in oklch, var(--color-neutral-0) 10%, transparent);
    --color-border-strong:  color-mix(in oklch, var(--color-neutral-0) 20%, transparent);
    --color-text:           var(--color-neutral-50);
    --color-text-muted:     color-mix(in oklch, var(--color-neutral-50) 65%, transparent);
    /* Accent and danger usually stay the same — verify contrast in both themes. */
  }
}
```

A few non-obvious choices, each load-bearing:

- **OKLCH, not HSL or hex.** OKLCH is perceptually uniform — equal lightness deltas look equal to the eye, which means generated hover/active states from `oklch(from … calc(l - 0.05) c h)` are predictable. It also unlocks the P3 gamut on modern displays without breaking sRGB fallback. Browser support since 2023; modern-web baseline.
- **`color-mix()` for derived colors instead of separate primitives.** A muted text token is "65% of the text color, mixed with transparent" — one source of truth, automatically correct in both themes. No `--color-neutral-700-light` and `--color-neutral-300-dark` parallel scales.
- **Cascade Layers (`@layer tokens`).** Locks token specificity below components and utilities, so a desperate utility class can override a token reference without specificity wars.
- **Dark theme is a value swap, not a code branch.** Components never write `dark:bg-zinc-900`. They write `bg-surface`, and the surface token redefines itself under `[data-theme="dark"]`.

## Tailwind v4 as the Runtime

Tailwind v4 ships a CSS-first config (`@theme`) that maps the semantic tokens above into Tailwind's utility namespace. The JS-object `tailwind.config.ts` of v3 is legacy — don't write new projects against it.

```css
/* src/styles/globals.css */
@import "tailwindcss";
@import "./tokens.css" layer(tokens);

@theme {
  --color-surface: var(--color-surface);
  --color-surface-muted: var(--color-surface-muted);
  --color-surface-raised: var(--color-surface-raised);
  --color-border: var(--color-border);
  --color-border-strong: var(--color-border-strong);
  --color-text: var(--color-text);
  --color-text-muted: var(--color-text-muted);
  --color-text-on-accent: var(--color-text-on-accent);
  --color-accent: var(--color-accent);
  --color-accent-hover: var(--color-accent-hover);
  --color-danger: var(--color-danger);

  --spacing-page-gutter: var(--space-page-gutter);
  --spacing-section-gap: var(--space-section-gap);

  --radius-control: var(--radius-control);
  --radius-card: var(--radius-card);
  --radius-pill: var(--radius-pill);

  --font-family-sans: var(--font-sans);
  --font-family-mono: var(--font-mono);
}
```

This generates utilities the components use — `bg-surface`, `text-text-muted`, `border-border`, `rounded-card`, `gap-section-gap`. **The default Tailwind palette (`bg-zinc-50`, `text-blue-500`, etc.) should be considered absent from the project.** Don't disable it for ceremony's sake; just treat any appearance of a default-palette utility in a code review as a defect.

Why this design over "just use `bg-zinc-50` directly":

| Forces | Discipline | Default palette |
|--------|------------|------|
| Rebrand | Edit one primitive | Find/replace across the codebase |
| Dark mode | Swap semantic-token values once | Add `dark:` variants to every component |
| Accessibility audit | Adjust one token if contrast fails | Audit and patch every component independently |
| New designer joins | Reads a one-page token catalog | Reads the codebase to infer what colors mean |

## The Semantic Token Catalog

These are the tokens every product starts with. Add to this list cautiously (see next section).

### Color
| Token | Use |
|-------|-----|
| `surface` | Page background, default container fill |
| `surface-muted` | Subtle background for grouped content (e.g., a settings group, a callout) |
| `surface-raised` | Elevated surfaces — cards, popovers, modals |
| `border` | Default 1px separator |
| `border-strong` | Border that needs emphasis (focused input, selected card) |
| `text` | Primary text color |
| `text-muted` | Secondary text (captions, helper, timestamps) |
| `text-on-accent` | Text rendered on top of `accent` (typically white-ish in both themes) |
| `accent` | The product's one signature color, used for primary CTA, focus, links |
| `accent-hover` | Darker/lighter step of accent for hover/active |
| `danger` | Destructive actions, error states |
| `focus-ring` | The focus-visible outline color (often equal to `accent`) |
| `disabled-fg` / `disabled-bg` | Foreground/background for disabled controls. Distinct tokens — `opacity: 0.5` alone collides with focus-ring visibility, fails contrast for disabled-but-meaningful text, and discourages proper `aria-disabled` use. |

Two colors deliberately missing: `success` and `warning`. Most products invent them too early, then use them once. If a real surface needs a success state (e.g., a confirmation banner that lives across the product), promote a primitive at that point. Premature warning/success tokens are a smell.

### Spacing
The full primitive scale is `1, 2, 3, 4, 6, 8, 12, 16, 24` (rem multiples of 0.25). Most components use only `2`, `3`, `4`, `6`. Semantic spacing tokens live above primitives:

| Token | Use |
|-------|-----|
| `page-gutter` | Horizontal padding at the page edge — varies by breakpoint via container queries |
| `section-gap` | Vertical rhythm between major sections of a page |
| `control-padding-x` / `control-padding-y` | Internal padding shared by buttons, inputs, selects |

### Typography
A type scale of 6 sizes is enough for nearly any product. Apple's system uses fewer than that across iOS.

| Token | Size | Use |
|-------|------|-----|
| `text-display` | 48–72px (fluid) | Marketing hero only |
| `text-h1` | 32px | Page title |
| `text-h2` | 24px | Section title |
| `text-h3` | 18px | Subsection title |
| `text-body` | 16px | Default paragraph and UI text |
| `text-caption` | 13px | Helper text, metadata, timestamps |

Resist the seventh size. If a designer needs "something between h2 and h3," the answer is almost always to use one of the existing two and adjust hierarchy via weight, color, or position.

### Radius, Shadow, Motion, Layering
- **Radius**: `control` (buttons, inputs), `card` (cards, modals, popovers), `pill` (avatars, chips). Three is enough.
- **Shadow**: deemphasize. Apple uses shadows sparingly — almost never on flat UI, only on floating surfaces (popovers, drag previews). Two tokens cover this: `shadow-popover`, `shadow-drag`. Resist adding a "card shadow" — flat cards with a clear `border` token communicate elevation without the visual weight.
- **Motion**: define easing, duration, *and spring* tokens here, used by `team/ui-ux/skills/web-interaction-patterns.md` and `team/ui-ux/skills/web-accessibility.md`:

```css
/* Easing — for transitions */
--ease-standard:    cubic-bezier(0.2, 0, 0, 1);
--ease-emphasized:  cubic-bezier(0.3, 0, 0, 1);

/* Durations */
--duration-instant: 100ms;
--duration-short:   200ms;
--duration-medium:  300ms;

/* Springs — for animations that should feel physical (Apple's UI is spring-driven).
   CSS linear() is supported in Chromium 113+, Safari 17.4+, Firefox 112+.
   Generate via tools like easings.net or linear() generators. */
--spring-snappy: linear(0, 0.218 2.1%, 0.862 6.5%, 1.114, 1.224 9.4%, 1.244, 1.252, 1.246, 1.224, 1.183 12.8%, 1.097 14.3%, 0.946 16.5%, 0.317 23.4%, 0.121 27.1%, 0.029 32.5%, 0 40%);
--spring-gentle: linear(0, 0.05 5%, 0.40 20%, 0.85 50%, 1);
```

Use easing curves for everyday transitions; reach for springs when an element should feel like it has weight (popover open, drag drop, modal slide-up). A product that uses cubic-bezier for everything can never quite feel Apple-like even when the timings are right — physical-feeling motion is a discipline of its own.

Components reference these by name. `transition-all duration-300` with magic numbers is a defect.

- **Layering (z-index)**: a small explicit scale prevents the z-index chaos that grows organically in any product at scale. Five tokens are enough for almost any product:

```css
--z-base:    0;     /* default flow */
--z-popover: 100;   /* dropdowns, tooltips, popovers */
--z-modal:   200;   /* modal dialogs, sheets */
--z-toast:   300;   /* transient notifications */
--z-tooltip: 400;   /* tooltip on top of everything (rare; use sparingly) */
```

Every floating surface uses a token; `z-index: 9999` and `z-index: 99999` in component code are defects. The relative ordering — popover < modal < toast — is what prevents "my toast is hiding behind my modal" bugs.

## When to Add a New Token vs. Reuse

Token bloat is a real failure mode — once a system has 200 semantic tokens, no one knows which to use, designers pick by vibe, and the system effectively reverts to a stylesheet. Hold this line:

**Add a new semantic token only when the new use is conceptually distinct from every existing token.** A "conceptually distinct" use is one where, if a future rebrand changed it, you would want it to change *separately* from every other use it currently shares a value with.

Examples:

| Situation | Add new token? | Why |
|-----------|---------------|-----|
| The design needs a slightly different shade of border for a focused input | **No** — use `border-strong` (which already exists for emphasized borders) | "Focused input border" and "selected card border" are the same concept ("border that needs emphasis"). One token, two surfaces. |
| Marketing wants a soft mint background on the homepage hero | **No** — this is an art-directed surface, not a system token. Inline the value at the marketing component, with a comment that it's intentionally outside the system. | One-off creative use doesn't justify a system addition. The system covers product surfaces. |
| The product introduces a "Pro tier" accent color used across upgrade UIs throughout the product | **Yes** — add `accent-pro`. It will appear on dozens of surfaces and needs to be theme-aware and contrast-checked. | New, recurring concept. Will outlive any single screen. |
| A designer requests a 17px font size between body (16) and h3 (18) | **No** — pick one and adjust weight/color | The system is intentionally sparse. Sizes between existing sizes signal hierarchy confusion, not a missing token. |
| The product needs a "warning" surface for billing reminders that appear on multiple screens | **Yes** — add `surface-warning`, `text-on-warning` | Recurring distinct concept; promote from one-off to system. |

When in doubt: **start without the token. Inline the value with a comment. Promote to a token when a third surface needs it.** The third use is the pattern; the first two are anecdotes.

## Forced Colors (Windows High Contrast Mode)

Windows High Contrast Mode (and `prefers-contrast: more`) lets users override the product's color system entirely with system colors. This is a real primary user mode at least as common on enterprise Windows as `prefers-reduced-motion` is on macOS — and the token system, by design, gets bypassed when it's active. The fix is *not* to fight it; it's to ensure the product still works.

```css
@media (forced-colors: active) {
  /* System colors take over: CanvasText, ButtonText, LinkText, Highlight, etc.
     The token system is overridden — design must survive without color tokens. */

  .button {
    /* Use system colors so OS contrast pairings hold */
    border: 1px solid ButtonText;
    color: ButtonText;
    background: ButtonFace;
  }

  .focus-visible {
    /* OS focus indicator is preserved; ours may be invisible */
    outline: 2px solid Highlight;
    outline-offset: 2px;
  }
}
```

What breaks in forced-colors and how to design around it:

- **Background images and gradients** disappear (the OS forces a flat background). Don't communicate state via gradient buttons or image-as-icon.
- **Box shadows** are discarded. Don't rely on shadow as the only elevation signal.
- **Icons rendered as background images** become invisible. Use inline SVG or icon fonts so the OS can color them.
- **Borders are visible by default.** A button distinguished only by background color disappears; one with a `1px solid` border survives.

The audit: turn on Windows High Contrast Mode (or DevTools "Emulate forced-colors: active") and verify every interactive element is still distinguishable. Buttons should look like buttons; links should look like links; focus should be visible. If anything disappears, fix it via the strategies above. See `team/ui-ux/skills/web-accessibility.md` for the full design-side a11y treatment.

## Dark Mode (Falls Out For Free)

Because UI code references semantic tokens and the dark theme redefines those tokens at the `:root[data-theme="dark"]` layer, dark mode requires zero work in components. A `<Button>` written with `bg-accent text-text-on-accent` is correct in both themes by construction.

What this rules out:

- `dark:bg-zinc-900` style variants in component code. If you see one in a PR, it's a defect — the token system isn't being used.
- Per-component dark-mode overrides in CSS. Same thing in CSS shape.
- A separate "dark theme component" (e.g., `<DarkButton>`). The component is unaware of theme.

What it requires once, at the app shell:

- A `data-theme` attribute on `<html>` set from a user preference (with `prefers-color-scheme` as the default), persisted in a cookie so the server can render the correct theme on first paint without a flash.
- A theme-toggle component that updates the attribute and the cookie.

Verify dark mode by switching the attribute in DevTools and scanning the screen. Anywhere the design breaks in dark mode is a token bug — the fix is in `tokens.css`, not in the component.

### Why Not `light-dark()`?

CSS `light-dark(light, dark)` (Interop 2024) is a modern alternative for declaring per-token light/dark values inline. It's well-supported and ergonomic for client-only apps. We use the attribute-swap pattern instead because **server-rendered theme without flash requires the server to know the theme on first paint**, which means the theme has to be a cookie-readable attribute — not a CSS-resolved preference. `light-dark()` resolves at the client based on `color-scheme`, which is too late for SSR.

If a project ships as a pure client-rendered SPA (rare for this stack), `light-dark()` is acceptable and shorter. For Next.js App Router with SSR, the attribute swap is the modern correct pattern.

## shadcn-Style Components: Owned, Composed, Variant-Driven

The library lives in `components/ui/`. Components are *copy-pasted into the codebase*, not installed as a package. This is non-obvious to engineers used to MUI, Chakra, or Mantine, but it's the correct architecture and worth defending:

| Owned-in-repo (shadcn) | Packaged dependency |
|-----------------------|---------------------|
| Edit any component for product needs | Wrestle with library author's API |
| Tailwind tokens are the styling system | Library brings its own theming layer |
| No version-bump churn for cosmetic changes | Major version bumps break the design |
| Dependency surface is Radix primitives only | Dependency surface is the entire library + its peer deps |
| New patterns added by writing one file | Extension requires forking or wrapping |

Each component is built on a **Radix primitive** for behavior (focus management, ARIA, keyboard handling, portal management) and styled with the token system.

```tsx
// components/ui/button.tsx
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/cn";

const buttonVariants = cva(
  // Base — applies to every variant
  "inline-flex items-center justify-center gap-2 font-medium " +
  "rounded-control transition-colors duration-short ease-standard " +
  "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-focus-ring focus-visible:ring-offset-2 focus-visible:ring-offset-surface " +
  // Disabled uses the dedicated tokens, NOT opacity. Opacity-only disabled
  // collides with focus-visible visibility and fails contrast for disabled
  // text. Pair the visual with `aria-disabled` (or the native `disabled`
  // attribute on real <button>) so SR users hear the state.
  "disabled:bg-disabled-bg disabled:text-disabled-fg disabled:pointer-events-none",
  {
    variants: {
      intent: {
        primary:   "bg-accent text-text-on-accent hover:bg-accent-hover",
        secondary: "bg-surface-muted text-text border border-border hover:border-border-strong",
        ghost:     "bg-transparent text-text hover:bg-surface-muted",
        danger:    "bg-danger text-text-on-accent hover:opacity-90",
      },
      size: {
        sm: "h-8  px-control-padding-x text-caption",
        md: "h-10 px-control-padding-x text-body",
        lg: "h-12 px-6 text-body",
      },
    },
    defaultVariants: { intent: "primary", size: "md" },
  },
);

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

export function Button({
  className, intent, size, asChild = false, ref, ...props
}: ButtonProps & { ref?: React.Ref<HTMLButtonElement> }) {
  const Comp = asChild ? Slot : "button";
  return <Comp ref={ref} className={cn(buttonVariants({ intent, size }), className)} {...props} />;
}
```

Three patterns to internalize:

1. **`cva` for variants.** Each visual variant is a named option (`intent: "primary"`), not a boolean prop (`<Button primary>`). Adding a new variant is one line. Removing one is one line. The variant-to-class mapping is in one place, not scattered across `clsx` calls.
2. **`asChild` (Radix Slot pattern).** Lets a caller pass any child element and have it inherit the button's styles and behavior — the canonical use is `<Button asChild><Link href="…">Open</Link></Button>`, which renders as an `<a>` styled like a button without the accessibility hazards of `<a><Button /></a>`. Polymorphism without the `as` prop's type ergonomics problems.
3. **Composition over configuration.** The `<Button>` exposes `intent`, `size`, and standard button attributes. It does not grow `iconLeft`, `iconRight`, `loading`, `tooltip`, `confirmText`, `dropdown` props. Composition handles those — `<Button><LoadingSpinner />Save</Button>`. A 12-prop component is a missing 3 components.

## Component vs. Token: Where Does X Go?

| If the change is… | It belongs in… |
|-------------------|---------------|
| The accent color of every primary button across the product | A token (`--color-accent`) |
| The padding inside every button regardless of intent | A token (`--space-control-padding-x`) |
| A new button intent ("subtle outline", say) | A new variant in `buttonVariants` |
| A new button shape (icon-only square, say) | A new variant `shape: "square"` |
| A one-off adjustment for a specific screen ("this button needs a custom icon arrangement") | Caller composes with `<Button>…</Button>` and arranges children |
| A whole new pattern (toast notifications) | A new component in `components/ui/` |
| A pattern that's specific to one feature, not reused | A feature-scoped component in `features/<x>/components/`, not in `components/ui/` |

The `components/ui/` folder should stay small. A library with 50 components is mostly dead code. Better: 12 well-designed primitives that compose.

## Where It Lives (file map)

```
src/
  styles/
    tokens.css          # Tier 1 primitives + Tier 2 semantic tokens, both themes
    globals.css         # @import tokens, @theme mapping, base styles, font setup
  components/
    ui/                 # Design-system primitives — owned in repo
      button.tsx
      input.tsx
      label.tsx
      dialog.tsx        # Wraps Radix Dialog
      popover.tsx       # Wraps Radix Popover
      ...
  lib/
    cn.ts               # clsx + tailwind-merge helper used by every variant component
```

The token file is the single source of truth. If a designer asks "what's the product's accent color?", the answer is "open `tokens.css` and read the `--color-accent` line." Nothing in Figma, no Notion page, no Slack message — the file is the spec.

A separate `knowledge-base/design-system-reference.md` in each project mirrors this catalog in human-readable form (for the Developer's reference, the QA agent's expectations, and future designers' onboarding). The CSS file is authoritative; the markdown file is a view of it.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **Raw hex colors in component code or specs.** `bg-[#1A1A1A]`, `style={{ color: "#888" }}`, `border: 1px solid #ccc`. | The system has no record of this color. It can't be themed, contrast-checked, or rebranded. | Replace with a semantic token. If no token fits, that's the signal to add one (see decision rules above). |
| **Default Tailwind palette in JSX.** `bg-zinc-50`, `text-blue-500`, `border-gray-200`. | Same failure mode as raw hex, just dressed up. Bypasses the entire token system. | Replace with a semantic token. Treat any default-palette utility as a code-review defect. |
| **`dark:` variants on individual components.** `<div className="bg-white dark:bg-zinc-900">`. | The token system is supposed to handle dark mode. A `dark:` variant in component code means a missing or ignored token. | Use `bg-surface`. The token resolves correctly in both themes. |
| **Configurable prop explosion.** A `<Card>` with `title`, `description`, `actions`, `footer`, `headerColor`, `border`, `padding`, `elevation` props. | Composition is the right API. Every new design need adds a prop, the component grows monstrous, and 90% of props are unused on any given instance. | Expose `<Card>`, `<CardHeader>`, `<CardBody>`, `<CardFooter>`. Caller arranges. |
| **Boolean variant props.** `<Button primary danger small>`. | Two booleans means four states — three of which are nonsense (a button can't be both primary and danger). The type system should make invalid states unrepresentable. | Use a single discriminated `intent` prop with named variants. `cva` enforces this. |
| **Token at the wrong tier.** A component that references `--color-blue-500` directly. | Cuts the system in half. The component now requires a code change for a rebrand. | Always reference Tier 2. Primitives are for the token layer's eyes only. |
| **One-off utility classes that override tokens.** `<Button className="bg-purple-500">` to make a button "stand out on this one screen." | The product accumulates dozens of "just this once" colors that designers can't track. | Either it's a real product need (add a token or variant) or it's a one-off art-directed surface (inline with a comment explaining why it's outside the system). The middle path of "override on the fly" is what kills design systems. |
| **Inventing a new component for every screen.** Each new feature folder has a `Card`, `Panel`, `Tile`, `Box`, `Container`. | The library balloons, primitives diverge, the design feels less coherent over time. | Use the primitive. If it doesn't fit, fix the primitive. |
| **Shadow as the elevation system.** Three shadow tokens for "elevation 1, 2, 3." | Shadows on flat UI feel dated and noisy. Apple uses shadow sparingly, only on floating surfaces. | Use `border` or `surface-raised` to communicate elevation. Reserve shadow for popovers and drag previews. |
| **Theming via class name on `<html>` plus per-component overrides.** `.theme-blue .btn-primary { … }`. | Couples themes to components, requires a global stylesheet edit for every theme change. | Themes are token-value swaps under `[data-theme="…"]`. Components are theme-unaware. |

## Principles

1. **One token system, used everywhere.** A design system is not a library of components — it's a token system, and the components are one of its consumers. Specs reference tokens. Components reference tokens. Marketing pages reference tokens. The product feels coherent because it shares a vocabulary, not because it shares classnames.

2. **Two tiers, one direction.** Primitives feed semantic tokens. Semantic tokens feed UI. Components never reach past semantic into the primitive palette. This rule is what makes rebrands a one-line change instead of a quarter-long project.

3. **Fewer tokens than you want.** The pressure on a maturing design system is always to add more — a token for every new shade, a size for every new context. Resist. Apple ships products with type scales of 6 sizes and color systems of fewer than 20 semantic colors. Sparseness is the system; abundance is the failure.

4. **Composition over configuration.** Components expose small, orthogonal APIs (intent, size, plus standard HTML attributes) and rely on children for arrangement. A 30-prop component is three components in a trench coat.

5. **Themes are token-value swaps, never component branches.** Dark mode, branded subdomains, white-label deployments — all are solved by redefining semantic tokens under a scope. Component code is theme-blind.

6. **Behavior comes from Radix; styling comes from tokens.** Component composition wins on two axes: Radix handles the hard work (focus, keyboard, ARIA, portals); the token system handles the look. Owned-in-repo gives the team final say over both.

7. **The token file is the spec.** No design tool, no documentation site, no shared doc beats `tokens.css` as the source of truth. Every other artifact is downstream of it.

8. **A token's job is to outlive a redesign.** If a token needs to change every time the product is redesigned, it's named for its appearance, not its purpose. Rename `--color-blue-button` to `--color-accent` before it ships. The right name describes the role, not the rendering.
