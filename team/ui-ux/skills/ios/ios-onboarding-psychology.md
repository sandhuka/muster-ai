# iOS Onboarding Psychology

## Purpose
Define the behavioral design principles behind the product's onboarding — not the layout or flow mechanics (those are in `mobile-patterns.md` and `user-flow-mapping.md`), but the *why* behind every question's placement, the psychology of commitment, and the transition from setup to first value. Onboarding is confidence-building and momentum-building, not data collection. Read this skill when designing onboarding screens (F-ONB-0 through F-ONB-6) and the first-routine handoff. See `team/ui-ux/skills/ios-content-hierarchy.md` for how to prioritize content within each onboarding screen.

## Onboarding's Job
Onboarding must accomplish four things — in this order of importance:

1. **Build confidence** — "This app understands me and will give me something good."
2. **Collect inputs** — Disciplines, goals, equipment, schedule, fitness level for the algorithm.
3. **Create momentum** — The user should feel they're moving *toward* their first workout, not *through* a form.
4. **Establish trust** — The user should feel safe sharing preferences and believe the app will use them well.

If onboarding nails #1 and #3 but collects slightly less data, that's a better outcome than collecting everything but losing the user to fatigue or doubt.

## Apple's First-Run Philosophy
Apple onboards with these principles:

- **Show value before asking for anything.** The Weather app shows your weather before asking for notification permission. the product should show what it can do before asking what you want.
- **Make every choice feel reversible.** "You can change this anytime in Settings" removes decision anxiety. Say it explicitly.
- **Fewer options, more confidence.** 4 choices per screen maximum. Apple never shows a wall of checkboxes.
- **Skip is always available.** No question is mandatory. The algorithm works with defaults — it just works *better* with input. Frame it that way.
- **Explain by showing, not telling.** Don't explain that the algorithm personalizes routines — show a preview of what a personalized routine looks like.

## Motivation-First Sequencing
The order of questions matters because it mirrors the user's internal motivation arc:

| Step | Question | Psychological Purpose |
|------|----------|----------------------|
| 1 | **Welcome** (F-ONB-0) | No question — build excitement. Show the characters, show the value. The user should think "I want this." |
| 2 | **Disciplines** (F-ONB-5) — "What movement do you enjoy?" | Identity question. Easy, low-stakes, feels like self-expression not data entry. Starts with desire, not limitation. |
| 3 | **Goals** (F-ONB-1) — "What are you working toward?" | Aspiration question. Still positive, forward-looking. User is imagining their better self. |
| 4 | **Equipment** (F-ONB-3) — "What do you have access to?" | Practical constraint. Asked *after* goals so it feels like "let's make this work for you" not "what are your limitations." |
| 5 | **Schedule** (F-ONB-4) — "How much time do you have?" | Time constraint. By now the user is invested — they've stated who they are and what they want. Sharing constraints feels collaborative, not limiting. |
| 6 | **Fitness level** (F-ONB-2) — "Where are you starting from?" | Most vulnerable question — asked last (before summary) when trust is highest. Frame as starting point, not judgment. |
| 7 | **Summary** (F-ONB-6) | Confirmation + handoff. "Here's what we know. Let's build your first routine." |

**Key insight**: The sequence moves from identity → aspiration → constraints → vulnerability. Never reverse this. Never lead with constraints or fitness level.

## Progressive Profiling Rules
Not everything needs to be asked during onboarding.

### Ask Now (Onboarding)
Information the algorithm *needs* to generate a reasonable first routine:
- Discipline preferences (strength, yoga, stretching)
- Primary goal
- Available equipment
- Available time per session
- General fitness level

### Ask Later (In-Context)
Information that's better collected when the user has context to answer well:
- Specific muscle group preferences → After first few workouts, when they've seen what's available
- Rest day preferences → After they've experienced the weekly plan
- Notification timing → After they've completed a few sessions and have a rhythm
- Injury/limitation details → When they encounter an exercise they can't do (contextual prompt)

### Never Ask (Infer Instead)
- Workout frequency → Infer from completed sessions
- Preferred workout time of day → Infer from usage patterns
- Exercise difficulty preferences → Infer from skip/complete behavior

## Choice Architecture

### Option Count
- **3-5 options per screen** is the sweet spot. Fewer feels restrictive. More causes decision paralysis.
- Multi-select questions (disciplines, goals): show all options but visually suggest "most people pick 1-2"
- Single-select questions (fitness level, schedule): use clear, non-overlapping labels

### Default Selections
- No pre-selected defaults for identity questions (disciplines, goals) — the user should feel they're *choosing*, not *confirming*
- Sensible defaults for constraint questions: "15-30 minutes" for schedule, "Beginner-Intermediate" for fitness level — with easy override
- Default selections should be the most common choice for the product's target persona

### Handling Uncertain Users
- **"Not sure" is a valid answer.** For fitness level: offer "Not sure — start me at a comfortable level" as an option. The algorithm defaults to moderate and adapts.
- For goals: if the user selects nothing, show a gentle nudge: "Pick one to start — you can always change it" rather than blocking progress
- For equipment: "Just my body" is always the first option (lowest barrier)

### Label Psychology
| Avoid | Use Instead | Why |
|-------|-------------|-----|
| "Beginner" | "Starting fresh" or "New to this" | "Beginner" can feel like a label. Starting fresh feels like a beginning. |
| "Advanced" | "I train regularly" | Describes behavior, not identity. Less intimidating to claim. |
| "Weight loss" | "Feel lighter" or "Lean out" | Goal-oriented, not problem-focused. |
| "How fit are you?" | "Where are you starting from?" | Starting point, not judgment. |
| "Select your limitations" | "What do you have access to?" | Frames around capability, not restriction. |

