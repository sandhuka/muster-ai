# System Guide

Reference manual for extending and operating Muster. This is not a read-through document — use it on demand when adding agents, adding skills, modifying workflows, or verifying system integrity.

For setup, see [getting-started.md](getting-started.md). For architecture and design, see [architecture-and-design.md](architecture-and-design.md).

---

## Agent Brain Template (`team/<agent>/CLAUDE.md`)

Every agent brain file follows this structure:
- **Role**: 2-3 sentence role definition
- **Cross-Agent Dependencies**: Generic role relationships (applies to ANY project)
- **Pre-Handoff Self-Review**: One-line pointer to the checklist in `muster/system-guide.md`, making self-review non-optional before any handoff
- **Available Skills**: Index of skill files in `team/<agent>/skills/{generic,platform}/`
- **Project Skills**: Note directing agents to check their agent-context file for product-specific skills
- **Reference Documents**: Links to project-relative knowledge-base/ files the agent reads on demand

Agent brain files contain NO product-specific content. Product context is provided per-project via `knowledge-base/agent-context/<agent>.md`.

## Agent-Context Template (`knowledge-base/agent-context/<agent>.md`)

Per-project filtered context for each agent. PM-managed. Standard sections:
- **Product Context**: Filtered product information relevant to this agent's role. Includes key references as bullet points at the end.
- **Project Skills**: Index of product-specific skill files in `knowledge-base/agent-skills/<agent>/`.
- **Current Tasks**: Full sprint task specs (deliverable, priority, effort, dependencies, acceptance criteria, key refs). Tasks must be self-contained. Do NOT inline a per-task skill list — the agent's brain file already lists every available skill with descriptions, organized by platform subfolder. If a task needs unusual methodology, PM calls out the specific skill in the task description prose.
- **Agent-Specific Context** (optional): Agent-owned notes

Size varies by role:
- **Developer, QA** (~40-80 lines + tasks): Tech stack, architecture, data model, feature mapping, testing, UI library workflow
- **UI/UX** (~30-50 lines + tasks): Target user, design system, content approach, navigation, monetization UX
- **Content, Marketing, Legal, Research** (~15-30 lines + tasks): Brand context, target user, positioning, compliance scope

See `templates/knowledge-base/agent-context/` for section templates per agent.

---

## Adding a New Agent

### Registration Points (all must be updated)

| # | File | What to Add |
|---|------|-------------|
| 1 | `muster/team/<name>/CLAUDE.md` | Agent brain file |
| 2 | `muster/team/<name>/skills/` | Domain skill files organized by platform |
| 3 | Project `.claude/agents/<name>.md` | Startup config (template below — must include `.populated` halt check) |
| 4 | `muster/CLAUDE.md` — Agent Roster table | New row |
| 5 | `muster/CLAUDE.md` — Sub-Agent Access line | Add `@<name>` |
| 6 | Project `knowledge-base/agent-context/<name>.md` | Filtered product context + tasks |
| 7 | Project `knowledge-base/agent-skills/<name>/` | Create directory for product-specific skills |
| 8 | Project `knowledge-base/agent-context/.populated` | Add `<name>: null` entry under the `agents` block (PM populates the timestamp at first cascade or JIT populate) |
| 9 | `templates/knowledge-base/agent-context/.populated` | Add `<name>: null` to the framework template so future projects scaffold with the new agent |

### Startup Config Template (`.claude/agents/<name>.md`)

