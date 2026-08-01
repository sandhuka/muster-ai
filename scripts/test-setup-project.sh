#!/usr/bin/env bash
# test-setup-project.sh — smoke fixture for setup-project.sh (the day-one adopter path).
# Seeds a REAL project from this repo's HEAD (local file:// clone — offline, no network) and
# then runs the shipped gates against the pristine seed: boot must route, the plan gate and
# board/requests lints must be clean on an untouched project. This pins the seed<->gate
# contract: any template change or lint tightening that would break a new adopter's first
# session goes red HERE, not in a stranger's first impression.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SB="$(mktemp -d "${TMPDIR:-/tmp}/muster-setup-test.XXXXXX")"
trap 'rm -rf "$SB"' EXIT
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }
no(){ echo "FAIL: $1"; fail=$((fail+1)); }

BRANCH="$(git -C "$SRC" rev-parse --abbrev-ref HEAD)"
# local file:// submodule clones need explicit allowance on modern git; env-injected config
# reaches every git child the setup script spawns. Git identity for the initial commit.
# HOME is overridden per case so the user-level-statusline branch is DETERMINISTIC, not an
# artifact of whichever machine runs the fixture.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=protocol.file.allow GIT_CONFIG_VALUE_0=always
export GIT_AUTHOR_NAME=fixture GIT_AUTHOR_EMAIL=f@x GIT_COMMITTER_NAME=fixture GIT_COMMITTER_EMAIL=f@x
mkdir -p "$SB/homeA"

( cd "$SB" && HOME="$SB/homeA" bash "$SRC/scripts/setup-project.sh" seedling --muster-url "file://$SRC" --muster-branch "$BRANCH" ) > "$SB/setup.out" 2>&1
rc=$?
P="$SB/seedling"
if [ "$rc" -eq 0 ]; then ok "setup-project.sh exits 0"
else no "setup-project.sh failed (rc=$rc)"; tail -15 "$SB/setup.out" | sed 's/^/  got: /'; fi

# ---- seeded shape ----
missing=""
for f in CLAUDE.md .claude/settings.json .claude/statusline.sh .muster/config \
         knowledge-base/orchestration-queue.md knowledge-base/current-sprint.md \
         knowledge-base/agent-requests.md knowledge-base/agent-context/.populated \
         muster/system-guide.md muster/scripts/muster-boot.sh; do
  [ -f "$P/$f" ] || missing="$missing $f"
done
for r in pm developer ui-ux qa content marketing legal research; do
  [ -f "$P/.claude/agents/$r.md" ] || missing="$missing agents/$r.md"
done
[ -z "$missing" ] && ok "seeded shape complete (files + 8 bootloaders)" || no "seed missing:$missing"

if command -v jq >/dev/null 2>&1; then
  n="$(jq '.permissions.allow | length' "$P/.claude/settings.json" 2>/dev/null)"
  [ "$n" = "18" ] && ok "allowlist parses as JSON with 18 entries" || no "allowlist entries=$n (want 18)"
else
  echo "·  jq absent — allowlist JSON assert skipped"
fi
git -C "$P" log --oneline -1 >/dev/null 2>&1 && ok "initial commit exists" || no "no initial commit"

# ---- the load-bearing part: shipped gates run clean on the pristine seed ----
out="$(cd "$P" && bash muster/scripts/muster-boot.sh 2>&1)"; rc=$?
route="$(printf '%s\n' "$out" | grep -c '^ROUTE=')"
printf '%s\n' "$out" | grep -q '^ROUTE=onboarding' && [ "$route" = "1" ] \
  && ok "boot routes the pristine seed (exactly one ROUTE=onboarding)" \
  || { no "boot route wrong (rc=$rc)"; printf '%s\n' "$out" | tail -5 | sed 's/^/  got: /'; }

out="$(cd "$P" && bash muster/scripts/muster-plan-gate.sh 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q "ALL GREEN" \
  && ok "plan gate ALL GREEN on the pristine seed" \
  || { no "plan gate not green on seed (rc=$rc)"; printf '%s\n' "$out" | sed 's/^/  got: /'; }

out="$(cd "$P" && bash muster/scripts/muster-lint-requests.sh 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "requests lint clean on seed" || { no "requests lint red on seed (rc=$rc)"; printf '%s\n' "$out" | tail -3 | sed 's/^/  got: /'; }

out="$(cd "$P" && bash muster/scripts/muster-doctor-populated.sh 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "populated doctor clean on seed" || { no "doctor red on seed (rc=$rc)"; printf '%s\n' "$out" | tail -5 | sed 's/^/  got: /'; }

# ---- user-level-statusline path: permissions must STILL ship (statusLine key deferred) ----
mkdir -p "$SB/homeB/.claude"
printf '{\n  "statusLine": { "type": "command", "command": "mine.sh" }\n}\n' > "$SB/homeB/.claude/settings.json"
( cd "$SB" && HOME="$SB/homeB" bash "$SRC/scripts/setup-project.sh" seedling2 --muster-url "file://$SRC" --muster-branch "$BRANCH" ) > "$SB/setup2.out" 2>&1
P2="$SB/seedling2"
if [ -f "$P2/.claude/settings.json" ] && ! grep -q '"statusLine"' "$P2/.claude/settings.json" \
   && [ ! -f "$P2/.claude/statusline.sh" ]; then
  ok "user-statusline path: permissions seeded, statusLine key + script deferred"
else no "user-statusline path wrong (settings=$([ -f "$P2/.claude/settings.json" ] && echo yes || echo MISSING))"; fi
if command -v jq >/dev/null 2>&1; then
  n2="$(jq '.permissions.allow | length' "$P2/.claude/settings.json" 2>/dev/null)"
  [ "$n2" = "18" ] && ok "stripped settings is valid JSON with all 18 permissions" || no "stripped settings entries=$n2 (want 18)"
fi

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed   (sandbox kept on failure: $SB)"
if [ "$fail" -eq 0 ]; then exit 0; else trap - EXIT; exit 1; fi
