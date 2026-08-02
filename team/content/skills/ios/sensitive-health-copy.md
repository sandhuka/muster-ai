# Sensitive Health Copy

## Purpose
Methodology for writing copy that touches health, body, fitness behavior, and physical outcomes — the emotional and behavioral layer of health communication. [Product Name] is YMYL-adjacent: copy about bodies, movement habits, and physical capability carries real psychological weight. This skill defines the guardrails. See the `brand-voice` skill for inclusive language rules and voice application. See the `ux-writing` skill for error states and progressive reduction. See the `notification-copy` skill for streak and missed-session messaging patterns. See the `email-sequences` skill for win-back sequence (lapsed user messaging). See the `fitness-claims-advertising` skill for claim boundaries. See the `compliance` skill for health data and regulatory context. See `knowledge-base/brand-guidelines.md` for brand voice.

## Body-Image-Safe Language

All copy that references fitness levels, physical goals, body metrics, or physical capability must pass through this filter. The rule: focus on what the body can do, never how it looks.

### Replacement Table

| Do Not Write | Write Instead | Why |
|-------------|---------------|-----|
| "Lose weight" / "weight loss" | "Build strength" / "improve endurance" | Frames goals as capability, not appearance |
| "Get toned" / "tone up" | "Build muscle" / "get stronger" | "Toned" is aesthetic language disguised as fitness language |
| "Burn calories" / "torch fat" | "Build endurance" / "increase your capacity" | Calorie framing reduces movement to a punishment for eating |
| "Problem areas" | Do not reference — reframe as muscle group focus | Implies the body has defects that need fixing |
| "Beach body" / "summer ready" | Never use — no seasonal body language | Ties physical worth to appearance and seasons |
| "Transform your body" | "Build a consistent practice" | Transformation language implies the current body is wrong |
| "No excuses" / "push through" | "Your routine is ready" / "pick up where you left off" | Shame-based motivation causes dropout, not adherence |
| "Beginner" (as identity) | "New to [discipline]" / "starting out" | "Beginner" as a label feels like a rank; a state is temporary and neutral |
| "Advanced" (as identity) | "Experienced with [discipline]" | Same principle — describe experience, not status |
| "Ideal weight" / "goal weight" | Do not reference weight as a goal metric | [Product Name] tracks movement, not weight — keep the frame consistent |
| "Guilty pleasure" / "cheat day" | Never use — no morality language around behavior | Movement and rest are both neutral; neither requires guilt |
| "Struggle" / "weakness" | "Working on" / "building" | Deficit framing vs. growth framing |
| "Fix your posture" / "correct your form" | "Improve your posture" / "refine your form" | "Fix" and "correct" imply brokenness |

### Contextual Rules

- **Exercise descriptions**: Describe what the exercise targets and how to perform it. Never describe what it "fixes" about the body.
- **Progress language**: "You've completed 20 strength sessions" (fact). Never "You're getting closer to your ideal body" (judgment).
- **Comparison**: Compare the user only to their own history. "Up from 2 sessions last week" is fine. "Most users at your level..." is not — it introduces social comparison.
- **Equipment-aware copy**: Never imply that bodyweight exercises are lesser. "Your routine uses bodyweight exercises" is neutral. "Don't worry, you can still get a good workout without equipment" is not.

## Missed-Session and Lapsed-User Framing

The algorithm adjusts when users miss sessions. The copy reflects that adjustment as a neutral fact, not a problem that needs addressing.

### Core Rule
The app adapts. The copy states the adaptation. That is the entire message. No commentary on the absence itself.

### Pattern Table

| Scenario | On-Brand | Off-Brand |
|----------|----------|-----------|
| 1 day missed | "Your routine is ready." (same as any day) | "Welcome back! We missed you!" |
| 3-5 days missed | "Your routine adjusted for the break." | "It's been a few days — let's get back on track!" |
| 7-14 days missed | "Welcome back. Starting with a lighter session — your body will ramp up from here." | "You've been away for a while. Don't worry, you can still reach your goals!" |
| 14-30 days missed | "Welcome back. Your routine is recalibrated — a good place to restart." | "We've been waiting for you! Time to get back in the game!" |
| 30+ days missed | "Welcome back. Fresh start — your routine is built for today." | "It's never too late to start again! Your journey continues!" |

