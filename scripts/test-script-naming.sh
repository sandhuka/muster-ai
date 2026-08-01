#!/usr/bin/env bash
# test-script-naming.sh — fixture gate: the script-fleet convention polices itself.
# Pins three floors so prose never has to: (1) every scripts/*.sh|*.py basename belongs to an
# allowed family (muster-lint-* checks and never mutates, muster-guard-* blocks fail-closed,
# muster-read-* shared parsers, muster-sprint-* the autonomous loop, an explicit verb list for
# the rest — plus test-*, and a FROZEN legacy-exception list that must never grow); (2) every
# muster-* script's line 2 declares its family — `(family:` — except DEPRECATED shims; (3) every
# script is executable. A new script that skips the grammar, the header, or chmod goes red here.
set -uo pipefail
cd "$(dirname "$0")/.."

pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }
bad(){ echo "FAIL: $1"; fail=$((fail+1)); }

# Frozen exceptions: pre-convention names kept for compatibility. Do NOT add to this list —
# new scripts take a family name.
legacy_ok(){
  case "$1" in
    setup-project.sh|setup-existing-project.sh|add-bootstrap-permissions.sh) return 0 ;;
    migrate-v1-to-v2.sh|migrate-v2-to-v3.sh|migrate-v3-to-v4.sh) return 0 ;;
    *) return 1 ;;
  esac
}

family_ok(){ # muster-<rest> basename -> allowed family?
  case "$1" in
    muster-lint-*.sh|muster-guard-*.sh|muster-read-*.sh|muster-sprint-*.sh) return 0 ;;
    muster-advance-queue.sh|muster-agent-cli.sh|muster-bind.sh|muster-boot.sh) return 0 ;;
    muster-bound-role.sh|muster-check-context.sh|muster-closeout.sh) return 0 ;;
    muster-doctor-*.sh|muster-find-*.sh|muster-housekeeping.sh) return 0 ;;
    muster-list-*.sh|muster-plan-gate.sh|muster-meter.py|muster-statusline.sh) return 0 ;;
    # Tier-2 deprecation shims (remove at next major, and this exemption with them)
    muster-commit-lint.sh|muster-queue-lint.sh|muster-requests-lint.sh) return 0 ;;
    *) return 1 ;;
  esac
}

names_bad=0; header_bad=0; exec_bad=0
for f in scripts/*.sh scripts/*.py; do
  b="$(basename "$f")"
  case "$b" in
    test-*.sh) : ;;                                   # fixture family
    muster-*)  family_ok "$b" || { bad "naming: $b matches no allowed family (see header)"; names_bad=1; } ;;
    *)         legacy_ok "$b" || { bad "naming: $b is neither muster-<family> nor a frozen legacy exception"; names_bad=1; } ;;
  esac
  case "$b" in
    muster-*)
      l2="$(sed -n '2p' "$f")"
      case "$l2" in
        *"(family:"*|*"DEPRECATED shim"*) : ;;
        *) bad "header: $b line 2 does not declare its family"; header_bad=1 ;;
      esac ;;
  esac
  [ -x "$f" ] || { bad "mode: $b is not executable"; exec_bad=1; }
done
[ "$names_bad" -eq 0 ]  && ok "every script belongs to an allowed family"
[ "$header_bad" -eq 0 ] && ok "every muster-* script declares its family on line 2"
[ "$exec_bad" -eq 0 ]   && ok "every script is executable"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
exit 0
