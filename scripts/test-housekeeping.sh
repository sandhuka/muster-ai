#!/usr/bin/env bash
# test-housekeeping.sh — fixture gate for muster-housekeeping.sh (session-start hygiene).
# Pins: stale bind files (>1 day) pruned while fresh ones survive, oversized bind/boot logs
# (>500 lines) rotate to a dated archive while small ones stay, and the no-.claude no-op
# guarantee (safe in non-muster projects). Last uncovered behavior-bearing fleet script.
set -uo pipefail
MUSTER="$(cd "$(dirname "$0")/.." && pwd)"
SB="$(mktemp -d "${TMPDIR:-/tmp}/muster-hk-test.XXXXXX")"
trap 'rm -rf "$SB"' EXIT
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }
no(){ echo "FAIL: $1"; fail=$((fail+1)); }

mkdir -p "$SB/proj/.claude" "$SB/proj/knowledge-base"
cd "$SB/proj"

# stale (2 days old) vs fresh bind file
touch .claude/.muster-bound-role.fresh
touch .claude/.muster-bound-role.stale
if touch -d '2 days ago' .claude/.muster-bound-role.stale 2>/dev/null; then :
else touch -t "$(date -v-2d +%Y%m%d%H%M 2>/dev/null)" .claude/.muster-bound-role.stale; fi   # BSD fallback

# oversized bind log (501 lines) + small boot log
seq 1 501 | sed 's/^/line /' > knowledge-base/.muster-bind-log
printf 'one\ntwo\n' > knowledge-base/.muster-boot-log

bash "$MUSTER/scripts/muster-housekeeping.sh"; rc=$?
[ "$rc" -eq 0 ] && ok "exits 0" || no "exit rc=$rc"
[ ! -f .claude/.muster-bound-role.stale ] && ok "stale bind file pruned" || no "stale bind file survived"
[ -f .claude/.muster-bound-role.fresh ] && ok "fresh bind file survives" || no "fresh bind file deleted"
[ ! -f knowledge-base/.muster-bind-log ] && ls knowledge-base/.muster-bind-log.archive.* >/dev/null 2>&1 \
  && ok "oversized bind log rotated to archive" || no "bind log not rotated"
if [ -f knowledge-base/.muster-boot-log ] && [ "$(ls knowledge-base/.muster-boot-log.archive.* 2>/dev/null | wc -l | tr -d ' ')" = "0" ]; then
  ok "small boot log untouched"
else no "small boot log rotated/lost"; fi

# no-.claude no-op (non-muster project safety)
mkdir -p "$SB/bare"; cd "$SB/bare"
bash "$MUSTER/scripts/muster-housekeeping.sh"; rc=$?
[ "$rc" -eq 0 ] && ok "no-ops cleanly without .claude/" || no "failed in bare dir (rc=$rc)"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
exit 0
