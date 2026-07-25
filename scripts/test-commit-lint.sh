#!/usr/bin/env bash
# test-commit-lint.sh — regression fixtures for muster-commit-lint.sh (CLAUDE.md Rule 16).
# Builds a throwaway repo, makes commits with known subjects, asserts lint verdicts.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
LINT="$HERE/muster-commit-lint.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0

cd "$T" && git init -q && git config user.email t@t && git config user.name t
c(){ echo "$RANDOM" >> f; git add f; git commit -qm "$1"; }   # commit with subject $1

check(){ # name  expected_exit  target
  bash "$LINT" "${3:-HEAD}" >/dev/null 2>&1; local rc=$?
  if [ "$rc" = "$2" ]; then echo "PASS: $1"; pass=$((pass+1))
  else echo "FAIL: $1 (rc=$rc want=$2)"; fail=$((fail+1)); fi
}

c "init";                                                     check "scaffold init exempt"        0
c "developer: hero streams the live run-log";                 check "conforming subject"          0
c "Fix stuff";                                                check "missing role prefix"         1
c "qa: rotation verified across 3 timezones — 11/11 pass";    check "role with unicode dash ok"   0
c "designer: not a muster role";                              check "unknown role rejected"       1
c "ui-ux: hyphenated role accepted";                          check "hyphenated role"             0
c "pm: $(printf 'x%.0s' {1..80})";                            check "over-72-char subject"        1
first="$(git rev-list --max-parents=0 HEAD)"
check "range with violations" 1 "$first..HEAD"
c "xo: framework roles lint too";                             check "xo role accepted"            0
git checkout -qb side HEAD~1 && echo s > g && git add g && git commit -qm "content: side work" \
  && git checkout -q - && git merge -q --no-ff -m "merge branch side" side
check "merge commit exempt (range)" 1 "$first..HEAD"          # still 1: earlier violations in range
git checkout -qb clean2 "$first" && c "pm: clean range start" && c "legal: clean range end"
check "clean range" 0 "$first..HEAD"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