### Rules

- Never quantify the absence in user-facing copy. "Welcome back" is enough — "You missed 12 days" is a guilt mechanism, even if it looks like a fact.
- Never use reunion language ("we missed you", "glad you're back", "welcome home"). The app is a tool, not a relationship that suffers when unused.
- Never frame return as redemption or second chances. "Fresh start" is acceptable because it's forward-looking. "Second chance" is not because it implies the first attempt failed.
- Win-back emails follow the same rules — see the `email-sequences` skill for the full sequence.

## Injury and Discomfort Copy

Three contexts: during-workout safety cues, post-workout check-ins, and algorithm adaptation messaging when the routine changes due to reported discomfort.

### During-Workout Safety Cues
Displayed alongside exercise animations or during transitions.

| Type | Pattern | Example |
|------|---------|---------|
| General form cue | "[What to maintain]. [Why]." | "Keep your back neutral. This protects your lower spine." |
| Difficulty scaling | "Modify: [easier option]." | "Modify: drop to your knees for less load." |
| Stop cue | "Stop if you feel sharp pain." | Appears on every exercise screen as persistent helper text |
| Joint awareness | "[Joint] should feel stable, not strained." | "Your knees should feel stable, not strained." |

**Rules**:
- Every exercise that loads joints or the spine gets a safety cue. No exceptions.
- Use "sharp pain" as the stop threshold — it is clinically meaningful and universally understood. "Discomfort" is too vague (some discomfort during exercise is normal). "Pain" alone is too broad.
- Never say "push through the pain" or "no pain, no gain" — these are dangerous in a fitness context.
- Modify options are presented as neutral alternatives, not as lesser versions. "Modify: drop to your knees" not "Can't do a full push-up? Try this instead."

### Post-Workout Check-In
If the user reports discomfort after a session.

| Scenario | Copy |
|----------|------|
| User reports mild discomfort | "Noted. Your next routine will adjust for this." |
| User reports discomfort in a specific area | "Noted — [area] flagged. Tomorrow's routine will reduce load on that area." |
| User reports recurring discomfort | "You've flagged [area] more than once. Consider consulting a healthcare professional. Your routines will continue to adjust." |

**Rules**:
- Acknowledge the report. Confirm the adaptation. That is all.
- Never interpret the discomfort ("That's probably just DOMS" or "You might have strained your..."). The app is not qualified to assess.
- Escalate to medical referral after 2 reports in the same area within 14 days — see Medical Boundary Escalation below.

### Algorithm Adaptation Messaging
When the routine visibly changes because of a discomfort report.

- Pattern: "Adjusted: [what changed] — [area] is flagged for lighter load."
- Example: "Adjusted: yoga focus today — your lower back is flagged for lighter load."
- Never frame the adjustment as a downgrade. It is not "easier" or "lighter" — it is "adjusted."

## Rest and Recovery Framing

Rest days and lower-intensity sessions are algorithm outputs, not failures. The copy treats them with the same authority as high-intensity days.

### Pattern Table

| Scenario | On-Brand | Off-Brand |
|----------|----------|-----------|
| Scheduled rest day | "Rest day. Your body is building on this week's work." | "You deserve a break! Take it easy today." |
| Recovery day (active) | "Active recovery today — 15-minute stretching session." | "Light day today — don't worry, you'll be back to full workouts soon!" |
| Algorithm reduces intensity | "Lower intensity today — your recent sessions were high output." | "Taking it easy today so you don't overdo it!" |
| User trained hard all week | "Recovery day. 4 sessions this week — your muscles need time to adapt." | "Wow, great week! You earned this rest day!" |

### Rules

- Rest is prescribed, not earned. "Your body is building on this week's work" frames rest as part of the process. "You earned this" frames rest as a reward for suffering.
- Never imply that rest requires justification. The algorithm prescribed it. That is sufficient.
- Never contrast rest with "real" training. Lower intensity is not lesser intensity.
- "Active recovery" is the correct term for light movement days. Never "easy day" or "light day."
- Recovery rationale follows the same pattern as workout rationale — explain the "why" in one sentence. "Tuesday's lower body session needs 48 hours" gives the user confidence that rest is intentional.

## Medical Boundary Escalation

