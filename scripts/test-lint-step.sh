#!/usr/bin/env bash
# test-lint-step.sh — regression fixtures for muster-lint-step.sh (step-body executability).
# Each fixture asserts an exit code + a substring of the verdict. Calibrated against the live
# arogh Sprint-9 queue before shipping (0 FAIL, 5 correct premium WARNs on 19 steps).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
LINT="$HERE/muster-lint-step.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
check(){ # name  expected_exit  expected_substr  fixture_file
  local out rc; out="$(bash "$LINT" "$4" 2>&1)"; rc=$?
  if [ "$rc" = "$2" ] && printf '%s' "$out" | grep -qF -- "$3"; then
    echo "PASS: $1"; pass=$((pass+1))
  else echo "FAIL: $1 (rc=$rc want=$2; out=<<$out>>)"; fail=$((fail+1)); fi
}

# a complete specialist step (plain-field live convention) + PM step + halt gate -> clean
cat > "$T/good.md" <<'EOF'
## Next Step

### Step 2 — Marketing: doc refresh
```
Role: marketing
Inputs: agent-context/marketing.md · brand-guidelines.md
Deliverable: launch/strategy.md re-derived
Acceptance: traces to thesis. See current-sprint.md.
On-completion: Pre-Handoff Self-Review; HO to PM; update the queue.
```

## Upcoming

### Step 3 — PM: encode
```
Role: pm
Fold the verdict into the ledger and promote Step 4.
```

### Step 4 — Founder gate (halt)
```
Role: halt
Walk the wave-review.md checklist, write APPROVE / CHANGES in the Verdict block.
```
EOF
check "clean queue (plain fields, pm exempt, halt cites gate file)" 0 "OK: every step body is cold-agent-executable" "$T/good.md"

# bold-field template convention also satisfies
cat > "$T/bold.md" <<'EOF'
### Step 1 — Developer: build
```
Role: developer
**Task:** build the thing
**Inputs:**
- `a.md`
**Deliverable:** `out/thing.swift`
**Acceptance criteria:** See `knowledge-base/current-sprint.md`. Summary: works.
**On completion:** File handoff; run the Pre-Handoff Self-Review Checklist.
```
EOF
check "bold template fields accepted" 0 "OK: every step body" "$T/bold.md"

# missing Deliverable + Acceptance -> FAIL naming the fields
cat > "$T/missing.md" <<'EOF'
### Step 5 — QA: verify
```
Role: qa
Inputs: agent-context/qa.md
On-completion: file the HO.
```
EOF
check "missing fields fail, named" 1 "missing field line(s): Deliverable, Acceptance" "$T/missing.md"

# @-mention role marker -> FAIL
cat > "$T/atrole.md" <<'EOF'
### Step 6 — Dev
```
Role: developer
Inputs: a.md
Deliverable: b.md
Acceptance: works
On-completion: hand off to @qa for verification.
```
EOF
check "@-mention role marker fails" 1 "@-mention role marker" "$T/atrole.md"

# an email @ is NOT an @-mention
cat > "$T/email.md" <<'EOF'
### Step 7 — Legal
```
Role: legal
Inputs: privacy@arogh.com placeholder list
Deliverable: docs
Acceptance: entity filled
On-completion: HO to PM.
```
EOF
check "email @ not flagged" 0 "OK:" "$T/email.md"

# halt gate without wave-review.md -> FAIL
cat > "$T/badhalt.md" <<'EOF'
### Step 8 — Gate
```
Role: halt
Review the build and give a verdict.
```
EOF
check "halt without wave-review.md fails" 1 "does not cite wave-review.md" "$T/badhalt.md"

# founder-chat vocabulary -> WARN only (exit 0)
cat > "$T/vocab.md" <<'EOF'
### Step 9 — Dev
```
Role: developer
Inputs: a.md
Deliverable: b.md
Acceptance: works
On-completion: tell the founder about the tradeoff, then file the HO.
```
EOF
check "founder-chat instruction warns (not fail)" 0 "WARN:" "$T/vocab.md"

# session-relative reference -> WARN only
cat > "$T/relative.md" <<'EOF'
### Step 10 — Dev
```
Role: developer
Inputs: a.md
Deliverable: b.md
Acceptance: follow the existing pattern for error handling
On-completion: HO to PM.
```
EOF
check "session-relative reference warns" 0 "session-relative reference" "$T/relative.md"

# premium model -> WARN listed; malformed Model -> FAIL
cat > "$T/model.md" <<'EOF'
### Step 11 — Dev
```
Role: developer
Model: fable
Inputs: a.md
Deliverable: b.md
Acceptance: works
On-completion: HO.
```
EOF
check "premium model warns, listed" 0 "premium model queued" "$T/model.md"
cat > "$T/badmodel.md" <<'EOF'
### Step 12 — Dev
```
Role: developer
Model: claude opus latest please
Inputs: a.md
Deliverable: b.md
Acceptance: works
On-completion: HO.
```
EOF
check "malformed Model line fails" 1 "malformed Model: line" "$T/badmodel.md"

# missing file -> exit 3 usage
check "missing file exit 3" 3 "file not found" "$T/nope.md"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