```markdown
---
name: <name>
description: "<one-line role description>"
tools: Read, Write, Edit, Grep, Glob, Bash
---

You are the <Name> agent for this project.

**Startup halt — FIRST action**: Read `knowledge-base/agent-context/.populated`. If `agents.<name>` is `null`, your ENTIRE response must be exactly: `HALT: agent-context null. PM: run JIT populate per context-cascading.md, then re-invoke.` — and nothing else. Do not answer the user, read other files, or self-populate (Rule 1). If it's a timestamp, continue startup.

PM auto-handles this by reading the JIT Populate procedure, populating the agent's context file, setting the timestamp in `.populated`, and re-invoking with the original task. The hardened "ENTIRE response must be exactly" phrasing prevents the model from rationalizing past the halt when the user's prompt is substantive.

**Always read on startup** (after halt check passes — lightweight, essential):
1. muster/CLAUDE.md (system rules, protocols, communication standards)
2. muster/team/<name>/CLAUDE.md (your role definition + skill index)
3. knowledge-base/agent-context/<name>.md (filtered product context for your role)
4. knowledge-base/orchestration-queue.md (check if there is a step assigned to you — that is your primary task)
5. knowledge-base/agent-requests.md (check for requests to you, handoffs needing your review, and your handoffs needing revision)

**Session completion**: After completing your task, update `knowledge-base/orchestration-queue.md` — move your step to Done with a one-line summary (if Done exceeds 10 entries, remove the oldest first), then move the next upcoming step to Next Step. This should be your final action.

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

### Steps

1. Create `muster/team/<name>/` directory
2. Create `muster/team/<name>/CLAUDE.md` from brain template
3. Create `muster/team/<name>/skills/` with domain skill files (organized by platform)
4. Create `.claude/agents/<name>.md` in the project repo from startup config template (include the `.populated` halt check)
5. Add row to `muster/CLAUDE.md` Agent Roster table
6. Add `@<name>` to `muster/CLAUDE.md` Sub-Agent Access line
7. Create `knowledge-base/agent-context/<name>.md` from template in the project repo
8. Add `<name>: null` to `knowledge-base/agent-context/.populated` (project-level) AND to `templates/knowledge-base/agent-context/.populated` (framework-level so future projects scaffold with the new agent)
9. PM (in a PM-bound session) populates the agent-context file with project-specific content and sets the agent's timestamp in `.populated`
10. PM mirrors cross-agent dependencies in the Muster brain file (generic relationships only)

### Safety Checklist

- [ ] Brain file has Role, Cross-Agent Dependencies, Pre-Handoff Self-Review, Available Skills, Reference Documents sections
- [ ] No product-specific content in the Muster brain file
- [ ] Agent-context file exists in the project with PM-managed product context
- [ ] Dependencies mirrored in counterpart agents' brain files
- [ ] Agent appears in `muster/CLAUDE.md` roster table
- [ ] `@<name>` appears in `muster/CLAUDE.md` Sub-Agent Access line
- [ ] Startup config reads muster/CLAUDE.md, brain file, and agent-context file
- [ ] Startup config includes the `.populated` halt check as its first action (before any other read)
- [ ] Startup config uses two-tier reading model (always-read vs on-demand)
- [ ] Session-start rule for agent-requests.md present in startup config
- [ ] Orchestration queue integration present (startup read + session completion protocol)
- [ ] Agent has `<name>: null` entry in BOTH the project-level `.populated` AND the framework template `templates/knowledge-base/agent-context/.populated`

### Special Ownership Boundary (rare)

If the agent needs to own a directory (like Research owns `knowledge-base/research/`):
1. Add a new rule in `muster/CLAUDE.md`
2. Create an async channel (like `change-log.md`) for PM communication
3. Add monitoring instruction to `muster/CLAUDE.md` "Role Binding" section (or to `templates/.claude/agents/pm.md` "Monitoring duties" if the trigger is PM-only at PM bind time)
4. Document the boundary in `muster/team/pm/skills/generic/agent-management.md`

---

## Adding a New Skill

### When to Create a New Skill
- The agent needs structured methodology for a recurring task type
- The methodology is stable enough to codify — if it changes every sprint, it's not ready
- The content is about *how to do the work* (methodology) — not *what the product is* (knowledge-base)
- An existing skill file has grown beyond one focused topic — split it

### Skill vs. Knowledge-Base Content
| Put in skills/ | Put in knowledge-base/ |
|----------------|----------------------|
| How to write component specs | The actual component spec for a screen |
| Testing methodology and standards | The current sprint's test plan |
| Brand voice application rules | Brand guidelines (voice definition, colors, personas) |
| Bug report template and process | Actual bug reports |

**Rule of thumb**: Skills describe *how*. Knowledge-base describes *what*.

### Skill File Template

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

### Quality Checklist
- [ ] **Purpose section** immediately after the H1 title
- [ ] **At least one cross-reference** to a sibling skill or knowledge-base doc
- [ ] **Principles section** at the end if the skill involves judgment
- [ ] **Output section** if the skill produces a deliverable with a specific destination
- [ ] **No duplicated content** from knowledge-base — reference, don't copy
- [ ] **Focused scope** — one skill per topic

### Registration
1. Create the skill file in `muster/team/<agent>/skills/{generic,platform}/<skill-name>.md`
2. Add entry to the agent's brain file under "Available Skills"
3. Verify cross-referenced files exist

---

## Product Skills (Project-Specific)

Muster methodology skills are product-agnostic frameworks. Product-specific strategies, keywords, competitor analysis, and domain details live in the project repo at `knowledge-base/agent-skills/<agent>/`.

### When to Create a Product Skill
- The content is specific to THIS product (competitor names, pricing, keyword lists, specific algorithms)
- The corresponding muster methodology skill has placeholders that need filling
- The content changes with product strategy (not with methodology evolution)

### Product Skill vs. Agent-Context Content
| Put in agent-skills/ | Put in agent-context/ |
|---------------------|----------------------|
| Filled-in growth strategy with real competitors | Product positioning summary (2-3 lines) |
| Actual keyword clusters and SEO terms | Target user profile |
| Product-specific test cases and algorithm rules | Tech stack overview |
| Competitor counter-positioning playbook | Key references list |

**Rule of thumb**: Agent-context = product summary (read every session, ~20 lines). Product skills = deep reference material (read on demand, full documents).

### Product Skill Structure
```markdown
# [Product Name] [Topic] — Product Specifics

