# Brand Voice Guidelines

## Purpose
Define the writing methodology and per-surface copy patterns that implement the brand voice. The authoritative voice definition lives in `knowledge-base/brand-guidelines.md` — this skill covers how to apply it. See `team/content/skills/content-calendar.md` for copy cadence and refresh cycles.

## Authoritative Voice Reference
The complete brand voice definition — personality, tone spectrum, do's/don'ts, example phrases, and competitive positioning language — lives in `knowledge-base/brand-guidelines.md` (Sections 2-3). Read that file before writing any copy. This skill file covers methodology and per-surface guidance that supplements the brand guidelines.

## Writing Principles
- Second person ("you") for all user-facing content
- Active voice by default ("Track your progress" not "Progress can be tracked")
- Short sentences (15-20 words average)
- One idea per paragraph
- Frontload the value — most important info first
- **Positive framing**: Always tell the user what they *can* do, not what they can't. "You can change this in Settings" not "This can't be changed here." "Your routine uses bodyweight exercises" not "Equipment exercises aren't available." Reframe every negative into an action or a fact.
- **Sentence case everywhere**: Buttons, headings, labels, menu items, banners — all sentence case. "See your routine" not "See Your Routine." Only exceptions: proper nouns ([Product Name]), tab names (Today, Plan, Library, Progress), and exercise names in lists/cards.

## Writing Conventions (Apple HIG-Aligned)

### Word Choice
| Use | Don't Use | Why |
|-----|-----------|-----|
| "Tap" | "Tap on", "Click", "Press" | "Tap" is the iOS standard — clean and direct |
| "Choose" | "Select" (for menus) | "Choose" for picking from a menu or list |
| "Select" | "Choose" (for objects) | "Select" for highlighting an object on screen |
| "Turn on / Turn off" | "Enable / Disable", "Activate" | Plain language over technical terms |
| "Enter" | "Type in", "Input" | For text fields |
| "Swipe" | "Slide", "Drag" (for navigation) | iOS gesture vocabulary |
| "Sign in / Sign out" | "Log in / Log out" | Apple convention |

### Words to Avoid
- **"Please"**: Implies the system is doing the user a favor. "Enter your email" not "Please enter your email." Exception: apology contexts ("Please try again later" is acceptable for errors).
- **"Just"**: Minimizes the action and sounds condescending. "Tap Settings" not "Just tap Settings."
- **"Simply"**: Same problem as "just" — implies the user should find it obvious.
- **"Note that" / "Keep in mind"**: Filler. State the fact directly.
- **"Our"**: Avoid possessive references to the product. "Your routine is ready" not "Our algorithm built your routine." The user owns the experience.

### Formatting Standards
- **Numbers**: Use numerals for all numbers in UI copy (1, 2, 3 — not "one", "two", "three"). Spell out in marketing prose only when the number starts a sentence.
- **Time**: "30 sec", "5 min", "48 hours" in UI. Spell out in marketing: "thirty seconds."
- **Dates**: Day-first in UI labels: "Mon, Mar 18." Full date in long-form content.
- **Lists**: Parallel grammatical structure. If the first item starts with a verb, all items start with a verb.

## Inclusive Language

All copy must follow inclusive language standards across every surface:

### Gender
- Use "they/them" for singular references when gender is unknown
- Avoid gendered terms: "everyone" not "guys", "team" not "manpower"
- Character personas use their established pronouns — this is the only context where gendered language is appropriate

### Ability
- Avoid ableist language in UI and marketing:

| Don't Use | Use Instead |
|-----------|-------------|
| "See your progress" | "View your progress" |
| "Walk through the steps" | "Go through the steps" |
| "Blind spot" | "Gap" or "oversight" |
| "Lame" | Remove or rephrase |
| "Crippling" | "Significant" or "severe" |

- Exception: exercise instruction copy ("Look forward", "Stand tall") uses physical language appropriately — these are literal movement cues, not metaphors

