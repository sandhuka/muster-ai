# Orchestration Queue
<!-- This file tells the founder which agent to invoke next. PM populates at sprint planning. Agents update on session completion. -->
<!-- Protocol: See muster/system-guide.md → Invocation Patterns and Agent Communication Protocol. -->

## Prompt Standard

<!-- Every Next Step / Upcoming entry wraps the prompt in a fenced code block so the founder can copy the whole block in one shot. The @<agent> mention on the first line is a role marker — see `muster/CLAUDE.md` → '@-mention prefix in user messages' for the routing rule (matching role tab → execute body directly; non-matching role tab → spawn subagent; `MUSTER_ROLE=auto` → parse as bind target). -->

<!-- Specialist-agent format:

### [DATE] [Agent (platform)]: [Step title]

```
@<agent-name>

**Task:** [1-line description]

**Inputs:**
- `path/to/file1.md`
- `path/to/file2.md`

**Deliverable:** `path/to/output` (or handoff ID)

**Acceptance criteria:** See `knowledge-base/current-sprint.md` for full criteria. Summary: [2-3 bullets].

**On completion:** File handoff in `agent-requests.md`. Run the Pre-Handoff Self-Review Checklist (`muster/system-guide.md`) before filing — item 9 enforces queue + decision-log update.
```

Platform tag in the heading: use the task's platform when it's single-surface
(e.g., "Developer (ios): ...", "Developer (web): ..."), `cross-platform`
when the task spans surfaces, or omit the parenthetical for platform-agnostic
tasks (e.g., "Legal: ...", "Marketing: ..."). Keeps the queue scannable for
multi-surface projects.

Available @-tags: `@developer`, `@ui-ux`, `@qa`, `@content`, `@marketing`,
`@legal`, `@research`, `@pm`. PM steps typically omit the @-tag because
the founder handles them in the PM-bound tab (no specialist to invoke);
include `@pm` only if the step is a one-shot consult intended for spawning
PM as a subagent from another role-bound session.

PM-step format (no @-tag):

### [DATE] PM: [Step title]

```
[Task description for the PM-bound tab. No @<agent> tag — handled in the
PM tab directly without spawning a subagent.]
```
-->

## Founder Decisions
<!-- Agents add questions requiring founder input here. -->
<!-- PM monitoring: scan this section at every session start. Entries older than 24h without founder response are flagged to the founder immediately. -->
<!-- Format: - [DATE] [Agent]: [Question] -->

## Next Step
<!-- The single next agent invocation. Copy the ENTIRE code block (including @<agent> at the top) and paste as one message in Claude Code. -->
<!-- @<agent> behavior depends on receiving session — see muster/CLAUDE.md '@-mention prefix' rule. Bound to that role: header is informational, task body executes directly. Bound to a different role (typically PM): @<agent> spawns the named subagent with the body as prompt. -->

## Upcoming
<!-- Ordered sequence of remaining steps for this sprint. -->

## Done (Last 10)
<!-- Completed steps. Growth rules: Done keeps max 10 entries (trim oldest on overflow). PM clears Done entirely at each new sprint. -->
<!-- Format: - [DATE] [Agent]: [One-line summary] -->

