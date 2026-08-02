# Web Localization and Internationalization

## Purpose
Define how to design web product UI for languages other than English: text expansion across locales (German +30%, Finnish +40%, Russian +20%, Japanese -50%), RTL mirroring (not just text flow — icons, scroll, animation direction, focus order), CSS logical properties as the default, locale-aware date / number / currency / plural / sort formatting via the full `Intl.*` family, the `lang` attribute discipline, IME composition handling, bidi text via `<bdi>`, ICU MessageFormat for complex strings, hreflang and URL structure as UX, language switcher design, and the cultural-meaning concerns most product teams discover only when shipping breaks. This skill is the design-side counterpart to the developer-side i18n implementation; design must build for localizability from screen one because retrofitting is one of the most expensive product mistakes a team can make. See the `web-design-system` skill for the tokens that consume logical properties (gutter, control padding) — those token names should never carry directional bias. See the `web-screen-specification` skill for how locale + direction get specified per screen. See the `web-content-hierarchy` skill for hierarchy under text expansion. See the `web-form-patterns` skill for the autocomplete + label-position rules that interact with i18n (and the IME-composition discipline this skill flags). See the `web-information-architecture` skill for locale-prefixed URL structure. See UI/UX's `web-accessibility` skill for the `lang` attribute's screen-reader role and RTL focus-order requirements. See the `web-onboarding-flows` skill for first-visit locale detection (an onboarding decision). See the `web-nextjs-app-router` skill for the App Router locale routing primitive. **Note: there is no Developer-side `web-i18n` skill yet** — the message-extraction / runtime / build-time / cached-translation pipeline (typically `next-intl` or `next-international` with App Router) is a known framework gap; flag for a future Developer wave when the project hits real i18n implementation. Target: **product UI on web shipping to multiple languages, multiple text directions, multiple locale formatting conventions**.

## The Anchor: Localization Is a Design Constraint, Not a Translation Step

