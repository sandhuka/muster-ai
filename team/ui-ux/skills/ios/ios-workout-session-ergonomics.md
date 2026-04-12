# iOS Workout Session Ergonomics

## Purpose
Define the ergonomic design methodology for any screen where the user is physically active — exercising, resting between sets, or transitioning between movements. These screens operate under fundamentally different constraints than browse, form, or dashboard screens: the user is moving, sweaty, distracted, and only glancing at the device for fractions of a second. Every design decision must be validated against physical exertion conditions, not calm sitting-at-desk conditions. Read this skill when designing Active Workout Session (F-PLY-1 through F-PLY-4), rest periods, timers, and any screen shown during physical activity. See `team/ui-ux/skills/ios-animation-interaction.md` for animation/haptic specs that complement these ergonomic patterns. See `team/ui-ux/skills/ios-content-hierarchy.md` for general hierarchy principles (this skill overrides density targets for session screens).

## Session Design Objective
Workout-session UX must be: **glanceable, controllable, interruption-tolerant, and safe under physical exertion.**

- **Glanceable**: The user gets the information they need in under 1 second of looking at the screen.
- **Controllable**: Primary actions (pause, skip, complete) are hittable with a sweaty thumb while breathing hard.
- **Interruption-tolerant**: Phone calls, notifications, AirPods disconnecting, backgrounding — the session survives all of it gracefully.
- **Safe**: No accidental tap can end the session or skip an exercise without recovery. The user is making imprecise inputs.

## Ergonomic Constraints of Active Use

### Physical Realities
| Constraint | Impact on Design |
|-----------|-----------------|
| **One-hand grip, often non-dominant** | Controls must be reachable with either thumb. No small targets at screen edges. |
| **Shaky hands** | Tap targets must be larger than standard (60pt minimum, not 44pt). Generous dead zones between destructive and progressive actions. |
| **Sweat on screen** | Swipe gestures are unreliable. Prefer taps over swipes for critical actions. Swipes for non-critical shortcuts only. |
| **Distance from device** | Phone may be on floor, bench, or propped against wall at 2-4 feet distance. Key info (exercise name, timer, rep count) must be readable at arm's length. |
| **Intermittent attention** | User glances at phone between reps or during rest. They will NOT read paragraphs. Maximum 3 pieces of information visible. |
| **Body position changes** | User may be standing, lying down, in plank, inverted. Screen orientation should be locked to portrait during session. |
| **Elevated heart rate** | Cognitive load tolerance drops during exertion. Decision-making is impaired. Minimize choices. |
| **Audio reliance** | Many users rely on audio cues (countdown beeps, voice prompts) more than visual during active exercise. Design visual as complement, not sole channel. |

### Device Scenarios
| Scenario | Design Implication |
|---------|-------------------|
| Phone in hand | Standard touch interaction, but with reduced precision |
| Phone on floor/bench (nearby) | Visual info must be large. Tap targets must be huge. No precision required. |
| Phone propped at distance | Read-only — user can see but not touch. Audio/haptic cues carry the interaction. Auto-advance is essential. |
| Phone on arm band | Screen is tiny and angled. Not a primary scenario for most apps but session should degrade gracefully. |

## Glanceability Hierarchy
During active exercise, these elements must be readable in under 1 second, in this priority order:

| Priority | Element | Min Size | Visibility Rule |
|----------|---------|----------|----------------|
| 1 | **Current exercise name** | Font.title or larger (22pt+) | Always visible, never scrolled off, never obscured by controls |
| 2 | **Rep count OR time remaining** | 48pt+ numerals, high contrast | Centered or near-center, monospacedDigit, updates without layout shift |
| 3 | **What's next** | Font.subheadline (15pt) | Visible below primary content: "Next: Warrior II" or "Rest: 30s" |
| 4 | **Session progress** | Thin progress bar or "3 of 8" | Top edge or subtle position, glanceable but not distracting |

Everything else (form cues, exercise details, modification options) is below the fold or behind a tap.

### Distance Readability
- Exercise name: readable at 3 feet → minimum 22pt bold, high contrast (white on dark or dark on light)
- Timer digits: readable at 4 feet → minimum 48pt, extra bold or black weight
- Test: if you can't read it with your phone on the floor while standing, the text is too small

## Control Sizing and Placement

### Control Map
```
┌─────────────────────────────┐
│                             │
│     [Exercise Animation]    │  ← Hero area: NO controls overlaid
│                             │
│                             │
├─────────────────────────────┤
│   Exercise Name             │
│   ████████ 12 ████████      │  ← Rep/time counter: LARGE
│   Next: Warrior II          │
├─────────────────────────────┤
│                             │
│  ┌─────────────────────┐    │
│  │                     │    │
│  │    ▶ PAUSE / ⏭ SKIP │    │  ← Primary controls: bottom-center
│  │    (60pt+ targets)  │    │     thumb zone, maximum size
│  │                     │    │
│  └─────────────────────┘    │
│                             │
│        ✕ End Session        │  ← Destructive: small, top corner
│                             │     or requires long-press
└─────────────────────────────┘
```

