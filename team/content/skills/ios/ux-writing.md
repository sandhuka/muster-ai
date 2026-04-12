# UX Writing

## Purpose
Define the methodology for writing interface copy — every text element the user sees inside the app that isn't marketing or long-form content. Primary collaboration surface with the UI/UX agent. See `team/content/skills/brand-voice.md` for voice application and error state patterns. See `team/content/skills/subscription-copy.md` for subscription state copy and paywall screen methodology. See `knowledge-base/product-spec.md` Section 5I for error and empty state specs.

## UX Copy Hierarchy

Every screen has a hierarchy of text. Write the most important element first, then decide if the others are even necessary.

| Level | Element | Max Length | When to Use |
|-------|---------|-----------|-------------|
| 1 | Headline | 5-8 words | Every screen — communicates what this screen is |
| 2 | Supporting text | 15-25 words | Only when the headline isn't self-explanatory |
| 3 | Action label | 2-4 words | Buttons, CTAs — describes what happens on tap |
| 4 | Helper text | 10-15 words | Input fields, tooltips — prevents errors |
| 5 | Caption/metadata | Varies | Labels, badges, timestamps — informational |

**Rule**: If removing a text element doesn't reduce comprehension, remove it.

## Copy as Design

Words are design elements. They have visual weight, rhythm, and spatial impact — treat them with the same rigor as colors and spacing.

### Character Budgets
Every UI element has a character budget. Exceeding it breaks layouts, especially after localization (30-40% expansion for German/French).

| Element | English Budget | Expansion Budget (i18n) | Notes |
|---------|---------------|------------------------|-------|
| Button label | 20 chars | 28 chars | Must fit one line, no wrapping |
| Tab label | 10 chars | 14 chars | Single word preferred |
| Badge | 18 chars | 25 chars | "Designed for You" = 16 chars |
| Headline | 40 chars | 56 chars | One line on smallest supported device (iPhone SE) |
| Supporting text | 80 chars | 112 chars | Max 2 lines |
| Toast/snackbar | 60 chars | 84 chars | Must be readable in 3-second display |
| Rationale string | 80 chars | 112 chars | One line on most devices |

### Visual Rhythm
- **Pair short with long**: A 4-word headline + 15-word supporting line creates visual contrast. Two equal-length lines feel flat.
- **White space is copy**: Choosing not to write something is a content decision. If the UI communicates through layout alone, don't add words.
- **Alignment with UI elements**: Copy length should complement the visual design — a 3-word button centered under a 6-word headline feels balanced. A 12-word button does not.

### Copy Review as Design Review
When reviewing copy, check it visually in context (not just in a spreadsheet). Copy that reads well in a document can look wrong on screen — too long, too dense, wrong rhythm. Request mockups from UI/UX agent before finalizing any copy for key screens.

## Progressive Reduction

Users need different levels of guidance depending on familiarity. Write copy that adapts.

### First-Use vs. Returning-User Copy

| Surface | First Use | Returning Use |
|---------|-----------|---------------|
| Today screen greeting | "Your first routine is ready. Here's what to expect." | "Your routine is ready." |
| Empty Plan tab | "Your workout history will appear here as you train." | (Shows data — no empty state) |
| Pre-workout summary | Full block breakdown with explanation | Block breakdown only (user knows the format) |
| Post-workout summary | "Session complete. Here's how you did." with explanations | Data only — streak, duration, next preview |
| Settings | Section descriptions visible ("Change your workout preferences") | Descriptions can be collapsed or removed |

### Implementation Notes
- First-use copy triggers on: no local workout history, first visit to a specific screen, or onboarding just completed
- Returning-user copy triggers on: 3+ completed sessions, or 2+ visits to the specific screen
- The transition should be invisible — users shouldn't notice copy disappearing. It should feel like the app "knows" them better.
- Never reduce copy that serves a safety function (health disclaimers, deletion confirmations)

## Seamless Legal Integration

Legal copy (disclaimers, subscription terms, privacy disclosures) must read in the same voice as the rest of the product. Users shouldn't feel a tonal shift when they encounter required language.

### Rules
- **Rewrite legal into product voice**: "[Product Name] provides fitness information for educational purposes. It is not a substitute for medical advice." reads better than "DISCLAIMER: This application is not intended to provide medical advice, diagnosis, or treatment."
- **Same sentence structure**: Legal copy follows the same writing principles — short sentences, active voice, second person, sentence case
- **Integrated, not appended**: Disclaimers are part of the screen design, not a block of small text bolted to the bottom
- **Subscription terms as product information**: "Premium renews monthly at $7.99. Cancel anytime in iOS Settings." — this is helpful product copy that happens to satisfy Apple's disclosure requirement
- **Approval chain**: Legal agent approves the substance, Content agent approves the voice. Both must sign off before shipping.

## State-Based Copy

Every interactive element has multiple states. Each state needs considered copy.