Supplements `muster/team/<agent>/skills/generic/<methodology-skill>.md` methodology.

## [Sections matching the methodology skill's structure]
[Filled-in content with strategic reasoning — not just values, but WHY these values]
```

### Registration
1. Create `knowledge-base/agent-skills/<agent>/<skill-name>.md`
2. Add to the agent's agent-context file under "Project Skills"
3. Name to match the muster skill it supplements

---

## Skill Contribution Protocol

When PM classifies a new skill as generic (per `skill-gap-classification.md`), this protocol handles contributing it back to the Muster framework so all projects benefit.

### How It Works

1. PM writes the skill to `muster/team/<agent>/skills/generic/` and updates the agent's brain file skill index
2. PM presents a summary to the user:
   - Skill name and which agent it's for
   - One-line description of what it does
   - Why it's generic (which product types benefit)
   - "This skill has been added to your project and your agents will use it this sprint. It's also generic enough to benefit the Muster framework — contributing it means your future projects (and other Muster users) get it out of the box. Say no if you'd rather keep it private to this project."
3. **Default is contribution** — if the user confirms or says nothing, proceed. If the user says no, move the skill to `knowledge-base/agent-skills/<agent>/` instead
4. On contribution, commit using the standard Muster submodule commit flow (Rule 13 in CLAUDE.md)

### Existing Skill Fixes

When a project discovers an issue with an existing generic skill (e.g., platform-specific assumptions in a generic skill), the same flow applies — fix locally in the submodule, commit via Rule 13.

---

## System Extensibility

### Adding a New Feature/Vertical
1. Research agent creates `knowledge-base/research/features/<feature>.md` with market context
2. PM updates `knowledge-base/product-spec.md` with a new section
3. PM cascades feature context to affected agents via their agent-context files
4. No protocol or structural changes needed

### Adopting New Tools/Libraries
1. Developer updates `knowledge-base/architecture.md`
2. PM cascades the change to affected agents
3. No structural changes needed

### Archiving a Completed Product
1. Create a new project repo for the next product
2. Add Muster as a submodule
3. Copy templates from `muster/templates/`
4. The Muster framework is shared — no duplication. The old project stays intact as reference.

### Product Pivot or Direction Change
1. Research agent updates its docs
2. PM updates knowledge-base/ files
3. PM cascades updated context to agent-context files
4. The structure stays the same — only content changes

### Changing Rules
- System-wide rules: `muster/CLAUDE.md`
- Agent-specific methodology: that agent's `skills/` files
- Project-specific overrides: the project's root `CLAUDE.md`
- None of these require touching other agents' files

---

## Framework Change Protocol

When a change affects how agents structurally operate (not product content, but behavior, startup patterns, file structure, or workflows):

**Checklist:**
1. Update all live agent instances (startup configs, brain files, skills)
2. Update **Startup Config Template** in this file if startup behavior changed
3. Update **Agent Brain Template** in this file if brain file structure changed
4. Update **Skill File Template** in this file if skill structure changed
5. Update **Agent-Context Templates** in `templates/knowledge-base/agent-context/` if context file structure changed
6. Update **Safety Checklist** in this file if a new structural requirement was added
7. Update `muster/team/pm/skills/generic/agent-management.md` if PM's update protocol changed

---

## System Verification Checklist

Run **once after completing a batch of related framework changes** — not after each individual edit. A PM-bound session runs this directly.

**Layer 1 — Reference integrity**: For every file added, removed, renamed, or whose role changed — grep startup configs, brain files, PM skills, system-guide, and CLAUDE.md. Confirm no stale pointers or orphaned references.

**Layer 2 — Skill coverage**: For every new workflow or protocol — identify which PM skills touch it, verify each documents the new step, verify the Decision Autonomy Matrix covers new decision types.

**Layer 3 — Template sync**: Compare templates in this file against actual live instances. Must match structurally.

**Layer 4 — Ownership trace**: For every new file or responsibility — identify the owning agent, verify their config reads it and their brain/skills reference it. Exactly one owner per file.

**Layer 5 — Context budget**: Count total startup read lines per agent. Flag specialists exceeding 200 lines, PM exceeding 400. Check for files read but never acted on (wasted context) and duplicate reads.

**Layer 6 — Growth & scalability**: For every file read at startup — confirm it has a growth cap or archival rule. If no cap exists and the file can grow unbounded, add one.

**Layer 7 — Duplication detection**: For every piece of information added or changed — verify it lives in exactly one place. If same fact appears in two files, one must be the source and the other must reference it.

**Layer 8 — Failure mode scan**: What happens if an agent session is killed mid-task? If PM skips a protocol step? If a file grows past its cap? Are there single points of failure?

---

## Workflow Protocols

### Invocation Patterns

Muster supports three invocation modes. Use the right one for the moment.

- **Mode A (interactive picker)** — Open Claude in the project. The role picker fires (Coordination / Build / Communicate / Validate → role). Pick the role this session needs. Use for: founder-driven workflow, multi-tab sessions, anything attended.

- **Mode B (env-var bind)** — `MUSTER_ROLE=<role> claude "..."` skips the picker and binds directly. Use for: scripts, power-users with stable role per shell, CI steps with a known role. Set `MUSTER_ROLE=auto` to bind to whatever role the orchestration queue's Next Step lists (parses the `@<role>` prefix). Use `MUSTER_ROLE=auto` for: orchestrator daemons, scheduled runs, autonomous loops with `--dangerously-skip-permissions`.

- **Mode C (subagent)** — From any role-bound session, invoke `Agent({subagent_type: "<role>"})` for parallel work, tool-isolated tasks, or quick cross-role consults. The subagent runs with its own startup config (does NOT fire the picker). Use for: spawning a Developer subagent from a PM tab to do a quick task; same-role parallel work; throwaway cross-role trivia.

**Defaults**:
- Founder-attended workflow: Mode A. Open one tab per active role; PM tab for planning, specialist tabs for execution.
- Scripted/CI: Mode B with explicit role.
- Autonomous orchestration: Mode B with `MUSTER_ROLE=auto`.

**Closeout guarantee (all modes):** specialists run the Pre-Handoff Self-Review Checklist before filing any handoff. Item 10 enforces queue + decision-log update — sessions stay state-consistent without PM reconciling after every step.

**Cross-role consult policy**: when a role-bound session needs input from another role, default to **file-based** via `agent-requests.md` (write request, switch tabs to answer). Permitted exceptions for throwaway trivia: spawn a one-shot subagent (Mode C), OR open a new role-bound tab. Test: if the answer would deserve a `decision-log` entry, use file-based instead. Rationale: conversations are ephemeral, files persist.

**Mid-session role swap**: `/rebind` re-fires the picker mid-session. Use when you bound the wrong role at start, or finished one role's work and want to switch without opening a new tab.

**Status line**: `[muster: <role>]` shows the bound role at the bottom of the terminal. Updates after every bind. `[muster: unbound]` indicates the bind file is missing for this session (shouldn't happen in normal flow).

### Autonomous Sprint Execution

`muster/scripts/muster-sprint-run.sh` walks the orchestration queue to completion unattended — the machine middle of a sprint whose bookends stay human (plan + approve the queue at the start; review the branch diff and `## Founder Decisions` at the end). It is **Mode B with `MUSTER_ROLE=auto` run in a loop**: each iteration is a fresh `claude -p` process that binds the role named in the queue's Next Step, does the work, files its handoff, and **advances the queue itself** (Pre-Handoff Self-Review item 10). Fresh-process-per-step is deliberate — it keeps every step's context window bounded; do not warm or reuse sessions across steps.

