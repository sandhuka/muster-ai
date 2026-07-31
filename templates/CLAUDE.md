<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->
**First tool call this session: `bash muster/scripts/muster-boot.sh`.** No reads, LS, Grep, or Glob first — the script routes, binds, and prints exactly one `ROUTE=` directive. Obey it literally: read only the file its `READ=` names, relay any `MSG=` halt verbatim, and on `ROUTE=pick` run the two-step role picker from the printed `GROUP=` lines then run the `AFTER_PICK=` command. Full route contract: `muster/CLAUDE.md` → Role Binding.
<!-- END BOOTSTRAP -->

# [Project Name]

## Muster Framework

Multi-agent framework. Every session picks ONE role at start (picker or `MUSTER_ROLE` env var). Roles: PM, Developer, UI/UX, QA, Content, Marketing, Legal, Research. PM coordinates; specialists do domain work; `Agent({subagent_type: "<role>"})` for parallel/throwaway work.

Authoritative rules, role binding, agent protocols: `muster/CLAUDE.md`. System guide, agent roster, skill index: `muster/system-guide.md`. This file holds only project-specific content (sections below).

**Framework guide**: `/muster` — setup, modes, knobs, stuck runs, upgrades.

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
