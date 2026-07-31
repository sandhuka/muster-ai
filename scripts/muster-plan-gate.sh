#!/usr/bin/env bash
# muster-plan-gate.sh — action: the sprint-planning gate, one pasteable verdict (family: verb — reports, never mutates).
#
# PM prose used to say "run these checks and paste the green results" — whether ALL ran, in
# order, was an honor system, and a partial paste is forgeable. This wrapper runs the planning
# gates in the mandated order, prints one ✓/✗ block, and REFUSES to print a green summary if
# anything failed. Zero new check logic — it only sequences the existing lints.
#
# Order: queue structure → context gate for EVERY role queued (Next Step + Upcoming) → kb budgets.
#
# Usage: muster-plan-gate.sh    Exit: 0 all green · 1 any red · 3 wiring error
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ "$(basename "$MUSTER_ROOT")" != "muster" ]; then
  echo "muster-plan-gate: not inside a project (muster tree not at <project>/muster/)" >&2; exit 3
fi
cd "$MUSTER_ROOT/.."

red=0
check(){ # $1=label, rest=command
  local label="$1"; shift
  local out rc; out="$("$@" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then echo "✓ $label"
  else red=1; echo "✗ $label"; printf '%s\n' "$out" | sed 's/^/    /'; fi
}

echo "MUSTER PLAN GATE"
check "queue structure (driver-parseable)" bash "$SCRIPT_DIR/muster-queue-lint.sh"

QUEUE=knowledge-base/orchestration-queue.md
roles="$(grep '^Role:' "$QUEUE" 2>/dev/null | sed 's/^Role:[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^halt$' | sort -u || true)"
if [ -z "$roles" ]; then
  echo "✓ context gate (no agent steps queued)"
else
  for r in $roles; do
    check "context gate: $r has real inlined tasks" bash "$SCRIPT_DIR/muster-lint-context.sh" "$r"
  done
fi

check "kb budgets (Rule 14 bootstrap surface)" bash "$SCRIPT_DIR/muster-lint-kb-budgets.sh"

if [ "$red" -eq 0 ]; then
  echo "ALL GREEN — paste this block into the planning closeout."
  exit 0
fi
echo "NOT GREEN — fix the ✗ items and re-run; planning is not complete."
exit 1
