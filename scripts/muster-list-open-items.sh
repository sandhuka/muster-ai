#!/usr/bin/env bash
# muster-list-open-items.sh — action: sprint-boundary open-item enumerator (family: verb — answers, never mutates).
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
# Usage: bash muster/scripts/muster-list-open-items.sh [--for <role>] [REQUESTS] [CHANGELOG]
#   defaults: knowledge-base/agent-requests.md  knowledge-base/research/change-log.md
#
# --for <role>: the per-role session-start view (replaces the communication-check prose in the
# role bootloaders). Prints three actionable groups for that role — requests addressed to it
# and still open (TO_ME_OPEN), handoffs where its reviewer box is unticked-pending
# (REVIEW_PENDING), and its own handoffs sent back (MY_NEEDS_REVISION) — with STALE(>5d) tags
# computed by real date arithmetic. Role names in entries are matched tolerantly
# (PM/pm, UI/UX / ui-ux, etc.). Detection-only like the no-arg mode: always exits 0.
set -uo pipefail

FOR_ROLE=""
if [ "${1:-}" = "--for" ]; then
  FOR_ROLE="${2:-}"; shift 2 || { echo "usage: muster-list-open-items.sh [--for <role>] [REQUESTS] [CHANGELOG]" >&2; exit 3; }
  case "$FOR_ROLE" in
    pm|developer|ui-ux|qa|content|marketing|legal|research) ;;
    *) echo "usage: muster-list-open-items.sh [--for <role>] — role must be one of: pm developer ui-ux qa content marketing legal research" >&2; exit 3 ;;
  esac
fi
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

# Staleness constant — single source for both modes (PM monitoring flags STALE to the founder).
STALE_DAYS=5
stale_tag(){ # $1 = age_days output ("Nd" or "?")
  case "$1" in
    [0-9]*d) [ "${1%d}" -gt "$STALE_DAYS" ] && printf '  STALE(>%sd)' "$STALE_DAYS" ;;
  esac
  return 0
}

# Print one enumerated group with ages, or "(none)".
print_group() {
  local label="$1"; shift
  printf '%s:\n' "$label"
  local printed=0 date id status title age
  while IFS=$'\t' read -r date id status title; do
    printed=1
    age="$(age_days "$date")"
    printf '  %-8s %-14s %-12s (%s)%s  — %s\n' \
      "${id:-—}" "${status:-?}" "${date:-—}" "$age" "$(stale_tag "$age")" "${title:-}"
  done < <("$@")
  [ "$printed" -eq 1 ] || printf '  (none)\n'
}

