#!/usr/bin/env bash
# test-lint-decisions.sh — fixture gate for muster-lint-decisions.sh (Rule 11 reconciliation).
# Pins: both live entry formats, whole-entry coverage (not Touched-only), capitalized-role
# extraction, "All agents" expansion, stub exemption, WARN-only path resolution.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/muster-dec-test.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT

PROJ="$SBX/proj"
mkdir -p "$PROJ/muster/scripts" "$PROJ/knowledge-base/agent-context"
for s in muster-lint-decisions.sh muster-read-populated.sh; do cp "$SRC/scripts/$s" "$PROJ/muster/scripts/"; done
touch "$PROJ/muster/system-guide.md"
LINT="$PROJ/muster/scripts/muster-lint-decisions.sh"

pop(){ # $1 = legal value (stub knob); everything else populated
  cat > "$PROJ/knowledge-base/agent-context/.populated" <<EOF
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
    "legal": $1,
    "pm": "2026-01-01"
  },
  "lock": null
}
EOF
}
pop '"2026-01-01"'
dl(){ cat > "$PROJ/knowledge-base/decision-log.md"; }

n=0; fails=0
t(){ # $1=name $2=want-exit $3=grep-must ('' skip) $4=grep-must-NOT ('' skip)
  local name="$1" wrc="$2" want="$3" nowant="$4"
  n=$((n+1))
  local out rc; out="$(cd "$PROJ" && bash "$LINT" 2>&1)"; rc=$?
  local ok=1
  [ "$rc" = "$wrc" ] || ok=0
  [ -n "$want" ] && { printf '%s\n' "$out" | grep -qF -- "$want" || ok=0; }
  [ -n "$nowant" ] && { printf '%s\n' "$out" | grep -qF -- "$nowant" && ok=0; }
  if [ "$ok" = 1 ]; then echo "PASS: $name"
  else fails=$((fails+1)); echo "FAIL: $name (rc=$rc want=$wrc)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fi
}

# no log -> OK
rm -f "$PROJ/knowledge-base/decision-log.md"
t no-log-ok 0 "OK: no decision log" ""

# seeded template (commented ENTRY TEMPLATE only) -> 0 entries, clean
cp "$SRC/templates/knowledge-base/decision-log.md" "$PROJ/knowledge-base/decision-log.md"
t template-clean 0 "scanned 0 decision entr" ""

# template format, fully reconciled -> OK
dl <<'EOF'
# Decision Log
## Active Decisions
### DEC-001 — Pick blue (2026-07-30)
**Decision**: Blue.
**Rationale**: Calm.
**Impact**: Developer, UI/UX.
**Touched**: `agent-context/developer.md`, `agent-context/ui-ux.md`, `product-spec.md`
EOF
touch "$PROJ/knowledge-base/product-spec.md"
mkdir -p "$PROJ/knowledge-base/agent-context"; touch "$PROJ/knowledge-base/agent-context/developer.md" "$PROJ/knowledge-base/agent-context/ui-ux.md"
t template-format-ok 0 "OK: decision reconciliation clean" ""

# missing field -> FAIL
dl <<'EOF'
### DEC-002 — Half entry (2026-07-30)
**Decision**: Something.
**Impact**: Developer.
**Touched**: `agent-context/developer.md`
EOF
t missing-field-fails 1 "missing field(s): Rationale" ""

# Impact names role, no coverage anywhere -> FAIL naming it
dl <<'EOF'
### DEC-003 — Uncascaded (2026-07-30)
**Decision**: X.
**Rationale**: Y.
**Impact**: Developer and QA are affected.
**Touched**: `product-spec.md`
EOF
t uncovered-role-fails 1 "Impact names developer but no agent-context/developer" ""

# coverage recorded OUTSIDE Touched (hardening-note style) -> OK
dl <<'EOF'
### DEC-004 — Fixed late (2026-07-30)
**Decision**: X.
**Rationale**: Y.
**Impact**: QA.
**Touched**: `product-spec.md`
- **Second-pass**: swept `agent-context/qa.md` too (missed in first pass).
EOF
t whole-entry-coverage-ok 0 "OK: decision reconciliation clean" ""

# dated-bold live format + All agents with one non-stub missing -> FAIL only that role
dl <<'EOF'
**2026-07-18 — Sprint chartered**
- **Decision**: Plan.
- **Rationale**: Evidence.
- **Impact**: All agents — cascaded.
- **Touched**: `agent-context/pm.md`, `agent-context/developer.md`, `agent-context/ui-ux.md`, `agent-context/qa.md`, `agent-context/content.md`, `agent-context/marketing.md`, `agent-context/research.md`
EOF
t all-agents-missing-legal 1 "Impact names legal" ""
# same entry, legal is a STUB -> exempt, clean
pop null
t stub-exempt-ok 0 "OK: decision reconciliation clean" "Impact names legal"
pop '"2026-01-01"'

# lowercase noun "content" in Impact does not trigger the Content role
dl <<'EOF'
### DEC-005 — Copy tweak (2026-07-30)
**Decision**: X.
**Rationale**: Y.
**Impact**: Developer (the content of the file changes).
**Touched**: `agent-context/developer.md`
EOF
t noun-content-ignored 0 "OK: decision reconciliation clean" "Impact names content"

# unresolvable Touched path -> WARN, exit 0
dl <<'EOF'
### DEC-006 — Renamed later (2026-07-30)
**Decision**: X.
**Rationale**: Y.
**Impact**: Developer.
**Touched**: `agent-context/developer.md`, `old-name-gone.md`
EOF
t touched-path-warns 0 "WARN: Touched path not found on disk: old-name-gone.md" ""

echo "----"
if [ "$fails" -eq 0 ]; then echo "RESULT: $n/$n passed"; exit 0
else echo "RESULT: $((n-fails))/$n passed — $fails FAILED"; exit 1; fi
