# Web Marketing and Conversion Pages

## Purpose
Define the design discipline for marketing surfaces — landing pages, pricing pages, comparison tables, trial-end / paywall pages, social-proof patterns, OG / social card design, and the conversion hierarchy that makes them work without dark patterns. Marketing pages and product UI follow different rhythms: product wants efficient task completion; marketing wants the user to *act*. Conflating the two produces marketing pages that feel like dashboards and product UI that feels like sales pitches. This skill is the home for the craft Apple's marketing demonstrably leads on (apple.com product pages, App Store editorial, Fitness+ landings) and that vibes-coded LLM output is consistently bad at. See the `web-content-hierarchy` skill for the parent hierarchy discipline; the marketing landing ladder there is the input to this skill. See the `web-design-system` skill for the tokens marketing pages consume — marketing surfaces still use product tokens, with selective art-directed exceptions called out. See the `web-form-patterns` skill for the form rules that interact with marketing-page conversion forms (sign-up, lead capture). See the `web-information-architecture` skill for the marketing-vs-product route separation (route groups). See the `web-onboarding-flows` skill for what happens after the marketing CTA is clicked (and for the cookie consent that must not break LCP / CLS on the marketing hero). See the `web-localization-and-i18n` skill for marketing-page localization (currency display, locale-prefixed routes, `hreflang` for SEO). See the `web-empty-error-and-edge-states` skill for the marketing 404 / 500 (which use the same brand-moment patterns as product errors but with marketing voice). See the `web-performance-engineering` skill for the LCP discipline marketing pages live or die by. Target: **marketing surfaces on web — landing pages, pricing pages, comparison pages, paywall / trial-end pages, brand pages, OG / social card design**.

## The Anchor: One Promise, One Action

The single most-violated rule on marketing pages: **one page makes one promise and asks for one action.** Every additional promise dilutes the primary one; every additional CTA dilutes the primary one. Apple's iPad page sells you the iPad. Apple's iPhone page sells you the iPhone. Neither tries to sell both, and neither tries to sell you a Mac on the side.

Two implications:

1. **The promise is the headline.** It's the first thing the user reads. Three rotating slides means three half-promises and no headline; that's the hero-carousel anti-pattern.
2. **The CTA is one button.** Secondary actions ("Learn more," "Watch a demo," "Read the docs") are smaller, ghost-styled, visually subordinate. They exist; they don't compete.

The product team will want more — more features highlighted, more proof points, more secondary CTAs. The marketing-page designer's job is to push back and keep the page focused. Conversion lives or dies on focus.

## Marketing vs. Product: Different Rhythms

Pattern decisions that hold for product UI are sometimes wrong for marketing, and vice versa. Make the distinction explicit.

| Concern | Product UI | Marketing page |
|---------|-----------|---------------|
| Density | Calm, minimal, hierarchy-first | Variable; can be denser in supporting sections |
| Hero | Often no hero; the interface IS the content | Hero is the page; everything else supports it |
| Type scale | Body 16px, modest display sizes | Display sizes can be 64–96px; product type scale is too small |
| Image use | Restrained; images are functional (avatars, content thumbnails) | Photography and product shots can be large, art-directed |
| Animation | Reduced-motion as primary mode; subtle | Curated cinematic moments are acceptable (with reduced-motion alternatives) |
| Form | Many fields, validation, autosave | One or two fields; sign-up or email capture |
| Navigation | Coordinated system with sidebar / cmd-K | Top nav only; deep IA discouraged |
| Performance budget | LCP < 2.5s for product UI | LCP < 1.5s — bounce rates triple past 3s on landing |
| URL structure | Routes as state (filters, sort) | Stable URLs for shareability and SEO |

This is not a permission to abandon product principles on marketing pages — it's a recognition that the *application* of those principles differs.

## The Landing Page

The single most-built marketing surface. The skeleton:

