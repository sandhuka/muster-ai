# Apple Human Interface Guidelines — iOS Reference

## Purpose
Codify the Apple HIG conventions that every screen must follow. This is not a summary of the full HIG — it's the subset that directly impacts day-to-day design decisions for an iOS app. When in doubt, the answer should feel like something Apple would ship. See `team/ui-ux/skills/mobile-patterns.md` for product-specific screen patterns built on top of these conventions. See `team/ui-ux/skills/ios-animation-interaction.md` for motion and haptic guidelines.

## Apple's Core Design Principles
These aren't abstract ideals — they are decision filters. When choosing between two design options, pick the one that better satisfies these:

1. **Aesthetic Integrity** — The app's appearance and behavior should match its purpose. A fitness app should feel energetic but focused, not playful like a game or sterile like a utility.
2. **Consistency** — Use system-provided components and patterns so users already know how the app works before they learn it. Don't reinvent the tab bar, the navigation bar, or the sheet.
3. **Direct Manipulation** — People should feel like they're touching content, not pressing buttons that affect content elsewhere. Swipe the card, drag the slider, pinch the chart.
4. **Feedback** — Every action needs a visible (and often haptic) response. A tap with no feedback is a broken tap.
5. **Metaphor** — Use real-world parallels. A calendar looks like a calendar. A card stack looks stackable. Progress fills like a liquid.
6. **User Control** — The user is in charge. Never trap them in a flow. Always provide a way back, a way out, and a way to undo.

## Navigation Model

### Tab Bar (UITabBarController)
- Maximum 5 tabs. Most apps use 4-5 (e.g., Home, Browse, Activity, Settings)
- Each tab maintains its own navigation stack (switching tabs preserves state)
- Tab icons: SF Symbols only. Use filled variant for selected, outlined for unselected
- Badge indicators: small red dot for attention-needed states (not numbered badges for fitness apps)
- Tab bar is always visible except during immersive experiences (active workout session uses `fullScreenCover` to hide it)

