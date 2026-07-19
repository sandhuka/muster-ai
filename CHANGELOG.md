# Muster Version History

Framework version lives in `VERSION`. This file tracks what changed at each bump so you can
trace behavior to a version. Newest first.

Versioning: **major** = a workflow or routing model change that existing projects migrate to
(ships with a `MIGRATING-*` guide); **minor** = additive capability or hardening, non-breaking.
Most of a minor arrives on the next `muster/` submodule pointer bump; any new project-level files
it adds (knowledge-base templates, `.claude/skills/*`, `scripts/test.sh` — these live outside the
submodule) are seeded copy-if-absent by re-running the live upgrade script. No breaking migration.

---

## 4.6 — Unreleased

Fixed-cost audit pass on the always-read surface, plus a planning-quality addition. Theme: tokens
are spent at read time, so author-only guidance must not ride on files every agent reads every
session. Net tier-1 bind-path: **384 → 302 lines** (−82, every session, every project, forever),
zero behavior lost, all pillar budgets green (20/20).

- **New — Cold-Start Sufficiency Test** (`team/pm/skills/generic/sprint-planning.md`, with pointers
  in `context-cascading.md` + `decision-making.md`): a completeness gate PM runs whenever it authors
  OR edits a queue step (not just at planning — also wave-gate fixes, blocker re-sequences, JIT
  populate). The existing anchor rules make each *reference* resolvable; this asks whether the *set*
  is complete — list the decisions the cold headless agent must make to satisfy the
  Deliverable/Acceptance, verify each is specified or cited. Catches the unstated-assumption a cold
  agent fills by guessing and ships. On-demand skill, zero always-read cost.
- **Token — author-only templates moved off the always-read surface.** Three seeded KB templates
  carried entry/format templates that only the *author* needs, but every agent reads the files at
  session start: queue step-authoring schema → `sprint-planning.md` "Queue Step Format"
  (`orchestration-queue.md` 66→27); inter-agent entry templates (a duplicate of the canonical
  `system-guide.md` block) → pointer (`agent-requests.md` 40→12); task-board format →
  `sprint-planning.md` "Task Definition Standard" (`current-sprint.md` 40→25). Single-source in each
  case; structure stays backstopped by the lints + the files' own live entries. Fixed a now-stale
  `system-guide.md` claim that the entry templates "also live as HTML comments in the file itself."
- **Fix — refuse to spawn a sprint worktree from a dirty tree** (`scripts/muster-guard-clean-tree.sh`,
  sourced by `muster-sprint-new.sh` + `muster-sprint-sandbox.sh`). `git worktree add` checks out from
  HEAD, so any uncommitted work — modified/staged/untracked files, or an uncommitted `muster/` pointer
  bump (which silently runs the *old* submodule version) — was absent from the run. The top
  autonomous-launch footgun, from a field report. Deterministic guard, one shared file (no drift, same
  pattern as `muster-guard-worktree.sh`); `MUSTER_ALLOW_DIRTY=1` overrides for deliberate scratch.
  Fixture: `scripts/test-sprint-new.sh` (11 cases), wired into CI.

> **Existing-project propagation note (read before bumping the submodule pointer to 4.6):** the
> *skill* changes above (sprint-planning, context-cascading, decision-making, system-guide) live in
> the submodule and arrive automatically on pointer bump — so an existing project gets every
> behavioral improvement for free. The three trimmed files are **seeded `knowledge-base/` templates
> copied into each project's own repo at setup**; a pointer bump does NOT touch them (and migration
> scripts deliberately never edit KB content). An un-migrated project keeps ~82 lines of inert
> comment blocks (harmless redundancy, recurring token cost — not a break). To realize the token
> saving in an existing project, manually delete those comment blocks from its
> `orchestration-queue.md` / `agent-requests.md` / `current-sprint.md` and paste the same pointer
> lines the templates now use. No migration script — over-engineering for a comment cleanup, and it
> would break the "migration never edits KB files" safety invariant.

## 4.5 — 2026-06-25