### Empty States
When a screen has no data yet. Most critical UX writing — this is the user's first encounter with the feature.

| Screen | Empty State Copy | CTA |
|--------|-----------------|-----|
| Progress dashboard | "Complete your first session to start tracking progress." | "Go to Today" |
| Weekly plan (free) | "Your workout history will appear here as you train." | None (passive) |
| Workout history | "No sessions yet. Your first routine is waiting." | "See Today's Routine" |

**Rules**:
- Tell the user what will appear here and how to get there
- Include a CTA that leads to the action that populates this screen
- Never show a blank screen — always have a message
- Encouraging but not pushy: "Your first routine is waiting" not "Start working out now!"

### Loading States
- Default: no text (spinner or skeleton screen is sufficient)
- Long load (3+ seconds): "Building your routine..." or "Loading your week..."
- Use present participle ("Building...") not passive ("Your routine is being built...")

### Error States
See `team/content/skills/brand-voice.md` for error patterns. Additional rules:

| Error Type | Pattern | Example |
|------------|---------|---------|
| Network | "[What failed]. [How to fix it]." | "Couldn't load your routine. Check your connection and try again." |
| Server | "[What failed]. [Reassurance + retry]." | "Something didn't work. Tap to retry." |
| Validation | "[What's wrong]. [What to do]." | "Password must be at least 8 characters." |
| Timeout | "[What happened]. [Fallback]." | "Took too long to connect. Showing your cached routine." |

**Rules**:
- Never expose technical details (error codes, stack traces, server names)
- Never blame the user ("You entered an invalid email" → "Check your email format")
- Always provide a next step (retry, alternative, support link)
- Calm and solution-oriented — never alarmist

### Confirmation Dialogs
High-stakes actions require explicit confirmation.

| Action | Title | Body | Confirm | Cancel |
|--------|-------|------|---------|--------|
| Delete all data (free) | "Reset all data?" | "This erases your workout history, preferences, and progress. This can't be undone." | "Reset Everything" | "Keep My Data" |
| Delete account (premium) | "Delete your account?" | "This permanently deletes your account and all data from our servers and this device. Cancel your subscription separately in iOS Settings." | "Delete Account" | "Keep Account" |
| Skip exercise | "Skip this exercise?" | None needed — low stakes | "Skip" | "Continue" |

**Rules**:
- Destructive action button uses destructive styling (red/warning color)
- Confirm button label describes the action specifically ("Reset Everything" not "OK" or "Yes")
- Cancel button label is reassuring ("Keep My Data" not "Cancel")
- Include consequences in the body — don't assume the user knows what deletion means

## Settings & Label Copy

### Settings Screen Labels
- Use the same terminology as the feature: "Time preference" not "Workout duration setting"
- Current value should be visible without tapping in: "Fitness level: Intermediate"
- Group labels in sentence case: Workout preferences, Account, Data, About

### Badge & Tag Copy
- "Designed for You" — smart routine badge (free tier, first 2/week)
- "Premium" — premium feature indicator
- "Manual" — manually logged workout marker
- Keep badges to 1-3 words — they're labels, not sentences

## Accessibility Text

### VoiceOver Labels
- Every interactive element must have a VoiceOver label
- Labels describe the element's purpose, not its visual appearance: "Start workout" not "Green button"
- Dynamic content (timers, progress bars) must announce state changes
- Image alt text for exercise thumbnails: "[Exercise name], [discipline]" — e.g., "Push-Up, strength"

### Screen Reader Flow
- Reading order matches visual hierarchy (headline → supporting text → actions)
- Decorative images marked as decorative (empty alt text)
- Form fields have associated labels (not just placeholder text)

## Handoff to UI/UX Agent

When delivering UX copy to the UI/UX agent, provide:
1. Copy per screen, organized by screen ID
2. All states covered (default, empty, loading, error)
3. Character count for each element (so UI/UX can size containers)
4. Notes on any copy that may change dynamically (e.g., rationale strings, streak counts)

## Principles

1. **UI copy is invisible when it works**: The user should complete their task without noticing the words. If they notice the copy, it's either too clever, too long, or confusing.
2. **States are content**: An empty state, an error message, and a loading indicator are all content decisions. Design the unhappy path with the same care as the happy path.
3. **Destructive actions need friction**: Confirmation dialogs for data deletion should slow the user down on purpose. Use specific language ("Reset Everything") over generic ("OK") to force conscious choice.
4. **Words are pixels**: Every string has a visual footprint. Write within character budgets, check copy in mockups, and treat text length as a design constraint — not something to fix after the layout is done.
5. **Reduce as you earn trust**: First-use copy explains. Returning-user copy gets out of the way. The app should feel smarter the more you use it — and that includes the words.
6. **Legal copy is product copy**: If a disclaimer reads like it was pasted from a legal document, rewrite it. The user should never feel a tonal shift between "your routine is ready" and "not a substitute for medical advice." Same voice, same care.
