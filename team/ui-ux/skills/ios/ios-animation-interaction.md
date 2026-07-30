# iOS Animation & Interaction Specification

## Purpose
Define how to specify animations, transitions, haptics, and gesture interactions — following Apple's motion design philosophy. Apple uses motion to communicate, not decorate. Every animation must answer: "What relationship or state change am I helping the user understand?" See the `ios-hig-reference` skill for the broader platform conventions. See the `accessibility` skill for Reduce Motion requirements.

## Apple's Motion Principles

### Motion Communicates
- **Continuity**: An element that moves from Screen A to Screen B tells the user "this is the same thing." Use matched geometry transitions.
- **Causality**: Motion should follow the user's touch — the thing I tapped grows, the thing I swiped slides away.
- **Feedback**: Subtle motion confirms actions — a button depresses, a toggle snaps, a card settles.

### Apple's Motion Personality
- **Fast in, ease out**: Apple animations feel responsive because they start fast and decelerate naturally (spring-based, not linear)
- **Never bouncy**: iOS is not a game. Springs should have low bounce (0.0–0.3 dampingFraction). Prefer `.snappy` or `.smooth` over `.bouncy`
- **Purposeful duration**: 0.2–0.35s for most transitions. Under 0.2s feels abrupt. Over 0.5s feels sluggish. Apple's default sheet presentation is ~0.3s
- **Respect momentum**: Scrolling, swiping, and dragging should carry inertia. Never stop abruptly.

## Animation Specification Format
When specifying an animation in a screen spec or wireframe, use this format:

```
Animation: [descriptive name]
Trigger: [user action or state change]
Property: [what changes — position, opacity, scale, color, etc.]
From → To: [start value → end value]
Timing: .spring(duration: 0.3, bounce: 0.15) | .easeOut(duration: 0.25) | .default
Reduce Motion: [alternative — typically crossfade at 0.2s]
Notes: [implementation hints]
```

### Example
```
Animation: Exercise Card Expand
Trigger: Tap exercise card in Library
Property: Frame, corner radius, position
From → To: Card size/position → fullscreen detail
Timing: .spring(duration: 0.35, bounce: 0.1)
Reduce Motion: Crossfade to detail view, 0.2s
Notes: Use matchedGeometryEffect — card image is the shared element
```

## Transition Types

### Navigation Transitions
| Transition | When to Use | Implementation |
|-----------|-------------|----------------|
| Push (slide left) | Drilling into detail from a list | Default NavigationStack behavior |
| Pop (slide right) | Going back | Back button or swipe from left edge |
| Sheet (slide up) | Focused task without leaving context | `.sheet()` with detents |
| Full screen cover (slide up) | Immersive flow (workout, onboarding) | `.fullScreenCover()` |
| Crossfade | Swapping content in place (tab switch, segment change) | `.animation(.default)` on content |
| Zoom | Opening from a specific element | `.navigationTransition(.zoom)` iOS 18, or matchedGeometry |
| None | Instant state change (toggle, inline edit) | No explicit animation needed |

### Content Transitions
| Content Change | Animation | Duration |
|---------------|-----------|----------|
| Skeleton → loaded content | Crossfade | 0.2s |
| Empty → first item added | Scale up from center + fade in | 0.3s spring |
| Item removed from list | Slide out + collapse gap | 0.25s easeOut |
| Counter increment (reps, timer) | Vertical slide (old number up, new down) | 0.15s |
| Progress bar fill | Width animation | 0.3s easeOut |
| Card reorder | Move with spring | 0.35s spring |

## Haptic Patterns

### Haptic Types (UIFeedbackGenerator)
| Type | Intensity | When to Use |
|------|-----------|---------------------|
| **Impact — light** | Subtle tap | Scrolling past section headers, hovering over selectable items |
| **Impact — medium** | Noticeable tap | Completing an exercise, selecting a discipline in onboarding |
| **Impact — heavy** | Strong thud | Completing entire workout, hitting a milestone |
| **Selection changed** | Tick | Scrolling through picker values, switching segments |
| **Notification — success** | Satisfying double-tap | Workout saved, streak achieved, subscription activated |
| **Notification — warning** | Attention | Rest timer approaching 0, about to skip last exercise |
| **Notification — error** | Harsh buzz | Network error, invalid input, failed save |

### Haptic Rules
- Pair haptics with visual feedback — never haptic-only
- Don't over-use: if everything buzzes, nothing stands out
- Disable haptics when the device is in Silent mode (system handles this)
- Active workout session: use haptics for exercise transitions (medium impact) and rest timer countdown (selection tick at 3, 2, 1)

## Gesture Specification Format
When a screen uses custom gestures (beyond standard scroll/tap):

```
Gesture: [name]
Type: [tap / long press / swipe / drag / pinch / rotation]
Target: [which element]
Direction/Threshold: [e.g., swipe right > 50pt]
Action: [what happens]
Visual feedback: [what the user sees during the gesture]
Haptic: [feedback type, if any]
Cancel behavior: [what happens if gesture is abandoned mid-way]
Accessibility alternative: [button/menu fallback]
```

### Example
```
Gesture: Skip Exercise
Type: Swipe left
Target: Active exercise card during workout
Direction/Threshold: Swipe left > 100pt
Action: Skip to next exercise (or rest period)
Visual feedback: Card slides left revealing "Skip" label, card opacity decreases
Haptic: Impact — medium on threshold cross
Cancel behavior: Card springs back to center if released before threshold
Accessibility alternative: "Skip" button below exercise card
```

## Product-Specific Animation Patterns
Define animation patterns specific to your product's core experience. Common patterns include:

### Media/Content Playback
- Looping or streaming media as hero content during the core experience
- Loading: show static thumbnail immediately, crossfade to media when loaded (never show spinner over the content area)
- Transition between items: current content fades out (0.2s), brief pause (0.3s), next thumbnail appears, crossfades to content
- Pause state: content freezes on current frame, slight dim overlay with pause icon

### Session Timer
- Countdown numbers: vertical slide transition (`.contentTransition(.numericText())`)
- Last 5 seconds: number scales up slightly (1.0 to 1.1) with each tick + selection haptic
- Timer complete: number pulses once (scale 1.0 to 1.2 to 1.0) + success notification haptic

### Onboarding Transitions
- Between onboarding steps: push transition (standard NavigationStack)
- Selection feedback (tapping a discipline/goal card): scale 1.0 → 0.95 → 1.0 with medium impact haptic, selected state appears with checkmark fade-in
- Progress indicator: smooth width animation matching current step

### Tab Switching
- No animation between tabs (instant switch — Apple convention)
- Content within tabs can have entrance animations on first appearance only (fade in, 0.2s)

## Reduce Motion Compliance
For every animation specified, provide a Reduce Motion alternative:
- Replace slides/scales/bounces with crossfades (0.2s)
- Replace spring animations with linear or easeOut
- Disable looping exercise animations — show static thumbnail (key pose frame)
- Keep haptic feedback (it's not motion)
- Timer countdown: plain number change, no scaling effect
