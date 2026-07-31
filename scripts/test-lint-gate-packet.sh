#!/usr/bin/env bash
# test-lint-gate-packet.sh — fixture gate for muster-lint-gate-packet.sh (notice fold-in).
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/muster-gate-test.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT

PROJ="$SBX/proj"
mkdir -p "$PROJ/muster/scripts" "$PROJ/knowledge-base"
cp "$SRC/scripts/muster-lint-gate-packet.sh" "$PROJ/muster/scripts/"
touch "$PROJ/muster/system-guide.md"
LINT="$PROJ/muster/scripts/muster-lint-gate-packet.sh"

n=0; fails=0
t(){ local name="$1" wrc="$2" want="$3"
  n=$((n+1))
  local out rc; out="$(cd "$PROJ" && bash "$LINT" 2>&1)"; rc=$?
  if [ "$rc" = "$wrc" ] && printf '%s\n' "$out" | grep -qF -- "$want"; then echo "PASS: $name"
  else fails=$((fails+1)); echo "FAIL: $name (rc=$rc want=$wrc)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fi
}
wr(){ cat > "$PROJ/knowledge-base/wave-review.md"; }
fn(){ cat > "$PROJ/knowledge-base/founder-notices.md"; }

# no packet file -> OK
t no-packet-ok 0 "OK: no wave-review packet"

# seeded template (placeholder Wave) -> inactive, OK
cp "$SRC/templates/knowledge-base/wave-review.md" "$PROJ/knowledge-base/wave-review.md"
t template-inactive-ok 0 "OK: no active gate"

# active gate with scaffold, no notices -> OK
wr <<'EOF'
## Current Wave
**Wave:** 3 — recovery map
**Verify (human-only checks):**
- [ ] tap through the map
### Notices since last gate
none
EOF
t active-clean-ok 0 "OK: gate packet carries the notices scaffold"

# active gate, scaffold missing -> FAIL
wr <<'EOF'
## Current Wave
**Wave:** 3 — recovery map
**Verify (human-only checks):**
- [ ] tap through the map
EOF
t missing-scaffold-fails 1 "no '### Notices since last gate' heading"

# live notice folded verbatim -> OK
fn <<'EOF'
<!-- channel comment with - 2020-01-01 fake bullet inside -->
- 2026-07-30 marketing: ASO experiment lands at step 9
EOF
wr <<'EOF'
## Current Wave
**Wave:** 3 — recovery map
### Notices since last gate
- 2026-07-30 marketing: ASO experiment lands at step 9
EOF
t notice-folded-ok 0 "OK: gate packet carries the notices scaffold and every live notice"

# live notice NOT folded -> FAIL naming it
wr <<'EOF'
## Current Wave
**Wave:** 3 — recovery map
### Notices since last gate
none
EOF
t notice-missing-fails 1 "FAIL: live notice not folded into the gate packet verbatim: - 2026-07-30 marketing: ASO experiment lands at step 9"

echo "----"
if [ "$fails" -eq 0 ]; then echo "RESULT: $n/$n passed"; exit 0
else echo "RESULT: $((n-fails))/$n passed — $fails FAILED"; exit 1; fi
