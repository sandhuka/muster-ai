# Accessibility Standards

## Purpose
Ensure every screen meets WCAG 2.1 AA and iOS accessibility requirements. See `team/ui-ux/skills/design-system.md` for touch target and contrast standards in component specs. See `team/ui-ux/skills/mobile-patterns.md` for interaction patterns that need accessible alternatives.

## Minimum Requirements (WCAG 2.1 AA)
- Color contrast: 4.5:1 for normal text, 3:1 for large text (18pt+) and UI components
- All images have meaningful alt text (decorative images marked as such)
- All interactive elements reachable and operable via VoiceOver
- Support Dynamic Type up to at least xxxLarge
- No information conveyed by color alone (use icons, patterns, or text)

## iOS-Specific Accessibility
- Use semantic SwiftUI views (Button, Toggle, Link — not onTapGesture on Text/Image)
- Add .accessibilityLabel() for icon-only buttons and non-text elements
- Group related elements: .accessibilityElement(children: .combine)
- Add .accessibilityHint() for non-obvious actions
- Use .accessibilityValue() for sliders, progress indicators
- Test VoiceOver navigation order — it should follow logical reading order

## Support These System Settings
- Dynamic Type (text scaling)
- Bold Text
- Reduce Motion (replace animations with crossfades)
- Reduce Transparency
- Increase Contrast
- VoiceOver
- Switch Control
- Dark Mode (not just a11y but essential for OLED and low-light)

## Testing Checklist
- [ ] VoiceOver: Navigate entire screen — logical order, all elements labeled
- [ ] Dynamic Type: Test at xxxLarge — no truncation, no overlaps
- [ ] Bold Text: Ensure readability maintained
- [ ] Reduce Motion: No sliding/bouncing animations, only crossfade
- [ ] Color contrast: Verify all text passes 4.5:1 ratio
- [ ] Touch targets: All interactive elements at least 44x44pt
- [ ] Keyboard/Switch Control: All actions achievable without gestures
- [ ] Screen reader: No "button button" or "image image" redundancy

## Health/Fitness A11y Considerations
- Workout timers must be accessible (announce time remaining via VoiceOver)
- Progress charts need text alternatives summarizing the data
- Haptic feedback should pair with visual + audio cues (not standalone)
- Exercise demonstrations: provide text descriptions alongside images/animations
- Exercise animation a11y: provide static thumbnail fallback when Reduce Motion is enabled — never force looping animation on users who've opted out
- Rest timer VoiceOver announcements: announce time remaining at intervals (30s, 15s, 5s countdown), not continuously
- Character persona a11y descriptions: Sarah, Candy, and Ayan need `.accessibilityLabel()` descriptions when their images appear ("Sarah demonstrating push-up" not just "exercise image")
- Algorithm rationale strings: ensure rationale text on Today screen and Plan tab is readable by VoiceOver as a single coherent element, not fragmented across multiple accessibility containers
