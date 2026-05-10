# Sprint Planning Skill

## Sprint Cycle
- Default sprint length: 2 weeks
- Sprint starts: Define goals, assign tasks across agents, update current-sprint.md
- Mid-sprint: Check-in with the founder, unblock dependencies, adjust priorities
- Sprint end: Review completed work, carry over incomplete tasks, retrospective notes

## Planning Process
0. **Run QA consistency audit** — invoke QA with `consistency-audit.md` skill before planning. Fix all findings before proceeding. This is mandatory at every sprint boundary.
1. Review knowledge-base/current-sprint.md for carry-over items
2. Review knowledge-base/decision-log.md for new decisions needing implementation
3. Break down work into agent-specific tasks with clear deliverables
4. Identify cross-agent dependencies and sequence work (upstream first)
5. Update each affected agent's agent-context file (`knowledge-base/agent-context/<agent>.md`) Current Tasks section with their full task spec (deliverable, priority, effort, acceptance criteria — not just a pointer to current-sprint.md). An agent's agent-context file must be self-contained for their tasks.
6. Mirror all cross-agent dependencies in both agents' files
7. Update knowledge-base/current-sprint.md with the full sprint plan
8. Populate knowledge-base/orchestration-queue.md — translate the sprint plan into a founder-executable sequence of agent invocations (Next Step + Upcoming list). Use the agent invocation sequence from Solo Founder Model below. Clear the Done section from the previous sprint. **Validation**: Do not promote an agent's step to Next Step unless that agent's agent-context file Current Tasks has real tasks inlined (not a pointer to current-sprint.md). **Prompt standard** (mandatory — see full schema in `orchestration-queue.md` Prompt Standard comment): each step's prompt MUST be wrapped in a fenced code block (triple-backtick) with `@<agent-name>` as the first line of the code block (e.g., `@developer` for Developer steps). This makes each step a single copy-paste action — the founder selects the entire code block and pastes one message; the `@<agent>` mention auto-invokes the specialist, the rest is the task instruction. PM steps (handled in the PM-bound tab) omit the @-tag. Each prompt body must include: (a) structured **Inputs** list, (b) **Deliverable** path, (c) **Acceptance criteria** summary with "See `knowledge-base/current-sprint.md` for full criteria" reference, and (d) **On completion** instruction citing the Pre-Handoff Self-Review Checklist (`muster/system-guide.md`).

### Step 9: Skill Gap Scan (Lightweight)
After populating the orchestration queue, scan for skill gaps:
1. For each agent with tasks in this sprint, read ONLY the skill index in their brain file (`team/<agent>/CLAUDE.md` — the "Available Skills" section listing skill names and one-line descriptions). Do NOT read full skill files.
2. Compare assigned tasks against available skills. A gap exists when a task requires methodology not described by any existing skill name/description.
3. If no gaps: proceed. This step should take <2 minutes.
4. If gaps found: note each gap (agent name, task, missing methodology) and add a "PM: Create missing skills" step as the FIRST item in the orchestration queue, before any agent invocations. Do NOT create skills inline during planning — skill creation, classification, and contribution happen in that dedicated queue step using `skill-gap-classification.md`. This protects the sprint planning session's context budget.

## Task Definition Standard
Each task assigned to an agent must include:
- **Clear deliverable**: What "done" looks like (specific output, not activity)
- **Priority**: HIGH / MED / LOW
- **Effort estimate**: S (< 1 day) / M (1-3 days) / L (3-5 days) / XL (5+ days)
- **Dependencies**: What must happen first, from which agent
- **Acceptance criteria**: How we'll know it's done correctly (2-3 bullet points)

## Solo Founder Model
This project is run by a solo founder working with AI agents sequentially — NOT in parallel.

- **Sequential batching**: Group sprint tasks by focus area so the founder isn't context-switching across all domains simultaneously. Example: "Week 1: Design + Content, Week 2: Dev + QA"
- **Sprint length flexibility**: Consider 1-week sprints for faster feedback loops. 2-week sprints may be too long for a solo founder who can't parallelize agent work
- **Agent invocation sequence**: When cascading work, specify the ORDER agents should be invoked:
  1. UI/UX (design direction must exist before dev starts)
  2. Content (brand voice and copy must exist before marketing)
  3. Developer (builds from design specs and content direction)
  4. Legal (can run alongside dev but must complete before launch)
  5. Marketing (needs brand voice, design assets, and product to market)
  6. QA (needs built features to test)
- **Founder review gates**: Build explicit founder approval checkpoints before moving between phases. The founder must approve design direction before dev begins, review content before marketing launches, and sign off on QA results before release

## Capacity Guidelines
- Solo founder works with one agent focus area at a time
- Each agent: 3-5 active tasks per sprint max
- No more than 2 HIGH priority tasks per agent simultaneously
- Dependencies should be resolved in the first half of the sprint
- Leave 20% buffer for unplanned work and blockers

