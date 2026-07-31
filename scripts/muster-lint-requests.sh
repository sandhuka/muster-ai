#!/usr/bin/env bash
# muster-lint-requests.sh — lint: agent-requests closure (family: lint — reports OK/FAIL, never mutates).
# Deterministic closure check for agent-requests.md. Run at every PM bind
# (warn) and as a HARD sprint-closeout gate (PM pastes the green result into closeout). The ledger
# is only a useful "what's actually open" signal if closed work leaves Active; this catches the four
# ways it failed to in autonomous mode (Arogh Sprint-7 F-S7-1, where Active reached 1,382 lines
# carrying ~50 already-accepted handoffs and buried the one genuinely-open request):
#
#   (i)  reviewed-but-stale — a handoff whose reviewer checkboxes are ALL ticked but whose top-level
#        `**Status:**` never flipped to `done`. The "done -> Resolved" sweep keys on Status, so these
#        accepted entries are invisible to it and rot in Active.
#   (ii) done-in-Active     — a `Status: done` entry still sitting in Active (the sweep never ran).
#   (iii) duplicate IDs     — the same HO-/REQ-NNN filed twice (free-form Edit on the shared ledger
#        corrupting siblings — recurrence of F-S6-4).
#   (iv) Active over budget — Active has no size cap today (unlike current-sprint / decision-log per
#        Rule 14); a missed sweep should trip a budget check, not balloon to four figures.
#
# Usage:  bash muster-lint-requests.sh [REQUESTS] [BUDGET]
#         defaults: knowledge-base/agent-requests.md   300 (Active-sections line budget)
# Exit:   0 = clean (incl. an empty/fresh ledger), 1 = one or more defects (each printed), 2 = file/usage error.
set -euo pipefail

REQUESTS="${1:-knowledge-base/agent-requests.md}"
BUDGET="${2:-300}"
[ -f "$REQUESTS" ] || { echo "requests-lint: file not found: $REQUESTS" >&2; exit 2; }

# One awk pass. Per-entry state is flushed (evaluated) at the next `### ` heading or section change.
# The leading `<!-- … -->` TEMPLATES block is skipped so its example entries never false-positive.
awk -v budget="$BUDGET" '
  function fail(msg){ print "FAIL: " msg; fails++ }
  function flush(){
    if (entry_id=="") return
    if (entry_status=="done")
      fail("entry " entry_id " has Status: done but sits in Active — move it to Resolved (line " entry_line ")")
    else if (cur_is_ho && rev_total>0 && rev_unchecked==0)
      fail("handoff " entry_id " has all reviewers ticked but Status is \"" entry_status "\" (not done) — flip Status in the same edit (line " entry_line ")")
    entry_id=""; entry_status=""; rev_total=0; rev_unchecked=0
  }

  # --- skip the HTML comment / TEMPLATES block (its example ### entries are not real) ---
  /<!--/ { in_comment=1 }
  in_comment { if (/-->/) in_comment=0; next }

  # --- section transitions (flush the open entry at every boundary) ---
  /^## Active Requests/ { flush(); section="active"; cur_is_ho=0; next }
  /^## Active Handoffs/ { flush(); section="active"; cur_is_ho=1; next }
  /^## Resolved/        { flush(); section="resolved"; next }
  /^## /                { flush(); section="other"; next }

  # --- Active-section line budget (everything between the heading and the next `## `) ---
  section=="active" { active_total++ }

  # --- duplicate-ID detection across ALL `### ` entry headings (Resolved is one-liner bullets) ---
  /^### / {
    id=""
    if (match($0, /(HO|REQ)-[0-9]+/)) id=substr($0, RSTART, RLENGTH)
    if (id!="") { idcount[id]++; if (idcount[id]==2) fail("duplicate entry ID " id " (filed more than once)") }
    if (section=="active") { flush(); entry_line=NR; entry_id=(id!="" ? id : ("entry@" NR)) }
    next
  }

  # --- inside an Active entry: capture Status + reviewer checkbox state ---
  # (v) status-enum check: the raw token must be one of the documented values. Without this,
  # `Status: Done` truncates to "" at the capital D and `Status: in review` becomes "in" — both
  # sail past every check below while looking closed to a human (the truly silent hole: a
  # non-canonical finished-spelling with unticked reviewers reported the file as clean).
  section=="active" && /^\*\*Status:\*\*/ {
    raw=$0; sub(/^\*\*Status:\*\*[[:space:]]*/,"",raw); sub(/[[:space:]]+$/,"",raw)
    if (raw !~ /^\[/) {                                  # skip template placeholders like [open | done]
      valid = cur_is_ho ? "^(open|in-review|needs-revision|done)$" : "^(open|done)$"
      if (raw !~ valid)
        fail("entry " (entry_id!="" ? entry_id : "@" NR) " has invalid Status \"" raw "\" (line " NR ") — valid: " (cur_is_ho ? "open|in-review|needs-revision|done" : "open|done"))
    }
    s=$0; sub(/^\*\*Status:\*\*[[:space:]]*/,"",s); sub(/[^a-z-].*$/,"",s); entry_status=s; next
  }
  section=="active" && /^-[[:space:]]*\[[[:space:]]\]/ { rev_unchecked++; rev_total++; next }
  section=="active" && /^-[[:space:]]*\[[xX]\]/        { rev_total++; next }

  END {
    flush()
    if (active_total > budget)
      fail("Active sections total " active_total " lines (budget " budget ") — closed handoffs are accumulating; sweep done/reviewed entries to Resolved")
    if (fails>0) { print fails " defect(s) — agent-requests.md needs reconciliation"; exit 1 }
    print "OK: agent-requests clean — no reviewed-but-open, no done-in-Active, no duplicate IDs; Active " active_total "/" budget " lines"
  }
' "$REQUESTS"
