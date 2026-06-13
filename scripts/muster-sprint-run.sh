#!/usr/bin/env bash
# muster-sprint-run.sh — drive the orchestration queue to completion autonomously.
# RUN INSIDE A GIT WORKTREE. Never on your main checkout with --dangerously-skip-permissions.
# Reuses MUSTER_ROLE=auto: each step binds the role named in the queue's Next Step, executes,
# files its handoff, and advances the queue itself. The loop only reads + honors stop signals.
set -uo pipefail

# --- Tier-1 deterministic guard: refuse to run on the primary checkout. ---
# Sourced from a shared file so the resume wrapper enforces the identical guard (no drift).
# Fail CLOSED: a missing/unreadable guard file must refuse to run, not bypass the guard.
source "$(dirname "$0")/muster-guard-worktree.sh" || { echo "⛔ worktree guard missing — refusing to run."; exit 1; }

# Project knobs: ./.muster/config (plain KNOB=value lines, committed so worktrees inherit it)
# supplies project defaults for the driver's env knobs. Precedence: explicit env at invocation >
# config > built-in default — invocation env is captured before the source and re-applied after,
# so a config line can never override what the user typed on the command line.
if [ -f ./.muster/config ]; then
  _inv_env="$(declare -p MAX_STEPS MAX_TURNS ANTHROPIC_MODEL KEEP_RUNS LIMIT_RESUME_AT 2>/dev/null)"
  . ./.muster/config
  eval "$_inv_env"
  export ANTHROPIC_MODEL 2>/dev/null || true   # claude reads it from env; config-set needs the export
fi

QUEUE="knowledge-base/orchestration-queue.md"
MAX_STEPS="${MAX_STEPS:-30}"          # hard cap — cost circuit-breaker
MAX_TURNS="${MAX_TURNS:-150}"         # per-step model-turn budget — raise for heavy steps
[ -f "$QUEUE" ] || { echo "No queue at $QUEUE — run from a project root."; exit 1; }

# Fail fast on an unpopulated/partial muster checkout. `git worktree add` does not check out
# submodules, so a worktree's muster/ can be empty (the sandbox helper inits it; this guards the
# manual-worktree and partial-checkout paths). Resolved relative to THIS script so it never
# false-fails when muster IS the repo — the framework's own tree has system-guide.md at its root.
[ -f "$(dirname "$0")/../system-guide.md" ] || {
  echo "⛔ muster/ appears unpopulated in this worktree."
  echo "   Run: git submodule update --init --recursive"
  exit 1
}

# Sleep-proof: hold macOS idle-sleep exactly while the driver lives (-w $$ ties the assertion
# to this PID and auto-releases on exit — overnight runs survive lid-closed-adjacent idling).
# The command -v guard makes non-mac a no-op (Linux analog for a future port: systemd-inhibit).
command -v caffeinate >/dev/null && caffeinate -i -w $$ &

# Path to the handoff-integrity lint (sits next to this driver).
LINT="$(dirname "$0")/muster-lint-handoff.sh"

# Observability: each step streams its work (stream-json) through a formatter that prints a
# human-readable trail AND tees a full-fidelity raw log for debugging. Presentation only — the
# loop's stop conditions still key off claude's exit code (PIPESTATUS[0]), never the formatter.
FMT="$(dirname "$0")/muster-sprint-format.sh"
LOGDIR=".muster-sprint-logs"
mkdir -p "$LOGDIR" 2>/dev/null || true
# Prune old run logs — keep the most recent KEEP_RUNS runs (each run = a .log + .jsonl pair).
# The driver owns these logs, so it prunes them here (session-start housekeeping never fires in
# the worktree/bash context the loop runs in). Count-based: debugging artifacts, kept across runs.
KEEP_RUNS="${KEEP_RUNS:-20}"
ls -1t "$LOGDIR"/run-*.log 2>/dev/null | tail -n +"$((KEEP_RUNS+1))" | while IFS= read -r old; do
  rm -f "$old" "${old%.log}.jsonl" "${old%.log}.metrics"
