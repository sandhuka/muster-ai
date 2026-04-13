# Roadmapping Skill

## Purpose
Structure the product roadmap from MVP through future versions. The product brief defines features across Must Have / Should Have / Nice to Have tiers. This skill guides how to sequence them into releases with clear milestones and decision gates.

## Roadmap Structure

### MVP (v1.0)
- Must Have features ONLY. No exceptions.
- Single milestone: "Launch on App Store"
- Ship when ALL acceptance criteria for all Must Have features are met
- Timeline target from brief: 4-6 months
- The goal is to prove the core value proposition works and users trust it

### v1.1–v1.2 (Post-Launch Iteration)
- Should Have features, sequenced by value and dependency order
- Each release is a 2-4 week cycle
- Prioritize features that:
  - Improve retention (offline support, enhanced personalization)
  - Expand addressable market (new platforms)
  - Add high-demand content (new categories)
  - Enable user control (customization features)

### v2.0+ (Platform Expansion)
- Nice to Have features, loosely ordered by strategic value
- Larger scope items: additional platforms, new content categories, companion devices
- Social features and advanced analytics
- Sequence by: strategic value, technical readiness, market demand signals

## Sequencing Principles

1. **Ship the smallest thing that proves the core value prop.** The MVP proves that the core value proposition is compelling enough to retain users and convert them to paid. Every feature in MVP should serve this proof.

2. **Content pipeline and algorithm are parallel workstreams.** Content creation and core algorithm development can progress simultaneously. Plan them as such — they don't block each other until integration testing.

3. **New content categories are content additions, not architectural changes.** The architecture should support adding new content types or categories without code changes beyond the content itself and category-specific rules. Plan content expansion accordingly.

4. **Platform expansion requires architecture decisions upfront even if shipped later.** If Android is planned for v1.1, the data model and API layer should be designed for cross-platform from the start (even if only iOS is built initially). Flag these decisions early for Developer.

5. **User feedback gates between releases.** Don't plan v1.1 features in detail until v1.0 usage data is available. The roadmap beyond MVP is directional, not committed.

## MVP Scoping Heuristics
Must Have features pass ALL three tests:
1. **Core loop test**: Without this, the product's core value proposition cannot be demonstrated. If a user can experience the product's differentiator without it, it's not Must Have.
2. **Retention test**: Without this, a user who completes their first session has no reason to return tomorrow. If it doesn't drive Day 2 retention, it's probably a Should Have.
3. **Launchability test**: Without this, the app cannot be submitted to the App Store or would fail review. Legal compliance, basic onboarding, and payment flow pass this test. Extra disciplines do not.

When in doubt, defer. A Should Have shipped in v1.1 after you've validated the core loop is better than a delayed MVP stuffed with features that dilute the core experience.

## Milestone Definition
Each release milestone should have:

| Field | Description |
|-------|-------------|
| Version | e.g., v1.0 (MVP) |
| Feature list | Specific features included, referencing product-spec |
| Success criteria | Quantitative targets that determine if this release achieved its goal |
| Estimated timeline | Duration from start or calendar target |
| Go/no-go gate | Checklist that must be satisfied before release: (1) All Must Have acceptance criteria met and verified by QA, (2) Legal review complete and sign-off documented, (3) App Store assets complete (screenshots, description, keywords), (4) Founder approval after reviewing QA sign-off, (5) Crash-free rate ≥ 99% on primary device matrix |
| Key risks | Top 2-3 risks specific to this release |

## Roadmap Maintenance
- Update when scope changes, new research lands, or priorities shift
- Log all roadmap changes in `knowledge-base/decision-log.md`
- Re-evaluate post-MVP roadmap after launch data is available
- The roadmap is a living document — directional beyond MVP, specific only for the current release

## Output
Roadmap section within `knowledge-base/product-spec.md` (kept with the spec for single-source reference)