The driver only **reads** the queue and honors stop signals — it never writes the queue. It stops on any of **four conditions plus a hard cap**:
1. **Next Step empty** (whitespace-only block) → sprint complete.
2. **`Role: halt`** → an agent hit a hard block only the founder can resolve (it also wrote the question to `## Founder Decisions`). There is no checkbox convention; `Role: halt` is the signal.
3. **Next Step unchanged** after a step → the agent didn't advance the queue (stuck / failed). This is also the safety net for an agent that forgets to advance.
4. **Non-zero exit** from `claude` → stop for the founder.
- **`MAX_STEPS`** (default 30, env-overridable) is a cost circuit-breaker.

A non-empty Next Step block with no `Role:` line defaults to `pm` (PM steps may omit the marker); only a whitespace-only block means "complete."

**Handoff-integrity lint** (`muster/scripts/muster-lint-handoff.sh`, called at the top of each iteration): the most-recent `## Done` entry's `HO-NNN` references must already be filed in `agent-requests.md`. A dangling reference (Done entry advanced, handoff never filed) **stops** the loop — it does not auto-file. Zero-padding is normalized (`HO-37` ≡ `HO-037`); all referenced IDs are checked; Done entries with no HO reference (PM / coordination steps) are skipped.

**Worktree only — never the main checkout.** Running `--dangerously-skip-permissions` unattended on the primary tree is irreversible, so the driver refuses to start there unless `MUSTER_SPRINT_ALLOW_PRIMARY=1` is set. Use `muster/scripts/muster-sprint-sandbox.sh`, which creates an isolated worktree on a fresh `sprint/auto-*` branch, runs the loop there, and prints review/merge/discard commands. (Manual equivalent: `git worktree add ../<proj>-sprint -b sprint/auto-<stamp>`, then run the driver inside it.)

