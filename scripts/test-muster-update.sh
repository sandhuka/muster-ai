#!/usr/bin/env bash
# test-muster-update.sh — fixture gate for muster-update.sh (the post-bump converge command).
# Proves the stale -> converged -> idempotent-no-op arc, dirty-tree refusal (with the muster/
# submodule pointer exempt — bump-then-update must stay legal), user-content preservation
# (CLAUDE.md project sections, settings keys + entries, user-added skills), missing-stub
# creation (a new role is just another reseed), rollback warning, and --dry-run inertness.
# Runs in a throwaway git sandbox — never touches the real repo.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/muster-update-test.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }
no(){ echo "FAIL: $1"; fail=$((fail+1)); }

command -v jq >/dev/null 2>&1 || { echo "FAIL: jq required for this fixture"; exit 1; }

# ---- sandbox: a stale project (old seeded files) with a current muster/ tree ----
PROJ="$SBX/proj"
mkdir -p "$PROJ/muster/scripts" "$PROJ/.claude/agents" "$PROJ/.claude/skills/muster" \
         "$PROJ/.claude/skills/custom" "$PROJ/knowledge-base" "$PROJ/.muster"
cp -R "$SRC/templates" "$PROJ/muster/templates"
cp "$SRC/scripts/muster-update.sh" "$PROJ/muster/scripts/"
echo "9.9.9-test" > "$PROJ/muster/VERSION"

# stale seeded state: 7 old stubs (research.md missing -> creation case), old statusline/skill
for r in pm developer ui-ux qa content marketing legal; do echo "old stub" > "$PROJ/.claude/agents/$r.md"; done
echo "old statusline" > "$PROJ/.claude/statusline.sh"
echo "old skill" > "$PROJ/.claude/skills/muster/SKILL.md"
echo "my own skill" > "$PROJ/.claude/skills/custom/SKILL.md"
# CLAUDE.md: OLD bootstrap block between markers + founder-authored project content
{ echo '<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->'
  echo 'OLD BOOTSTRAP LINE'
  echo '<!-- END BOOTSTRAP -->'
  echo '# My Product'
  echo 'FOUNDER RULE: never delete this line'
} > "$PROJ/CLAUDE.md"
printf '%s\n' '{"permissions":{"allow":["Bash(my-own-tool)"]},"model":"my-choice"}' > "$PROJ/.claude/settings.json"
echo "0.1.0" > "$PROJ/.muster/seeded-version"
( cd "$PROJ" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm seed )

UP="muster/scripts/muster-update.sh"
run(){ (cd "$PROJ" && env HOME="$SBX/home" bash "$UP" "$@" 2>&1); }
mkdir -p "$SBX/home"   # empty HOME -> no user-level settings interference

# ---- 1. dirty-tree refusal (project dirt blocks; nothing changes) ----
echo "wip" > "$PROJ/knowledge-base/notes.md"
out="$(run)"; rc=$?
[ "$rc" -ne 0 ] && echo "$out" | grep -q "uncommitted changes" && [ "$(cat "$PROJ/.claude/agents/pm.md")" = "old stub" ] \
  && ok "dirty tree refused, nothing touched" || no "dirty-tree refusal broken (rc=$rc)"
rm "$PROJ/knowledge-base/notes.md"

# ---- 2. muster/ dirt is exempt (bump-then-update flow) + dry-run inertness ----
echo "bumped" > "$PROJ/muster/bump-marker"
before="$(cd "$PROJ" && find .claude CLAUDE.md .muster -type f -exec cat {} + | cksum)"
out="$(run --dry-run)"; rc=$?
after="$(cd "$PROJ" && find .claude CLAUDE.md .muster -type f -exec cat {} + | cksum)"
[ "$rc" -eq 0 ] && [ "$before" = "$after" ] && echo "$out" | grep -q "Dry run complete" \
  && ok "muster/ dirt exempt; --dry-run changes nothing" || no "dry-run/muster-exempt broken (rc=$rc)"

# ---- 3. the converge run ----
out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || no "converge run failed (rc=$rc): $out"
allok=1
for r in pm developer ui-ux qa content marketing legal research; do
  cmp -s "$PROJ/.claude/agents/$r.md" "$SRC/templates/.claude/agents/$r.md" || { allok=0; no "stub $r.md not converged"; }
done
[ "$allok" -eq 1 ] && ok "all 8 stubs converged (incl. missing research.md created)"
cmp -s "$PROJ/.claude/statusline.sh" "$SRC/templates/.claude/statusline.sh" \
  && [ -x "$PROJ/.claude/statusline.sh" ] && ok "statusline stub converged + executable" || no "statusline stub wrong"
