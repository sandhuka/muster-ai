# iOS Accessibility

## Purpose
Define accessibility requirements for iOS apps: Dynamic Type, VoiceOver, Reduce Motion, color differentiation, and interaction patterns. See `team/developer/skills/ios-best-practices.md` for broader Apple HIG compliance. See `team/developer/skills/ios-modern-api.md` for modern API replacements relevant to accessibility.

## Dynamic Type
- Never force specific font sizes — use semantic fonts (`.font(.body)`, `.font(.headline)`, etc.)
- Custom font sizes: use `@ScaledMetric` or `.font(.body.scaled(by:))` for dynamic scaling
- Avoid `.caption2` (extremely small) and use `.caption` carefully
- Avoid fixed frames for views — they break across Dynamic Type sizes and device sizes. Prefer flexible sizing

## VoiceOver
- Images must have an `accessibilityLabel()`, or be marked decorative with `Image(decorative:)` or `.accessibilityHidden()`. Flag images with unclear readings (e.g., `Image(.newBanner2026)`)
- Buttons must always include text, even if invisible: `Button("Label", systemImage: "plus", action: myAction)`. Flag icon-only buttons as bad for VoiceOver
- Menus must include text: `Menu("Options", systemImage: "ellipsis.circle") { }` — not image-only
- Never use `onTapGesture()` unless you specifically need tap location or tap count. All other tappable elements should be a `Button`
- If `onTapGesture()` must be used, add `.accessibilityAddTraits(.isButton)` so VoiceOver reads it correctly

## Reduce Motion
- When the user has Reduce Motion enabled, replace large motion-based animations with opacity transitions instead

## Voice Control
- For buttons with complex or frequently changing labels (e.g., live stock prices), use `accessibilityInputLabels()` to provide stable Voice Control commands

## Color Differentiation
- If color is an important differentiator, respect `accessibilityDifferentiateWithoutColor` — show variation beyond just color using icons, patterns, or strokes

## Tap Targets
- Minimum 44x44pt for all interactive elements — strictly enforced
- Prefer `Button` over `onTapGesture()` for all standard interactions

## Principles

1. **Text labels are non-negotiable**: Every interactive element must be describable by assistive technology. If a sighted user can tap it, a VoiceOver user must be able to identify and activate it.

2. **Respect user preferences**: Dynamic Type, Reduce Motion, and color differentiation settings exist because users need them. Design for flexibility, not fixed layouts.

3. **Test with assistive tech on**: Run VoiceOver through every screen's critical path at least once. Issues that are invisible in visual testing become immediately obvious.