### Control Rules
| Control | Min Target Size | Placement | Protection |
|---------|---------------|-----------|-----------|
| **Pause/Resume** | 60x60pt | Bottom-center (thumb zone) | None — always safe to tap |
| **Skip exercise** | 52x52pt | Bottom area, beside pause | None — skipping is recoverable |
| **Complete rep/set** | 60x60pt or full-width button | Bottom-center | None — safe action |
| **End session** | 44x44pt (standard) | Top-left corner OR long-press only | Requires confirmation dialog |
| **Next exercise (auto-advance off)** | Full-width button, 52pt height | Bottom, replaces rep counter | None — forward progress |

### Spacing Between Controls
- Minimum 24pt gap between Pause and Skip — prevents wrong-button hits with shaky hands
- Minimum 80pt vertical separation between any forward-progress control and End Session
- Never place "Skip" and "End Session" adjacent — the cost of confusing them is too high

## Workout State Model
The session moves through these states. Every state must have a designed screen:

```
                    ┌──────────┐
         start ────→│  Active   │◄──── resume
                    │ Exercise  │
                    └────┬─────┘
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
        ┌──────────┐ ┌────────┐ ┌────────┐
        │   Rest   │ │ Paused │ │  Skip  │
        │  Period  │ │        │ │(next)  │
        └────┬─────┘ └────┬───┘ └───┬────┘
             │            │         │
             ▼            ▼         ▼
        ┌──────────┐    resume   ┌──────────┐
        │  Next    │◄───────────│  Next    │
        │ Exercise │            │ Exercise │
        └────┬─────┘            └──────────┘
             │
        (after last exercise)
             │
             ▼
        ┌──────────┐
        │ Session  │
        │ Complete │
        └──────────┘
```

### State Definitions
| State | What's Shown | Controls Available | Auto-Advance |
|-------|-------------|-------------------|-------------|
| **Active Exercise** | Animation playing, exercise name, rep/time counter | Pause, Skip, End | Yes — after rep count or timer completes |
| **Rest Period** | Countdown timer (large), next exercise preview, motivational: keep minimal | Skip Rest, Extend (+15s), End | Yes — when timer hits 0 |
| **Paused** | Frozen exercise frame, dim overlay, "Paused" label | Resume (prominent), End | No |
| **Transition** | Brief crossfade between exercises (0.3-0.5s) | None — too brief for interaction | Yes — auto into next exercise |
| **Session Complete** | Summary: exercises done, time elapsed, streak update | Done (→ Today), Share | No |
| **Interrupted** | Depends on interruption type (see below) | Resume or End | Auto-resume for brief interruptions |

## Timer and Counter Readability

### Numeral Treatment
- Font: system ultra-light or thin at very large sizes (Apple Watch aesthetic) OR system bold at large sizes. Choose one and be consistent.
- Weight: for a confident, coaching-style brand, use **bold at 48pt+** — confidence over elegance
- Color: highest available contrast. On dark session background: white. On light: near-black.
- Format: `12` (reps) or `0:45` (time). Never `00:00:45`. Minimal formatting.
- Alignment: centered, fixed position. Number width changes must not shift layout (use `.monospacedDigit()`)

### Urgency Escalation (Timers)
| Time Remaining | Visual Treatment | Haptic |
|---------------|-----------------|--------|
| > 10 seconds | Normal size, normal color | None |
| 5-10 seconds | Slight scale increase (1.0 → 1.05) | None |
| 3-5 seconds | Amber/warning color optional, scale 1.05 | Selection tick each second |
| ≤ 3 seconds | Scale 1.1, each number pulses | Impact — light each second |
| 0 | Brief flash/pulse, transition to next state | Impact — medium |

### Rep Counter
- Show current / total: `5 / 12`
- Current rep number is 2x the size of total: **5** / 12
- Each rep completion: number slides up, new number slides in from below (`.contentTransition(.numericText())`)
- Haptic: impact — light on each rep count increment

## Auto-Lock, Backgrounding, and Interruption Handling

### Screen Auto-Lock Prevention
- Session screens must set `UIApplication.shared.isIdleTimerDisabled = true` while workout is active
- Re-enable idle timer when session is paused, completed, or backgrounded for > 5 minutes
- Note this in the screen spec for Developer agent

