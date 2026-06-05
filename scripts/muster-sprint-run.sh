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