```
1. Hero (above the fold)
   ├─ Promise (headline)
   ├─ Supporting line (sub-headline)
   ├─ Primary CTA
   ├─ Optional ghost secondary
   └─ Hero visual (product shot, demo, or designed illustration)

2. Three to five supporting sections (below the fold)
   ├─ Feature / benefit / proof point each
   ├─ One per scroll-screen
   └─ Visual + headline + 1–2 supporting paragraphs

3. Social proof (mid-page)
   ├─ Real customer logos (with permission)
   ├─ Real testimonials (with attribution)
   └─ Optional: case study link

4. Pricing teaser or feature comparison
   └─ "See pricing" → /pricing (separate page)

5. Secondary CTA (foot of page)
   ├─ Same primary action restated
   └─ Optional secondary (newsletter, demo)

6. Footer
   ├─ Product links
   ├─ Company links
   ├─ Legal (terms, privacy)
   └─ Language switcher
```

### The Hero

The hero is most of the conversion. Discipline:

- **Above-the-fold contract**: at the smallest target viewport (375 × 667), the user sees the headline + sub-headline + primary CTA without scrolling. If the hero requires scrolling to see the CTA, the hero is too tall.
- **Headline is the promise**, not a feature list. "Ship fast" beats "Modern web framework with React Server Components, edge runtime, and global CDN." Specifics belong in supporting sections.
- **Hero visual is the product**, not generic art. Apple shows the device. A SaaS product shows the product UI. A consumer app shows the screen the user will see. Stock photography is almost always wrong here.
- **Don't auto-play video with sound**. Auto-play silent loop is acceptable for a curated demo; sound-on auto-play is a known bounce-driver. Provide an explicit play control.
- **One CTA, one secondary** maximum in the hero. Three CTAs means none is primary.

### Supporting Sections

Each supporting section makes one point. The section's visual + headline + paragraph all serve that one point.

- **One concept per scroll-screen.** Don't compress three points into one section to save scroll length. Scroll length is fine; cluttered sections aren't.
- **Visual on one side, copy on the other** is the default for supporting sections (alternate sides for visual rhythm — left/right/left/right). Stack on mobile.
- **Headline pulls the user forward**: each supporting section's headline could function as a sub-promise that earns continued reading.
- **Don't overload with screenshots**. A single, sharp product visual beats a montage of six.

### Social Proof

When real social proof exists, use it. When it doesn't, *don't fabricate*.

- **Customer logos**: with explicit permission. Logo walls of "fake-looking" placeholder logos hurt more than they help.
- **Testimonials**: real names, real roles, real photos (or no photo, never stock). "John, San Francisco" with a stock face reads as fake.
- **Numbers**: only when they're real and meaningful. "10,000+ teams" is fine if it's true; "Trusted by thousands" without a number is filler.
- **Case studies**: a separate detail page; teaser on the landing page.

If the product is too new for genuine social proof, omit the section entirely. An empty proof section signals "no one uses this yet"; a missing one is invisible.

### The Secondary CTA

At the bottom of the page, restate the primary CTA. The user who scrolled all the way is a high-intent signal — give them the action without making them scroll back up. Same wording, same primary styling.

## The Pricing Page

The most-scrutinized page on most products. Conversion is highly sensitive to the pricing-page craft.

### The Tier Display

- **Three tiers is the SaaS-canonical pattern** (Free / Pro / Enterprise, or Starter / Growth / Scale). Two is often too few (no middle anchor); four+ is decision paralysis. Note this is a SaaS convention, not a universal rule — Apple's pricing pages aren't three-tier (iCloud is four storage steps; hardware is config-as-pricing). If the product genuinely has two tiers (or one), ship two (or one). Don't manufacture a middle tier just to fit the template.
- **The middle tier is highlighted** as "Most popular" or "Recommended" — the visual weight (slightly larger card, accent border, badge) anchors the user's attention there. This is not a dark pattern; it's helping the user decide. Don't lie about which is most popular.
- **Each tier card has the same fields** in the same order: tier name, brief description, price, billing toggle (if monthly/annual), CTA, included-features list, "what's not included" if relevant.
- **Price is prominent**, not buried. Numerals are larger than the surrounding text; currency symbol is appropriate to the user's locale.

### The Annual Toggle

For SaaS with annual discount: a toggle at the top of the tier cards switches monthly ↔ annual pricing. **Default to annual** — it's the discounted, recommended path that aligns the user's interest (lower per-month price) with the product's interest (lower churn). The user toggles to see the monthly alternative. Show the savings explicitly when on annual ("Save $48 / year"). Apple, Notion, Linear all default to annual.

