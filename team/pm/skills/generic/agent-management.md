# Agent Management Skill

## Purpose
This skill defines how the PM updates agent-context files (`knowledge-base/agent-context/<agent>.md`). These files hold each agent's filtered product context, current task assignments, and cross-agent dependencies. Follow this protocol every time a decision is made or a plan changes.

## Update Protocol
1. Read the target agent's current agent-context file in full before making changes
2. Only modify sections marked `<!-- PM-MANAGED -->`
3. NEVER overwrite the "Agent-Specific Context" section — that belongs to the agent
4. After updating, add an entry to knowledge-base/decision-log.md

## Section Update Patterns

### Product Context
**Update when:** New product direction, feature changes, pivot, brand updates, anything that changes what the agent needs to know about the product.
**Format:** Brief summary of what's relevant to THIS agent's role specifically. A developer doesn't need marketing strategy details. A content writer doesn't need architecture decisions.
**Rule:** Filter for relevance — don't dump everything. Ask: "What does this specific agent need to know to do their job?"

### Current Tasks
**Location:** Agent-context file (`knowledge-base/agent-context/<agent>.md`), NOT the agent brain file (`muster/team/<agent>/CLAUDE.md`).
**Update when:** New sprint, task assignment, priority changes, task completion.
**Format:**
- [ ] Task description — Priority: HIGH/MED/LOW — Effort: S/M/L/XL — Due: date
  - Deliverable: [specific output]
  - Dependencies: [agent-name] must complete [thing] first
  - Acceptance criteria: [2-3 bullets]
  - Key skills: [muster/team/<agent>/skills/ paths]
  - Key refs: [knowledge-base/ paths]
**Rules:**
- Keep to 3-5 active tasks max per agent
- Move completed tasks to a "Recently Completed" subsection (keep last 5)
- Archive older completed tasks to decision-log.md
- Tasks must be self-contained — an agent should be able to work from just its agent-context file without reading current-sprint.md

### Cross-Agent Dependencies
Cross-agent dependencies are maintained in agent **brain files** (`muster/team/<agent>/CLAUDE.md`), not in agent-context files. These describe generic role relationships (e.g., "Developer depends on UI/UX for design specs") that apply to any project.
**Update when:** A new agent is added, or the role relationships between agents change.
**Where:** Edit the relevant brain files in the muster submodule. Both sides of a dependency MUST be reflected — if Developer depends on UI/UX, the UI/UX brain file must show "Provides to Developer."
**Remember:** Brain file edits require a muster submodule commit (Rule 13).

## Batch Update Workflow
When a major decision affects multiple agents:
1. Update knowledge-base/ first (product-spec.md, decision-log.md, etc.)
2. List which agents need updates and what each needs to know
3. Update each agent's agent-context file in dependency order (upstream agents first)
4. Verify cross-agent dependencies are mirrored correctly on both sides
5. Update knowledge-base/current-sprint.md if tasks changed

## Adding a New Agent
1. Create `muster/team/<name>/` directory
2. Create `muster/team/<name>/CLAUDE.md` brain file using the standard template (see system-guide.md for template)
3. Create `muster/team/<name>/skills/` directory with domain skill files
4. Create `.claude/agents/<name>.md` startup config in the project repo
5. Update `muster/CLAUDE.md` agent roster table and sub-agent access line
6. Create `knowledge-base/agent-context/<name>.md` in the project repo and populate with PM-managed product context, cross-agent dependencies, and current tasks
7. Add relevant cross-agent dependencies to both the new agent's and existing agents' brain files (`muster/team/<agent>/CLAUDE.md`)

## Research Agent Protocol
The Research agent has a special relationship with the PM:
- Research **owns** knowledge-base/research/ — PM does NOT write to research files directly
- PM communicates with Research via knowledge-base/research/change-log.md
- To request research: add an entry with `status: needs-research`, include context, question, and affected docs
- When Research sets `status: researched`: read the recommendation, make a decision, log in decision-log.md, move entry to Resolved
- See root CLAUDE.md "Scope Change Protocol" for the full flow

## Context Window Management
Agent CLAUDE.md files and startup configs tell agents to read large files (product spec ~800 lines, decision log growing, brand guidelines, design system reference). This creates context window pressure -- agents burn tokens on reading before they start working. Mitigate with these rules:

### Rule 1: Agent CLAUDE.md = Summarized Context, Not a Pointer to Read Everything
Each agent's Product Context section should contain a **self-sufficient summary** of what that agent needs. The agent should be able to start working after reading ONLY their agent-context file and the relevant skill file. Full knowledge-base docs are reference material for edge cases, not required reading.

**Current approach (good)**: Agent Product Context sections are 15-25 lines of filtered, role-specific context with links to full docs.
**Anti-pattern to avoid**: "Read knowledge-base/product-spec.md for all details" as the primary context delivery mechanism.

