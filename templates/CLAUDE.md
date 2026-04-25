<!-- MUSTER SYSTEM BOOTSTRAP — DO NOT REMOVE -->

# SESSION-START PROTOCOL — EXECUTE BEFORE RESPONDING TO ANY USER MESSAGE

**The very first tool call you make in this session MUST be Read on
`knowledge-base/agent-context/.populated`.** Do not LS, Grep, Glob, or
read any other file first. Do not infer state from the user's message
or project name. The state file tells you what to do.

## STEP 1 — Read `.populated`

Read `knowledge-base/agent-context/.populated`. It is JSON with:
- `onboarded_at`: ISO-8601 timestamp OR null
- `agents.<name>`: ISO-8601 timestamp OR null, for each specialist

## STEP 2 — Match `.populated` to exactly one path and follow it

Pick one path. Each path's Reads list is complete — read those files
and only those files during bootstrap. Each path's "Do NOT read" list
is blocking — those files are for other paths.

### PATH A — existing-project onboarding (reverse discovery)
**When:** `onboarded_at` is a non-null timestamp AND at least one value
under `agents.*` is `null`.
**Reads (in order):**
  1. `muster/CLAUDE.md`
  2. `muster/team/pm/skills/generic/reverse-discovery.md`
**Then:** start reverse-discovery Phase 1 (orientation) immediately.
Run the 11 phases end-to-end with the user.
**Do NOT read:** `decision-log.md`, `current-sprint.md`,
`orchestration-queue.md`, `agent-requests.md`, `ui-component-requests.md`,
`research/change-log.md`, `product-spec.md`, `getting-started.md`,
`adopting-existing-project.md`, or any other docs. Reverse-discovery
has its own reads inside the skill file; PM monitoring files are for
greenfield/steady-state only and do not exist meaningfully yet.

### PATH B — greenfield project
**When:** `onboarded_at` is `null`.
**Reads:** `muster/CLAUDE.md`, then follow PM Mode "First PM question
in a session" bootstrap list inside that file.

### PATH C — steady-state (either path, post-onboarding)
**When:** every value under `agents.*` is a non-null timestamp.
**Reads:** `muster/CLAUDE.md`, then follow PM Mode "First PM question
in a session" bootstrap list.

### PATH D — setup incomplete
**When:** `.populated` does not exist, is empty, or is not valid JSON.
**Action:** halt and respond: *"Muster setup appears incomplete. From
the repo root, run `scripts/setup-existing-project.sh --resume` (if
adopting) or `scripts/setup-project.sh <name>` (if greenfield)."*
Do not proceed.

## What NOT to do at session start

- Do **not** LS/Grep/Glob the project to "figure out" whether this is
  existing-project or greenfield. `.populated` already tells you.
- Do **not** read `getting-started.md`, `adopting-existing-project.md`,
  `system-guide.md`, or `architecture-and-design.md` during routing.
  Those are user-facing docs, not routing inputs.
- Do **not** start PM bootstrap reads (decision-log, current-sprint,
  orchestration-queue, etc.) on PATH A — reverse-discovery is a
  self-contained flow.
<!-- END BOOTSTRAP -->

# [Project Name]

## Muster Framework

Multi-agent framework coordinated by Root Claude (acting as PM). Specialist agents — Developer, UI/UX, QA, Content, Marketing, Legal, Research — invoked via Task tool with `subagent_type="<agent>"`.

Authoritative rules, PM mode, agent protocols: `muster/CLAUDE.md`. System guide, agent roster, skill index: `muster/system-guide.md`. This file holds only project-specific content (sections below).

## Product Information

**Product**: [Name] — "[Tagline]"
[2-3 sentence product description]

- **Platforms / surfaces**: [iOS / Android / Web / Backend / Desktop / CLI / library / etc.]
- **Tech stack**: [Languages, frameworks, key dependencies]
- **Target user**: [Brief persona description]
- **Monetization**: [Model — free / freemium / subscription / paid / other / not yet]
- **Team model**: [Solo founder + AI agents / Small team + AI agents]

See `knowledge-base/product-spec.md` for full spec, `knowledge-base/brand-guidelines.md` for brand, `knowledge-base/current-sprint.md` for sprint status.

<!-- Add shared UI library, design system, or other cross-cutting technical details below if they affect multiple agents. -->

## Project-Specific Rules

<!-- Rules that replace, add to, or are orthogonal to Muster framework rules.
     Do NOT copy framework rules here — they live in muster/CLAUDE.md. Empty section = default behavior.
     Format each as current-truth ("Rule X (this project): ..." / "[Preference]: ..."). No archaeology.
     Examples: "Rule 9 (this project): shared UI components go through design-system review";
     "Package manager: pnpm"; "Testing: new endpoints require integration + unit tests". -->
