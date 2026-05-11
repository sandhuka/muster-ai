<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->
**First tool call this session: Read `knowledge-base/agent-context/.populated`.** Do not LS/Grep/Glob first — the file is the routing signal.

Route on `.populated` (JSON: `onboarded_at`, `onboarding_complete_at`, `agents.<name>` — each timestamp-or-null):
- `onboarded_at` is a timestamp AND `onboarding_complete_at` is null → **existing-project onboarding active**. First, write the bind file via Bash: `mkdir -p .claude && echo "pm" > .claude/.muster-bound-role.$CLAUDE_CODE_SESSION_ID` (so the status line shows `[muster: pm]` during onboarding). Then read `muster/team/pm/skills/generic/reverse-discovery.md` and run it (Phase 1 first). No picker. Do NOT load `.claude/agents/pm.md` — onboarding is self-contained in the discovery skill.
- `onboarded_at` is null AND `agents.pm` is null → **greenfield first session**. First, write the bind file via Bash: `mkdir -p .claude && echo "pm" > .claude/.muster-bound-role.$CLAUDE_CODE_SESSION_ID` (so the status line shows `[muster: pm]` during the welcome). Then read `muster/team/pm/skills/generic/greenfield-discovery.md` and fire Stage 1 welcome. No picker. Do NOT load `.claude/agents/pm.md` — the discovery skill drives PM behavior through Stage 1.3.
- `onboarded_at` is null AND `agents.pm` is a timestamp → **greenfield ongoing**. Read `muster/CLAUDE.md` and follow Role Binding. **CRITICAL**: before firing the picker, run Bash `echo "${MUSTER_ROLE:-UNSET}"` to check the env var per Role Binding step 1 — if set to a valid role, skip picker entirely. Do NOT re-read `greenfield-discovery.md`.
- `onboarded_at` AND `onboarding_complete_at` both timestamps → **steady-state** (null `agents.*` entries trigger JIT populate, NOT re-onboarding). Read `muster/CLAUDE.md` and follow Role Binding. **CRITICAL**: before firing the picker, run Bash `echo "${MUSTER_ROLE:-UNSET}"` to check the env var per Role Binding step 1 — if set to a valid role, skip picker entirely. Do NOT read `reverse-discovery.md`.
- File missing/invalid → halt: *"Muster setup incomplete. Run `scripts/setup-existing-project.sh --resume` or `scripts/setup-project.sh <name>` at repo root."*
<!-- END BOOTSTRAP -->

# [Project Name]

## Muster Framework

Multi-agent framework. Every session picks ONE role at start (picker or `MUSTER_ROLE` env var). Roles: PM, Developer, UI/UX, QA, Content, Marketing, Legal, Research. PM coordinates; specialists do domain work; `Agent({subagent_type: "<role>"})` for parallel/throwaway work.

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
