# Web Content Hierarchy

## Purpose
Define how to decide what deserves emphasis on any web screen — *before* wireframing begins. Apple-quality UI is won or lost at the hierarchy level, not the component level. A screen with a beautiful component library and a flat hierarchy is mediocre; a screen with rough components and a clear hierarchy is strong. This skill produces a *hierarchy map* that becomes the input to the wireframe (the `web-wireframe-methodology` skill) and the spec (the `web-screen-specification` skill). See the `web-design-system` skill for the type, color, and spacing tokens hierarchy is expressed through. See the `web-responsive-patterns` skill for the layout primitives that preserve hierarchy across viewports. See UI/UX's `web-accessibility` skill for the heading-semantics rules that make hierarchy machine-readable. Target: **product screens for web — dashboards, lists, detail views, settings, forms, and marketing pages**.

## Decision Rule
Before laying out any web screen, complete the hierarchy exercise below. **If you can't name in one sentence the single most important thing the user should see, the screen isn't ready to wireframe.** Skipping this step produces visually competent screens with no answer to "where do I look?" — which is the most common failure mode in product UI.

## Apple's Content-First Hierarchy Model

Apple's marketing pages, App Store editorial, Fitness+, and News all share the same four-lever discipline. None of them rely on decorative chrome to communicate importance.

1. **Scale.** The most important element is the largest *by a lot*. Apple's iPad product page leads with a hero image where the device dominates the visual area; supporting text is a fraction of the size. The ratio matters — 4× scale reads as primary; 1.5× scale reads as "two equal things."

   **Weight is the second axis of scale.** Apple actively pairs weights at the *same* size as a hierarchy lever — a Semibold label sitting next to a Regular label at the same `text-body` size reads as primary-and-secondary without occupying more space. This is the tool to reach for when scale is constrained (dense rows, sidebars, tight cards) and bumping size would break the layout. Two weights paired at the same size: hierarchy. Three weights at the same size: noise — pick two.
2. **Space.** Important elements get generous whitespace around them. Cramped elements feel secondary regardless of size. Apple gives hero content room to breathe; on the web, that means `space-section-gap` between major regions, generous `padding` inside hero containers, and resistance to filling every margin.
3. **Position.** Primary content occupies the top of the visible area at the screen's smallest target viewport (375px). On desktop, primary content occupies the central column with secondary in sidebars. Tertiary lives below the fold. Quaternary lives behind a tap or interaction.
4. **Restraint.** Apple removes elements until removing one more would hurt comprehension. If something doesn't help the user's immediate task, it's hidden behind progressive disclosure, deferred to another screen, or removed entirely. The empty space is the design.

What Apple does *not* use for hierarchy: colored backgrounds on every card, borders around every region, bold weights on half the text, badges and pills strewn through the UI, drop shadows for emphasis, gradients to "make things pop." These are decorative crutches and almost always a sign that hierarchy was decided too late.

## Web-Specific Hierarchy Concerns

Web hierarchy adds five concerns iOS doesn't have. Address each during the hierarchy exercise.

### 1. The Fold (still real, despite the cliché)
The first viewport-height of content gets the most attention by an order of magnitude. Anything below the fold should *not* be primary. The fold differs by viewport:

| Viewport | Fold height (approx.) |
|----------|----------------------|
| Mobile portrait (375 × 667) | ~600px after browser chrome |
| Mobile landscape (667 × 375) | **~300px** after browser chrome — and **~110px** when on-screen keyboard is open |
| iPad portrait (768 × 1024) | ~960px after browser chrome |
| iPad landscape (1024 × 768) | ~700px after browser chrome |
| Desktop (1280 × 800) | ~700px after browser chrome |

Primary content must clear the fold contract on the smallest target *and* on landscape phone if the screen supports landscape. The harshest fold a product UI realistically faces is mobile landscape with the keyboard open — ~110px of usable space. A form that requires 300px of vertical room before the user sees the submit button is broken on that surface, regardless of how it looks in portrait.

### 2. Scroll-Driven Reading (F-pattern, Z-pattern)
Eye-tracking research repeatedly shows web users scan content-heavy pages in an F-pattern (left edge dominates), and marketing-style pages in a Z-pattern (top-left → top-right → bottom-left → bottom-right). Both patterns put *what's at the top-left* in the strongest position. Plan accordingly:

- Page title and primary CTA: top-left or top-center.
- Secondary navigation: top-right (less attention, but still visible).
- Tertiary content: scrolled-to.
- Don't bury primary actions in the bottom-right — that's the weakest position on a content page.

### 3. Hover and Focus as Interactive Hierarchy
Web has a state iOS doesn't: hover. Hover is a hint that a thing is interactive — but it's only available on pointer devices and is invisible until the user investigates. The hierarchy implication: **the static state of an interactive element must already communicate "this is interactive."** Hover is a refinement, never a reveal — a card that looks like a static container until hovered hides primary-or-secondary status from the eye scanning the screen, breaking the hierarchy intent.

The full rule (the touch-discovery and accessibility framings, the per-element treatment, the design-side enforcement) lives in UI/UX's `web-accessibility` skill → Anti-Patterns → "Hover-only interactivity" and is cited in the `web-interaction-patterns` skill. This skill cares about the hierarchy consequence: the static state is the hierarchy signal. Hover is decoration on top of it.

### 4. Heading Semantics (`<h1>` through `<h6>`)
Hierarchy is *also* machine-readable. Screen readers and search engines walk the heading tree. The discipline:

- One `<h1>` per page (the page's purpose).
- `<h2>` for major sections (3–5 per page is typical).
- `<h3>` for subsections.
- Don't skip levels (`<h1>` then `<h3>`) — even when visually you want a smaller size. Use the right tag and override style with a token (`text-h3` token on an `<h2>` element if needed — but ask whether the visual demotion is masking a hierarchy problem).

The heading tree should match the visual hierarchy. If they diverge, either the markup is wrong or the visual hierarchy is wrong.

### 5. Density Scales with Viewport (Within Limits)
On a 375px phone, density is necessarily low. On a 1280px desktop, the same screen can show more — but only if the additional information is *deliberate*. Adding "more dashboard widgets because we have room" is the dashboard-bloat anti-pattern; adding a sidebar with secondary actions because the design called for it is fine. The rule: **desktop layout adds content the design intentionally surfaces, not content the small layout had to hide.**

## Hierarchy Ladder Examples

Below are example hierarchy ladders for common web screen types. Adapt them to the product's specific screens; don't copy verbatim.

### Dashboard / Home Screen (signed-in app)
| Level | Content | Expression |
|-------|---------|-----------|
| Primary | Today's primary content — what should the user do right now? | Hero card, top of fold, distinct visual treatment, primary CTA |
| Secondary | Supporting context — why this content? | One line below primary card; tappable for detail |
| Tertiary | Streak / progress summary, recent activity | Subtle, after primary card, scannable |
| Hidden | Full historical breakdowns, settings | Behind navigation, not on this screen |

Rule: The dashboard answers one question — "what should I do right now?" Everything else supports or explains that answer. No more than one hero card per dashboard.

### List / Browse Screen
| Level | Content | Expression |
|-------|---------|-----------|
| Primary | The list itself (rows, cards, grid) | Fills the main area, scrollable |
| Secondary | Search and active filters | Top of list, compact, shows what's filtered |
| Tertiary | Sort control, filter sheet trigger | Behind a control, not always visible |
| Hidden | Item metadata (created at, modified by) | Inside detail view on row click |

Rule: The list is the screen. Filters refine, search retrieves — neither competes for primary attention. Pagination or "load more" lives below the list, not as a sticky element competing for attention.

### Detail / Article Screen
| Level | Content | Expression |
|-------|---------|-----------|
| Primary | The thing — title, hero, body | Large heading, comfortable reading width (`max-w-prose`), centered |
| Secondary | Author, date, status, primary action (edit, share, save) | Below title, smaller, less weight |
| Tertiary | Related content, comments, secondary actions | Below primary content, scrolled-to |
| Hidden | Edit history, raw metadata | Behind a "Details" or "History" link |

Rule: Reading is the task. Sidebars of "related" or "recommended" content compete for attention with the thing the user came for. Reserve sidebars for marketing pages; on detail pages, lead with the content.

### Form Screen (sign-up, settings, multi-field input)
| Level | Content | Expression |
|-------|---------|-----------|
| Primary | The fields the user must complete | Vertical stack, single column, generous spacing |
| Secondary | Field labels and helper text | Above each field; helper below; don't use placeholders as labels |
| Tertiary | Optional fields, advanced settings | Collapsed behind a disclosure |
| Hidden | Validation rules, format requirements | Surface at the moment the user violates them, not preemptively |

Rule: A form has *one* primary action ("Save," "Sign up," "Continue") at the bottom. Secondary actions ("Cancel") get less visual weight (ghost or text button). Do not put two equally-weighted submit buttons next to each other.

### Settings Screen
| Level | Content | Expression |
|-------|---------|-----------|
| Primary | Grouped settings list | Standard rows with labels and current values |
| Secondary | Group headings | Section titles, generous spacing between groups |
| Tertiary | Destructive actions (delete account, export data) | Bottom of screen, `danger` token, requires confirmation |
| Hidden | Help / documentation links | Inline within the relevant setting, not in a global sidebar |

Rule: Settings is a list. Don't dress it up. The user is here for one specific switch — they need to find it fast and toggle it once.

### Marketing / Landing Page
| Level | Content | Expression |
|-------|---------|-----------|
| Primary | Value proposition + primary CTA ("Get started," "Try free") | Hero, top of fold, fills viewport at smallest target |
| Secondary | Three or four supporting points (features, benefits) | Below the fold, scrolled-to, each gets its own region |
| Tertiary | Social proof, testimonials, logos | Further down |
| Hidden | Pricing details (linked to a dedicated page), FAQs | Behind links |

Rule: A landing page makes *one* promise and asks for *one* action. Sub-CTAs ("Watch a demo," "Read the docs") are smaller and visually subordinate. Hero carousels are an anti-pattern — they let no single message be primary.

### Onboarding Screen (one screen in a flow)
| Level | Content | Expression |
|-------|---------|-----------|
| Primary | The single question being asked or value being shown | Large heading, top of viewport |
| Secondary | Supporting illustration or input | Centered, generous space |
| Tertiary | Progress indicator, back button | Edges of screen, low weight |
| Hidden | Help text, "what is this?" links | Available but not pushed |

Rule: Each onboarding screen does *one* thing. No sidebars, no related content, no "learn more" boxes. See the `web-onboarding-flows` skill for full onboarding methodology.

## Attention Budgeting

Each screen has a finite attention budget. Apple's rule of thumb, applied to web:

| Screen Type | Max Primary Elements | Max Visible Actions |
|-------------|---------------------|--------------------|
| Dashboard | 1 hero card | 1 primary CTA + 1 secondary |
| List / browse | 1 content area | Search + filter (both subtle), 1 contextual action |
| Detail / article | 1 hero + 1 body | 1 primary CTA |
| Form | Stack of fields, 1 group at a time | 1 primary submit |
| Onboarding step | 1 question | 1 primary action |
| Marketing landing | 1 value prop | 1 primary CTA + 1 ghost secondary |
| Settings | N/A (list) | N/A (per-row) |

A wireframe with more primary elements than this table allows means something needs to be demoted, hidden behind interaction, or moved to another screen.

## Information Density Calibration

| Screen Type | Target Density | Guideline |
|-------------|---------------|-----------|
| Onboarding | Very low | One question per screen, generous whitespace, no distractions |
| Dashboard | Low–medium | Key info at a glance, details on tap or in tabs |
| List / browse | Medium | Efficient scanning; rows have just enough info to choose |
| Detail / article | Medium | Hero + supporting + body; sidebars only for navigation, never extra "you might like" content competing with body |
| Form | Medium | One field per row, clear labels; multi-column only when fields are intrinsically grouped (e.g., first/last name) |
| Settings | Medium–high | Dense list is expected and familiar |
| Marketing landing | Variable | Hero is low-density; supporting sections build density gradually as user scrolls in |

Warning: many web products err toward high density — every metric, badge, and CTA visible. A well-designed product feels calm and focused. More Linear than Jira.

## Copy-to-Layout Prioritization Method

Before wireframing, take the screen's product requirements and rank every piece of information:

1. **List every piece of content** the screen must communicate (from product spec).
2. **Force-rank by user need** — "If the user sees only ONE thing on this screen, what must it be?" That's #1. Continue ranking.
3. **Assign hierarchy level** — Top 1–2 → Primary. Next 2–3 → Secondary. Rest → Tertiary or Hidden.
4. **Challenge every Tertiary item** — Can it be removed entirely? Moved to another screen? Revealed only on interaction?
5. **Output a hierarchy map** (table format from the Output section below).

The hierarchy map becomes the input to wireframing. The wireframe is the spatial expression of this map. If the map and wireframe disagree, fix the wireframe — the map is the decision.

## Progressive Disclosure Rules

Not everything belongs on the first view. Web makes progressive disclosure cheaper than iOS (more screen space, hover affordances, route-driven detail screens), but the discipline still applies.

| Show immediately | Show on hover / focus | Show on click (expand / disclose) | Show on navigation (push / drill) |
|-----------------|----------------------|----------------------------------|-----------------------------------|
| The answer to "why am I on this screen?" | Tooltips for ambiguous icons | Supporting details that explain primary content | Full data, settings, edge cases |
| Primary CTA | Definition of a term | "Why" explanations (rationale) | History, logs, raw data |
| Current state | Keyboard shortcut hint | Secondary metrics | "How" details (methodology, algorithm) |
| Critical errors | — | Form field validation rules | Bulk actions, exports |

Apple's test: if removing something from the first view doesn't confuse the user, it shouldn't be on the first view.

## Scannability Checks

Run these checks on every wireframe before finalizing.

### 3-Second Test
Look at the wireframe for 3 seconds, then look away. Can you answer: "What is this screen for and what should I do?" If not, the hierarchy is wrong.

### Squint Test
Blur the wireframe (or imagine it at 25% size). The primary content should still be identifiable by its size and position. If everything blurs into the same shape, the hierarchy is flat.

### F-Pattern Test (content pages)
Trace your eye in an F shape across the wireframe — top edge, then a midline sweep, then a left-edge scan. Do the most important elements fall on those paths? If primary content sits in the bottom-right while the F-pattern's hot zones contain decoration, fix the layout.

### Above-the-Fold Test
Run this test at *both* portrait and landscape on the smallest phone target.

- **Portrait (375 × 667, ≈ 600px usable):** does the user see (a) what the screen is for, and (b) what to do next? If both don't fit, the hierarchy is too tall.
- **Landscape (667 × 375, ≈ 300px usable, ≈ 110px with keyboard open):** if the screen supports landscape, does the primary action remain reachable? Forms must keep the submit button reachable above (or just below) the keyboard on focus; heroes must surface the CTA without scroll.

If landscape is genuinely out of scope for the screen, mark it explicitly in the spec rather than skipping the test silently.

### Heading-Tree Test
Strip the wireframe of everything except headings. Can a screen-reader user understand the page from `<h1>` and `<h2>` alone? If the heading tree reads like a meaningless outline, either the visual hierarchy is wrong or the headings aren't aligned with it.

### Hover-Off Test
Disable hover styles in your imagination. Are interactive elements still discoverable as interactive? If a card only signals "click me" on hover, touch users will miss it entirely.

## Anti-Patterns to Reject

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| **Hero carousels.** Three rotating slides at the top of a marketing page. | No single message is primary; users mentally tune out the carousel; analytics consistently show CTR drops sharply after slide 1. | One hero, one message, one CTA. If you can't pick, the marketing team owes you a strategy decision, not more slides. |
| **Equal-weight cards across a dashboard.** Six cards of identical size and treatment, each with its own metric. | Nothing is primary. The user's eye finds no anchor and scans randomly. | Pick one hero (2–4× larger). Demote the others to secondary, or collapse them into a single "summary" panel. |
| **Banner overload.** Upgrade banner + cookie consent + notification + new-feature tip + system-status banner all visible simultaneously. | Competing banners create noise; users dismiss them all without reading. | One banner maximum at any moment. Use a queue if multiple need to surface. |
| **Hover-only interactivity.** Cards that look static until hovered; row actions that appear only on hover. | Touch users miss them entirely; pointer users have to investigate. | Static state must communicate interactivity (border, cursor, slight elevation, persistent action icon). Hover refines. |
| **Decorative chrome instead of hierarchy.** Bordered cards, drop-shadowed sections, gradient backgrounds applied to every region. | Decoration that doesn't communicate hierarchy adds noise. The eye still has nowhere to rest. | Remove decoration. Use scale, space, and position to communicate. Add back only what's needed to separate groups. |
| **Metric overload.** Showing 6+ KPIs / numbers / stats on a single dashboard. | Users absorb 2–3 metrics at a glance; more creates cognitive load and tunnel-out. | Pick the 1–2 most important metrics. Others go behind a "View all" tab or a separate analytics screen. |
| **Sidebars of "related content" on detail pages.** "You might also like" rails next to the article. | Competes with the body content the user came for; raises bounce rate. | Reserve sidebars on detail pages for navigation (table of contents, prev/next), not for related content. Related content goes below the body. |
| **Stuffed navigation.** A top nav with 9 links plus a sidebar with 7 more. | Discovery is harder, not easier — every link is competing. | Top nav: 4–6 destinations max. Sidebar: grouped, scannable. Less-used destinations live behind a "More" or in a dedicated screen. |
| **Demoting headings to fit a visual style.** Using `<div className="text-h2">` because you don't want an `<h2>` in this position. | Breaks the heading tree, hurts accessibility and SEO, signals confused hierarchy. | Either it's an `<h2>` (because it's a section title) or it's body text. Picking the visual via div masks the issue. |
| **"Above the fold" treated as desktop-only.** Hero designed at 1280px, mobile is "we'll figure it out." | Most users see the mobile fold; designing only for desktop guarantees the primary message is buried for the majority. | Design hierarchy at 375px first. Desktop adapts up; mobile is the contract. |

## Output Format

When completing a hierarchy exercise, produce this map and include it in the screen spec (`web-screen-specification.md`) before the wireframe section:

```markdown
## Hierarchy Map: [Screen Name]

### Content Ranking
| Rank | Content Item | Hierarchy Level | Expression | Rationale |
|------|-------------|----------------|-----------|-----------|
| 1 | [item] | Primary | [how it's shown — scale / space / position treatment] | [why it's #1] |
| 2 | [item] | Primary / Secondary | [how] | [why] |
| ... | ... | ... | ... | ... |

### Removed / Deferred Items
| Item | Reason | Where it lives instead |
|------|--------|----------------------|
| [item] | [why removed from this screen] | [other screen, hover, behind disclosure] |

### Density Assessment
- **Target** (from calibration table): [level]
- **Current**: [assessment]
- **Action needed**: [none / remove X / consolidate Y]

### Heading Tree
- `<h1>` [page title]
  - `<h2>` [section title]
    - `<h3>` [subsection title]
  - `<h2>` [section title]

### Above-the-Fold Contract (375px)
- User sees: [list of elements visible without scrolling]
- User can do: [primary action available without scrolling]
```

This map is the input to wireframing. The wireframe is the spatial expression of the map.

## Principles

1. **Hierarchy is the design.** Components, color, type — these are *how* hierarchy is expressed. The hierarchy decision *is* the design. A screen with a clear hierarchy and rough components is closer to shipping than one with polished components and a flat hierarchy.

2. **One thing is primary.** Every screen has exactly one most-important element. If two things are tied for primary, the hierarchy hasn't been decided — go back and rank.

3. **Scale, space, position, restraint — never decoration.** Apple's four levers cover 95% of hierarchy needs. Borders, shadows, gradients, badges, and pills are not hierarchy tools; they're decoration. Reach for them after hierarchy is decided, not before.

4. **The smallest viewport is the contract.** Hierarchy is verified at 375px. If primary content can't clear the fold there, the design isn't done. Desktop is the polish layer; mobile is the deliverable.

5. **Static state communicates interactivity.** Hover and focus refine; they never reveal interactivity that wasn't already implied. Touch users don't have hover; design for them first.

6. **Heading tree mirrors visual hierarchy.** `<h1>` is the page; `<h2>` is sections. Skipping levels or using divs for visual reasons breaks accessibility and SEO simultaneously. If you don't want an `<h2>` here visually, either the content isn't a section or the visual treatment is wrong.

7. **Less, then less, then less.** The pressure to add — another card, another metric, another banner, another link — is constant. Push back. The product feels calm because designers held the line, not because the codebase happened to ship clean.

8. **Hierarchy is decided once, expressed everywhere.** The hierarchy map flows into the wireframe, the spec, the implementation, and even the analytics events. Inconsistency in hierarchy across these artifacts is a tell that the decision wasn't really made.
