#!/usr/bin/env bash
# test-queue-lint.sh — regression fixtures for muster-queue-lint.sh. The lint mirrors the driver's
# (muster-sprint-run.sh) queue-parsing contract; this test pins both so they can't silently drift.
# Each fixture asserts an exit code + a substring of the verdict. Exit 0 = all green.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
LINT="$HERE/muster-queue-lint.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
check(){ # name  expected_exit  expected_substr  fixture_file
  local out rc; out="$(bash "$LINT" "$4" 2>&1)"; rc=$?
  if [ "$rc" = "$2" ] && printf '%s' "$out" | grep -q "$3"; then
    echo "PASS: $1"; pass=$((pass+1))
  else echo "FAIL: $1 (rc=$rc want=$2; out=<<$out>>)"; fail=$((fail+1)); fi
}

cat > "$T/ok.md" <<'EOF'
## Next Step
### Step 1 — Developer: build seam
```
Role: developer
Body may mention ### Section A in prose — must not be miscounted as a step.
```
## Upcoming
### Step 2 — QA: verify
```
Role: qa
```
### Step 32.5 — Content: microcopy fix
```
Role: content
```
## Founder Decisions
## Done
EOF
check "well-formed (NS=1, 3 steps, prose ### in body)" 0 "OK: queue well-formed" "$T/ok.md"

cat > "$T/fenceless-with-work.md" <<'EOF'
## Next Step
### Step 1 — PM: plan
_(forgot to fence the next step)_
## Upcoming
### Step 2 — QA
```
Role: qa
```
EOF
check "run-killer: fenceless NS + queued Upcoming" 1 "halts WITHOUT running the queued work" "$T/fenceless-with-work.md"

cat > "$T/idle.md" <<'EOF'
## Next Step

_Sprint CLOSED. Intentionally fenceless — nothing queued._

## Upcoming

## Founder Decisions
EOF
check "idle/closed sprint (fenceless NS, empty Upcoming) = OK" 0 "OK: idle" "$T/idle.md"

cat > "$T/twofence.md" <<'EOF'
## Next Step
### Step 1
```
Role: developer
```
### Step 2 wrongly in Next Step
```
Role: qa
```
## Upcoming
EOF
check "Next Step holds >1 fenced step" 1 "exactly 1 is allowed" "$T/twofence.md"

cat > "$T/noheading.md" <<'EOF'
## Next Step
```
Role: developer
```
## Upcoming
EOF
check "fenced step with no heading (empty label)" 1 "no heading" "$T/noheading.md"

cat > "$T/norole.md" <<'EOF'
## Next Step
### Step 1
```
Inputs: no role line
```
## Upcoming
EOF
check "fenced step missing Role:" 1 "missing a .Role:. line" "$T/norole.md"

cat > "$T/badrole.md" <<'EOF'
## Next Step
### Step 1
```
Role: sprint
```
## Upcoming
EOF
check "invalid Role: value" 1 "invalid Role" "$T/badrole.md"

cat > "$T/nons.md" <<'EOF'
## Upcoming
### Step 1
```
Role: qa
```
EOF
check "no ## Next Step section" 1 "no .## Next Step. section" "$T/nons.md"

cat > "$T/nested.md" <<'EOF'
## Next Step
### Step 1 — Developer
```
Role: developer
```
### Upcoming
#### Step 2 — QA
```
Role: qa
```
## Founder Decisions
EOF
check "nested ### Upcoming form (NS bounded at any-level Upcoming)" 0 "OK: queue well-formed" "$T/nested.md"

echo "---- $pass passed, $fail failed ----"
[ "$fail" = 0 ]
