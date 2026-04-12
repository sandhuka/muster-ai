# iOS Content Hierarchy

## Purpose
Define how to decide what deserves emphasis on any screen — before wireframing begins. Apple-quality UI is won or lost at the hierarchy level, not the component level. A technically correct wireframe with wrong emphasis is worse than a rough wireframe with right emphasis. Read this skill when structuring a screen's information density, prioritization, and visual emphasis. See `team/ui-ux/skills/ios-wireframe-methodology.md` for the wireframe production format that comes *after* hierarchy is decided. See `team/ui-ux/skills/ios-hig-reference.md` for platform conventions that constrain how hierarchy is expressed.

## Decision Rule
Before laying out any screen, complete the hierarchy exercise below. If you can't clearly name the #1 thing the user should see, the screen isn't ready to wireframe.

## Apple's Content-First Hierarchy Model
Apple reduces chrome and promotes the main task through four techniques — never decoration:

1. **Scale** — The most important thing is the largest. Not by a little — by a lot. Apple's Weather app: the current temperature is 4x larger than any other text on screen.
2. **Space** — Important things get generous whitespace around them. Cramped elements feel secondary regardless of size. Apple gives hero content room to breathe.
3. **Position** — Primary content occupies the top-center of the visible area (above the fold). Secondary content is below or in tabs. Tertiary is behind taps (drill-in, sheets).
4. **Restraint** — Apple removes elements until removing one more would hurt comprehension. If something doesn't help the user's immediate task, it's hidden behind progressive disclosure or removed entirely.

What Apple does NOT use for hierarchy: colored backgrounds on cards, borders around everything, bold on half the text, badges/pills on every element, drop shadows for emphasis. These are decorative crutches.

## Hierarchy Ladder Examples
Below are example hierarchy ladders for common screen types. Adapt these to your product's specific screens.

### Onboarding Screens
| Level | Content | Expression |
|-------|---------|-----------|
| Primary | The question being asked ("What are your goals?") | Large heading, top of visible area |
| Secondary | Selection options (cards/chips) | Medium size, central area, generous tap targets |
| Tertiary | Progress indicator, back/skip actions | Small, edges of screen, low visual weight |
| Hidden | Explanatory help text | Only on tap/long-press if user needs it |

Rule: Each onboarding screen asks ONE question. No sidebars, no secondary info, no previews.

### Dashboard / Home Screen
| Level | Content | Expression |
|-------|---------|-----------|
| Primary | Today's primary content — what should the user do right now? | Prominent card with preview, primary CTA |
| Secondary | Supporting context — why this content? | 1-line text below primary card, tappable for detail |
| Tertiary | Streak/progress summary | Small, above or below primary card, glanceable number |
| Hidden | Full detail breakdowns, history | Behind taps (expand, drill to other tabs) |

Rule: The home screen answers one question: "What should I do right now?" Everything else supports or explains that answer.

### Active Session Screen
| Level | Content | Expression |
|-------|---------|-----------|
| Primary | Current content/media + name | Hero area, largest element, full-width |
| Secondary | Counter/timer | Large, high contrast, directly below hero |
| Tertiary | Progress indicator, controls (pause/skip) | Edges, minimal chrome |
| Hidden | Details, tips, options | Swipe up or tap for info sheet |

Rule: During an active session, the user's focus is on the primary content. Everything else must be glanceable in peripheral vision. Maximum 3 visible elements competing for attention.

### Browse / Library Screen
| Level | Content | Expression |
|-------|---------|-----------|
| Primary | Content collection (grid/list of items) | Fills the screen, scrollable |
| Secondary | Active filters/search | Top area, compact, shows what's filtered |
| Tertiary | Filter/sort controls | Behind search bar expansion or filter sheet |
| Hidden | Item metadata | Inside detail view on tap |

### Plan / Schedule Tab
| Level | Content | Expression |
|-------|---------|-----------|
| Primary (premium) | This week's plan — calendar with daily content | Central, visual calendar layout |
| Primary (free) | Upgrade value proposition | Clear message + preview of what they'd get |
| Secondary | Individual day details | On tap — not all visible at once |
| Tertiary | Rationale chips per day | Subtle, tappable for explanation |

### Progress / History Screen
| Level | Content | Expression |
|-------|---------|-----------|
| Primary | Current streak / key metric | Large number, top of screen |
| Secondary | Trend visualization (chart) | Mid-screen, full-width |
| Tertiary | History list | Below chart, scrollable |
| Hidden | Individual item details | On tap from history list |

### Settings
| Level | Content | Expression |
|-------|---------|-----------|
| Primary | Grouped settings list | Standard iOS insetGrouped list |
| Secondary | Current values/states | Right-aligned detail text per row |
| Tertiary | Destructive actions (delete account, clear data) | Bottom of list, red text, requires confirmation |

## Attention Budgeting
A screen has a limited attention budget. Apple's rule of thumb:

| Screen Type | Max Primary Elements | Max Visible Actions |
|-------------|---------------------|-------------------|
| Dashboard (Today) | 1 hero card | 1 primary CTA + 1 secondary |
| Active session | 1 animation + 1 counter | 2 controls (pause + skip) |
| List/browse | 1 content area | Search + filter (both subtle) |
| Form (onboarding) | 1 question | 1 primary action (Next) |
| Detail | 1 hero + 1 description | 1 primary CTA |
| Settings | N/A (standard list) | N/A |

