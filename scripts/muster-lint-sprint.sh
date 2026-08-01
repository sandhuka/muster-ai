#!/usr/bin/env bash
# muster-lint-sprint.sh — lint: sprint-board well-formedness + queue<->board coherence (family: lint — reports OK/FAIL, never mutates).
#
# The board (current-sprint.md) is what cascades into agent-context files and the queue; a
# malformed entry rots everything downstream. Two live board conventions exist and both are
# valid — this lint checks WHAT IT FINDS and skips what is absent (an empty seeded board passes;
# planning fills it):
#   checkbox entries (`- [ ] **Task** — Priority: …, Effort: …`, the Task Definition Standard):
#     FAIL  Priority not in HIGH/MED/LOW · Effort not in S/M/L/XL · Platform (when present) not
#           in ios/android/web/backend/desktop/cli/cross-platform/n-a
#     FAIL  a task with no Deliverable or no Acceptance sub-bullet
#     WARN  capacity guidelines as counts: an agent section with >5 open tasks or >2 open HIGH
#   wave-table rows (`| N | Role | Deliverable | … |`, the autonomous-sprint convention):
#     FAIL  a row with an empty Role or Deliverable cell
#     WARN  an unrecognizable Role cell
#   coherence (when the queue file exists — the only check spanning the whole plan):
#     WARN  a queued specialist role with no presence on the board
#     WARN  a board role with open work that is never queued
#
# Usage: muster-lint-sprint.sh [board-file] [queue-file]
#   defaults: knowledge-base/current-sprint.md · knowledge-base/orchestration-queue.md
# Exit: 0 clean (warns allowed) · 1 FAIL found · 3 usage/missing board.

B="${1:-knowledge-base/current-sprint.md}"
Q="${2:-knowledge-base/orchestration-queue.md}"
[ -f "$B" ] || { echo "muster-lint-sprint: board not found: $B"; echo "usage: muster-lint-sprint.sh [board-file] [queue-file]"; exit 3; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

awk -v rolesfile="$TMP/board_roles" '
  function norm_role(s) {
    gsub(/\*/, "", s); gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); s = tolower(s)
    gsub(/\//, "-", s)                                   # UI/UX -> ui-ux
    return s
  }
  function flush_task() {
    if (!intask) return
    missing = ""
    if (!t_deliv)  missing = missing "Deliverable, "
    if (!t_accept) missing = missing "Acceptance, "
    if (missing != "") {
      sub(/, $/, "", missing)
      print "FAIL: task \"" tname "\" (" section ") — missing sub-bullet(s): " missing
      fails++
    }
    intask = 0
  }
  /^### / { flush_task(); section = $0; sub(/^### +/, "", section); open[section] += 0 }
  /^- \[[ x]\] \*\*/ {
    flush_task()
    intask = 1; t_deliv = 0; t_accept = 0
    tname = $0; sub(/^- \[[ x]\] \*\*/, "", tname); sub(/\*\*.*$/, "", tname)
    isopen = ($0 ~ /^- \[ \]/)
    if (isopen) { open[section]++ ; seen_open_section[section] = 1 }
    if ($0 !~ /Priority: (HIGH|MED|LOW)/)  { print "FAIL: task \"" tname "\" — Priority missing or not HIGH/MED/LOW"; fails++ }
    else if (isopen && $0 ~ /Priority: HIGH/) high[section]++
    if ($0 !~ /Effort: (S|M|L|XL)([, ]|$)/) { print "FAIL: task \"" tname "\" — Effort missing or not S/M/L/XL"; fails++ }
    if ($0 ~ /Platform:/ && $0 !~ /Platform: (ios|android|web|backend|desktop|cli|cross-platform|n-a)([, ]|$)/) {
      print "FAIL: task \"" tname "\" — Platform not a valid value"; fails++
    }
    next
  }
  intask && /^[[:space:]]+- / {
    low = tolower($0)
    if (low ~ /\*\*deliverable\*\*|deliverable:/)  t_deliv = 1
    if (low ~ /acceptance/)                        t_accept = 1
  }
  /^\| [0-9]+[a-z]? \|/ {
    n = split($0, c, "|")
    role = norm_role(c[3]); deliv = c[4]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", deliv)
    if (role == "")  { print "FAIL: wave-table row " c[2] " — empty Role cell"; fails++ }
    if (deliv == "") { print "FAIL: wave-table row " c[2] " — empty Deliverable cell"; fails++ }
    if (role ~ /founder|halt/) next
    if (role !~ /^(pm|developer|ui-ux|qa|content|marketing|legal|research)$/) {
      print "WARN: wave-table row " c[2] " — unrecognized Role cell \"" role "\""; warns++
    } else print role >> rolesfile
    next
  }
  END {
    flush_task()
    for (s in open) {
      if (open[s] > 5)  { print "WARN: " s " has " open[s] " open tasks (capacity guideline: 3-5 per agent)"; warns++ }
      if (high[s] > 2)  { print "WARN: " s " has " high[s] " open HIGH tasks (guideline: max 2 simultaneous)"; warns++ }
      if (seen_open_section[s]) print norm_role(s) >> rolesfile
    }
    print fails+0 > "'"$TMP"'/fails"; print warns+0 > "'"$TMP"'/warns"
  }
' "$B"

fails="$(cat "$TMP/fails" 2>/dev/null || echo 0)"
warns="$(cat "$TMP/warns" 2>/dev/null || echo 0)"

# ---- coherence: the queue and the board must agree on who has work ----
if [ -f "$Q" ]; then
  grep '^Role:' "$Q" 2>/dev/null | sed 's/^Role:[[:space:]]*//; s/[[:space:]]*$//' \
    | grep -vE '^(halt|pm)$' | sort -u > "$TMP/queue_roles" || true
  sort -u "$TMP/board_roles" 2>/dev/null > "$TMP/board_roles_u" || : > "$TMP/board_roles_u"
  # board_roles collects agent-name sections too (e.g. "developer"); keep only real roles
  grep -E '^(developer|ui-ux|qa|content|marketing|legal|research)$' "$TMP/board_roles_u" > "$TMP/board_real" || : > "$TMP/board_real"
  while IFS= read -r r; do
    grep -qx "$r" "$TMP/board_real" || { echo "WARN: coherence — queued role '$r' has no open work on the board"; warns=$((warns+1)); }
  done < "$TMP/queue_roles"
  while IFS= read -r r; do
    grep -qx "$r" "$TMP/queue_roles" || { echo "WARN: coherence — board role '$r' has open work but is never queued"; warns=$((warns+1)); }
  done < "$TMP/board_real"
fi

echo "-----------------------------------------------"
if [ "$fails" -gt 0 ]; then echo "RESULT: $fails FAIL, $warns WARN — board entries are malformed"; exit 1
elif [ "$warns" -gt 0 ]; then echo "OK: board passes the floor ($warns WARN for PM judgment)"; exit 0
else echo "OK: board well-formed and coherent with the queue"; exit 0
fi
