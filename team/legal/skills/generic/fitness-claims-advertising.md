# Fitness Claims & Advertising Compliance

## Purpose
Provide a structured methodology for reviewing health and fitness claims in product copy, marketing, and App Store metadata. Primary consumers: Content agent (in-app copy, blog, help docs) and Marketing agent (ads, social, App Store listing). See the `compliance` skill for FTC regulatory context. See the `app-store-review` skill for Apple metadata claim rules.

## FTC Fitness Advertising Rules

### Core Requirements
- Every claim must be **truthful**, **substantiated**, and **not misleading** — including by implication
- Claims about results must reflect typical outcomes, not exceptional cases
- "Results may vary" disclaimers do not cure a misleading claim — the underlying claim must be truthful
- Before/after imagery requires that results shown are representative and achievable by typical users
- Endorsements and testimonials must reflect honest experiences with material connection disclosures

### Fitness-Specific FTC Guidance
- Weight loss claims require "competent and reliable scientific evidence" — anecdotes are insufficient
- Exercise benefit claims must be consistent with established exercise science (ACSM, NSCA standards)
- Claims about time savings ("get fit in 10 minutes") must be substantiated and qualified
- Comparative claims ("better than [competitor]") require head-to-head evidence or clear basis for comparison

## Claim Risk Classification

Use this framework when reviewing any copy from Content or Marketing agents.

### Green — Safe to Use
No qualification needed. Statements of fact or general wellness language.

- Describes what the app does: "[Factual description of your core action]"
- General wellness: "Stay consistent with your [activity] routine"
- Feature descriptions: "[Factual description of a shipped feature]"
- Effort-based: "Designed to help you [core activity] every day"
- User control: "Choose your [customizable parameters]"

### Yellow — Requires Qualification
Acceptable with hedging language and disclaimers.

- Outcome-adjacent: "Designed to support your fitness goals" (not "will achieve your goals")
- Science-referenced: "Based on exercise science principles" (not "scientifically proven")
- Time claims: "A focused routine that fits your schedule" (not "get fit in 15 minutes")
- Personalization: "Adapts to your recovery state" (not "knows exactly what your body needs")
- Comparative: "[Factual capability comparison]" (factual comparison, not superiority claim)

### Red — Do Not Use
Reject outright. These trigger FTC scrutiny and Apple review rejection.

- Medical claims: "Prevents injury," "Treats back pain," "Rehabilitates your knee"
- Guaranteed outcomes: "You will lose weight," "Guaranteed results," "Proven to build muscle"
- Absolute safety: "Completely safe for all users," "Injury-free workouts"
- Unsubstantiated superlatives: "The most effective fitness app," "Best workout algorithm"
- Diagnosis: "Detects muscle imbalances," "Identifies your weak points"
- Clinical language: "Prescribed," "Treatment plan," "Therapeutic"

## AI & Algorithm Claims

The FTC holds AI-related claims to the same substantiation standard as any other product claim — no special exemption. Product marketing may use terms like "smart," "personalized," and "science-backed." Each requires specific handling.

### AI Claim Classification

| Claim Type | Green (Safe) | Yellow (Hedge) | Red (Reject) |
|------------|-------------|----------------|--------------|
| Algorithm description | "Uses a rules-based algorithm" | "Smart [scheduling/recommendations] based on [domain] science" | "AI-powered personal [expert role]" |
| Personalization | "Adapts to your preferences and history" | "Personalized to your [tracked state]" | "Knows exactly what [you/your body] need(s)" |
| Science claims | "[Feature] follows [authority] guidelines" | "[Domain]-science-backed [feature]" | "Clinically validated algorithm" |
| Intelligence framing | "Considers your [data input]" | "Learns from your patterns" (only if true) | "AI that understands [you/your body/your needs]" |

### Rules for AI/Algorithm Language
- **Describe the mechanism, not magic**: "[Applies specific rule] based on [user data]" is substantiable. "Smart AI designs your perfect [outcome]" is not.
- **"Personalized" must map to real inputs**: Only claim personalization for factors the algorithm actually uses. Never imply the algorithm considers factors it doesn't.
- **"Science-backed" requires a traceable chain**: The claim must connect to a specific methodology or authoritative source. If challenged, you need to point to the rule, not just the marketing copy.
- **Match language to actual technology**: If the algorithm is rules-based, don't imply machine learning. If it's ML, don't imply human-level understanding. "Smart" should map to a specific capability.
- **Document substantiation**: For every AI/algorithm claim used in marketing, Content and Marketing agents should record what product feature substantiates it. Legal agent verifies the chain during claim review.

## Hedging Language Reference

When a Yellow claim needs qualification, use these patterns:

| Instead of | Use |
|------------|-----|
| "Will improve your [outcome]" | "Designed to support [outcome] over time" |
| "Proven [domain] science" | "Based on established [domain] science principles" |
| "Smart AI knows what you need" | "Algorithm considers your [actual data inputs]" |
| "[Quantified outcome claim]" | "Estimates [metric] based on [tracked inputs]" |
| "Perfect for [desired result]" | "Supports [desired result] as part of your [broader goal]" |
| "Personalized to your body" | "Adapts to your [actual customization parameters]" |

## Disclaimer Placement Requirements

| Surface | Required Disclaimer | Placement |
|---------|--------------------|-----------|
| App Store description | "[Domain] disclaimer — e.g., 'Not medical advice. Consult your physician before starting a new exercise program.'" | Within first 3 lines (visible without "more" tap) |
| Onboarding | Full [domain] disclaimer (see `terms-privacy.md` template) | Dedicated screen or prominent banner before first [core action] |
| In-app settings | Full disclaimer accessible at any time | Settings > About or Settings > Health Disclaimer |
| Marketing website | Condensed disclaimer on any page making fitness claims | Footer or inline near claims |
| Social ads | Space-constrained: link to full disclaimer | Bio link or ad landing page |
| Email campaigns | Condensed disclaimer | Email footer |

## Claim Review Workflow

When Content or Marketing agents submit copy for review:

1. **Classify every claim** using the Green/Yellow/Red framework above
2. **Flag Red claims** — provide a safe alternative using the hedging reference
3. **Qualify Yellow claims** — suggest specific hedging language
4. **Verify Green claims** — confirm they accurately describe shipped functionality (don't claim features that aren't built yet)
5. **Check surfaces** — ensure required disclaimers are present for the target surface
6. **Log the review** — append to `knowledge-base/decision-log.md` if a claim decision has product-wide implications

## Output
Claim review results are returned directly to the requesting agent (Content or Marketing) via `knowledge-base/agent-requests.md`. Product-wide claim decisions are logged in `knowledge-base/decision-log.md`.

## Principles

1. **Describe the tool, not the outcome**: "[Does specific action] based on [methodology]" is safe. "Will [achieve outcome]" is not. The app is a tool — the user's effort produces results.
2. **FDA exemption is the guardrail**: Every claim must stay within the general wellness lane. If a claim could be read as medical advice, diagnosis, or treatment, it's Red regardless of intent.
3. **Qualification is not weakness**: Hedged language ("designed to support," "may help") builds trust with informed consumers and protects against regulatory action. Overclaiming erodes both.
