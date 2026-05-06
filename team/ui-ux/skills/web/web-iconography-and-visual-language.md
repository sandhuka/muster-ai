# Web Iconography and Visual Language

## Purpose
Define how to design the product's visual language: icon library choice (one library, owned), icon size and stroke-weight scale, optical alignment with type, icon-only button rules, illustration system (when to commission, when to avoid entirely), photography treatment, OG / social card design, favicon system, and the installable-PWA app icon. iOS gets a coherent visual language for free via SF Symbols + the HIG; web has to author the system. The vibes-coded default is to mix three icon libraries, sprinkle stock illustrations from undraw.co, slap a generic favicon together, and call it design — and the result is a product that looks like every other vibes-coded SaaS. Apple-quality web visual language is an authored system, with the same restraint and discipline as the design-system tokens. See `team/ui-ux/skills/web-design-system.md` for the tokens (color, type, spacing) the visual language consumes; iconography is parallel — its own system, its own tokens (size scale, stroke weight). See `team/ui-ux/skills/web-content-hierarchy.md` for the four-lever framing iconography supports (icons should never be load-bearing for hierarchy). See `team/ui-ux/skills/web-accessibility.md` for the icon-as-text-replacement a11y rules (`aria-label`, `aria-hidden`, decorative-vs-meaningful distinction). See `team/ui-ux/skills/web-marketing-and-conversion-pages.md` for OG card design as part of marketing-page craft. See `team/ui-ux/skills/web-localization-and-i18n.md` for icon mirroring in RTL (paired directional siblings, not CSS-flip) and cultural icon meaning. See `team/ui-ux/skills/web-empty-error-and-edge-states.md` for the illustration policy in empty states (which references this skill's "no stock illustrations" rule). See `team/ui-ux/skills/web-onboarding-flows.md` for onboarding's illustration policy (same source-of-truth — this skill). See `team/ui-ux/skills/web-interaction-patterns.md` for the View Transitions API mechanism that signature transitions are built on. Target: **product UI on web — the icons, illustrations, photography, OG cards, favicons, and PWA app icons that constitute the visual language**.

## Brand Mark vs. Functional Icon: A Distinction That Matters

Two categories of visual element are easy to conflate but follow different rules:

| Concern | Brand mark (logo, wordmark, app icon, favicon) | Functional icon (nav, action, status) |
|---------|------------------------------------------------|--------------------------------------|
| Source | Authored once per brand; rarely changed | Pulled from chosen icon library |
| Sizing | Fixed canvas with safe area | Variable across the size scale |
| Color | Brand color, often non-token (the brand color is the brand) | `currentColor` from surrounding text |
| Dark mode | Designed twice — light variant + dark variant; never tinted | Token-driven; works in both themes via inheritance |
| Motion | Signature; carries brand personality (logo reveal, app-icon tap bounce) | Functional only (hover state, loading spinner) |
| Mirroring (RTL) | Never mirrored (logos are not directional) | Swap to directional sibling per `team/ui-ux/skills/web-localization-and-i18n.md` |
| Optical alignment | Sits on its own canvas, doesn't align to type baseline | Aligns to type baseline (see Optical Alignment below) |

The rest of this skill addresses both — sections on functional iconography (size scale, optical alignment, icon-only buttons, library choice), then sections on brand mark expression (logo in dark mode, brand expression in motion, signature transitions, app icon, PWA splash). Don't apply functional-icon rules to brand marks or vice versa.

## The Anchor: Pick One System and Hold It

The single most-violated rule in product visual language: **pick one icon library, one stroke weight, one illustration treatment, and hold the line.** Every "we'll use Lucide for nav, Heroicons for actions, and a custom set for the hero" decision is a coherence failure that compounds with every screen.

Apple's web properties demonstrate this without effort because Apple authors its own visual language. A product without that authoring budget can still ship coherent visual language by choosing existing systems and committing to them — but only if the team treats "pick one and stick with it" as non-negotiable.

Two implications:

1. **Mixing icon libraries is the visual-language equivalent of mixing default-Tailwind-palette colors with semantic tokens.** Every icon should come from the same library. If a needed icon doesn't exist there, draw a custom one in the same style (same stroke weight, same corner radius, same proportions) — or rethink the need.
2. **Don't add new visual primitives without removing one.** The product accumulates icon styles, illustration approaches, photography treatments. Each addition that isn't deliberate degrades the system. Periodically audit and prune.

