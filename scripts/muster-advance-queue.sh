#!/usr/bin/env bash
# muster-advance-queue.sh — action: session-completion queue advance (family: verb — acts).
#
# Replaces the advance procedure duplicated across all 8 role bootloaders: move the finished
# Next Step to Done (one-line entry, newest first, 10-entry cap), promote the first Upcoming
# step to Next Step (or mark the sprint complete). This is the step-end mutation autonomous
# runs corrupt when a model does it half-right — so it is SELF-CHECKING: the rewrite lands in
# a temp file, muster-queue-lint.sh must pass on it, and the real queue is replaced only on
# green. A red self-check leaves the queue untouched and exits 1.
#
# Safety contract:
#   - Refuses to advance a step whose `Role:` is not the caller's (an agent moving someone
#     else's step is the corruption class; route to PM instead). `Role: halt` is a founder
#     gate — never advanced by an agent.
#   - WARNs (does not block) when a specialist summary carries no HO-ref — the driver's
#     handoff lint stops the run later if a referenced HO is missing; no ref means no check.
#   - Fence-aware parsing throughout: `## `/`### ` lines INSIDE a step's fenced block are
#     body text, never section/step boundaries (clones muster-queue-lint.sh's toggle).
#
# Usage: bash muster/scripts/muster-advance-queue.sh <role> "<one-line summary>"
# Exit:  0 advanced (prints what moved) · 1 refused (reason printed, queue untouched) · 3 usage
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ "$(basename "$MUSTER_ROOT")" != "muster" ]; then
  echo "muster-advance-queue: not inside a project (muster tree not at <project>/muster/)" >&2; exit 3
fi
cd "$MUSTER_ROOT/.."

ROLE="${1:-}"; shift || true
SUMMARY="$(printf '%s' "$*" | tr '\n' ' ')"
case "$ROLE" in
  pm|developer|ui-ux|qa|content|marketing|legal|research) ;;
  *) echo "usage: muster-advance-queue.sh <role> \"<one-line summary>\"" >&2; exit 3 ;;
esac
[ -n "$SUMMARY" ] || { echo "usage: muster-advance-queue.sh <role> \"<one-line summary>\" (summary required)" >&2; exit 3; }

QUEUE="knowledge-base/orchestration-queue.md"
[ -f "$QUEUE" ] || { echo "muster-advance-queue: no queue at $QUEUE" >&2; exit 1; }

source "$SCRIPT_DIR/muster-read-queue.sh"

STEP_ROLE="$(next_role)"
if [ -z "$STEP_ROLE" ]; then
  echo "REFUSED: Next Step has no fenced step (sprint complete or not planned) — nothing to advance."; exit 1
fi
if [ "$STEP_ROLE" = "halt" ]; then
  echo "REFUSED: Next Step is a 'Role: halt' founder gate — agents never advance it. PM resumes via muster-sprint-resume.sh."; exit 1
fi
if [ "$STEP_ROLE" != "$ROLE" ]; then
  echo "REFUSED: Next Step is Role: $STEP_ROLE, not yours ($ROLE). Do not advance another role's step — route to PM."; exit 1
fi

case "$ROLE" in
  pm) DISPLAY="PM" ;; developer) DISPLAY="Developer" ;; ui-ux) DISPLAY="UI/UX" ;;
  qa) DISPLAY="QA" ;; content) DISPLAY="Content" ;; marketing) DISPLAY="Marketing" ;;
  legal) DISPLAY="Legal" ;; research) DISPLAY="Research" ;;
esac
# grep -c, not -q: -q's early exit can SIGPIPE printf under pipefail; -c reads to EOF
if [ "$ROLE" != "pm" ] && ! printf '%s\n' "$SUMMARY" | grep -ciE 'HO-[0-9]+' >/dev/null; then
  echo "WARN: summary has no HO-NNN reference — if this step filed a handoff, cite it (the driver's handoff lint checks cited refs only)."
fi

DATE="$(date +%F)"
export ENTRY="- $DATE $DISPLAY: $SUMMARY"   # via ENVIRON: awk -v would reinterpret backslashes in summaries
TMP="$(mktemp)"
PROMOTED_LABEL_FILE="$(mktemp)"
trap 'rm -f "$TMP" "$PROMOTED_LABEL_FILE"' EXIT

