# iOS Wireframe Methodology

## Purpose
Define how to produce high-fidelity text-based wireframes as an LLM — matching the clarity and intentionality of Apple's own design process. Every wireframe must communicate layout hierarchy, content priority, interaction behavior, and state variations so that a Developer agent can implement it without ambiguity. See `team/ui-ux/skills/ios-content-hierarchy.md` for the hierarchy exercise that must precede wireframing. See `team/ui-ux/skills/ios-screen-specification.md` for the full screen spec that wraps around wireframes. See `team/ui-ux/skills/ios-hig-reference.md` for platform conventions that wireframes must follow.

## Apple's Design Philosophy Applied to Wireframes
Apple designs with three principles that every wireframe must reflect:
1. **Deference** — The UI gets out of the way of the content. Wireframes should show content hierarchy first, chrome second. If a wireframe has more UI controls than content, reconsider the layout.
2. **Clarity** — Every element serves a purpose. If you can't explain why an element exists in the wireframe, remove it. White space is a design tool, not wasted space.
3. **Depth** — Layering creates meaning. Use z-axis to communicate relationships: sheets over content, blurred backgrounds behind modals, elevated cards for actionable items.

## Wireframe Format

### ASCII Layout Block
Use ASCII art within a fenced code block to represent spatial arrangement. This is the primary visual artifact.

```
┌─────────────────────────────┐
│ ◄ Back         Screen Title │  ← Navigation bar
├─────────────────────────────┤
│                             │
│  ┌───────────────────────┐  │
│  │  [Hero Content Area]  │  │  ← Primary content
│  │  fixed-height, .fit   │  │
│  └───────────────────────┘  │
│                             │
│  Heading Text               │  ← Font.heading2
│  Body text that explains    │  ← Font.body
│  the content above.         │
│                             │
│  ┌─────────┐ ┌─────────┐   │
│  │ Action1 │ │ Action2 │   │  ← Button row
│  └─────────┘ └─────────┘   │
│                             │
├─────────────────────────────┤
│ ● Today  Plan Library Progress│  ← Tab bar
└─────────────────────────────┘
```

### Conventions
- `┌┐└┘│─` for container boundaries
- `[Bracketed Text]` for placeholder media (images, animations, icons)
- `●` prefix for active/selected tab or state
- `◄` for back chevron
- `▼` for disclosure indicator
- `☰` for menu/hamburger (rare in iOS — avoid unless justified)
- `⬡` for SF Symbol icon placeholder (note the symbol name beside it)
- `───` horizontal rule for section dividers
- `...` for truncated text
- `(scrollable →)` annotation for horizontal scroll regions
- `(↕ scrollable)` annotation for vertical scroll content

### Width Reference
- iPhone SE: `[───── 375pt ─────]`
- Standard iPhone: `[────── 390pt ──────]`
- Pro Max: `[──────── 430pt ────────]`
- Always design for 390pt as default, note adaptations for SE and Max

## Annotation Layer
Below every ASCII wireframe, provide a structured annotation block:

```markdown
### Annotations
| # | Element | Design Token / Component | Behavior | Notes |
|---|---------|---------------------|----------|-------|
| 1 | Navigation bar | System UINavigationBar | Large title collapses on scroll | preferredLargeTitleDisplayMode: .always |
| 2 | Hero image | Radius.lg corner clip | Tap → fullscreen | Fixed-height container, ContentMode: .fit, Color.surface fill |
| 3 | Heading | Font.heading2, Color.onBackground | Static | Max 2 lines, truncate tail |
| 4 | Primary button | Library component name (if exists) or `needs-component` | Tap → next screen | Full width, Spacing.lg horizontal margin |
```

## Wireframe Completeness Checklist
Every wireframe delivery must include:

- [ ] **Default state** — The "happy path" with real sample data (not "Lorem ipsum" — use product-realistic content)
- [ ] **Empty state** — What shows when there's no data yet (illustration placeholder + message + CTA)
- [ ] **Loading state** — Skeleton screen layout showing shimmer placeholders matching content shapes
- [ ] **Error state** — Network/data error with recovery action
- [ ] **Edge cases** — Long text, single item, maximum items, first-time vs returning user
- [ ] **Free vs Premium** — If the screen differs by tier, show both variants
- [ ] **Scroll behavior** — What's fixed, what scrolls, what happens to nav bar on scroll
- [ ] **Safe area compliance** — Content respects notch/Dynamic Island and home indicator
- [ ] **Media recognizability** — For any image, thumbnail, or media element: can the user identify what's depicted at the specified size? Consider the actual content (3D character poses, exercise previews, profile photos) — not just abstract placeholders. Compare against Apple's sizing for similar elements (Apple Music ~80pt album art, App Store ~80pt app icons, Fitness+ ~120pt workout previews). If the element is content-forward (the user needs to understand what's in the image, not just see that an image exists), err toward larger sizes. Calculate how many items remain visible in scroll containers at the larger size and verify the parent layout still fits on iPhone SE without pushing the primary CTA below the fold.

## Content-First Wireframing Process
Before producing a wireframe, complete the hierarchy exercise in `team/ui-ux/skills/ios-content-hierarchy.md`. That skill defines how to rank content, assign hierarchy levels, and produce a hierarchy map. The hierarchy map is the input to wireframing — the wireframe is its spatial expression. Do not skip this step.

## Sample Data Guidelines
- Use realistic product content in wireframes: real item names, real entity names, realistic metrics (e.g., "Day 12 streak", "3 of 5 completed")
- Show text at realistic lengths — if an exercise name can be 30 characters, use one that long
- Numbers should be plausible (not "123" or "999" — use "47 exercises", "12 min")

## Multi-Screen Flow Notation
When documenting a flow (e.g., onboarding), connect screens with transition annotations:

```
[Screen 1: Welcome] ──push──→ [Screen 2: Discipline Select]
                                        │
                                   ──push──→ [Screen 3: Goals]
                                                    │
                                              (back via ◄)
```

Transition types: `push` (NavigationStack), `sheet` (modal), `fullScreenCover`, `tab switch`, `replace` (no back)
