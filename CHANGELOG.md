# Muster Version History

Framework version lives in `VERSION`. This file tracks what changed at each bump so you can
trace behavior to a version. Newest first.

Versioning: **major** = a workflow or routing model change that existing projects migrate to
(ships with a `MIGRATING-*` guide); **minor** = additive capability or hardening that arrives on
the next `muster/` submodule pointer bump with no project-side migration.

---

## 4.2 — 2026-06-11

Autonomous-loop operability — everything the first real field sprint (Arogh Sprint 5) surfaced.
Display/routing only; the deterministic control floor (stop conditions, guards, lint) is untouched.

- **New — trail rebuild** (`muster-sprint-run.sh` + `muster-sprint-format.sh`): per-step trail
  lines carry the queue's own step heading (`▶ Step 16 — Content: …`) instead of the iteration
  counter, which is demoted to plumbing (run-start `run budget: N steps`, ~80% warning, and a
  self-explaining cap-stop message); halts print a self-explaining HALT block (wave-gate +
  PM-escalation guidance); each step closes with an icon-count activity summary and token
  telemetry (`✓ 74 turns · $4.05 · peak ctx 188k/1M 19% · out 21k` — peak ctx = largest single
  prompt, the step-sizing signal; total input deliberately excluded as misleading); runs end
  with a per-step summary table + totals + stop reason. New `run-<ts>.metrics` file per run.
  Deviation from the parked spec: the live per-event river is KEPT (paths are the diagnostic
  trail); compression is the step-close summary line, not in-place ticking.
- **New — per-step model routing**: optional `Model: <model-id>` line in a queue step's fenced
  block (after `Role:`) is passed as `--model`; absent → session default; value echoed into the
  flag, never branched on (invalid id = stop condition 4). `sprint-planning.md` Prompt standard
  documents assignment-by-step-weight; trail header shows `[model]` when overridden.
- **New — step-boundary commit floor**: first prose-trust failure observed in the field (a model
  override skipped its closeout commit, blurring two steps' work). At the end of each successful
  step, the driver commits any uncommitted changes (`sprint step boundary: <step heading>`);
  no-op on a clean tree. `--ignore-submodules=dirty`; logs dir excluded.
- **New — founder-notices channel**: field incident — a queue step's "surface the pod-build
  track to the founder" executed correctly into the run log, which nobody reads; the notice
  silently died and the deadline-bearing track was discovered days later. Fix is file-mediated:
  agents append dated one-line FYIs to `knowledge-base/founder-notices.md` (new template); the
  driver diffs it after each step, echoes new entries (📣), and counts them in the run summary;
  PM folds unread notices into the next `wave-review.md` packet; the driver also alerts (📌)
  when `## Founder Decisions` changes mid-run. Wrapper prompt + `sprint-planning.md` Prompt
  standard ban "tell/surface to the founder" vocabulary in favor of file actions. Driver reads
  both channels, never writes them.
- **Fixed:** formatter forces `LC_ALL=C` — macOS bash 3.2 multibyte case-glob/trim corrupts
  emoji under UTF-8 locales (eats lead bytes, breaks counters). Run logs get a PID suffix so
  same-second runs can't share files.
- **Changed:** `system-guide.md` → Autonomous Sprint Execution documents all of the above.
- Verified end-to-end against a disposable stub-claude fixture (17 assertions: labels, telemetry,
  model flag pass-through, cap/halt messages, summary table, commit floor, clean-tree invariant).

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
