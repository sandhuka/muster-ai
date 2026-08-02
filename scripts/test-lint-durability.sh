#!/usr/bin/env bash
# test-lint-durability.sh — fixture gate for muster-lint-durability.sh (Rule 15).
# Pins the two-tier design (IDs/sprint-refs/date-bullets FAIL; phrasings WARN-only — a live
# corpus proved "added for" appears in legitimate current-truth prose) and the code-span skips.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/muster-dur-test.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT

PROJ="$SBX/proj"
mkdir -p "$PROJ/muster/scripts" "$PROJ/knowledge-base/design-specs" "$PROJ/knowledge-base/agent-skills/qa"
cp "$SRC/scripts/muster-lint-durability.sh" "$PROJ/muster/scripts/"
touch "$PROJ/muster/system-guide.md"
LINT="$PROJ/muster/scripts/muster-lint-durability.sh"

n=0; fails=0
t(){ # $1=name $2=want-exit $3=grep-must-appear ('' = skip)
  local name="$1" wrc="$2" want="$3"
  n=$((n+1))
  local out rc; out="$(cd "$PROJ" && bash "$LINT" 2>&1)"; rc=$?
  if [ "$rc" = "$wrc" ] && { [ -z "$want" ] || printf '%s\n' "$out" | grep -qF -- "$want"; }; then echo "PASS: $name"
  else fails=$((fails+1)); echo "FAIL: $name (rc=$rc want=$wrc)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fi
}

# no durable files at all -> OK
t empty-project 0 "OK: no durable knowledge-base files"

# clean current-truth docs -> OK, count reported
cat > "$PROJ/knowledge-base/product-spec.md" <<'EOF'
# Product Spec
The app assembles workouts from the exercise library. Recovery drives progression.
EOF
cat > "$PROJ/knowledge-base/architecture.md" <<'EOF'
# Architecture
The engine is a pure function over history. New rows added for new dimension values get keys.
EOF
t clean-docs-ok 0 "OK: durability discipline clean"
t warn-counted 0 "1 WARN"

# transient IDs -> FAIL
cat > "$PROJ/knowledge-base/design-specs/screen.md" <<'EOF'
# Screen
Layout revised per HO-212 feedback.
EOF
t id-fails 1 "FAIL: knowledge-base/design-specs/screen.md:2 — transient ID"

# sprint/wave refs + date bullets -> FAIL
cat > "$PROJ/knowledge-base/design-specs/screen.md" <<'EOF'
# Screen
Built in Sprint 9 as part of Wave 2.
- 2026-07-30: adjusted padding per review.
EOF
t sprint-ref-fails 1 "sprint/wave reference"
t date-bullet-fails 1 "date-stamped edit bullet"

# fenced code + inline code spans are skipped
cat > "$PROJ/knowledge-base/design-specs/screen.md" <<'EOF'
# Screen
Current truth only here.
```
Example entry format: - 2026-01-01 HO-999 Sprint 4 (template sample)
```
The board file uses `HO-NNN` identifiers.
EOF
t code-skipped 0 "OK: durability discipline clean"

# agent-skills tree is scanned
cat > "$PROJ/knowledge-base/agent-skills/qa/matrix.md" <<'EOF'
# Matrix
Regression rows trace to BUG-14.
EOF
t agent-skills-scanned 1 "FAIL: knowledge-base/agent-skills/qa/matrix.md:2 — transient ID"
rm -f "$PROJ/knowledge-base/agent-skills/qa/matrix.md"

# phrasings alone -> WARN, exit 0
cat > "$PROJ/knowledge-base/design-specs/screen.md" <<'EOF'
# Screen
Previously the header was tall; now it is compact.
EOF
t phrasing-warns-only 0 'WARN: knowledge-base/design-specs/screen.md:2 — "previously - now"'

echo "----"
if [ "$fails" -eq 0 ]; then echo "RESULT: $n/$n passed"; exit 0
else echo "RESULT: $((n-fails))/$n passed — $fails FAILED"; exit 1; fi
