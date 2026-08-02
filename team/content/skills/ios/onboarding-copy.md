# Onboarding Copy

## Purpose
Define the methodology for writing onboarding flows — the first impression of the brand voice and the critical path to activation. See the `brand-voice` skill for voice application rules. See the `sensitive-health-copy` skill for body-image-safe language and sensitive self-assessment copy (fitness level, goals). See `knowledge-base/product-spec.md` Section 5A for onboarding feature specs (F-ONB-0 through F-ONB-6).

## Onboarding Copy Principles

### Progressive Disclosure
- Each screen communicates exactly one decision
- Never front-load information the user doesn't need yet
- Explanatory text is optional — if the options are self-evident, skip the explanation
- Save the "why this matters" for contexts where the user might hesitate (e.g., fitness level, body metrics)

### Speed Over Completeness
- The goal is getting the user to their first routine as fast as possible
- Every word on an onboarding screen is friction — cut ruthlessly
- If a screen takes more than 5 seconds to read, it's too long
- No tutorials, feature tours, or "did you know" content during onboarding

### Tone Calibration
- **Screen 1 (Welcome)**: Warmest tone in the entire app. This is the only moment to be slightly aspirational. Still no exclamation marks or hype.
- **Screens 2-6 (Selections)**: Functional, efficient. Short headlines, clear option labels. The user is doing a task — help them do it quickly.
- **Post-onboarding transition**: Shift to confident coach. First routine is ready — the app has delivered on its promise.

## Per-Screen Copy Structure

Each onboarding screen follows this template:

| Element | Max Length | Purpose | Required |
|---------|-----------|---------|----------|
| Headline | 6-8 words | What this screen is about | Yes |
| Subheadline | 15-20 words | Why this matters (only if non-obvious) | Optional |
| Option labels | 3-5 words each | Clear, jargon-free choices | Yes |
| Option descriptions | 10-15 words each | Clarifies what the option means in practice | Optional |
| CTA button | 2-3 words | Advances to next screen | Yes |

### Headline Writing Rules
- Action-oriented or question-based: "What's your goal?" or "Select your equipment"
- Never cute or clever — clarity beats personality in onboarding
- No articles ("a", "the") unless grammatically required

### Option Label Writing Rules
- Parallel grammatical structure across all options on a screen
- Self-explanatory without the description (description adds context, not meaning)
- User's language, not product language: "I exercise 2-3x per week" not "Intermediate (moderate training frequency)"

### CTA Button Patterns
- Default: "Continue" (neutral, works everywhere)
- First screen: "Get Started" (signals beginning)
- Last screen: "Build My Routine" or "See My Routine" (signals payoff)
- Never: "Next", "Submit", "Done" (generic and uninspiring)

## Value Before Asking

Apple's onboarding philosophy: show the user what the product does for them *before* asking them to do anything. Apply this to every screen.

### The Exchange Framework
Every onboarding screen asks the user to give something (a choice, information, attention). In return, the copy must communicate what they get back.

| Screen | User Gives | User Gets | Copy Should Convey |
|--------|-----------|-----------|-------------------|
| Welcome (F-ONB-0) | Attention (5 sec) | Understanding of what the app does | "This app builds your daily routine for you" |
| Goal (F-ONB-1) | Their primary goal | Routines weighted toward that goal | "This shapes what your routines focus on" |
| Fitness level (F-ONB-2) | Self-assessment | Appropriate difficulty | "So your routines match where you are" |
| Equipment (F-ONB-3) | What they have | Exercises they can actually do | "Only exercises you can do at home" |
| Time (F-ONB-4) | Schedule constraint | Routines that fit their day | "Your routine fits your schedule" |
| Disciplines (F-ONB-5) | Training preference | A balanced weekly plan | "Your week balances what you choose" |
| Pace (F-ONB-6) | Intensity preference | Comfortable workout density | "Controls how your routine feels" |

