# System Guide

Reference material for extending and operating the multi-agent system. Read this file on-demand when performing the tasks described below.

## Agent Brain Template (`team/<agent>/CLAUDE.md`)

Every agent brain file in Muster follows this structure:
- **Role**: 2-3 sentence role definition
- **Cross-Agent Dependencies**: Generic role relationships (what this agent waits on or provides to other agents — applies to ANY project)
- **Available Skills**: Index of skill files in `team/<agent>/skills/{generic,platform}/`
- **Reference Documents**: Links to project-relative knowledge-base/ files the agent reads on demand

Agent brain files contain NO product-specific content. Product context is provided per-project via `knowledge-base/agent-context/<agent>.md`.

## Agent-Context Template (`knowledge-base/agent-context/<agent>.md`)

Per-project filtered context for each agent. PM-managed. Every agent-context file has these standard sections:
- **Product Context**: Filtered product information relevant to this agent's role (varies by agent — Developer gets tech stack/architecture, Marketing gets positioning/metrics, etc.). Includes key references (product-specific file pointers) as bullet points at the end.
- **Current Tasks**: Full sprint task specs (deliverable, priority, effort, dependencies, acceptance criteria, key skills, key refs). PM updates at sprint planning and task completion. Tasks must be self-contained — an agent should be able to work from just its agent-context file.
- **Agent-Specific Context** (optional): Agent-owned notes (e.g., Legal's skill backlog)

Size varies by role:
- **Developer, QA** (~40-80 lines + tasks): Tech stack, architecture, data model, feature mapping, testing requirements, UI library workflow
- **UI/UX** (~30-50 lines + tasks): Target user, design system, content approach, navigation, monetization UX
- **Content, Marketing, Legal, Research** (~15-30 lines + tasks): Brand context, target user, positioning, compliance scope

See `templates/knowledge-base/agent-context/` for section templates per agent.

## System Extensibility

### Adding a New Agent

#### Registration Points (all must be updated)

| # | File | What to add |
|---|------|-------------|
| 1 | `muster/team/<name>/CLAUDE.md` | Agent brain file (template above) |
| 2 | `muster/team/<name>/skills/` | Domain skill files organized by platform |
| 3 | Project `.claude/agents/<name>.md` | Startup config (template below) |
| 4 | `muster/CLAUDE.md` — Agent Roster table | New row with name, brain file path, responsibility |
| 5 | `muster/CLAUDE.md` — Sub-Agent Access line | Add `@<name>` to the list |
| 6 | Project `knowledge-base/agent-context/<name>.md` | Filtered product context for this role |

#### Startup Config Template (`.claude/agents/<name>.md`)

```markdown
---
name: <name>
description: "<one-line role description>"
tools: Read, Write, Edit, Grep, Glob, Bash
---

You are the <Name> agent for this project.

**Always read on startup** (lightweight, essential):
1. muster/CLAUDE.md (system rules, protocols, communication standards)
2. muster/team/<name>/CLAUDE.md (your role definition + skill index)
3. knowledge-base/agent-context/<name>.md (filtered product context for your role)
4. knowledge-base/orchestration-queue.md (check if there is a step assigned to you — that is your primary task)
5. knowledge-base/agent-requests.md (check for requests to you, handoffs needing your review, and your handoffs needing revision)

**Session completion**: After completing your task, update `knowledge-base/orchestration-queue.md` — move your step to Done with a one-line summary (if Done exceeds 5 entries, remove the oldest first), then move the next upcoming step to Next Step. This should be your final action.

**Session-start communication check**: After reading agent-requests.md, check: (1) Requests with `To: [you]` and `Status: open` — respond and set to `done`. (2) Handoffs listing you as a Reviewer with sub-status `pending` — review the deliverable and update your sub-status. (3) Handoffs where you are Producer with status `needs-revision` — read feedback, revise, update revision log. Flag any entry older than 5 days as stale.

**Read on demand** (only the sections relevant to your current task):
- knowledge-base/product-spec.md — your agent-context file already has a role-specific summary; read the full spec only when you need feature-level detail
- knowledge-base/decision-log.md — read when you need decision history or rationale for a past choice
- knowledge-base/brand-guidelines.md — read when writing copy, designing screens, or creating brand-facing content
- knowledge-base/design-system-reference.md — read when specifying or building UI
- <any role-specific knowledge-base/ files>

Your skills are indexed in your brain file (`muster/team/<name>/CLAUDE.md`) under "Available Skills." Read only the skill file(s) relevant to the current task.

<1-2 sentences of role-specific behavioral guidance>
```

**Agent-specific startup additions** (add to the "Always read on startup" list):
- Developer, UI/UX, QA: also read `knowledge-base/ui-component-requests.md`
- Content: also read `knowledge-base/brand-guidelines.md`
- Research: also read `knowledge-base/research/product-brief.md` and `knowledge-base/research/change-log.md`

#### Steps

1. Create `muster/team/<name>/` directory
2. Create `muster/team/<name>/CLAUDE.md` from brain template
3. Create `muster/team/<name>/skills/` with domain skill files (organized by platform)
4. Create `.claude/agents/<name>.md` in the project repo from startup config template
5. Add row to `muster/CLAUDE.md` Agent Roster table
6. Add `@<name>` to `muster/CLAUDE.md` Sub-Agent Access line
7. Create `knowledge-base/agent-context/<name>.md` from template in the project repo
8. Root Claude (acting as PM) populates the agent-context file with project-specific content
9. Root Claude mirrors cross-agent dependencies in the Muster brain file (generic relationships only)

#### Safety Checklist

- [ ] Brain file has Role, Cross-Agent Dependencies, Available Skills, Reference Documents sections
- [ ] No product-specific content in the Muster brain file
- [ ] Agent-context file exists in the project with PM-managed product context
- [ ] Dependencies mirrored in counterpart agents' brain files (generic relationships)
- [ ] Agent appears in `muster/CLAUDE.md` roster table
- [ ] `@<name>` appears in `muster/CLAUDE.md` Sub-Agent Access line
- [ ] Startup config reads muster/CLAUDE.md, brain file, and agent-context file
- [ ] Startup config uses two-tier reading model (always-read vs on-demand) — never load full product spec or decision log on every startup
- [ ] Session-start rule for agent-requests.md present in startup config
- [ ] Orchestration queue integration present (startup read + session completion protocol)

#### Special Ownership Boundary (rare — most agents don't need this)

If the agent needs to own a directory (like Research owns `knowledge-base/research/`):
1. Add a new rule in `muster/CLAUDE.md` (e.g., "Rule N: \<Agent\> owns \<path\>")
2. Create an async channel (like `change-log.md`) for PM communication
3. Add monitoring instruction to `muster/CLAUDE.md` "PM Mode (Built-in)" section
4. Document the boundary in `muster/team/pm/skills/generic/agent-management.md`

### Adding a New Skill

#### When to Create a New Skill
- The agent needs structured methodology for a recurring task type (e.g., "how to write a test plan" vs. one-off test plans)
- The methodology is stable enough to codify — if it changes every sprint, it's not ready for a skill file
- The content is about *how to do the work* (methodology) — not *what the product is* (that belongs in knowledge-base/)
- An existing skill file has grown beyond one focused topic — split it

#### Skill vs. Knowledge-Base Content
| Put in skills/ | Put in knowledge-base/ |
|----------------|----------------------|
| How to write component specs | The actual component spec for a screen |
| Testing methodology and standards | The current sprint's test plan |
| Brand voice application rules | Brand guidelines (voice definition, colors, personas) |
| Bug report template and process | Actual bug reports |

**Rule of thumb**: Skills describe *how*. Knowledge-base describes *what*.

#### Skill File Template

```markdown
# [Skill Name]

## Purpose
[One-liner describing what this skill covers and when to use it.] See `team/<agent>/skills/<sibling>.md` for [related methodology]. See `knowledge-base/<doc>.md` for [related product context].

## [Core Sections]
[The methodology, standards, templates, or workflows this skill defines.]

## [Principles Section] (if the skill involves judgment)
1. **[Principle name]**: [Explanation — when and why this principle applies.]
2. ...

## Output (if the skill produces a deliverable)
[Where the output goes — file path, agent handoff, or tracker.]
```

#### Structural Requirements (Quality Checklist)
- [ ] **Purpose section** immediately after the H1 title — one-liner + scope context
- [ ] **At least one cross-reference** to a sibling skill or knowledge-base doc (use backtick file paths)
- [ ] **Principles section** at the end if the skill involves judgment or edge-case decision-making (numbered, bold headers)
- [ ] **Output section** if the skill produces a deliverable with a specific destination
- [ ] **No duplicated content** from knowledge-base — reference, don't copy
- [ ] **Focused scope** — one skill per topic. If a file covers two unrelated topics, split it

#### Registration Points
1. Create the skill file in `muster/team/<agent>/skills/{generic,platform}/<skill-name>.md`
2. Add an entry to the agent's brain file (`muster/team/<agent>/CLAUDE.md`) "Available Skills" section with a one-line description
3. If the skill references other agents' skills or knowledge-base docs, verify those files exist

### Product Skills (Project-Specific)

Muster methodology skills (`team/<agent>/skills/`) are product-agnostic frameworks — they teach HOW to do the work. Product-specific strategies, keywords, competitor analysis, algorithm rules, and domain details live in the project repo at `knowledge-base/agent-skills/<agent>/`.

#### When to Create a Product Skill
- The content is specific to THIS product (competitor names, pricing, keyword lists, specific algorithms)
- The corresponding muster methodology skill has placeholders that need filling for the product
- The content changes with product strategy (not with methodology evolution)

#### Product Skill vs. Agent-Context Content
| Put in agent-skills/ | Put in agent-context/ |
|---------------------|----------------------|
| Filled-in growth strategy with real competitors and pricing | Product positioning summary (2-3 lines) |
| Actual keyword clusters and SEO terms | Target user profile |
| Product-specific test cases and algorithm rules | Tech stack overview |
| Competitor counter-positioning playbook | Key references list |

**Rule of thumb**: Agent-context = product summary (read every session, ~20 lines). Product skills = deep reference material (read on demand per task, full documents).

#### Product Skill File Structure
Product skills supplement muster methodology — they are complete standalone documents with strategic reasoning, not just extracted data points. An agent reading only the product skill should understand the strategy. An agent reading both the methodology skill and the product skill gets the full picture.

```markdown
# [Product Name] [Topic] — Product Specifics

Supplements `muster/team/<agent>/skills/generic/<methodology-skill>.md` methodology.

## [Sections matching the methodology skill's structure]
[Filled-in content with strategic reasoning — not just values, but WHY these values]
```

#### Registration
1. Create `knowledge-base/agent-skills/<agent>/<skill-name>.md`
2. Add to the agent's agent-context file (`knowledge-base/agent-context/<agent>.md`) "Project Skills" section with a one-line description
3. Name the product skill to match the muster skill it supplements (e.g., muster's `growth-strategy.md` → product's `growth-strategy.md`)

### Adding a New Feature/Vertical
1. Research agent creates `knowledge-base/research/features/<feature>.md` with market context
2. PM updates `knowledge-base/product-spec.md` with a new section for the feature
3. PM cascades feature context to affected agents via their agent-context files
4. No protocol changes or structural modifications needed

### Adopting New Tools/Libraries
1. Developer updates `knowledge-base/architecture.md` with the new dependency
2. PM cascades the change to affected agents (e.g., QA for test updates)
3. No structural changes needed

### Archiving a Completed Product
When a product ships and you want to reuse the framework for the next one:
1. Create a new project repo for the next product
2. Add Muster as a submodule (`git submodule add <muster-repo-url> muster/`)
3. Copy templates from `muster/templates/` to set up the new project structure
4. The Muster framework (agent brains, skills, protocols) is shared — no duplication needed
5. The old project repo stays intact as reference

### Changing Rules
- System-wide rules go in `muster/CLAUDE.md`
- Agent-specific methodology changes go in that agent's `skills/` files in Muster
- Project-specific overrides go in the project's root CLAUDE.md
- Neither requires touching other agents' files

### Framework Change Protocol
When a change affects how agents structurally operate (not product content, but agent behavior, startup patterns, file structure, or workflows), the system guide templates must be updated alongside the live instances.

**Examples of framework changes:**
- Startup config reading patterns (what agents load on startup)
- Brain file section structure (adding/removing/renaming sections)
- New workflow protocols (new communication channels, new file types)
- Agent tool permissions or behavioral rules
- Skill file structural requirements

**Checklist (run after any framework change):**
1. Update all live agent instances (startup configs in project, brain files in Muster, skills)
2. Update the **Startup Config Template** in this file if startup behavior changed
3. Update the **Agent Brain Template** in this file if brain file structure changed
4. Update the **Skill File Template** in this file if skill structure changed
5. Update the **Agent-Context Templates** in `templates/knowledge-base/agent-context/` if agent-context file structure changed
6. Update the **Safety Checklist** in this file if a new structural requirement was added
7. Update `muster/team/pm/skills/generic/agent-management.md` if the PM's update protocol changed

### System Verification Checklist

Run this **once, after completing a batch of related framework changes** — not after each individual edit. Root Claude (as PM) runs this directly: "Run system verification for [what changed]. Read the System Verification Checklist in system-guide.md and check all 8 layers."

**Layer 1 — Reference integrity**: For every file added, removed, renamed, or whose role changed:
- Grep `.claude/agents/*.md`, `muster/team/*/CLAUDE.md`, `muster/team/pm/skills/*.md`, `muster/system-guide.md`, and `muster/CLAUDE.md` for references to it
- Confirm: no stale pointers, no orphaned references, no file referenced that doesn't exist

**Layer 2 — Skill coverage**: For every new workflow or protocol:
- Identify which PM skills touch this workflow (sprint-planning? agent-management? decision-making?)
- Verify each skill documents the new workflow step
- Verify Decision Autonomy Matrix covers any new decision types introduced

**Layer 3 — Template sync**: After updating live instances:
- Compare startup config template in this file against any live specialist agent's actual config — must match structurally
- Compare safety checklist against actual checks needed for a new agent
- Verify brain file template sections match what live agents actually have

**Layer 4 — Ownership trace**: For every new file or responsibility:
- Identify which agent owns it (creates/updates it)
- Verify that agent's startup config reads it, brain file or skills reference it
- Confirm: exactly one owner per file (no shared ownership ambiguity)

**Layer 5 — Context budget**: After all changes are complete:
- Count total startup read lines per agent (brain file + agent-context + startup reads)
- Flag any specialist agent exceeding 200 lines at startup, PM exceeding 400
- Check: does any agent read a file it never acts on? (wasted context)
- Check: does any agent read the same information from two different files? (duplication = bloat)
- List every file read by all agents — these are highest-cost files. Verify each is as lean as possible.

**Layer 6 — Growth & scalability**: For every file read at startup:
- Confirm it has a growth cap or archival rule (Done max 5, Resolved max 10, decision log archive at 50, etc.)
- If no cap exists and the file can grow unbounded, add one
- Check: are there new files that will accumulate entries over time? Verify self-cleaning rules exist (who cleans, when, how)

**Layer 7 — Duplication detection**:
- For every piece of information added or changed, verify it lives in exactly ONE place
- If same fact appears in two files, one must be the source and the other must reference it (not copy it)
- Check agent-context files for inlined info that duplicates knowledge-base files — should be a summary with a reference, not a copy

**Layer 8 — Failure mode scan**:
- What happens if an agent's session is killed before it completes? Is state left inconsistent? Is recovery obvious?
- What happens if the PM skips a step in the protocol? Will the next agent or the founder notice?
- What happens if a file grows past its cap and no one trims it? Is there a safety net?
- Are there any single points of failure where one missed update breaks the chain?

### New Project Setup

1. Clone Muster: `git clone <muster-repo-url>`
2. Run setup: `cd muster-ai && ./scripts/setup-project.sh <project-name>`
   - Creates new git repo
   - Adds Muster as submodule
   - Copies `.claude/agents/` from templates
   - Copies `CLAUDE.md` template with placeholders
   - Copies `knowledge-base/` templates with protocol headers and empty agent-context files
3. Fill in project CLAUDE.md (product name, description, platforms, tech stack)
4. Fill in agent-context files (filtered context for each agent)
5. Start working — invoke Root Claude as PM to plan your first sprint

### Product Pivot or Direction Change
1. Research agent updates its docs (Current State sections in knowledge-base/research/)
2. PM updates knowledge-base/ files (product-spec, brand-guidelines, etc.)
3. PM cascades updated context to agent-context files
4. The structure stays the same — only content changes

## Workflow Protocols

### Agent Communication Protocol

Agents communicate via `knowledge-base/agent-requests.md` using two entry types: **requests** (questions, clarifications, new work asks) and **handoffs** (completed deliverables needing review). Format templates also live as HTML comments in the file itself for quick reference.

#### Entry Type 1: Request

For questions, spec clarifications, asset requests, or new work requests between agents.

```markdown
### [DATE] REQ-[ID] — [Title]
**Type:** request
**From:** [agent]
**To:** [agent]
**Status:** open | done
**Request:** [1-2 sentences]
**Response:** [Filled by receiving agent when status → done]
```

Status lifecycle: `open` → `done`

#### Entry Type 2: Handoff

For completed deliverables needing review or consumption by other agents.

```markdown
### [DATE] HO-[ID] — [Title]
**Type:** handoff
**Producer:** [agent]
**Deliverable:** `path/to/file.md`
**Status:** open | in-review | needs-revision | done
**Reviewers:**
- [ ] Agent — pending
- [x] Agent — done (DATE: "Summary.")
- [ ] Agent — needs-revision (DATE: "Feedback.")

**Revision log:**
- DATE: Description of revision or feedback event.
```

Status lifecycle: `open` → `in-review` → `needs-revision` (if any reviewer flags) → `done` (all reviewers complete)

#### Session-Start Rule (ALL agents)

Every agent checks `knowledge-base/agent-requests.md` at the start of every session. Three checks:

1. **Requests to you**: Any entry with `To: [you]` and `Status: open` — respond and set status to `done`.
2. **As a Reviewer**: Any handoff listing you in Reviewers with sub-status `pending` — review the Deliverable, update your sub-status to `done` or `needs-revision` (with feedback). If any reviewer sets `needs-revision`, update overall Status to `needs-revision`.
3. **As a Producer**: Any handoff where you are Producer with overall status `needs-revision` — read feedback, revise deliverable, update revision log, reset flagging reviewer to `pending`, flip status to `in-review`.

Additionally: flag any entry older than 5 days to the founder as potentially stale.

#### PM Additional Session-Start Rule (Root Claude)

Root Claude (acting as PM) reads `knowledge-base/agent-requests.md` in full and is prepared to report complete status to the founder: all active entries, who is pending, what is stale, what is blocked. Thresholds for escalation:
- Requests `open` >3 days
- Handoffs `in-review` >3 days or `needs-revision` >2 days
- Entries with 3+ revision log items → escalate to founder
- When flagging stale entries, add a note to the revision log and notify founder with specific entry and blocking agent

#### Self-Cleaning Rules

- The agent that flips overall status to `done` moves the entry to the Resolved section as a one-liner summary. For requests, the agent who fills the Response also moves it. **If completing a request also involves creating a handoff (REQ → HO), move the request to Resolved before creating the handoff.**
- **PM enforcement (mandatory)**: When PM reads `agent-requests.md` at session start, scan Active Requests and Active Handoffs for any entry with `Status: done`. Move every such entry to Resolved immediately — before reporting status or doing any other PM work. Done items must never remain in Active sections across sessions.
- Resolved section capped at 10 entries; oldest trimmed when adding new ones.
- Target: file under 150 lines.

#### Pre-Handoff Self-Review Checklist

Before filing a handoff (HO entry), the producing agent MUST run this self-review against the deliverable. This catches internal inconsistencies before the reviewer spends time on them.

1. **Internal consistency**: Grep the deliverable for contradictions (e.g., a term defined one way in Section A but used differently in Section B). Pay special attention to assumptions that appear in multiple sections.
2. **Acceptance criteria**: Re-read the acceptance criteria from `knowledge-base/current-sprint.md` for this task. Verify each criterion is met. If any criterion is ambiguous, document your interpretation in the handoff revision log.
3. **Cross-references**: If the deliverable references other knowledge-base files (product-spec, design-specs, legal drafts), spot-check that at least 3 references are still accurate (file exists, section exists, content matches).
4. **Feature ID validation**: If the deliverable references any feature IDs (F-XXX-N pattern), grep `knowledge-base/product-spec.md` for each one. Every feature ID must exist in the product spec. If any ID is not found, it is a typo or a phantom ID — fix or remove it before filing.
5. **Foundational assumptions**: Read `knowledge-base/foundational-assumptions.md`. Verify the deliverable is consistent with all active assumptions relevant to your domain. Verify the deliverable uses the EXACT terminology from the assumption statements. If the deliverable introduces a term not present in the assumptions or product spec, it is likely terminology drift — verify or flag it.
6. **Open questions**: If the deliverable contains unresolved questions or placeholders, list them explicitly in the handoff revision log — do not leave them for the reviewer to discover.
7. **Missing assets**: If the design spec requires assets the agent cannot produce (logos, illustrations, images, animations), list them in the handoff revision log as founder dependencies. PM must add these to Founder Decisions in `knowledge-base/orchestration-queue.md` during review.

If any check fails, fix the issue before filing the handoff. Log what the self-review caught in the revision log entry (e.g., "Self-review: caught 2 internal inconsistencies, fixed before filing").

#### Entry Creation Guidance

- Use sequential IDs: REQ-001, REQ-002, HO-001, HO-002 (check the file for the latest ID before creating a new one).
- Keep Request descriptions to 1-2 sentences. Keep Reviewer feedback to 1 sentence.
- When creating a handoff, set initial status to `in-review` if the deliverable is ready for review, or `open` if it is still being finalized.

---

### Discovery Phase (PM → Research → PM)
1. Founder tells PM about their product idea (raw — can be as rough as "I want to build X")
2. PM seeds `knowledge-base/research/product-brief.md` — fills in the **Founder's Idea** section with the founder's full context (problem, target user, proposed solution, why they think they can win, any background). This preserves context that would be lost in a one-line request.
3. PM writes a change-log entry (`status: needs-research`) referencing the seeded brief, and adds a Research step to the orchestration queue
4. Founder invokes @research. Research agent reads the seeded brief + change-log request, conducts web research, completes all sections of product-brief.md and supporting files (market-landscape.md, competitive-analysis.md, user-insights.md)
5. Research sets change-log entry to `status: researched`
6. Founder returns to PM. PM reads the completed brief + supporting files, evaluates using `product-evaluation.md` skill (6-dimension scoring rubric), and presents a GO / CONDITIONAL / NO-GO recommendation to the founder
7. Founder makes the final call. If GO: PM reads brief → populates product-spec.md, brand-guidelines.md, etc. → cascades context to specialist agents via agent-context files — execution begins

### Scope Change Protocol (PM ↔ Research)
1. Scope change arises (new feature, pivot, market shift, new tool/library)
2. PM writes change request to knowledge-base/research/change-log.md with `status: needs-research`
3. Founder spins up Research agent to investigate
4. Research agent reads request, does analysis, updates relevant docs (or creates new feature file)
5. Research agent writes recommendation, sets `status: researched`
6. PM reads recommendation → decides → logs in decision-log.md → updates execution docs
7. Change-log entry moves to Resolved

### Product Expansion (adding a feature vertical)
1. PM or founder flags "explore [new feature]" via change-log
2. Research creates knowledge-base/research/features/[feature].md
3. Research conducts scoped market/competitive analysis
4. Normal handoff to PM when research is complete

## Sub-Agent Usage Examples
- `@research Here's my product idea: [description]. Explore the market and build a brief.`
- `The product brief is ready. Plan execution and update all agents.` (Root Claude handles this directly as PM)
- `@developer How should we structure the data layer?`
- `@ui-ux Design the onboarding flow for new users.`
- `@legal Review our terms of service draft.`
- `@developer Let's discuss the API architecture.` (Root Claude coordinates as PM)
