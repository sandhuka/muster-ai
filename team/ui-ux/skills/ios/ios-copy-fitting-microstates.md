# iOS Copy Fitting & Microstates

## Purpose
Define how the UI/UX agent designs layouts when final copy hasn't arrived from the Content agent, handles variable-length strings that change at runtime, and specifies the dozens of small UI states (microstates) that collectively determine whether an app feels polished or rough. Apple-quality apps nail every 2-word label, every transient status message, and every edge-case banner — this skill ensures the UI/UX agent designs for all of them. Read this skill when fitting copy into layouts, designing status/state indicators, writing placeholder copy, or preparing copy requirements for the Content agent. See the `ios-screen-specification` skill for the copy table format within screen specs. See the `agent-coordination` skill for how to request copy from the Content agent.

## How Design Proceeds Before Final Copy
The UI/UX agent delivers wireframes and specs before the Content agent writes final copy. This is the correct order — layout shapes copy constraints, not the other way around. But the agent must:

1. **Design for real string lengths** — not "Lorem ipsum" but realistic placeholder copy at expected lengths
2. **Define character budgets** — tell the Content agent exactly how much space exists
3. **Specify overflow behavior** — what happens when copy is longer than expected
4. **Test with extremes** — verify the layout works with shortest possible and longest plausible strings

## Copy-Fitting Rules for iOS

### Character Budget Planning
Every text element in a wireframe needs a character budget:

| Element Type | Typical Budget | Rationale |
|-------------|---------------|-----------|
| Navigation title | 12-18 chars | Large title mode allows more; inline is tighter. System truncates with ellipsis. |
| Button label | 8-20 chars | Must fit single line. Shorter is better — Apple uses 1-2 word buttons. |
| Card title | 20-35 chars | 1 line preferred, 2 lines maximum |
| Body text | No hard limit | Flows naturally in scroll view. Limit by line count instead (3-5 lines). |
| Tab label | 6-10 chars | Single word preferred. Apple: "Today", "Library", "Search" |
| Section header | 15-25 chars | Must fit on one line with potential accessory (see-all link, count badge) |
| Banner/toast | 40-60 chars | Must be readable in 2-3 seconds. One sentence. |
| Empty state message | 50-80 chars | 1-2 short sentences. Not a paragraph. |
| Error message | 40-70 chars | Problem + action in one breath |
| Rationale string | 50-80 chars | Algorithm explanation — must feel like a coach, not a tooltip |

### Truncation Priority
When text exceeds its budget, truncation follows this priority (truncate lowest priority first):

1. **Never truncate**: Button labels, tab labels, error actions ("Retry", "Go Back")
2. **Truncate with ellipsis (last resort)**: Card titles, exercise names, navigation titles
3. **Wrap to next line**: Body text, empty state messages, rationale strings
4. **Collapse behind tap**: Detailed explanations, full rationale, metadata

Rule: if an element is truncating frequently, the budget is wrong — increase the space or simplify the content, don't just clip.

### iOS Truncation Conventions
- `.lineLimit(1)` + `.truncationMode(.tail)` — default for titles, labels
- `.lineLimit(2)` + `.truncationMode(.tail)` — for card titles, exercise names that might be long
- No line limit — for body text in scroll views
- Never truncate mid-word in a way that creates an unintended meaning
- For numbers: never truncate. If "1,247 calories" doesn't fit, show "1.2K cal" — transform, don't clip.

## Variable-Length Content Handling
Runtime content (exercise names, algorithm rationale, user-generated text) varies in length. Every layout must be tested against three string lengths:

### String Test Matrix
| Element | Short Test | Medium Test | Long Test (Worst Case) |
|---------|-----------|-------------|----------------------|
| Exercise name | "Plank" (5) | "Bodyweight Squat" (16) | "Single-Leg Romanian Deadlift" (29) |
| Routine title | "Today" (5) | "Morning Strength" (16) | "Upper Body Recovery Focus" (26) |
| Rationale | "Rest day." (9) | "Upper body focus today." (23) | "Your legs are recovering from Tuesday's session — upper body and core today." (73) |
| Goal label | "Strength" (8) | "Stay flexible" (14) | "Build functional strength" (26) |
| Discipline | "Yoga" (4) | "Stretching" (10) | "Strength Training" (17) |
| CTA button | "Start" (5) | "Start Session" (13) | "Start Today's Routine" (21) |
| Error message | "Try again" (9) | "Couldn't load routine." (22) | "We couldn't generate your routine. Check your connection and try again." (70) |

Include these test strings in the screen spec's copy table. The Developer agent uses them to verify layout resilience.

### Layout Resilience Rules
- Buttons: fixed padding, text centered. Button width grows with text (up to full-width, then text wraps to 2 lines as last resort).
- Cards: fixed width, text wraps. Height is flexible. Never clip content in a card.
- Navigation titles: system handles truncation. Test with long title to ensure it collapses to inline correctly.
- Tags/chips: truncate with ellipsis if > 15 chars. Show full text in tooltip or detail view.

## Microstate Inventory
Microstates are transient UI states that last seconds but define the app's perceived quality. Every one needs designed copy and visual treatment.

### Sync & Data States
| Microstate | Visual | Copy | Duration |
|-----------|--------|------|----------|
| **Syncing** | Subtle spinner near data (not full-screen) | "Syncing..." | Until complete |
| **Synced** | Brief checkmark animation | "Up to date" or no text (just checkmark) | 1.5s then fade |
| **Sync failed** | Warning icon, non-blocking | "Couldn't sync. Will retry." | Persistent until resolved |
| **Offline** | Subtle offline indicator in nav area | "Offline" | Persistent |
| **Saving** | Inline spinner or progress | "Saving..." | Until complete |
| **Saved** | Brief checkmark | "Saved" | 1s then fade |

### Session States
| Microstate | Visual | Copy | Duration |
|-----------|--------|------|----------|
| **Paused** | Dim overlay + pause icon | "Paused" | Until resume |
| **Resuming** | Brief countdown or fade-in | "Resuming..." or 3-2-1 countdown | 1-3s |
| **Session saved** | Success indicator | "Session saved" | 2s then transition to summary |
| **Timer extended** | Timer resets with new value | "+15s" toast | 1s |
| **Exercise skipped** | Card slides away | "Skipped [name]" + Undo link | 3s |
| **Rest started** | Background shift + timer | "Rest — 30s" | Until timer ends |

### Account & Premium States
| Microstate | Visual | Copy | Duration |
|-----------|--------|------|----------|
| **Premium locked** | Lock icon or premium badge | "Premium feature" — not "Upgrade now!" | Persistent on gated element |
| **Upgrade processing** | Spinner | "Activating your subscription..." | Until App Store confirms |
| **Upgrade complete** | Success animation | "Welcome to Premium!" | 2s then refresh to premium state |
| **Subscription expired** | Subtle downgrade notice | "Your premium access ended on [date]" | One-time notice, then app shows free state |
| **Restoring purchase** | Spinner | "Restoring..." | Until complete |

### Plan & Algorithm States
| Microstate | Visual | Copy | Duration |
|-----------|--------|------|----------|
| **Generating routine** | Skeleton or custom animation | "Building your routine..." | 1-3s |
| **Routine ready** | Content fades in | No text — routine just appears | Instant |
| **Plan updated** | Subtle refresh indicator | "Plan updated for this week" | Toast, 2s |
| **Algorithm adjusting** | Inline note | "Adjusting based on your last session" | Until routine generates |
| **No routine available** | Empty state | "Couldn't build a routine. [Reason]. Try again?" | Persistent until resolved |

