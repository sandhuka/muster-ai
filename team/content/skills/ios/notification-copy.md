# Notification & Triggered Copy

## Purpose
Define the methodology for writing short-form copy triggered by user actions or system events — in-app messages, algorithm rationale strings, paywall prompts, streak/insight messages, and push notifications (v1.1). See the `brand-voice` skill for rationale string templates and upgrade prompt patterns. See the `sensitive-health-copy` skill for missed-session and streak tone rules. See `knowledge-base/product-spec.md` Sections 5B and 5D for algorithm and session specs.

## Copy Categories

### Algorithm Rationale Strings
Displayed on the Today screen and pre-workout summary. Explain *why* today's routine looks the way it does.

**Structure**: `[What's happening] — [why].`

**Template bank** (maintain 8-10 variants per type, refresh quarterly):

| Type | Pattern | Example |
|------|---------|---------|
| Discipline focus | "[Discipline] focus — [reason]" | "Strength focus — your yoga sessions are on track this week" |
| Recovery-based | "[Target] today — [recovering group] needs [time]" | "Upper body today — your legs need another day" |
| Cold start | "Your first [discipline] session — starting with [rationale]" | "Your first strength session — starting with full body to build a baseline" |
| Schedule-aware | "[Duration]-minute [discipline] — [context]" | "20-minute stretching — a lighter session after yesterday's strength" |
| Welcome back | "Welcome back. [What's changed]" | "Welcome back. All muscle groups recovered — full routine options available" |

**Rules**:
- Always explain the "why" — this is the product's key differentiator
- Keep under 80 characters when possible (must fit one line on most devices)
- No exclamation marks, no hype language
- Free tier basic sessions get simpler rationale (no recovery references); smart sessions get full rationale

### Paywall Prompts
Displayed on post-workout screen (trigger 2), Plan tab banner (trigger 3), and post-onboarding interstitial (trigger 1).

**Rules**:
- Informative, never pushy — lead with the specific benefit being gated
- Trigger 2 recurs weekly — copy must feel fresh on repeat, not nagging
- Never interrupt a workout in progress
- Never use: "Go PRO!", "Upgrade now!", "Don't miss out!", "Limited time!"

**Rotation strategy for recurring trigger 2**:
Maintain a pool of 4-6 variants. Cycle through them so the user doesn't see the same message on consecutive weeks.

| Variant | Copy |
|---------|------|
| A | "You've used your 2 smart routines this week. Upgrade for smart scheduling every day." |
| B | "This week's smart sessions are done. Premium gives you the full algorithm on every workout." |
| C | "Want recovery-aware scheduling on every session? Upgrade to premium." |
| D | "Smart routines used up for the week. Unlock unlimited with premium." |

### Post-Workout Insights
Displayed on the post-workout summary screen (F-PLY-4). Quick, satisfying feedback.

**Structure**: `[Achievement]. [Context or comparison].`

| Type | Pattern | Example |
|------|---------|---------|
| Streak | "[Count] days in a row. [Comparison]." | "5 days in a row. Your longest streak this month." |
| Weekly progress | "[Count] sessions this week — [comparison to last week]." | "3rd session this week — up from 2 last week." |
| Recovery preview | "[What's next]. [Why]." | "Tomorrow looks like yoga — upper body is recovering." |
| Milestone | "[Achievement]. [Simple acknowledgment]." | "50th session completed. Consistency adds up." |

**Rules**:
- Calm acknowledgment, not celebration — "Solid week" not "AMAZING JOB!"
- Data-driven — reference specific numbers (streak count, session count, muscle groups)
- Keep under 2 sentences
- Never guilt-trip about gaps or missed days

### Streak & Engagement Messages
For the Today screen greeting and Progress tab.

**Rules**:
- Active streak: state the fact, don't over-celebrate. "Streak: 7 days" is enough.
- Broken streak: no guilt. "Your routine is ready" — same as any other day.
- Long absence (30+ days): "Welcome back. Your routine adjusted — picking up where recovery allows."
- Never: "You missed X days!", "Don't break your streak!", "You're falling behind!"

### Push Notifications (v1.1 — Write Templates Now)
Character limit: ~110 characters (iOS lock screen). Title + body format.

**Template bank** (maintain 15-20 variants, rotate monthly, never repeat back-to-back):

| Type | Title | Body |
|------|-------|------|
| Routine ready | "Your routine is ready" | "22-min strength — upper body focus today." |
| Streak at risk | "Keep it going" | "Day 6. Your routine takes [X] minutes today." |
| Weekly summary | "Your week in review" | "4 sessions, 3 disciplines. Check your progress." |

**Rules**:
- One emoji max (and only in title), zero in body
- Never guilt-trip or create urgency
- Time-sensitive notifications (routine ready) should include duration and discipline
- Streak-at-risk should emphasize ease ("takes 15 minutes") not loss ("don't lose your streak")

## Rotation & Freshness Strategy

| Copy Type | Pool Size | Rotation Cycle | Refresh Cadence |
|-----------|-----------|---------------|-----------------|
| Algorithm rationale | 8-10 per type | Contextual (varies by day) | Quarterly |
| Paywall prompts | 4-6 variants | Weekly cycle | Quarterly |
| Post-workout insights | Template-driven | Contextual | Stable (data-driven) |
| Push notifications | 15-20 variants | Monthly | Quarterly |
| Streak messages | 5-8 variants | Contextual | Biannually |

## Principles

1. **Short-form is harder than long-form**: Every word carries more weight when you have 80 characters. Write 5 versions, pick the tightest one.
2. **Repetition breeds annoyance**: Any copy the user sees more than once per month needs a rotation pool. Single-variant messages become invisible or irritating.
3. **Data over enthusiasm**: "3 sessions this week — up from 2 last week" is more motivating than "Great job this week!" The Efficient Professional persona responds to evidence, not cheerleading.