Defaulting to monthly so the headline price *looks* lower is the dark-pattern variant — it produces a worse comparison-shop experience and trains users to distrust the page. Don't.

Don't lock pricing to one billing period — users want to compare.

### The Comparison Table

For long feature lists, a comparison table below the tier cards expands the included-features bullet into a full row-by-row table.

- **Columns are the tiers** (same order as the tier cards).
- **Rows are features**, grouped by category. Group headers in caption-sized muted text.
- **Cells are check / em-dash / number**. Check (✓) for included; em-dash (—) for not included; number for limits ("10 users" vs "unlimited").
- **Don't hide competitor or self-comparison failures**. If you compare to a competitor, list every feature, including the ones they have and you don't. Hiding loses trust faster than the lost feature does.
- **"Custom" or "Contact us"** entries should be rare. Users want to see the price; "Contact us" for everything signals you don't want them.

### Pricing Anti-Patterns to Reject

- **"Coming soon" or "TBD" prices.** If the tier exists, its price exists.
- **Hidden seat costs.** "$99/month" with "+$10 per additional user, billed annually" buried in fine print is dishonest.
- **Limited-time discount countdown timers** (`Sale ends in 23:14:09`). Fake urgency erodes trust; if the user comes back tomorrow and the timer is reset, you've broken the promise.
- **No money-back / cancellation policy** stated. The Apple-quality default: clear money-back window, clear cancellation path, no surprises.

## Trial-End and Paywall Pages

The most-anxious user moment. Designed badly, it's a bounce; designed honestly, it's an upgrade.

### Trial-End

- **Heads-up email + in-app banner** in the days leading up. The trial-end page itself should not be a surprise.
- **Trial-end page**: clear headline ("Your trial ends today"), clear options (upgrade / extend / continue with limited free / cancel), the implications of each choice spelled out.
- **Don't lock the user out without warning**. The day after trial-end, the product should still let them in to a degraded view (read-only, or limited features), not a hard wall.
- **"Add payment method to continue"** is honest; "Buy now or lose your data" is dark-pattern coercion.

### Paywall

For products where some content / features are gated:

- **Show the gate clearly**: a paywall is a paywall, not a fake error or a confusing redirect. The user should know exactly what they hit and why.
- **Show what they unlock**, specifically. "Unlock all 50+ courses" with a list of what's included beats "Get the premium experience."
- **One primary CTA** ("Subscribe to unlock"); secondary is "Cancel anytime" or "See pricing."
- **Don't trap the user**. Back button works; close button is visible; "no thanks" exists somewhere.

## Conversion Hierarchy: Different from Product Hierarchy

Product hierarchy answers "what should the user see first?" Marketing hierarchy answers "what should the user *do* first?"

| Surface | Primary | Secondary | Tertiary |
|---------|---------|-----------|----------|
| Landing | The promise + CTA | Supporting points | Social proof, footer |
| Pricing | Tier comparison | Feature detail table | FAQ, social proof |
| Trial-end | Upgrade CTA | Extend / downgrade | Cancel |
| Paywall | Subscribe CTA | What's unlocked | Cancel anytime, see pricing |
| Comparison | The tier matrix | Per-feature explanations | Migration / sign-up CTA |

The conversion hierarchy is enforced by visual weight. Primary is largest, brightest, most-positioned-for-attention; secondary fades; tertiary recedes. If two CTAs are visually equal, neither is primary.

## OG / Social Card Design

Every shareable URL should have a designed OG image. When a user shares the URL in Slack, Twitter, LinkedIn, or iMessage, the OG image is the preview — and a missing or default image looks unfinished.

- **Dimensions**: 1200 × 630 (Twitter, LinkedIn, Facebook, Slack).
- **Templated by route**, not designed per page. A landing page might have a custom OG; a blog post should auto-generate from the post title + author + brand template.
- **Per-page metadata**: `og:title`, `og:description`, `og:image` set per route via Next.js Metadata API.
- **Twitter card type**: `summary_large_image` for the 1200 × 630 layout.
- **Test the preview** in the actual platforms before shipping a major page. Slack's OG preview, Twitter's card preview, LinkedIn's preview each render slightly differently.