done
RUN_TS="$(date +%Y%m%d-%H%M%S)-$$"   # PID suffix: two runs in the same second must not share logs
HUMANLOG="$LOGDIR/run-$RUN_TS.log"     # readable trail (scannable)
RAWLOG="$LOGDIR/run-$RUN_TS.jsonl"     # full-fidelity stream-json (deep debug)
METRICS="$LOGDIR/run-$RUN_TS.metrics"  # formatter-written, one line per step — summary table source

# Trail layout: heavy rules (═) mark only the places a human decision lives — run start, a halt,
# run end. Per-step lines carry the QUEUE's own step heading; the iteration counter is plumbing
# (the MAX_STEPS circuit-breaker) and surfaces only at run start, near the cap, and when it fires.
RULE_H="═══════════════════════════════════════════════════════════"
RULE_L="───────────────────────────────────────────────────────────"
{ echo "📓 sprint trail · run-$RUN_TS  (run budget: $MAX_STEPS steps)"
  echo "   log: $HUMANLOG · raw: $RAWLOG"
  echo "$RULE_H"
  echo
} | tee -a "$HUMANLOG"

# Text of the Next Step block: everything between '## Next Step' and the boundary that ends it.
# The boundary is the next top-level '## ' heading OR an 'Upcoming' heading at ANY level. Older
# projects nest the upcoming list as '### Upcoming' / '#### Step N' under Next Step; without the
# any-level Upcoming stop the block would over-capture the whole list and completion would be
# unreachable. The '$'-anchored Upcoming match means only a bare 'Upcoming' heading ends the block,
# so a step whose title merely contains the word "Upcoming" does not falsely terminate it.
next_block(){
  awk '
    /^## Next Step/ {f=1; next}
    f && (/^## / || /^#+[[:space:]]+Upcoming[[:space:]]*$/) {f=0}
    f
  ' "$QUEUE"
}

# Bind role for the current Next Step, mirroring the MUSTER_ROLE=auto contract in CLAUDE.md:
#   block has a fenced code block, with a 'Role:' line -> that role
#   block has a fenced code block, no 'Role:' line     -> 'pm'  (PM steps may omit the marker)
#   block has NO fenced code block                     -> ''    (queue complete)
# Completion keys on the ABSENCE of a ``` fence, NOT on whitespace: at sprint end agents write a
# human-readable placeholder (e.g. "_(empty — sprint complete)_") that is non-whitespace but
# fenceless. A real step (specialist or PM) always wraps its prompt in a ``` fence.
next_role(){
  local blk; blk="$(next_block)"
  printf '%s\n' "$blk" | grep -q '^```' || return 0   # col-0 fence, symmetric with the ^Role: grep below
  local r; r="$(printf '%s' "$blk" | grep -m1 -i '^Role:' | sed 's/^[Rr]ole:[[:space:]]*//')"
  [ -n "$r" ] && printf '%s' "$r" || printf 'pm'
}

# Count the STEPS in the Next Step section = the number of fenced blocks (each step wraps its prompt
# in one ``` fence). Count fence OPENINGS via a toggle, NOT '###' headings: a step's prompt BODY may
# legitimately contain '### ' lines (e.g. a content step describing section structure), which would
# fool a heading count, but it cannot contain a ``` line (that would break the wrapping fence — so
# nested fences are unsupported by the queue convention). Same section bounding as next_block.
next_step_count(){
  awk '
    /^## Next Step/ {f=1; next}
    f && (/^## / || /^#+[[:space:]]+Upcoming[[:space:]]*$/) {f=0}
    !f {next}
    /^```/ { infence = !infence; if (infence) n++; next }   # count each fence opening = one step
    END {print n+0}
  ' "$QUEUE"
}

# Human label for a step: the first markdown heading line inside the Next Step block
# (e.g. '### Step 16 — Content: browser copy' -> 'Step 16 — Content: browser copy').
# Echoed text for the trail and commit messages ONLY — never parsed for control: step numbering
# is a PM authoring convention, not a contract (32.5 / 9-fix-2 / unnumbered fixes are legitimate).
next_label(){
  printf '%s\n' "$1" | sed -n 's/^#\{1,4\}[[:space:]]\{1,\}//p' | head -1
}

# Optional per-step model override: a 'Model: <id>' line inside the fenced block, same parsing
# pattern as 'Role:'. Absent -> empty -> no --model flag -> the session default applies. An
# invalid id makes claude exit non-zero -> stop condition 4 catches it; no validation here, and
# the value is only ever echoed into the flag — never branched on.
next_model(){
  printf '%s' "$1" | grep -m1 -i '^Model:' | sed 's/^[Mm]odel:[[:space:]]*//'
}

# Founder channels — terminal output of an autonomous step is never read by the founder, so
# "tell the founder X" executed in chat is a swallowed notification. The durable channel is
# knowledge-base/founder-notices.md (agents append dated one-line FYIs); the driver diffs it
# after each step and echoes new entries loudly. It also alerts when '## Founder Decisions'
# changes mid-run (escalated observations park there while the loop keeps running). Read-only
# diffs — the driver never writes either channel. Missing notices file = no notices (older
# projects); agents create it on first append.
NOTICES="knowledge-base/founder-notices.md"
fd_section(){ awk '/^## Founder Decisions/{f=1;next} f&&/^## /{f=0} f' "$QUEUE" 2>/dev/null | cksum; }
notices_seen="$(wc -l < "$NOTICES" 2>/dev/null | tr -d ' ')"; notices_seen="${notices_seen:-0}"
fd_snap="$(fd_section)"
notices_run=0
report_founder_channels(){
  local now fd
  now="$(wc -l < "$NOTICES" 2>/dev/null | tr -d ' ')"; now="${now:-0}"
  if [ "$now" -gt "$notices_seen" ]; then
    { echo "  📣 FOUNDER NOTICE:"
      sed -n "$((notices_seen+1)),${now}p" "$NOTICES" | sed 's/^/     /'
    } | tee -a "$HUMANLOG"
    notices_run=$((notices_run + now - notices_seen))
    notices_seen="$now"
  fi
  fd="$(fd_section)"
  if [ "$fd" != "$fd_snap" ]; then
    echo "  📌 '## Founder Decisions' changed this step — review $QUEUE" | tee -a "$HUMANLOG"
    fd_snap="$fd"
  fi
  return 0
}

step=0; prev=""
reason="interrupted"; reason_note=""; executed=0; ROWS=""
while :; do
  step=$((step+1))
  if [ "$step" -gt "$MAX_STEPS" ]; then
    nl="$(next_label "$(next_block)")"
    { echo "⛔ Run cap reached (MAX_STEPS=$MAX_STEPS) — cost circuit-breaker, not an error."
      echo "   Sprint position is saved in the queue (next: ${nl:-see $QUEUE})."
      echo "   Re-run muster-sprint-run.sh to continue with a fresh $MAX_STEPS-step budget."
    } | tee -a "$HUMANLOG"
    reason="run cap"; break
  fi

  # Handoff-integrity lint (§7.8): the most-recent Done entry's HO refs must be filed.
  # Top-of-loop so it also gates resume — a missing HO must exist before proceeding.
  if ! bash "$LINT" "$QUEUE" "knowledge-base/agent-requests.md"; then
    echo "⛔ Handoff missing for most-recent Done entry — stopping for founder" | tee -a "$HUMANLOG" # cond: HO-existence
    reason="handoff lint"; break
  fi

  blk="$(next_block)"
  role="$(next_role)"
  label="$(next_label "$blk")"

  if [ -z "$role" ]; then                                                                          # cond 1
    echo "✅ Next Step empty — sprint complete" | tee -a "$HUMANLOG"
    reason="sprint complete"; break
  fi
  if [ "$role" = halt ]; then                                                                      # cond 2
    { echo "$RULE_H"
      echo "⛔ HALT — ${label:-founder checkpoint}   (Role: halt)"
      echo
      echo "   The loop stopped for founder input — nothing is wrong."
      echo "   • Wave gate: review knowledge-base/wave-review.md, write your verdict in its"
      echo "     ## Verdict section, then run: bash muster/scripts/muster-sprint-resume.sh"
      echo "     (from this worktree)."
      echo "   • PM escalation: see '## Founder Decisions' in $QUEUE, answer, then re-run"
      echo "     muster-sprint-run.sh."
      echo "$RULE_H"
    } | tee -a "$HUMANLOG"
    reason="halt"; reason_note="${label:-Role: halt}"
    ROWS="${ROWS}$(printf '  %-36.36s %5s' "${label:-Role: halt}" "halt")"$'\n'
    break
  fi
  # Queue-contract guard: '## Next Step' must hold exactly ONE step. PM gate-processing of a
  # changes-requested verdict can mis-place a re-review gate as a 2nd step here; the fix's closeout
  # could then promote the wrong step and drop the gate (skipped human re-review). Catch it
  # deterministically — a mechanical integrity check, symmetric with the handoff lint (not policy).
  steps="$(next_step_count)"
  [ "${steps:-0}" -gt 1 ] && {
    { echo "⛔ '## Next Step' holds $steps steps — the contract is one step per Next Step."         # cond: one-step-per-next-step
      echo "   Extra steps (e.g. a re-review gate) belong under '## Upcoming'. Stopping for founder."
    } | tee -a "$HUMANLOG"
    reason="queue guard"; break
  }
  [ "$blk" = "$prev" ] && {                                                                         # cond 3
    echo "⛔ Next Step unchanged — agent didn't advance / failure" | tee -a "$HUMANLOG"
    reason="step did not advance"; reason_note="$label"; break
  }
  prev="$blk"

  model="$(next_model "$blk")"
  hdr="▶ ${label:-step $step (role: $role)}"
  [ -n "$model" ] && hdr="$hdr  [$model]"
  echo "$hdr" | tee -a "$HUMANLOG"

  # Mid-step continuation: the commit floor guarantees a clean tree at every successful step
  # boundary, so a dirty tree at step START deterministically means an interrupted prior attempt
  # (or a manual excursion that skipped closeout — identical treatment). Prepend a continuation
  # preamble to the WRAPPER prompt (the queue file is never edited) so the fresh agent
  # inventories and continues instead of restarting. Deliberate discard stays a manual founder
  # call (git checkout .) — destructive choices are never automated.
  preamble=""
  dirty_start="$(git status --porcelain --ignore-submodules=dirty -- . ":(exclude)$LOGDIR" 2>/dev/null \
                 || git status --porcelain --ignore-submodules=dirty)"
  if [ -n "$dirty_start" ]; then
    preamble="The working tree contains uncommitted changes — almost certainly partial work \
from an interrupted previous attempt at this step. Do NOT start over. First inventory it \
(git status, git diff --stat), reconcile against the step's task, and continue from that state. \
If the changes are clearly unrelated to this step, stop and route to PM. "
    echo "  ↻ dirty tree — continuation preamble added" | tee -a "$HUMANLOG"
  fi

  # Stream the step's work through the formatter (live trail + logs). PIPESTATUS[0] is claude's
  # own exit code — the formatter/tee cannot change it, so cond-4 stays accurate (verified).
  MUSTER_ROLE=auto claude -p --dangerously-skip-permissions --max-turns "$MAX_TURNS" \
        ${model:+--model} ${model:+"$model"} \
        --output-format stream-json --verbose \
        "${preamble}Execute the current Next Step in $QUEUE end-to-end: do the work, file your handoff, \
run the Pre-Handoff Self-Review (muster/system-guide.md), and update the queue (move your step \
to Done, promote the next Upcoming step to Next Step). PM is the sole party that calls the \
founder: if you are a specialist and hit a blocker you cannot resolve (a decision you lack \
authority for, a missing input, a bug you cannot crack, a red build), do NOT set Role: halt and \
do NOT write to '## Founder Decisions' — instead file the blocker as a PM-addressed request and \
re-point Next Step to a 'Role: pm' assessment step (see decision-making.md → Autonomous-mode \
boundary). Only PM sets Role: halt. The founder does NOT read this session's output: anything \
the founder must SEE goes in a file — append a dated one-line FYI to \
knowledge-base/founder-notices.md (parallel-track kickoffs, heads-ups, deadlines); never \
'surface' or 'tell' anything in chat. Do NOT guess and do NOT expand sprint scope (no new queue \
steps)." | bash "$FMT" "$RAWLOG" "$METRICS" | tee -a "$HUMANLOG"
  if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    { echo "⛔ claude exited non-zero on step $step — stopping for founder"                         # cond 4
      echo "   (if this was a heavy step, it may have hit MAX_TURNS=$MAX_TURNS — raise MAX_TURNS and"
      echo "    re-run to continue, or split the step at planning. Safe to resume: state was not advanced.)"
    } | tee -a "$HUMANLOG"
    reason="error (non-zero exit)"; reason_note="$label"; break
  fi

  report_founder_channels

  # Summary row for this step, paired with the formatter's metrics line (dashes if it degraded).
  executed=$((executed+1))
  m="$(sed -n "${executed}p" "$METRICS" 2>/dev/null)"
  IFS='|' read -r mt mc mp mo _ <<< "${m:-—|—|—|—|0}"
  mc_disp="—"; [ "$mc" != "—" ] && mc_disp="\$$mc"
  ROWS="${ROWS}$(printf '  %-36.36s %5s %8s %5s %6s' "${label:-step $step}" "$mt" "$mc_disp" "$mp" "$mo")"$'\n'

  # Step-boundary commit floor: one commit per completed step, regardless of model or whether
  # the agent's closeout remembered to commit. Agents committing their own work stays the
  # convention (and the normal case — this is then a no-op on a clean tree); the floor exists so
  # a skipped closeout commit can't blur two steps' work into one diff. --ignore-submodules=dirty
  # keeps a content-dirty muster/ checkout (e.g. a hand-patched script) from firing this every
  # step — a moved submodule POINTER still commits. Logs dir excluded defensively (gitignored).
  dirty="$(git status --porcelain --ignore-submodules=dirty -- . ":(exclude)$LOGDIR" 2>/dev/null \
           || git status --porcelain --ignore-submodules=dirty)"
  if [ -n "$dirty" ]; then
    git add -A -- . ":(exclude)$LOGDIR" 2>/dev/null || git add -A
    if git commit -q -m "sprint step boundary: ${label:-step $step}"; then
      echo "  📦 step-boundary commit (agent left uncommitted work)" | tee -a "$HUMANLOG"
    else
      echo "  ⚠️ step-boundary commit failed — tree left as-is for diagnosis" | tee -a "$HUMANLOG"
    fi
  fi

  # Near-cap warning — the only mid-run appearance of the budget counter.
  if [ "$MAX_STEPS" -ge 5 ] && [ "$step" -eq $(( MAX_STEPS * 8 / 10 )) ]; then
    echo "⚠️  run budget: $step of $MAX_STEPS steps used this run" | tee -a "$HUMANLOG"
  fi
  echo | tee -a "$HUMANLOG"
done

# Run summary — per-step rows (queue labels) + totals from the metrics file, and WHY the run
# stopped. This is where step-sizing judgment happens: scan the ctx% column for outliers.
{ echo "── run summary ────────────────────────────────────────────"
  [ -n "$ROWS" ] && printf '%s' "$ROWS"
  echo "$RULE_L"
  if [ -s "$METRICS" ]; then
    awk -F'|' '{t+=$1; c+=$2; o+=$5} END {
      ok = (o>=1000) ? sprintf("%dk", int(o/1000+0.5)) : o
      printf "  %d steps · %d turns · $%.2f · out %s", NR, t, c, ok }' "$METRICS"
  else
    printf '  %d steps' "$executed"
  fi
  echo " · stopped: $reason${reason_note:+ ($reason_note)}"
  if [ "$notices_run" -gt 0 ]; then
    echo "  📣 $notices_run founder notice(s) this run — read $NOTICES"
  fi
} | tee -a "$HUMANLOG"
exit 0
