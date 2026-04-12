# Accessibility Testing

## Purpose
Define accessibility testing methodology for the product on iOS. Covers VoiceOver, Dynamic Type, color contrast, motion preferences, alternative input, and the shared UI library component compliance. Use this skill when building test plans, executing accessibility audits, or reviewing new screens against accessibility requirements.

Cross-references: `test-strategy.md` (testing levels, device matrix), `bug-reporting.md` (filing accessibility bugs), `knowledge-base/design-system-reference.md` (TA token definitions), `knowledge-base/ui-component-requests.md` (component tracker).

---

## VoiceOver Testing

### Navigation Order
- Enable VoiceOver on the test device (Settings > Accessibility > VoiceOver, or triple-click Side button if shortcut configured).
- Swipe right through each screen end-to-end. Verify the focus order matches the visual reading order (top-to-bottom, leading-to-trailing). Flag any element that is announced out of sequence.
- On screens with distinct sections (e.g., Today screen: greeting, streak badge, routine card, bottom nav), verify sections are traversed in logical groups, not interleaved.
- Tab bar: verify VoiceOver announces the selected tab and allows switching tabs with a single tap. Verify the tab bar is reachable from any point on the screen via the rotor "Containers" action or by swiping to the end.

### Accessibility Labels
Every interactive and informational element must have a meaningful label. Reject:
- Generic labels: "Button", "Image", "Icon", "View"
- Redundant trait announcements: "Start Workout Button Button" (double trait)
- Missing labels: elements that VoiceOver skips entirely or announces as "dimmed" with no context
- Technical identifiers: "img_exercise_001", "btn_cta_primary"

Required label quality by screen area:
| Element | Expected Label Pattern | Bad Example |
|---------|----------------------|-------------|
| Exercise thumbnail | "[Exercise name]" or "[Exercise name], [muscle group]" | "Image" or "thumbnail_42" |
| Routine card CTA | "Start Workout" (the button title) | "Button" |
| Streak badge | "5 day streak" (count + context) | "flame.fill" or "5" |
| Smart badge | "Designed for You" | "sparkles" or "Badge" |
| Selection card | "[Title], [Description], not selected" or "selected" | "Card" |
| Chip in chip group | "[Option text], selected" or "not selected" | "Chip 1" |
| Progress dots | "Step 3 of 6" | "dot dot dot" |
| Timer during session | "2 minutes 30 seconds remaining" (live, not "02:30") | "02:30" |
| Back/navigation buttons | "Back, [previous screen name]" or "[destination]" | "chevron.left" |

### Custom Actions for Complex Interactions
These elements have multiple interaction targets that must be individually reachable via VoiceOver:
- **TARoutineCard**: Card body tap (opens detail) and CTA button (starts workout) are separate targets. Verify VoiceOver does not combine them into a single element. Both must be independently focusable and tappable.
- **TAThumbnailStrip**: The strip itself announces "N exercise thumbnails" (group label). Individual thumbnails should not each receive focus (noise reduction). If the strip becomes interactive (tap to preview), each thumbnail needs its own label.
- **TASelectionCard**: Verify the combined label reads "[Title], [Description]" and announces "selected" or "not selected" state. Verify double-tap toggles selection and VoiceOver confirms the state change.
- **Active session exercise transitions**: When the user advances to the next exercise, VoiceOver must announce the new exercise name and any changed state (rep count, timer reset). Do not rely on the user noticing a visual change — the transition must push an accessibility notification (`UIAccessibility.post(notification: .screenChanged, argument: ...)`).

### Rotor Support
- Verify the Headings rotor option navigates between screen sections (e.g., on Today screen: greeting heading, routine card heading).
- Verify any adjustable controls (sliders, steppers, pickers) respond to rotor "Adjust" swipe-up/swipe-down gestures.
- During active session: verify the Actions rotor surfaces pause/skip/previous actions without requiring the user to find buttons spatially.

