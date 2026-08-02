#!/usr/bin/env bash
# muster-lint-decisions.sh — lint: Rule 11 decision reconciliation (family: lint — reports, never mutates).
#
# The framework's named recurring failure is cascade lag: a decision names affected agents in
# Impact, PM updates SOME of their context files, feels done, and the rest drift. Rule 11 says
# Impact and Touched must reconcile; nothing checked it. This does.
#
# Per decision entry:
#   FAIL — a required field is missing (Decision/Rationale/Impact/Touched)
#   FAIL — Impact names a role (or "All agents") whose agent-context update is recorded NOWHERE
#          in the entry and the role is not a stub (.populated.agents.<role> == null)
#   WARN — a Touched path that does not resolve on disk (as-is or under knowledge-base/)
# Calibrations from live corpora:
#   - TWO entry formats exist in the field: the template's `### DEC-ID — Title (DATE)` and a
#     dated-bold form `**DATE — TITLE**` with bulleted fields. Both parse.
#   - Role coverage scans the WHOLE entry, not just the Touched line — a real project recorded
#     late agent-context fixes in a hardening note within the entry; Touched-only would
#     false-flag a genuinely reconciled decision.
#   - Role extraction from Impact matches capitalized role tokens only (Content-the-role vs
#     "content"-the-noun) plus "All agents".
#
# Usage: muster-lint-decisions.sh [decision-log]   (default knowledge-base/decision-log.md)
# Exit: 0 clean (WARNs allowed) · 1 FAIL findings · 3 wiring error
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ "$(basename "$MUSTER_ROOT")" != "muster" ]; then
  echo "muster-lint-decisions: not inside a project (muster tree not at <project>/muster/)" >&2; exit 3
fi
cd "$MUSTER_ROOT/.."

LOG="${1:-knowledge-base/decision-log.md}"
[ -f "$LOG" ] || { echo "OK: no decision log at $LOG — nothing to lint"; exit 0; }

source "$SCRIPT_DIR/muster-read-populated.sh"

# Stubs: unpopulated agents are exempt from coverage (their cascade accrues, applied at JIT).
STUBS=""
for r in pm developer ui-ux qa content marketing legal research; do
  [ "$(pop_key "$r" agents)" = "null" ] && STUBS="$STUBS $r"
done

# Emit per-entry TSV findings from one awk pass. Entry starts at `### ` or `**<date> — ` line
# (outside fences/comments); fields and role mentions accumulate until the next entry.
findings="$(awk -v stubs="$STUBS" '
  function flushentry(   i, role, n, roles, miss) {
    if (ehead == "") return
    if (!has["Decision"] || !has["Rationale"] || !has["Impact"] || !has["Touched"]) {
      missing = ""
      if (!has["Decision"])  missing = missing " Decision"
      if (!has["Rationale"]) missing = missing " Rationale"
      if (!has["Impact"])    missing = missing " Impact"
      if (!has["Touched"])   missing = missing " Touched"
      printf "FAIL\t%s\tmissing field(s):%s\n", ehead, missing
    }
    n = 0
    if (impact ~ /[Aa]ll agents/) {
      n = split("pm developer ui-ux qa content marketing legal research", roles, " ")
    } else {
      if (impact ~ /PM/)                       roles[++n] = "pm"
      if (impact ~ /Developer/)                roles[++n] = "developer"
      if (impact ~ /UI\/UX|UI-UX/)             roles[++n] = "ui-ux"
      if (impact ~ /QA/)                       roles[++n] = "qa"
      if (impact ~ /Content/)                  roles[++n] = "content"
      if (impact ~ /Marketing/)                roles[++n] = "marketing"
      if (impact ~ /Legal/)                    roles[++n] = "legal"
      if (impact ~ /Research/)                 roles[++n] = "research"
    }
    for (i = 1; i <= n; i++) {
      role = roles[i]
      if (index(stubs, " " role) > 0 || stubs ~ "(^| )" role "( |$)") continue
      if (body ~ ("agent-context/" role)) continue
      # bare "<role>.md" is unambiguous coverage too — only agent-context files carry role
      # names (a live entry recorded a late fix as "incl. legal.md"; require-the-full-path
      # false-flagged a genuinely reconciled decision)
      if (body ~ ("[^a-z-]" role "\\.md")) continue
      printf "FAIL\t%s\tImpact names %s but no agent-context/%s update is recorded in the entry (Rule 11: reconcile or mark stub)\n", ehead, role, role
    }
    ehead = ""; body = ""; impact = ""
    delete has
  }
  /^[[:space:]]*```/ { infence = !infence; next }
  infence { next }
  incomment { if ($0 ~ /-->/) incomment = 0; next }
  /<!--/ && !/-->/ { incomment = 1; next }
  /<!--.*-->/ { next }
  /^### / || /^\*\*20[0-9][0-9]-[0-9][0-9]-[0-9][0-9][[:space:]]*[—–-]/ {
    flushentry()
    entries++
    ehead = $0
    sub(/^###[[:space:]]+/, "", ehead); gsub(/\*/, "", ehead)
    if (length(ehead) > 60) ehead = substr(ehead, 1, 57) "..."
    next
  }
  ehead != "" {
    body = body "\n" $0
    if ($0 ~ /\*\*Decision\*\*/)  has["Decision"] = 1
    if ($0 ~ /\*\*Rationale\*\*/) has["Rationale"] = 1
    if ($0 ~ /\*\*Impact\*\*/)  { has["Impact"] = 1;  line = $0; sub(/^.*\*\*Impact\*\*[:[:space:]]*/, "", line);  impact = impact " " line }
    if ($0 ~ /\*\*Touched\*\*/)   has["Touched"] = 1
  }
  END { flushentry(); printf "COUNT\t%d\t-\n", entries+0 }
' "$LOG")"

fails=0; warns=0; entries=0
if [ -n "$findings" ]; then
  while IFS=$'\t' read -r kind head why; do
    [ -z "$kind" ] && continue
    if [ "$kind" = "COUNT" ]; then entries="$head"; continue; fi
    echo "$kind: [$head] $why"
    [ "$kind" = "FAIL" ] && fails=$((fails+1)) || warns=$((warns+1))
  done <<< "$findings"
fi

# Touched-path resolution (WARN tier): backticked/bare *.md tokens on Touched lines should
# exist as-is or under knowledge-base/. Entries can outlive renames, so this never blocks.
while read -r p; do
  [ -z "$p" ] && continue
  [ -f "$p" ] || [ -f "knowledge-base/$p" ] || { echo "WARN: Touched path not found on disk: $p (renamed or archived?)"; warns=$((warns+1)); }
done < <(grep '\*\*Touched\*\*' "$LOG" 2>/dev/null | grep -oE '[A-Za-z0-9_./-]+\.md' | sort -u)

echo "scanned ${entries:-0} decision entr(ies); $fails FAIL, $warns WARN"
[ "$fails" -eq 0 ] && { echo "OK: decision reconciliation clean"; exit 0; }
exit 1