[Product Name] provides fitness guidance. It does not provide medical advice, diagnosis, or treatment. This section defines the line and what happens when copy approaches it.

### The Line

| [Product Name] Can Say | [Product Name] Cannot Say |
|---------------|-----------------|
| "Stop if you feel sharp pain" | "This pain is probably [diagnosis]" |
| "Consider consulting a healthcare professional" | "You should see a doctor about this" (directive) |
| "Your routine will adjust for this" | "Rest for [X] days and then try again" (prescription) |
| "Science-backed routine design" | "Clinically proven to reduce injury" |
| "May help improve flexibility" | "Will improve your flexibility" |
| "Designed to support recovery" | "Treats" / "heals" / "fixes" |

### Escalation Triggers

When any of these conditions are met, the copy must include a medical referral nudge:

1. **Recurring discomfort**: User flags the same body area 2+ times within 14 days.
2. **Pre-existing condition disclosure**: If onboarding or settings include a health condition field (post-MVP), any routine adjustment based on that disclosure includes: "This routine accounts for your settings. For medical guidance, consult your healthcare provider."
3. **High-risk exercise context**: Exercises with spinal loading, deep joint flexion, or inversion include persistent safety copy (covered in During-Workout Safety Cues above).
4. **User-initiated health questions**: If any future conversational UI or support channel receives health questions, the response is always: "[Product Name] provides fitness routines, not medical advice. For health concerns, consult a healthcare professional."

### Medical Referral Language

Use this exact phrasing (Legal-approved pattern):
- Standard: "Consider consulting a healthcare professional."
- After recurring flags: "You've flagged [area] more than once. Consider consulting a healthcare professional."
- Onboarding disclaimer: "[Product Name] provides fitness routines based on exercise science. It is not a substitute for medical advice."

Do not use:
- "See a doctor" (too directive, assumes access and relationship)
- "You need medical attention" (alarm without basis)
- "This could be serious" (diagnosis by implication)
- "Consult your physician" (formal, excludes people without a physician)

"Healthcare professional" is the approved term — it is broad enough to include physiotherapists, sports medicine practitioners, and general practitioners without assuming the user's healthcare context.

## Sensitive Onboarding Copy

Onboarding screens F-ONB-0 through F-ONB-6 collect fitness level, goals, and preferences. This is the moment of highest vulnerability — the user is self-assessing in a domain where many people feel inadequate.

### Fitness Level Self-Assessment (F-ONB-2)

The user selects their fitness level. The labels and descriptions must empower without ranking.

**Framing principle**: Describe what the person does, not what the person is.

| Level | Label | Description |
|-------|-------|-------------|
| Level 1 | "New to this" | "Little or no regular exercise right now." |
| Level 2 | "Sometimes active" | "You move a few times a week, but not on a set schedule." |
| Level 3 | "Regularly active" | "You exercise 3-4 times a week with some consistency." |
| Level 4 | "Very active" | "You train 5+ times a week and follow a structured approach." |

**Rules**:
- No value judgment between levels. Level 1 is not worse than level 4 — it is a different starting point.
- Descriptions reference behavior ("you exercise 3-4 times a week"), not identity ("you're an intermediate athlete").
- No aspirational language on level selection. "Where are you right now?" not "Where do you want to be?"
- The screen header frames the question practically: "How active are you right now?" — present tense, factual, no pressure.

### Goal-Setting Language (F-ONB-1)

The user selects fitness goals. Goals must be aspirational without promising outcomes.

**Framing principle**: The user is choosing a direction, not signing a contract.

| Goal Option | Label | Do Not Use |
|------------|-------|------------|
| Build strength | "Get stronger" | "Build muscle fast" / "Get ripped" |
| Improve flexibility | "Improve flexibility" | "Get flexible" / "Touch your toes in 30 days" |
| Stay consistent | "Stay consistent" | "Never miss a workout" / "Build an unbreakable habit" |
| Move more | "Move more" | "Get off the couch" / "Stop being sedentary" |
| Manage stress | "Manage stress" | "Fix your stress" / "De-stress your life" |
| Support recovery | "Support recovery" | "Heal faster" / "Bounce back" |