The implementation lives in the `web-nextjs-app-router` skill → Metadata API; the design responsibility is the template + per-page asset.

## Performance: Marketing Pages Live or Die By It

A landing page with LCP > 3 seconds loses about half its visitors before they see the headline. The Core Web Vitals bar for marketing:

- **LCP < 1.5 seconds** at the smallest reasonable network (4G, simulated mid-tier mobile). Hero is the LCP element; treat it as such.
- **INP < 200ms.** Interaction to Next Paint is now the primary engagement metric (replacing FID in 2024). A marketing page with a sticky CTA whose scroll handler adds 150ms to every interaction passes LCP and fails INP. Keep handlers cheap; prefer CSS for scroll-tied effects.
- **CLS < 0.1.** Cumulative Layout Shift — hero must not jump as fonts load or images decode. Reserve `width` × `height` on every image, including the hero. Cookie banners (see `web-onboarding-flows.md` → Cookie Consent) must not push hero content down.
- **Hero image is `priority` in `next/image`** — preloaded, not lazy.
- **No render-blocking third-party scripts** above the fold. Analytics, chat widgets, A/B test SDKs, marketing-pixel SDKs all defer or load post-LCP.
- **No web fonts blocking text render** — `font-display: swap` or `optional` per the `web-performance-engineering` skill.
- **Hero video** (when used): poster image renders first, video loads after. Never block paint on video decode. See "Video as Content" below.
- **Page weight under 1MB total** for marketing pages where possible. Heavy hero videos and high-res photos eat the budget; compress aggressively.

The design has performance implications. A hero illustration at 4MB is a defect; a video carousel at 12MB is a guarantee of poor conversion.

## Cinematic Hero Treatment

The single most-visible difference between Apple-quality marketing pages and vibes-coded ones lives in the hero. Apple's iPhone, iPad, Vision Pro, and Watch product pages are the benchmark — full-bleed visuals, the product itself as the protagonist, motion that earns its place. Most product teams reach for either a generic stock-image hero (boring) or a kitchen-sink hero with three CTAs and a feature list (cluttered). Neither hits the bar.

The discipline:

- **The product is the hero.** Apple shows the device at scale. SaaS shows the product UI in the actual context the user will use it. A consumer app shows the screen the user will see. Stock photography is almost always wrong here.
- **Full-bleed visuals are acceptable** when they earn their bandwidth. A muted-loop video of the product in use; a high-res still that fills the viewport; an art-directed composition that holds attention. They're not decoration; they *are* the message.
- **Auto-play silent loop only**, never sound-on. Set `autoplay muted playsinline loop preload="metadata"` on the video. `playsinline` is non-negotiable on iOS — without it, video opens fullscreen on tap. Provide an explicit play/pause control for users who want it.
- **Parallax is allowed when it earns its motion budget.** A subtle parallax that ties the product visual to scroll progress is acceptable; a busy multi-layer parallax that fights `prefers-reduced-motion` is not. Always provide reduced-motion alternative (static).
- **Hero-into-section transitions** (the product visual transforming as the user scrolls into the next section) are the apple.com signature move. They require View Transitions API or scroll-tied animation, ship reduced-motion fallbacks, and need to feel earned. Reserve for marquee marketing pages, not every landing.
- **Don't use marketing display sizes (64–96px) without proportional whitespace.** A massive headline crammed against a small product visual reads as shouty. Apple's display type sits in generous negative space.

If the product team can't ship a hero asset that meets this bar, ship a *quieter* hero — strong typography on plain background, single product still — instead of cluttering or stock-imaging. Restrained beats overstuffed.

## Scrollytelling Discipline

Apple's product pages are scroll-tied stories: each scroll-screen reveals a new product fact, with the visual transforming or shifting in coordination. This is *not* the same as the AOS-style "fade in as you enter the viewport" pattern called out as anti-pattern in the `web-interaction-patterns` skill. The difference matters; conflating them produces either timid pages (no scroll storytelling) or overstuffed ones (every section fades and translates).