### Cultural Sensitivity
- No idioms, slang, or culturally specific references in UI copy (they don't translate and exclude non-native speakers)
- No food metaphors for body types or fitness levels
- No assumptions about family structure, living situation, or economic access in marketing copy

## Localization-Ready Writing

Even before translating, write copy that can be translated cleanly:

- **No concatenated strings**: Never build sentences by joining variables. "You completed [X] sessions" as one string — not "You completed " + X + " sessions" as three fragments. Translators need full sentences to reorder grammar.
- **Leave room for expansion**: German and French expand 30-40% over English. UI copy should work if it grows by a third. If a button label barely fits at 3 words, it will break in German.
- **No puns or wordplay**: They don't translate. Clarity always beats cleverness.
- **No idioms**: "Hit the ground running", "low-hanging fruit", "ballpark" — none of these survive translation. Use literal language.
- **Full sentences over fragments**: "Your routine is ready" translates cleanly. "Routine ready!" doesn't — fragments have implicit grammar that varies by language.
- **Date/time/number formatting**: Use system locale formats where possible. Never hardcode "March 18" — use formatters that adapt to the user's region.

## Per-Surface Microcopy Guide

### Exercise Naming
- Use the exercise's common name, not anatomical terminology: "Push-Up" not "Horizontal Adduction Press"
- Capitalize exercise names as proper nouns in lists/cards: "Warrior II", "Plank Hold"
- In sentences, lowercase: "your routine includes a plank hold and lunges"

### Rest Timer Language
- Countdown: just the number, large and centered. No extra words
- Rest prompt: "Rest — [duration]" (e.g., "Rest — 30 seconds")
- Next exercise teaser during rest: "Next: [Exercise Name]" with thumbnail

### Algorithm Rationale Strings
Template patterns for the Today screen and Plan tab:
- Discipline focus: "Today: [discipline] focus — [reason]." → "Today: strength focus — your flexibility sessions are on track."
- Recovery-based: "[Muscle group] today — [recovering group] needs [time]." → "Upper body today — your legs need 48 hours."
- Schedule-aware: "[Duration]-minute [discipline] — fits your [day] window." → "22-minute strength — fits your Tuesday window."
- Adaptation: "Adjusted: [what changed] because [reason]." → "Adjusted: yoga instead of strength because you trained upper body yesterday."

### Upgrade Prompt Patterns
Always informative, never pushy. Lead with the specific benefit. See `team/content/skills/subscription-copy.md` for full paywall screen methodology and `team/content/skills/notification-copy.md` for recurring prompt rotation:
- "Smart weekly planning uses your full workout history. Unlock it."
- "Recovery tracking knows when each muscle group is ready. See yours."
- "Your routine syncs across devices with premium."
- Never: "Upgrade now!", "Go PRO!", "Don't miss out!"

### Error State Patterns
Calm, solution-oriented, brand-consistent. See `team/content/skills/ux-writing.md` for the full error state framework by error type:
- Network: "Couldn't load your routine. Check your connection and try again."
- Generic: "Something didn't work. Tap to retry."
- Data: "Your data wasn't saved. Try again in a moment."
- Never: "Oops!", "Uh oh!", "Error 500", technical jargon

## Character Persona Usage
Character personas are defined in `knowledge-base/brand-guidelines.md`. Full bios, disciplines, and personality traits live there.

### When to use character names
- Content detail views: "[Character]'s pick: [content variations]"
- Category introduction during onboarding
- Content marketing and blog posts where personality adds value
- App Store screenshots / marketing materials

### When to use generic references
- Algorithm rationale strings (describe the rationale, don't attribute it to a character)
- Error states, system messages, settings
- Any context where forcing a character name feels artificial
- Notifications (keep short and direct)

## Legal Coordination
Health claim boundaries apply to all copy surfaces:
- Use qualified language: "may help improve", "designed to support", "science-backed"
- Never: "will improve", "guarantees results", "scientifically proven"
- Fitness disclaimers must appear in onboarding and settings — not hidden
- When in doubt, flag copy to the Legal agent for review before shipping

## Voice Principles

1. **Brand guidelines is the source of truth**: `knowledge-base/brand-guidelines.md` defines the voice. This skill file applies it to specific surfaces. If there's a conflict, the guidelines win.

2. **Explain the "why"**: The product's differentiator is that it tells users why their routine looks the way it does. Every rationale string, notification, and insight should answer "why" before "what."

3. **Qualified health language always**: "May help improve", "designed to support", "science-backed" — never "will improve" or "guarantees results." Legal coordination is not optional for health-adjacent copy.

4. **Concise over enthusiastic**: The Efficient Professional persona respects intelligence and hates filler. One clear sentence beats three excited ones. If it reads like a fitness influencer wrote it, rewrite it.

5. **Positive framing over negative**: Tell the user what they can do, what's available, what's next — not what's missing, locked, or unavailable. Negative framing creates frustration; positive framing creates momentum.

6. **Inclusive by default**: Every copy decision is a design decision that includes or excludes. Gender-neutral, ability-conscious, culturally neutral language is not a constraint — it's precision.

7. **Write for translation even before you translate**: No idioms, no puns, no fragments, no concatenated strings. Copy that translates cleanly is also copy that communicates clearly in English. Localization-readiness is a clarity discipline.