**Rules**:
- Goals are directions, not destinations. "Get stronger" is a trajectory. "Bench press your body weight in 12 weeks" is a promise.
- Never use timeline language in goal descriptions. No "in X weeks" or "by [date]."
- Never tie goals to appearance outcomes. "Get stronger" is about capability. "Look better" is about appearance.
- The screen header: "What are you working toward?" — open, forward-looking, no pressure.

### Body Metrics (If Collected)

If any future onboarding step collects height, weight, or body measurements:
- Frame the collection as functional: "This helps calibrate exercise recommendations."
- Make it optional and say so: "Optional — skip if you prefer."
- Never display BMI, body fat estimates, or "ideal" ranges. These are clinically contested and psychologically loaded.
- Never store or surface weight trends unless the user explicitly opts in to a weight tracking feature (not in current scope).

## Sensitivity Review Checklist

Run this checklist on every screen, notification, email, or marketing asset that touches health, body, fitness behavior, or physical outcomes. If any item fails, revise before shipping.

### Language Check
- [ ] No guilt, shame, or anxiety about fitness behavior (missed sessions, low activity, breaks)
- [ ] No moral framing of exercise adherence (no "good job for showing up" — it implies not showing up is bad)
- [ ] No appearance-based language (weight, body shape, "toned," "lean," "slim")
- [ ] No comparison to other users or population norms
- [ ] No deficit language ("fix," "correct," "weakness," "struggle")
- [ ] Body references focus on capability, not appearance

### Safety Check
- [ ] Injury and discomfort copy defers to healthcare professionals — never diagnoses or prescribes
- [ ] "Sharp pain" stop cues present on exercises with joint or spinal load
- [ ] Recurring discomfort triggers medical referral language
- [ ] No "push through" or pain-normalization language

### Framing Check
- [ ] Rest and recovery framed as active parts of the plan, not failures or rewards
- [ ] Missed sessions treated as neutral facts — algorithm adjusted, copy reflects it
- [ ] Algorithm adaptations described without value judgment (not "easier" or "lighter")
- [ ] Fitness levels described as states ("new to this"), not ranks ("beginner")

### Claim Check
- [ ] No unqualified health claims ("will improve," "guarantees," "proven")
- [ ] Qualified language used where needed ("may help," "designed to support," "science-backed")
- [ ] Medical boundary not crossed — no diagnosis, prescription, or treatment language
- [ ] Legal agent flagged for review on any copy making health-adjacent claims

### Emotional Check
- [ ] Copy reads as calm, factual, and forward-looking
- [ ] User does not feel judged, ranked, or pressured after reading
- [ ] Onboarding self-assessment empowers without creating anxiety
- [ ] Win-back and re-engagement copy is welcoming without implying the user failed

## Principles

1. **The body is not a problem to solve**: Every word choice either reinforces or undermines this. "Get stronger" treats the body as capable. "Fix your posture" treats it as broken. Default to capability framing in every context.

2. **Neutrality is kindness in health copy**: When the user misses a session, the kindest thing the app can say is nothing about the absence. State what is true now ("your routine is ready") and what the algorithm did ("adjusted for the break"). Silence on the gap is more respectful than any reassurance.

3. **The algorithm is the authority, not the copy**: When the app prescribes rest, reduces intensity, or changes the plan, the copy reports the decision — it does not editorialize. "Rest day. Your muscles are adapting" is a report. "You deserve a break" is an editorial. Reports build trust; editorials build dependency.

4. **Medical humility is non-negotiable**: The moment copy implies diagnosis, treatment, or clinical assessment, the product crosses a line it cannot uncross. "Consider consulting a healthcare professional" is the ceiling. Everything above it belongs to licensed practitioners, not a fitness app.

5. **Shame drives dropout, not adherence**: Every piece of research on fitness behavior shows the same thing — guilt and shame cause people to disengage, not recommit. Copy that guilt-trips (even gently, even with good intentions) is copy that loses users. Neutral, factual, forward-looking language retains them.

6. **Sensitive copy ages differently**: "Push through" felt motivational in 2015. It reads as reckless now. Health communication norms shift. Review this skill file annually and pressure-test every pattern against current standards. What feels neutral today may not in two years.

7. **When in doubt, say less**: If a screen, notification, or email could function without the sensitive line, remove it. The safest health copy is often no health copy at all — just the routine, the data, and the next step.
