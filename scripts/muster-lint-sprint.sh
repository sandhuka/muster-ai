#!/usr/bin/env bash
# muster-lint-sprint.sh — lint: sprint wave-board well-formedness + queue<->board coherence (family: lint — reports OK/FAIL, never mutates).
#
# THE board format (founder-ruled): the wave-table — `| Step | Role | Deliverable | Verification |`
# rows under phase headings. One convention, taught once (sprint-planning.md → Task Definition
# Standard), linted here. Full task specs live in agent-context files (Rule 5); the queue owns
# sequence and prompts; the board is the compact index that must agree with both.
#   FAIL  a row with an empty Role or Deliverable cell
#   FAIL  per-step coherence: a step number present in BOTH board and queue whose roles differ
#         (row 4 says Developer, queue Step 4 binds qa — the plan disagrees with itself)
#   WARN  an unrecognizable Role cell (founder/halt rows are legitimate and skipped)
#   WARN  capacity guideline as a count: >5 rows for one role (3-5 open tasks per agent)
#   WARN  role-set coherence: a queued specialist role with no board row, or a board role never
#         queued (completed steps legitimately leave the queue — only WHOLE-role absence warns)
# An empty board (no rows yet) passes — planning fills it.
#
# Usage: muster-lint-sprint.sh [board-file] [queue-file]
#   defaults: knowledge-base/current-sprint.md · knowledge-base/orchestration-queue.md
# Exit: 0 clean (warns allowed) · 1 FAIL found · 3 usage/missing board.

B="${1:-knowledge-base/current-sprint.md}"
Q="${2:-knowledge-base/orchestration-queue.md}"
[ -f "$B" ] || { echo "muster-lint-sprint: board not found: $B"; echo "usage: muster-lint-sprint.sh [board-file] [queue-file]"; exit 3; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# ---- board pass: validate rows, collect step->role map + per-role counts ----
awk -v mapfile="$TMP/board_map" '
  function norm_role(s) {
    gsub(/\*/, "", s); gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); s = tolower(s)
    gsub(/\//, "-", s)                                   # UI/UX -> ui-ux
    return s
  }
  /^\|[[:space:]]*[0-9]+[a-z]?[[:space:]]*\|/ {
    split($0, c, "|")
    step = c[2]; gsub(/[[:space:]]/, "", step)
    role = norm_role(c[3]); deliv = c[4]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", deliv)
    if (role == "")  { print "FAIL: wave-table row " step " — empty Role cell"; fails++ }
    if (deliv == "") { print "FAIL: wave-table row " step " — empty Deliverable cell"; fails++ }
    if (role ~ /founder|halt/) next
    if (role !~ /^(pm|developer|ui-ux|qa|content|marketing|legal|research)$/) {
      print "WARN: wave-table row " step " — unrecognized Role cell \"" role "\""; warns++
      next
    }
    count[role]++
    print step " " role >> mapfile
  }
  END {
    for (r in count) if (count[r] > 5) {
      print "WARN: role " r " has " count[r] " board rows (capacity guideline: 3-5 open tasks per agent)"; warns++
    }
    print fails+0 > "'"$TMP"'/fails"; print warns+0 > "'"$TMP"'/warns"
  }
' "$B"

fails="$(cat "$TMP/fails" 2>/dev/null || echo 0)"
warns="$(cat "$TMP/warns" 2>/dev/null || echo 0)"

# ---- coherence: the board index must agree with the queue ----
if [ -f "$Q" ]; then
  # queue pass: step number (from `### Step N` headings) -> Role: of the fence that follows
  awk '
    /^### / { if (match($0, /Step [0-9]+[a-z]?/)) { step = substr($0, RSTART+5, RLENGTH-5) } else step = "" }
    /^```/  { fence = !fence; next }
    fence && /^Role:/ && step != "" {
      role = $0; sub(/^Role:[[:space:]]*/, "", role); sub(/[[:space:]]+$/, "", role)
      print step " " role; step = ""
    }
  ' "$Q" > "$TMP/queue_map"

  # per-step: same step number in both -> roles must match (halt/founder rows already excluded)
  while read -r step brole; do
    qrole="$(awk -v s="$step" '$1 == s {print $2; exit}' "$TMP/queue_map")"
    if [ -n "$qrole" ] && [ "$qrole" != "halt" ] && [ "$qrole" != "$brole" ]; then
      echo "FAIL: coherence — board row $step says '$brole' but queue Step $step binds '$qrole'"
      fails=$((fails+1))
    fi
  done < "$TMP/board_map" 2>/dev/null

  # role-set: whole-role absences (completed steps leave the queue; only a role with NO queue
  # presence at all, or a queued role with NO board row, is a planning slip)
  awk '{print $2}' "$TMP/queue_map" 2>/dev/null | grep -vE '^(halt|pm)$' | sort -u > "$TMP/qroles" || true
  awk '{print $2}' "$TMP/board_map" 2>/dev/null | grep -vE '^pm$' | sort -u > "$TMP/broles" || true
  while IFS= read -r r; do
    grep -qx "$r" "$TMP/broles" || { echo "WARN: coherence — queued role '$r' has no board row"; warns=$((warns+1)); }
  done < "$TMP/qroles"
  while IFS= read -r r; do
    grep -qx "$r" "$TMP/qroles" || { echo "WARN: coherence — board role '$r' is never queued"; warns=$((warns+1)); }
  done < "$TMP/broles"
fi

echo "-----------------------------------------------"
if [ "$fails" -gt 0 ]; then echo "RESULT: $fails FAIL, $warns WARN — the board disagrees with itself or the queue"; exit 1
elif [ "$warns" -gt 0 ]; then echo "OK: board passes the floor ($warns WARN for PM judgment)"; exit 0
else echo "OK: wave-board well-formed and coherent with the queue"; exit 0
fi