cmp -s "$PROJ/.claude/skills/muster/SKILL.md" "$SRC/templates/.claude/skills/muster/SKILL.md" \
  && ok "seeded skill converged" || no "seeded skill not converged"
[ -f "$PROJ/.claude/skills/rebind/SKILL.md" ] && ok "missing seeded skill created" || no "rebind skill not created"
[ "$(cat "$PROJ/.claude/skills/custom/SKILL.md")" = "my own skill" ] && ok "user skill untouched" || no "user skill clobbered"
grep -q "FOUNDER RULE: never delete this line" "$PROJ/CLAUDE.md" && ! grep -q "OLD BOOTSTRAP LINE" "$PROJ/CLAUDE.md" \
  && grep -q "muster-boot.sh" "$PROJ/CLAUDE.md" \
  && ok "CLAUDE.md block replaced, founder sections preserved" || no "CLAUDE.md sync wrong"
jq -e '.model == "my-choice" and (.permissions.allow | index("Bash(my-own-tool)"))' "$PROJ/.claude/settings.json" >/dev/null \
  && ok "user settings key + entry preserved" || no "user settings clobbered"
tcount="$(jq '.permissions.allow | length' "$SRC/templates/.claude/settings.json")"
mcount="$(jq --argjson t "$(jq '.permissions.allow' "$SRC/templates/.claude/settings.json")" \
  '($t - (.permissions.allow // [])) | length' "$PROJ/.claude/settings.json")"
[ "$mcount" = "0" ] && ok "all $tcount template pre-approvals merged" || no "$mcount template entries missing after merge"
grep -qxF "knowledge-base/.muster-boot-log" "$PROJ/.gitignore" && ok "gitignore boot-log entry" || no "gitignore entry missing"
[ "$(cat "$PROJ/.muster/seeded-version")" = "9.9.9-test" ] && ok "stamp written last (9.9.9-test)" || no "stamp wrong: $(cat "$PROJ/.muster/seeded-version" 2>/dev/null)"

# ---- 4. idempotence: second run is a clean no-op ----
( cd "$PROJ" && git add -A && git -c user.email=t@t -c user.name=t commit -qm converge )
before="$(cd "$PROJ" && find .claude CLAUDE.md .muster .gitignore -type f -exec cat {} + | cksum)"
out="$(run)"; rc=$?
after="$(cd "$PROJ" && find .claude CLAUDE.md .muster .gitignore -type f -exec cat {} + | cksum)"
[ "$rc" -eq 0 ] && [ "$before" = "$after" ] && echo "$out" | grep -q "Current." \
  && ok "idempotent: re-run is a no-op reporting Current" || no "idempotence broken (rc=$rc)"

# ---- 5. rollback warning (stamp newer than muster/VERSION) ----
echo "1.0.0" > "$PROJ/muster/VERSION"
( cd "$PROJ" && git add -A >/dev/null 2>&1; git -c user.email=t@t -c user.name=t commit -qam ver >/dev/null 2>&1 )
out="$(run)"; rc=$?
echo "$out" | grep -q "rollback" && [ "$rc" -eq 0 ] && [ "$(cat "$PROJ/.muster/seeded-version")" = "1.0.0" ] \
  && ok "rollback warned, converged anyway, stamp follows" || no "rollback path wrong (rc=$rc)"

# ---- 6. missing markers -> ✗ step, exit 1, stamp NOT advanced ----
( cd "$PROJ" && git -c user.email=t@t -c user.name=t commit -qam pre-marker >/dev/null 2>&1 )
grep -v "MUSTER BOOTSTRAP" "$PROJ/CLAUDE.md" > "$PROJ/CLAUDE.md.t" && mv "$PROJ/CLAUDE.md.t" "$PROJ/CLAUDE.md"
( cd "$PROJ" && git -c user.email=t@t -c user.name=t commit -qam drop-marker >/dev/null 2>&1 )
echo "5.5.5" > "$PROJ/muster/VERSION"
out="$(run)"; rc=$?
[ "$rc" -ne 0 ] && echo "$out" | grep -q "missing the BOOTSTRAP markers" \
  && [ "$(cat "$PROJ/.muster/seeded-version")" = "1.0.0" ] \
  && ok "marker loss: ✗ + exit 1 + stamp held back (NOTICE stays alive)" || no "marker-failure path wrong (rc=$rc)"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && exit 0 || exit 1