# One fence-aware pass: discard the finished step from Next Step (keep heading + comment lines),
# move the first Upcoming step (its heading lines + one fence-pair) into Next Step, insert the
# Done entry newest-first, cap Done at 10 bullets. Section tracking ignores lines inside fences.
awk -v labelfile="$PROMOTED_LABEL_FILE" '
  BEGIN { entry = ENVIRON["ENTRY"] }
  function section_of(line) {
    if (line ~ /^## Next Step[[:space:]]*$/) return "ns"
    if (line ~ /^## Upcoming[[:space:]]*$/)  return "up"
    if (line ~ /^## Done/)                    return "done"
    if (line ~ /^## /)                        return "other"
    return ""
  }
  { lines[NR] = $0 }
  END {
    n = NR
    # ---- pass 1: locate the completed step in Next Step AND the first Upcoming step ----
    # Same window shape for both (fence-aware): first heading line -> its fence CLOSE.
    # Everything else in Next Step (PM preamble notes, separators, comments) is preserved —
    # the advance excises exactly one step, it does not sanitize the section.
    sec = ""; fence = 0
    pstart = 0; pend = 0; pstarted = 0        # Upcoming: step to promote
    dstart = 0; dend = 0; dstarted = 0        # Next Step: finished step to excise
    for (i = 1; i <= n; i++) {
      l = lines[i]
      if (!fence) { s = section_of(l); if (s != "") sec = s }
      if (l ~ /^```/) fence = !fence
      if (sec == "ns" && !dend) {
        if (!dstarted && !fence && l ~ /^#+[[:space:]]/ && l !~ /^## /) { dstart = i; dstarted = 1 }
        if (dstarted && l ~ /^```/ && !fence) dend = i               # fence just CLOSED
      }
      if (sec == "up") {
        if (!pstarted && !fence && l ~ /^#+[[:space:]]/ && l !~ /^## /) { pstart = i; pstarted = 1 }
        if (pstarted && l ~ /^```/ && !fence) { pend = i; break }    # fence just CLOSED
      }
    }
    have_promo = (pstart > 0 && pend >= pstart)
    have_done_step = (dstart > 0 && dend >= dstart)
    # A fence in Next Step with no locatable heading->fence window is malformed input —
    # refuse (exit 9) rather than mutate around it; bash reports and leaves the queue alone.
    if (!have_done_step) exit 9
    if (have_promo) {
      for (i = pstart; i <= pend; i++)
        if (lines[i] ~ /^#+[[:space:]]/ && lines[i] !~ /^## /) {
          lab = lines[i]; sub(/^#+[[:space:]]+/, "", lab); print lab > labelfile; break
        }
    }
    # ---- pass 2: emit the rebuilt file -------------------------------------
    sec = ""; fence = 0; done_bullets = 0; done_inserted = 0
    for (i = 1; i <= n; i++) {
      l = lines[i]
      if (!fence) { s = section_of(l); if (s != "") sec = s }
      infence_before = fence
      if (l ~ /^```/) fence = !fence
      # NOTE: inside END, bare `print` means `print $0` (the LAST input line) — every
      # structural emit below must print the loop variable `l` explicitly.
      if (sec == "ns" && i >= dstart && i <= dend) {          # the finished-step window:
        if (i == dstart) emit_ns_payload()                    # splice replacement in place
        continue
      }
      if (sec == "up" && have_promo && i >= pstart && i <= pend) continue      # moved out
      if (sec == "done" && l ~ /^[[:space:]]*-[[:space:]]/ && !infence_before) {
        if (!done_inserted) { print entry; done_inserted = 1 }
        done_bullets++
        if (done_bullets >= 10) continue     # new entry + 9 kept = cap 10
        print l; continue
      }
      # transition emit: when leaving an empty Done section, the new entry must not be lost.
      if (l ~ /^## / && !infence_before && prevsec == "done" && !done_inserted) { print entry; done_inserted = 1 }
      print l
      prevsec = sec
    }
    if (sec == "done" && !done_inserted) print entry      # Done was empty; entry goes last
  }
  function emit_ns_payload(   j) {
    if (ns_done) return
    ns_done = 1
    if (have_promo) { for (j = pstart; j <= pend; j++) print lines[j] }
    else            { print "_(sprint complete — plan the next sprint in a PM tab)_" }
  }
' "$QUEUE" > "$TMP"

AWK_RC=$?
if [ "$AWK_RC" -eq 9 ]; then
  echo "REFUSED: Next Step is malformed (fence with no step heading) — queue NOT modified. Fix it by hand or route to PM."; exit 1
elif [ "$AWK_RC" -ne 0 ]; then
  echo "REFUSED: queue rewrite failed (awk exit $AWK_RC) — queue NOT modified."; exit 1
fi

# Self-check: the rewritten queue must satisfy the same structural contract the driver parses.
if ! LINT_OUT="$(bash "$SCRIPT_DIR/muster-queue-lint.sh" "$TMP" 2>&1)"; then
  echo "REFUSED: rewrite failed queue-lint — queue NOT modified. Lint output:"
  printf '%s\n' "$LINT_OUT"
  exit 1
fi

mv "$TMP" "$QUEUE"
trap 'rm -f "$PROMOTED_LABEL_FILE"' EXIT
PROMOTED="$(cat "$PROMOTED_LABEL_FILE" 2>/dev/null || true)"
echo "OK: step moved to Done ($ENTRY)"
if [ -n "$PROMOTED" ]; then echo "OK: promoted to Next Step — $PROMOTED"
else echo "OK: no Upcoming steps left — Next Step marked sprint complete"; fi
exit 0