## Icon Library Choice

For a new product launching now, the realistic choices:

| Library | Style | Best for |
|---------|-------|----------|
| **Phosphor** | Rounded, multi-weight (Thin / Light / Regular / Bold / Fill) | Products that want optionality across weights and a friendly feel |
| **Lucide** | Sharp, single weight, open-source community | Default for productivity tools; Linear/Vercel-adjacent feel |
| **Heroicons** | Tailwind official, Outline + Solid pair | Tight integration with Tailwind ecosystem; clean and minimal |
| **Tabler Icons** | Outline-style, large set | Comprehensive coverage; less distinctive |
| **Custom (SF-Symbols-style)** | Authored per product | Brands with budget for distinctive icon work |

The choice is mostly stylistic; the discipline is in committing. Pick one. Don't mix.

### Once Chosen

- **One stroke weight per context.** Phosphor's variable weights are tempting, but using Thin in nav and Bold in toolbar reads as inconsistent. Pick one weight (typically Regular) and apply it across the product. Use other weights only with explicit purpose (e.g., Bold for the active state).
- **One size scale.** 16, 20, 24, 32 — most products need only these four sizes. Larger sizes (48, 64) for hero / marketing only.
- **Color is the design system's job, not the icon library's.** Icons inherit `currentColor`; they take their color from the surrounding text. Don't pre-color icons.

## Size Scale and Optical Alignment

| Size | Use |
|------|-----|
| **16px** | Inline within body text (e.g., a chevron next to a link), dense table cells, secondary metadata |
| **20px** | Toolbar icons, button-internal icons next to body text, list-item leading icons |
| **24px** | Standalone icon buttons, primary nav, prominent actions |
| **32px** | Empty-state visuals, marketing-section accents, large action targets |

These are the *visual* sizes; the touch-target hit area is always 44×44 minimum on touch (see `team/ui-ux/skills/web-accessibility.md`).

### Optical Alignment

An icon's geometric center is not always the visual center. A circle and a triangle of the same height look different sizes; a chevron-right's visual weight sits to the right of the geometric center. This produces the alignment problem most products get wrong: a 24px icon next to 16px body text looks "off" because the icon's centerline doesn't sit on the type baseline.

The discipline:

- **Align icons to the cap height of body text**, not to the line height. The icon visually sits at the same vertical position as a capital letter.
- **Use `vertical-align: -0.125em` or `-0.15em`** to nudge icons down so their centerline matches the baseline. The exact value depends on the font and icon library; calibrate once per product.
- **For larger icons** (24px+ next to 16px body), the alignment is more visible; calibrate carefully. For small icons (16px), the misalignment is usually invisible.

This is per-icon-library calibration work that pays off forever. Spend the hour up front.

## Icon + Label vs. Icon-Only

The default: **icon + label.** An icon paired with a text label is more discoverable, more accessible, and more localizable than an icon alone. Reserve icon-only for:

- **Dense toolbars** where the user sees the same icons repeatedly (formatting toolbars, code editors). Tooltips on hover for first-time discovery; the user learns through repetition.
- **Universally-known controls** (close `×`, search 🔍, menu hamburger ☰, settings gear). Even here, pair with label when the surface allows.
- **Per-row actions in a dense table** where labels would overflow. Tooltip on hover; explicit menu for accessibility.

Anti-pattern: icon-only buttons that *aren't* universally known. A pencil icon means "edit" to most users, but a sliders icon for "filters" requires learning. Pair with label when in doubt.

### The `aria-label` Rule

Every icon-only button has an `aria-label` describing the action. The label is the screen-reader user's only way to know what the button does. The visual icon is invisible to them.

```tsx
<button aria-label="Close dialog">
  <XIcon aria-hidden="true" />
</button>
```

Decorative icons (next to a text label) are `aria-hidden="true"` — the surrounding text already announces the action; the icon adds no information for SR users. See `team/ui-ux/skills/web-accessibility.md` → aria-label-bombing for what *not* to do.

## The Illustration System (or the Decision Not to Have One)