| Legitimate scrollytelling | AOS-style anti-pattern |
|--------------------------|----------------------|
| Visual transforms in coordination with scroll position (the iPhone rotates as you scroll) | Sections decoratively fade in as they enter the viewport |
| Each section earns its motion as part of the narrative | Motion is decoration applied uniformly to every section |
| Reduced-motion alternatives ship as static layouts that still tell the story | Reduced-motion just disables the fade; story is unaffected because there was no story |
| Tied to scroll position (`scroll-timeline` or IntersectionObserver with progress) | Tied to viewport entry (binary: faded or not) |
| Reserved for marquee marketing pages | Applied to every section by default |

When scrollytelling is correct: a product page where the narrative *is* the scroll. Apple's iPhone page, Stripe's homepage, Linear's marketing landing. When it's wrong: every other use.

Implementation hints to the developer: CSS `scroll-timeline` and `view-timeline` (Chromium 115+, behind a flag in Safari/Firefox at time of writing) are the modern correct primitives. Fall back to IntersectionObserver-driven progress for broader support. Always ship reduced-motion alternative.

## Video as Content

When marketing uses video — hero loop, product demo, customer story — the design treatment is its own craft.

- **Poster image renders first.** Set `poster="..."` on the `<video>` element so the first paint shows a high-quality still while video decodes. Without it, the area is blank during decode.
- **Reserve dimensions to prevent CLS.** `<video width="1920" height="1080">` (or aspect-ratio CSS) so the layout doesn't jump as the video loads.
- **`playsinline` for iOS.** Non-negotiable for hero loops; without it, the video tries to open fullscreen.
- **Captions / transcripts for any video > 30 seconds.** WCAG 1.2.2 (Captions, Level A) and 1.2.3 (Audio Description, Level A). Marketing videos are not exempt. Captions improve completion rate even for hearing users (sound-off viewing).
- **Lazy-load below-the-fold videos.** A "see the product in action" video three sections down doesn't need to load on first paint.
- **Compression**: H.264 + AAC for broad compatibility; AV1 / HEVC for modern browsers via `<source>` elements. A 60-second hero loop should target ≤ 3MB; longer videos served from a CDN with adaptive bitrate.
- **No sound-on autoplay**, ever. Hostile and blocked by every modern browser anyway.

## FAQ Section

Most marketing pages benefit from an FAQ section near the bottom, addressing the common pre-purchase questions a high-intent visitor asks before clicking the CTA.

- **Pattern**: accordion (one-at-a-time disclosure) — see the `web-interaction-patterns` skill. Don't use linear stacked Q&As that double the page length.
- **5–10 questions max.** Beyond 10, the FAQ becomes a help center; link to the help center instead.
- **Real questions**, written in the user's voice ("How does pricing work?" not "Pricing methodology overview").
- **Honest answers.** "We don't currently support X" beats marketing-speak around the missing feature.
- **`schema.org/FAQPage` JSON-LD** for SEO — the implementation lives Developer-side; the design responsibility is identifying which Q&As get marked up.
- **Voice consistency**: same brand voice as the rest of the marketing page. Content owns voice; UI/UX owns the structural pattern.

FAQ is the last persuasion surface before the user converts. Treat it as load-bearing, not as filler.

## A/B Test Readiness

Marketing pages are the place A/B testing genuinely matters (product UI rarely benefits from constant testing; marketing always does). Design with testing in mind:

- **Each section is independently testable**. Don't compose sections so tightly that swapping one breaks the layout.
- **Track every CTA** (in the section, in the hero, in the footer). The conversion funnel needs to identify which CTA drove the click.
- **Variant-friendly type scale**: a headline test that swaps 6-word headline for 12-word headline shouldn't break the layout.
- **Image variants**: the hero visual is testable separately from the copy.
- **Performance-first**: a slow A/B test SDK that delays render kills the test. Ship the SDK in a way that doesn't block LCP.

## The Footer

Often the last thing designed; sometimes the most-clicked area on the page.

- **Product links** (features, pricing, security, changelog) — by category.
- **Company links** (about, blog, careers, contact) — by category.
- **Legal** (terms, privacy, cookie preferences) — separate row, smaller text.
- **Language switcher** — see the `web-localization-and-i18n` skill. Footer is the canonical placement.
- **Social handles** with real icons (not platform-stamped logos that go out of date).
- **Copyright + company name** — bottom, muted.

