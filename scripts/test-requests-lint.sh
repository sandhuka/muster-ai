#!/usr/bin/env bash
# test-requests-lint.sh — regression fixtures for muster-requests-lint.sh (Arogh Sprint-7 F-S7-1).
# Each fixture asserts an exit code + a substring of the verdict. Exit 0 = all green.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
LINT="$HERE/muster-requests-lint.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
check(){ # name  expected_exit  expected_substr  fixture_file  [budget]
  local out rc; out="$(bash "$LINT" "$4" ${5:+"$5"} 2>&1)"; rc=$?
  if [ "$rc" = "$2" ] && printf '%s' "$out" | grep -q "$3"; then
    echo "PASS: $1"; pass=$((pass+1))
  else echo "FAIL: $1 (rc=$rc want=$2; out=<<$out>>)"; fail=$((fail+1)); fi
}

# --- clean: empty Active + one healthy in-review handoff (a pending reviewer remains) ---
cat > "$T/clean.md" <<'EOF'
# Agent Requests & Handoffs
<!-- TEMPLATES (copy when creating):
### [DATE] HO-[ID] — [Title]
**Status:** open | in-review | done
- [ ] Agent — pending
END TEMPLATES -->

## Active Requests

## Active Handoffs

### [2026-06-24] HO-201 — live feature
**Status:** in-review
**Reviewers:**
- [x] PM — done
- [ ] QA — pending

## Resolved (Last 10)
- HO-200 — earlier thing
EOF
check "clean ledger passes (template block ignored)" 0 "OK: agent-requests clean" "$T/clean.md"

# --- fresh/empty ledger (new project) passes ---
cat > "$T/empty.md" <<'EOF'
# Agent Requests & Handoffs
## Active Requests
## Active Handoffs
## Resolved (Last 10)
EOF
check "empty ledger passes" 0 "OK: agent-requests clean" "$T/empty.md"

# --- (i) reviewed-but-stale: all reviewers ticked, Status never flipped to done ---
cat > "$T/stale.md" <<'EOF'
# Agent Requests
## Active Handoffs
### [2026-06-24] HO-204 — accepted but Status lagged
**Status:** in-review
**Reviewers:**
- [x] PM — done
- [x] QA — done
## Resolved (Last 10)
EOF
check "(i) reviewed-but-stale handoff" 1 "all reviewers ticked but Status" "$T/stale.md"

# --- (ii) Status: done still sitting in Active ---
cat > "$T/doneactive.md" <<'EOF'
# Agent Requests
## Active Handoffs
### [2026-06-24] HO-301 — done but not swept
**Status:** done
- [x] PM — done
## Resolved (Last 10)
EOF
check "(ii) done entry left in Active" 1 "has Status: done but sits in Active" "$T/doneactive.md"

# --- (iii) duplicate ID (free-form Edit corrupting the ledger — F-S6-4 recurrence) ---
cat > "$T/dup.md" <<'EOF'
# Agent Requests
## Active Handoffs
### [2026-06-24] HO-106 — first copy
**Status:** in-review
- [ ] PM — pending
### [2026-06-24] HO-106 — duplicate copy
**Status:** open
- [ ] PM — pending
## Resolved (Last 10)
EOF
check "(iii) duplicate entry ID" 1 "duplicate entry ID HO-106" "$T/dup.md"

# --- (iv) Active over budget (coarse accumulation backstop) ---
check "(iv) Active over budget" 1 "Active sections total" "$T/clean.md" 3

# --- file/usage errors ---
check "missing file → exit 2" 2 "file not found" "$T/nope.md"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