Most products should not have an illustration system. The Apple-quality stance: **a great illustration is a force multiplier; a mediocre illustration is worse than none.** And building a great illustration system is expensive — custom commissioned art per surface, consistent style, multiple variants per state.

The honest options:

| Option | When |
|--------|------|
| **No illustrations** | Default. Strong typography + restraint communicates plenty. Apple's product UI uses very few illustrations. |
| **Single curated illustrator** | When the product has the brand budget for it. Linear, Notion, and Figma have invested here. |
| **Open-source illustration set used selectively** | A specific set used for specific purposes (onboarding only, empty states only) — not "drop into any empty space." |
| **Stock illustration libraries (undraw.co, Storyset, etc.)** | **Almost always wrong.** Generic, off-brand, instantly recognizable as "vibes-coded SaaS." |

When you do invest in illustrations:

- **One illustrator, one style.** Two illustrators always look like two illustrators. Pick one and commit.
- **Defined use cases**: onboarding empty states, marketing pages, error pages — each with its own size and treatment standard.
- **Variants per theme**: light and dark variants, never just "tinted-down dark version." Designed twice, shipped twice.
- **Restrained color**: illustrations use the brand palette, not their own. They feel like part of the product, not visitors.

### Why Stock Illustrations Are Almost Always Wrong

The "people-shaped-blob" style of undraw.co and its clones is so recognizable that a knowledgeable user identifies the source within seconds. Using it signals "this product didn't invest in design," which in turn signals "this product probably doesn't invest in other things either." For a product trying to be Apple-quality, that signal is fatal.

If the budget is "no illustrations," ship no illustrations. Strong typography + token-driven UI + restrained color is an honest, calm, Apple-adjacent aesthetic. Stock illustrations are always a downgrade from honest restraint.

## Photography Treatment

Most product UI doesn't use photography. When it does (marketing pages, content products, profile photos, content imagery):

- **One photographer or one art director, one treatment.** Color grading, framing, lighting consistent across the set.
- **Authentic over staged.** Real customers in real spaces beat stock photography by every measure.
- **Diverse representation as a default**, not an afterthought. The set of photos in a product communicates who the product is for.
- **No "diverse team shaking hands" stock.** This category of stock is so ubiquitous that it signals "we needed photos and didn't think about it."
- **Avoid hand-gesture imagery for cross-cultural products** (see `team/ui-ux/skills/web-localization-and-i18n.md` → Cultural Meaning).

### Image Sourcing Discipline

For products with content imagery (e.g., blog posts, product cards, marketing landing pages):

- **Original photography** when budget allows.
- **Curated stock** (Unsplash with attribution, paid stock with rights) — but vetted for "doesn't look like stock."
- **AI-generated imagery in product or marketing surfaces is an anti-pattern at the Apple-quality bar.** Apple does not ship AI-generated imagery in its marketing or product surfaces; doing so signals exactly the "vibes-coded" aesthetic Muster's positioning rejects. The exceptions where AI-generated imagery is acceptable: internal-only tooling, data-visualization placeholders, prototype mockups not intended to ship. For any user-facing brand or marketing surface, commission real work or ship none.
- **Image dimensions and aspect ratios are part of the design system** (`aspect-card`, `aspect-hero`, `aspect-thumbnail`). Don't ad-hoc per use.

## OG / Social Card Design

Every shareable URL has a designed OG image. See `team/ui-ux/skills/web-marketing-and-conversion-pages.md` → OG / Social Card Design for the marketing-side craft. The visual-language angle:

- **Templated per route type** (landing-page template, blog-post template, product-page template). Custom per-page only for marquee pages.
- **Brand-consistent**: same typography as the product, same colors, same restraint.
- **Per-route variability via Next.js OG image API** (`next/og`) — render at request time with the route's actual content (post title, author, hero image).
- **1200 × 630px**. Twitter, LinkedIn, Slack, Facebook all use this. iMessage uses a smaller crop; design with the safe-area in mind.

A well-designed OG card is one of the cheapest brand investments — every share is free brand impressions, and a templated OG generator pays back forever.

## Favicon System

The favicon is the most-overlooked brand asset, and the most-visible. Every browser tab shows it; every bookmark; every browser-history entry.

The modern correct favicon set:

