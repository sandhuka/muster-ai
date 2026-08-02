#!/usr/bin/env bash
# test-sprint-resume.sh — fail-closed safety fixture for muster-sprint-resume.sh.
#
# Resume sources the Tier-1 worktree guard BEFORE its `--dangerously-skip-permissions` PM call,
# so a regression that drops or reorders the guard would run skip-permissions on the operator's
# PRIMARY checkout (irreversible). This gate asserts the guard fires first: on a primary checkout,
# and when the guard file is missing, resume refuses (non-zero exit) and makes NO `claude` call —
# proven by a PATH-injected stub claude that drops a marker if it is ever invoked.
#
# Deterministic, remote-severed, self-contained. Self-cleans on green; keeps the sandbox on failure.
set -uo pipefail
MUSTER="$(cd "$(dirname "$0")/.." && pwd)"
SB="$(mktemp -d "${TMPDIR:-/tmp}/muster-resume-test.XXXXXX")"
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }
no(){ echo "FAIL: $1"; fail=$((fail+1)); }

# --- stub claude: drops a marker if invoked (it must NOT be, on a guarded refusal) ---
mkdir -p "$SB/bin"
cat > "$SB/bin/claude" <<EOF
#!/usr/bin/env bash
touch "$SB/claude-was-called"
exit 0
EOF
chmod +x "$SB/bin/claude"

# --- a PRIMARY git checkout (git-dir = .git, NOT */worktrees/*) ---
PRIMARY="$SB/primary"; mkdir -p "$PRIMARY"; git -C "$PRIMARY" init -q

run_resume(){ # $1 = resume.sh path ; runs FROM the primary checkout with the stub claude on PATH
  rm -f "$SB/claude-was-called"
  ( cd "$PRIMARY" && PATH="$SB/bin:$PATH" bash "$1" ) >"$SB/out" 2>&1
  echo $?
}

# --- 1. primary checkout: real resume.sh (guard sibling present) refuses, no claude ---
rc="$(run_resume "$MUSTER/scripts/muster-sprint-resume.sh")"
[ "$rc" -ne 0 ] && ok "resume refuses on primary checkout (exit $rc)" || no "resume ran on primary checkout (exit 0)"
grep -q "primary checkout" "$SB/out" && ok "refusal names the primary-checkout reason" || no "refusal message missing"
[ ! -f "$SB/claude-was-called" ] && ok "no claude call on primary (skip-permissions never ran)" || no "claude was invoked on the primary checkout"

# --- 2. guard file missing: resume's own `|| exit 1` fallback refuses, no claude ---
mkdir -p "$SB/noguard"
cp "$MUSTER/scripts/muster-sprint-resume.sh" "$SB/noguard/"   # copied WITHOUT its guard sibling
rc="$(run_resume "$SB/noguard/muster-sprint-resume.sh")"
[ "$rc" -ne 0 ] && ok "resume refuses when the guard file is missing (exit $rc)" || no "resume ran with no guard present"
[ ! -f "$SB/claude-was-called" ] && ok "no claude call when guard missing" || no "claude was invoked with no guard"

# --- 3. structural: the guard is sourced BEFORE the skip-permissions PM call (now the
# adapter's agent_plain — the harness flags themselves live in muster-agent-cli.sh) ---
gl="$(grep -n 'muster-guard-worktree.sh' "$MUSTER/scripts/muster-sprint-resume.sh" | head -1 | cut -d: -f1)"
cl="$(grep -n '^agent_plain pm' "$MUSTER/scripts/muster-sprint-resume.sh" | head -1 | cut -d: -f1)"
{ [ -n "$gl" ] && [ -n "$cl" ] && [ "$gl" -lt "$cl" ]; } \
  && ok "guard sourced before the skip-permissions call (line $gl < $cl)" \
  || no "guard not before skip-permissions (guard=$gl call=$cl)"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed   (sandbox: $SB)"
if [ "$fail" -eq 0 ]; then rm -rf "$SB"; exit 0; else echo "(sandbox kept: $SB)"; exit 1; fi
