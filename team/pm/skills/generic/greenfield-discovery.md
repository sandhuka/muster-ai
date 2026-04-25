# Greenfield Discovery

## Purpose

Procedural methodology for PM to conduct greenfield (new product from zero) onboarding — the forward complement to `reverse-discovery.md`. Greenfield Discovery is **multi-session by design** (founder shares idea → invokes Research separately → returns to PM for evaluation → drafts → Sprint 1 plan), spread across ~3 sessions over a day or two. Total founder-attended time: ~1-2 hours.

This skill governs the **first** session's welcome + Stage 1 idea capture, and the **post-Research evaluation session** (Stages 3-5). Stage 2 (Research) is handled by the Research agent — see `team/research/skills/generic/product-validation.md`.

See `team/pm/skills/generic/product-evaluation.md` for the Stage 3 scoring rubric. See `team/pm/skills/generic/sprint-planning.md` for the Stage 5 sprint planning this skill hands off to.

## When This Skill Runs

PM reads this skill when:
1. At session start, PM reads `knowledge-base/agent-context/.populated` and finds `onboarded_at: null` AND `agents.pm: null` → **greenfield first session, fire welcome**.
2. After Research returns and the founder asks for evaluation → continue from Stage 3.

**Do not silently skip, do not improvise.** Welcome is non-skippable for the first greenfield session.

## User-Facing Stage Numbering

Greenfield Discovery has **5 user-visible stages** spread across multiple sessions. Use **Stage 1-5** in announcements, not internal phase or session numbers.

| Stage | Founder-attended time | Session | Annotation |
|-------|-----------------------|---------|------------|
| Stage 1: Idea share | ~10 min | Session 1 | *highest leverage* |
| Stage 2: Market research | ~15-30 min (Research) | Session 2 (separate) | *mostly waiting* |
| Stage 3: Go/no-go decision | ~10 min | Session 3 | *your focus* |
| Stage 4: Draft review | ~15 min | Session 3 (continued) | *read & confirm* |
| Stage 5: Sprint 1 plan | ~5 min | Session 3 (continued) | *quick decision* |

Stage transitions follow the same format as existing-project (mirror visual rhythm of the setup script):

```
---
## ✓ Stage [N-1]: [Name] complete
[1-line summary]
---
## Stage N: [Name] (~[time] · [annotation])
[Stage intro / instruction]
```

## Stage 1: Welcome + Idea Share (Session 1)

### 1.1 Deliver welcome verbatim

Render this markdown block as the very first response. Founder will see this BEFORE PM does any other work. Format is intentional — Claude Code renders the markdown for visual hierarchy.

> # ✨ Welcome — let's bring your idea to life
>
> Over the next few sessions (typically **3 sessions across a day or two**), we'll go from your raw product idea to a Sprint 1 plan with your AI team ready to build. I'm Claude, acting as your product manager — I coordinate the specialist agents (Developer, UI/UX, QA, Content, Marketing, Legal, Research) and handle planning, decisions, and cross-agent context.
>
> ## What you're getting
>
> Seven specialists — **Developer, UI/UX, QA, Content, Marketing, Legal, Research** — coordinated by me as your product manager. Every decision logged. Every sprint planned. No re-explaining your product to a fresh AI chat ever again.
>
> **Why it's worth the time:** every sprint after Discovery is fast. The agents already know your product. You spend your time shipping, not re-onboarding.
>
> ## How Discovery works (5 stages)
>
> - **Stage 1 — Idea share** (~10 min · this session) · *Highest leverage* — Tell me about your product idea: what problem, who it's for, why now.
> - **Stage 2 — Market research** (~15-30 min · separate session) · *Mostly waiting* — You'll invoke `@research`. Research investigates market, competitors, users.
> - **Stage 3 — Go/no-go decision** (~10 min · session 3, after Research returns) · *Your focus* — I score the research on 6 dimensions and recommend GO / CONDITIONAL / NO-GO.
> - **Stage 4 — Draft review** (~15 min · same session as Stage 3) · *Read & confirm* — I draft product-spec, brand-guidelines, foundational-assumptions. You read and approve.
> - **Stage 5 — Sprint 1 plan** (~5 min · same session) · *Quick decision* — You name the first feature; I plan Sprint 1.
>
> ## One thing before we begin
>
> In Stage 3, I evaluate the research with a 6-dimension scoring rubric. If the score isn't high enough or there's missing signal, I'll recommend CONDITIONAL (do more research) or NO-GO (rethink the idea) rather than rubber-stamping a GO. Slow-down moments may save you weeks.
>
> **Privacy note:** what you share now goes into `knowledge-base/research/product-brief.md` (tracked in git by default). If your idea includes sensitive material — competitor analysis, partnership details, internal model specifics — scrub it before sharing, or tell me to keep specific details out of the brief.
>
> ---
>
> **Ready?** Just describe your product idea — what it does, who it's for, what's broken about today's solutions. The more you share, the sharper the research will be.