### Rules
- If the copy can't answer "what does the user get from this screen?", the screen needs redesigning, not better copy
- Never ask for information the algorithm doesn't use — every question must connect to a visible outcome
- The payoff (first routine) must arrive immediately after the last question — no gap between asking and delivering

## Health Disclaimer Integration

Legal disclaimers must read in the same voice as the rest of onboarding. The user should not feel a tonal shift.

- The health disclaimer must appear before the user starts their first workout
- **Preferred placement**: Integrated into the pre-workout summary screen as a calm, prominent note — not a separate "legal" screen that breaks the flow
- **Fallback placement**: Dedicated screen between onboarding and first routine, only if the pre-workout integration doesn't provide enough visibility

### Writing the Disclaimer in Product Voice
The Legal agent provides the required substance (see the `terms-privacy` skill — Fitness App Disclaimer Template). The Content agent rewrites it in product voice. Both agents must approve.

| Legal Substance | Compliance Copy | Product Voice Copy |
|----------------|----------------|-------------------|
| Not medical advice | "This application does not provide medical advice, diagnosis, or treatment." | "[Product Name] provides fitness guidance, not medical advice." |
| Consult physician | "Consult a qualified healthcare provider before beginning any exercise program." | "Check with your doctor before starting a new exercise routine." |
| Injury risk | "Exercise carries inherent risks of physical injury." | "Listen to your body. Stop if something doesn't feel right." |
| No guarantees | "Results are not guaranteed and may vary." | "Results depend on your effort, consistency, and individual factors." |

### Rules
- Same sentence case, same sentence length, same direct tone as the rest of the app
- No ALL CAPS, no "DISCLAIMER:" prefix, no legalese formatting
- The disclaimer should feel like the Intelligent Coach giving honest context — not a lawyer covering liability

## Post-Onboarding Interstitial

After the last onboarding step, before the first routine:
- Brief preview of the smart weekly plan (premium feature teaser)
- Copy should show value without hard-selling: "Here's what your week could look like" with premium badges on recovery-aware days
- Dismissal CTA: "See Today's Routine" — drives to immediate value
- This is paywall trigger 1 — no paywall interruption, just a preview

## Writing Checklist (Per Screen)

- [ ] Headline is 8 words or fewer
- [ ] All option labels use parallel structure
- [ ] No jargon or technical fitness terminology
- [ ] Subheadline only present if the question isn't self-explanatory
- [ ] CTA button clearly communicates what happens next
- [ ] Copy uses approved terminology from `knowledge-base/brand-guidelines.md` Section 5
- [ ] Total readable text takes under 5 seconds
- [ ] The "value exchange" is clear — user knows what they get from answering
- [ ] Sentence case on all text elements (per `brand-voice.md` conventions)
- [ ] No idioms or culturally specific references (localization-ready)
- [ ] Health disclaimer (if on this screen) reads in product voice, not legal voice
- [ ] All copy fits within character budgets at 140% expansion (per `ux-writing.md`)

## Output
Finalized onboarding copy is handed to the UI/UX agent for wireframe integration and to the Developer agent for implementation. File format: one markdown document with copy per screen, organized by screen ID (F-ONB-0 through F-ONB-6).

## Principles

1. **Every word is friction**: Onboarding is not a content surface — it's a gate between install and activation. The fastest onboarding that captures enough signal wins.
2. **Warm start, efficient middle, confident finish**: The welcome screen earns trust, the selection screens respect time, and the first routine delivers the promise. Tone shifts with the user's journey.
3. **Options are content**: The way you label "Beginner / Intermediate / Advanced" shapes how users perceive themselves. Use empowering language that helps users self-select accurately without feeling judged.
4. **Value before asking**: Every screen must answer "what does the user get from this?" before asking them to choose. If the value isn't clear, the user hesitates — and hesitation in onboarding is abandonment.
5. **Legal copy is onboarding copy**: The health disclaimer is not a legal interruption — it's the Intelligent Coach being transparent. Write it in the same voice, with the same care, at the same quality bar as every other screen.