- **`favicon.svg`** (modern browsers, scales to any size). Single SVG, 512×512 viewBox, transparent background, dark-mode-aware via CSS media queries inside the SVG.
- **`favicon.ico`** (legacy fallback for old browsers). 32×32 or multi-size .ico.
- **`apple-touch-icon.png`** (iOS home-screen). 180×180, no transparency (iOS adds rounded corners).
- **PWA manifest icons**: 192×192 and 512×512 PNG, plus a *maskable* variant (see PWA section below).

```html
<link rel="icon" href="/favicon.svg" type="image/svg+xml" />
<link rel="icon" href="/favicon.ico" sizes="any" />
<link rel="apple-touch-icon" href="/apple-touch-icon.png" />
<link rel="manifest" href="/manifest.webmanifest" />
```

### Favicon Design Discipline

- **Recognizable at 16×16.** The most-common rendering size. If the favicon is a complex logo, simplify — many brands use a single letter or a symbol mark for the favicon.
- **Different from competitors at 16×16.** A blue "D" is indistinguishable from a hundred other blue D-favicons. Use color, shape, or treatment that stands out.
- **Dark-mode variant**: when the OS is in dark mode, the favicon's tab background may be dark. Test against both. SVG favicons can use `@media (prefers-color-scheme: dark)` inside the SVG to swap colors.
- **Padding inside the canvas**: the favicon visually fills its space; don't render a tiny logo with empty padding around it.

## Logo and Wordmark in Dark Mode

The brand mark is *not* a token. Tinting the logo via `filter: invert(1)` for dark mode produces visually-wrong color (a navy-blue logo becomes orange) and defeats the brand. The discipline:

- **Design two variants explicitly**: a light-on-dark version and a dark-on-light version. Both ship as separate assets.
- **Switch via `<picture>` with `prefers-color-scheme` media** or via a CSS `@media (prefers-color-scheme: dark)` query that swaps the `background-image` URL.
- **Sometimes the dark-mode variant drops the wordmark** to a symbol-only mark. Apple's wordmark is text-based and works in both themes; a brand whose logo is text + symbol may simplify to symbol-only on dark surfaces where the text version becomes too low-contrast.
- **Don't auto-invert.** A logo with intentional color (the brand-blue, the brand-red) is wrong when inverted. Always design, never compute.
- **Test the logo on every surface it appears on**: marketing hero, app shell, transactional email header, OG card, favicon, PWA app icon, sign-in screen. The same logo at six surfaces with two themes is twelve renders to verify.

This is the most-overlooked area of brand expression on the web. Most products ship a single logo asset and let CSS / OS dark-mode treatment handle the rest — and then wonder why the brand reads as off in dark mode. Design twice; ship twice.

## Brand Expression in Motion

Apple's brand has signature motion that you can identify without seeing the logo: the iOS app-icon tap bounce, the Mac dock magnification curve, the Watch crown-driven UI spring, the iMessage send-with-effect sheen. These aren't UI affordances — they're brand expression in motion form. The motion vocabulary itself is part of how the brand feels.

Web brands have analogues: Linear's command palette has a specific feel; Vercel's logo wordmark has a signature reveal animation; Stripe's gradient hero has its own pacing; Notion's page-load fade is recognizable. The discipline:

- **Define one or two signature motion moments** that are unmistakably brand-tied. The logo-reveal animation. The hero-section enter. The primary CTA's hover/active treatment. Don't sprinkle "branded motion" across the product; pick the moments and treat them with care.
- **Use the design-system motion tokens** (`--spring-snappy`, `--spring-gentle`, `--ease-emphasized` from `team/ui-ux/skills/web-design-system.md`) — but the *choice* of which token to use where is brand-language work, not just pattern-matching to the closest token.
- **Reduced-motion alternatives are mandatory**, and the alternative still reads as on-brand (a static composition that captures the same mood as the motion). Disabling the motion shouldn't make the brand surface feel broken.
- **Restraint is the brand**. A brand that reaches for motion at every opportunity reads as eager; one that reserves motion for the right moments reads as confident. Apple's UI has very little motion most of the time; the motion that exists is conspicuous.
- **Motion-on-load is high-stakes territory.** First impression. A wordmark that animates in subtly on first paint, then sits still for the rest of the session, is a brand signature. A wordmark that animates on every navigation is a distraction.