The vibes-coded default treats localization as "we'll translate the strings later." That assumption produces broken layouts (English fits in 80px; German doesn't), broken icons (back arrows that point the wrong way in RTL), broken dates ("3/4/2026" parsed as April 3 by half the world), and broken trust (a Brazilian user sees a Portuguese flag for their language).

The Apple-quality stance: **design assumes multiple locales, multiple text directions, and multiple formatting conventions from screen one.** The cost of building for localizability up front is small; the cost of retrofitting is the entire UI.

Three rules that anchor the rest:

1. **Logical properties everywhere; physical properties nowhere.** `padding-inline-start` not `padding-left`. `margin-block-end` not `margin-bottom`. `border-inline-end` not `border-right`. The CSS logical-properties spec exists exactly so that one stylesheet works in LTR English, RTL Arabic, and vertical Japanese. Use it as the default; physical properties are the exception that needs justification.
2. **Never concatenate sentences from translated fragments.** `"Hello, " + name + ", you have " + count + " items."` is broken in any language with grammatical case (most), gendered nouns (many), or plural rules beyond English's two. Use ICU MessageFormat or equivalent — pass the whole message with placeholders to the translator.
3. **Design for the longest plausible string, not the English one.** When you spec a button as "Save," a translator will produce "Speichern" (German, +30%), "Lưu" (Vietnamese, -33%), and "保存" (Japanese, -67%). The button must work for all of them. Hard-coded widths are anti-pattern; intrinsic sizing (`min-content`, `auto`, container queries) is the discipline.

## Text Expansion: The Numbers and the Discipline

Text expansion is real and asymmetric. A label fits in English; the same label in German overflows; the same label in Japanese is half the width and the surrounding spacing looks wrong.

| Language | Expansion vs. English | Notes |
|----------|----------------------|-------|
| German | +30–40% | Compound nouns; long words common |
| Finnish | +40–50% | Highly inflected; long word forms |
| Polish, Russian | +20–30% | Inflected forms add length |
| Spanish, French, Portuguese | +15–25% | Modest expansion |
| Italian | +5–15% | Closest to English length |
| Chinese (Simplified) | -25–40% | More information per character |
| Japanese | -30–50% | Compact when written; spacing differs |
| Korean | -10–20% | Block-script compact |
| Arabic | +25% (text), but RTL mirrors layout entirely |

### Designing for Expansion

- **Label widths are intrinsic, never fixed.** A button that's `width: 80px` because "Save" fits in 80px is broken in German. Use `width: auto`, `min-width: <floor>` for visual rhythm.
- **Two-line labels are sometimes correct.** A nav item that wraps to two lines in German is better than one that overflows the container. Design with vertical breathing room; specify max line counts where wrapping should be allowed.
- **Truncation with tooltip recovery.** When truncation is genuinely necessary (table cell, sidebar item), show the full value on hover and on focus. Never truncate without a recovery path.
- **Test at the longest target language.** German is the canonical stress test. If a layout works in German, it works in nearly every other language. (Finnish is the harder stress test if the product targets Finland.)
- **Don't design "to the English fit" and add buffer for translation.** Design *to the German fit*; English will look slightly under-dense, which is fine. The other direction is broken.

### Designing for Compaction

When the layout is tested only at English and longer, compact languages (Chinese, Japanese, Korean) often look *too sparse* — generous padding designed for German feels empty around 4-character Japanese words.

- **Padding tokens scale with language?** Generally no — keep tokens fixed and accept that some languages render with more whitespace. Adjusting padding per-locale is a maintenance nightmare; the visual difference is acceptable.
- **Font-size tokens scale with script?** CJK scripts often look better at slightly larger pixel sizes than Latin (the per-glyph density differs). If the product is primarily CJK, calibrate body type accordingly. For mixed-script products, hold one scale.

## Right-to-Left (RTL): A Different Layout, Not a Mirrored One

Arabic, Hebrew, Persian, Urdu, and several other major languages flow right-to-left. RTL is not "flip the layout horizontally" — it's a coherent set of layout, icon, and interaction conventions.

### What Mirrors

| Element | LTR | RTL |
|---------|-----|-----|
| Text flow | left → right | right → left |
| Page layout | sidebar on left | sidebar on right |
| Form field flow (label + input) | label left of input (or above) | label right of input (or above) |
| Breadcrumbs | Home / Section / Page | Page / Section / Home |
| Back arrow icon | ← (chevron-left) | → (chevron-right, mirrored) |
| Forward arrow | → | ← |
| Slide-in / drawer animation | enters from left | enters from right |
| Scroll direction (horizontal) | left → right | right → left |
| Pagination prev/next | prev on left, next on right | prev on right, next on left |
| Default text alignment | left | right |
| Tab order (focus) | left → right, top → bottom | right → left, top → bottom |

### What Doesn't Mirror

| Element | Behavior |
|---------|---------|
| Logos and brand marks | Never mirrored |
| Phone numbers, math, code | Stay LTR even within RTL text (numbers run LTR globally) |
| Media controls (play / pause / stop) | Play icon (▶) does NOT mirror — universal media convention |
| Time-progress UI (timeline, video scrubber) | Often LTR (time always flows forward), but check per-platform convention |
| Clock / time display | Stays in numerical order |
| Trademark / certification marks | Never mirrored |
| Photographs of real-world objects | Never mirrored (don't flip a person's face) |

The discipline: **mirror by default; explicitly opt out for the non-mirroring set.** Many design systems get this backwards (don't-mirror by default, manually mirror per case), and it produces RTL versions that feel half-baked.

### Implementation: `dir="rtl"` + Logical Properties

Set `dir="rtl"` on `<html>` for RTL locales. CSS logical properties resolve correctly in both directions:

```css
/* Works in both LTR and RTL — no per-direction CSS needed */
.card {
  padding-inline-start: 1rem;  /* visual: left padding in LTR, right in RTL */
  padding-inline-end: 1rem;
  border-inline-start: 4px solid var(--color-accent);  /* accent bar on the natural reading start */
  margin-block-end: 1rem;
}
```

If you find yourself writing `[dir="rtl"] .foo { … }` overrides, that's a sign the logical-property discipline broke down somewhere. Find the physical property and replace it.

### Icon Mirroring

The 2025+ correct pattern: **swap to the directional sibling, don't CSS-flip.** Modern icon libraries ship paired directional icons explicitly — Phosphor has `caret-left` / `caret-right`, Lucide has `chevron-left` / `chevron-right`, Phosphor and Heroicons both have `arrow-left` / `arrow-right`. The design picks the correct icon for the direction; the markup swaps the icon component based on `dir`.

```tsx
// Correct: swap the icon
{isRTL ? <CaretLeft /> : <CaretRight />}
```

CSS-flipping (`transform: scaleX(-1)`) is the 2018 pattern and is wrong by default for three reasons:

1. **Light source flips.** Icons with subtle gradients or shadows now have light coming from the wrong side.
2. **Asymmetric stroke caps.** Icons with `stroke-linecap` variants (rounded one end, flat the other) become subtly wrong.
3. **Internal text or marks.** Any icon containing letters, numbers, or asymmetric strokes becomes mirror-image text.

Reserve `transform: scaleX(-1)` for the rare icon that genuinely has no directional sibling and is purely directional in meaning (e.g., a custom flow-arrow with no shadow). Mark these explicitly in the spec.

```css
/* Last-resort fallback — used sparingly, only for icons with no directional sibling */
[dir="rtl"] .icon-mirror-fallback {
  transform: scaleX(-1);
}
```

Mark icons that should swap in the spec. Don't swap the brand-mark, media controls, or photographs (see "What Doesn't Mirror" above).

## Locale-Aware Formatting

Dates, numbers, currencies, plurals, names, addresses — every one of these has locale-specific conventions. Hard-coding any of them is a defect.

### Dates

- **Display via `Intl.DateTimeFormat`**, never via string manipulation. The locale determines the order (`MM/DD/YYYY` in US, `DD/MM/YYYY` in UK, `YYYY-MM-DD` in ISO/Asia), the separator, the month-name abbreviation, and the time format.
- **Server-side**, do the same — `Intl.DateTimeFormat` is available in Node 20+.
- **Month abbreviations differ by locale** ("Jan" vs "Janv." vs "1月"). Design for variable width.
- **Calendar systems**: Most locales use Gregorian, but some users prefer Hijri (Saudi Arabia), Hebrew (Israel — alongside Gregorian), Buddhist (Thailand). For most products, Gregorian is correct; for products that target these markets, allow user preference.
- **Time zones**: store UTC, display in user's TZ. Show the abbreviation when ambiguous ("3:00 PM PT" not "3:00 PM"). See the `web-form-patterns` skill → Time Zone.

### Numbers and Currencies

- **`Intl.NumberFormat`** for both. Locale determines decimal mark (`.` vs `,`), thousands separator (`,` vs `.` vs `'` vs space), digit grouping (`1,000` vs `1.000` vs `10,00,000` for India), and currency-symbol position (`$1,000` vs `1 000 €` vs `1.000 €`).
- **Currency code, not symbol, in spec**. Use ISO 4217 codes (USD, EUR, JPY) in code; let `Intl.NumberFormat` produce the symbol.
- **Don't assume two decimal places**: JPY has zero decimals, BHD has three. `Intl.NumberFormat` handles this; hard-coded `.toFixed(2)` is a defect.

### Plurals

English has two plural forms (`1 item`, `5 items`). Most languages have more.

| Language | Plural forms | Example |
|----------|-------------|---------|
| English | 2 | one, other |
| Russian | 3 | one, few, many |
| Polish | 3 | one, few, many (different rules from Russian) |
| Arabic | 6 | zero, one, two, few, many, other |
| Japanese, Korean, Chinese | 1 | (no grammatical plural — context conveys count) |

Use `Intl.PluralRules` to select the form, and ICU MessageFormat to express the message:

```
{count, plural,
  =0 {No items}
  one {One item}
  other {# items}
}
```

The translator receives the whole pattern and produces the locale-specific forms. Never write `count === 1 ? "1 item" : count + " items"` in product code.

### Names and Addresses

- **Single "name" field**, not first / middle / last. Many cultures don't decompose names into Western first / middle / last; some have honorifics that aren't optional; some put family name first. A single `name` field is universal and correct.
- **Address fields vary by country** (Japan has prefecture + city + ward + chōme + banchi; the US has street + city + state + ZIP). Use a library like `i18n-postal-address` or render per-country forms. Don't force a US-shaped form on every locale.

### Sort Order: `Intl.Collator`

Sorting is locale-dependent. `"Ångström".localeCompare("Zebra")` returns negative in English (Å sorts before Z) and positive in Swedish (Å is a separate letter that sorts *after* Z). Hard-coded `Array.sort((a,b) => a.localeCompare(b))` without an explicit locale is wrong by default — it uses the runtime's locale, which may not match the user's.

Use `Intl.Collator` with the active locale and explicit options:

```ts
const collator = new Intl.Collator(activeLocale, {
  sensitivity: "base",       // a vs A vs á — pick the right level for the surface
  numeric: true,             // "Item 2" sorts before "Item 10" (natural sort)
  caseFirst: "false",        // browser default; "upper" or "lower" if you need control
});
items.sort((a, b) => collator.compare(a.name, b.name));
```

Every list, table, or picker that sorts user-visible strings runs them through a locale-aware collator. Hard-coded `localeCompare()` without a locale is a defect for any non-English locale.

### Word and Grapheme Boundaries: `Intl.Segmenter`

`Intl.Segmenter` (Baseline 2024) produces locale-correct word, sentence, and grapheme boundaries. Use it for:

- **Truncation that respects graphemes**: `"👨‍👩‍👧 family"`.slice(0, 1)` produces a broken half-emoji; `Intl.Segmenter` slicing respects the grapheme cluster.
- **Word-count UIs** in CJK contexts where there are no spaces between words; `string.split(" ").length` returns 1 for a Japanese sentence.
- **Line-breaking hints** for clamped text in CJK, where breaking mid-word is incorrect.
- **Screen-reader-correct narration** of mixed-script text.

```ts
const segmenter = new Intl.Segmenter(activeLocale, { granularity: "grapheme" });
const firstGrapheme = [...segmenter.segment("👨‍👩‍👧 family")][0].segment;
```

Specialized but real — design specs that mandate truncation should use grapheme-aware truncation, not `.slice()`.

## The `lang` Attribute: Non-Negotiable

Every page sets `<html lang="...">` to the active locale. This is the single attribute screen readers, browser hyphenation (`hyphens: auto`), font-fallback chains (Asian sans-serif resolution differs by `lang`), and search engines all depend on. Missing it produces wrong-language screen-reader pronunciation, wrong hyphenation, wrong font fallback — silent failures the team only notices when an external user complains.

```html
<html lang="de" dir="ltr">    <!-- German page -->
<html lang="ar" dir="rtl">    <!-- Arabic page -->
<html lang="ja">              <!-- Japanese (dir defaults to ltr) -->
```

For embedded foreign-language content within a page (a Spanish quote inside an English article, a Japanese product name within German UI), set `lang` per element:

```html
<p>The slogan is <span lang="es">"Piensa diferente"</span> in the Spanish edition.</p>
```

Screen readers switch voice / pronunciation accordingly; copy-paste preserves the language metadata. Missing per-element `lang` produces the same screen-reader mispronunciation as a missing root `lang`, just scoped to the embedded fragment.

The design spec for any localized screen calls out: root `lang`, plus any per-element `lang` for foreign-language fragments.

## Bidi Text: `<bdi>` for Mixed-Direction Strings

A user named `"محمد Smith"` rendered in plain HTML produces visually-broken output — the bidi algorithm reorders the characters and the result is unreadable (the surname may end up on the wrong side, the punctuation may collapse). The fix is the `<bdi>` element (Bidirectional Isolate), which tells the browser to render the contained string as a self-contained directional unit:

```html
<p>Invitation from <bdi>{{user.name}}</bdi> to your project.</p>
```

Use `<bdi>` for any user-supplied text rendered inside a sentence: usernames, display names, project titles, content excerpts. This is most-visible on invitations, mentions, receipts, and any UI that renders user-supplied strings inline.

For larger blocks (a comment, a chat message), `<bdo>` or CSS `unicode-bidi: isolate` provides equivalent isolation. Either way, the design specs for any UI that renders user-supplied text in a multi-locale product flag the bidi-isolation requirement.

## IME Composition: `compositionend`, Not `blur`

For CJK input methods (Japanese IME, Chinese pinyin, Korean Hangul), the user types into an *intermediate* composition buffer that resolves into the final character on confirmation. During composition, the input fires `input` events (with the in-progress romaji or pinyin) and `blur` may fire mid-composition if focus moves.

This breaks the form-validation discipline (the `web-form-patterns` skill → "validate on blur"): a Japanese user typing `"こん"` mid-composition who triggers blur sees a "this isn't a valid name" error before they've finished typing.

The correct discipline:

- **Listen for `compositionstart` and `compositionend` events** in addition to `blur`.
- **Suppress validation while composition is active** (between `compositionstart` and `compositionend`).
- **Validate after `compositionend`**, not after `blur` if `blur` fired during composition.

This is a real shipping bug Western teams produce constantly. The form-patterns skill assumes Latin keyboard input; the i18n skill flags the IME interaction. Specs for any text input shipping to CJK locales explicitly call out IME-aware validation.

## ICU MessageFormat: The Modern Correct Pattern

ICU MessageFormat handles plurals, gender, select, nested arguments, and date / number formatting in one expression. It is the modern correct way to express any string with variables.

```
{userGender, select,
  female {{count, plural,
    =0 {Sarah hasn't posted anything yet.}
    one {Sarah posted 1 item.}
    other {Sarah posted # items.}
  }}
  male {{count, plural,
    =0 {Mark hasn't posted anything yet.}
    one {Mark posted 1 item.}
    other {Mark posted # items.}
  }}
  other {{count, plural,
    =0 {This user hasn't posted anything yet.}
    one {This user posted 1 item.}
    other {This user posted # items.}
  }}
}
```

The ICU pattern handles: zero / singular / plural / "few" / "many" forms per locale; gendered references; nested formatting. The translator receives the whole pattern and adapts it.

The design responsibility: **specify messages as ICU patterns from the start, not as English-with-variables that someone will "convert later."** Conversion later means refactoring every callsite when you ship to a new locale.

## URL Structure for Localized Routes

Three options for representing locale in URLs:

| Strategy | Example | Pros | Cons |
|----------|---------|------|------|
| **Path prefix** | `/en/products`, `/de/produkte` | Easy to implement; clear; SEO-friendly with hreflang | Adds prefix to every URL |
| **Subdomain** | `en.example.com`, `de.example.com` | Strong locale signal to browsers + crawlers | Cookie / auth scope across subdomains is harder |
| **Country domain** | `example.com`, `example.de` | Strongest locale signal; legal / billing alignment | Requires per-domain setup; most expensive |

Default for most products: **path prefix**. App Router `[locale]` segment is the standard pattern. Subdomain or country domain only when there's a specific reason (regulatory, marketing, dramatically different content per region).

### `hreflang` Tags

For SEO and browser hints, every localized page declares its alternates:

```html
<link rel="alternate" hreflang="en" href="https://example.com/en/products" />
<link rel="alternate" hreflang="de" href="https://example.com/de/produkte" />
<link rel="alternate" hreflang="x-default" href="https://example.com/en/products" />
```

`x-default` is the fallback when no language match is found. This is implementation work, but the design decision (what the default fallback is) belongs to the spec.

### Default Locale Selection

Two signals, in order:

1. **Saved preference** (cookie, account setting). Once a user has chosen, respect their choice.
2. **`Accept-Language` header** on first visit. Read the user's browser preference; pick the best match from your supported set; fall back to `x-default`.

Don't auto-redirect on every visit based on `Accept-Language` — once the user has navigated to a specific locale URL, respect their choice for that session. Redirecting `/de/products` → `/en/products` because the user's browser is English is hostile.

## The Language Switcher

The language switcher is a small but load-bearing UI element. Conventions:

- **Placement**: footer is the Apple convention (low chrome cost, easy to find). Account dropdown is the SaaS convention (more discoverable for signed-in users). Pick one per product; don't have it in both.
- **Label**: the language name **in its own language** ("Deutsch" not "German", "日本語" not "Japanese"). Users looking for their language scan for their own word.
- **Generate the language names dynamically with `Intl.DisplayNames`**, not by hardcoding a static list. The API produces locale-correct names for every BCP 47 language tag; hardcoding drifts as supported languages change and bakes in spelling errors.

```ts
const displayNames = new Intl.DisplayNames([targetLocale], { type: "language" });
const label = displayNames.of(targetLocale); // "Deutsch" for de, "日本語" for ja, "Português (Brasil)" for pt-BR
```

  Use the same API for region names (`type: "region"`), currency names (`type: "currency"`), and script names (`type: "script"`) wherever the UI displays them.

- **Don't use flags**. A flag is a country, not a language. Brazilian Portuguese is not the Portuguese flag; Quebec French is not the France flag; Hindi has no flag. Use the language name in its own script.
- **List the supported set explicitly**, not "more languages coming soon" placeholders.
- **Switch is immediate**: the page reloads in the new locale. URL updates to the locale-prefixed path. Cookie updates so future visits land in the chosen locale.

### Locale Cookie and GDPR Classification

The locale-preference cookie (the one that remembers "this user prefers German") is **essential under GDPR / ePrivacy** — no consent banner required for it. Tracking the locale switch as an analytics event is a separate concern that *does* require consent. Specify the locale-preference cookie in the cookie-policy as essential; coordinate with the `web-onboarding-flows` skill → Cookie Consent.

## Cultural Meaning: Beyond Translation

Some design choices have meanings the design must respect:

- **Colors**: red is danger / stop in much of the West, lucky / celebratory in China and parts of East Asia, mourning in South Africa. White is purity in much of the West, mourning in China and Japan. Don't reach for color symbolism when you can use shape or text.
- **Icons**: a thumbs-up means approval in most of the West, an insult in parts of the Middle East and West Africa. An owl means wisdom in the West, ill-fortune in parts of India. Mailbox icons differ by country (the US "flag-up" mailbox is unfamiliar elsewhere). Stick to icons whose meaning is broadly universal; pair with labels.
- **Photography**: representation matters; photos chosen for one market may feel exclusionary in another. Use locally-relevant imagery for marketing pages targeting specific regions.
- **Gestures**: the "OK" gesture, the V-sign, and the thumbs-up all have different meanings in different cultures. Avoid hand-gesture imagery in cross-cultural product UI unless the meaning is explicit (e.g., a wave = "hi").
- **Names and surnames**: "Test User" or "John Smith" placeholders are recognizably American. For international products, use locally-appropriate placeholder names per locale.

## Designing the Spec

Per-screen, the spec must address:

- **Locale strategy**: path prefix / subdomain / domain.
- **Supported languages**: the list, in their own scripts.
- **Default fallback** (`x-default`): which locale serves users with no detected match.
- **Direction handling**: which surfaces have RTL variants (default: all of them); which icons mirror; which don't.
- **Text expansion verified**: every label tested at the longest plausible target (German for European, Finnish for Nordic, Russian for Cyrillic).
- **Date / number / currency formatting**: all dynamic values produced via `Intl.*` with the active locale.
- **Plural messages**: ICU MessageFormat patterns for every count-dependent string.
- **Cultural review**: any color, icon, or photographic choice that might carry locale-specific meaning is flagged for review.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **Treating localization as a post-launch translation step.** "We'll translate the strings later." | Layouts break in expansion languages; physical CSS properties don't mirror in RTL; concatenated strings are ungrammatical in every other language. Retrofitting is the entire UI. | Design for localizability from screen one: logical properties, ICU MessageFormat, intrinsic widths, locale-aware formatting. |
| **Physical CSS properties** (`padding-left`, `margin-right`, `border-left`). | Don't mirror in RTL. Every screen needs per-direction overrides. | Use logical properties (`padding-inline-start`, `margin-inline-end`, `border-inline-start`) as the default. |
| **Concatenating sentences from fragments.** `"Hello, " + name + ", you have " + count + " items."` | Ungrammatical in any language with case, gender, or plurality beyond English's two. Translators receive disconnected fragments. | ICU MessageFormat: pass the whole message with placeholders to the translator. |
| **Hard-coded date / number formats.** `date.toLocaleDateString("en-US")` or string templating. | Wrong format for every other locale; sometimes legally wrong (date order is meaningful for compliance). | Use `Intl.DateTimeFormat` / `Intl.NumberFormat` with the active locale. |
| **Single English label for plurality.** `${count} item${count === 1 ? "" : "s"}` | Doesn't generalize to Russian's three forms, Arabic's six, or CJK's none. | `Intl.PluralRules` + ICU MessageFormat. |
| **Flag icons as language indicators.** US flag for English, France flag for French, Portugal flag for Portuguese. | Flags are countries, not languages. Brazilian Portuguese ≠ Portugal flag; Hindi has no flag; Spanish is spoken in 20 countries. | Use the language name in its own script (`Deutsch`, `Português (Brasil)`, `日本語`). |
| **Designing only at English (or a similar-length language).** | Layouts overflow in German, Finnish, Russian. The team discovers it in production. | Design at German fit; English looks slightly under-dense, which is correct. |
| **Hard-coded widths on labels and buttons.** `width: 80px` because "Save" fits. | Truncates or overflows in expansion languages. | Intrinsic widths; min-width for visual rhythm; allow wrapping or truncation with recovery. |
| **Auto-redirecting based on `Accept-Language` on every visit.** User on `/de/products` gets redirected to `/en/products` because their browser language is English. | Hostile — overrides the user's explicit URL navigation. Breaks bookmarks and shared links. | Detect on *first* visit only. After that, the URL is the source of truth. |
| **Splitting names into First / Middle / Last.** | Doesn't generalize across cultures (no middle name; family-name-first; honorifics). | Single "name" field. |
| **Forcing US-shaped address forms on every locale.** Street, City, State, ZIP. | Wrong field set for many countries (Japan's prefecture / chōme / banchi; UK's county; Germany's Postleitzahl). | Render per-country address forms or use a library like `i18n-postal-address`. |
| **Per-direction overrides** (`[dir="rtl"] .foo { left: auto; right: 0; }`). | Defeats the logical-properties spec. Two parallel stylesheets to maintain. | Use logical properties; per-direction overrides are the exception. |
| **Mirroring icons that shouldn't mirror.** Logos, media play, photographs flipped in RTL. | Logos become wrong; play icon convention violated; faces look uncanny. | Mirror by default; explicit opt-out for the non-mirror set (logos, media, photographs, code, math). |
| **Translating brand names, technical terms, or established loanwords.** "Cloud" translated as a German word for atmospheric water vapor. | Loses meaning; users expect the loan-word; SEO suffers. | Keep brand names and technical terms in source language unless there's a real local convention. |
| **No `hreflang` declarations on localized pages.** | Search engines duplicate-content-flag your locales; users land in the wrong language from search. | Every localized page declares its alternates including `x-default`. |
| **Color-symbolic UX** (red = danger, green = success) with no shape backup. | Color meaning differs across cultures; color-blind users miss it. | Pair color with shape, icon, or text. See UI/UX's `web-accessibility` skill. |
| **Showing prices in the engineer's currency on a foreign-locale page.** USD prices on `/de/pricing` because "we haven't built currency conversion yet." | German user does mental math, abandons; signals "we don't actually serve your market." | Either build currency display in the user's locale (with the resource currency clearly noted) or restrict the localized page to markets where the source currency is appropriate. |
| **Partial translation.** UI translated; error messages and third-party-component strings stay English. | Worse than full English — looks broken; user can't trust which parts they understand. | Either fully translate the surface or don't ship that locale yet. |
| **Engineer's TZ as default for every new user.** "Pacific Time" everywhere. | Confusing for non-PT users; wrong by default. | Detect via `Intl.DateTimeFormat().resolvedOptions().timeZone`; user can override. |
| **Subdomain auto-redirect.** `example.de` redirects to `example.com` because the primary market is elsewhere. | Hostile; defeats locale-specific subdomains; breaks bookmarks. | Serve from the locale-specific subdomain when it exists. |
| **Translating brand names or loanwords.** Translating "Cloud" into a German atmospheric-vapor word for SEO. | Loses meaning; hurts SEO (users search the loanword); reads as foreign. | Keep brand names and established loanwords in the source language. |
| **CSS-flipping icons (`transform: scaleX(-1)`) as the default RTL pattern.** | Light source flips, asymmetric stroke caps wrong, internal text mirrors. The 2018 pattern. | Swap to the directional sibling icon (`caret-left` ↔ `caret-right`). CSS-flip only as last resort for icons with no directional pair. |
| **Hardcoded language names in the language switcher.** "Deutsch" / "日本語" / "Português (Brasil)" written as a static array. | Drifts as supported set changes; bakes spelling errors. | Generate via `Intl.DisplayNames(targetLocale, { type: "language" }).of(targetLocale)`. |
| **Validating CJK input on `blur` instead of `compositionend`.** Japanese user typing through IME triggers validation mid-composition. | False errors mid-typing; user can't complete the form. | Listen for `compositionstart` / `compositionend`; suppress validation while composition active. |
| **Mixed-direction user-supplied text rendered without `<bdi>`.** A user named "محمد Smith" displayed inline. | Bidi algorithm reorders incorrectly; visually broken. | Wrap user-supplied text in `<bdi>` for any inline render (mentions, invitations, receipts). |
| **Hard-coded `localeCompare()` without a locale.** `array.sort((a,b) => a.localeCompare(b))` returns runtime-locale-dependent ordering. | Wrong sort for any non-English locale; "Ångström" sorts wrong in Swedish. | `Intl.Collator(activeLocale, { sensitivity, numeric }).compare`. |
| **Missing `lang` attribute on `<html>` (or per-element for embedded foreign-language text).** | Wrong screen-reader pronunciation, wrong hyphenation, wrong font fallback chain. | Set `<html lang="..." dir="...">` per locale; per-element `lang` for foreign-language fragments. |

## Output

A localization design produces:

1. **Locale list** in `knowledge-base/design-specs/locales.md` — supported locales, their script, their text direction, the default fallback (`x-default`).
2. **i18n routing strategy** in the same file — path prefix vs. subdomain vs. domain; URL structure for each supported locale.
3. **Per-screen i18n addressing** in the screen spec (the `web-screen-specification` skill) — verified expansion, direction handling, ICU patterns for count-dependent strings, locale-aware formatting for all dynamic values.
4. **Cultural-review flags** — any color, icon, or photo choice with locale-specific meaning, in the relevant screen spec's Open Questions or as a dedicated review pass before launch in a new market.

## Principles

1. **Localization is a design constraint from screen one.** Every layout assumes multiple languages, multiple directions, multiple formatting conventions. Retrofitting is the entire UI.

2. **Logical properties everywhere; physical properties never.** `padding-inline-start`, `margin-block-end`, `border-inline-end`. One stylesheet, every direction. Physical properties are the exception that needs justification.

3. **Mirror by default; opt out explicitly.** RTL mirrors layout, icons, animation direction, scroll, focus order. Logos, media controls, photographs, code, math, and trademark marks don't mirror — list them explicitly.

4. **Never concatenate translated fragments.** ICU MessageFormat handles plurals, gender, select, and nesting. A translator receives the whole pattern and adapts it.

5. **Design for the longest plausible string.** German is the European stress test; Finnish for Nordic. If the layout works there, it works in every other language. Hard-coded widths are defects.

6. **`Intl.*` for every dynamic value.** Dates, numbers, currencies, plurals — never via string templating. The browser's i18n API is the source of truth.

7. **Single name field; per-country address forms.** Names don't decompose universally; addresses don't share one shape. The Western form is wrong for most of the world.

8. **Language names in their own script; never flag icons.** A flag is a country; a language is a language. Users scan for their own word in their own writing system.

9. **Respect user choice.** A user on `/de/products` stays on `/de/products` until they choose otherwise. Auto-redirecting on `Accept-Language` overrides the URL; that's hostile.

10. **Cultural meaning isn't translatable.** Colors, icons, gestures, photographs carry locale-specific signals. Pair color with shape; pair icons with labels; review imagery per market.
