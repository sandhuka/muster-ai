#!/usr/bin/env bash
# Run AFTER writing your verdict to knowledge-base/wave-review.md, FROM INSIDE the sprint
# worktree (this operates on the CWD's queue + wave-review.md — the wrong tree processes the
# wrong files). Processes the gate (applies your verdict), then continues the sprint.
set -uo pipefail

# Same Tier-1 worktree guard as the driver, BEFORE the skip-permissions PM call below —
# otherwise resume would run --dangerously-skip-permissions unguarded on the primary checkout.
# Fail CLOSED: a missing/unreadable guard file must refuse to run, not bypass the guard.
source "$(dirname "$0")/muster-guard-worktree.sh" || { echo "⛔ worktree guard missing — refusing to run."; exit 1; }

MUSTER_ROLE=pm claude -p --dangerously-skip-permissions --max-turns 50 \
  "Process the wave gate per knowledge-base/wave-review.md: read the founder's latest verdict. \
If there is no verdict yet, do nothing and leave the gate in place (the loop will halt again). \
For each bug, insert a fix step into the queue; if approved with no bugs, remove the wave-gate halt \
step and promote the next wave's first step to Next Step. Then stop. Do not expand scope."
exec bash "$(dirname "$0")/muster-sprint-run.sh"
