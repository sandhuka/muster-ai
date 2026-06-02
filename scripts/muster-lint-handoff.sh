#!/usr/bin/env bash
# muster-lint-handoff.sh — handoff-filing integrity check (deterministic).
#
# Catches the dangling-reference failure: an agent writes a queue Done entry that
# references (HO-NNN), advances the queue, but never files HO-NNN in agent-requests.md.
# The dangling reference breaks the next step's inputs and the review trail.
#
# Invoked at the TOP of each loop iteration by muster-sprint-run.sh (a few lines of
# mechanical integrity checking — NOT policy; the driver stays dumb).
#
# Rules (from BUILD spec §7.8 — implemented exactly):
#   1. Most-recent Done entry ONLY (top of '## Done'), never the whole queue. Old entries
#      false-positive on legitimately trimmed HOs (queue Done and agent-requests Resolved
#      have different retention).
#   2. Conditional — only a Done entry containing an HO-NNN reference is checked; no-ref
#      Done entries (PM / coordination / wave-gate steps) are skipped.
#   3. Normalize zero-padding when matching (HO-37 == HO-037); check ALL referenced IDs.
#   4. Existence only, not content. A thin HO body passes; quality is a PM concern.
#
# Exit 0 = pass (HOs present, or nothing to check). Exit 1 = a referenced HO is missing.
#
# Usage: bash muster/scripts/muster-lint-handoff.sh [QUEUE] [REQUESTS]
#   defaults: knowledge-base/orchestration-queue.md  knowledge-base/agent-requests.md
set -uo pipefail

QUEUE="${1:-knowledge-base/orchestration-queue.md}"
REQUESTS="${2:-knowledge-base/agent-requests.md}"

[ -f "$QUEUE" ]    || { echo "lint-handoff: no queue at $QUEUE"; exit 1; }
[ -f "$REQUESTS" ] || { echo "lint-handoff: no agent-requests at $REQUESTS"; exit 1; }

# Most-recent Done entry = the first bullet line under '## Done' (newest is at the top).
# awk: inside the Done section, capture the first line beginning with '-' and stop.
recent_done="$(awk '
  /^## Done/      {indone=1; next}
  indone && /^## /{exit}
  indone && /^[[:space:]]*-/ {print; exit}
' "$QUEUE")"

# Nothing in Done yet — nothing to verify.
[ -n "$recent_done" ] || exit 0

# Extract every HO-NNN referenced in that one entry (case-insensitive).
refs="$(printf '%s' "$recent_done" | grep -oiE 'HO-[0-9]+' | tr '[:lower:]' '[:upper:]')"

# Conditional: a Done entry with no HO reference is skipped (rule 2).
[ -n "$refs" ] || exit 0

# Numbers actually defined as handoff entries in agent-requests.md, zero-stripped.
# Anchor to the '### [DATE] HO-NNN — Title' heading form from the Handoff Entry template:
# a mere prose mention of HO-NNN (e.g. a revision-log "depends on HO-NNN") is NOT a filed
# handoff and must not count as defined. Safe against resolved HOs because the lint only
# checks the most-recent Done entry, whose HO was just filed and is still a live ### heading.
defined="$(grep -iE '^###[[:space:]].*HO-[0-9]+' "$REQUESTS" \
  | grep -oiE 'HO-[0-9]+' \
  | grep -oE '[0-9]+' \
  | sed 's/^0*\([0-9]\)/\1/' \
  | sort -u)"

missing=""
for ref in $refs; do
  num="${ref#HO-}"
  num="${num#"${num%%[!0]*}"}"   # strip leading zeros (HO-037 -> 37); guard all-zero below
  [ -n "$num" ] || num=0
  if ! printf '%s\n' "$defined" | grep -qx "$num"; then
    missing="${missing:+$missing }$ref"
  fi
done

if [ -n "$missing" ]; then
  echo "⛔ Handoff-integrity: most-recent Done entry references $missing but it is not filed in $REQUESTS."
  echo "   Entry: ${recent_done#"${recent_done%%[![:space:]]*}"}"
  exit 1
fi
exit 0