Autonomous-run trust + telemetry, plus discipline and process hardening. Theme: the driver's
per-step read-out should be believable and informative, the release gates should measure what they
claim to, and the planning that feeds an autonomous run should be sound. **No token-floor regression**
— the telemetry/driver work is zero always-read (bash comments + human-facing trail echoes, never
sent to the model); the discipline additions add a few always-read lines to the developer/ui-ux/PM
brain paths and a shared on-demand skill, all within the pillar budgets (20/20). Methodology that an
agent loads per-task lives in skills, not always-read surface.

- **New — autonomous-run planning hardening** (`team/pm/skills/generic/sprint-planning.md`): four
  Sprint-7 field findings, all light planning-discipline additions (on-demand PM skill, no always-read
  cost). (F-S7-D) the queue **Prompt Standard now requires concrete file/symbol anchors** in each
  step's Inputs — a cold headless worktree can't resolve "per the Step-7 design" and will guess;
  restate decisions or cite the file, never the step. (F-S7-A) a closeout **durability-promotion**
  step — an autonomous worktree is merged then deleted, so any durable content in a gitignored or
  worktree-local path vanishes; promote the next sprint's needed artifacts into tracked
  `knowledge-base/` files first. (F-S7-C) a wave-gate rule to **confirm the artifact under test is
  built from committed source before diagnosing** an observation — a stale build burns a
  founder-attended gate pass on a non-bug. (F-S7-E) guidance that **high-context PM steps (closeout,
  exit-prep) prefer a live tab** over cold-headless, or need complete durable inputs — a planning
  choice, explicitly no driver flag. (F-S7-B, the wave-boundary handoff sweep, needed no new work —
  the handoff-closure lint below already runs at every PM bind and as a closeout gate.)
- **New — Apple-quality bar in the UI/UX brain file** (`team/ui-ux/CLAUDE.md`): a standing design
  standard every project inherits with zero per-project setup — before signing off any deliverable
  (design AND its rendered implementation), ask "Would Apple ship this?"; if no, redo with a better,
  *simpler* approach (simplicity is part of the bar). Wired as a mandatory item in the UI/UX
  Pre-Handoff Self-Review (state the question + honest answer in the handoff; a "no" blocks sign-off).
  Apple is the named exemplar; a non-consumer-design-led project substitutes its category's quality
  leader. The design-side analog of the developer "build for growth" principle, and the back bookend
  to `plan-first-discipline.md`'s plan-stage Apple-ship check.
- **New — handoff-closure lint + closeout gate** (`scripts/muster-requests-lint.sh` + `test-requests-lint.sh`
  in CI, wired into PM bind, sprint closeout, and the review protocol): in autonomous runs the handoff
  ledger (`agent-requests.md`) rotted — accepted handoffs never left Active because the "done → Resolved"
  sweep keys on a `**Status:**` field that reviewers leave stale while ticking their own checkboxes, and
  nothing blocked on it (one field run reached 1,382 lines / ~50 dead entries, burying the one genuinely-open
  request). The new lint deterministically blocks on the four failure modes: (i) all reviewer boxes ticked
  but `Status≠done`, (ii) `Status: done` still in Active, (iii) duplicate HO/REQ IDs, (iv) Active over a line
  budget (default 300). It runs at PM bind (warn) and as a HARD closeout gate (PM pastes the green result),
  and unlike the detection-only `muster-list-open-items.sh` worklist it never fires on a legitimately
  in-review handoff with a pending reviewer — so it's safe to gate on. Paired with an **atomic-close**
  protocol note (`deliverable-review.md`): flip `Status: done` in the same edit that ticks the last reviewer
  box. **Not built:** structured append-only filing (the dedup assertion catches the duplicate symptom; the
  deeper fix is parked).
- **Fixed — step-boundary commit no longer cries "agent left uncommitted work"** (`muster-sprint-run.sh`):
  the floor's echo asserted agent fault on every fire, but the floor catches several non-agent cases —
  most commonly a moved submodule pointer the agent committed *inside* `muster/` but didn't `git add`
  in the parent (`--ignore-submodules=dirty` suppresses dirty content, not a pointer move). The echo
  now states it neutrally and **lists the swept paths** (first 6 + overflow count), turning a false
  alarm into diagnostic signal: a lone `muster` line reads instantly as a benign pointer bump, a real
  source file reads as a missed closeout commit. The commit itself is unchanged — floor behavior was
  always correct; only the message lied.
