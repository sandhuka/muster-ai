#!/usr/bin/env bash
# test-find-skill.sh — regression fixtures for muster-find-skill.sh. Builds a throwaway muster
# tree (framework layout AND project-submodule layout) and asserts resolution, ambiguity,
# case-exactness, and cwd-independence.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0

check(){ # name expected_exit expected_stdout_substr cmd...
  local nm="$1" want_rc="$2" want_out="$3"; shift 3
  local out rc; out="$("$@" 2>/dev/null)"; rc=$?
  if [ "$rc" = "$want_rc" ] && { [ -z "$want_out" ] || printf '%s' "$out" | grep -qF "$want_out"; }; then
    echo "PASS: $nm"; pass=$((pass+1))
  else
    echo "FAIL: $nm (rc=$rc want=$want_rc; out=$out)"; fail=$((fail+1))
  fi
}

# --- fixture 1: framework-repo layout (scripts/ at tree root, skills under team/) ---
F="$T/framework"
mkdir -p "$F/scripts" "$F/team/developer/skills/ios" "$F/team/developer/skills/generic" \
         "$F/team/ui-ux/skills/web" "$F/team/developer/skills/web" "$F/team/qa/skills/generic"
cp "$HERE/muster-find-skill.sh" "$F/scripts/"
touch "$F/team/developer/skills/ios/ios-mvvm.md" \
      "$F/team/developer/skills/generic/code-standards.md" \
      "$F/team/developer/skills/web/web-accessibility.md" \
      "$F/team/ui-ux/skills/web/web-accessibility.md" \
      "$F/team/qa/skills/generic/verification-discipline.md"

check "unique name resolves"            0 "team/developer/skills/ios/ios-mvvm.md" \
      bash "$F/scripts/muster-find-skill.sh" ios-mvvm
check "tolerates .md suffix"            0 "ios-mvvm.md" \
      bash "$F/scripts/muster-find-skill.sh" ios-mvvm.md
check "cross-role resolves"             0 "team/qa/skills/generic/verification-discipline.md" \
      bash "$F/scripts/muster-find-skill.sh" verification-discipline
check "ambiguous → exit 2"              2 "" \
      bash "$F/scripts/muster-find-skill.sh" web-accessibility
check "role qualifier disambiguates"    0 "team/ui-ux/skills/web/web-accessibility.md" \
      bash "$F/scripts/muster-find-skill.sh" web-accessibility ui-ux
check "not found → exit 1"              1 "" \
      bash "$F/scripts/muster-find-skill.sh" no-such-skill
check "wrong role scoping → exit 1"     1 "" \
      bash "$F/scripts/muster-find-skill.sh" ios-mvvm qa
check "no args → usage exit 3"          3 "" \
      bash "$F/scripts/muster-find-skill.sh"
# cwd-independence: run from a deep subdir of the tree
check "cwd-agnostic (deep subdir)"      0 "ios-mvvm.md" \
      bash -c 'cd "$1/team/qa/skills" && bash "$1/scripts/muster-find-skill.sh" ios-mvvm' _ "$F"
# case-exactness: must NOT resolve wrong case even on case-insensitive filesystems
check "case-exact (IOS-MVVM rejected)"  1 "" \
      bash "$F/scripts/muster-find-skill.sh" IOS-MVVM

# --- fixture 2: project layout (muster as submodule at muster/, caller at project root) ---
P="$T/project"
mkdir -p "$P/muster/scripts" "$P/muster/team/developer/skills/ios" "$P/knowledge-base"
cp "$HERE/muster-find-skill.sh" "$P/muster/scripts/"
touch "$P/muster/team/developer/skills/ios/ios-mvvm.md"

check "project layout emits muster/ path" 0 "/muster/team/developer/skills/ios/ios-mvvm.md" \
      bash -c 'cd "$1" && bash muster/scripts/muster-find-skill.sh ios-mvvm' _ "$P"
check "project subdir cwd-agnostic"       0 "/muster/team/developer/skills/ios/ios-mvvm.md" \
      bash -c 'cd "$1/knowledge-base" && bash ../muster/scripts/muster-find-skill.sh ios-mvvm' _ "$P"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