### Rule 2: Agents Read Full Docs Only When Needed
Agent startup configs (`.claude/agents/*.md`) should instruct agents to:
1. ALWAYS read: Their own `CLAUDE.md` and relevant skill file(s) for the current task
2. Read ON DEMAND: Product spec sections relevant to a specific feature they're working on (not the whole doc)
3. NEVER read at startup: Decision log (PM summarizes relevant decisions in agent context), other agents' files

### Rule 3: Decision Log Stays Append-Only but Agents Don't Read It
The decision log is the PM's tool. Agents should never need to read the full decision log. When a decision affects an agent, the PM updates that agent's Product Context or Current Tasks -- the decision log entry is the audit trail, not the communication channel.

### Rule 4: Split Large Docs When They Cross Thresholds
- Product spec: If it exceeds ~1000 lines, consider splitting into `product-spec-features.md` (feature details) and `product-spec-overview.md` (architecture, monetization, data model). Agents read only the section they need.
- Decision log: When it exceeds ~50 entries, archive older resolved entries to `decision-log-archive.md` and keep only the last 20 in the active file.

### Rule 5: Skill Files are Read-Per-Task, Not Read-All
Agent startup configs should NOT tell agents to read all their skills. They should read the 1-2 skill files relevant to their CURRENT task. The skill index in CLAUDE.md tells them which to pick.

### Rule 6: Framework Changes Must Update System Guide Templates
When you change how agents structurally operate (startup patterns, CLAUDE.md structure, skill requirements), you must also update the templates in `system-guide.md`. The live instances and the templates must always match. See `system-guide.md` → "Framework Change Protocol" for the build checklist, then run the **System Verification Checklist** (same file, next section) to catch gaps across all 8 layers: reference integrity, skill coverage, template sync, ownership, context budget, growth caps, duplication, and failure modes.

## Communication Queue Monitoring

The PM monitors `knowledge-base/agent-requests.md` at every session start as a queue manager.

### Stale Entry Thresholds
- **Requests**: `open` for more than 3 days
- **Handoffs**: `in-review` for more than 3 days, or `needs-revision` for more than 2 days

### Actions on Stale Entries
1. Add a note to the entry's revision log: `[DATE]: PM flagged as stale. [Blocking agent] has not responded in [N] days.`
2. Escalate to founder with: entry ID, title, blocking agent name, and days elapsed.

### Revision Loop Escalation
If any entry has 3 or more revision log items, escalate to the founder. Repeated revision cycles indicate a misalignment that needs founder resolution, not more agent iterations.

### Cleanup Check
Any entry with overall status `done` that is still in the Active Requests or Active Handoffs section should be moved to Resolved as a one-liner. This catches entries where the completing agent forgot the self-cleaning step.

## Orchestration Queue Management

The PM owns `knowledge-base/orchestration-queue.md` — the founder's "what to do next" file.

### Lifecycle
1. **Sprint planning**: Populate the queue with the full agent invocation sequence (see `sprint-planning.md` step 8). Clear the Done section from the previous sprint.
2. **Before each step goes live**: Verify the Next Step agent's agent-context file (`knowledge-base/agent-context/<agent>.md`) Current Tasks has real tasks inlined — not a pointer to current-sprint.md.
3. **After reviewing agent output**: If accepted, confirm the completing agent promoted the next step. If the agent didn't update the queue (e.g., session was killed early), do it yourself. If rejected, add revision notes to agent-requests.md and keep the same agent as Next Step.
4. **Founder decisions**: When a decision requires founder input (per Decision Autonomy Matrix in `decision-making.md`), write it to the Founder Decisions section with context, your recommendation, and what's blocked.

### Growth Cap
Done section: max 5 entries. The completing agent trims, but PM catches any that slip through. PM clears Done entirely at each new sprint.

## Agent Management Principles
- **Read before writing.** Always read the full target agent-context file before making changes. Agents may have added context to non-PM-managed sections (e.g., Agent-Specific Context) that creates dependencies you need to know about.
- **Filter, don't dump.** The PM's job is to be a context translator, not a forwarder. If you find yourself copying entire sections from the knowledge base into an agent's file, stop — link to the source doc instead.
- **Both sides of every dependency.** A dependency that only appears in one agent's file will cause coordination failures. Mirror every dependency on both sides, every time, without exception.
- **Cascade in dependency order.** Update upstream agents first so their outputs are available when downstream agents start work. A Developer who starts before UI/UX has delivered design specs will guess or block.
- **Treat the Research agent differently.** The PM does not write to `knowledge-base/research/`. All Research interactions go through `change-log.md`. This boundary exists to prevent the PM from overwriting validated research with PM assumptions.