- **New — glanceable step read-out: role-first header + ruled sections + optional color**
  (`muster-sprint-run.sh` + `MUSTER_COLOR` knob, on by default in a terminal): the step header led with the queue
  label and buried the agent, so the founder had to dig to see *who* was working. Now every step
  opens with a `─── step N` rule and a role-first header (`▶ DEVELOPER · Step 28a` / task on line
  2 — the two-line start glance), and closes with a consolidated end-block (`✓ <ROLE> · <time> ·
  advanced → <next> (<role>) · handoff HO-NNN filed ✓` + run totals) and a closing rule. The
  protocol-confirmation, wall-clock, and ctx-warning lines from earlier in 4.5 are folded into this
  block. Color is **on by default in a terminal** (agent name in its per-agent palette, key figures
  bold); `MUSTER_COLOR=0` or `NO_COLOR` opts out, `MUSTER_COLOR=1` forces on, and it auto-disables
  when output isn't a TTY so redirected `.log` files stay plain. The formatter's `✓ turns/cost/ctx`
  line is unchanged — all restyling is driver-side, keeping the never-fail formatter untouched.
  Documented in `guide/skills/config-knobs.md`.
- **Fixed — an interrupted step no longer borrows the previous step's metrics** (`muster-sprint-run.sh`):
  the formatter appends a metrics line only at a `result` event, so a step aborted before completing
  (a manual Ctrl-C, or a crash before the result) wrote none — and the driver's blind `tail -1 $METRICS`
  then attributed the PRIOR step's turns/cost/ctx/out to it (a phantom summary row, seen when a
  device-gate Ctrl-C made a freshly-started QA step show the developer step's 62 turns / $6.21 / 15%).
  Now the driver compares the metrics line count before/after the step: a fresh line → real metrics (a
  failed step with a result line still counts its real cost); no new line → the row shows dashes, the
  step isn't tallied as executed, and the end-block leads with `⚠` instead of `✓`.
- **New — live ctx-outlier warning** (`muster-sprint-run.sh` + `CTX_WARN_PCT` knob, default 80):
  the `✓` line shows peak-ctx % every step, but the founder shouldn't have to eyeball each one — a
  step whose peak crosses the threshold now prints `⚠ ctx ran hot: peak N% (≥ T%) — consider
  splitting this step at planning`. A near-full window risks truncation/degraded output and is the
  step-sizing signal, surfaced live instead of buried in the post-run table. Tunable per project
  (`CTX_WARN_PCT=0` disables); reuses the metrics pct the formatter already writes, no formatter
  change. Documented in `guide/skills/config-knobs.md`.
- **New — per-step protocol confirmation** (`muster-sprint-run.sh`): each step prints
  `✓ advanced → next: <step> · handoff HO-NNN filed ✓` — independently VERIFIED from the queue +
  `agent-requests.md`, not the agent's self-report. Advancement is the same comparison cond-3 makes
  at the next loop top; the handoff verdict reuses the handoff lint (single source of truth, no
  second parser) to confirm the new Done entry's HO refs are actually filed. A step that files no
  handoff (PM/coordination) shows advancement only — no false warning; a step that didn't advance or
  left a dangling HO ref shows a `⚠` early, before the next loop's gate stops the run. This is the
  trust signal for autonomy: proof the sprint moved correctly, not just that tokens were spent.
- **New — per-step wall-clock + cumulative burn** (`muster-sprint-run.sh`): each step prints
  `⏱ <step time> · run so far: <total> · $<cost> · N step(s)`; the run-summary table gains a time
  column and the totals line a `<dur> wall` figure. Wall-clock maps to tokens/throughput — the
  founder's requested signal for sizing steps and tuning model routing. Driver-side only (epoch
  bracketing the `claude` invocation); the formatter stays presentation-pure (never-fail contract
  untouched). `.metrics` file format unchanged — time lives in the trail + summary, not the
  machine-readable per-step line (a structured time field there is a parked follow-up if the founder
  wants offline analysis).