## Commitment and Momentum Design

### Progress Indicator
- Show a simple step indicator (dots or thin bar, not "Step 3 of 7")
- Numbered steps feel like a checklist. Dots feel like a journey.
- Progress bar should be visually ahead of actual progress — at step 1, show ~20% fill, not ~14%. This creates momentum.

### Micro-Completion Signals
- Each selection should produce immediate visual feedback: card highlights, subtle animation, haptic tap
- After completing each screen, a brief transition (not just an instant cut) signals "that's done, moving forward"
- The summary screen should feel like an achievement: "Here's your profile" — not "Review your answers"

### Time Perception
- Onboarding should feel like < 60 seconds even if it takes 90
- Achieve this through: fast transitions, visual variety (different layouts per screen), and the feeling that each step brings them closer to their routine
- Never show a loading spinner during onboarding. Pre-compute what you can.

## Permission Timing Rules
iOS permission prompts are one-shot — if the user declines, recovery is hard. Time them carefully.

| Permission | When to Ask | How to Frame |
|-----------|------------|-------------|
| **Notifications** | After first completed workout — when the user has experienced value | "Want us to remind you tomorrow? We'll send one message when your routine is ready." |
| **HealthKit** | After 3+ completed workouts — when they'd benefit from richer data | "Connect Health to track your activity across apps." Show what data you'll read (not write). |
| **App Tracking (ATT)** | Delay as long as possible. Ideally never for v1.0. | If required: frame around "personalized experience" not "ads." |
| **Subscription** | NOT during onboarding. After the user has completed 2-3 free routines and seen the Plan tab. | Natural upgrade moment: when they try to access a premium feature, not before they've used the free one. |

**Rule**: Never ask for a permission before the user has experienced the value that permission enables. This is Apple's own guidance and it dramatically improves grant rates.

## Summary and Confirmation Design (F-ONB-6)

The summary screen is the bridge between "setup" and "my app." It serves three purposes:

1. **Validation** — "We heard you. Here's proof." Show their selections back to them in a clean, visual format.
2. **Editability** — Each section is tappable to change. This removes the anxiety of "did I pick right?"
3. **Anticipation** — End with a forward-looking statement: "Building your first routine..." or "Meet your coaches" — not just "Done."

### Summary Screen Structure
- Profile card showing: selected disciplines (icons), goal, schedule, fitness level
- Each item is a tappable row (tap → goes back to that step to edit)
- "Looks good" primary CTA at the bottom
- Subtle animation or character introduction as anticipation builder
- Transition: CTA triggers a brief "generating" moment (0.5-1s with animation), then cross-fades directly into Today screen with the first routine ready

## First-Value Transition
The moment between "onboarding complete" and "here's your first routine" is the most critical transition in the app.

### Rules
- **Zero taps between summary confirmation and first routine.** "Looks good" → generating animation → Today screen with routine. No interstitial screens, no tutorials, no "welcome to your dashboard" messages.
- **The first routine must be visible immediately.** Pre-generate it while the user is on the summary screen. Never show a loading spinner as the first post-onboarding experience.
- **Don't explain the UI.** No coach marks, no tooltips, no "tap here to start." The interface should be self-evident. If it needs explanation, the design is wrong.
- **Let the first routine be imperfect.** A routine generated from 5 quick questions won't be perfect. That's fine. The algorithm improves over time. Don't over-promise on the summary screen — say "here's a great place to start" not "your perfect routine."

## Failure and Hesitation States

### Skipped Steps
- If the user skips a question, use a sensible default (documented per question above)
- Don't warn or guilt: "You can always update this later" — one line, dismissive, move on
- Track which steps were skipped → Later, surface an in-context prompt when relevant ("We noticed you skipped equipment — tap here to update for better recommendations")

### Decision Paralysis
- If a user sits on a screen for > 15 seconds without interaction, the agent should design a subtle hint (not a popup): gentle animation on the most popular choice, or a "Most people pick..." label
- Never auto-advance. The user is in control.

### Back Navigation
- Users must be able to go back to any previous step without losing selections
- Back should feel instant (no re-animation of the previous screen)
- Selections persist across back/forward navigation

### Drop-Off Recovery
- If the user leaves during onboarding and returns: resume where they left off, don't restart
- Show a brief "Welcome back — pick up where you left off?" with option to restart
- Preserve all previous selections

## Output Format
When designing onboarding, produce this alongside the wireframes:

```markdown
## Onboarding Design Rationale

### Question Sequence
| Step | Screen | Question | Psychological Purpose | Default if Skipped |
|------|--------|----------|----------------------|-------------------|
| 0 | F-ONB-0 | (none — welcome) | Build excitement, show value | N/A |
| 1 | F-ONB-5 | Disciplines | Identity, self-expression | All three selected |
| ... | ... | ... | ... | ... |

### Permission Timing Plan
| Permission | Trigger Point | Pre-prompt Copy | Grant Rate Target |
|-----------|--------------|-----------------|------------------|
| Notifications | After first workout completion | "..." | > 60% |
| ... | ... | ... | ... |

### Momentum Checkpoints
| After Step | User Should Feel | Design Element That Creates This |
|-----------|-----------------|--------------------------------|
| Welcome | "This is polished and smart" | Character showcase + value prop |
| Disciplines | "This is about me" | Visual selection with immediate feedback |
| ... | ... | ... |
```
