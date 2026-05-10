<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->
**First tool call this session: Read `knowledge-base/agent-context/.populated`.** Do not LS/Grep/Glob first — the file is the routing signal.

Route on `.populated` (JSON: `onboarded_at`, `onboarding_complete_at`, `agents.<name>` — each timestamp-or-null):
- `onboarded_at` is a timestamp AND `onboarding_complete_at` is null → **existing-project onboarding active**. Skip role-picker; force-bind PM. Read `muster/team/pm/skills/generic/reverse-discovery.md` and run it (Phase 1 first). Do NOT run PM monitoring-duty reads (no decision-log, current-sprint, orchestration-queue, agent-requests) — those are for greenfield-ongoing/steady-state.
- `onboarded_at` is null AND `agents.pm` is null → **greenfield first session**. Skip role-picker; force-bind PM. Read `muster/team/pm/skills/generic/greenfield-discovery.md` and fire Stage 1 welcome. Do NOT skip the welcome — first impression matters.
- `onboarded_at` is null AND `agents.pm` is a timestamp → **greenfield ongoing** (Discovery in progress or post-Sprint-1 work). Read `muster/CLAUDE.md` and follow Role Binding (Explicit) — the role-picker fires after this routing check. Do NOT read `greenfield-discovery.md` again — welcome already shown.
- `onboarded_at` AND `onboarding_complete_at` both timestamps → **steady-state** (existing-project, post-onboarding; regardless of individual `agents.*` state — null entries trigger JIT populate, NOT re-onboarding). Read `muster/CLAUDE.md` and follow Role Binding (Explicit) — the role-picker fires after this routing check. Do NOT read `reverse-discovery.md`.
- File missing/invalid → halt: *"Muster setup incomplete. Run `scripts/setup-existing-project.sh --resume` or `scripts/setup-project.sh <name>` at repo root."*
<!-- END BOOTSTRAP -->

# [Project Name]

## Muster Framework

Multi-agent framework. Every Claude Code session picks ONE role at session start via the role-picker (or `MUSTER_ROLE` env var). All eight roles — PM, Developer, UI/UX, QA, Content, Marketing, Legal, Research — are peer roles bound the same way. PM coordinates; specialists do domain work; subagent invocation via `Agent({subagent_type: "<role>"})` is available for parallel/throwaway work.

Authoritative rules, role binding, agent protocols: `muster/CLAUDE.md`. System guide, agent roster, skill index: `muster/system-guide.md`. This file holds only project-specific content (sections below).

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