- **Fixed — wrapper-prompt budget gate was measuring the whole script tail** (`test-pillar-budgets.sh`):
  the awk end-anchor `/no new queue steps/` never matched — the prompt's tail wraps `no new queue \`
  / `steps)."` across a line-continuation — so the range silently ran to EOF, counting the prompt PLUS
  every line below it. The 5800-char budget was tuned to that inflated number and meaningless; the real
  prompt is 1517 chars. Anchored the range to the prompt's pipe-to-formatter line (`bash "$FMT"`, exists
  exactly once, immune to growth below it) and re-tuned the budget to 1800 (~19% headroom over the true
  prompt). This bug is why a ~1300-char bash addition below the prompt tripped a "token-floor regression"
  that wasn't one.
- **Fixed — PM tab now auto-binds** (`muster-sprint-new.sh`, commit 759758e): the v4.4 bare-interactive
  `MUSTER_ROLE=pm claude` skipped perms but never fired the bootstrap (a bare interactive session idles
  until the first message), so the founder had to manually say "bind to PM". Added an opening prompt that
  triggers turn 1 → bootstrap runs → binds, then waits. Mirrors the documented `MUSTER_ROLE` + prompt
  pattern. **Field-verify on the next sprint-new run before release.**

## 4.4 — 2026-06-20

Arogh Sprint-6 retro findings (F-S6-1/3/5/8) plus two operability fixes surfaced in founder review.
Theme: make the autonomous run trustworthy (believable telemetry, errors that mean something, less
friction) and the work safer (don't derail on a malformed queue, don't drop founder notices, don't
ship "technically legal but wrong"). **Zero always-read surface change** — one new on-demand validator
script, two scripts, and on-demand skill/convention edits; the token floor is untouched.

- **New — deterministic queue/planning gate** (`scripts/muster-queue-lint.sh` + `test-queue-lint.sh`
  in CI + `sprint-planning.md`): a fenceless `## Next Step` step is a latent run-killer — the driver
  keys completion on the ABSENCE of a fence, so a fenceless step promoted to Next Step reads as "sprint
  complete" and halts mid-run. The lint mirrors the driver's exact parse (Next Step bounding, fence-
  toggle step counting, any-level-`Upcoming` stop) and asserts at planning closeout: Next Step = exactly
  1 fenced step; every step has a heading + a valid `Role:`. PM runs it; planning isn't done until green.
  Distinguishes the dangerous fenceless case (work queued under Upcoming) from the benign idle case
  (sprint closed, nothing queued) — verified against a live closed queue so it never cries wolf.
  **Convention tightened:** every step (PM included) carries an explicit `Role:` line — the "may omit
  the marker" wording caused the field defect; the driver's Role-less→`pm` default stays as a tolerant
  backstop. **REJECTED:** folding the F-S6-3 notices check and the F-S6-2 pre-flight steps into this
  lint — different artifacts (gate packet / planning closeout) and partly judgment; the notices count-
  check is parked (needs a last-gate anchor), pre-flight is covered by the lint-as-closeout-gate.
- **Changed — gate-packet notices fold-in is mandatory** (`sprint-planning.md`): the "Notices since
  last gate" heading convention existed but was judgment-dependent — a notice could be surfaced via a
  topic section instead of the named heading, so a less-diligent gate-prep could silently drop a
  between-gate FYI. Now the heading is required in every packet (even when empty → `none`), verbatim,
  with the PM Pre-Handoff Self-Review confirming its presence. One canonical place the founder scans.
- **Fixed — bind no longer errors on every autonomous step** (`scripts/muster-bind.sh`): each
  autonomous bind passed a context word (step id, "sprint", queue name) as the invoker; the script
  hard-failed (`exit 1`), printing a spurious "tool returned an error" and forcing a wasted retry every
  step. The invoker is a low-stakes audit tag — warn and coerce unrecognized values to `auto`
  (correct for the autonomous path), never halt. The first call now succeeds, killing both the false
  error and the retry. The recurring false error was the real hazard: it desensitizes the operator to
  genuine bind failures.