### Interruption Matrix
| Interruption | Behavior | Resume UX |
|-------------|----------|-----------|
| **Phone call** | Auto-pause session, pause timer | After call: show "Resume Session?" prompt over paused state |
| **Notification banner** | No pause — banner appears briefly over top safe area | No action needed — session continues |
| **Incoming FaceTime/video call** | Auto-pause | Same as phone call |
| **App backgrounded (< 2 min)** | Timer continues in background, session persists | Return: session resumes at current state, timer shows updated count |
| **App backgrounded (2-5 min)** | Auto-pause, timer stops | Return: show "You stepped away. Resume?" with elapsed-away time |
| **App backgrounded (> 5 min)** | Auto-pause, save partial session | Return: show "Resume session? (X exercises remaining)" or "Start fresh?" |
| **Low battery alert** | No pause — system alert appears | No action needed |
| **AirPods disconnect** | No pause — audio switches to speaker | Show brief toast: "Audio switched to speaker" |
| **AirPods reconnect** | Audio routes back automatically | Show brief toast: "Audio connected" |
| **Siri activation** | Auto-pause | Resume after Siri dismisses |
| **App crash** | Save session state to local storage every exercise transition | On relaunch: "Resume your session? (X of Y exercises completed)" |

### Background Timer Accuracy
- Use `UNUserNotificationCenter` for background timer notifications, not just in-app timer
- Spec should note: Developer must use a reliable background timing mechanism, not just `Timer.scheduledTimer`

## Rest Period UX

### Rest Screen Hierarchy
| Priority | Element | Treatment |
|----------|---------|-----------|
| 1 | **Countdown timer** | Largest element on screen, 64pt+ numerals, center |
| 2 | **Next exercise preview** | Below timer: name + static thumbnail of next exercise |
| 3 | **Skip Rest / Extend** | Bottom area: "Skip" (primary, tap to jump to next exercise), "+15s" (secondary) |

### Rest Design Rules
- Rest screen background should differ from active-exercise background (slightly lighter/darker) — the visual shift signals state change
- Timer is the hero. Make it impossible to miss.
- "Skip Rest" is always available — some users don't need rest between stretches or yoga poses
- "+15s" extend button: adds 15 seconds each tap, no upper limit, but subtle (users who need more rest shouldn't feel judged)
- **No motivational quotes, no "Great job!" during rest.** A coaching-style tone should be confident and calm, not cheerleader. Reserve celebration for session completion only.

## Exercise Clarity and Comprehension

### Animation as Primary Instruction
- The looping 3D animation is the primary teaching tool — it shows the movement
- Animation must be large enough to see body position details (muscle engagement, joint angles)
- Minimum animation area: 60% of screen width, fixed-height container with `.fit` content mode at native aspect ratio (6:7 portrait for standing poses, 9:7 landscape for floor poses). Color.surface fills remaining space. No layout shift between exercises

### Supporting Text
| Element | When to Show | Format |
|---------|-------------|--------|
| Exercise name | Always | Large, bold, above or below animation |
| Primary form cue | During first 2 loops of animation | 1 line max: "Keep your back straight" — fades after 2 loops |
| Muscle groups | On tap/swipe-up detail | Tag chips: "Quads, Glutes, Core" |
| Modification option | If available | Small link: "Easier version" → swaps animation |

### Character Persona Context
- The character performing the exercise (Sarah, Candy, Ayan) should be identifiable but not labeled during session — the focus is on the movement, not the character
- Character name appears in Library detail view, not during active session

## Safety and Control Recovery

### Accidental Tap Protection
| Action | Protection Level | Mechanism |
|--------|-----------------|-----------|
| Pause | None — always safe | Single tap |
| Skip exercise | None — recoverable | Single tap (can go back if needed) |
| End session | **High** | Confirmation dialog: "End session? Your progress (X of Y) will be saved." with "End" (destructive red) and "Continue" (default, prominent) |
| Skip rest | None — always safe | Single tap |
| Share (post-session) | None — safe | Single tap |

### Exit Safety Net
- "End Session" confirmation always offers to save partial progress
- If > 50% of exercises completed: "Great session! Save X completed exercises?" — don't make partial completion feel like failure
- If < 50% completed: "End early? You can pick up a new routine later." — no guilt, no judgment

### Undo
- After skipping an exercise: show brief toast "Skipped [exercise name]" with "Undo" action (3 second window)
- After completing a rep: no undo needed (forward progress is always fine)
- After ending workout: no undo — session is saved, user returns to Today. They can start a new session anytime.

## Output Format
When designing session screens, include alongside wireframes:

```markdown
## Session Ergonomics Spec: [Screen/State Name]

### Glanceability Audit
| Element | Size | Distance Readable | 1-Second Readable? |
|---------|------|-------------------|-------------------|
| Exercise name | 22pt bold | 3 ft | Yes |
| Timer | 48pt bold | 4 ft | Yes |
| ... | ... | ... | ... |

### Control Map
| Control | Size | Position | Protection | Haptic |
|---------|------|----------|-----------|--------|
| Pause | 60x60pt | Bottom-center | None | Impact — light |
| ... | ... | ... | ... | ... |

### Interruption Handling
[Reference the standard matrix above, note any screen-specific exceptions]

### Sweat/Precision Notes
[Any screen-specific notes about reduced-precision interaction]
```
