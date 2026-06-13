#!/usr/bin/env bash
# Muster — migration regression gate.
#
# Scope: v3→v4 ONLY — the live upgrade path (existing v3/v4 projects adopting the
# current release; the script also doubles as "bring KB current"). v1→v2 and v2→v3
# are finite, historical populations (no new project can ever land there) and are
# deliberately NOT gated — gating a run-once path is maintenance with no ongoing payoff.
#
# Builds a throwaway "v3 project" (the framework repo symlinked in as the submodule),
# runs migrate-v3-to-v4.sh against it, and asserts: dry-run safety, copy-if-absent
# seeding (founder-notices.md + .muster/config), preservation of existing content,
# idempotency, and no-clobber of a user's customized config.
#
# Self-cleans on green; keeps the sandbox on failure for inspection.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FW="$(dirname "$SCRIPT_DIR")"
SB="$(mktemp -d "${TMPDIR:-/tmp}/muster-migrate-test.XXXXXX")"
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }
no(){ echo "FAIL: $1"; fail=$((fail+1)); }

# --- build a fake v3 project: submodule = the real framework repo ---
cd "$SB" || { echo "cannot enter sandbox"; exit 2; }
ln -s "$FW" muster
printf '# Test Project\n' > CLAUDE.md
mkdir -p knowledge-base
printf 'existing\n' > knowledge-base/product-spec.md   # must be PRESERVED
# deliberately MISSING: founder-notices.md, and no .muster/config

# --- 1. dry-run touches nothing but reports both new seeds ---
out="$(bash muster/scripts/migrate-v3-to-v4.sh --dry-run 2>&1)"
[ ! -f knowledge-base/founder-notices.md ] && ok "dry-run did not create founder-notices.md" || no "dry-run created founder-notices.md"
[ ! -e .muster/config ] && ok "dry-run did not create .muster/config" || no "dry-run created .muster/config"
echo "$out" | grep -q "founder-notices.md" && ok "dry-run reports founder-notices.md" || no "dry-run silent on founder-notices.md"
echo "$out" | grep -q ".muster/config" && ok "dry-run reports .muster/config" || no "dry-run silent on .muster/config"

# --- 2. real run seeds both, preserves existing ---
bash muster/scripts/migrate-v3-to-v4.sh >/dev/null 2>&1
[ -f knowledge-base/founder-notices.md ] && ok "real run seeded founder-notices.md" || no "founder-notices.md not seeded"
[ -f .muster/config ] && ok "real run seeded .muster/config" || no ".muster/config not seeded"
[ "$(cat knowledge-base/product-spec.md)" = "existing" ] && ok "existing kb file preserved" || no "existing kb file clobbered"
diff -q .muster/config muster/templates/.muster/config >/dev/null 2>&1 && ok ".muster/config matches template" || no ".muster/config differs from template"

# --- 3. idempotency: second run copies nothing ---
out2="$(bash muster/scripts/migrate-v3-to-v4.sh 2>&1)"
echo "$out2" | grep -qi "already present" && ok "idempotent: reports already-present" || no "idempotent run did not report already-present"

# --- 4. no-clobber: a user's customized config survives a re-run ---
printf 'MAX_STEPS=99 # user custom\n' > .muster/config
bash muster/scripts/migrate-v3-to-v4.sh >/dev/null 2>&1
grep -q "user custom" .muster/config && ok "no-clobber: user .muster/config preserved" || no "user .muster/config was clobbered"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed   (sandbox: $SB)"
if [ "$fail" -eq 0 ]; then
    rm -rf "$SB"
    exit 0
else
    echo "(sandbox kept for inspection: $SB)"
    exit 1
fi
