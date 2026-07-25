# Web Testing Methodology

## Purpose
Web-specific validation patterns: responsive layout, code-level accessibility auditing, PWA/service-worker
verification, network-absence and privacy assertions, cross-engine rendering, link/asset validation, and
timezone-sensitive logic. Covers static sites, web apps, and web surfaces of multi-platform products. See
`team/qa/skills/generic/test-strategy.md` for testing levels and coverage targets;
`team/qa/skills/generic/verification-discipline.md` for the trust-then-verify stance every check below
assumes (re-run it yourself; never accept the developer's screenshot as evidence).

## Sandbox Reality
Most QA sessions validate without real devices, app stores, or live screen readers. That is workable if
you are explicit about what each environment can prove:

| Claim | Sandbox-provable? | How |
|---|---|---|
| Layout, rendering, responsive behavior | Yes | Headless browser screenshots at set viewports |
| Accessibility *tree* correctness | Yes | DOM/semantic audit at code level |
| Real screen-reader experience | No — say so | Code-level audit is the stand-in; flag for device pass |
| Offline behavior | Yes | Local server + service-worker lifecycle test |
| Zero network calls / tracker-free | Yes | DevTools/network-log assertion |
| Cross-engine parity (WebKit vs Blink) | Partially | `qlmanage`/Safari on macOS, else flag |
| Live performance (real network, real device) | No — say so | Lab metrics only; label them as lab |

Never let a sandbox stand-in silently impersonate the real check. The handoff states which column each
verdict came from.

## 1. Responsive & Layout
- Test the breakpoint *boundaries*, not just the design's named sizes: 320, 375, 768, 1024, 1440, plus
  ±1px around each CSS breakpoint the stylesheet declares.
- **No horizontal scroll at any viewport** — assert `document.documentElement.scrollWidth <= innerWidth`
  in a headless run; a screenshot alone hides a 2px overflow.
- Wide content (tables, code blocks, diagrams) must scroll inside its own container, never the page body.
- Text zoom 200% and browser-font-size overrides: layout reflows, nothing truncates or overlaps.
- Verify with content at realistic extremes: longest real string, empty states — not lorem ipsum.

## 2. Accessibility (code-level audit)
Audit the semantic tree the assistive tech will consume:
- **Landmarks & structure:** one `<main>`, `<nav>`/`<header>`/`<footer>` present, heading levels
  strictly nested (no h1→h3 skips), one h1 per page.
- **Focus:** every interactive element reachable by Tab in a sensible order; visible focus indicator
  (`:focus-visible` styled, never `outline: none` without replacement); no keyboard traps.
- **Names:** every control has an accessible name (text content, `aria-label`, or association);
  images carry `alt` (empty `alt=""` only when decorative); links make sense out of context.
- **ARIA:** prefer native elements; every `aria-*` attribute checked against actual semantics — wrong
  ARIA is worse than none.
- **Contrast:** compute ratios for text/background pairs from the actual CSS values (≥4.5:1 body,
  ≥3:1 large text); check both themes if the site ships light + dark.
- **Motion:** every animation gated behind `prefers-reduced-motion`; verify the reduced path renders
  complete content, not a blank.
- Label the audit honestly: "semantic tree verified at code level — real VoiceOver/NVDA pass still
  pending" when that is the truth.

## 3. PWA / Service Worker / Offline
- Serve the production build from a local HTTP server (service workers don't register from `file://`).
- Lifecycle: first visit registers the worker and populates the cache → kill the server (or set browser
  offline) → reload → the app renders fully from cache. Assert content, not just HTTP 200 from cache.
- Manifest: valid JSON, icons resolve, `start_url` in scope, display mode as spec'd.
- Update path: deploy a changed build → verify the worker updates and stale caches are evicted
  (versioned cache names). A worker that pins users to a dead version is a Critical bug.

## 4. Network & Privacy Assertions
- **Zero-request builds:** load with the network log recording; assert no requests leave the page's own
  origin beyond the expected set. "Tracker-free" and "Data Not Collected" claims are verified here — at
  code level AND network level (a removed SDK can leave a live beacon).
- Grep the built output for analytics/telemetry fingerprints (gtag, fbq, hotjar, sentry, plausible…) —
  whatever the privacy claim excludes must be absent from the *shipped* bundle, not just the source.
- Third-party requests that do remain (fonts, CDNs): each one is a privacy-policy line item — cross-check
  with Legal's data-collection statement.

## 5. Cross-Engine Rendering
Chrome-only verification is not web verification:
- On macOS, `qlmanage -p` or Safari exercises WebKit cheaply; headless Chrome covers Blink. Firefox if
  available.
- Known divergence hot-spots to check deliberately: SVG (filters, masks, foreignObject), `data:` URIs,
  backdrop-filter, form controls, font fallback, smooth-scroll behavior.
- Self-contained artifacts (inline SVG, canvas-painted textures) are the classic WebKit-only failure —
  an independent cross-engine re-check has caught Safari-only breakage that every Chrome pass missed.
  If an engine is unavailable in the sandbox, the handoff says which engines were actually verified.

## 6. Links & Assets
- Crawl every `href`/`src` in the built output: internal links resolve (case-sensitive — the deploy
  host will be), anchors point at existing ids, no localhost/placeholder URLs survive the build.
- Placeholder awareness: links intentionally stubbed pre-launch ("#", "TBD") are inventoried in the
  handoff with their fill-by milestone, not silently passed.
- Assets: no 404s, no oversized images (flag > ~200KB unoptimized), correct MIME/caching headers if the
  host is configurable.

## 7. Timezone & Date Logic
Date-driven features (rotations, schedules, "today" logic) fail at the edges, not the middle:
- Re-derive expected values independently (own script, not the implementation) across a matrix of dates
  × timezones — include UTC-positive, UTC-negative, and a DST transition day.
- Run the implementation under forced timezones (`TZ=Pacific/Kiritimati`, `TZ=America/Anchorage`, UTC)
  and diff against the derivation. Byte-identical data + matching derivation = pass.
- Midnight boundaries: the value must change exactly at the product's declared boundary (local vs UTC —
  confirm which one the spec means; this is a common unstated assumption).

## 8. Evidence Discipline
- Every verdict names its evidence: the command, the viewport, the engine, the screenshot path. "Looks
  right" is not a QA artifact.
- Take your own screenshots; never re-use the developer's (independent re-verification — the same rule
  PM applies to you).
- Acceptance items map 1:1 to checks run; a skipped item is reported as skipped with the reason, never
  absorbed into an overall PASS.
