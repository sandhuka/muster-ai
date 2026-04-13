# Product Spec Writing Skill

## Purpose
`knowledge-base/product-spec.md` is the execution-facing source of truth. The research product brief is the "why" — the product spec is the "what exactly." Every specialist agent builds from the product spec. If it's vague, they'll guess. If it's bloated, they'll waste effort on non-MVP work.

## Structure Template

### 1. Product Overview
- Product name
- Tagline
- One-liner description (what it is + who it's for + core differentiator)
- Current version / milestone target

Before detailing features, define the product's core thesis in one sentence: "We believe [target user] will pay for [specific value] if we deliver it via [mechanism]." This bet statement anchors every priority decision in the spec — if a feature doesn't help validate the bet, it's not Must Have.

### 2. Target Users
Summarized from research personas. For each persona:
- Name and archetype
- Demographics (age range, fitness level)
- Core need (one sentence)
- How the product serves them

Keep concise — reference `knowledge-base/research/user-insights.md` for depth.

### 3. MVP Feature Requirements
For each feature:
| Field | Description |
|-------|-------------|
| Feature name | Clear, specific name |
| Description | What it does (2-3 sentences) |
| Acceptance criteria | Bulleted list — how we know it's done correctly |
| Priority | Must Have / Should Have / Nice to Have |
| Effort estimate | S / M / L / XL |
| Dependencies | Other features or agent outputs this requires |

Group features by functional area (e.g., Onboarding, Workout Engine, Content, Progress Tracking).

**Algorithm-driven features** (e.g., routine generation, smart scheduling) require deeper specification beyond the standard feature table. For these, also define: (1) an inputs table listing every variable, its source, and allowed values, (2) constraint rules the algorithm must enforce, with explicit fallback logic for when constraints can't be satisfied, and (3) an output specification describing what the algorithm produces. If QA cannot write a test case for every rule, the spec is not specific enough.

### 4. Content Requirements
- Exercise library specifications (count, disciplines, difficulty levels)
- Clip format and technical specs (resolution, duration ranges, file format)
- Character details (personas, visual style, which discipline each covers)
- Content pipeline requirements (production rate, review process)

**Content-driven products** (where content feeds an algorithm) require additional depth: (1) a metadata schema defining every field each content item must carry (discipline, difficulty, muscle groups, equipment, duration, etc.), (2) minimum coverage requirements per constraint combination the algorithm will encounter — audit the content plan against these before production begins, and (3) persona-discipline mapping validated against the algorithm to ensure no constraint combination yields an empty result set.

### 5. Technical Constraints
- Platform (iOS-first, Native Swift)
- Tech stack decisions and rationale
- Performance requirements (app launch time, animation rendering smoothness, offline capability)
- Device support matrix (minimum iOS version, device models)

### 6. Monetization Model
- Tier structure (free vs. premium)
- Pricing (monthly, annual)
- Paywall logic (what's free, what's gated, when the paywall appears)
- Trial mechanics if applicable

**Freemium products** require deliberate gate design, not afterthought pricing. For each feature, explicitly classify it as Always Free, Soft Gate (previewed then locked), or Hard Gate (premium only). Define paywall trigger rules specifying exactly when and where the paywall appears — tied to value milestones (e.g., after N completed routines), not arbitrary blocks. Spec upgrade moment CTAs at emotional high points (streak completions, post-workout screens) rather than frustration points. The free tier should create a retention habit before conversion pressure begins.

### 7. Success Metrics
From the product brief, with measurement approach added:
| Metric | Target | How to Measure |
|--------|--------|---------------|
| ... | ... | ... |

Define at least one primary metric across all four layers: activation (did the user experience core value?), engagement (is a habit forming?), retention (are they coming back?), and conversion (are free users paying?). Every metric needs a specific numeric target — not "improve over time." Include instrumentation requirements (event name, properties, trigger point) as Developer acceptance criteria so tracking is built in, not bolted on after launch.

### 8. Out of Scope
Explicitly list features, platforms, and capabilities that are NOT in MVP. This prevents scope creep. Include "Should Have" and "Nice to Have" items with a note on when they're planned.

### 9. Unknowns and Assumptions
When research doesn't answer a product question, don't leave the spec silent and don't invent an answer.

For each unknown:
- **State the assumption explicitly**: "Assumption: offline playback is required based on persona research indicating unreliable gym WiFi."
- **Label it**: Mark with `[ASSUMPTION - validate post-launch]` or `[ASSUMPTION - request research]`
- **Flag for research if blocking**: If the unknown affects a Must Have feature, add a research request to `knowledge-base/research/change-log.md` before finalizing that section of the spec.

Unknown ≠ unspecified. The spec must account for every surface the Developer and QA agents will build and test — fill gaps with documented assumptions rather than silence.

### 10. Roadmap Summary
High-level release sequence (MVP → v1.1 → v1.2 → v2.0+). See roadmapping.md skill for detailed guidance.

## Writing Principles
- **Be specific enough to build from.** "User profile" is not a spec. "User profile screen with fields for: goal selection (single-select from 5 options), fitness level (beginner/intermediate/advanced), height, weight, time preference (15/20/30/45/60 min)" is a spec.
- **Every feature has acceptance criteria.** If you can't define "done," the feature isn't ready to assign.
- **Reference research files for context, don't duplicate findings.** Say "See competitive-analysis.md for positioning rationale" instead of copying the competitive analysis.
- **Tables over paragraphs.** Feature lists, metrics, and comparisons are easier to scan in table format.
- **Separate what from how.** Product spec defines WHAT to build. Architecture decisions (HOW) go in `knowledge-base/architecture.md` and are owned by Developer.
- **Write through the persona lens.** Before assigning a feature its priority tier, ask: does the Efficient Professional (28–45, 15–30 min window, decision fatigue) actually need this at launch? "Nice to have for someone" is not a Must Have. Run every feature through the primary persona before locking its tier.
- **The spec is a living document.** When a feature changes, update `product-spec.md` first, then cascade to affected agent-context files (`knowledge-base/agent-context/<agent>.md`). Never let an agent's context be more current than the spec it references.

## Output
`knowledge-base/product-spec.md`
