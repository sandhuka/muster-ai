# Muster Version History

Framework version lives in `VERSION`. This file tracks what changed at each bump so you can
trace behavior to a version. Newest first.

Versioning: **major** = a workflow or routing model change that existing projects migrate to
(ships with a `MIGRATING-*` guide); **minor** = additive capability or hardening, non-breaking.
Most of a minor arrives on the next `muster/` submodule pointer bump; any new project-level files
it adds (knowledge-base templates, `.claude/skills/*`, `scripts/test.sh` — these live outside the
submodule) are seeded copy-if-absent by re-running the live upgrade script. No breaking migration.

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
- **New:** `scripts/test-sprint-driver.sh` — the stub-claude end-to-end fixture that verified
  this release (22 assertions: labels, telemetry, model pass-through, cap/halt messages, summary
  table, commit floor, notices echo, clean-tree invariant), checked in as the standing regression
  gate for any change touching the driver or formatter. First slice of the framework regression
  suite. Deterministic, remote-severed, self-cleaning on green.

### Bundle 2 — the framework agent + self-healing run (founder-approved 2026-06-12, built via `private/builds/4.2/`)

The framework gains its own agent and the autonomous loop becomes self-healing. This bundle adds
surface (an agent) and touches control flow (auto-resume, continuation), unlike Bundle 1's
display-only changes — the driver fixture grew to 35 assertions to cover it.

- **New — Muster, the framework's own agent** (`MUSTER.md` at repo root, `guide/skills/`,
  `private/xo/`): one persona, two homes — the **Guide** in a project, the **XO** in the
  framework repo. Question-routing is the load-bearing rule: **process** questions (where did the
  run stop, which mode, how to resume) are the Guide's; **project** questions (what did the
  developer decide) route to PM, never answered from a stale read. Constraints: it is an **opt-in
  load, not a 9th picker role** (the picker is untouched); **`/muster` is the single front door**
  — name-invocation was dropped (a deterministic harness trigger beats a prose trigger that can
  mis-fire), and `/muster` branches on bound state (unbound → bind; bound → one-shot consult, the
  tab keeps its role). The Guide **never writes product state** (queue, knowledge-base, code) —
  only framework plumbing (`.muster/config`, drafted reports). The **XO is founder-only via three
  locks** (possession of `private/`, repo write perms, channel auth) and obeys a **no-meta-loop
  fence** (never runs autonomous sprints on the framework repo).
- **New — `.muster/config` knob layer** (`templates/.muster/config`, sourced by the driver):
  project-local, committed so worktrees inherit it. Precedence is **explicit env > config >
  built-in default**, enforced in the driver (invocation env captured and re-applied around the
  source). Day-one knobs are every variable the driver already read from the environment
  (`MAX_STEPS`, `MAX_TURNS`, `ANTHROPIC_MODEL`, `KEEP_RUNS`, `LIMIT_RESUME_AT`) — exposing them
  is free. Constraint: **no speculative knobs** — new ones arrive only via knob-ify when field
  reports prove demand.
- **New — self-healing-run trio** (`muster-sprint-run.sh` only): **sleep-proof loop**
  (`caffeinate -i -w $$` held for the driver's lifetime, `command -v`-guarded so non-mac is a
  no-op); **mid-step continuation** (a dirty tree at step start — guaranteed meaningful by
  Bundle 1's commit floor — prepends a continue-don't-restart preamble to the wrapper prompt and
  prints `↻`; the queue is never edited); **limit-aware auto-resume** (a usage-limit death is
  classified against the real captured 429 payload, then the driver sleeps past the stated reset
  +buffer and re-enters the step). Constraints, all do-not-revisit: **proactive pre-step
  usage-gating is REJECTED** (no reliable usage signal; the economics are illusory — reactive
  only); **classification is fail-closed** (any uncertainty halts as before); auto-resume bridges
  this one mechanical error class and **never a `Role: halt` founder checkpoint**; **deliberate
  discard of partial work stays manual** (`git checkout .` by the founder — destructive choices
  are never automated).
- **New — `STATUS` run-status surface** (`$LOGDIR/STATUS`, ~8 lines, overwritten at run/step
  start, step end, limit-sleep, and final): the deterministic answer to multi-tab state sync and
  the **first rung of the Guide's cheap-read ladder** — it carries the *mid-step* state the trail
  and metrics (completed work only) cannot. Excluded from the commit floor's pathspec, so it
  never pollutes step commits.