### Active Workout Session with VoiceOver
This is the highest-risk screen for accessibility because it changes state continuously:
1. **Exercise name**: Announced on every transition. Must include position ("Exercise 3 of 12, Goblet Squat").
2. **Timer**: Use `.accessibilityValue` that updates with remaining time in human-readable format ("45 seconds remaining"), not "00:45". Mark with `.updatesFrequently` trait. Do NOT post a screen-changed notification every second — that interrupts the user.
3. **Rest periods**: Announce "Rest, 30 seconds" when rest begins. Announce "Next exercise, [name]" when rest ends.
4. **Pause/Resume**: VoiceOver must announce the state change ("Paused" / "Resumed"). Timer announcement should stop during pause.
5. **Session completion**: Post `.screenChanged` notification to announce the completion screen. VoiceOver should read the summary (duration, exercises completed, calories if shown).
6. **Animation playback**: The exercise loop animation does not need an audio description (the exercise name label is sufficient), but verify the animation view is not focusable as a separate VoiceOver element with an empty or useless label.

---

## Dynamic Type Testing

### Test Matrix
Test at these sizes minimum. Do not skip the extremes — most bugs appear at AX sizes.

| Category | Settings Path | Priority |
|----------|--------------|----------|
| Default (Large) | Baseline — verify no regressions | Required |
| xSmall | Smallest standard size | Required |
| AXXXLarge | Maximum accessibility size | Required |
| XXXL | Largest standard (non-AX) size | Required |
| AXLarge | Mid-range accessibility size | Recommended |

To set Dynamic Type in Simulator: Settings > Accessibility > Display & Text Size > Larger Text. Or use Xcode Accessibility Inspector's font size override for faster iteration.

### Layout Validation at Large Sizes
At AXXXLarge, verify every screen for:
- **Clipping**: Text is not cut off or hidden behind other elements. Multi-line wrapping must work.
- **Overlap**: Elements do not stack on top of each other. Check especially: TARoutineCard block rows (name + duration may collide), TASelectionRow (title + subtitle + radio indicator), tab bar labels.
- **Scrollability**: If content overflows the screen, it must be scrollable. Screens that fit at Default size but not at AXXXLarge need a ScrollView wrapper.
- **Minimum tap targets**: All interactive elements must be at least 44x44pt at every text size. Apple HIG minimum. Check: chip group chips (TAChipGroup min height is 44pt — verify this holds at all text sizes), selection row radio indicators, progress dots (not interactive, but if tapped, should not trigger adjacent elements), thumbnail strip items (if interactive).
- **Button height**: TAPrimaryButton has a 52pt fixed height. At AXXXLarge, verify the button label does not clip. If the label overflows, it should either wrap to two lines or the button height should grow. Flag if it clips.

### TAFont Token Scaling
the shared UI library uses Poppins (custom font). Custom fonts do NOT automatically support Dynamic Type unless explicitly configured with `UIFontMetrics` or SwiftUI's `.dynamicTypeSize()` / `@ScaledMetric`.

Verify:
- Every `TAFont.*` token scales proportionally when the user changes text size. Set AXXXLarge and compare each token's rendered size to its base size — it should be noticeably larger.
- If any TAFont token does NOT scale (stays at its base size regardless of Dynamic Type setting), file a `needs-update` request in `knowledge-base/ui-component-requests.md` against the typography tokens.
- Test in both Simulator (fast) and physical device (authoritative — Simulator can mask font rendering differences).

### Screens to Prioritize for Dynamic Type
1. Onboarding selection screens (F-ONB-1 through F-ONB-5): Cards with titles and descriptions must not clip.
2. Today screen routine card: Duration, exercise count, block rows, and CTA button.
3. Active session: Exercise name, timer, and controls.
4. Library: Exercise list items with names, muscle group tags, and thumbnails.
5. Settings: All row labels and any inline values.

---

## Color Contrast Testing

