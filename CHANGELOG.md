# Muster Version History

Framework version lives in `VERSION`. This file tracks what changed at each bump so you can
trace behavior to a version. Newest first.

Versioning: **major** = a workflow or routing model change that existing projects migrate to
(ships with a `MIGRATING-*` guide); **minor** = additive capability or hardening that arrives on
the next `muster/` submodule pointer bump with no project-side migration.

---

## 4.2 — 2026-06-11

Step-boundary commit floor — first prose-trust failure observed in field use (Arogh Sprint 5:
a model override ran a step that skipped its closeout commit, blurring two steps' work and
breaking the one-commit-per-step review unit).

- **Changed:** `scripts/muster-sprint-run.sh` — at the end of each successful step, if the agent
  left uncommitted changes, the driver commits them (`sprint step boundary: <step heading>`).
  No-op on a clean tree (agents committing in closeout remains the convention; this is the
  deterministic floor). `--ignore-submodules=dirty` so a hand-patched `muster/` checkout doesn't
  fire it every step; run-logs dir excluded.
- **Changed:** `system-guide.md` → Autonomous Sprint Execution documents the floor.

## 4.1 — 2026-06-09

Handoff / request boundary reconciliation — closes the gap where unresolved items leaked across
sprint boundaries (handoffs validated collectively by a regression sweep never reached `done`;
nothing swept the board at the boundary).

- **New:** `scripts/muster-list-open-items.sh` — deterministic, detection-only enumerator of
  everything still unresolved in `agent-requests.md` (Active Handoffs + Active Requests) and
  `research/change-log.md` (Active), with item age. Always exits 0 and never halts; it is *not*
  wired into the autonomous loop's lint gate (in-review handoffs are legitimate mid-sprint).
- **Changed:** `sprint-planning.md` §Sprint Closeout gains a reconciliation step — run the
  enumerator, close validated handoffs (citing the covering HO), carry the rest forward;
  conservative default is carry-forward. Invariant: no prior-sprint handoff stays `in-review`.
- **Changed:** `sprint-planning.md` Planning Process runs the same enumerator at planning start,
  catching anything an interrupted/skipped closeout left behind before the new queue is built.
- **Changed:** `system-guide.md` §Status Lifecycles documents the boundary-reconciliation close
  path so the lifecycle and the closeout rule agree.

Migration: none — arrives with the submodule pointer bump; the closeout/planning sweep applies at
the next sprint boundary.

---

## 4.0 — 2026-06-07

Autonomous sprint execution. Manual and Assisted workflows unchanged; v4 adds a hands-off mode.
See [MIGRATING-V3-TO-V4.md](MIGRATING-V3-TO-V4.md).

- Sprint loop (`muster-sprint-run.sh`) walks the orchestration queue unattended in an isolated
  worktree, a fresh agent per step, advancing the queue itself.
- Wave gates — PM can plan a `Role: halt` gate for human verification; resume via
  `muster-sprint-resume.sh` after writing a verdict to `wave-review.md`.
- PM-sole-escalation gatekeeping — specialists never call the founder directly; only PM (or a
  planned wave gate) halts the loop.
- Observation triage — agents file non-blocking observations; PM triages them to `triage-log.md`
  without adding queue steps.
- Handoff-filing integrity lint (`muster-lint-handoff.sh`) + run observability under
  `.muster-sprint-logs/`.

---

## 3.0

Explicit role-picker at session start, replacing v2's implicit "Root Claude is PM" model. PM
becomes a peer agent like the other seven; every session binds to one role for its lifetime.
See [MIGRATING-V2-TO-V3.md](MIGRATING-V2-TO-V3.md).

---

## 2.0

- `.populated` routing signal (`knowledge-base/agent-context/.populated`) — the first file Root
  Claude reads to decide its mode (onboarding / greenfield / steady-state).
- Specialist HALT check — specialists read `.populated` first and halt if their entry is `null`;
  PM catches the halt and runs JIT populate.
- Slim `.populated`-based routing block in the project root `CLAUDE.md`.

See [MIGRATING-V1-TO-V2.md](MIGRATING-V1-TO-V2.md).

---

## 1.0

Initial release — multi-agent product team (8 roles), shared Muster submodule, file-based
knowledge base, and the agent communication / handoff protocol.
