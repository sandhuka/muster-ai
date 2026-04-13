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
8. Populate knowledge-base/orchestration-queue.md — translate the sprint plan into a founder-executable sequence of agent invocations (Next Step + Upcoming list). Use the agent invocation sequence from Solo Founder Model below. Clear the Done section from the previous sprint. **Validation**: Do not promote an agent's step to Next Step unless that agent's agent-context file Current Tasks has real tasks inlined (not a pointer to current-sprint.md). **Prompt standard**: Each step's prompt must include: (a) structured deliverables list, (b) acceptance criteria pulled from current-sprint.md, (c) "Reference knowledge-base/current-sprint.md for full acceptance criteria" instruction, and (d) "Before filing your handoff, run the Pre-Handoff Self-Review Checklist (system-guide.md)" instruction.

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
5. Plan next sprint

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

## Sprint Planning Principles
- **Sequence before assigning.** Never assign tasks without first mapping dependencies. An agent with three tasks that all depend on another agent's unfinished work has zero effective tasks.
- **The solo founder constraint is a hard constraint, not a preference.** Plan as if parallelism is impossible, because it is. Sequential batching by domain area reduces context-switching cost for the founder.
- **Specificity prevents blockers.** Vague task definitions ("work on the design") generate mid-sprint questions. Specific deliverables ("deliver annotated wireframes for onboarding screens 1-4 in Figma-ready format") don't.
- **Sprint velocity is one agent at a time.** Don't plan sprints as if all agents are running simultaneously. The effective sprint is the sum of sequential agent sessions, not a parallel workstream.
- **Leave the buffer.** The 20% buffer isn't optional. Solo founders working with AI agents encounter unexpected output quality issues, scope clarifications, and decision points that weren't anticipated. Plan for them.
