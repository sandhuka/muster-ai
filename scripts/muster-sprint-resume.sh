#!/usr/bin/env bash
# Run AFTER writing your verdict to knowledge-base/wave-review.md.
# Processes the gate (applies your verdict), then continues the sprint.
set -uo pipefail
MUSTER_ROLE=pm claude -p --dangerously-skip-permissions --max-turns 50 \
  "Process the wave gate per knowledge-base/wave-review.md: read the founder's latest verdict. \
For each bug, insert a fix step into the queue; if approved with no bugs, remove the wave-gate halt \
step and promote the next wave's first step to Next Step. Then stop. Do not expand scope."
exec bash "$(dirname "$0")/muster-sprint-run.sh"
