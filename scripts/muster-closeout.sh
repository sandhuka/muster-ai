#!/usr/bin/env bash
# muster-closeout.sh — action: the sprint-closeout gate, one pasteable verdict (family: verb — reports, never mutates).
#
# The closeout's five mandated checks used to be five separate "run X, paste green" prose
# fragments — a skipped gate was invisible and a partial paste forgeable. This runs them in the
# mandated order, prints one ✓/✗ block, and REFUSES a green summary if anything failed. Zero
# new check logic. The open-items worklist is printed first as INFO — it is detection-only by
# contract (never blocks; PM still makes the close-vs-carry judgment on each line).
#
# Order: worklist (info) → board closure → entry bodies → decision reconciliation →
#        kb budgets → durability → gate-packet notices.
#
# Usage: muster-closeout.sh    Exit: 0 all green · 1 any red · 3 wiring error
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ "$(basename "$MUSTER_ROOT")" != "muster" ]; then
  echo "muster-closeout: not inside a project (muster tree not at <project>/muster/)" >&2; exit 3
fi
cd "$MUSTER_ROOT/.."

red=0
check(){ # $1=label, rest=command
  local label="$1"; shift
  local out rc; out="$("$@" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then echo "✓ $label"
  else red=1; echo "✗ $label"; printf '%s\n' "$out" | sed 's/^/    /'; fi
}

echo "MUSTER CLOSEOUT GATE"
echo "-- open-items worklist (INFO — disposition each; never blocks) --"
bash "$SCRIPT_DIR/muster-list-open-items.sh" 2>&1 | sed 's/^/  /'
echo "-- checks --"
check "board closure (requests lifecycle)"      bash "$SCRIPT_DIR/muster-requests-lint.sh"
check "entry bodies (fields + deliverables)"    bash "$SCRIPT_DIR/muster-lint-entry.sh"
check "decision reconciliation (Rule 11)"       bash "$SCRIPT_DIR/muster-lint-decisions.sh"
check "kb budgets (Rule 14 bootstrap surface)"  bash "$SCRIPT_DIR/muster-lint-kb-budgets.sh"
check "durability (Rule 15 durable docs)"       bash "$SCRIPT_DIR/muster-lint-durability.sh"
check "gate packet (notices folded)"            bash "$SCRIPT_DIR/muster-lint-gate-packet.sh"

if [ "$red" -eq 0 ]; then
  echo "ALL GREEN — paste this block into the closeout."
  exit 0
fi
echo "NOT GREEN — fix the ✗ items and re-run; closeout is not complete."
exit 1
