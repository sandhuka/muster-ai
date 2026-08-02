#!/usr/bin/env bash
# muster-read-queue.sh — action: parse the orchestration queue's Next Step (family: verb — answers, never mutates).
#
# THE single implementation of the MUSTER_ROLE=auto Next Step contract. muster-sprint-run.sh
# sources it; muster-boot.sh executes it. One parser, two consumers — driver and bootstrap can
# never drift on what the queue says.
#
# Contract (mirrors CLAUDE.md → Role Binding):
#   block has a fenced code block, with a 'Role:' line -> that role
#   block has a fenced code block, no 'Role:' line     -> 'pm'  (PM steps may omit the marker)
#   block has NO fenced code block                     -> ''    (queue complete)
# Completion keys on the ABSENCE of a ``` fence, NOT on whitespace: at sprint end agents write a
# human-readable placeholder (e.g. "_(empty — sprint complete)_") that is non-whitespace but
# fenceless. A real step (specialist or PM) always wraps its prompt in a ``` fence.
# Section bounding: the block ends at the next top-level `## ` heading OR an `Upcoming` heading
# at ANY level — older projects nest the upcoming list as `### Upcoming` under Next Step; without
# the any-level stop the block would over-capture and completion would be unreachable. The
# '$'-anchored Upcoming match means only a bare `Upcoming` heading ends the block, so a step
# title merely containing the word "Upcoming" does not falsely terminate it.
#
# Usage (executed): muster-read-queue.sh [role|block] [queue-file]
#   role  -> prints the Next Step's bind role, or nothing if the queue is complete (exit 0 both ways)
#   block -> prints the raw Next Step section body
# Usage (sourced):  defines next_block/next_role over "$QUEUE" (defaulted if unset).

next_block(){
  awk '
    /^## Next Step/ {f=1; next}
    f && (/^## / || /^#+[[:space:]]+Upcoming[[:space:]]*$/) {f=0}
    f
  ' "${QUEUE:-knowledge-base/orchestration-queue.md}"
}

next_role(){
  local blk; blk="$(next_block)"
  # grep -c, not -q: -q's early exit can SIGPIPE the printf under pipefail; -c reads to EOF.
  # col-0 fence, symmetric with the ^Role: grep below.
  printf '%s\n' "$blk" | grep -c '^```' >/dev/null || return 0
  local r; r="$(printf '%s' "$blk" | grep -m1 -i '^Role:' | sed 's/^[Rr]ole:[[:space:]]*//; s/[[:space:]]*$//')"
  [ -n "$r" ] && printf '%s' "$r" || printf 'pm'
}

# Executed (not sourced) -> dispatch a query. Guarded so sourcing never runs the dispatcher
# and never alters the caller's shell options.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -uo pipefail
  cmd="${1:-role}"
  QUEUE="${2:-${QUEUE:-knowledge-base/orchestration-queue.md}}"
  [ -f "$QUEUE" ] || { echo "muster-read-queue: queue file not found: $QUEUE" >&2; exit 1; }
  case "$cmd" in
    role)  r="$(next_role)"; [ -n "$r" ] && printf '%s\n' "$r"; exit 0 ;;
    block) next_block ;;
    *) echo "usage: muster-read-queue.sh [role|block] [queue-file]" >&2; exit 3 ;;
  esac
fi