**Resume is free.** After answering a parked blocker (or clearing the condition that stopped the loop), re-run the driver in the same worktree — file state makes it continue from where it stopped. No resume flag.

### Agent Communication Protocol

Agents communicate via `knowledge-base/agent-requests.md` using two entry types. Format templates also live as HTML comments in the file itself.

#### Request Entry
```markdown
### [DATE] REQ-[ID] — [Title]
**Type:** request
**From:** [agent]
**To:** [agent]
**Status:** open | done
**Request:** [1-2 sentences]
**Response:** [Filled by receiving agent when status -> done]
```

#### Handoff Entry
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

#### Status Lifecycles
- Requests: `open` -> `done`
- Handoffs: `open` -> `in-review` -> `needs-revision` (if flagged) -> `done` (all reviewers complete)

#### Self-Cleaning Rules
- The agent that flips status to `done` moves the entry to Resolved as a one-liner. If completing a request also creates a handoff (REQ -> HO), move the request to Resolved first.
- **PM enforcement**: At session start, scan Active sections for `Status: done` entries and move them to Resolved immediately.
- Resolved section capped at 10 entries; oldest trimmed when adding new.
- Target: file under 150 lines.

#### Entry Creation Guidance
- Sequential IDs: REQ-001, REQ-002, HO-001, HO-002 (check file for latest ID first)
- Keep request descriptions to 1-2 sentences. Reviewer feedback to 1 sentence.
- Set initial handoff status to `in-review` if ready for review, `open` if still being finalized.