### General Microstates
| Microstate | Visual | Copy | Duration |
|-----------|--------|------|----------|
| **Loading (short)** | Skeleton | None — skeleton is self-explanatory | < 2s |
| **Loading (long)** | Skeleton + text | "Still loading..." (appears after 3s) | Until complete |
| **Network error** | Error card | "Can't connect. Check your internet and try again." + Retry button | Persistent |
| **Empty (first time)** | Illustration + message | Welcoming: "Your session history will appear here" | Persistent until data exists |
| **Empty (returning)** | Message only | Neutral: "No sessions this week yet" | Persistent until data exists |
| **Copied to clipboard** | Brief toast | "Copied" | 1s |
| **Settings changed** | Inline confirmation | "Updated" or just visual state change | 0.5s |

## Tone-Safe UI Placeholders
When the Content agent hasn't provided final copy, the UI/UX agent must use placeholder text that:

1. **Is the right length** — match the expected character budget, not filler
2. **Is tonally neutral** — don't attempt the product's brand voice. Use plain descriptive text.
3. **Is clearly marked** — wrap in brackets: `[Your routine is ready — 20 min of strength and stretching]`
4. **Communicates the intent** — the placeholder should tell the Content agent what the copy needs to accomplish

### Placeholder Format
```
[PLACEHOLDER: Purpose — Max X chars]
"Suggested direction in plain language"
```

Example:
```
[PLACEHOLDER: Empty state for workout history — Max 80 chars]
"No sessions recorded yet. Complete your first routine to start tracking."
```

The Content agent replaces these with final copy in brand voice. The brackets ensure no one mistakes placeholder for final.

## Action Label Decision Rules
Button and action labels are the most constrained copy in the app. Apply these rules:

### Apple's Button Label Patterns
| Pattern | Example | When |
|---------|---------|------|
| **Verb** | "Start", "Skip", "Retry" | Primary actions — clear, immediate |
| **Verb + Object** | "Start Session", "Skip Exercise" | When the verb alone is ambiguous |
| **Noun** | "Done", "Cancel", "Settings" | Dismissal and navigation |

### Rules
- 1-2 words for primary buttons. 3 words maximum.
- Use the verb that describes what WILL happen, not what the user IS doing: "Save" not "Saving", "Start" not "Starting"
- Destructive actions: name the destructive thing. "Delete Account" not "Continue" or "Confirm"
- Cancel vs. Close vs. Done: "Cancel" abandons changes. "Close" or "Done" preserves them. Use the right one.
- Avoid "Submit", "OK", "Click Here", "Learn More" (web conventions, not iOS)
- Apple standard: "Get Started" for onboarding CTA, "Continue" for multi-step flows, "Done" for completing a task

### Product-Specific Labels
Follow brand terminology from `knowledge-base/brand-guidelines.md` for consistent labeling across the app. Define a label table like the one below for your product:

| Action | Label | NOT |
|--------|-------|-----|
| Begin core experience | "[Product verb] [noun]" | Vague or generic verbs ("Begin", "Let's Go!", "Go") |
| Next onboarding step | "Continue" | "Next", "->", "Proceed" |
| Complete onboarding | "[Action-oriented CTA]" | "Done", "Finish", "Submit" |
| Pause session | "Pause" | "Stop", "Hold" |
| End session early | "End [Session noun]" | "Quit", "Exit", "Stop" |
| Upgrade to premium | "Try Premium" or "See Plans" | "Upgrade Now!", "Go Premium!", "Unlock" |
| Dismiss/close | "Done" or "Close" | "OK", "Got It", "Dismiss" |
| Retry after error | "Try Again" | "Retry", "Reload", "Refresh" |

## Banner and Explanation Restraint
Premium banners, algorithm rationale, and educational tooltips can easily overwhelm the primary task. Rules:

### The One-Banner Rule
- Maximum 1 banner per screen, ever. If premium banner and algorithm rationale both want banner space, rationale wins (it's content, not marketing).
- Banner height: maximum 60pt. If it needs more space, it belongs in a sheet or section, not a banner.

### Rationale Restraint
- Algorithm rationale: 1 line (50-80 chars) visible by default. Expanded detail on tap.
- Never show rationale that the user didn't ask for in a way that interrupts the primary task
- Rationale should feel like a footnote, not a headline

### Educational Text Restraint
- First-time hints: maximum 1 per screen, shown once, dismissible
- Never block the primary action with education. Show the hint beside or below the action, not in front of it.
- If the feature needs explanation to be usable, the design is wrong — simplify before explaining.

## Localization and Future-Proofing
Even if launching in English only, layouts should survive future localization:

### Expansion Safety
- German and French text is typically 30-40% longer than English
- Japanese and Chinese text is typically 10-20% shorter but taller
- Design rule: if the layout breaks with 40% more text, it's too tight
- Test: take each button and title, add 40% characters, verify no overlap or clipping

### RTL Awareness
- Arabic and Hebrew read right-to-left
- SwiftUI handles most RTL automatically if you use `.leading`/`.trailing` instead of `.left`/`.right`
- Note in specs: use semantic alignment (`.leading`/`.trailing`), never `.left`/`.right`

### Strings to Avoid Hardcoding
- Date formats: use `DateFormatter` with locale
- Number formats: use `NumberFormatter` (commas vs periods for decimals)
- Pluralization: "1 exercise" vs "3 exercises" — use `String.LocalizedStringResource` with plural rules

## Handoff Requirements to Content Agent
When requesting copy from the Content agent, include:

```markdown
### Copy Request: [Screen / Element]
| Slot | Purpose | Max Chars | Lines | Tone Note | Placeholder |
|------|---------|-----------|-------|-----------|-------------|
| hero_title | Main screen heading | 25 | 1 | Confident, brief | "[Your Routine]" |
| body_text | Supporting explanation | 80 | 2-3 | Informative, warm | "[A strength and stretching routine based on your recovery]" |
| cta_button | Primary action | 18 | 1 | Action verb + object | "[Start Session]" |
| empty_state | No data message | 80 | 2 | Encouraging, not pushy | "[No sessions yet. Complete your first routine.]" |
| error_message | Network failure | 70 | 2 | Calm, solution-oriented | "[Couldn't load routine. Check connection and try again.]" |

### Context for Content Agent
- Screen: [which screen and flow]
- User state: [first-time / returning / free / premium]
- Emotional moment: [excited / focused / frustrated / accomplished]
- Adjacent elements: [what's above and below this text — affects tone continuity]
```

This format ensures the Content agent has constraints without being micromanaged on voice.

## Output Format
When specifying copy slots in a screen spec:

```markdown
## Copy Fitting Spec: [Screen Name]

### String Slots
| Slot ID | Element | Budget (chars) | Lines | Overflow | Test: Short | Test: Medium | Test: Long | Content Status |
|---------|---------|---------------|-------|----------|-------------|-------------|------------|---------------|
| s01 | Screen title | 18 | 1 | Truncate tail | "Today" | "Your Routine" | "Today's Personalized Routine" | PLACEHOLDER |
| s02 | CTA button | 18 | 1 | Never truncate — revise copy | "Start" | "Start Session" | "Start Today's Routine" | PLACEHOLDER |
| ... | ... | ... | ... | ... | ... | ... | ... | ... |

### Microstate Spec
| State | Visual Treatment | Copy | Duration | Triggered By |
|-------|-----------------|------|----------|-------------|
| Syncing | Spinner, inline | "Syncing..." | Until done | Data change |
| ... | ... | ... | ... | ... |

### Content Agent Request Status
- [ ] Copy request filed: [link to agent-requests.md entry]
- [ ] Character budgets communicated
- [ ] Final copy received
- [ ] Final copy tested against layout (short/medium/long)
```
