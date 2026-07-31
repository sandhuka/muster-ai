#!/usr/bin/env bash
# test-gate-wrappers.sh — fixture gate for muster-plan-gate.sh + muster-closeout.sh.
# Pins the wrapper contract: mandated order, ✓/✗ per check, refuse-green-if-any-red, the
# closeout worklist as non-gating INFO, and per-queued-role fan-out in the plan gate.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/muster-gatew-test.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT

PROJ="$SBX/proj"
mkdir -p "$PROJ/muster/scripts" "$PROJ/knowledge-base/agent-context"
for s in muster-plan-gate.sh muster-closeout.sh muster-queue-lint.sh muster-lint-context.sh \
         muster-read-queue.sh muster-read-populated.sh muster-lint-kb-budgets.sh \
         muster-requests-lint.sh muster-lint-entry.sh muster-lint-decisions.sh \
         muster-lint-durability.sh muster-lint-gate-packet.sh muster-list-open-items.sh; do
  cp "$SRC/scripts/$s" "$PROJ/muster/scripts/"
done
touch "$PROJ/muster/system-guide.md"

cat > "$PROJ/knowledge-base/agent-context/.populated" <<'EOF'
{
  "version": "2",
  "onboarded_at": "2026-07-01",
  "onboarding_complete_at": "2026-07-02",
  "agents": {
    "developer": "2026-01-01",
    "ui-ux": "2026-01-01",
    "content": "2026-01-01",
    "qa": "2026-01-01",
    "research": "2026-01-01",
    "marketing": "2026-01-01",
    "legal": "2026-01-01",
    "pm": "2026-01-01"
  },
  "lock": null
}
EOF
ctx(){ printf '# %s\n## Current Tasks\n### Sprint 1 — real task\nDo the thing well.\n## Product Context\n' "$1" > "$PROJ/knowledge-base/agent-context/$1.md"; }
ctx qa; ctx developer; ctx pm
cat > "$PROJ/knowledge-base/orchestration-queue.md" <<'EOF'
# Orchestration Queue

## Founder Decisions

## Next Step

### Step 1 — QA: verify
```
Role: qa
Verify.
```

## Upcoming

### Step 2 — Developer: build
```
Role: developer
Build.
```

### Step 3 — Founder gate
```
Role: halt
Gate.
```

## Done (Last 10)
EOF
cat > "$PROJ/knowledge-base/agent-requests.md" <<'EOF'
# Agent Requests & Handoffs

## Active Requests

## Active Handoffs

## Resolved (Last 10)
EOF

n=0; fails=0
t(){ # $1=name $2=script $3=want-exit $4=grep-must $5=grep-must-NOT ('' skip)
  local name="$1" script="$2" wrc="$3" want="$4" nowant="${5:-}"
  n=$((n+1))
  local out rc; out="$(cd "$PROJ" && bash "muster/scripts/$script" 2>&1)"; rc=$?
  local ok=1
  [ "$rc" = "$wrc" ] || ok=0
  printf '%s\n' "$out" | grep -qF -- "$want" || ok=0
  [ -n "$nowant" ] && printf '%s\n' "$out" | grep -qF -- "$nowant" && ok=0
  if [ "$ok" = 1 ]; then echo "PASS: $name"
  else fails=$((fails+1)); echo "FAIL: $name (rc=$rc want=$wrc)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fi
}

# plan gate: all green, fans out per queued role, halt skipped
t plan-all-green      muster-plan-gate.sh 0 "ALL GREEN — paste this block into the planning closeout."
t plan-role-fanout    muster-plan-gate.sh 0 "context gate: developer has real inlined tasks"
t plan-halt-skipped   muster-plan-gate.sh 0 "MUSTER PLAN GATE" "context gate: halt"

# plan gate: red on unpopulated context -> ✗ + NOT GREEN, no green line
printf '# dev\n## Current Tasks\nSee `knowledge-base/current-sprint.md` for current sprint tasks.\n' > "$PROJ/knowledge-base/agent-context/developer.md"
t plan-red-unpopulated muster-plan-gate.sh 1 "✗ context gate: developer has real inlined tasks" "ALL GREEN"
t plan-red-notgreen    muster-plan-gate.sh 1 "NOT GREEN — fix the ✗ items"
ctx developer

# closeout: all green + worklist always printed as INFO
t closeout-all-green  muster-closeout.sh 0 "ALL GREEN — paste this block into the closeout."
t closeout-worklist   muster-closeout.sh 0 "open-items worklist (INFO"

# closeout: red on phantom deliverable -> ✗ entry bodies, refuse green
cat > "$PROJ/knowledge-base/agent-requests.md" <<'EOF'
## Active Handoffs
### 2026-07-30 HO-9 — Ghost
**Type:** handoff
**Producer:** Developer
**Deliverable:** `does-not-exist.md`
**Status:** in-review
**Reviewers:**
- [ ] QA — pending

## Active Requests

## Resolved (Last 10)
EOF
t closeout-red-entry  muster-closeout.sh 1 "✗ entry bodies (fields + deliverables)" "ALL GREEN"
t closeout-notgreen   muster-closeout.sh 1 "NOT GREEN — fix the ✗ items"

echo "----"
if [ "$fails" -eq 0 ]; then echo "RESULT: $n/$n passed"; exit 0
else echo "RESULT: $((n-fails))/$n passed — $fails FAILED"; exit 1; fi