### 1.2 Capture the idea

Wait for founder's response. They'll describe their product idea. Capture verbatim into `knowledge-base/research/product-brief.md` Founder's Idea section. Write the founder's full description — do not summarize. The Research agent reads this section as the input to investigation; lossy summarization here costs Research signal downstream.

If the founder pastes URLs, doc references, or markdown files, ingest them into the brief alongside the verbatim description (clearly marked as "Linked materials:").

### 1.3 Set agents.pm timestamp

After capturing the founder's idea, update `.populated.agents.pm` to the current ISO-8601 timestamp. **This is the load-bearing routing signal** — it tells future sessions "PM has engaged with this project" so the welcome doesn't fire again.

Verify the JSON is valid before finalizing.

### 1.4 Queue Research

- Write a `change-log.md` entry in `knowledge-base/research/change-log.md` with `status: needs-research` referencing the seeded brief.
- Add a Research step to `knowledge-base/orchestration-queue.md` with the prompt: "Read `knowledge-base/research/product-brief.md` Founder's Idea section. Conduct full discovery research per `team/research/skills/generic/product-validation.md`. Update brief, market-landscape, competitive-analysis, user-insights. Set change-log entry to `status: researched` when complete."

### 1.5 Hand off to founder

Tell the founder: *"I've captured your idea. Stage 2 starts when you invoke `@research` — that's a separate Claude Code session. Research will take 15-30 minutes; you can grab coffee. When Research finishes, come back to me and ask 'how did the research go?' or 'evaluate the research.' I'll pick up from Stage 3."*

End Session 1 cleanly. Do NOT continue into Stage 2 — Research is a separate agent invocation that the founder triggers.

## Stage 2: Market Research (Session 2 — Research-owned)

PM does not run this stage. Founder invokes `@research` directly. Research reads the seeded brief and conducts investigation per `team/research/skills/generic/product-validation.md`.

PM is NOT in the loop during Stage 2. This is by design — keeps Research focused, keeps PM context clean.

When Research sets `status: researched` in `change-log.md`, Stage 2 is done.

## Stage 3: Go/No-Go Decision (Session 3, part 1)

When the founder returns to PM and asks about evaluation (or simply says "what's next"):

### 3.1 Detect Stage 3 entry condition

Check `knowledge-base/research/change-log.md` for `status: researched` entry. If present → enter Stage 3. If still `needs-research` → tell the founder Research hasn't completed yet.

### 3.2 Announce Stage 3 transition

```
---
## ✓ Stage 2: Market research complete
Research delivered: product-brief, market-landscape, competitive-analysis, user-insights.
---
## Stage 3: Go/no-go decision (~10 min · your focus)
```

### 3.3 Run product evaluation

Use `team/pm/skills/generic/product-evaluation.md` 6-dimension scoring rubric. Read all Research outputs. Produce GO / CONDITIONAL / NO-GO recommendation with explicit reasoning per dimension.

Present to founder. Founder decides — accept, push back on a dimension, or reject. Log the decision in `decision-log.md`.

If CONDITIONAL or NO-GO and founder accepts: handle accordingly (more Research, or pivot/rethink). Skill ends here for this session.

If GO: proceed immediately to Stage 4.

## Stage 4: Draft Review (Session 3, part 2)

### 4.1 Announce Stage 4 transition

```
---
## ✓ Stage 3: Go/no-go decision complete
Recommendation: GO. Decision logged.
---
## Stage 4: Draft review (~15 min · read & confirm)
```

### 4.2 PM writes drafts

- `knowledge-base/product-spec.md` — using `team/pm/skills/generic/product-spec-writing.md`. Inputs: Founder's Idea + Research findings.
- `knowledge-base/brand-guidelines.md` — using `team/pm/skills/generic/brand-guidelines.md`. Inputs: brand-relevant content from Research + idea share.
- `knowledge-base/foundational-assumptions.md` — current-truth assumptions only. See "Foundational Assumptions Authoring" in `reverse-discovery.md` Phase 8.3 (same pattern).