- **New — quiet-test discipline** (`templates/scripts/test.sh` + testing-skill edits): test
  EXECUTION is free, test OUTPUT is not (a verbose xcodebuild suite ingested per fix-iteration
  was the dominant cost of a $47 field step). The runner sends raw output to a log and only
  pass/fail counts + failing `file:line` + exit code to the session; skills add **targeted-then-
  full** iteration (affected class while fixing, full suite once at pre-closeout). Constraint:
  **CI-as-the-gate is REJECTED** (agents must know green BEFORE closeout — the queue never
  advances past a red build; post-commit CI is async and nobody watches it). CI is a welcome
  **backstop** feeding `founder-notices.md`, never the gate.
- **New — pillar-budget gate** (`scripts/test-pillar-budgets.sh` + `.github/workflows/muster-ci.yml`):
  the always-read (tier-1) token surface is statically measurable, so it is guarded mechanically
  — project `CLAUDE.md` template, each agent bootloader, `MUSTER.md`, the driver's wrapper prompt
  (char budget), the tier-1 bind-path total (Rule 14's 600 lines), and always-read KB templates.
  Budgets set at encoding size + ~10% headroom: green at birth, red on GROWTH. The fixed-cost
  audit converted from prose duty to release gate. CI runs both gates on every push/PR.
- **Changed — model policy inverted** (`sprint-planning.md`): **Opus-family is now the default**
  for queue steps — the deterministic gates guarantee correctness mechanically, so premium buys
  judgment, not correctness. A **premium model (Fable) is the exception, reserved for
  foundation-critical creation and requiring explicit founder acceptance** at planning (PM
  proposes, founder confirms). Replaces the prior "strongest model by default" guidance.
- **New — field-report feedback pipeline** (`guide/skills/field-report.md` + XO `triage.md`):
  the Guide drafts a scrubbed framework-level report, shows the **verbatim payload** as the
  consent gate (never sends what the user hasn't seen character-for-character), and files it via
  `gh issue create --label field-report`; the XO pulls open reports at bind time and closes the
  loop with outcome labels (`shipped-in-4.2` / `captured` / `rejected`). Constraint:
  **shipping credentials with the framework was REJECTED** (public repo = key theft) — the
  fallback prints the report for manual filing instead.
- **New — verification-discipline skill** (`team/qa/skills/generic/verification-discipline.md`):
  trust-then-verify as shared methodology — independently re-run checks, mechanical-over-prose,
  build a fixture if none exists, verify against source-of-truth not summaries. QA-owned, with
  cross-role pointers (PM accepting handoffs, Developer before handoff) and XO cross-load before
  declaring a framework change shipped.
- **New — migration regression gate** (`scripts/test-migrate.sh`, wired into CI): a throwaway
  v3-project sandbox exercises `migrate-v3-to-v4.sh` for dry-run safety, copy-if-absent seeding
  (`founder-notices.md`, `.muster/config`, `.claude/skills/*`, `scripts/test.sh`), preservation,
  idempotency, and no-clobber of a user's config or skill. Scoped to **v3→v4 only** — the live
  upgrade path; v1→v2 and v2→v3 are finite historical populations and deliberately not gated
  (gating a run-once path is upkeep with no ongoing payoff).
- **Fixed — the upgrade path now delivers project-level files that live outside the submodule**:
  the live "bring current" script (`migrate-v3-to-v4.sh`) also seeds `.claude/skills/*` (the
  `/muster` front door, `/rebind`) and `scripts/test.sh`, copy-if-absent. These sit OUTSIDE the
  submodule, so a pointer bump alone never delivered them — an upgraded project got the Guide's
  code but not its `/muster` skill, the one thing the CHANGELOG calls the single front door. The
  migration gate now asserts both seed and no-clobber-of-a-customized-skill.
- **New — Muster-agent contract gate** (`scripts/test-muster-agent.sh`, wired into CI): asserts
  the deterministic Guide/XO scaffold — the carve-out, `MUSTER.md` bind commands, `muster-bind.sh`
  accepting `guide`/`xo`, the status-line chain rendering `[muster: xo]`, the guide skills, the
  `/muster` front door — and the XO loadout conditionally (only when `private/xo/` is present, so
  public CI skips it gracefully). Guards the **plumbing** the agent behaviors stand on; the
  model-judgment layer is out of scope (needs a live run, regresses only when the driving prose
  changes).
- **Convention — build proposals** (`release-discipline.md`): a non-trivial build earns an HTML
  proposal at `private/builds/<version>/<name>-proposal.html` (ranking/what/why/stress-cases —
  including those that did NOT survive, carried as named open questions/regression/commit plan)
  before code. **No-build is a valid ruling** (`roi-doctrine.md`): "what should we build next?"
  may answer "validate/release first" — no proposal is manufactured for it.

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
