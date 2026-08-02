#!/usr/bin/env bash
# muster-lint-durability.sh — lint: Rule 15 durability discipline (family: lint — reports, never mutates).
#
# Durable artifacts describe CURRENT TRUTH only; transient archaeology (ticket IDs, sprint/wave
# refs, dated edit stamps, previously/now framings) belongs in the board files and git history.
# Rule 15 was a prose duty with no check; this is the check.
#
# Two tiers, calibrated on a live project corpus (a legitimate "rows added for new dimension
# values" sentence proved the phrasing patterns can't be hard failures):
#   FAIL — mechanical archaeology, no legitimate durable use:
#          HO-/REQ-/BUG-/DEC- IDs · `Sprint <n>` / `Wave <n>` refs · date-stamped edit bullets
#   WARN — phrasing smells for PM judgment (listed, never blocking):
#          "previously … now" · "revised per" · "changed from" · "added for"
# Fenced code blocks and inline code spans are skipped (format templates/examples self-trip).
#
# Scope: the knowledge-base durable set + agent-skills (below). SOURCE CODE is explicitly out
# of scope — project layouts vary; Rule 15 for code stays a review concern. The scanned file
# count is printed so a thin run is visible, never silent.
#
# Usage: muster-lint-durability.sh   (project call site: PM sprint-closeout gate)
# Exit: 0 clean (WARNs allowed) · 1 FAIL findings · 3 wiring error
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ "$(basename "$MUSTER_ROOT")" != "muster" ]; then
  echo "muster-lint-durability: not inside a project (muster tree not at <project>/muster/)" >&2; exit 3
fi
cd "$MUSTER_ROOT/.."

KB=knowledge-base
FILES=""
for f in "$KB"/product-spec.md "$KB"/architecture.md "$KB"/foundational-assumptions.md \
         "$KB"/brand-guidelines.md "$KB"/brand-voice-guide.md "$KB"/test-strategy.md \
         "$KB"/design-patterns.md "$KB"/migration-path.md; do
  [ -f "$f" ] && FILES="$FILES $f"
done
for d in "$KB"/design-specs "$KB"/agent-skills; do
  [ -d "$d" ] && FILES="$FILES $(find "$d" -name '*.md' -type f | sort | tr '\n' ' ')"
done

if [ -z "${FILES// /}" ]; then
  echo "OK: no durable knowledge-base files found to scan (fresh project?)"; exit 0
fi

fails=0; warns=0; scanned=0
for f in $FILES; do
  scanned=$((scanned+1))
  # Strip fenced blocks and inline code spans, then scan; keep line numbers via awk NR.
  out="$(awk '
    /^[[:space:]]*```/ { infence = !infence; next }
    infence { next }
    {
      line = $0
      gsub(/`[^`]*`/, "", line)          # inline code spans are examples, not claims
      lo = tolower(line)
      if (line ~ /(HO|REQ|BUG|DEC)-[0-9]+/)                        { print "FAIL\t" NR "\ttransient ID (HO-/REQ-/BUG-/DEC-)"; next }
      if (line ~ /(Sprint|Wave)[[:space:]]+[0-9]+/)                 { print "FAIL\t" NR "\tsprint/wave reference"; next }
      if (line ~ /^[[:space:]]*-[[:space:]]*\[?20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) { print "FAIL\t" NR "\tdate-stamped edit bullet"; next }
      if (lo ~ /previously[^.]*now/)                                { print "WARN\t" NR "\t\"previously - now\" framing"; next }
      if (lo ~ /revised per|changed from|added for/)                { print "WARN\t" NR "\trevision-archaeology phrasing"; next }
    }
  ' "$f")"
  [ -z "$out" ] && continue
  while IFS=$'\t' read -r kind ln why; do
    [ -z "$kind" ] && continue
    echo "$kind: $f:$ln — $why (Rule 15: current truth only; history belongs in board files + git)"
    [ "$kind" = "FAIL" ] && fails=$((fails+1)) || warns=$((warns+1))
  done <<< "$out"
done

echo "scanned $scanned durable file(s); $fails FAIL, $warns WARN (source code out of scope — review concern)"
[ "$fails" -eq 0 ] && { echo "OK: durability discipline clean"; exit 0; }
exit 1
