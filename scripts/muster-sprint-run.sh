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
  rm -f "$old" "${old%.log}.jsonl"
done
RUN_TS="$(date +%Y%m%d-%H%M%S)"
HUMANLOG="$LOGDIR/run-$RUN_TS.log"     # readable trail (scannable)
RAWLOG="$LOGDIR/run-$RUN_TS.jsonl"     # full-fidelity stream-json (deep debug)
echo "📓 trail: $HUMANLOG  (raw: $RAWLOG)"

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

step=0; prev=""
while :; do
  step=$((step+1))
  [ "$step" -gt "$MAX_STEPS" ] && { echo "⛔ MAX_STEPS=$MAX_STEPS reached — stopping"; break; }

  # Handoff-integrity lint (§7.8): the most-recent Done entry's HO refs must be filed.
  # Top-of-loop so it also gates resume — a missing HO must exist before proceeding.
  if ! bash "$LINT" "$QUEUE" "knowledge-base/agent-requests.md"; then
    echo "⛔ Handoff missing for most-recent Done entry — stopping for founder"; break          # cond: HO-existence
  fi

  role="$(next_role)"
  [ -z "$role" ]       && { echo "✅ Next Step empty — sprint complete"; break; }                  # cond 1
  [ "$role" = halt ]   && { echo "⛔ Role: halt — agent hard-block, handing to founder"; break; }  # cond 2

  blk="$(next_block)"
  # Queue-contract guard: '## Next Step' must hold exactly ONE step. PM gate-processing of a
  # changes-requested verdict can mis-place a re-review gate as a 2nd step here; the fix's closeout
  # could then promote the wrong step and drop the gate (skipped human re-review). Catch it
  # deterministically — a mechanical integrity check, symmetric with the handoff lint (not policy).
  steps="$(next_step_count)"
  [ "${steps:-0}" -gt 1 ] && {
    echo "⛔ '## Next Step' holds $steps steps — the contract is one step per Next Step."           # cond: one-step-per-next-step
    echo "   Extra steps (e.g. a re-review gate) belong under '## Upcoming'. Stopping for founder."
    break
  }
  [ "$blk" = "$prev" ] && { echo "⛔ Next Step unchanged — agent didn't advance / failure"; break; } # cond 3
  prev="$blk"

  echo "▶ step $step → role: $role" | tee -a "$HUMANLOG"
  # Stream the step's work through the formatter (live trail + logs). PIPESTATUS[0] is claude's
  # own exit code — the formatter/tee cannot change it, so cond-4 stays accurate (verified).
  MUSTER_ROLE=auto claude -p --dangerously-skip-permissions --max-turns "$MAX_TURNS" \
        --output-format stream-json --verbose \
        "Execute the current Next Step in $QUEUE end-to-end: do the work, file your handoff, \
run the Pre-Handoff Self-Review (muster/system-guide.md), and update the queue (move your step \
to Done, promote the next Upcoming step to Next Step). PM is the sole party that calls the \
founder: if you are a specialist and hit a blocker you cannot resolve (a decision you lack \
authority for, a missing input, a bug you cannot crack, a red build), do NOT set Role: halt and \
do NOT write to '## Founder Decisions' — instead file the blocker as a PM-addressed request and \
re-point Next Step to a 'Role: pm' assessment step (see decision-making.md → Autonomous-mode \
boundary). Only PM sets Role: halt. Do NOT guess and do NOT expand sprint scope (no new queue \
steps)." | bash "$FMT" "$RAWLOG" | tee -a "$HUMANLOG"
  if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    { echo "⛔ claude exited non-zero on step $step — stopping for founder"                         # cond 4
      echo "   (if this was a heavy step, it may have hit MAX_TURNS=$MAX_TURNS — raise MAX_TURNS and"
      echo "    re-run to continue, or split the step at planning. Safe to resume: state was not advanced.)"
    } | tee -a "$HUMANLOG"
    break
  fi
done
echo "Run ended at step $step."