### Pre-Handoff Self-Review Checklist

Before filing a handoff, the producing agent MUST run this self-review:

1. **Internal consistency**: Grep the deliverable for contradictions. Pay attention to assumptions that appear in multiple sections.
2. **Acceptance criteria**: Re-read criteria from `current-sprint.md`. Verify each is met. Document ambiguous interpretations in the revision log.
3. **Cross-references**: Spot-check at least 3 references to other knowledge-base files (file exists, section exists, content matches). For skill paths specifically: any `team/<role>/skills/...` path cited in this handoff (in prose, agent-context updates, or cascade docs) must resolve on disk — skills live under platform subfolders (`skills/{generic,ios,backend,android,web}/`), so a flat `skills/<name>.md` path is stale.
4. **Feature ID validation**: Grep `product-spec.md` for every feature ID referenced. Every ID must exist — fix or remove phantoms.
5. **Foundational assumptions**: Read `foundational-assumptions.md`. Verify consistency with active assumptions. Use EXACT terminology — flag any new terms not in assumptions or product spec.
6. **Open questions**: List unresolved questions explicitly in the revision log.
7. **Missing assets**: List assets the agent cannot produce (logos, illustrations) as founder dependencies.
8. **Test failure discipline**: If a test failure surfaces in your run, do NOT label it "flaky" or "pre-existing" without a root-cause look. A failure may be tagged "flaky" exactly once across handoffs; on its second appearance, the next agent that observes it MUST either root-cause it, quarantine it with a filed bug ID, or escalate to PM. Copy-pasting prior handoffs' "flaky test, scoped to QA regression" language forward across multiple sessions is a self-review violation — it masks deterministic bugs under the cover of a false story.
9. **Durability discipline** (Rule 15): Strip bug IDs, handoff IDs, session-date stamps, sprint / wave references, "previously / now" framings, and specific-agent mentions from durable artifacts (source code, product spec, design specs, brand docs, architecture, test strategy, foundational assumptions, agent-skills). That history belongs in `agent-requests.md`, `orchestration-queue.md`, `current-sprint.md`, `decision-log.md`, and git commits.
10. **Session closeout**: Update `orchestration-queue.md` — add your step to the top of `## Done` (newest first) and promote the next Upcoming step to Next Step (trim oldest if Done exceeds 10). A specialist Done entry is a **one-line pointer to the handoff, not a substitute for it**: `- DATE — Step N: <title> (HO-NNN). <one-line outcome>.` If it grows past ~5 lines, the summary content belongs in the HO body, not the queue. Append any resolved decisions to `decision-log.md`. If your handoff needs review before the next step proceeds, add an "Awaiting review" note to the Done entry.

