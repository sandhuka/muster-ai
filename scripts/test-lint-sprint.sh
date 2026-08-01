#!/usr/bin/env bash
# test-lint-sprint.sh — regression fixtures for muster-lint-sprint.sh (board floor + coherence).
# Calibrated before shipping against BOTH live conventions: the arogh Sprint-9 wave-table board
# (green) and the empty seeded template board (green — planning fills it).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
LINT="$HERE/muster-lint-sprint.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
check(){ # name  expected_exit  expected_substr  board  [queue]
  local out rc; out="$(bash "$LINT" "$4" "${5:-$T/noqueue.md}" 2>&1)"; rc=$?
  if [ "$rc" = "$2" ] && printf '%s' "$out" | grep -qF -- "$3"; then
    echo "PASS: $1"; pass=$((pass+1))
  else echo "FAIL: $1 (rc=$rc want=$2; out=<<$out>>)"; fail=$((fail+1)); fi
}

# empty seeded-shape board -> clean (nothing to check yet)
printf '# Current Sprint\n## Sprint [N]: [Name]\n### Developer\n### QA\n' > "$T/empty.md"
check "empty seeded board passes" 0 "OK: board well-formed" "$T/empty.md"

# well-formed checkbox entry
cat > "$T/good.md" <<'EOF'
## Sprint 3: Ship it
### Developer
- [ ] **Build the widget** — Priority: HIGH, Effort: M, Platform: ios
  - **Deliverable**: `App/Widget.swift`
  - **Dependencies**: design spec HO-12
  - **Acceptance criteria**:
    - renders
    - tests green
EOF
check "well-formed checkbox entry passes" 0 "OK: board well-formed" "$T/good.md"

# bad enums fail, named
cat > "$T/badenum.md" <<'EOF'
### Developer
- [ ] **Build it** — Priority: URGENT, Effort: XXL, Platform: metaverse
  - **Deliverable**: `x`
  - **Acceptance criteria**: works
EOF
check "invalid Priority fails" 1 "Priority missing or not HIGH/MED/LOW" "$T/badenum.md"
check "invalid Effort fails"   1 "Effort missing or not S/M/L/XL" "$T/badenum.md"
check "invalid Platform fails" 1 "Platform not a valid value" "$T/badenum.md"

# missing sub-bullets fail
cat > "$T/nosub.md" <<'EOF'
### QA
- [ ] **Verify the build** — Priority: MED, Effort: S
  - **Dependencies**: none
EOF
check "missing Deliverable+Acceptance fails" 1 "missing sub-bullet(s): Deliverable, Acceptance" "$T/nosub.md"

# capacity guidelines warn (6 open tasks, 3 HIGH) — warn only, exit 0
{ echo '### Developer'
  for i in 1 2 3; do printf -- '- [ ] **T%s** — Priority: HIGH, Effort: S\n  - **Deliverable**: `d`\n  - **Acceptance criteria**: ok\n' "$i"; done
  for i in 4 5 6; do printf -- '- [ ] **T%s** — Priority: LOW, Effort: S\n  - **Deliverable**: `d`\n  - **Acceptance criteria**: ok\n' "$i"; done
} > "$T/cap.md"
check "capacity warns (>5 open)" 0 "open tasks (capacity guideline" "$T/cap.md"
check "HIGH-count warns (>2)"    0 "open HIGH tasks" "$T/cap.md"

# wave-table rows: good passes, empty deliverable fails
cat > "$T/table.md" <<'EOF'
### Phase C
| Step | Role | Deliverable | Pinned assertion |
|---|---|---|---|
| 3 | QA | the net | FD-5 |
| 4 | Developer | the revert | R11 |
EOF
check "wave-table board passes" 0 "OK: board well-formed" "$T/table.md"
cat > "$T/tablebad.md" <<'EOF'
| 5 | Developer |  | x |
EOF
check "empty table Deliverable cell fails" 1 "empty Deliverable cell" "$T/tablebad.md"

# coherence: queued role absent from board / board role never queued -> WARNs
cat > "$T/q.md" <<'EOF'
## Next Step
### Step 1 — QA: verify
```
Role: qa
Inputs: a
Deliverable: b
Acceptance: c
On-completion: d
```
EOF
check "coherence: queued role missing from board warns" 0 "queued role 'qa' has no open work on the board" "$T/good.md" "$T/q.md"
check "coherence: board role never queued warns"        0 "board role 'developer' has open work but is never queued" "$T/good.md" "$T/q.md"

# missing board -> exit 3
check "missing board exit 3" 3 "board not found" "$T/nope.md"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
