# Context Cascading Skill

## Purpose
When cascading product context to specialist agents, tailor what each role needs to know. Each agent should receive filtered, relevant context — not a dump of everything. The goal is to give each agent exactly what they need to do their job without overwhelming them or leaving gaps.

## Per-Agent Context Guide

### Developer
**Needs to know**: What to build and technical constraints.
- Tech stack and architecture constraints (platform, language, framework, backend)
- Core algorithm/logic requirements (key business rules, constraints — from research/validation)
- Content/asset pipeline requirements (file types, delivery mechanism, storage)
- Data model considerations (key entities, relationships, storage strategy)
- Performance requirements (rendering, load time, offline behavior)
- Device/platform support matrix

**Key references**: product-spec.md, architecture.md, relevant research files

### UI/UX Designer
**Needs to know**: Who the users are, what they experience, and the brand's visual identity.
- Target personas with behavioral details (from user-insights.md)
- User journey: onboarding → core experience → progress/retention loop
- Onboarding requirements (what data to collect, how many steps)
- Key flow UX requirements (primary interaction patterns, content display, transitions)
- Visual content direction (characters, imagery, animation style — from brand-guidelines)
- Brand aesthetic direction (from brand-guidelines.md)
- Platform conventions (platform-specific design guidelines)

**Key references**: research/user-insights.md, product-brief.md, brand-guidelines.md

### Content
**Needs to know**: Brand voice, character personalities, and what copy is needed.
- Brand voice and personality traits (from brand-guidelines.md)
- Character/persona backstories and personality traits (from brand-guidelines)
- In-app copy surfaces: onboarding, core feature UI, system messages, notifications, error states
- Naming conventions (consistent terminology across the product)
- Domain messaging tone (how to communicate expertise/credibility without jargon)
- Naming conventions for app sections and features

**Key references**: brand-guidelines.md, research/user-insights.md

### Marketing
**Needs to know**: How to position and sell the product.
- Positioning vs. competitors (from competitive-analysis.md — key differentiators, gaps the product fills)
- Pricing strategy and rationale (from monetization research)
- App Store/marketplace optimization insights (keyword opportunities, category positioning)
- Target personas for acquisition messaging (which persona to target first, where they are)
- Launch strategy considerations (pre-launch, beta, public launch phases)
- Success metrics related to acquisition (downloads, conversion targets)

**Key references**: research/competitive-analysis.md, research/monetization.md, research/app-store-intel.md, research/market-landscape.md

### Legal
**Needs to know**: Compliance and liability requirements.
- Content IP considerations (AI-generated or licensed content ownership)
- Domain-specific liability and disclaimers
- Terms of service scope (subscription billing, content licensing, user data)
- Privacy policy needs (data types collected, sensitivity classification)
- App Store/platform compliance requirements
- Data storage and processing practices

**Key references**: product-brief.md, product-spec.md

### QA
**Needs to know**: What to test and how to validate quality.
- MVP feature scope for test plan creation (from product-spec.md)
- Device/platform matrix (target devices and versions)
- Key user flows to test (from product-spec feature list)
- Acceptance criteria from product-spec.md (the definition of "done" for each feature)
- Content quality validation (asset rendering, accuracy, consistency)
- Performance benchmarks (rendering, responsiveness, load times)

**Key references**: product-spec.md, test-strategy.md

## Cascading Principles

0. **All PM-managed content lives in agent-context files**: Product context, current tasks, and cross-agent dependencies are updated in `knowledge-base/agent-context/<agent>.md`, not in agent brain files (`muster/team/<agent>/CLAUDE.md`). Brain files contain role definition, skills, and reference doc lists — they are framework-level and rarely change.

1. **Filter for relevance**: Developer doesn't need marketing strategy. Marketing doesn't need data model details. Each agent should receive only what's actionable for their role.

2. **Include references to source docs**: Instead of copying entire sections, say "See knowledge-base/research/competitive-analysis.md for detailed competitor teardowns." This lets agents go deeper when needed without bloating their context.

3. **Always update cross-agent dependencies on BOTH sides**: If Developer depends on UI/UX for design specs, update BOTH agents' Cross-Agent Dependencies sections.

