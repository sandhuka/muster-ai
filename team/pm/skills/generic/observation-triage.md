# Observation Triage Skill

## Purpose
How PM disposes of **observations** filed by agents in handoffs (`agent-requests.md` → Handoff Entry → Observations block). Observations are items an agent noticed that are *not* tied to whether the deliverable passes review — tech debt, hygiene, a scope idea. They are non-blocking by definition. This skill is the per-observation routing flow; the **authority call (handle vs. escalate) lives only in the Decision Autonomy Matrix** (`decision-making.md`) — this skill points there, it does not restate it.

## Per-observation flow
For each `OBS-NNN` in a handoff:
1. **Read** the observation (title, severity, evidence, suggested action).
2. **Classify authority** using the Decision Autonomy Matrix in `decision-making.md` (PM Decides Alone vs. Escalates, plus the senior-PM self-check). Do not duplicate that logic here.
3. **Write a disposition line** on the observation in the handoff: `Disposition: <ACT|DEFER|IGNORE|ESCALATE> — <target or rationale>`.
4. **Route** per the table below.
5. **Log one line** in `triage-log.md` (every disposition, no exceptions).

## 4-way disposition + routing (PROVISIONAL — see note)
| Disposition | Meaning | Route to |
|---|---|---|
| **ACT** | Worth doing now, within approved scope | A `REQ` in `agent-requests.md` addressed to an **already-scheduled** agent. **Never** a new queue step. |
| **DEFER** | Worth doing, not now | `pre-launch-checklist.md` (if milestone-gated) **or** roadmap / next-sprint as a sub-field. **No `backlog.md`.** |
| **IGNORE** | Not worth acting on | A `triage-log.md` line only (the audit trail *is* the record). |
| **ESCALATE** | Needs a founder call | `## Founder Decisions` in `orchestration-queue.md` (**non-halting** — see integration rules). |

> **PROVISIONAL:** these four categories and their routing are a first cut. They are calibrated after the first real autonomous run produces actual observation data — expect the boundaries (especially ACT vs. DEFER, and what reaches IGNORE) to shift. Do not treat them as settled or gold-plate around them.

## triage-log.md line format
`- YYYY-MM-DD | OBS-NNN (HO-NNN) | DISPOSITION | summary | rationale-or-target`
Log **all** dispositions, including IGNORE — silent autonomous handles are exactly the class the founder needs to be able to audit. `triage-log.md` is tier-2 (read on demand, never a startup read) and is archived at sprint closeout.

## Integration rules (must hold — these keep triage from breaking the loop)
1. **Non-halting escalation.** An escalated observation parks in `## Founder Decisions` and the loop keeps running; the founder reviews it at the bookend. Only genuine hard blocks set `Role: halt` (see `decision-making.md` → Autonomous-mode boundary). If observation escalations halted, a long run would stop on the first one.
2. **No autonomous scope mutation.** Triage never invents queue steps. ACT routes only to an agent already scheduled in the sprint; anything needing *new* scope is an ESCALATE, not an ACT.
3. **Single authority source.** Handle-vs-escalate is decided only by the Decision Autonomy Matrix. This skill routes; it never defines a second authority rule.

## Principles
- **Route, don't re-decide.** If you find yourself reasoning about *whether* PM has authority, you're in the matrix's job — go read it, don't re-derive it here.
- **The log is the safety net.** Because ACT/DEFER/IGNORE can all happen without the founder, the `triage-log.md` line is non-optional — it's what makes silent handling auditable.
