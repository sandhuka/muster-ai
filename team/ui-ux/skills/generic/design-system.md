# Design System

## Purpose
Define the component standards, spec handoff format, and component request workflow that ensure every screen is built from shared UI library tokens — never raw values. See the `mobile-patterns` skill for screen-level layout patterns and the `accessibility` skill for accessibility requirements that apply to every component.

## Token Source of Truth
All design tokens (colors, typography, spacing, radius) are defined in the **shared UI library** (e.g., a private CocoaPod, Swift Package, or design token package). Components are added incrementally as the UI/UX agent designs screens and identifies reusable patterns — the Components section in the reference file may be empty. The authoritative reference is `knowledge-base/design-system-reference.md`, auto-generated from the library source files after every dependency update. Do not edit it manually. Do not duplicate token values here — always reference that file.

## Token Refresh Procedure
If `design-system-reference.md` seems outdated or you need to verify current token values, read the source files directly:

1. **Token source files** (always present):
   - `[App]/Pods/[LibraryName]/Sources/[LibraryName]/Tokens/ColorTokens.swift` — all color definitions
   - `[App]/Pods/[LibraryName]/Sources/[LibraryName]/Tokens/TypographyTokens.swift` — font scale and weights
   - `[App]/Pods/[LibraryName]/Sources/[LibraryName]/Tokens/SpacingTokens.swift` — spacing and corner radius
   - `[App]/Pods/[LibraryName]/Sources/[LibraryName]/Tokens/ThemeTokens.swift` — theme environment object

2. **Extensions and Modifiers** (always present):
   - `[App]/Pods/[LibraryName]/Sources/[LibraryName]/Extensions/*.swift` — Color/Font convenience accessors, font registration, resource bundle
   - `[App]/Pods/[LibraryName]/Sources/[LibraryName]/Modifiers/*.swift` — View modifiers (card, shadow, rounded border)

3. **Components** (may be empty — added incrementally):
   - `[App]/Pods/[LibraryName]/Sources/[LibraryName]/Components/*.swift` — if directory exists

**Steps**: Read the source files above → compare against `design-system-reference.md` → if values differ, regenerate the reference file with current values.

## Component Standards
- Every component must support light and dark mode
- Every interactive component must have visible focus states
- Touch targets: minimum 44x44pt (Apple HIG requirement)
- Loading states: skeleton screens for initial load, spinner for actions
- Empty states: illustration + message + primary action for all list/collection views
- Error states: clear message + recovery action (retry, go back, contact support)

## Component Spec Handoff Template
When handing off a component spec to the Developer agent, use design token references — never raw values:

```
Component: [Name]
Screen: [Where it appears]
Library Component: [existing library component name, or "needs-component"]

Layout:
- Background: Color.surface
- Padding: Spacing.md (16pt)
- Corner radius: Radius.lg (12pt)
- Border: Color.border, 1pt (if applicable)

Typography:
- Title: Font.heading3, Color.onBackground
- Body: Font.body, Color.onSurface
- Caption: Font.caption, Color.onSurface

Spacing:
- Between title and body: Spacing.xs (8pt)
- Between body and action: Spacing.sm (12pt)

States:
- Default: [describe]
- Pressed: [describe]
- Disabled: [describe]
- Loading: [describe]
- Error: [describe]
```

## Component Request Workflow

### New Component
When a design requires a component not yet in the shared UI library:
1. Design the component using existing library tokens (colors, fonts, spacing, radius) for visual consistency
2. Add a request to `knowledge-base/ui-component-requests.md` with status `needs-component`
3. Include: component name, screen/feature, description, priority, the token-based spec, AND a **Prompt** field (see "Component Prompt Authoring" below)
4. The founder hands the Prompt to a coding agent to build the component into the library; Developer consumes via dependency update
5. When updating any field in an existing request, update the Prompt in the same edit -- the two must always match

### Component Update
When an existing shared UI library component needs modification (e.g., size change, new parameter, behavior tweak):
1. Read the current component source from the library's `Components/[ComponentName].swift` to understand what exists
2. Add a request to `knowledge-base/ui-component-requests.md` with status `needs-update` using the update template
3. The `What Changed` field must clearly describe the diff from current behavior (e.g., "Thumbnail size 56x56 → 72x72")
4. The `Breaking` field must state YES or NO — YES if the public API signature changes (parameters added/removed/renamed) or if existing visual behavior changes in a way that could affect screens already using the component
5. The `Prompt` field must contain the full updated component specification — not just the diff. The coding agent replaces the existing implementation with the prompt's spec
6. Update any design spec annotations in `knowledge-base/design-specs/` that reference the changed properties
7. The founder hands the Prompt to a coding agent to update the component; Developer consumes via dependency update

## Component Prompt Authoring
Every `needs-component` or `needs-update` request must include a `Prompt` field: a self-contained specification the founder can copy-paste directly to a coding agent. The prompt must be complete enough that the coding agent needs no additional context beyond the shared UI library codebase. For `needs-update` prompts, the prompt replaces the entire component — it is not a diff. Write the full spec as if building from scratch, incorporating the changes.

### Required Sections in Every Prompt
```
Build a SwiftUI component called [ComponentName] in [LibraryName]/Components/[ComponentName].swift.

[If dependencies on other library components: list them and note build order]

Public API:
  [Full initializer signature with parameter names, types, and defaults]

Visual spec:
  [Every visual detail using library token names — never raw values]
  [Layout structure (HStack/VStack/ZStack nesting)]
  [All states: default, pressed, disabled, loading, error — omit any that truly don't apply]
  [Animations with duration and easing]
  [Haptic feedback type if interactive]

Accessibility:
  [accessibilityLabel, traits, hints]
  [Dynamic Type support notes]
  [VoiceOver behavior]

Dark mode: automatic via library color token resolution.

Preview: [What to show in the SwiftUI preview — include concrete example data]
```

### Rules
- Use library token names only (e.g., Color.primary, Font.button, Spacing.md, Radius.lg) — never hex values, point sizes, or "some padding"
- The prompt must be self-contained: a coding agent reading only this prompt and the library source should produce the correct component
- If the component composes other library components, state that dependency explicitly and note build order
- Include concrete preview examples with realistic data (not "placeholder")
- When the design spec changes, rewrite the prompt in the same edit — never leave a stale prompt

## Handoff Format for Developer Agent
When providing specs:
- Use exact token references (e.g., "Spacing.md" not "some padding", "Color.surface" not a hex value)
- Specify ALL states: default, pressed, disabled, loading, error
- Note any animations with duration token and easing
- Call out platform-specific adaptations (iOS vs web)
- Include redlines for spacing-critical layouts
- Reference existing library components by name where available

## Design System Principles

1. **Tokens over raw values**: Every color, font, spacing, and radius value in a spec must reference a library token. If a designer writes a hex value instead of a token name, the spec is incomplete.

2. **Reference over duplicate**: Token definitions live in `knowledge-base/design-system-reference.md`. Never copy token values into specs or skill files — always point to the reference.

3. **Design first, then check the library**: Design what's best for the product. After finalizing, check if the component exists in the shared UI library. If not, file a `needs-component` request — don't compromise the design to fit existing components.

4. **Every state specified**: A component spec without all 5 states (default, pressed, disabled, loading, error) is incomplete. Omitting states leads to inconsistent developer implementations.