- **Changed — test-philosophy hardening** (`decision-making.md`, `test-strategy.md`): a premium-quality
  regression shipped past a green combinatorial suite (a floor-hugging result for a requested range),
  caught on device, not by the net. Two field-proven lessons into the judgment skills: (1) tolerance/
  assertion-loosening as a test-fix is a candidate product regression — PM flags/escalates, never
  silently rules it (a lone edge-case failure is often the tip of a systematic drift); (2) invariants
  prove the output *legal*, not *good* — felt-quality surfaces (duration, volume, difficulty, breadth)
  require a quality-target assertion ("lands at intent"), not only invariants. Both on-demand, kept
  generic/durable (no project specifics).
- **Fixed — sprint telemetry context-window denominator** (`muster-sprint-format.sh`): the peak-ctx %
  divided by a stale hardcoded 200k and gated 1M behind a `[1m]` marker the stream-json model id never
  carries, so every Opus run divided by 200k (a 300k peak printed as 150%). The 4.6+ frontier
  generation ships a 1M window by default — default to 1M, enumerate only the 200k exceptions (Haiku +
  legacy 4.5-and-earlier); unknown/new models resolve to 1M.
- **New — one-paste PM tab** (`scripts/muster-sprint-new.sh`): the printed PM-tab command was bare
  `claude`, forcing a manual role-pick and manual permission grants every sprint. Now
  `MUSTER_ROLE=pm claude --dangerously-skip-permissions` — one paste boots PM-bound with permissions
  pre-granted, mirroring the loop tab's existing `MUSTER_ROLE=auto` pattern.

## 4.3 — 2026-06-16

Arogh Sprint-5 retro findings, triaged (F1–F14) — the deeper batch behind 4.2's operability fixes:
autonomous-run test capture, test rigor, design-for-evolution, planning discipline. No control-floor
change — agent guidance, skills, and planning conventions, almost all read on-demand; exactly one
always-run touch (Self-Review item 8). Web skills untouched (already the benchmark — the gaps were iOS).

- **New — autonomous test-gating discipline** (`muster-sprint-run.sh` wrapper + `system-guide.md`): a
  test-gated step runs its test FOREGROUND/blocking in one Bash call with a large timeout — never
  `run_in_background` then yield, which orphans the test (the headless `-p` session has no inter-turn
  channel) and trips the no-advance halt. The full rule (600s-timeout caveat, blocked-`sleep` trap,
  run-early/reserve-the-tail) lives in system-guide; the wrapper carries the tight imperative. Driver
  fixture +1 wiring assertion. **REJECTED:** a driver-side auto-resume of the orphaned test — once
  `-p` exits you cannot distinguish "yielded with a pending test" from "genuinely stuck," and it would
  weaken the load-bearing no-advance halt; the agent-guidance fix prevents the situation instead.
- **Changed — sleep-proofing honesty** (`muster-sprint-run.sh`, `system-guide.md`, `operating-help.md`):
  `caffeinate -i` covers IDLE sleep only — it never prevented lid-close or low-battery sleep. The
  overclaiming comment is corrected; run guidance is lid-open + AC for long runs; a sleep that does
  land is non-fatal (the step is resumable on re-run). Recovery already worked — only the claim was wrong.
- **New — "Meaningful Coverage" + test rigor** (`verification-discipline.md` is the SSoT, referenced by
  Self-Review item 8, `test-strategy.md`, `decision-making.md`): a test counts only if it can fail for
  the right reason — no `.disabled()`, no weakened assertions, and code-read ≠ coverage for a
  load-bearing contract. Self-Review item 8 broadened: every behavioral change incl. a composition/UI
  change that carries a contract ships a test. `test-strategy.md` gains a zero-test-surface sweep and
  combinatorial regression for decision surfaces (parametrize over input dimensions; a new value is a
  matrix row, and the matrix ships with the engine change).
- **New — design-for-evolution (iOS)** (`ios-best-practices.md`): exhaustive `switch` with no `default`
  (the compiler becomes the extension checklist), data-tables over branches, one SSoT accessor,
  orchestrator/delegate split, anti-pattern catalog. iOS-only — web already states this (exhaustive
  `assertNever`, "the compiler is your first reviewer").
- **New — inject-the-clock (iOS)** (`ios-mvvm.md` DI + `ios-modern-api.md`): "now" is an injected
  dependency, never a direct `Date.now`/`Calendar.current` read in a view-model/repository/domain type.
  iOS-only — web's `lib/time.ts` seam already does this. **No new generic skill** (it would have
  duplicated existing web doctrine — the SSoT anti-pattern the change itself preaches).
