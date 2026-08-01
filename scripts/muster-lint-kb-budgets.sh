#!/usr/bin/env bash
# muster-lint-kb-budgets.sh — lint: Rule 14's RUNTIME half (family: lint — reports, never mutates).
#
# test-pillar-budgets.sh guards the SHIPPED templates; it explicitly leaves live-project growth
# to "Rule 14's own archiving job" — prose. This is that job's check. Failure mode is slow
# accretion: nobody notices bootstrap creep 600 → 900 lines; the cost shows up as degraded
# output and higher bills, never as an error.
#
# Checks (mirrors the static tier-1 proxy, measured live):
#   FAIL — PM bootstrap-read total > 600 lines (project CLAUDE.md + muster/team/pm/bootloader.md +
#          muster/team/pm/CLAUDE.md + the 8 monitoring KB files). Prints per-file breakdown
#          and names the archive move for the top offenders.
#   FAIL — current-sprint.md holds more than one sprint (completed sprints belong in
#          sprint-archive.md at closeout).
#   WARN — soft per-file ceilings on the usual accretors (decision-log 150, current-sprint 120,
#          founder-notices 20 lines) — early nudges before the total reddens.
# This script is also the arbiter of a doc contradiction: archiving triggers are these
# budgets — not an entry-count rule; agent-management.md and sprint-planning.md defer here.
#
# Usage: muster-lint-kb-budgets.sh   (call sites: PM closeout gate; PM bind-time monitoring)
# Exit: 0 within budget (WARNs allowed) · 1 over budget / multi-sprint · 3 wiring error
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ "$(basename "$MUSTER_ROOT")" != "muster" ]; then
  echo "muster-lint-kb-budgets: not inside a project (muster tree not at <project>/muster/)" >&2; exit 3
fi
cd "$MUSTER_ROOT/.."

BUDGET=600
KB=knowledge-base
TIER1="CLAUDE.md muster/team/pm/bootloader.md muster/team/pm/CLAUDE.md \
$KB/orchestration-queue.md $KB/agent-requests.md $KB/current-sprint.md $KB/decision-log.md \
$KB/founder-notices.md $KB/ui-component-requests.md $KB/pre-launch-checklist.md $KB/foundational-assumptions.md"

remedy(){ # per-file archive/trim move for the offender report
  case "$1" in
    */orchestration-queue.md)  echo "Done cap is script-enforced; trim Upcoming step verbosity, archive answered Founder Decisions" ;;
    */agent-requests.md)       echo "reconcile Active to Resolved (muster-lint-requests.sh) and trim Resolved to its cap" ;;
    */decision-log.md)         echo "move pre-current-sprint entries to decision-log-archive.md" ;;
    */current-sprint.md)       echo "move completed sprints to sprint-archive.md; full task specs live in agent-context files" ;;
    */founder-notices.md)      echo "sweep acted-on / stale notices" ;;
    CLAUDE.md)                 echo "project rules creep — move detail to on-demand KB docs" ;;
    *)                         echo "trim or archive — this file is read at every PM bind" ;;
  esac
}

fails=0; warns=0; total=0
breakdown=""
for f in $TIER1; do
  if [ -f "$f" ]; then n="$(wc -l < "$f" | tr -d ' ')"; else n=0; fi
  total=$((total + n))
  breakdown="$breakdown$(printf '%4d\t%s' "$n" "$f")"$'\n'
done

echo "PM bootstrap-read total: $total/$BUDGET lines"
printf '%s' "$breakdown" | awk -F'\t' '{printf "  %4d  %s\n", $1, $2}'

if [ "$total" -gt "$BUDGET" ]; then
  fails=$((fails+1))
  echo "FAIL: bootstrap reads exceed Rule 14's $BUDGET-line budget. Top offenders:"
  printf '%s' "$breakdown" | sort -rn | head -3 | while IFS=$'\t' read -r sz f; do
    [ -z "$f" ] && continue
    echo "  - $f ($sz lines): $(remedy "$f")"
  done
fi

# One active sprint only — count sprint headings (h1/h2) in current-sprint.md.
if [ -f "$KB/current-sprint.md" ]; then
  sprints="$(grep -cE '^#{1,2} Sprint ' "$KB/current-sprint.md" || true)"
  if [ "${sprints:-0}" -gt 1 ]; then
    fails=$((fails+1))
    echo "FAIL: current-sprint.md holds $sprints sprint headings — only the active sprint stays; move completed sprints to sprint-archive.md"
  fi
fi

soft(){ # $1=file $2=ceiling $3=hint
  [ -f "$1" ] || return 0
  local n; n="$(wc -l < "$1" | tr -d ' ')"
  if [ "$n" -gt "$2" ]; then
    warns=$((warns+1))
    echo "WARN: $1 at $n lines (soft ceiling $2) — $3"
  fi
  return 0
}
soft "$KB/decision-log.md"    150 "archive pre-current-sprint entries to decision-log-archive.md"
soft "$KB/current-sprint.md"  120 "trim: full task specs belong in agent-context files; board stays thin"
soft "$KB/founder-notices.md"  20 "sweep acted-on / stale notices (git history preserves them)"

echo "$fails FAIL, $warns WARN"
[ "$fails" -eq 0 ] && { echo "OK: knowledge-base within Rule 14 budgets"; exit 0; }
exit 1