If your wireframe has more primary elements than this table allows, something needs to be demoted or hidden.

## Information Density Calibration

| Screen Type | Target Density | Guideline |
|-------------|---------------|-----------|
| Onboarding | Very low | One question, generous whitespace, no distractions |
| Dashboard (Today) | Low-medium | Key info at a glance, details on tap |
| Active session | Minimal | Exercise + counter only. User is physically moving. |
| Library browse | Medium | Grid of content, efficient scanning |
| Detail | Medium | Hero + supporting info, scrollable |
| Progress/charts | Medium | Data visualization + summary stats |
| Settings/form | Medium-high | Dense list is expected and familiar |

Warning: many apps err toward high density (showing every metric, badge, and stat). A well-designed product should feel calm and focused — more Apple Fitness+ than a cluttered dashboard.

## Copy-to-Layout Prioritization Method
Before wireframing, take the screen's product requirements and rank every piece of information:

1. **List every piece of content** the screen must communicate (from product spec)
2. **Force-rank by user need** — "If the user sees only ONE thing on this screen, what must it be?" That's #1. Continue ranking.
3. **Assign hierarchy level** — Top 1-2 items → Primary. Next 2-3 → Secondary. Rest → Tertiary or Hidden.
4. **Challenge every Tertiary item** — Can it be removed entirely? Moved to another screen? Revealed only on interaction?
5. **Output a hierarchy map** (table format from Hierarchy Ladder above)

This map becomes the input to wireframing. The wireframe is the spatial expression of this hierarchy.

## Progressive Disclosure Rules
Not everything belongs on the first view. Use these rules:

| Show immediately | Show on tap/expand | Show on drill-in (push/sheet) |
|-----------------|-------------------|------------------------------|
| The answer to "why am I on this screen?" | Supporting details that explain the primary content | Full data, settings, edge cases |
| Primary CTA | Secondary metrics or metadata | History, logs, raw data |
| Current state (what's happening now) | "Why" explanations (rationale) | "How" details (methodology, algorithm) |

Apple's test: if removing something from the first view doesn't confuse the user, it shouldn't be on the first view.

## Scannability Checks
Run these checks on every wireframe before finalizing:

### 3-Second Test
Look at the wireframe for 3 seconds, then look away. Can you answer: "What is this screen for and what should I do?" If not, the hierarchy is wrong.

### Squint Test
Blur your vision (or imagine the wireframe at 25% size). The primary content should still be identifiable by its size and position. If everything looks the same blurred, the hierarchy is flat.

### Thumb-Zone Test
On a one-handed phone grip, the primary CTA must be in the natural thumb arc (bottom-center). Secondary actions can be at the top. Avoid placing primary actions in the top corners (hard to reach).

### Count-the-Boxes Test
Count distinct visual containers (cards, sections, bordered areas). If > 4 visible containers on a phone screen, the layout is probably too fragmented. Consolidate.

## Anti-Patterns to Reject

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| **Equal-weight cards** — 3-4 cards of identical size/style on one screen | Nothing is primary. User doesn't know where to look first. | Make one card the hero (2x size), demote others or collapse into a list. |
| **Banner overload** — upgrade banner + notification + tip + streak all visible | Competing banners create noise. User dismisses all of them mentally. | One banner max per screen. Rotate them or prioritize by context. |
| **Over-explained empty states** — 3 paragraphs explaining why the list is empty | User just needs to know what to do. | One sentence + one CTA. "No sessions yet. Start your first routine." |
| **Decorative clutter** — borders, shadows, backgrounds, icons on everything | Decoration that doesn't communicate hierarchy is noise. | Remove all decoration. Add back only what's needed to separate groups. |
| **Metric overload** — showing 6+ numbers/stats on a single screen | Users can absorb 2-3 metrics at a glance. More creates cognitive load. | Pick the 1-2 most important metrics. Others go behind a "See all" tap. |
| **Persistent navigation clutter** — showing breadcrumbs, page titles, section headers all at once | iOS handles navigation through the nav bar and back button. Extra nav elements waste space. | Trust the system navigation. Remove redundant wayfinding. |

## Output Format
When completing a hierarchy exercise, produce:

```markdown
## Hierarchy Map: [Screen Name]

### Content Ranking
| Rank | Content Item | Hierarchy Level | Expression | Rationale |
|------|-------------|----------------|-----------|-----------|
| 1 | [item] | Primary | [how it's shown] | [why it's #1] |
| 2 | [item] | Primary/Secondary | [how] | [why] |
| ... | ... | ... | ... | ... |

### Removed/Deferred Items
| Item | Reason | Where it lives instead |
|------|--------|----------------------|
| [item] | [why removed from this screen] | [other screen or interaction] |

### Density Assessment
Target: [density level from calibration table]
Current: [assessment]
Action needed: [none / remove X / consolidate Y]
```

This hierarchy map should be completed BEFORE starting the wireframe and included as a section in the screen specification (see `ios-screen-specification.md`).