4. **Cascade in dependency order**: Update upstream agents first so their outputs are available when downstream agents start:
   - **First wave**: UI/UX (design direction), Content (voice and copy), Legal (compliance requirements)
   - **Second wave**: Developer (needs design specs from UI/UX), Marketing (needs brand voice from Content)
   - **Third wave**: QA (needs feature specs from Developer, content from Content)

5. **Keep PM-MANAGED sections concise**: Use bullet points, not paragraphs. Link to docs instead of duplicating. Each agent's Product Context should be 10-20 lines max.

6. **Verify completeness**: After cascading, review each agent's agent-context file to confirm they have enough context to begin their assigned tasks without needing to ask clarifying questions.

## Post-Cascade Verification Checklist
After updating all agent-context files, run this check before closing the cascade:

- [ ] Each agent's Product Context reflects the current state of `product-spec.md` — no references to deprecated features or old priorities
- [ ] Every cross-agent dependency appears in BOTH the providing and receiving agent's file
- [ ] No agent's file contains information that belongs exclusively to another agent's domain (e.g., Developer doesn't have marketing strategy in their context)
- [ ] Each agent has enough context to begin their assigned tasks without needing to ask the PM a clarifying question
- [ ] `knowledge-base/current-sprint.md` reflects the same task list as each agent's agent-context file (`knowledge-base/agent-context/<agent>.md`) Current Tasks section
- [ ] `decision-log.md` has an entry for any context change driven by a product decision

If any item fails: fix the gap before declaring the cascade complete.

## Cascade Lag Prevention Protocol
Run this after EVERY product decision, not just after full cascades. Cascade lag happens when a decision updates the product spec and decision log but agent files still reference the old state.

### Per-Decision Quick Audit (2 minutes)
After logging a decision in `decision-log.md`, immediately check:

1. **Keyword scan (mandatory)**: Identify the key terms that changed (e.g., "video clips" became "looping animations," "iOS + Android" became "iOS-first," "breathwork" was removed). Grep the FULL repository for the OLD terms — not just agent files. Record the grep results in the decision-log entry's Touched field so there is an audit trail. If a file contains the old term but does not need updating (e.g., historical/archival), note it as "reviewed, no change needed."
2. **Agent Product Context**: For each affected agent listed in the decision's "Impact" field, re-read their Product Context section. Does it still describe the old state? Fix it.
3. **Agent Current Tasks**: If the decision changes task scope or adds/removes tasks, update the affected agent's agent-context file (`knowledge-base/agent-context/<agent>.md`) Current Tasks and `current-sprint.md`.
4. **Skills files**: Check PM skills files (context-cascading.md, roadmapping.md, sprint-planning.md) for references to the old state. These are easy to miss because they feel "stable."
5. **Cross-references**: If the decision changes feature IDs, feature names, or tier assignments, grep for the old values across all agent files.
6. **Active handoffs**: Check `knowledge-base/agent-requests.md` for active handoffs affected by this decision. If a decision changes a deliverable that is currently in-review, add a revision log note to the handoff entry so reviewers know the deliverable has changed.

### Common Lag Patterns to Watch For
- Completed PM tasks still listed as pending (task list not cleaned up after finishing work)
- Research agent Product Context not updated after product spec refinements (Research finished discovery but context was never refreshed)
- Old media format references surviving after format decisions (e.g., "video clips," "AVFoundation," "clip stitching")
- Removed features/disciplines still mentioned in agent context (e.g., "breathwork," "tvOS" if descoped)
- Old pricing or tier assignments persisting after monetization changes

### Research File Cascade
Research files (`knowledge-base/research/*.md`) are owned by the Research agent — PM cannot edit them directly. When the keyword scan surfaces stale terminology in research files, PM must add an entry to `knowledge-base/research/change-log.md` with `status: needs-research` listing the specific files and terms to update. This is the only PM-to-Research communication channel.

### Enforcement
The "Touched" field in each decision log entry forces enumeration of every file modified. If an agent file should have been touched but is missing from the list, the update was likely missed. Review the "Touched" list against the "Impact" list -- every impacted agent should have a corresponding file touch.
