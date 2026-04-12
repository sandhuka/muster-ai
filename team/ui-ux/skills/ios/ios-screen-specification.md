# iOS Screen Specification Template

## Purpose
Define the complete screen specification format used to hand off designs to the Developer agent. A screen spec is the single source of truth for implementing one screen. It wraps wireframes, component specs, interaction specs, state definitions, and accessibility annotations into one document. See `team/ui-ux/skills/ios-content-hierarchy.md` for the hierarchy exercise that precedes layout. See `team/ui-ux/skills/ios-wireframe-methodology.md` for wireframe format. See `team/ui-ux/skills/design-system.md` for component token usage. See `team/ui-ux/skills/ios-animation-interaction.md` for animation specs. See `team/ui-ux/skills/ios-copy-fitting-microstates.md` for copy budgets, placeholder format, and microstate specs. See `team/ui-ux/skills/accessibility.md` for a11y requirements.

## Apple's Detail Standard
Apple ships screens where every pixel is intentional. A world-class screen spec leaves zero ambiguity:
- Every element has a token reference
- Every state is defined
- Every interaction has a response
- Every edge case has a design
If the Developer has to guess, the spec is incomplete.

## Screen Spec Template

```markdown
# Screen: [Screen Name]
**Feature ID**: [F-XXX-N from product spec]
**Flow**: [Which user flow this screen belongs to]
**Entry points**: [How the user arrives — tab tap, push from X, sheet from Y]
**Exit points**: [Where the user can go — back, close, tap to X, tab switch]

---

## Navigation Context
- **Presented via**: [NavigationStack push | sheet(detent) | fullScreenCover | tab root]
- **Navigation bar**: [large title | inline title | hidden]
- **Title**: "[exact title text]"
- **Left bar item**: [back (auto) | close button | none]
- **Right bar items**: [SF Symbol name + action, max 2]
- **Tab bar visible**: [yes | no]

---

## Layout

### Wireframe
[ASCII wireframe here — see ios-wireframe-methodology.md]

### Annotations
[Annotation table here — element-by-element breakdown]

### Layout Structure
[Describe the SwiftUI view hierarchy in plain language]
- Root: ScrollView (vertical, bounces: true)
  - Section 1: [Description] — VStack, spacing Spacing.md
    - Element A: ...
    - Element B: ...
  - Section 2: [Description] — LazyVGrid, 2 columns
    - Element C (repeating): ...
- Fixed bottom: [Description] — pinned outside scroll, Spacing.md padding

### Scroll Behavior
- [What scrolls, what's fixed]
- [Large title collapse behavior]
- [Sticky headers, if any]
- [Pull-to-refresh: yes/no]

---

## Content & Data

### Data Sources
| Field | Source | Update Frequency | Fallback |
|-------|--------|-----------------|----------|
| Routine title | Algorithm output | Daily generation | "Your Routine" |
| Exercise list | Algorithm output | Per session | Empty state |
| Streak count | Local storage | After each session | 0 |

### Copy
| Element | Copy | Character Limit | Design Token |
|---------|------|----------------|----------|
| Screen title | "Today" | 10 | Font.largeTitle via nav bar |
| Section header | "Your Routine" | 20 | Font.heading3 |
| Empty state message | "[Content agent to provide]" | 80 | Font.body |
| CTA button | "Start Session" | 20 | Font.bodyBold |

---

## States

### Loading
[Wireframe or description of skeleton layout]
- Duration: show skeleton for minimum 0.3s to avoid flash
- Transition to content: crossfade 0.2s

### Content (Default)
[Primary wireframe — this is the main design]

### Empty
[Wireframe or description]
- When: [condition — e.g., "no routine generated yet"]
- Elements: [illustration placeholder] + [message] + [CTA]
- CTA action: [what happens on tap]

### Error
[Wireframe or description]
- When: [condition — e.g., "algorithm failed to generate routine"]
- Elements: [error icon] + [message] + [retry button]
- Retry action: [re-trigger data load]

### Free Tier Variant
[If this screen differs for free users, show the variant]
- Differences: [what changes — hidden elements, upgrade banners, degraded features]

### Premium Variant
[If different from default, show the premium version]

---

## Interactions

### Tap Targets
| Element | Action | Transition | Haptic |
|---------|--------|-----------|--------|
| "Start Session" button | Begin active session | fullScreenCover | Impact — medium |
| Exercise card | Open exercise detail | push | Impact — light |
| Rationale text | Expand rationale card | sheet(.medium) | None |

### Gestures
[Custom gestures, if any — use format from ios-animation-interaction.md]

### Animations
[Screen-specific animations — use format from ios-animation-interaction.md]

---

## Accessibility

### VoiceOver Reading Order
1. [First element read] — label: "[text]"
2. [Second element] — label: "[text]", hint: "[hint]"
3. ...

### Dynamic Type Behavior
- [How layout adapts at xxxLarge — e.g., "2-column grid becomes single column"]
- [Text that truncates vs. wraps]
- [Elements that reflow]

### Reduce Motion
- [What animations are replaced with crossfades]
- [Looping content that becomes static]

### Accessibility Actions
- [Custom actions available via VoiceOver rotor, if any]

---

## Responsive Adaptations
| Device | Adaptation |
|--------|-----------|
| iPhone SE (375pt) | [Changes — e.g., "exercise cards show 1 column instead of 2"] |
| iPhone standard (390pt) | [Default design — no changes] |
| iPhone Pro Max (430pt) | [Changes — e.g., "wider margins, 3-column grid option"] |
| iPad | [Changes — e.g., "sidebar navigation, master-detail layout"] |

---

## Component Inventory
List all components used on the screen. Check `knowledge-base/design-system-reference.md` for existing library components (may be empty after library reset).

| Component | Library Component | Status |
|-----------|-------------|--------|
| *(example)* Primary button | Library component name | exists |
| *(example)* Exercise card | — | needs-component (request UIUX-COMP-001) |

---

## Open Questions
- [Any unresolved design decisions — tag the agent who can answer]
- [e.g., "PM: Should rationale be visible by default or collapsed?"]
```

## When to Use This Template
- **Always** for screens being handed off to the Developer agent
- For Sprint 1: onboarding screens (F-ONB-0 through F-ONB-6), navigation structure, Today screen (F-ALG-1)
- Create one spec file per screen in `knowledge-base/design-specs/`
- Reference this template from the spec file — don't copy the template headers into every spec (use the structure, fill in the content)

## Spec Quality Checklist
Before marking a screen spec as ready for Developer:

- [ ] All sections filled (no "[TBD]" or empty sections)
- [ ] Every element uses design system tokens (no raw color/size values)
- [ ] All 5 states defined (loading, content, empty, error + tier variants)
- [ ] Copy is either final (from Content agent) or has clear placeholders with character limits
- [ ] Component inventory complete — all `needs-component` requests filed
- [ ] VoiceOver reading order specified
- [ ] Dynamic Type behavior at xxxLarge documented
- [ ] Reduce Motion alternatives noted for all animations
- [ ] Responsive adaptations for SE and Pro Max noted
- [ ] Open questions tagged with responsible agent