### 4.3 Founder review

Present the three drafts for founder read-through. Edit invitation, not per-item forcing. Founder largely contributed via idea share + Research, so review is a sanity check.

### 4.4 Populate project root `CLAUDE.md` placeholders

After founder approves drafts, fill in placeholders in the project root `CLAUDE.md`. The setup script copied `templates/CLAUDE.md` to `<project-root>/CLAUDE.md`, but the `## Product Information` section still has `[Project Name]`, `[Tagline]`, etc. Future sessions auto-load this file — leaving placeholders means every session reads incomplete product context.

Edit only the section between the `## Product Information` heading and the `<!-- Add shared UI library...` comment. Do NOT touch the bootstrap block at the top (between `<!-- MUSTER BOOTSTRAP -->` and `<!-- END BOOTSTRAP -->`) or the framework pointer section.

Source mapping for each placeholder:

| Placeholder | Source |
|---|---|
| `# [Project Name]` (the H1) | Project name from `product-spec.md` |
| `**Product**: [Name] — "[Tagline]"` | Product name + tagline from `product-spec.md` |
| `[2-3 sentence product description]` | Overview from `product-spec.md` |
| `**Platforms / surfaces**` | From `product-spec.md` |
| `**Tech stack**` | From `product-spec.md` (initial choices) — TBD if not yet decided |
| `**Target user**` | From `product-spec.md` |
| `**Monetization**` | From `product-spec.md` |
| `**Team model**` | Default "Solo founder + AI agents" |

After populating, surface a one-line confirmation: *"Updated your project root CLAUDE.md with the product info we just synthesized."*

## Stage 5: Sprint 1 Plan (Session 3, part 3)

### 5.1 Announce Stage 5 transition

```
---
## ✓ Stage 4: Draft review complete
Product spec, brand guidelines, and foundational assumptions approved. Project CLAUDE.md populated.
---
## Stage 5: Sprint 1 plan (~5 min · quick decision)
```

### 5.2 Cascade context to Sprint 1 agents

Use `team/pm/skills/generic/context-cascading.md` methodology. Populate agent-context files **only for the agents needed for Sprint 1** — typically Developer + UI/UX + QA + Content for product-with-UI projects. Other agents stay `null` and populate lazily at first invocation.

After writing each populated agent-context file, set the agent's timestamp in `.populated`.

### 5.3 Sprint 1 planning

Use `team/pm/skills/generic/sprint-planning.md`. Ask the founder: *"What's the first feature/task you want to tackle? I'll plan Sprint 1 around it."* Populate `knowledge-base/current-sprint.md` and `knowledge-base/orchestration-queue.md` with 3-5 steps.

### 5.4 Close Discovery

Tell the founder: *"Discovery complete. Your queue is in `orchestration-queue.md` — first task is `<feature>`. Open the queue, copy the next prompt, invoke the listed agent."*

End the session. From this point on, the project is in steady-state greenfield: future sessions take normal PM Mode bootstrap, no welcome, no Discovery flow.

## Edge cases and design rationale

1. **Why fire welcome via `agents.pm: null` instead of a separate flag?** Reuses the existing field. After PM seeds the brief in Stage 1.3, it sets its own timestamp — natural transition from "first session" to "subsequent." No new schema field needed.

2. **Why is greenfield Discovery multi-session?** Research takes 15-30 minutes of Claude tool-use that we don't want to block PM's session on. Separating Stage 2 also keeps Research's context clean — it doesn't see PM's welcome or Stages 1/3-5 work.

3. **What if founder skips the welcome by typing their idea first?** Welcome still fires before PM responds. PATH B-fresh routes through this skill before any other action. The founder's first message is captured as the idea after the welcome renders.

4. **What if founder closes Claude mid-Stage-1 (after welcome but before idea capture)?** `agents.pm` is still null (PM hadn't completed Stage 1.3 yet). Next session re-fires welcome. Slightly redundant but recoverable. Cost: ~200 words of welcome.

5. **What if the founder's idea is shared in fragments across multiple messages?** Capture each fragment into the Founder's Idea section. Set `agents.pm` timestamp only after the founder signals they're done sharing (e.g., "that's everything" or stops sharing).

6. **Greenfield does not have an `onboarding_complete_at` equivalent.** Steady-state is "PATH B-ongoing" (greenfield, agents.pm set). There's no archive cleanup because greenfield has no `.muster-onboarding/` transient directory — `product-brief.md` and the other research files live in `knowledge-base/research/` permanently.