If any check fails, fix before filing. Log what self-review caught in the revision log.

**Exemption — first post-onboarding sprint (existing-project adoption only)**: if `.populated.onboarded_at` is less than one completed sprint old, items 4 (feature IDs) and 5 (foundational assumptions) flag mismatches in the revision log but do NOT block filing. `product-spec.md` and `foundational-assumptions.md` are still settling from reverse discovery; forcing revisions during Sprint 1 produces churn without value. After one full sprint has closed, items 4 and 5 become hard-fails as usual.

Confidence tagging (`[verified]`/`[inferred]`) is NOT part of this checklist — it is onboarding-only and lives in `team/developer/skills/generic/codebase-audit.md` + `team/pm/skills/generic/deliverable-review.md` → Confidence tagging for extracted claims.

---

### Discovery Phase (greenfield: PM -> Research -> PM, multi-session)

Full procedure lives in `team/pm/skills/generic/greenfield-discovery.md` (5 user-facing stages spread across ~3 sessions, ~1-2 hours founder-attended time).

**User-facing nomenclature**: Stage 1: Idea share, Stage 2: Market research, Stage 3: Go/no-go decision, Stage 4: Draft review, Stage 5: Sprint 1 plan.

**Entry detection**: priority-zero check reads `.populated` at session start. If `onboarded_at` is null AND `agents.pm` is null → first greenfield session, force-bind PM (skip picker), fire welcome via `greenfield-discovery.md`. After Stage 1.3 (idea captured), PM sets `agents.pm` timestamp; subsequent sessions hit the role picker normally.

**High-level flow**:
1. Stage 1: Founder shares idea → PM seeds `knowledge-base/research/product-brief.md` Founder's Idea section, writes change-log entry (`status: needs-research`), queues Research step. Sets `agents.pm` timestamp.
2. Stage 2: Founder invokes @research separately. Research reads the seeded brief, conducts investigation per `team/research/skills/generic/product-validation.md`, completes research files, sets change-log entry to `status: researched`.
3. Stage 3: Founder returns to PM, asks for evaluation. PM scores via `product-evaluation.md` (6 dimensions), presents GO / CONDITIONAL / NO-GO.
4. Stage 4 (if GO): PM writes product-spec, brand-guidelines, foundational-assumptions; founder reviews. PM populates project root `CLAUDE.md` placeholders.
5. Stage 5: PM cascades context to Sprint 1 agents, asks founder for first feature, plans Sprint 1.

### Existing-Project Onboarding Protocol

For adopting Muster into projects with pre-existing code (not greenfield). Full 11-phase procedure lives in `team/pm/skills/generic/reverse-discovery.md` (~2 hours founder time). This section covers the high-level flow, the `.populated` state file, and the `.muster-onboarding/` transient-file protocol.

**User-facing nomenclature**: founder-visible announcements use **Stage 1-6** (Brain-dump, Code audit, Audit review, Questionnaire, Draft review, Sprint 1 plan); internal Phases 4-10 map to Stages 1-6 respectively, while Phases 2/3/9/11 are housekeeping with no Stage label. PM never announces "Phase N" to the founder. Mapping table lives in `reverse-discovery.md` → User-Facing Stage Numbering.

#### Entry point
Founder runs `scripts/setup-existing-project.sh`. Script: three-case git detection (no-git offers `git init`; repo root proceeds; inside-larger-repo aborts), archives existing `CLAUDE.md` + `.claude/agents/`, scaffolds templates, initializes `.populated` with `onboarded_at` (and `onboarding_complete_at: null`), gitignores `.muster-onboarding/`. Has `--resume` for interrupted runs.