Apple's footer is calm, dense, and load-bearing — the team finds the help link, the developer finds the docs, the investor finds the investor-relations link. Don't treat the footer as decorative.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **Hero carousel.** Three rotating slides at the top of the page. | Click-through rates drop sharply after slide 1. Users mentally tune out. No single message is primary. | One hero, one promise, one CTA. If the team can't pick, that's a strategy problem upstream. |
| **Multiple equal-weight CTAs in the hero.** "Sign up" + "Watch demo" + "Try free" + "See pricing" all the same size. | Decision paralysis; conversion drops for every additional equal CTA. | One primary CTA + one ghost secondary, max. Other actions live below the fold or in the nav. |
| **Auto-play video with sound on hero.** | Bounce driver. Hostile to users in shared spaces. | Auto-play *silent* loop only (and only for curated cinematic moments); explicit play control for sound. |
| **Stock-photo testimonials with stock-photo people.** "John, San Francisco" with a stock face. | Reads as fake. Erodes trust faster than no testimonials. | Real names, real photos (or no photo). If you don't have testimonials yet, omit the section. |
| **Fake urgency timers.** "Sale ends in 23:14:09 — don't miss out!" | The user comes back tomorrow, sees the timer reset; trust breaks. Reads as manipulative. | Real promotions with real end dates, or no countdown at all. |
| **Hidden trial-cancellation paths.** Easy to start; hard to cancel. | Dark pattern. Generates chargebacks, regulator complaints, and viral negative reviews. | Cancellation is one click (or one easy flow) from account settings, prominently labeled. |
| **Comparison tables that hide competitor wins.** Marking only your own checkmarks; omitting features your competitor has. | Users research; they notice; trust degrades. | Honest comparison: every feature listed; you and the competitor both win and lose rows. |
| **"Contact us" for prices users want to compare.** Enterprise tier has no price; users can't decide. | High-intent buyers leave because they can't price you against alternatives. | Show a starting price or band. Reserve "Contact us" for genuinely customized enterprise deals (not as a default). |
| **Long, busy marketing pages built with product-UI density.** Twelve cards of equal weight, four banners, three CTAs per section. | Looks busy, feels overwhelming, conversion suffers. | Marketing rhythm: one concept per scroll-screen, generous whitespace, one CTA per section. |
| **No OG / social card → links share with placeholder image.** | Looks unfinished. Reduces share-driven traffic. | Designed OG image per route (or templated per route type). Test in actual share previews. |
| **Pricing locked to monthly when annual is the better deal** (or vice versa). | Users want to compare; locking forces them to do math. | Toggle between monthly and annual; show the annual savings explicitly. |
| **Sticky CTA that follows scroll forever.** A "Sign up" button pinned to the bottom of the viewport from screen 1 to screen 12. | Visual noise, ad-blocker-flagged, annoying past 50% scroll. | Top-of-page CTA in nav + restated CTA at the bottom of the page. Sticky CTA is fine briefly (e.g., when the hero CTA scrolls out of view) but not perpetually. |
| **Marketing emails disguised as transactional.** Receipts that include "Check out our new feature!" promotions. | Legal issue (CAN-SPAM in US, GDPR in EU); trust degrades when receipts feel like ads. | Transactional emails are transactional. Marketing emails are separately opted into. |
| **Hero video > 5MB.** A 12MB autoplay video that delays LCP. | LCP misses budget; bounce rate triples; conversion drops. | Compress aggressively; use a poster image for first paint; lazy-load video. |
| **A/B-test SDK that blocks render.** A 200ms blocking script that decides which variant to show. | Delays LCP; defeats the test (the slowed-down variant always loses). | A/B test infrastructure that doesn't block paint. Vercel Edge Config or similar. |
| **Footer treated as decorative.** "Stay in the loop" + huge logo + no actual links. | Loses the users who need help, want docs, look for legal. | Calm, dense, load-bearing footer with real categorized links. |
| **Long-scroll page with no anchor nav.** Twelve sections; user scrolls past what they wanted. | Frustrating; users bounce. | Sticky in-page anchor nav that highlights the current section, OR shorter pages with focused content. |
| **Newsletter-popup modal that blocks the page after 5 seconds.** | Hostile; bounces users; ad-blockers flag it; ubiquitous SaaS regression. | Inline newsletter signup in the footer or a single section. If a modal is genuinely warranted, trigger on exit-intent at most, and dismissible permanently. |
| **Live-chat widget that fights LCP and is keyboard-trap-prone.** Intercom / Drift / etc. injected at top of `<body>`. | Slows LCP, blocks render, traps keyboard focus, conflicts with `inert` modal patterns. | Lazy-load post-LCP; defer to user click on a "Need help?" affordance; or omit entirely on landing pages. The conversion gain rarely justifies the cost. |
| **Cookie banner that shifts the marketing hero.** Banner renders after first paint; hero content jumps down. | CLS spike; hero CTA may be pushed off-screen on mobile; user clicks the wrong thing. | Reserve banner space at first paint via fixed height; or render banner as overlay (no layout shift). Coordinate with the `web-onboarding-flows` skill → Cookie Consent on placement. |
| **Auth-required marketing screenshots.** "See how it works → sign in to see the demo." | Defeats the marketing page; high-intent user bounces. | Show real screenshots inline. Sensitive customer data is anonymized or generic. |
| **Fabricated "As seen in" press logos.** Press logos from publications that haven't covered the product. | Trust-eroding when discovered; sometimes legally actionable. | Real coverage with real attribution, or omit the section. |
| **Hero headline that's a feature spec.** "React 19 + Server Components + Edge Runtime" as the H1. | Communicates capability, not value. The user doesn't buy capabilities; they buy outcomes. | Headline is the promise (the outcome), not the spec. Specs go in supporting sections. |

