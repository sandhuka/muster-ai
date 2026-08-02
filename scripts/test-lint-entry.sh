#!/usr/bin/env bash
# test-lint-entry.sh — fixture gate for muster-lint-entry.sh (entry-body well-formedness).
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/muster-entry-test.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT

PROJ="$SBX/proj"
mkdir -p "$PROJ/muster/scripts" "$PROJ/knowledge-base/design-specs"
cp "$SRC/scripts/muster-lint-entry.sh" "$PROJ/muster/scripts/"
touch "$PROJ/muster/system-guide.md"
LINT="$PROJ/muster/scripts/muster-lint-entry.sh"

n=0; fails=0
t(){ local name="$1" wrc="$2" want="$3"
  n=$((n+1))
  local out rc; out="$(cd "$PROJ" && bash "$LINT" 2>&1)"; rc=$?
  if [ "$rc" = "$wrc" ] && printf '%s\n' "$out" | grep -qF -- "$want"; then echo "PASS: $name"
  else fails=$((fails+1)); echo "FAIL: $name (rc=$rc want=$wrc)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fi
}
board(){ cat > "$PROJ/knowledge-base/agent-requests.md"; }

# no board -> OK
rm -f "$PROJ/knowledge-base/agent-requests.md"
t no-board-ok 0 "OK: no board"

# seeded template (comments only) -> 0 entries
cp "$SRC/templates/knowledge-base/agent-requests.md" "$PROJ/knowledge-base/agent-requests.md"
t template-clean 0 "scanned 0 Active entr"

# well-formed request + handoff with real deliverable -> OK
touch "$PROJ/knowledge-base/design-specs/spec.md"
board <<'EOF'
## Active Requests
### 2026-07-30 REQ-01 — Ask
**Type:** request
**From:** QA
**To:** Developer
**Status:** open
**Request:** Do the thing.

## Active Handoffs
### 2026-07-30 HO-01 — Spec done
**Type:** handoff
**Producer:** UI/UX
**Deliverable:** `knowledge-base/design-specs/spec.md`
**Status:** in-review
**Reviewers:**
- [ ] Developer — pending

## Resolved (Last 10)
- 2026-07-01 HO-00 old one-liner (no fields — exempt)
EOF
t wellformed-ok 0 "OK: entry bodies well-formed"

# phantom deliverable -> FAIL
board <<'EOF'
## Active Handoffs
### 2026-07-30 HO-02 — Ghost
**Type:** handoff
**Producer:** Developer
**Deliverable:** `knowledge-base/design-specs/does-not-exist.md`
**Status:** in-review
**Reviewers:**
- [ ] QA — pending
EOF
t phantom-deliverable-fails 1 "Deliverable path not found on disk: knowledge-base/design-specs/does-not-exist.md"

# kb-relative path resolves under knowledge-base/ -> OK
board <<'EOF'
## Active Handoffs
### 2026-07-30 HO-03 — Relative
**Type:** handoff
**Producer:** Developer
**Deliverable:** `design-specs/spec.md`
**Status:** in-review
**Reviewers:**
- [ ] QA — pending
EOF
t kb-relative-resolves 0 "OK: entry bodies well-formed"

# missing fields -> FAIL naming them
board <<'EOF'
## Active Requests
### 2026-07-30 REQ-02 — Bare ask
**Type:** request
**To:** Developer
**Request:** Thing.
EOF
t missing-fields-fail 1 "request missing field(s): From Status"

# missing Type -> FAIL
board <<'EOF'
## Active Handoffs
### 2026-07-30 HO-04 — Untyped
**Producer:** Developer
**Status:** open
EOF
t missing-type-fails 1 "no **Type:** field"

# prose deliverable (no path) -> WARN only
board <<'EOF'
## Active Handoffs
### 2026-07-30 HO-05 — Prose deliverable
**Type:** handoff
**Producer:** Developer
**Deliverable:** the refactor is in the app repo
**Status:** in-review
**Reviewers:**
- [ ] QA — pending
EOF
t prose-deliverable-warns 0 "WARN: [2026-07-30 HO-05 — Prose deliverable] Deliverable has no extractable path"

echo "----"
if [ "$fails" -eq 0 ]; then echo "RESULT: $n/$n passed"; exit 0
else echo "RESULT: $((n-fails))/$n passed — $fails FAILED"; exit 1; fi
