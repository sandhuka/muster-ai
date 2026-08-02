#!/usr/bin/env bash
# muster-lint-commit.sh — lint: commit-subject convention, CLAUDE.md Rule 16 (family: lint — reports OK/FAIL, never mutates).
#
# Convention: subject = '<role>: <outcome>' — the committing role, lowercase, then an
# outcome-first line (what the repo can now do, not the mechanics). ≤100 chars total —
# long enough to inform (never truncate meaning to fit), short enough to stay one line.
# HO-/DEC- references belong in the body, never the subject.
#
# Usage:  muster-lint-commit.sh [<commit>|<range>]     default: HEAD (last commit only)
#         a range ('abc123..HEAD') lints every non-merge commit in it.
# Exit:   0 all conforming · 1 violations (subjects printed) · 2 git error.
# Merge commits and the scaffold 'init' commit are exempt (not agent work-commits).
set -uo pipefail

ROLES='pm|developer|ui-ux|qa|content|marketing|legal|research|guide|xo|founder'
target="${1:-HEAD}"

if [[ "$target" == *".."* ]]; then
  subjects="$(git log --no-merges --format='%s' "$target" 2>/dev/null)" || { echo "⛔ bad range: $target"; exit 2; }
else
  subjects="$(git log --no-merges --format='%s' -1 "$target" 2>/dev/null)" || { echo "⛔ bad commit: $target"; exit 2; }
fi

bad=0
while IFS= read -r s; do
  [ -z "$s" ] && continue
  [ "$s" = "init" ] && continue
  if ! printf '%s' "$s" | grep -qE "^($ROLES): \S"; then
    echo "✗ no role prefix: $s"; bad=1; continue
  fi
  if [ "${#s}" -gt 100 ]; then
    echo "✗ subject ${#s} chars (max 100): $s"; bad=1
  fi
done <<< "$subjects"

[ "$bad" = 0 ] && exit 0 || exit 1
