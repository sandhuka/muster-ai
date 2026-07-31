#!/usr/bin/env bash
# muster-lint-entry.sh — lint: handoff/request entry well-formedness (family: lint — reports, never mutates).
#
# muster-requests-lint.sh checks the board's CLOSURE lifecycle; nothing checked an entry's BODY.
# The silent failure this closes: a handoff whose `Deliverable:` path doesn't exist on disk is
# invisible to its producer and breaks the REVIEWER's next session instead. Also asserts the
# canonical field sets (system-guide.md → Agent Communication Protocol) per entry type.
#
# Per Active entry (Resolved one-liners are exempt):
#   FAIL — request missing Type/From/To/Status/Request, or handoff missing
#          Type/Producer/Deliverable/Status/Reviewers
#   FAIL — a Deliverable path (backticked or bare *.md/*.* token) that resolves nowhere
#          (as-is, or under knowledge-base/)
#   WARN — a Deliverable with no extractable path at all (prose deliverable — unverifiable)
# Bracketed/angled placeholder tokens are skipped (template text never trips).
#
# Usage: muster-lint-entry.sh [agent-requests.md]   (default knowledge-base/agent-requests.md)
# Exit: 0 clean (WARNs allowed) · 1 FAIL findings · 3 wiring error
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ "$(basename "$MUSTER_ROOT")" != "muster" ]; then
  echo "muster-lint-entry: not inside a project (muster tree not at <project>/muster/)" >&2; exit 3
fi
cd "$MUSTER_ROOT/.."

REQ="${1:-knowledge-base/agent-requests.md}"
[ -f "$REQ" ] || { echo "OK: no board at $REQ — nothing to lint"; exit 0; }

findings="$(awk '
  function flushentry(   missing) {
    if (ehead == "") return
    entries++
    if (etype == "request") {
      missing = ""
      if (!has["From"])    missing = missing " From"
      if (!has["To"])      missing = missing " To"
      if (!has["Status"])  missing = missing " Status"
      if (!has["Request"]) missing = missing " Request"
      if (missing != "") printf "FAIL\t%s\trequest missing field(s):%s\n", ehead, missing
    } else if (etype == "handoff") {
      missing = ""
      if (!has["Producer"])    missing = missing " Producer"
      if (!has["Deliverable"]) missing = missing " Deliverable"
      if (!has["Status"])      missing = missing " Status"
      if (!has["Reviewers"])   missing = missing " Reviewers"
      if (missing != "") printf "FAIL\t%s\thandoff missing field(s):%s\n", ehead, missing
    } else {
      printf "FAIL\t%s\tno **Type:** field (request|handoff)\n", ehead
    }
    ehead = ""; etype = ""
    delete has
  }
  incomment { if ($0 ~ /-->/) incomment = 0; next }
  /<!--/ && !/-->/ { incomment = 1; next }
  /<!--.*-->/ { next }
  /^## / {
    flushentry()
    insec = ($0 ~ /^## Active/)
    next
  }
  insec && /^###[[:space:]]/ { flushentry(); ehead = $0; sub(/^###[[:space:]]+/, "", ehead); if (length(ehead) > 50) ehead = substr(ehead, 1, 47) "..."; next }
  ehead != "" {
    # field colons live INSIDE the bold on this board (`**Type:** handoff`) — prefix-match
    if ($0 ~ /\*\*Type[:*]/)        { t = tolower($0); etype = (t ~ /request/) ? "request" : (t ~ /handoff/) ? "handoff" : "" }
    if ($0 ~ /\*\*From[:*]/)         has["From"] = 1
    if ($0 ~ /\*\*To[:*]/)           has["To"] = 1
    if ($0 ~ /\*\*Status[:*]/)       has["Status"] = 1
    if ($0 ~ /\*\*Request[:*]/)      has["Request"] = 1
    if ($0 ~ /\*\*Producer[:*]/)     has["Producer"] = 1
    if ($0 ~ /\*\*Reviewers[:*]/)    has["Reviewers"] = 1
    if ($0 ~ /\*\*Deliverable[:*]/) { has["Deliverable"] = 1; printf "DELIV\t%s\t%s\n", ehead, $0 }
  }
  END { flushentry(); printf "COUNT\t%d\t-\n", entries+0 }
' "$REQ")"

fails=0; warns=0; entries=0
while IFS=$'\t' read -r kind head payload; do
  [ -z "$kind" ] && continue
  case "$kind" in
    COUNT) entries="$head" ;;
    FAIL)  echo "FAIL: [$head] $payload"; fails=$((fails+1)) ;;
    DELIV)
      # Extract candidate paths: backticked tokens first, else bare file-ish tokens.
      paths="$(printf '%s' "$payload" | grep -oE '`[^`]+`' | tr -d '\`' || true)"
      [ -z "$paths" ] && paths="$(printf '%s' "$payload" | sed 's/^.*\*\*Deliverable\*\*[:[:space:]]*//' | grep -oE '[A-Za-z0-9_./-]+\.[A-Za-z0-9]+' || true)"
      if [ -z "$paths" ]; then
        echo "WARN: [$head] Deliverable has no extractable path — reviewer cannot verify it exists"; warns=$((warns+1))
        continue
      fi
      while read -r p; do
        [ -z "$p" ] && continue
        case "$p" in *'['*|*'<'*|*'{'*) continue ;; esac   # placeholder tokens
        if [ ! -e "$p" ] && [ ! -e "knowledge-base/$p" ]; then
          echo "FAIL: [$head] Deliverable path not found on disk: $p — phantom deliverables break the reviewer's session"
          fails=$((fails+1))
        fi
      done <<< "$paths"
      ;;
  esac
done <<< "$findings"

echo "scanned $entries Active entr(ies); $fails FAIL, $warns WARN"
[ "$fails" -eq 0 ] && { echo "OK: entry bodies well-formed"; exit 0; }
exit 1
