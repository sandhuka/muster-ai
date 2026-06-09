#!/usr/bin/env bash
# muster-list-open-items.sh — sprint-boundary open-item enumerator (deterministic, detection-only).
#
# The problem it counters: handoffs/requests accumulate unresolved in agent-requests.md and
# research/change-log.md and leak across sprint boundaries. Collective validation (one regression
# sweep validates many prior handoffs) never ticks each handoff's reviewer boxes, so they never
# reach `done` and never move to Resolved; nothing sweeps the board at the boundary. The historical
# failure was ATTENTION, not disposition — stale items sat un-noticed for weeks. This script makes
# detection deterministic and complete; PM still makes the close-vs-carry judgement.
#
# Invoked by the PM at TWO call sites in `sprint-planning.md` (both run in all three modes, because
# both are PM-driven and mode-agnostic):
#   1. Sprint Closeout — reconcile before archiving.
#   2. Sprint Planning start — catch anything an interrupted/skipped closeout left behind, before
#      building the new queue.
#
# DETECTION-ONLY by design. It ALWAYS exits 0 and never halts anything. In-review handoffs are
# legitimate mid-sprint, so this must NOT be wired into muster-sprint-run.sh's per-iteration lint
# gate — that would stop every autonomous run on normal in-progress work. It only enumerates.
#
# It lists EVERY entry still sitting in an Active section (over-inclusive in the safe direction):
# the self-cleaning rule moves `done` entries to Resolved immediately, so anything left in an
# Active-* section is by definition unresolved and owed a disposition. Status is printed as a hint;
# inclusion does not depend on parsing it (robust to status-format drift between files).
#
# Usage: bash muster/scripts/muster-list-open-items.sh [REQUESTS] [CHANGELOG]
#   defaults: knowledge-base/agent-requests.md  knowledge-base/research/change-log.md
set -uo pipefail

REQUESTS="${1:-knowledge-base/agent-requests.md}"
CHANGELOG="${2:-knowledge-base/research/change-log.md}"

# Age in whole days from a YYYY-MM-DD date. Portable: GNU date, then BSD/macOS date, else "?".
# Never errors — a date it can't parse just prints "?" so the script can't crash on format drift.
age_days() {
  local d="$1" epoch now
  [ -n "$d" ] || { printf '?'; return; }
  if   epoch=$(date -d "$d" +%s 2>/dev/null); then :
  elif epoch=$(date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null); then :
  else printf '?'; return; fi
  now=$(date +%s)
  printf '%dd' $(( (now - epoch) / 86400 ))
}

# Enumerate entries under ONE named section of a markdown file.
# Emits TSV: date<TAB>id<TAB>status<TAB>title  (one record per `### ` entry; empty fields are
# emitted as "-" so a whitespace IFS can't collapse adjacent tabs and scramble the columns).
# An entry = a `### ` heading plus the first `**Status...` line beneath it (status optional).
# Pairing is buffered: a new `### ` or a section boundary flushes the pending entry, so an entry
# with no status line is still emitted. Title is derived by subtraction (strip the heading marker,
# the date, the id, and a leading dash separator) so it doesn't depend on matching a literal em-dash.
enumerate() {
  local file="$1" section="$2"
  [ -f "$file" ] || return 0
  awk -v sec="$section" '
    function flush() {
      if (have) {
        printf "%s\t%s\t%s\t%s\n",
          (edate   == "") ? "-" : edate,
          (eid     == "") ? "-" : eid,
          (estatus == "") ? "-" : estatus,
          (etitle  == "") ? "-" : etitle
        have = 0
      }
    }
    # Skip HTML comments so commented-out entry templates (e.g. "### [DATE] — [Topic]" living
    # under ## Active in a fresh change-log) are never parsed as real entries.
    incomment { if ($0 ~ /-->/) incomment = 0; next }
    /<!--/ && !/-->/ { incomment = 1; next }
    /<!--.*-->/ { next }
    /^## / {
      flush()
      hdr = $0; sub(/^##[[:space:]]+/, "", hdr); sub(/[[:space:]]+$/, "", hdr)
      insec = (hdr == sec)
      next
    }
    insec && /^###[[:space:]]/ {
      flush()
      have = 1; edate = ""; eid = ""; estatus = ""; etitle = ""
      if (match($0, /[0-9]{4}-[0-9]{2}-[0-9]{2}/)) edate = substr($0, RSTART, RLENGTH)
      if (match($0, /(HO|REQ)-[0-9]+/))            eid   = substr($0, RSTART, RLENGTH)
      t = $0
      sub(/^###[[:space:]]+/, "", t)
      gsub(/[0-9]{4}-[0-9]{2}-[0-9]{2}/, "", t)
      gsub(/(HO|REQ)-[0-9]+/, "", t)
      sub(/^[[:space:]]*[—–-]+[[:space:]]*/, "", t)   # strip a leading em/en/hyphen separator
      sub(/^[[:space:]]+/, "", t); sub(/[[:space:]]+$/, "", t)
      etitle = t
      next
    }
    insec && have && estatus == "" && /\*\*[Ss]tatus/ {
      s = $0
      sub(/^[^:]*:[[:space:]]*/, "", s)   # strip up to and incl. the first colon
      gsub(/\*/, "", s)                    # drop any trailing bold markers
      sub(/[[:space:]]+$/, "", s)
      estatus = s
    }
    END { flush() }
  ' "$file"
}

# Print one enumerated group with ages, or "(none)".
print_group() {
  local label="$1"; shift
  printf '%s:\n' "$label"
  local printed=0 date id status title
  while IFS=$'\t' read -r date id status title; do
    printed=1
    printf '  %-8s %-14s %-12s (%s)  — %s\n' \
      "${id:-—}" "${status:-?}" "${date:-—}" "$(age_days "$date")" "${title:-}"
  done < <("$@")
  [ "$printed" -eq 1 ] || printf '  (none)\n'
}

echo "Open items at sprint boundary — disposition each (close-if-validated / carry-forward / defer)."
echo "Detection only; this never blocks closeout. Judge prior-sprint vs current by context."
echo
print_group "HANDOFFS (Active Handoffs — unresolved)"                              enumerate "$REQUESTS"  "Active Handoffs"
echo
print_group "REQUESTS (Active Requests — unresolved)"                              enumerate "$REQUESTS"  "Active Requests"
echo
print_group "RESEARCH (change-log Active — needs-research / in-progress / unconsumed)" enumerate "$CHANGELOG" "Active"

exit 0
