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
5. **Earns its token weight**: Under 80 lines. Every line must teach something an AI agent wouldn't already know from base training.

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

1. Read the proposed skill content
2. Run it against ALL 5 generic criteria. If any fails, classify as product-specific. No exceptions.
3. If all 5 pass, classify as generic and follow the Skill Contribution Protocol in `system-guide.md`
4. If hybrid, create both versions

## Anti-Patterns (Do NOT add to Muster)

- Checklists for a specific product's launch
- A specific founder's preferences rather than general methodology
- Content an AI agent already knows from training (e.g., "how to write clean code")
- Content that will only be read once and never referenced again
- Skills longer than 80 lines that haven't been split or trimmed

## Principles
- **When in doubt, keep it product-specific.** The cost of a missing generic skill is one project creating it locally. The cost of a bad generic skill is every future project paying the context tax.
- **Extending > creating.** Adding 5 lines to an existing skill beats creating a new 40-line skill that overlaps.
- **The 80-line limit is a hard cap.** If you can't teach the methodology in 80 lines, it's too complex for a single generic skill or should be split.
