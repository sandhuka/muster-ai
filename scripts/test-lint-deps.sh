#!/usr/bin/env bash
# test-lint-deps.sh — fixture gate for muster-lint-deps.sh (dependency mirroring).
# Proves it can FAIL (asymmetric sandbox graph, both directions) and PASS (mirrored graph,
# pm/founder exemptions, name normalization incl. "UI/UX agent" vs ui-ux).
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/muster-deps-test.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT

mk(){ mkdir -p "$SBX/team/$1"; cat > "$SBX/team/$1/CLAUDE.md"; }
run(){ bash "$SRC/scripts/muster-lint-deps.sh" "$SBX/team" 2>&1; }

n=0; fails=0
t(){ local name="$1" wrc="$2" want="$3"
  n=$((n+1))
  local out rc; out="$(run)"; rc=$?
  if [ "$rc" = "$wrc" ] && printf '%s\n' "$out" | grep -qF -- "$want"; then echo "PASS: $name"
  else fails=$((fails+1)); echo "FAIL: $name (rc=$rc want=$wrc)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fi
}

# symmetric graph with pm/founder edges and UI/UX display-name -> OK
mk qa <<'EOF'
# QA
- Depends on: UI/UX agent — visual states
- Depends on: PM — acceptance criteria
- Provides to: Developer agent — bug reports
EOF
mk ui-ux <<'EOF'
# UI/UX
- Provides to: QA agent — visual states
- Depends on: Founder — component library
EOF
mk developer <<'EOF'
# Developer
- Depends on: QA agent — bug reports
EOF
t symmetric-ok 0 "OK: dependency graph is symmetric"

# break one direction: remove developer's depends -> FAIL names the exact missing line
mk developer <<'EOF'
# Developer
EOF
t missing-dep-mirror 1 "qa provides to developer, but"
# break the other: qa depends on ui-ux, ui-ux no longer provides
mk developer <<'EOF'
# Developer
- Depends on: QA agent — bug reports
EOF
mk ui-ux <<'EOF'
# UI/UX
- Depends on: Founder — component library
EOF
t missing-prov-mirror 1 "qa depends on ui-ux, but"
t names-target-file 1 "ui-ux/CLAUDE.md has no '- Provides to: qa' line"

# live framework corpus is green (the same check CI runs)
n=$((n+1))
if bash "$SRC/scripts/muster-lint-deps.sh" >/dev/null 2>&1; then echo "PASS: live-corpus-symmetric"
else echo "FAIL: live-corpus-symmetric"; fails=$((fails+1)); fi

echo "----"
if [ "$fails" -eq 0 ]; then echo "RESULT: $n/$n passed"; exit 0
else echo "RESULT: $((n-fails))/$n passed — $fails FAILED"; exit 1; fi