### Navigation Bar (UINavigationBar)
- **Large titles**: Use for top-level screens (each tab's root). Collapses to inline on scroll.
- **Inline titles**: Use for pushed detail screens
- **Back button**: Always shows previous screen's title (or "Back" if title is too long). Never replace with a custom icon.
- **Right bar items**: Maximum 2 actions. Use SF Symbols. Primary action rightmost.
- **Search**: Use `.searchable()` modifier. Search bar appears below nav bar, hides on scroll down, appears on scroll up or pull.

### Modal Presentation
- **Sheet (`.sheet`)**: For focused tasks that don't require full context switch. Medium detent (`.presentationDetents([.medium, .large])`) for quick inputs. Dismiss via swipe-down or explicit button.
- **Full screen cover (`.fullScreenCover`)**: For immersive flows (active workout, onboarding). Must provide explicit dismiss/close button — no swipe dismiss.
- **Alert**: For destructive confirmations only. Never for information delivery.
- **Confirmation dialog (`.confirmationDialog`)**: For action menus with 2-4 options. Replaces action sheets.

## Typography System

### iOS Semantic Text Styles
Design using semantic size tiers (not arbitrary font sizes). If your product uses a custom font (via design system font tokens) rather than SF Pro, Dynamic Type scaling must be implemented manually using `UIFontMetrics` — it is NOT automatic. The font tokens should map to the same semantic size tiers as the system styles below:

| Style | Usage | Approx. Size (default) |
|-------|---------------|----------------------|
| `.largeTitle` | Tab root screen titles (via large nav bar) | 34pt |
| `.title` | Section headers on dashboard | 28pt |
| `.title2` | Card titles | 22pt |
| `.title3` | Subsection headers | 20pt |
| `.headline` | Emphasized body text, exercise names in session | 17pt semibold |
| `.body` | Primary readable text | 17pt |
| `.callout` | Secondary descriptive text | 16pt |
| `.subheadline` | Metadata, timestamps, tags | 15pt |
| `.footnote` | Captions, disclaimers, legal text | 13pt |
| `.caption` | Tertiary labels | 12pt |
| `.caption2` | Smallest labels (badge text) | 11pt |

Design system font tokens should follow this hierarchy (e.g., Font.heading2 = custom font SemiBold 22pt, matching the .title2 tier). See `knowledge-base/design-system-reference.md` for exact token definitions. The Developer agent must register custom fonts via the library's font registration method and scale with `UIFontMetrics` for Dynamic Type support.

### Typography Rules
- Never use more than 2 font weights on a single screen (regular + semibold is typical)
- Line spacing: use system defaults (they're optimized for readability)
- Truncation: prefer truncation (`.lineLimit()`) over shrinking font size. Shrinking breaks Dynamic Type.
- Numbers in data displays: use `.monospacedDigit()` so digits don't jump during updates (timers, counters)

## SF Symbols

### Usage Rules
- Use SF Symbols for all icons. Never use custom icon assets unless the symbol doesn't exist.
- Use the **filled** variant for selected states, **outlined** for unselected
- Rendering modes:
  - **Monochrome**: Default for navigation, toolbars
  - **Hierarchical**: For icons with depth (e.g., `figure.run` in workout context)
  - **Multicolor**: Only for system-provided meanings (e.g., `heart.fill` in red for health)
  - **Palette**: For brand-colored icons (use design system accent colors)
- Symbol weight should match adjacent text weight
- Prefer symbols with `.circle.fill` suffix for action buttons (e.g., `play.circle.fill`)

### Common Symbol Patterns
| Context | Symbol | Notes |
|---------|--------|-------|
| Home/Dashboard tab | `house.fill` or `calendar.badge.clock` | Evaluate based on product |
| Browse/Library tab | `books.vertical` or `rectangle.grid.2x2` | |
| Schedule/Plan tab | `calendar` | |
| Progress/Stats tab | `chart.line.uptrend.xyaxis` | |
| Play/start action | `play.circle.fill` | Large, prominent |
| Pause | `pause.circle.fill` | |
| Skip/next | `forward.end.fill` | |
| Timer | `timer` | |
| Premium badge | `crown.fill` | Gold/accent colored |
| Settings | `gearshape` | |

## Color & Appearance

### System Colors vs Design System Tokens
iOS provides semantic system colors (`.label`, `.secondaryLabel`, `.systemBackground`, etc.) that auto-adapt to light/dark mode and accessibility. Products with a shared UI library use **design system color tokens instead** — they serve the same semantic roles but with the product's custom palette (see `knowledge-base/design-system-reference.md`):

| Semantic Role | System Color | Design Token (example) | Key Difference |
|--------------|-------------|----------|---------------|
| Primary text | `.label` | `Color.onBackground` | Custom tone instead of pure black |
| Secondary text | `.secondaryLabel` | `Color.onSurface` | Custom gray |
| Background | `.systemBackground` | `Color.background` | Custom light/dark variants |
| Elevated surface | `.secondarySystemBackground` | `Color.surface` | Custom elevated surface |

Always use design system tokens in specs, never raw system colors. The tokens already include light/dark mode variants. For system-provided components (alerts, action sheets), system colors apply automatically — don't override them.

### Dark Mode
- Not an inverted light mode — it's a separate considered design
- Elevated surfaces get lighter (not darker) in dark mode to show depth
- Use materials (`.ultraThinMaterial`, `.regularMaterial`) for overlays — they adapt automatically
- Test every screen in both modes. Shadows behave differently (less visible in dark mode — use elevated backgrounds instead)

### Materials & Vibrancy
- Use `.ultraThinMaterial` for overlays on top of media content (e.g., controls over workout animation)
- Use `.regularMaterial` for navigation bars and tab bars when content scrolls behind them
- Vibrancy makes text/icons adjust to the content behind the blur — use `.secondary` vibrancy for less important text on materials

## Layout & Spacing

### Safe Areas
- Always respect safe areas. Content must not be obscured by Dynamic Island, home indicator, or rounded corners.
- Edge-to-edge images/media can ignore safe areas (`ignoresSafeArea()`) but interactive elements must stay within them
- Keyboard avoidance: use `.scrollDismissesKeyboard(.interactively)` for forms

### Layout Margins
- Use system layout margins (`.padding(.horizontal)` with default values) — they adapt per device
- iPhone SE: 16pt margins. Standard: 16pt. Pro Max: 20pt. iPad: content-width centered.
- Cards within margins: additional internal padding of Spacing.md (16pt)

### Spacing Hierarchy (Apple's Visual Rhythm)
- Related elements: 8pt (Spacing.xs)
- Grouped elements: 16pt (Spacing.md)
- Section breaks: 24-32pt (Spacing.lg to Spacing.xl)
- The eye should be able to "parse" groups instantly by their spacing

### Scroll Views
- `.contentMargins()` for section insets
- Lazy stacks for long lists (`LazyVStack` with `.pinned` section headers)
- Pull-to-refresh: system-provided `.refreshable()` — don't custom-build
- Scroll indicators: visible by default, hide only for horizontal paged content

## Lists & Grouped Content

### List Styles
- `.insetGrouped` — Default for settings, forms, preference screens (rounded cards)
- `.plain` — For content feeds and exercise lists
- `.sidebar` — iPad only
- Swipe actions: `.swipeActions()` — primary action on trailing edge, secondary on leading
- Use section headers for grouping. Headers should be sticky (`.headerProminence(.increased)`)

## Sheets & Popovers

### Sheet Sizing (iOS 16+)
- Use `presentationDetents` to offer multiple heights:
  - `.medium` — Quick input, previews, confirmations
  - `.large` — Complex forms, detailed content
  - `.height(200)` — Known small content (e.g., upgrade prompt)
- `.presentationDragIndicator(.visible)` — Always show the grab handle
- Corner radius: system default (don't override)

## Platform-Feel Checklist
Before finalizing any screen design, verify:
- [ ] Uses system navigation (NavigationStack, TabView) — not custom nav
- [ ] Large titles on root screens, inline on detail screens
- [ ] SF Symbols for all icons (correct rendering mode)
- [ ] Semantic text styles (not hardcoded sizes)
- [ ] System colors or design system tokens mapped to semantic equivalents
- [ ] Works in light mode AND dark mode
- [ ] Respects safe areas
- [ ] Uses system layout margins
- [ ] Pull-to-refresh where content updates
- [ ] Sheet detents for modal content
- [ ] Back button shows previous screen title
- [ ] No custom chrome where system components exist
