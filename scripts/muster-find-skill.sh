#!/usr/bin/env bash
# muster-find-skill.sh — action: resolve a skill NAME to its file path (family: verb — answers, never mutates).
# Skills cite each other by name ("the `ios-mvvm` skill"); this is the name→path map, so no agent
# ever composes a path. Root- and cwd-agnostic: the muster tree is derived from THIS SCRIPT's
# location (scripts/ sits inside it in both homes — framework repo root, or muster/ in a project),
# never from the caller's cwd. Case-exact by construction: matches against real directory listings,
# never `[ -f ]` (which false-passes on case-insensitive macOS and then breaks on Linux CI).
#
# Usage:  muster-find-skill.sh <skill-name> [role]
#         <skill-name> with or without .md; [role] disambiguates names that exist in 2+ roles.
# Exit:   0 = one path printed · 1 = not found · 2 = ambiguous (candidates on stderr; pass a role) ·
#         3 = usage error
set -uo pipefail
[ $# -ge 1 ] || { echo "usage: muster-find-skill.sh <skill-name> [role]" >&2; exit 3; }
name="${1%.md}"; role="${2:-}"
mroot="$(cd "$(dirname "$0")/.." && pwd)"
hits="$(find "$mroot"/team/${role:-*}/skills -type f -name '*.md' 2>/dev/null \
        | while read -r p; do [ "$(basename "$p")" = "$name.md" ] && echo "$p"; done)"
n="$(printf '%s' "$hits" | grep -c . || true)"
case "$n" in
  1) printf '%s\n' "$hits" ;;
  0) echo "NOT FOUND: no skill named '$name'${role:+ under role '$role'}" >&2; exit 1 ;;
  *) echo "AMBIGUOUS: '$name' exists in multiple roles — pass the role as arg 2:" >&2
     printf '%s\n' "$hits" >&2; exit 2 ;;
esac
