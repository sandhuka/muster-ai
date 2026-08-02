# Skill Gap Classification

## Purpose
When PM identifies a missing skill during the sprint planning skill gap scan (Step 9), this skill provides strict criteria for classifying it as generic (belongs in the Muster framework) or product-specific (belongs in the project's `knowledge-base/agent-skills/<agent>/` directory). See `sprint-planning.md` for the scan that triggers this skill.

The bar for generic inclusion is intentionally high — Muster's value depends on minimal context waste, and every generic skill added increases the framework's token footprint for all future projects.

## Classification Criteria

### Generic (Muster Framework) — ALL must be true:

1. **Cross-product applicability**: Useful across at least 3 product types (web apps, native mobile, backend services, B2B platforms, SaaS, marketplaces, consumer apps).
2. **Domain-neutral language**: Zero references to product-specific entities, industries, technologies, or workflows. Teaches a process that works regardless of what's being built.
3. **Repeatable process**: Describes methodology applied multiple times across a product's lifecycle or across projects — not a one-time solution.
4. **Not already covered**: No existing generic skill covers this methodology, even partially. If an existing skill covers 70%+, extend that skill instead.
5. **Earns its token weight**: Every line must teach something an AI agent wouldn't already know from base training. Aim for ~80 lines; a skill that needs far more is usually bundling more than one methodology.

### Product-Specific (Project Directory) — ANY is true:

1. References product-specific entities, domain terms, or industry concepts
2. Only applies to a specific tech stack, platform, or architecture
3. Solves a problem unique to this project's constraints, timeline, or team
4. Would require significant rewriting to be useful for a different product

### Hybrid Case — Generic Pattern, Product Implementation

Sometimes a product skill reveals a generic pattern:
1. Extract the generic methodology into a framework skill (strip all product references)
2. Keep the product-specific implementation in the project directory
3. The product skill references the generic skill for methodology and adds product-specific details on top

## Decision Process

This runs during the dedicated "PM: Create missing skills" orchestration queue step — not during sprint planning. Sprint planning only flags gaps; this skill handles the actual creation and classification.

1. **Draft generic first.** Write the skill using platform-neutral language with no project-specific references. The PM will be steeped in project context — resist that pull. If the methodology can be expressed generically, it should be, even if the immediate need came from a specific project. Only add project-specific content if the methodology itself is inherently domain-specific.
2. Run the generic draft against ALL 5 generic criteria. If any fails, classify as product-specific. No exceptions.
3. If all 5 pass, classify as generic and follow the Skill Contribution Protocol in `system-guide.md`
4. If hybrid, create the generic version first, then a product skill that references it
5. **Follow existing skill protocols.** Use the skill file template, quality checklist, and registration steps from `system-guide.md` → "Adding a New Skill." For platform-specific skills, use the established prefix convention (`ios-`, `backend-`, `web-`) and place in the matching subdirectory (`skills/ios/`, `skills/backend/`, `skills/web/`). If the target platform subdirectory doesn't exist, create it before writing the skill file. In the skill's body, cite other skills **by name, never by path** (``the `<name>` skill``, or ``<Role>'s `<name>` skill`` when the name exists under multiple roles) — `muster-lint-refs.sh` enforces this at registration.

## Tooling and Framework Findings Route Upstream First

This skill's five criteria apply to TOOLING the same as to skills: a script, lint, or protocol
change that would help any project belongs to the framework, not to `tools/` in one repo. The
routing rule (field failure: a working plan-lint built locally, stranding the value in one
project): a framework-shaped finding goes to the project's retrospective/friction report FIRST,
so the core team can land it in muster and every project inherits it on update. Building a
local workaround is permitted when the project cannot wait — but the retrospective entry must
then describe the workaround in enough detail (checks, exemptions, placement constraints) for
the core team to adopt or reject it rather than rediscover it. A local tool that never gets
routed upstream is a finding lost.

## Anti-Patterns (Do NOT add to Muster)

- Checklists for a specific product's launch
- A specific founder's preferences rather than general methodology
- Content an AI agent already knows from training (e.g., "how to write clean code")
- Content that will only be read once and never referenced again
- Sprawling skills that bundle several methodologies — split along the real seams before promoting

## Principles
- **When in doubt, keep it product-specific.** The cost of a missing generic skill is one project creating it locally. The cost of a bad generic skill is every future project paying the context tax.
- **Extending > creating.** Adding 5 lines to an existing skill beats creating a new 40-line skill that overlaps.
- **Skill size is budget-gated, not capped per file.** ~80 lines is the split heuristic (one methodology per skill); the mechanical floor is `test-pillar-budgets.sh` — each role's skills tree has a line budget that is green at its current size and red on growth, so bloat is caught at contribution time, not by an honor-system number.
