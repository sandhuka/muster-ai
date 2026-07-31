#!/usr/bin/env bash
# test-lint-kb-budgets.sh — fixture gate for muster-lint-kb-budgets.sh (Rule 14 runtime half).
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/muster-kbb-test.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT

PROJ="$SBX/proj"
mkdir -p "$PROJ/muster/scripts" "$PROJ/muster/team/pm" "$PROJ/knowledge-base" "$PROJ/.claude/agents"
cp "$SRC/scripts/muster-lint-kb-budgets.sh" "$PROJ/muster/scripts/"
touch "$PROJ/muster/system-guide.md"
LINT="$PROJ/muster/scripts/muster-lint-kb-budgets.sh"

n=0; fails=0
t(){ # $1=name $2=want-exit $3=grep-must
  local name="$1" wrc="$2" want="$3"
  n=$((n+1))
  local out rc; out="$(cd "${T_CWD:-$PROJ}" && bash "$LINT" 2>&1)"; rc=$?
  if [ "$rc" = "$wrc" ] && printf '%s\n' "$out" | grep -qF -- "$want"; then echo "PASS: $name"
  else fails=$((fails+1)); echo "FAIL: $name (rc=$rc want=$wrc)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fi
}
gen(){ local f="$1" lines="$2"; : > "$f"; local i=0; while [ $i -lt "$lines" ]; do echo "line $i" >> "$f"; i=$((i+1)); done; }

# thin project, files mostly missing -> OK (missing = 0 lines, tolerated)
gen "$PROJ/CLAUDE.md" 30
gen "$PROJ/knowledge-base/current-sprint.md" 20
t thin-ok 0 "OK: knowledge-base within Rule 14 budgets"
t breakdown-shown 0 "knowledge-base/current-sprint.md"

# over budget -> FAIL with archive hints
gen "$PROJ/knowledge-base/decision-log.md" 700
t over-budget-fails 1 "FAIL: bootstrap reads exceed Rule 14's 600-line budget"
t archive-hint 1 "move pre-current-sprint entries to decision-log-archive.md"
gen "$PROJ/knowledge-base/decision-log.md" 40

# two sprint headings -> FAIL
cat > "$PROJ/knowledge-base/current-sprint.md" <<'EOF'
# Sprint 3 — Active
tasks
## Sprint 2 — Done
old tasks
EOF
t multi-sprint-fails 1 "FAIL: current-sprint.md holds 2 sprint headings"
gen "$PROJ/knowledge-base/current-sprint.md" 20

# soft ceiling -> WARN, exit 0
gen "$PROJ/knowledge-base/founder-notices.md" 25
t soft-ceiling-warns 0 "WARN: knowledge-base/founder-notices.md at 25 lines (soft ceiling 20)"
rm -f "$PROJ/knowledge-base/founder-notices.md"

# cwd independence
mkdir -p "$PROJ/src/deep"
T_CWD="$PROJ/src/deep" t cwd-independent 0 "OK: knowledge-base within Rule 14 budgets"

echo "----"
if [ "$fails" -eq 0 ]; then echo "RESULT: $n/$n passed"; exit 0
else echo "RESULT: $((n-fails))/$n passed — $fails FAILED"; exit 1; fi