# --for mode: per-role entry scan. One awk pass over both Active sections; emits
# TSV: group<TAB>id<TAB>date<TAB>title. Name matching normalizes both sides to lowercase
# alphanumerics ("UI/UX" == "ui-ux" == "uiux") so display-name drift can't hide an item.
my_items(){
  [ -f "$REQUESTS" ] || return 0
  awk -v role="$FOR_ROLE" '
    function norm(s){ s=tolower(s); gsub(/[^a-z0-9]/,"",s); return s }
    function flush(){
      if (!have) return
      if (sec=="req" && norm(eto)==nrole && estatus ~ /^open/)                 emit("TO_ME_OPEN")
      if (sec=="ho"  && revpending)                                            emit("REVIEW_PENDING")
      if (sec=="ho"  && norm(eprod)==nrole && estatus ~ /needs-revision/)      emit("MY_NEEDS_REVISION")
      have=0
    }
    function emit(g){ printf "%s\t%s\t%s\t%s\n", g, (eid==""?"-":eid), (edate==""?"-":edate), (etitle==""?"-":etitle) }
    BEGIN { nrole = norm(role) }
    incomment { if ($0 ~ /-->/) incomment=0; next }
    /<!--/ && !/-->/ { incomment=1; next }
    /<!--.*-->/ { next }
    /^## / {
      flush()
      hdr=$0; sub(/^##[[:space:]]+/,"",hdr)
      sec = (hdr ~ /^Active Requests/) ? "req" : (hdr ~ /^Active Handoffs/) ? "ho" : ""
      next
    }
    sec != "" && /^###[[:space:]]/ {
      flush()
      have=1; edate=""; eid=""; estatus=""; etitle=""; eto=""; eprod=""; revpending=0
      if (match($0, /[0-9]{4}-[0-9]{2}-[0-9]{2}/)) edate = substr($0, RSTART, RLENGTH)
      if (match($0, /(HO|REQ)-[0-9]+/))            eid   = substr($0, RSTART, RLENGTH)
      t=$0; sub(/^###[[:space:]]+/,"",t)
      gsub(/[0-9]{4}-[0-9]{2}-[0-9]{2}/,"",t); gsub(/(HO|REQ)-[0-9]+/,"",t)
      sub(/^[[:space:]]*[—–-]+[[:space:]]*/,"",t); sub(/^[[:space:]]+/,"",t); sub(/[[:space:]]+$/,"",t)
      etitle=t; next
    }
    # field captures: cut at the first colon, drop bold markers, trim BOTH ends — the `**`
    # after the colon leaves a leading space once stripped, which would break anchored matches
    have && /\*\*[Ss]tatus/   { s=$0; sub(/^[^:]*:[[:space:]]*/,"",s); gsub(/\*/,"",s); sub(/^[[:space:]]+/,"",s); sub(/[[:space:]]+$/,"",s); if (estatus=="") estatus=tolower(s) }
    have && /\*\*[Tt]o/       { s=$0; sub(/^[^:]*:[[:space:]]*/,"",s); gsub(/\*/,"",s); sub(/^[[:space:]]+/,"",s); sub(/[[:space:]]+$/,"",s); if (eto=="")   eto=s }
    have && /\*\*[Pp]roducer/ { s=$0; sub(/^[^:]*:[[:space:]]*/,"",s); gsub(/\*/,"",s); sub(/^[[:space:]]+/,"",s); sub(/[[:space:]]+$/,"",s); if (eprod=="") eprod=s }
    have && /^[[:space:]]*-[[:space:]]*\[ \]/ && /pending/ {
      s=$0; sub(/^[[:space:]]*-[[:space:]]*\[ \][[:space:]]*/,"",s); sub(/[[:space:]]*[—–-].*$/,"",s)
      if (norm(s)==nrole) revpending=1
    }
    END { flush() }
  ' "$REQUESTS"
}

print_my_group(){ # $1=group label, $2=pre-captured TSV file
  local label="$1" file="$2" printed=0 g id date title age
  printf '%s:\n' "$label"
  while IFS=$'\t' read -r g id date title; do
    [ "$g" = "$label" ] || continue
    printed=1
    age="$(age_days "$date")"
    printf '  %-8s %-12s (%s)%s — %s\n' "${id:-—}" "${date:-—}" "$age" "$(stale_tag "$age")" "${title:-}"
  done < "$file"
  [ "$printed" -eq 1 ] || printf '  (none)\n'
}

if [ -n "$FOR_ROLE" ]; then
  MYTSV="$(mktemp)"; trap 'rm -f "$MYTSV"' EXIT
  my_items > "$MYTSV"
  echo "MY ITEMS — $FOR_ROLE (act on each; >5 days old = STALE, flag it):"
  echo
  print_my_group "TO_ME_OPEN"        "$MYTSV"   # respond, then set Status: done
  echo
  print_my_group "REVIEW_PENDING"    "$MYTSV"   # review deliverable, update your reviewer sub-status
  echo
  print_my_group "MY_NEEDS_REVISION" "$MYTSV"   # read feedback, revise, update revision log
  exit 0
fi

echo "Open items at sprint boundary — disposition each (close-if-validated / carry-forward / defer)."
echo "Detection only; this never blocks closeout. Judge prior-sprint vs current by context."
echo
print_group "HANDOFFS (Active Handoffs — unresolved)"                              enumerate "$REQUESTS"  "Active Handoffs"
echo
print_group "REQUESTS (Active Requests — unresolved)"                              enumerate "$REQUESTS"  "Active Requests"
echo
print_group "RESEARCH (change-log Active — needs-research / in-progress / unconsumed)" enumerate "$CHANGELOG" "Active"

exit 0