### WCAG 2.1 AA Requirements
| Content Type | Minimum Contrast Ratio |
|-------------|----------------------|
| Normal text (< 18pt or < 14pt bold) | 4.5:1 |
| Large text (>= 18pt or >= 14pt bold) | 3:1 |
| UI components and graphical objects | 3:1 |

### TAColor Token Contrast Verification
Test every foreground/background combination used in the app. The critical pairs from the current token set:

**Light Mode**
| Foreground | Background | Expected Ratio | Notes |
|-----------|-----------|----------------|-------|
| `TAColor.onBackground` (#2F2520) | `TAColor.background` (#FFFFFF) | ~13.5:1 | Primary text — should pass easily |
| `TAColor.onSurface` (#6B5D55) | `TAColor.surface` (#FDF8F7) | ~4.3:1 | Secondary text — borderline for AA normal text. Verify >= 4.5:1 |
| `TAColor.onPrimary` (#FFFFFF) | `TAColor.primary` (#B85635) | ~3.8:1 | White on primary brown — passes for large text only. Flag if used for body text |
| `TAColor.secondary` (#2D7D8A) | `TAColor.surface` (#FDF8F7) | Check | Smart badge teal on surface — must pass 4.5:1 for caption text |

**Dark Mode**
| Foreground | Background | Expected Ratio | Notes |
|-----------|-----------|----------------|-------|
| `TAColor.onBackground` (#EDE5DD) | `TAColor.background` (#1A1512) | Check | Primary text dark mode |
| `TAColor.onSurface` (#B0A59C) | `TAColor.surface` (#262019) | Check | Secondary text dark mode — verify >= 4.5:1 |
| `TAColor.onPrimary` (#1A1512) | `TAColor.primary` (#D4845F) | Check | Dark mode primary button text |

**Known risk**: `TAColor.onPrimary` on `TAColor.primary` in light mode (~3.8:1) fails AA for normal text. This is used for TAPrimaryButton labels (17pt SemiBold = "large text" threshold is 14pt bold, so 17pt SemiBold qualifies as large text). Verify the 3:1 large-text threshold is met. If any screen uses this combination for smaller text, file a bug.

### Tools
- **Xcode Accessibility Inspector** (Xcode > Open Developer Tool > Accessibility Inspector): Run Color Contrast audit on any view. Can inspect individual elements.
- **Colour Contrast Analyser** (macOS app, free from TPGi): Input hex values manually. Use for verifying token pairs offline.
- **Simulator contrast testing**: Take screenshots in both light and dark mode, measure contrast ratios for key pairs.
- **Environment override**: In Xcode Scheme settings, enable "Increase Contrast" accessibility option to test high-contrast mode support.

### What to Flag
- Any text with contrast below 4.5:1 on its background (or below 3:1 for large text).
- Any non-text UI element (icons, borders, focus indicators) with contrast below 3:1.
- Feedback colors (error, success, warning) used as the sole indicator — verify they are not the only way information is conveyed (color should be supplemented with icons or text).

---

## Motion and Animation

### Reduce Motion Preference
When the user enables Reduce Motion (Settings > Accessibility > Motion > Reduce Motion), the app must respect `UIAccessibility.isReduceMotionEnabled` / SwiftUI's `@Environment(\.accessibilityReduceMotion)`.

### What Must Change with Reduce Motion
| Animation | Normal Behavior | Reduce Motion Behavior |
|-----------|----------------|----------------------|
| Exercise loop animations | 2-5 sec looping video/WebP | Static thumbnail (first frame or designated poster frame). Must not play. |
| Screen transitions | Spring/slide animations | Instant cut (crossfade at most, no sliding) |
| TAPrimaryButton press | Scale 0.98 + spring | Instant state change, no scale animation |
| TAProgressDots step change | `.easeInOut(duration: 0.2)` | Instant transition |
| TASmartBadge appear | Fade-in `.easeIn(duration: 0.2)` | Instant appear |
| TAChipGroup selection | `.easeInOut(duration: 0.15)` | Instant state change |
| Routine card expand/collapse | Animated height change (if applicable) | Instant resize |
| Tab switching | Default SwiftUI transition | Crossfade only |

### Testing Procedure
1. Enable Reduce Motion on device/simulator.
2. Walk through every screen and interaction. Verify no spring, bounce, slide, or loop animation plays.
3. Exercise loop animations: verify the static thumbnail shows in place of the animation — in the library, on the Today screen routine card, and during the active session.
4. Active session: verify exercise transition does not animate (no slide between exercises). The next exercise should appear immediately.
5. Disable Reduce Motion and verify all animations return.

### Pre-fetch Behavior with Reduce Motion
Even with Reduce Motion enabled, the app may still pre-fetch animation assets (for the case where the user disables Reduce Motion mid-session). This is acceptable. What matters is that fetched animations are NOT played when the preference is active. Verify playback respects the preference, not fetching.

---

## Switch Control and Alternative Input

### Basic Validation
Switch Control testing is lower priority than VoiceOver but must be validated before release:
1. Enable Switch Control (Settings > Accessibility > Switch Control). Use "Auto Scanning" with a single switch (the screen) for simulator testing.
2. Verify every interactive element on each screen is highlighted during the scan cycle. No element should be skipped.
3. Verify the scan order is logical (matches visual layout).
4. Verify selection (tap) triggers the correct action.
5. Verify dismissible elements (sheets, modals, alerts) can be dismissed via Switch Control.

### Elements Most Likely to Fail
- Custom gesture-based interactions (swipe to skip exercise, drag to reorder) — these need Switch Control equivalents.
- Full-screen overlays (active session) — verify the scan can reach pause/stop controls.
- Floating elements (FABs, badges) — verify they appear in the scan cycle at the expected position.

### Voice Control
Verify that all buttons and interactive elements can be activated by saying their label name (Voice Control uses accessibility labels). This is a free validation if labels are already correct from VoiceOver testing. Quick smoke test: enable Voice Control, say "tap Start Workout" on the Today screen, verify it activates.

---

## Accessibility Audit Checklist

Use this per-screen checklist during system testing. Each row is a pass/fail check. Adapt as screens are implemented.

### Onboarding (F-ONB-0 through F-ONB-6)

| Check | Details | Pass/Fail |
|-------|---------|-----------|
| VoiceOver: Welcome screen | Focus order: illustration > title > subtitle > CTA. CTA label is button title, not "Button". | |
| VoiceOver: Selection screens (F-ONB-1 to F-ONB-5) | Each TASelectionCard/TASelectionRow announces title, description, selected state. State changes announced on toggle. | |
| VoiceOver: Progress dots | "Step N of M" announced. Individual dots not focusable. | |
| VoiceOver: Back navigation | "Back" button has meaningful label. | |
| Dynamic Type: Selection cards | Cards expand vertically at AXXXLarge. Title and description do not clip. | |
| Dynamic Type: CTA button | TAPrimaryButton label does not clip at AXXXLarge. | |
| Dynamic Type: Progress dots | Dots remain visible and correctly positioned at all sizes. | |
| Contrast: Selection card text | Title and description meet 4.5:1 on surface background. | |
| Contrast: Progress dots | Current/completed/future dots distinguishable at 3:1. | |
| Reduce Motion: Screen transitions | No slide animations between onboarding steps when Reduce Motion is on. | |

### Today Screen (F-ALG-1)

| Check | Details | Pass/Fail |
|-------|---------|-----------|
| VoiceOver: Greeting | Greeting text and any subtitle read correctly. | |
| VoiceOver: Streak badge | "N day streak" announced. Flame icon not separately focused. | |
| VoiceOver: Smart badge | "Designed for You" announced. Not announced on premium tier or basic+ free sessions. | |
| VoiceOver: Routine card | Card info reads "routineType, duration, N exercises". CTA and card body are separate focus targets. | |
| VoiceOver: Thumbnail strip | "N exercise thumbnails" group label. Individual thumbnails not separately focused (unless interactive). | |
| VoiceOver: Tab bar | Each tab announces name + selected state. | |
| Dynamic Type: Routine card | Block rows (name + duration) wrap or truncate gracefully at AXXXLarge. Routine type heading wraps. | |
| Dynamic Type: Tab bar labels | Labels do not overlap icons at AXXXLarge. | |
| Contrast: onSurface text | Secondary text on surface card meets 4.5:1. | |
| Contrast: Smart badge | Teal text on 12% teal background meets 4.5:1. | |
| Reduce Motion: Smart badge | Appears instantly, no fade-in. | |

### Active Session (F-PLY-1 through F-PLY-4)

| Check | Details | Pass/Fail |
|-------|---------|-----------|
| VoiceOver: Exercise name | "Exercise N of M, [name]" announced on every transition. | |
| VoiceOver: Timer | Human-readable time ("45 seconds remaining"), `.updatesFrequently` trait. Not announced every second. | |
| VoiceOver: Rest period | "Rest, N seconds" on start. "Next exercise, [name]" on end. | |
| VoiceOver: Pause/resume | State change announced. Timer stops updating during pause. | |
| VoiceOver: Session complete | `.screenChanged` notification. Summary read aloud. | |
| VoiceOver: Exercise animation | Animation view not separately focused with empty label. | |
| Dynamic Type: Exercise name | Name wraps at large sizes. Does not overlap timer. | |
| Dynamic Type: Controls | Pause, skip, previous buttons meet 44x44pt minimum. | |
| Contrast: Timer text | Timer text meets 4.5:1 on session background. | |
| Reduce Motion: Exercise animation | Static thumbnail displayed instead of looping animation. | |
| Reduce Motion: Exercise transition | Instant cut between exercises, no slide animation. | |
| Switch Control: All controls reachable | Pause, skip, previous, and stop all appear in scan cycle. | |

### Library (F-LIB-1, F-LIB-2)

| Check | Details | Pass/Fail |
|-------|---------|-----------|
| VoiceOver: Exercise list item | "[Exercise name], [muscle group], [discipline]" announced. Thumbnail not separately focused with empty label. | |
| VoiceOver: Filter/search | Filter chips announce selected state. Search field has "Search exercises" placeholder as label. | |
| VoiceOver: Exercise detail | All sections (description, muscles targeted, animation) announced in order. | |
| Dynamic Type: List items | Name and metadata wrap. Thumbnail size remains fixed (does not scale). | |
| Dynamic Type: Filter chips | TAChipGroup chips remain >= 44pt height. Labels do not clip. | |
| Contrast: Metadata text | Secondary metadata text meets 4.5:1. | |
| Reduce Motion: Animation preview | Static thumbnail shown on exercise detail when Reduce Motion is on. | |

### Progress (F-TRK-1)

| Check | Details | Pass/Fail |
|-------|---------|-----------|
| VoiceOver: Stats/charts | Numerical stats have labels ("12 workouts this month", not just "12"). Charts have summary labels. | |
| VoiceOver: History list | Each history entry announces date, routine type, and duration. | |
| Dynamic Type: Stats | Numbers and labels scale. Layout does not break. | |
| Contrast: Chart elements | Data points, lines, and axes meet 3:1 against background. | |

### Settings (F-PRO-1 through F-PRO-5)

| Check | Details | Pass/Fail |
|-------|---------|-----------|
| VoiceOver: Row items | Each setting row announces label + current value (e.g., "Notifications, On"). | |
| VoiceOver: Destructive actions | "Delete All Data" has a clear label. Confirmation alert is fully accessible. | |
| VoiceOver: Subscription management | Current plan, expiry, and upgrade/manage buttons all announced. | |
| Dynamic Type: Row items | Labels and values wrap. Row height grows to accommodate text. | |
| Dynamic Type: Legal text | Privacy policy and ToS text scales and is scrollable. | |
| Contrast: Row separators | Dividers meet 3:1 against background. | |

---

## the shared UI library Component Accessibility Compliance

### Per-Component Verification
When a new TA component is delivered or updated, verify these properties before marking the component as accessibility-compliant:

| Component | Required Traits | Required Label | Required Hint | Required State |
|-----------|----------------|---------------|---------------|----------------|
| TAPrimaryButton | `.isButton` (enabled), traits removed (disabled) | Button title text | None required | Disabled state announced as "dimmed" |
| TAProgressDots | `.updatesFrequently` | "Step N of M" | None required | Updates on step change |
| TASelectionCard | `.isButton`, `.isSelected` | "[Title], [Description]" | "Double tap to select/deselect" | Selected/not selected announced |
| TASelectionRow | `.isButton`, `.isSelected` | "[Title], [Subtitle]" | None required | Selected/not selected announced |
| TAChipGroup | Each chip: `.isButton`, `.isSelected` | Chip option text | None required | Selected/not selected per chip |
| TASmartBadge | `.isStaticText` | Badge text ("Designed for You") | None required | N/A |
| TAStreakBadge | None (children ignored) | "N day streak" | None required | Renders nothing when 0 |
| TAThumbnailStrip | None (children ignored) | "N exercise thumbnails" | None required | N/A |
| TARoutineCard | Info section: `.combine` children | "routineType, duration, N exercises" | None required | CTA handled by TAPrimaryButton |

### What to Flag
If any TA component fails the checks above:
1. File a `needs-update` request in `knowledge-base/ui-component-requests.md` with the specific accessibility gap.
2. Set priority to HIGH — accessibility is not a "nice to have."
3. In the "What Changed" field, describe exactly what is missing (e.g., "TASelectionCard missing `.isSelected` trait — VoiceOver does not announce selection state").

### Custom UI Bypass Detection
During any screen review, check whether the Developer used custom implementations instead of available TA components:
- Custom button instead of TAPrimaryButton — flag.
- Custom card instead of TASelectionCard/TARoutineCard — flag.
- Custom dot indicator instead of TAProgressDots — flag.
- Hardcoded colors/fonts instead of TAColor/TAFont tokens — flag.

Custom UI that bypasses an available TA component is a defect. Custom UI for which no TA component exists and no `needs-component` request has been filed is a process gap — flag to PM and the UI/UX agent.

---

## Testing Tools Summary

| Tool | Use For | When |
|------|---------|------|
| VoiceOver (device) | Full navigation and announcement testing | Every screen, every release |
| Xcode Accessibility Inspector | Element inspection, contrast audit, font size override | Development and QA screen reviews |
| Colour Contrast Analyser | Offline contrast ratio verification for token pairs | During design review and when tokens change |
| Simulator Accessibility settings | Dynamic Type, Reduce Motion, Switch Control | Fast iteration during development |
| Physical device | Authoritative VoiceOver, haptics, real-world performance | Before every release |

---

## Filing Accessibility Bugs
Use the standard bug report template from `bug-reporting.md` with these additions:
- **Category**: Accessibility
- **Subcategory**: VoiceOver / Dynamic Type / Contrast / Motion / Switch Control / Alternative Input
- **Assistive technology version**: VoiceOver version or iOS version (VoiceOver is tied to iOS)
- **Reproduction with AT enabled**: Step-by-step with the assistive technology active, not just visual steps
- **Impact**: Describe what a user relying on this assistive technology cannot do (e.g., "VoiceOver user cannot start a workout because the CTA button has no label")
- **Severity**: Accessibility bugs that block an entire flow for AT users are Critical. Missing labels on non-blocking elements are Medium. Cosmetic contrast issues on decorative elements are Low.
