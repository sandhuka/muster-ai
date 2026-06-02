#!/usr/bin/env bash
# muster-sprint-run.sh — drive the orchestration queue to completion autonomously.
# RUN INSIDE A GIT WORKTREE. Never on your main checkout with --dangerously-skip-permissions.
# Reuses MUSTER_ROLE=auto: each step binds the role named in the queue's Next Step, executes,
# files its handoff, and advances the queue itself. The loop only reads + honors stop signals.
set -uo pipefail

# --- Tier-1 deterministic guard: refuse to run on the primary checkout. ---
# Sourced from a shared file so the resume wrapper enforces the identical guard (no drift).
source "$(dirname "$0")/muster-guard-worktree.sh"

QUEUE="knowledge-base/orchestration-queue.md"
MAX_STEPS="${MAX_STEPS:-30}"          # hard cap — cost circuit-breaker
[ -f "$QUEUE" ] || { echo "No queue at $QUEUE — run from a project root."; exit 1; }

# Path to the handoff-integrity lint (sits next to this driver).
LINT="$(dirname "$0")/muster-lint-handoff.sh"

# Text of the Next Step block (between '## Next Step' and the next '## ' heading).
next_block(){ awk '/^## Next Step/{f=1;next} /^## /{f=0} f' "$QUEUE"; }

# Bind role for the current Next Step, mirroring MUSTER_ROLE=auto:
#   non-empty block with 'Role:' line -> that role
#   non-empty block, no 'Role:' line  -> 'pm'   (PM steps may omit the marker)
#   empty/whitespace block            -> ''     (queue complete)
next_role(){
  local blk; blk="$(next_block)"
  printf '%s' "$blk" | grep -q '[^[:space:]]' || return 0
  local r; r="$(printf '%s' "$blk" | grep -m1 -i '^Role:' | sed 's/^[Rr]ole:[[:space:]]*//')"
  [ -n "$r" ] && printf '%s' "$r" || printf 'pm'
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
  [ "$blk" = "$prev" ] && { echo "⛔ Next Step unchanged — agent didn't advance / failure"; break; } # cond 3
  prev="$blk"

  echo "▶ step $step → role: $role"
  if ! MUSTER_ROLE=auto claude -p --dangerously-skip-permissions --max-turns 50 \
        "Execute the current Next Step in $QUEUE end-to-end: do the work, file your handoff, \
run the Pre-Handoff Self-Review (muster/system-guide.md), and update the queue (move your step \
to Done, promote the next Upcoming step to Next Step). If you hit a hard blocker only the \
founder can resolve, write it to '## Founder Decisions' AND set the Next Step block's Role to \
'halt'. Do NOT guess and do NOT expand sprint scope (no new queue steps)."; then
    echo "⛔ claude exited non-zero on step $step — stopping for founder"; break                   # cond 4
  fi
done
echo "Run ended at step $step."
