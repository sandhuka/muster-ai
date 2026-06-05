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

# Extract every HO-NNN referenced in that one entry (case-insensitive), de-duplicated so the
# failure message can't repeat an ID (e.g. "HO-034 HO-034").
refs="$(printf '%s' "$recent_done" | grep -oiE 'HO-[0-9]+' | tr '[:lower:]' '[:upper:]' | sort -u)"

# Conditional: a Done entry with no HO reference is skipped (rule 2).
[ -n "$refs" ] || exit 0

# Build the set of HO-NNN that are provably FILED. A filed HO leaves a definition trace in two
# normal states, and BOTH count:
#   (a) live handoff heading — '### [DATE] HO-NNN — Title' (status open/in-review/needs-revision).
#   (b) a bullet in the '## Resolved' section — when PM accepts an HO it moves it here and DELETES
#       the ### heading, so a resolved-but-filed HO has NO heading. The most-recent Done entry
#       routinely points at such an HO (loop start after manual steps; any interleaved PM review
#       step that resolves the HO it reviewed) — checking headings only would false-positive.
# Prose mentions (e.g. a revision-log "depends on HO-027") are NOT definitions: they live inside
# Active-Handoff ### blocks, never as a '### ' heading nor a Resolved bullet, so neither source
# matches them. A genuinely never-filed HO (e.g. HO-999) appears in neither → still trips the lint.
# Resolved is section-scoped (any bullet between '## Resolved' and the next '## ') rather than
# format-matched, because the template only promises "one-liner summaries" — no fixed bullet shape.
heading_hos="$(grep -iE '^###[[:space:]].*HO-[0-9]+' "$REQUESTS" | grep -oiE 'HO-[0-9]+')"
resolved_hos="$(awk '
  /^##[[:space:]]+[Rr]esolved/ {inres=1; next}
  inres && /^## /             {exit}
  inres && /^[[:space:]]*-/   {print}
' "$REQUESTS" | grep -oiE 'HO-[0-9]+')"
defined="$(printf '%s\n%s\n' "$heading_hos" "$resolved_hos" \
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
