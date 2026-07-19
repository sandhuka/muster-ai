#!/usr/bin/env bash
# test-sprint-new.sh — fail-closed safety fixture for the clean-tree worktree guard.
#
# muster-sprint-new.sh and muster-sprint-sandbox.sh create a sprint worktree with `git worktree
# add`, which checks out from HEAD — so uncommitted work in the current tree is SILENTLY ABSENT
# from the run (the top autonomous-launch footgun). muster-guard-clean-tree.sh refuses on a dirty
# tree. This gate asserts: the guard passes on a clean tree, refuses on every dirty shape
# (modified / untracked / not-a-repo), honours the MUSTER_ALLOW_DIRTY override, the real scripts
# create NO worktree on refusal, a missing guard file fails closed, and the guard is sourced
# BEFORE `git worktree add` in both scripts.
#
# Deterministic, remote-severed, self-contained. Self-cleans on green; keeps the sandbox on failure.
set -uo pipefail
MUSTER="$(cd "$(dirname "$0")/.." && pwd)"
GUARD="$MUSTER/scripts/muster-guard-clean-tree.sh"
SB="$(mktemp -d "${TMPDIR:-/tmp}/muster-new-test.XXXXXX")"
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }
no(){ echo "FAIL: $1"; fail=$((fail+1)); }

# --- a git checkout with one commit (so worktree add / status have a HEAD) ---
PRIMARY="$SB/primary"; mkdir -p "$PRIMARY"
git -C "$PRIMARY" init -q
git -C "$PRIMARY" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
printf 'tracked\n' > "$PRIMARY/file.txt"
git -C "$PRIMARY" add file.txt
git -C "$PRIMARY" -c user.email=t@t -c user.name=t commit -q -m add-file

# source the guard in a subshell rooted at $1, with optional env "VAR=val" as $2; echo exit code
guard_rc(){ ( cd "$1"; [ -n "${2:-}" ] && export "$2"; source "$GUARD" ) >"$SB/out" 2>&1; echo $?; }

# --- 1. clean tree: guard passes ---
rc="$(guard_rc "$PRIMARY")"
[ "$rc" -eq 0 ] && ok "guard passes on a clean tree (exit 0)" || no "guard blocked a clean tree (exit $rc)"

# --- 2. modified tracked file: guard refuses, names the reason ---
printf 'changed\n' >> "$PRIMARY/file.txt"
rc="$(guard_rc "$PRIMARY")"
[ "$rc" -ne 0 ] && ok "guard refuses a modified tracked file (exit $rc)" || no "guard passed a modified tree (exit 0)"
grep -qi "uncommitted" "$SB/out" && ok "refusal names the uncommitted-work reason" || no "refusal message missing"
git -C "$PRIMARY" checkout -q -- file.txt   # clean up

# --- 3. untracked file: guard refuses (a new source file is the exact footgun) ---
printf 'new\n' > "$PRIMARY/untracked.txt"
rc="$(guard_rc "$PRIMARY")"
[ "$rc" -ne 0 ] && ok "guard refuses an untracked file (exit $rc)" || no "guard passed an untracked file (exit 0)"

# --- 4. MUSTER_ALLOW_DIRTY=1 overrides on the same dirty tree ---
rc="$(guard_rc "$PRIMARY" "MUSTER_ALLOW_DIRTY=1")"
[ "$rc" -eq 0 ] && ok "MUSTER_ALLOW_DIRTY=1 overrides the refusal (exit 0)" || no "override did not pass (exit $rc)"
rm -f "$PRIMARY/untracked.txt"   # clean up

# --- 5. not a git repo: guard refuses ---
NOGIT="$SB/nogit"; mkdir -p "$NOGIT"
rc="$(guard_rc "$NOGIT")"
[ "$rc" -ne 0 ] && ok "guard refuses outside a git repo (exit $rc)" || no "guard passed outside a git repo (exit 0)"

# --- 6. real muster-sprint-new.sh on a dirty tree: refuses AND creates no worktree ---
printf 'changed\n' >> "$PRIMARY/file.txt"
( cd "$PRIMARY" && bash "$MUSTER/scripts/muster-sprint-new.sh" ) >"$SB/out" 2>&1; rc=$?
[ "$rc" -ne 0 ] && ok "sprint-new refuses on a dirty tree (exit $rc)" || no "sprint-new ran on a dirty tree (exit 0)"
ls -d "$SB"/primary-sprint-* >/dev/null 2>&1 && no "a worktree was created despite the dirty refusal" || ok "no worktree created on refusal"
git -C "$PRIMARY" checkout -q -- file.txt   # clean up

# --- 7. guard file missing: the `|| exit 1` fallback fails closed ---
mkdir -p "$SB/noguard"
cp "$MUSTER/scripts/muster-sprint-new.sh" "$SB/noguard/"   # copied WITHOUT its guard sibling
( cd "$PRIMARY" && bash "$SB/noguard/muster-sprint-new.sh" ) >"$SB/out" 2>&1; rc=$?
[ "$rc" -ne 0 ] && ok "sprint-new fails closed when the guard file is missing (exit $rc)" || no "sprint-new ran with no guard present"

# --- 8-9. structural: guard sourced BEFORE `git worktree add` in both creators ---
for s in muster-sprint-new.sh muster-sprint-sandbox.sh; do
  gl="$(grep -n 'muster-guard-clean-tree.sh' "$MUSTER/scripts/$s" | head -1 | cut -d: -f1)"
  wl="$(grep -n 'git worktree add' "$MUSTER/scripts/$s" | head -1 | cut -d: -f1)"
  { [ -n "$gl" ] && [ -n "$wl" ] && [ "$gl" -lt "$wl" ]; } \
    && ok "$s sources the guard before worktree add (line $gl < $wl)" \
    || no "$s guard not before worktree add (guard=$gl worktree=$wl)"
done

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed   (sandbox: $SB)"
if [ "$fail" -eq 0 ]; then rm -rf "$SB"; exit 0; else echo "(sandbox kept: $SB)"; exit 1; fi
