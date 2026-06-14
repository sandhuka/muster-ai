# Sprint Planning Skill

## Sprint Cycle
- Default sprint length: 2 weeks
- Sprint starts: Define goals, assign tasks across agents, update current-sprint.md
- Mid-sprint: Check-in with the founder, unblock dependencies, adjust priorities
- Sprint end: Review completed work, carry over incomplete tasks, retrospective notes

## Planning Process
0. **Run QA consistency audit** — invoke QA with `consistency-audit.md` skill before planning. Fix all findings before proceeding. This is mandatory at every sprint boundary.
1. **Catch anything an interrupted closeout left behind**: run `bash muster/scripts/muster-list-open-items.sh` and reconcile any lingering items per Sprint Closeout step 5 (close-if-validated / carry-forward / defer) before building the new queue — covers the case where the prior sprint's closeout session ended before the board was reconciled. Then review knowledge-base/current-sprint.md for carry-over items
2. Review knowledge-base/decision-log.md for new decisions needing implementation, and scan `knowledge-base/triage-log.md` **DEFER** entries — deferred observations that were parked for "later" are candidates to pull into this sprint (see `observation-triage.md`)
3. Break down work into agent-specific tasks with clear deliverables
4. Identify cross-agent dependencies and sequence work (upstream first)
5. Update each affected agent's agent-context file (`knowledge-base/agent-context/<agent>.md`) Current Tasks section with their full task spec (deliverable, priority, effort, acceptance criteria — not just a pointer to current-sprint.md). An agent's agent-context file must be self-contained for their tasks.
6. Mirror all cross-agent dependencies in both agents' files
7. Update knowledge-base/current-sprint.md with the full sprint plan
8. Populate knowledge-base/orchestration-queue.md — translate the sprint plan into a founder-executable sequence of agent invocations (Next Step + Upcoming list). Use the agent invocation sequence from Solo Founder Model below. Clear the Done section from the previous sprint. **Validation**: Do not promote an agent's step to Next Step unless that agent's agent-context file Current Tasks has real tasks inlined (not a pointer to current-sprint.md). **Prompt standard** (mandatory — see full schema in `orchestration-queue.md` Prompt Standard comment): each step's prompt MUST be wrapped in a fenced code block (triple-backtick) with `Role: <agent-name>` as the first line of the code block (e.g., `Role: developer` for Developer steps). The `Role:` marker is informational text that tells the founder which role-bound tab to open (or which subagent to spawn from a PM tab) and is parsed by `MUSTER_ROLE=auto` to determine the bind target. **Do NOT use `@<agent>` as the role marker** — Claude Code's input parser auto-routes `@<agent>` mentions to that subagent regardless of the bound role, which causes redundant recursive spawns when the founder pastes a queue step into a role-bound tab. PM steps may omit the `Role:` marker (they're handled directly in the bound PM tab). Each prompt body must include: (a) structured **Inputs** list, (b) **Deliverable** path, (c) **Acceptance criteria** summary with "See `knowledge-base/current-sprint.md` for full criteria" reference, and (d) **On completion** instruction citing the Pre-Handoff Self-Review Checklist (`muster/system-guide.md`). **Optional `Model:` line** (autonomous mode): a `Model: <model-id>` line after `Role:` routes that step to a specific model — the sprint driver passes it as `--model`; absent, the session default applies. Assign at planning time: **Opus-family is the default for queue steps.** The deterministic gates (driver fixture, pillar budgets, commit floor, handoff lint, the quiet-test discipline) guarantee correctness mechanically, so the routine spend buys nothing extra above Opus — premium buys judgment, not correctness. A **premium model (Fable) is the exception, reserved for foundation-critical creation** (novel architecture, judgment-dense doctrine or skill authoring) and **requires explicit founder acceptance at sprint planning**: PM proposes the model plan and the founder confirms the premium steps before the run. A cheaper model (Sonnet/Haiku) is fine for reviews, microcopy, and mechanical cascades. Keep it to that judgment call — no cost matrices or per-model capability tables. **Autonomous-mode vocabulary**: never write "tell/surface/flag to the founder" in a queue prompt — the founder does not read autonomous sessions, so a notice delivered in chat is a swallowed notification. Such instructions must materialize as a file action: append a dated one-line FYI to `knowledge-base/founder-notices.md` (the driver echoes new entries and PM folds them into gate packets), or route a question needing an answer through the PM escalation path.

### Step 8.5: Interleave PM review steps
When populating the queue, interleave `Role: pm` review steps between specialist steps (e.g. after a wave's deliverables) rather than batching all review to the end. In an autonomous run these are the points where PM accepts/reviews handoffs and triages any observations filed in them (`observation-triage.md`). A PM step may omit the `Role:` marker (it defaults to `pm`); use a recognizable title so the queue stays scannable.

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
5. **Reconcile the communication board**: Run `bash muster/scripts/muster-list-open-items.sh` (deterministic enumeration of everything still unresolved in `agent-requests.md` + `research/change-log.md`; detection only — it never blocks closeout). For each **handoff** it lists: if the deliverable was validated — by its own reviewers OR by a later validation/regression handoff — flip it to `done` and move it to Resolved with a one-liner citing the covering HO; otherwise carry it forward with a note. For each **request / research item**: carry-or-defer explicitly. **Conservative default — if you cannot confirm validation, carry forward; never close on assumption.** Invariant: no prior-sprint handoff stays `in-review` after closeout. (Resolved is capped at 10; bulk closures trim oldest — full history lives in git.)
6. **Archive completed sprint**: Move the completed sprint's task board and summary from current-sprint.md to `knowledge-base/sprint-archive.md`. Only the active sprint should remain in current-sprint.md.
7. **Archive old decisions**: Move decision-log.md entries from before the current sprint to `knowledge-base/decision-log-archive.md`. Keep only entries from the current sprint in the active log. **Sweep stale founder-notices**: clear any `knowledge-base/founder-notices.md` entries dated before the current sprint — a between-gate FYI that survived a whole sprint unacted is stale, and since you surface every still-present notice in each gate packet, leaving them bloats future packets. The founder deletes acted-on notices as they go; this closeout sweep is the deterministic backstop (git history preserves anything removed).
8. Plan next sprint

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
6. **Mixed-type bug batches**: When a wave contains multiple bug types, group by route, then **size each route's steps by cohesion** (see "Size steps by cohesion" in Sprint Planning Principles): an agent handles cohesive fixes (shared screen/files/context) in one session; genuinely independent fixes are separate steps. Don't bundle unrelated fixes into one session — in an autonomous run a grab-bag step exhausts the turn budget and stalls. The sequential model is preserved either way (one step at a time).

### Wave Structure for Bug Fix Waves

When adding a bug-fix wave to a sprint, structure it based on which bug types are present:

- **Logic-only bugs**: Single wave — Developer fix + QA verify (Wave 3→4 precedent)
- **Visual/Copy bugs present**: Multi-step wave — UI/UX and/or Content first → PM review gate → Developer fix → QA verify
- **Mixed types**: Combine into one wave with ordered steps — upstream agents first (UI/UX, Content), then Developer handles the fixes grouped by cohesion (cohesive fixes together; independent fixes as separate steps — see "Size steps by cohesion"), then QA verifies everything

## Wave Gates (Autonomous Sprint Runs)

When a sprint runs unattended (`muster/scripts/muster-sprint-run.sh`), the autonomous unit is a **wave, not the whole sprint**: the loop runs a wave, the founder reviews at the wave boundary, then the loop resumes into the next wave. Worst-case unwind is one wave, never a sprint. Two containment layers — mechanical gates inside a wave, human gates between waves — and **both ride on the existing `Role: halt` signal**; planning conventions are all that's new (no driver changes, no new queue primitive).

### Wave sizing
Size a wave as the largest run of steps whose output can be verified in one review pass. Keep waves small enough that one bad wave is cheap to discard. A natural wave boundary is where the surface being built changes (logic → UI) or where a deliverable needs human eyes before later steps build on it.

### Conditional gate flag (the autonomy dial)
Not every wave needs a human gate. At planning, flag each wave: *does it produce something only a human can verify?*
- **Backend / logic wave** → covered by automated tests → **no gate step; the loop flows straight through.**
- **UI / behavioral wave** → needs human eyes → **insert a gate step at its end.**
A conditional gate is therefore just the presence or absence of a gate step — zero new machinery. As automated testing improves, fewer waves qualify for a human gate and autonomy grows.

### Gate-step insertion convention
For each wave needing human verification, insert a **wave-gate step** at its end:
- A `Role: halt` step with a recognizable title (e.g., `### [DATE] Wave N Gate — founder review`). The loop already stops on `Role: halt`.
- Its block points to the build and to `knowledge-base/wave-review.md`, where PM writes the human-only verification checklist (Output) and the founder writes the verdict (Input). The loop does not parse `wave-review.md`; PM reads it on resume.
- **Fold unread founder notices into the gate packet.** When writing the wave-review checklist, check `knowledge-base/founder-notices.md`: list any entries still present under a "Notices since last gate" heading in the packet, so a founder who only reads at gates sees every between-gate FYI. The founder deletes notices once acted on.
- Resume after a gate is **not** a blind re-run (a mechanical `Role: halt` can't self-clear): the founder writes their verdict to `wave-review.md`, then runs `muster/scripts/muster-sprint-resume.sh` **from inside the sprint worktree** (it operates on the CWD's queue and `wave-review.md`; the wrong tree processes the wrong files), which has PM process the verdict (insert a fix step per bug, or clear the gate and promote the next wave's first step if approved) and then re-enters the loop.
- **Changes-requested processing keeps one step per Next Step.** When PM processes a bugs-found verdict, the fix goes as the **single** `## Next Step`; the re-review `Role: halt` gate goes as the **first `## Upcoming` entry** (after any additional fixes), never as a second fenced block in `## Next Step`. Two steps there risks the fix's closeout promoting the wrong step and dropping the re-review gate — a skipped human re-verification, exactly what the gate exists to prevent. The driver enforces this mechanically: it stops if `## Next Step` holds more than one fenced step.

### Mechanical gate — halt on red build / failing tests
Agents must **not advance the queue past a red build or failing tests**. Rather than calling the founder directly, a specialist routes the failure to PM (re-points `## Next Step` to a `Role: pm` assessment step — see `decision-making.md` → Autonomous-mode boundary), and PM sets `Role: halt` (the hard-stop form of test-failure discipline, self-review item 8, for autonomous runs). This contains mechanical compounding on every wave, gated or not, while keeping PM the sole party that summons the founder. Halt-on-red is the rule; an autonomous fix-loop is deliberately not used.

## Sprint Planning Principles
- **Sequence before assigning.** Never assign tasks without first mapping dependencies. An agent with three tasks that all depend on another agent's unfinished work has zero effective tasks.
- **The solo founder constraint is a hard constraint, not a preference.** Plan as if parallelism is impossible, because it is. Sequential batching by domain area reduces context-switching cost for the founder.
- **Specificity prevents blockers.** Vague task definitions ("work on the design") generate mid-sprint questions. Specific deliverables ("deliver annotated wireframes for onboarding screens 1-4 in Figma-ready format") don't.
- **Size steps by cohesion, not by turn count.** A step is one cohesive unit of work — group changes that share context, separate changes that don't. Three bugs on the same screen (same files, same mental model) are one step; splitting them just forces re-reading the same files and re-deriving the same context. Three bugs on unrelated screens are three steps. A single feature is one step — unless it's large enough to strain the per-step turn budget or carry too much context, in which case decompose it along its most natural internal seam (data model → UI → wiring), which are themselves cohesive sub-units. The test is *what belongs together*, never an arbitrary turn count. Don't bundle unrelated changes into one step: it's harder to review and recover, and in an autonomous run a grab-bag step exhausts `MAX_TURNS` and stalls. When a step is large but genuinely cohesive, raise `MAX_TURNS` rather than fragment shared context — but split a *too-large* cohesive task along a real internal seam, not by leaning on an ever-higher cap.
- **Sprint velocity is one agent at a time.** Don't plan sprints as if all agents are running simultaneously. The effective sprint is the sum of sequential agent sessions, not a parallel workstream.
- **Leave the buffer.** The 20% buffer isn't optional. Solo founders working with AI agents encounter unexpected output quality issues, scope clarifications, and decision points that weren't anticipated. Plan for them.
