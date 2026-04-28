# Orchestration Queue
<!-- This file tells the founder which agent to invoke next. PM populates at sprint planning. Agents update on session completion. -->
<!-- Protocol: See muster/system-guide.md → Invocation Patterns and Agent Communication Protocol. -->

## Prompt Standard

<!-- Every Next Step / Upcoming entry wraps the prompt in a fenced code block so the founder can copy the whole block in one shot. The @<agent> mention at the top auto-invokes that specialist when the message is sent in Claude Code — no need to type @-tag separately. -->

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
`@legal`, `@research`. (PM is Root Claude — no @-tag; user talks to Root
Claude directly.)

PM-step format (no @-tag):

### [DATE] PM: [Step title]

```
[Task description for Root Claude. No @<agent> tag — Root Claude IS the PM.]
```
-->

## Founder Decisions
<!-- Agents add questions requiring founder input here. -->
<!-- PM monitoring: scan this section at every session start. Entries older than 24h without founder response are flagged to the founder immediately. -->
<!-- Format: - [DATE] [Agent]: [Question] -->

## Next Step
<!-- The single next agent invocation. Copy the ENTIRE code block (including @<agent> at the top) and paste as one message in Claude Code. -->
<!-- The @<agent> mention auto-invokes that specialist; the rest of the message is the task instruction. -->

## Upcoming
<!-- Ordered sequence of remaining steps for this sprint. -->

## Done (Last 10)
<!-- Completed steps. Growth rules: Done keeps max 10 entries (trim oldest on overflow). PM clears Done entirely at each new sprint. -->
<!-- Format: - [DATE] [Agent]: [One-line summary] -->

