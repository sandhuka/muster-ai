#!/usr/bin/env bash
# test-lint-sprint.sh — regression fixtures for muster-lint-sprint.sh (wave-board floor + coherence).
# The wave-table is THE board format (founder-ruled); calibrated against the live arogh Sprint-9
# board+queue (green, incl. per-step coherence across 18 shared step numbers) and the seeded
# template (green — an empty board passes, planning fills it).
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

# the seeded template itself must pass with an empty queue-shaped file
printf '## Next Step\n\n_(empty)_\n' > "$T/emptyq.md"
check "seeded template board passes" 0 "OK: wave-board well-formed" "$HERE/../templates/knowledge-base/current-sprint.md" "$T/emptyq.md"

# well-formed wave-table
cat > "$T/good.md" <<'EOF'
## Wave board
### Phase A — build
| Step | Role | Deliverable | Verification |
|---|---|---|---|
| 1 | Developer | the widget | widget assertion |
| 2 | QA | verification HO | suite green |
| 3 | **founder (halt)** | gate verdict | — |
EOF
check "well-formed wave-table passes" 0 "OK: wave-board well-formed" "$T/good.md"

# empty cells fail
cat > "$T/badcells.md" <<'EOF'
| 4 | Developer |  | x |
| 5 |  | thing | x |
EOF
check "empty Deliverable cell fails" 1 "empty Deliverable cell" "$T/badcells.md"
check "empty Role cell fails"        1 "empty Role cell" "$T/badcells.md"

# unrecognized role warns only
printf '| 6 | Wizard | spells | — |\n' > "$T/badrole.md"
check "unrecognized Role warns" 0 "unrecognized Role cell" "$T/badrole.md"

# capacity: >5 rows for one role warns
{ echo '| Step | Role | Deliverable | Verification |'; echo '|---|---|---|---|'
  for i in 1 2 3 4 5 6; do echo "| $i | Developer | thing $i | t$i |"; done; } > "$T/cap.md"
check "capacity warns (>5 rows one role)" 0 "capacity guideline" "$T/cap.md"

# a queue for coherence checks
cat > "$T/q.md" <<'EOF'
## Next Step

### Step 1 — Developer: build
```
Role: developer
Inputs: a
Deliverable: b
Acceptance: c
On-completion: d
```

## Upcoming

### Step 2 — QA: verify
```
Role: qa
Inputs: a
Deliverable: b
Acceptance: c
On-completion: d
```
EOF

# per-step coherence: board row 2 claims Developer but queue Step 2 binds qa -> FAIL
cat > "$T/mismatch.md" <<'EOF'
| Step | Role | Deliverable | Verification |
|---|---|---|---|
| 1 | Developer | the widget | t |
| 2 | Developer | more widget | t |
EOF
check "per-step role mismatch fails" 1 "board row 2 says 'developer' but queue Step 2 binds 'qa'" "$T/mismatch.md" "$T/q.md"

# matching board -> clean incl. coherence
cat > "$T/match.md" <<'EOF'
| Step | Role | Deliverable | Verification |
|---|---|---|---|
| 1 | Developer | the widget | t |
| 2 | QA | verification | t |
EOF
check "matching board+queue clean" 0 "OK: wave-board well-formed" "$T/match.md" "$T/q.md"

# role-set: queued role with no board row / board role never queued -> WARNs
printf '| Step | Role | Deliverable | Verification |\n|---|---|---|---|\n| 1 | Developer | w | t |\n| 9 | Marketing | docs | — |\n' > "$T/roleset.md"
check "queued role without board row warns" 0 "queued role 'qa' has no board row" "$T/roleset.md" "$T/q.md"
check "board role never queued warns"       0 "board role 'marketing' is never queued" "$T/roleset.md" "$T/q.md"

# a done step on the board whose fence left the queue is NOT flagged (only whole-role absence)
cat > "$T/done.md" <<'EOF'
| Step | Role | Deliverable | Verification |
|---|---|---|---|
| 0 | QA | earlier verification, done | t |
| 1 | Developer | the widget | t |
| 2 | QA | verification | t |
EOF
check "done board row (no queue step) not flagged" 0 "OK: wave-board well-formed" "$T/done.md" "$T/q.md"

# a table row inside a fenced example is NOT a board row
cat > "$T/fenced.md" <<'EOF'
Example of a malformed row:
```
| 1 | Developer |  | x |
```
EOF
check "fenced example row not parsed" 0 "OK: wave-board well-formed" "$T/fenced.md"

# missing board -> exit 3
check "missing board exit 3" 3 "board not found" "$T/nope.md"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