The motion tokens live in design-system; the *brand decision* about which moments get signature motion lives here.

## Signature Transitions

Adjacent to brand expression in motion, signature transitions are the cross-surface continuity moments that make the product feel coherent. The View Transitions API (see `team/ui-ux/skills/web-interaction-patterns.md`) is the mechanism; the *brand-language layer above it* is what this section covers.

- **Identify the transitions that matter**: a list-item expanding into a detail view; a hero image persisting across page navigation; a tab switch that morphs the active indicator. Pick a small set; don't sprinkle.
- **Each signature transition has its own timing curve and feel**, anchored on the brand's motion vocabulary. Apple's "zoom in to detail" is distinct from Notion's "fade-and-slide to drawer" — both are correct for their respective brands.
- **Cross-surface continuity**: if the home screen's product card uses a corner radius of 16px and a shadow-sheet of `--shadow-popover`, the detail view's hero should match — so the transition feels like the same object growing, not two unrelated views.
- **Reduced-motion fallback**: instant cut. The transition disappears; the destination renders directly. Don't try to "soften" a reduced-motion transition; either it's there or it isn't.

Signature transitions are reserve-for-marquee territory. A product where every navigation has a custom transition reads as overdesigned; one with two or three signature transitions in the right places reads as authored.

## PWA App Icon

For products that ship as an installable PWA (added to home screen on mobile, added to dock on desktop), the app icon is the brand's avatar on the user's device.

- **512×512 PNG** in the manifest, with a **maskable variant** (different file, same size). Maskable icons are designed for system-imposed shapes (iOS rounded square, Android variable) — the icon must work when cropped to a circle, a squircle, or a rounded rectangle.
- **Safe area for maskable**: the icon's important content lives in the central 80% of the canvas; the outer 20% is "trim safe" — content there may be cropped depending on the OS.
- **Solid background, not transparent.** Transparent PWA icons look broken when the OS adds its own background.
- **Distinctive at small sizes.** The home-screen icon renders at ~60–80px on phones; the dock at ~64px on desktop. The icon must read at those sizes.

Apple's iOS app icons are the reference: simple silhouette, strong color, no text inside the icon, distinctive at thumbnail size. Aim for that level of clarity.

### PWA Splash Screen

When the user launches an installed PWA, the OS shows a splash screen for the brief moment before the app shell renders. This is the second-most-visible brand asset after the icon (especially on mobile, where launch latency is most felt).

- **Background color**: declared in the manifest (`background_color`). Should match the app's first-paint background — if the app shell renders with a white background, the splash background is white; if dark, dark. A mismatch produces a visible flash.
- **Theme color**: declared as `theme_color` in the manifest; sets the OS chrome color (status bar tint on iOS, system-bar color on Android).
- **Splash icon**: most platforms render the app icon centered on the splash background. Some (older iOS) need explicit `<link rel="apple-touch-startup-image">` per device size — the modern correct stance is to ship the manifest icons and let the OS handle splash composition where supported, with one or two fallback startup images for legacy iOS.
- **Don't try to design a custom splash composition** with marketing imagery — the OS owns the layout, and the brand expression is the icon + background color, nothing more. Trying to control more produces broken-on-some-devices output.

Specify `background_color` and `theme_color` in the manifest in light and dark variants where supported. Test the launch experience on both iOS and Android before shipping the PWA.

## Color Application in Visual Language

Iconography and illustrations consume the design-system color tokens (see `team/ui-ux/skills/web-design-system.md`). Discipline:

- **Icons inherit `currentColor`**, taking their color from the surrounding text. Don't pre-color icons except for status indicators (success / warning / danger have their own tokens).
- **Illustrations use the brand palette only**, not their own custom palette. An illustration with off-brand colors looks like a sticker pasted onto the product.
- **Photography color grading**: match the product's overall palette in saturation, warmth, and contrast. A single warm-toned photo in an otherwise cool product reads as foreign.

Color in visual language is the same discipline as color in UI: restraint, system-driven, never decorative.

## Typography in Visual Language

The product's typography (`text-display`, `text-h1`, etc., from the design system) extends to visual language:

- **Marketing display sizes** can be larger than product UI's largest token (64–96px headlines). These are art-directed exceptions, not new tokens.
- **OG cards use product typography**, not standalone fonts. The OG image is a brand impression; off-brand type breaks it.
- **Illustrated text inside SVG illustrations** uses the product's font family, not arbitrary fonts. Render text in the user's installed font where possible (via foreignObject or via making the text a separate DOM element overlaid on the SVG).

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **Mixing icon libraries.** Lucide for nav, Heroicons for actions, custom for hero. | Stylistic incoherence is immediately visible. The product reads as assembled, not designed. | Pick one library; commit. Custom icons drawn in the same style for gaps. |
| **Multiple stroke weights in the same context.** Thin nav icons next to Bold action icons. | Visual noise; hierarchy via weight is broken because every icon already varies in weight. | One weight per context. Use weight contrast deliberately for hierarchy (e.g., active-state Bold vs default Regular). |
| **Stock illustrations from undraw.co and clones.** People-shaped blobs with brand color recolor. | Instantly recognizable; signals "didn't invest in design"; off-brand by construction. | Either commission custom illustration (rare, expensive) or ship none. Strong typography is enough. |
| **Stock people photography** ("diverse team shaking hands"). | Indistinguishable from a thousand other SaaS products; reads as inauthentic. | Real customer photos with permission, or no photos. |
| **Icon-only buttons without `aria-label`.** Just an SVG inside a button. | SR users hear "button" with no description. The action is invisible. | Every icon-only button has `aria-label` describing the action; decorative icons inside labeled buttons are `aria-hidden="true"`. |
| **`aria-label` on every element ("aria-label-bombing").** Decorative icons given elaborate labels; redundant labels on already-labeled elements. | Overrides visible text; SR users hear different words than sighted users; decorative icons announced as content. | See `team/ui-ux/skills/web-accessibility.md` → aria-label-bombing. Don't use `aria-label` when a visible label exists. |
| **Color-only icon variation.** Info / warning / error distinguished only by color. | Color-blind users miss the distinction; forced-colors mode strips the color. | Pair color with shape: ⓘ for info, ⚠ for warning, ⊗ for error. |
| **Custom icon for every screen.** Designer draws a new icon "because the closest one isn't quite right." | Library bloats; the product visual language fragments; new contributors don't know which icon to use. | Use the closest existing icon. Custom only when no existing icon fits and the concept recurs across the product. |
| **Cute icons that sacrifice clarity.** A coffee-cup icon for "settings" because it's "fun." | Users don't recognize the action; discoverability suffers; localization is harder (the metaphor may not translate). | Familiar icons for actions; reserve playfulness for hero / marketing surfaces, not for functional UI. |
| **Emoji as icons.** 🎉 in a button, 📊 in a nav. | Inconsistent rendering across platforms (Apple's emoji, Google's emoji, Microsoft's emoji all look different); breaks visual language. | Use the icon library. Reserve emoji for user-generated content. |
| **Generic favicons.** A blue "D" indistinguishable from a hundred other blue D-favicons. | Lost in the tab bar; no brand recall on bookmark; user can't find the tab. | Distinctive favicon at 16×16. Color, shape, treatment that stands out. |
| **Transparent PWA icon.** Designed without a background, looks broken when OS adds its own. | OS background colors clash with the icon design. | Solid background; design as a complete tile. |
| **PWA icon without maskable variant.** Icon disappears under OS-imposed shape (iOS rounded square, Android variable). | Cropped icon loses important content. | Ship a maskable variant with content in the central 80% safe area. |
| **OG image identical for every page.** Generic brand-card, no per-page content. | Every shared link looks the same; no preview-driven CTR uplift. | Templated per route type with per-page content (title, hero image) injected via `next/og`. |
| **Photography or illustrations in product UI dense areas.** A photo behind a settings form, an illustration in a sidebar. | Competes with the functional content; slows perceived performance; off-rhythm. | Reserve photography and illustrations for marketing, onboarding, empty states, and content surfaces. Product UI is usually icon + text. |
| **Off-brand color palette in illustrations.** Illustration uses bright pink and yellow when the product palette is muted blue and gray. | Illustration looks pasted-on, like a sticker rather than a designed element. | Illustrations use brand tokens. If the brand palette is too muted for the illustration concept, that's a clue the illustration concept is wrong. |
| **AI-generated imagery on user-facing brand or marketing surfaces.** | Signals "vibes-coded"; Apple-quality bar rejects. Tells the audience the team didn't invest in the brand. | Commission real work, or ship none. Internal-only / data-viz placeholder is the only acceptable use. |
| **Icon font (legacy `FontAwesome` `<i class="fa fa-...">` import).** | Slow to load (web font on critical path), inconsistent rendering, no inline color control, accessibility-hostile (icon font glyphs read aloud as control characters in some SR setups). | Inline SVG via icon-component library (Phosphor / Lucide / Heroicons). |
| **Logo color drift across surfaces.** Brand uses `oklch(64% 0.18 250)` in product, `#1A73E8` in marketing email, slightly different on the favicon. | Coherence failure visible to anyone who sees more than one surface; signals lack of system. | Logo color is a token (or referenced from the design-system accent token). Ship the same value across product / marketing / email / favicon / OG card. |
| **Flag emoji as language indicator** in the language switcher. 🇩🇪 Deutsch. | A flag is a country, not a language. See `team/ui-ux/skills/web-localization-and-i18n.md` → Language Switcher. | Language name in own script, no flag. |
| **Mismatched PWA splash and first-paint backgrounds.** Manifest `background_color: white`; app shell renders with a dark theme on first paint. | Visible flash on launch; product feels broken in the first 200ms. | Match `background_color` in the manifest to the app's first-paint background; ship light + dark variants where supported. |
| **Auto-inverting the logo for dark mode** (`filter: invert(1)`). | A navy logo becomes orange; a green logo becomes magenta. The brand's color is the brand. | Design dark-mode and light-mode logo variants explicitly; switch via `prefers-color-scheme` media. |

## Output

A visual-language design produces:

1. **Visual-language reference** in `knowledge-base/design-specs/visual-language.md` — chosen icon library, stroke weight, size scale, optical-alignment calibration, photography treatment, illustration policy, OG card template, favicon set, PWA icon set.
2. **Icon usage in screen specs** — each spec references icon names from the chosen library; new icons (rare) are flagged for review.
3. **OG image asset or template** — committed to the repo; `next/og` route handler if templated.
4. **Favicon and PWA icon assets** in `public/` — full set as listed above.

## Principles

1. **One library, one weight, one scale.** Iconography coherence is the visual-language equivalent of token discipline. Mixing systems is the failure mode that compounds with every screen.

2. **Default to icon + label.** Icon-only is the exception, reserved for dense toolbars and universally-known controls. The label is the screen-reader user's only access point — `aria-label` is non-negotiable on icon-only buttons.

3. **No illustrations beats stock illustrations.** A great illustration is a force multiplier; a stock illustration signals "didn't invest in design." Strong typography is enough; ship illustrations only when the product has the budget for custom work.

4. **Real photography or none. AI-generated imagery is not a substitute.** Stock people, stock-team-shaking-hands, generic conference photos all fail. AI-generated imagery on user-facing surfaces signals exactly the vibes-coded aesthetic the bar rejects. Commission real work, or ship none.

5. **Color inheritance, not pre-coloring.** Icons take `currentColor` from surrounding text. Color is the design system's job; iconography is the shape system. Mixing them creates two sources of truth for color.

6. **Optical alignment is a one-time investment.** Calibrate icon vertical-align to the type baseline once; pay back forever. Misaligned icons next to text is the single most-visible visual-language defect.

7. **The favicon and PWA icon are brand assets, not afterthoughts.** Distinctive at 16×16. Solid background for PWA. Maskable variant. Tested in dark mode. Treat them with the same care as the hero image.

8. **OG cards templated per route type.** Free brand impressions on every share. The template is the design investment; per-page content is injected automatically.

9. **Visual-language coherence is restraint.** Adding a new icon style, illustration approach, or photo treatment without removing one degrades the system. Audit and prune periodically.

10. **iOS gets this for free; the web has to author it.** SF Symbols + the HIG do the work for iOS designers. Web designers have to choose, calibrate, and commit. The choosing-and-committing is the discipline.
