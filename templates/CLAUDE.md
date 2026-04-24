<!-- MUSTER SYSTEM BOOTSTRAP — DO NOT REMOVE -->
**Before responding to any message, read `muster/CLAUDE.md` first** (authoritative framework rules, PM mode, agent protocols; do not copy into this file).

**If `muster/CLAUDE.md` does not exist**: submodule is uninitialized. Run `git submodule update --init muster` at repo root, then re-open this session. Muster cannot operate without the submodule.
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
