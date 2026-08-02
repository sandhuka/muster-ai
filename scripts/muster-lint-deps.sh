#!/usr/bin/env bash
# muster-lint-deps.sh — lint: brain-file dependency mirroring (family: lint — reports, never mutates).
#
# Brain files declare `- Depends on: <Agent> — why` / `- Provides to: <Agent> — why`.
# agent-management.md says "Mirror every dependency on both sides, every time, without
# exception" — restated in four places, enforced nowhere, and the graph was asymmetric in the
# field. This asserts: X depends on Y  ⟺  Y provides to X, for specialist↔specialist edges.
#
# PM and Founder endpoints are exempt: PM is the hub (its brain file declares the blanket
# "all agents depend on PM" + its own provides in prose, not the bullet convention) and
# Founder is not an agent (no brain file to mirror into).
#
# Usage: muster-lint-deps.sh [team-dir]   (default: the muster tree's team/ — works in both homes)
# Exit: 0 symmetric · 1 missing mirrors (each printed with the exact line to add) · 3 wiring
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEAM="${1:-$MUSTER_ROOT/team}"
[ -d "$TEAM" ] || { echo "muster-lint-deps: team dir not found: $TEAM" >&2; exit 3; }

# Emit edges as TSV: kind<TAB>src<TAB>dst  (kind: dep = src depends on dst; prov = src provides to dst)
edges="$(
  for f in "$TEAM"/*/CLAUDE.md; do
    [ -f "$f" ] || continue
    role="$(basename "$(dirname "$f")")"
    awk -v src="$role" '
      function norm(s) {
        sub(/[[:space:]]*[—–-].*$/, "", s)              # drop the "— why" tail
        gsub(/[Aa]gent/, "", s); gsub(/[^A-Za-z\/]/, "", s)
        s = tolower(s); gsub(/\//, "-", s)
        if (s == "ui-ux" || s == "uiux") s = "ui-ux"
        return s
      }
      /^-[[:space:]]*Depends on:/  { t = $0; sub(/^-[[:space:]]*Depends on:[[:space:]]*/,  "", t); printf "dep\t%s\t%s\n",  src, norm(t) }
      /^-[[:space:]]*Provides to:/ { t = $0; sub(/^-[[:space:]]*Provides to:[[:space:]]*/, "", t); printf "prov\t%s\t%s\n", src, norm(t) }
    ' "$f"
  done
)"

fails=0
check_mirror(){ # $1=kind-needed $2=src $3=dst $4=message
  printf '%s\n' "$edges" | grep -qxF "$(printf '%s\t%s\t%s' "$1" "$2" "$3")" && return 0
  echo "FAIL: $4"
  fails=$((fails+1))
}

while IFS=$'\t' read -r kind src dst; do
  [ -z "$kind" ] && continue
  case "$dst" in pm|founder|"") continue ;; esac
  case "$src" in pm) continue ;; esac
  if [ "$kind" = "dep" ]; then
    check_mirror prov "$dst" "$src" \
      "$src depends on $dst, but $TEAM/$dst/CLAUDE.md has no '- Provides to: ${src}' line — add the mirror"
  else
    check_mirror dep "$dst" "$src" \
      "$src provides to $dst, but $TEAM/$dst/CLAUDE.md has no '- Depends on: ${src}' line — add the mirror"
  fi
done <<< "$edges"

total="$(printf '%s\n' "$edges" | grep -c . || true)"
echo "checked ${total:-0} declared edge(s); $fails missing mirror(s)"
[ "$fails" -eq 0 ] && { echo "OK: dependency graph is symmetric (pm/founder hub edges exempt)"; exit 0; }
exit 1
