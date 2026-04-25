<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->
**First tool call this session: Read `knowledge-base/agent-context/.populated`.** Do not LS/Grep/Glob first — the file is the routing signal.

Route on `.populated` (JSON: `onboarded_at` timestamp-or-null, `agents.<name>` timestamp-or-null):
- `onboarded_at` is a timestamp AND any `agents.*` is null → **existing-project onboarding**. Read `muster/team/pm/skills/generic/reverse-discovery.md` and run it (Phase 1 first). Do NOT run PM bootstrap reads (no decision-log, current-sprint, orchestration-queue, agent-requests) — those are for greenfield/steady-state.
- `onboarded_at` is null → **greenfield**. Read `muster/CLAUDE.md` and follow PM Mode.
- All `agents.*` are timestamps → **steady-state**. Read `muster/CLAUDE.md` and follow PM Mode.
- File missing/invalid → halt: *"Muster setup incomplete. Run `scripts/setup-existing-project.sh --resume` or `scripts/setup-project.sh <name>` at repo root."*
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
