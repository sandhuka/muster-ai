#!/usr/bin/env bash
# Muster — agent contract gate (the Guide / XO wiring).
#
# Asserts the DETERMINISTIC scaffold the Muster-agent behaviors stand on — the carve-out,
# MUSTER.md bind commands, the bind script, the status-line chain, the skills, the /muster front
# door. It does NOT (and cannot cheaply) test the model's judgment — whether a live session
# *chooses* to follow the carve-out, reads minimally, or ranks well. That layer needs a live run
# and only regresses when the driving prose (MUSTER.md, the skills, the carve-out wording)
# changes — not when plumbing does. This gate covers the plumbing, which is what future changes
# usually break.
#
# Public asserts run everywhere (incl. CI). The XO loadout lives in private/ (gitignored, a
# separate repo), so its asserts run only when private/xo/ is present — same guard pattern as the
# driver's caffeinate. Self-cleans on green; exits 1 on any failure.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FW="$(dirname "$SCRIPT_DIR")"
SB="$(mktemp -d "${TMPDIR:-/tmp}/muster-agent-test.XXXXXX")"
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }
no(){ echo "FAIL: $1"; fail=$((fail+1)); }
have(){ [ -f "$FW/$1" ]; }

# ─── Public: carve-out + MUSTER.md routing ───────────────────────────────────
grep -qi "framework-repo carve-out" "$FW/CLAUDE.md" \
  && ok "carve-out present in root CLAUDE.md" || no "carve-out missing from root CLAUDE.md"

have MUSTER.md && ok "MUSTER.md exists at repo root" || no "MUSTER.md missing at repo root"

grep -qF "muster-bind.sh xo interactive" "$FW/MUSTER.md" \
  && ok "MUSTER.md carries the XO bind command" || no "MUSTER.md lost the XO bind command"
grep -qF "muster-bind.sh guide interactive" "$FW/MUSTER.md" \
  && ok "MUSTER.md carries the Guide bind command" || no "MUSTER.md lost the Guide bind command"
grep -q "system-guide.md" "$FW/MUSTER.md" && grep -q "private/xo/MUSTER-XO.md" "$FW/MUSTER.md" \
  && ok "MUSTER.md home-detection keys intact" || no "MUSTER.md home-detection keys changed"

# ─── Public: bind script accepts guide|xo ────────────────────────────────────
grep -q "guide|xo)" "$FW/scripts/muster-bind.sh" \
  && ok "muster-bind.sh accepts guide + xo" || no "muster-bind.sh no longer accepts guide/xo"

# ─── Public: functional — bind writes the file + exits 0 without knowledge-base ─
( cd "$SB" && env CLAUDE_CODE_SESSION_ID=ctest bash "$FW/scripts/muster-bind.sh" xo interactive ) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && [ -f "$SB/.claude/.muster-bound-role.ctest" ] && [ "$(cat "$SB/.claude/.muster-bound-role.ctest")" = "xo" ] \
  && ok "bind writes the xo bind file + exits 0 (no knowledge-base)" || no "xo bind did not write file / exit 0 (rc=$rc)"

# ─── Public: functional — status-line chain renders the role ─────────────────
mkdir -p "$SB/.claude"; echo xo > "$SB/.claude/.muster-bound-role.s1"
brs="$(cd "$SB" && echo '{"session_id":"s1"}' | bash "$FW/scripts/muster-bound-role.sh")"
[ "$brs" = "xo" ] && ok "muster-bound-role.sh resolves role from stdin session_id" || no "muster-bound-role.sh output wrong: '$brs'"
sl="$(cd "$SB" && echo '{"session_id":"s1"}' | bash "$FW/templates/.claude/statusline.sh")"
echo "$sl" | grep -q "\[muster: xo\]" && ok "statusline.sh renders [muster: xo]" || no "statusline.sh did not render the role: '$sl'"

# ─── Public: guide skills + /muster front door ───────────────────────────────
for s in setup-coach operating-help config-knobs field-report migration-coach; do
  have "guide/skills/$s.md" && ok "guide skill present: $s" || no "guide skill missing: $s"
done
# config-knobs MUST instruct committing the edit — worktree sprints check out the committed tip,
# so an uncommitted .muster/config never reaches the run (regression guard for the worktree gap).
grep -q "git commit" "$FW/guide/skills/config-knobs.md" \
  && ok "config-knobs commits .muster/config (worktree-visible)" || no "config-knobs lost the commit step"
have templates/.claude/skills/muster/SKILL.md \
  && ok "/muster skill present" || no "/muster skill missing"
grep -q "MUSTER.md" "$FW/templates/.claude/skills/muster/SKILL.md" \
  && grep -q "muster-bound-role.sh" "$FW/templates/.claude/skills/muster/SKILL.md" \
  && ok "/muster references resolve (MUSTER.md + bound-role)" || no "/muster references changed"

# ─── Private: XO loadout (only when present) ──────────────────────────────────
if [ -d "$FW/private/xo" ]; then
  have private/xo/MUSTER-XO.md && ok "MUSTER-XO.md exists" || no "MUSTER-XO.md missing"
  for s in roi-doctrine triage release-discipline retro user-validation; do
    have "private/xo/skills/$s.md" && ok "XO skill present: $s" || no "XO skill missing: $s"
  done
  grep -qi "retro" "$FW/private/xo/MUSTER-XO.md" && grep -qi "field" "$FW/private/xo/MUSTER-XO.md" \
    && ok "MUSTER-XO.md lists bind-time duties" || no "MUSTER-XO.md bind-time duties changed"
  grep -qi "cross-load" "$FW/private/xo/MUSTER-XO.md" \
    && ok "MUSTER-XO.md cross-load rule intact" || no "MUSTER-XO.md cross-load rule missing"
  [ -d "$FW/private/xo/retros" ] && ok "retros/ output dir exists" || no "retros/ dir missing"
  have private/xo/scripts/xo-session-log.sh && ok "xo-session-log.sh present" || no "xo-session-log.sh missing"
else
  echo "·  private/xo absent — XO-loadout asserts skipped (public CI is expected here)"
fi

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed   (sandbox: $SB)"
if [ "$fail" -eq 0 ]; then rm -rf "$SB"; exit 0; else echo "(sandbox kept: $SB)"; exit 1; fi