## Sprint Closeout
1. Review each agent's completed tasks
2. Move completed tasks from Current Tasks to decision-log.md as accomplishments
3. Carry over incomplete tasks with updated priority/notes
4. Write sprint summary in current-sprint.md
5. **Archive completed sprint**: Move the completed sprint's task board and summary from current-sprint.md to `knowledge-base/sprint-archive.md`. Only the active sprint should remain in current-sprint.md.
6. **Archive old decisions**: Move decision-log.md entries from before the current sprint to `knowledge-base/decision-log-archive.md`. Keep only entries from the current sprint in the active log.
7. Plan next sprint

## Blocker Protocol
A blocker is any condition that prevents an agent from completing their assigned task.

**Types and responses:**
| Blocker Type | Response |
|---|---|
| Dependency not ready (another agent hasn't delivered) | Re-sequence: pull forward an independent task for the blocked agent; escalate the blocking agent's task to HIGH |
| Spec ambiguity (agent needs a decision to proceed) | Make the decision using the decision-making framework, log it, update the spec, unblock the agent |
| Research gap (spec requires information that doesn't exist) | Pause the blocked task; file a research request via `change-log.md`; assign the agent an independent task in the interim |
| Scope creep discovered mid-task | Apply the scope change protocol from `decision-making.md`; do not let the agent expand scope without explicit PM approval |

Update `current-sprint.md` with blocker status any time a task transitions to blocked. Don't let blockers sit unlogged — they compound.

## Bug Routing Protocol

Bugs found during a sprint (by QA, founder, or any agent) are triaged by PM and routed based on bug type. Not all bugs go straight to Developer — visual, layout, and copy bugs require upstream agent input before a Developer fix.

### Bug Type Classification

| Bug Type | Description | Route |
|----------|-------------|-------|
| **Visual/Layout** | Spacing, positioning, sizing, color, visual hierarchy, animation timing | UI/UX → PM review → Developer → QA |
| **Copy/Voice** | Wrong text, tone mismatch, missing copy, placeholder text in production | Content → PM review → Developer → QA |
| **Visual + Copy** | Layout issue that also involves copy changes (e.g., text too long causing layout break) | UI/UX → Content → PM review → Developer → QA |
| **Logic/Code** | Wrong behavior, incorrect calculations, missing state handling, data bugs | Developer → QA |
| **Integration** | API contract mismatch, data flow between layers, sync issues | Developer → QA |

### Routing Rules

1. **PM classifies bug type during triage** — severity (HIGH/MED/LOW/INFO) and bug type determine the route. PM decides both alone (per Decision Autonomy Matrix).
2. **Upstream agents update specs first** — UI/UX updates the design spec with corrected layout/spacing/tokens. Content updates copy in the design spec. The updated spec IS the fix instruction for Developer.
3. **PM reviews upstream handoffs before Developer starts** — PM checks the spec update for correctness, token validity, and cross-file consistency (using deliverable-review skill). If Content is also involved, Content reviews the UI/UX handoff for copy implications before PM finalizes.
4. **Reviewer set per handoff**: UI/UX handoffs are reviewed by PM + Content (if copy-adjacent) + Developer (feasibility). Content handoffs are reviewed by PM + Developer. Developer handoffs are reviewed by PM + QA.
5. **Logic/Code bugs skip upstream agents** — they go directly to Developer, same as the standard bug-fix wave pattern.
6. **Mixed-type bug batches**: When a wave contains multiple bug types, group by route. UI/UX handles all visual bugs in one session, Content handles all copy bugs in one session, then Developer implements all fixes in one session. This preserves the solo-founder sequential model.

### Wave Structure for Bug Fix Waves

When adding a bug-fix wave to a sprint, structure it based on which bug types are present:

- **Logic-only bugs**: Single wave — Developer fix + QA verify (Wave 3→4 precedent)
- **Visual/Copy bugs present**: Multi-step wave — UI/UX and/or Content first → PM review gate → Developer fix → QA verify
- **Mixed types**: Combine into one wave with ordered steps — upstream agents first (UI/UX, Content), then Developer handles all fix types in one session, then QA verifies everything

## Sprint Planning Principles
- **Sequence before assigning.** Never assign tasks without first mapping dependencies. An agent with three tasks that all depend on another agent's unfinished work has zero effective tasks.
- **The solo founder constraint is a hard constraint, not a preference.** Plan as if parallelism is impossible, because it is. Sequential batching by domain area reduces context-switching cost for the founder.
- **Specificity prevents blockers.** Vague task definitions ("work on the design") generate mid-sprint questions. Specific deliverables ("deliver annotated wireframes for onboarding screens 1-4 in Figma-ready format") don't.
- **Sprint velocity is one agent at a time.** Don't plan sprints as if all agents are running simultaneously. The effective sprint is the sum of sequential agent sessions, not a parallel workstream.
- **Leave the buffer.** The 20% buffer isn't optional. Solo founders working with AI agents encounter unexpected output quality issues, scope clarifications, and decision points that weren't anticipated. Plan for them.