- **New — founder-time leverage** (`decision-making.md` principle + `sprint-planning.md` gate-packet):
  founder time goes only to what the machine cannot verify; PM certifies the mechanical layer is real
  and meaningful FIRST, then curates the wave-review packet to the human-judgment residue with evidence
  attached — never "green = covered." Folded into existing PM skills; **no new file.**
- **New — intra-wave dependency discipline** (`sprint-planning.md`, `ios-code-standards.md`): a step
  whose scope/inputs depend on earlier wave work points at the design handoff as authoritative scope
  (not a closed list that silently overrides it) and derives QA's charter from the same handoff; a step
  consuming a `needs-component`/`needs-update` dependency inlines the halt. The standing iOS rule now
  covers `needs-update` (stale-API), not just absent components. Gate changes-requested processing now
  cascades reassigned work to agent-context (the manual picker-bind path was the exposed one).
- **Fixed — operational-log gitignore** (`setup-project.sh`, `setup-existing-project.sh`):
  `knowledge-base/.muster-bind-log` was the lone tracked operational log — now gitignored by both setup
  paths. Also brought `setup-existing-project.sh` to parity (it was missing `.muster-sprint-logs/`).
  Forward-fix only — no migration/untrack machinery for a capped, harmless log on a non-breaking bump.

Already shipped in 4.2 (logged here as corroborated by the same retro, no new work): the per-step commit
floor (F4) and the resume/continuation machinery that partially covered the test-capture cluster.

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
- **Fixed — the Guide now commits `.muster/config` edits** (`config-knobs.md`): the knob-resolution
  flow wrote the file and *claimed* "it's committed, rides into worktrees" but never ran the commit.
  Since sprint worktrees are created with `git worktree add` (committed tip), an uncommitted edit
  silently never reached the run — the knob the user just set wouldn't apply. The skill now commits
  between write and confirm; the contract gate asserts the commit step survives (regression guard).
  Surfaced by the Guide acceptance test on a real project.
- **New — founder-notices closeout sweep** (`sprint-planning.md`): `founder-notices.md` was the one
  accumulating file without a deterministic growth backstop (siblings archive at closeout / cap /
  rotate; it relied on the founder manually deleting). PM now clears pre-current-sprint notices at
  closeout, so the live file and every gate packet stay lean; the founder still deletes acted-on
  notices as they go.
- **New — PM routes framework-process questions to `/muster`** (`team/pm/CLAUDE.md`): the Guide↔PM
  boundary was one-directional — the Guide sent project questions to PM, but PM, asked a
  framework-mechanics question ("how do I run an autonomous sprint?"), brute-forced `system-guide.md`
  and the sprint scripts to answer it. PM now mirrors the rule: how-Muster-runs questions → run
  `/muster` in the same tab (consult mode, keeps the PM role); project content stays PM's. Token
  win — the Guide answers process questions off its thin cheap-read ladder, not a pile of files.
  Contract gate asserts the reciprocal rule.
- **New — Muster-agent contract gate** (`scripts/test-muster-agent.sh`, wired into CI): asserts
  the deterministic Guide/XO scaffold — the carve-out, `MUSTER.md` bind commands, `muster-bind.sh`
  accepting `guide`/`xo`, the status-line chain rendering `[muster: xo]`, the guide skills, the
  `/muster` front door — and the XO loadout conditionally (only when `private/xo/` is present, so
  public CI skips it gracefully). Guards the **plumbing** the agent behaviors stand on; the
  model-judgment layer is out of scope (needs a live run, regresses only when the driving prose
  changes).
- **New — resume guard fixture** (`scripts/test-sprint-resume.sh`, 5th CI gate): asserts
  `muster-sprint-resume.sh` sources the Tier-1 worktree guard **before** its
  `--dangerously-skip-permissions` PM call — on a primary checkout (and when the guard file is
  missing) resume refuses and makes no `claude` call, proven by a PATH-injected stub. Closes the
  one autonomous-path script with branching safety logic that the driver fixture didn't reach;
  `muster-sprint-new`/`sandbox` stay untested (thin git-worktree glue, low payoff).
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
