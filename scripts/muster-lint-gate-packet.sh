#!/usr/bin/env bash
# muster-lint-gate-packet.sh — lint: founder-notice fold-in at wave gates (family: lint — reports, never mutates).
#
# The failure class is SILENCE: a notice the founder never sees was never surfaced, and
# sprint-planning says a notice "must never depend on luck to surface" — then enforced it with
# a PM self-review item, which is luck. This asserts, whenever a gate packet is ACTIVE:
#   FAIL — the packet has no `### Notices since last gate` heading (the fold-in scaffold)
#   FAIL — a live founder-notices.md entry (a `- YYYY-MM-DD ...` bullet) does not appear
#          VERBATIM in the packet
# No active gate (missing file / placeholder-only Current Wave) → OK, nothing to gate.
#
# Usage: muster-lint-gate-packet.sh [wave-review] [founder-notices]
#   defaults: knowledge-base/wave-review.md  knowledge-base/founder-notices.md
# Exit: 0 clean · 1 FAIL findings · 3 wiring error
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ "$(basename "$MUSTER_ROOT")" != "muster" ]; then
  echo "muster-lint-gate-packet: not inside a project (muster tree not at <project>/muster/)" >&2; exit 3
fi
cd "$MUSTER_ROOT/.."

WR="${1:-knowledge-base/wave-review.md}"
FN="${2:-knowledge-base/founder-notices.md}"
[ -f "$WR" ] || { echo "OK: no wave-review packet at $WR — nothing to gate"; exit 0; }

# Active gate = a **Wave:** line whose value is not a [placeholder].
wave_line="$(grep -m1 '^\*\*Wave:\*\*' "$WR" || true)"
case "$wave_line" in
  ""|*"["*) echo "OK: no active gate in $WR (placeholder or none) — nothing to lint"; exit 0 ;;
esac

fails=0
if ! grep -q '^### Notices since last gate' "$WR"; then
  echo "FAIL: $WR has an active gate but no '### Notices since last gate' heading — the fold-in scaffold is missing (a notice with no place to land depends on luck)"
  fails=$((fails+1))
fi

# Live notices: comment-stripped `- YYYY-MM-DD ...` bullets in founder-notices.md.
if [ -f "$FN" ]; then
  while IFS= read -r notice; do
    [ -z "$notice" ] && continue
    if ! grep -qF -- "$notice" "$WR"; then
      echo "FAIL: live notice not folded into the gate packet verbatim: $notice"
      fails=$((fails+1))
    fi
  done < <(awk '
    incomment { if ($0 ~ /-->/) incomment=0; next }
    /<!--/ && !/-->/ { incomment=1; next }
    /<!--.*-->/ { next }
    /^-[[:space:]]*20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ { print }
  ' "$FN")
fi

[ "$fails" -eq 0 ] && { echo "OK: gate packet carries the notices scaffold and every live notice"; exit 0; }
exit 1