## Output

A marketing-page design produces:

1. **The page spec** in `knowledge-base/design-specs/marketing-<page>.md` — full screen spec per the `web-screen-specification` skill, with marketing-specific additions (conversion funnel events, A/B-test variants planned, performance budget, OG image asset).
2. **OG image asset** committed to the repo (e.g., `public/og/<route>.png` or generated via `next/og`).
3. **Conversion-funnel event list** — every CTA tracked, every section view tracked. Coordinated with PM and Marketing agents.
4. **Performance budget** for the page in the spec — explicit LCP target, image-weight budget, third-party-script policy.

## Principles

1. **One promise, one action.** Every additional promise dilutes the primary; every additional CTA dilutes the primary. The marketing-page designer's job is to push back on more.

2. **Marketing rhythm differs from product rhythm.** Hero is the page; one concept per scroll-screen; generous whitespace; cinematic moments are acceptable (with reduced-motion alternatives). Don't apply product-UI density to marketing.

3. **Performance is the conversion mechanism.** LCP under 1.5 seconds. No render-blocking third-party scripts above the fold. Hero images compressed; video lazy-loaded. A slow marketing page is a closed door.

4. **Honesty wins long-term.** Real social proof or none; honest comparison tables or none; transparent pricing or "Contact us" only when genuinely warranted; fake urgency never.

5. **The pricing page is a craft surface.** Three tiers, middle anchored, annual / monthly toggle, comparison table that doesn't hide losses, clear cancellation path. Every detail of the pricing page is scrutinized; treat it accordingly.

6. **One designed OG image per route.** Shared URLs are previewed; missing or default OG looks unfinished. Templated per route type, with custom assets for marquee pages.

7. **Restate the CTA at the bottom.** The user who scrolled to the end is high-intent. Give them the action without making them scroll back.

8. **Marketing pages are testable; product UI rarely is.** Design sections as independent A/B units; track every CTA; ensure variants don't break the layout. Performance-first A/B infrastructure that doesn't block paint.

9. **Footer is load-bearing.** Calm, dense, categorized links. The team finds help; the developer finds docs; the investor finds investor-relations. Not decorative.

10. **The marketing route group is separate from the product route group.** Cleanly separated concerns: `(marketing)` for landing / pricing / blog; `(app)` for product. Different chrome, different patterns, different performance budgets, different A/B infrastructure. See the `web-architecture` skill.
