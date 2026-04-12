# User Flow & State Mapping

## Purpose
Define how to document end-to-end user journeys, screen state machines, and branching logic. A wireframe shows what one screen looks like. A user flow shows how screens connect, what decisions the user makes, and what the system does in response. See `team/ui-ux/skills/ios-wireframe-methodology.md` for individual screen wireframe format. See `team/ui-ux/skills/ios-hig-reference.md` for navigation patterns that constrain how screens connect.

## Apple's Flow Philosophy
Apple never makes users think about where they are in an app. Great flows have:
- **Obvious next step**: At every screen, one action is clearly primary
- **Easy retreat**: The user can always go back without losing work
- **Minimal depth**: 3 taps to any core action maximum. If it's deeper, reconsider the information architecture
- **Memory-free navigation**: Users shouldn't need to remember what's on other tabs or behind other buttons — surfacing and cross-links handle this

## User Flow Diagram Format
Use text-based flow diagrams with clear notation:

```
[Screen Name]
    │
    ├── action: "Tap Start Session"
    │   └── transition: fullScreenCover
    │       └── [Active Session Screen]
    │           ├── action: "Complete all exercises"
    │           │   └── [Session Summary]
    │           │       └── action: "Done" → dismiss → [Today Screen] (updated)
    │           └── action: "Tap X / Quit"
    │               └── confirm: "End session early?"
    │                   ├── "End" → [Today Screen] (partial session saved)
    │                   └── "Cancel" → [Active Session Screen]
    │
    ├── action: "Tap exercise card"
    │   └── transition: push
    │       └── [Exercise Detail]
    │
    └── action: "Switch to Library tab"
        └── transition: tab switch
            └── [Library Root]
```

### Notation Key
- `[Screen Name]` — A distinct screen/view
- `action:` — User-initiated action (tap, swipe, system event)
- `transition:` — How the screen change happens (push, sheet, fullScreenCover, tab switch, replace)
- `confirm:` — System asks for confirmation before proceeding
- `condition:` — System checks a state (logged in? premium? first time?)
- `→` — Direct result (no intermediate screen)
- `(note)` — Contextual annotation

## Branching Logic: Free vs Premium
Many flows branch based on subscription tier. Document these clearly:

```
[Plan Tab Root]
    │
    ├── condition: isPremium?
    │   ├── YES → [Full Weekly Plan]
    │   │   └── (shows smart schedule with rationale chips)
    │   └── NO → [Plan Upgrade View]
    │       └── (sample plan preview + upgrade banner)
    │           └── action: "Unlock Smart Planning"
    │               └── transition: sheet(.medium)
    │                   └── [Subscription Sheet (F-PRO-3)]
```

## Screen State Machine
Every screen has multiple states. Document them as a state machine:

```
Screen: Today Screen
States:
┌──────────────┐
│  loading     │──── data loaded ────→ ┌──────────────┐
└──────────────┘                       │  content     │
                                       └──────┬───────┘
┌──────────────┐                              │
│  empty       │◄── no routine generated ─────┘
└──────────────┘         │
                    routine generated
                         │
                         ▼
                  ┌──────────────┐
                  │  content     │
                  └──────────────┘

┌──────────────┐
│  error       │◄── network/data failure from any state
└──────────────┘
       │
  retry tap → loading
```

### Required States Per Screen
Every screen must define these core states: **Loading**, **Content**, **Empty**, **Error**, **Partial** (some data loaded, some pending).

Additional conditional states when applicable: **First-time**, **Free-tier**, **Premium**, **Offline**.

See `team/ui-ux/skills/ios-wireframe-methodology.md` Wireframe Completeness Checklist for the full list of states and edge cases every wireframe must cover. See `team/ui-ux/skills/ios-copy-fitting-microstates.md` for transient microstate design (syncing, saving, generating, etc.).

## User Journey Template
For documenting a complete user journey (not just screen-to-screen flow):

```markdown
## Journey: [Name] (e.g., "First Session Completion")

**Persona**: [Who — e.g., "Free-tier new user, first day"]
**Entry point**: [How they arrive — e.g., "Onboarding complete, auto-transition to Today"]
**Goal**: [What they want to achieve — e.g., "Complete their first session"]
**Success metric**: [How we know it worked — e.g., "Session saved, summary shown"]

### Steps
1. **Today screen** — User sees their first generated routine
   - Emotional state: curious but uncertain
   - Key element: prominent "Start Session" button, routine preview shows what's ahead
   - Risk: overwhelm if too much info. Keep it simple.

2. **Active session** — User performs exercises
   - Emotional state: engaged, focused
   - Key element: looping animation, clear rep counter, progress indicator
   - Risk: confusion about what to do next. Auto-advance with clear transitions.

3. **Session complete** — Summary and encouragement
   - Emotional state: accomplished
   - Key element: completion celebration, streak update, "what's next" preview
   - Risk: dead end. Always show what comes next.

### Edge Cases
- User quits mid-workout → save partial session, resume option next time?
- User's first routine has an exercise they can't do → how to skip/swap?
- Network error during session (premium) → local fallback, sync later
```

## Flow Completeness Checklist
Before handing off a flow:

- [ ] Every screen has all required states documented (loading, content, empty, error)
- [ ] All decision branches are covered (free/premium, first-time/returning, online/offline)
- [ ] Every dead end has an escape (back button, close button, home action)
- [ ] Destructive actions have confirmation
- [ ] Error states have recovery actions (retry, go back, contact support)
- [ ] Transition types specified for every screen change
- [ ] No orphan screens (every screen is reachable and has an exit)
- [ ] Flow respects iOS navigation conventions (no custom "back" icons, no breaking the stack)

## Cross-Flow References
When one flow connects to another, note it clearly:

```
action: "Tap Upgrade" → [Subscription Flow] (see flow doc: subscription-upgrade.md)
```

Don't duplicate an entire sub-flow — reference it. This prevents divergence when sub-flows are updated.