#### 11 phases (PM via reverse-discovery.md)
1. Orientation (~90s, non-skippable). 2. CLAUDE.md content-triage + merge. 3. `.claude/agents/` merge. 4. Brain-dump + doc ingest. 5. Audit brief + Developer bootstrap. 6. Audit review + architecture finalize. 7. Adaptive questionnaire. 8. Product synthesis (incl. 8.6 — populate project root `CLAUDE.md` placeholders from synthesized source docs). 9. Agent-context cascade (Sprint 1 agents only; others lazy). 10. Sprint 1 plan + Sprint 2 backlog (incl. 10.3 — chain into Phase 11 in same session, no pause). 11. Cleanup (11.1 rationale distillation, 11.2 atomic `mv` of `.muster-onboarding/` to `.muster-archive/`, 11.3 verification, 11.4 set `onboarding_complete_at` — load-bearing routing signal that flips bootstrap to steady-state).

#### `.populated` state file
Location: `knowledge-base/agent-context/.populated`. Tracks specialist populate state + onboarding lifecycle anchors.
- Schema: `{ version, onboarded_at, onboarding_complete_at, agents: {<name>: null | <ts>, ...}, lock }`
- `onboarded_at`: set by setup script at init, never modified. Anchor for Rule 11 stub-accrued scan.
- `onboarding_complete_at`: null during onboarding; set by PM at Phase 11.4 (after archive succeeds). **Routing signal** — when set, bootstrap takes steady-state path (no `reverse-discovery.md` read) regardless of individual agent state.
- `agents.<name>`: null until first populate. PM sets during Sprint 1 cascade or JIT populate. Null entries in steady-state trigger JIT populate at first invocation, NOT re-onboarding.
- `agents.pm` (greenfield-only signal): null at script init for greenfield. PM sets its own timestamp at Stage 1.3 of greenfield-discovery (after capturing the founder's idea). The transition `null → timestamp` flips routing from "greenfield first session, fire welcome" to "greenfield ongoing, skip welcome". For existing-project, the setup script sets `agents.pm` at init (PM is auto-engaged when adopting an existing codebase).
- `lock`: held during in-flight populate; 15-min stale threshold.
- Tracked in git (not gitignored — teammates pulling the repo need the state).
- Priority-zero check reads at session start — see CLAUDE.md "Role Binding" → Priority-zero routing for the four routing paths.

#### `.muster-onboarding/` transient-file protocol
Location: `knowledge-base/.muster-onboarding/`. Gitignored by default (brain-dump may contain sensitive content).
- Contents: `founder-brain-dump.md` (PM), `audit-brief.md` (PM), `architecture-audit-notes.md` (Developer in bootstrap mode).
- Writers authorized: PM and bootstrap-mode Developer only (Rule 2 carve-out).
- Retired at T+140: atomic `mv` to `.muster-archive/onboarding-<date>/`. Never present in steady-state.

#### CLAUDE.md merge — two-tier decision flow
1. **Content triage first**: route brand/tone/visual/testing/architecture/assumptions content to appropriate knowledge-base files (batch-by-destination approval).
2. **Rule classification + two-tier approval**:
   - Orthogonal (style, formatting): **batch-approved**
   - Adds (net-new behavior): **batch-approved** unless founder reviews
   - Replaces / Conflicts: **per-rule decision** (keep-user / keep-muster / merge-both / edit)
3. Result lives in project CLAUDE.md's `## Project-Specific Rules` as current truth ("Rule 9 (this project): ..."). No "overridden by" archaeology.

Full rationale: `reverse-discovery.md` → Phase 2.

### Scope Change Protocol (PM <-> Research)
1. Scope change arises (new feature, pivot, market shift, new tool)
2. PM writes change request to `knowledge-base/research/change-log.md` with `status: needs-research`
3. Founder spins up Research agent
4. Research investigates, updates relevant docs, writes recommendation, sets `status: researched`
5. PM reads recommendation -> decides -> logs in decision-log -> updates execution docs
6. Change-log entry moves to Resolved

### Product Expansion (adding a feature vertical)
1. PM or founder flags "explore [new feature]" via change-log
2. Research creates `knowledge-base/research/features/[feature].md`
3. Research conducts scoped analysis
4. Normal handoff to PM when complete
