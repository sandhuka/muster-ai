#!/usr/bin/env bash
# test-pillar-budgets.sh — deterministic regression gate on the always-read (tier-1) surface.
# Token cost lives at READ time: every line on this surface is rent paid by every session in
# every project, forever. The pillar (less token burning, better results, by design) is
# statically measurable, so it is guarded mechanically — the fixed-cost audit converted from
# prose duty to release gate. Second slice of the framework regression suite; runs with the
# driver fixture (scripts/test-sprint-driver.sh) before any release.
#
# Budgets = size at encoding time + ~10% headroom: green at birth, red on GROWTH. A red check
# means either (a) move the addition to an on-demand skill/doc — the usual right answer — or
# (b) consciously raise the budget HERE in the same commit and justify it in the commit message.
set -uo pipefail
cd "$(dirname "$0")/.."

pass=0; fail=0
ok(){   echo "PASS: $1"; pass=$((pass+1)); }
bad(){  echo "FAIL: $1"; fail=$((fail+1)); }
lines(){ wc -l < "$1" 2>/dev/null | tr -d ' '; }

check_lines(){ # $1=file $2=line-budget — missing file is a hard fail (fail-closed)
  local n; n="$(lines "$1")"
  if [ -z "$n" ]; then bad "$1 — missing"; return; fi
  if [ "$n" -le "$2" ]; then ok "$1 — $n/$2 lines"; else bad "$1 — $n lines exceeds budget $2"; fi
}

# --- always-read project surface (shipped templates) ---
check_lines templates/CLAUDE.md 40
for f in templates/.claude/agents/*.md; do
  check_lines "$f" 51                       # largest bootloader (pm, 46) + 10%
done

# --- always-read KB templates (read at bind/monitoring time in every project) ---
check_lines templates/knowledge-base/orchestration-queue.md 73
check_lines templates/knowledge-base/agent-requests.md 44
check_lines templates/knowledge-base/current-sprint.md 44
check_lines templates/knowledge-base/decision-log.md 18
check_lines templates/knowledge-base/founder-notices.md 11
check_lines templates/knowledge-base/ui-component-requests.md 26
check_lines templates/knowledge-base/pre-launch-checklist.md 14
check_lines templates/knowledge-base/foundational-assumptions.md 18

# --- MUSTER.md (loaded on every /muster invocation) ---
check_lines MUSTER.md 120                   # the build-time hard budget, kept as the gate

# --- the driver's wrapper prompt (sent with EVERY autonomous step) ---
# End anchor is the prompt's pipe-to-formatter line, NOT a phrase inside the prompt: the prompt's
# tail wraps "no new queue \\ steps)." across a line-continuation, so the old /no new queue steps/
# anchor never matched and the range silently ran to EOF — measuring prompt + the entire rest of
# the script. Anchor on `bash "$FMT"` (the line where the prompt string closes and pipes out) so
# the range is bounded to the prompt regardless of what's added below it.
wp_chars="$(awk '/Execute the current Next Step/,/bash "\$FMT"/' scripts/muster-sprint-run.sh | wc -c | tr -d ' ')"
if [ "${wp_chars:-0}" -eq 0 ]; then
  bad "wrapper prompt — extraction found nothing (driver text moved? update the awk range)"
elif [ "$wp_chars" -le 1800 ]; then
  ok "wrapper prompt — $wp_chars/1800 chars"
else
  bad "wrapper prompt — $wp_chars chars exceeds budget 1800"
fi

# --- tier-1 bind-path total (CLAUDE.md Rule 14: PM bootstrap reads ≤ 600 lines) ---
# Static proxy at template level: project CLAUDE.md + pm bootloader + PM brain + the 8
# PM-monitored KB templates. Runtime growth inside a project is Rule 14's own archiving job;
# this guards the SHIPPED baseline so projects don't start life over budget.
t1=0
for f in templates/CLAUDE.md templates/.claude/agents/pm.md team/pm/CLAUDE.md \
         templates/knowledge-base/orchestration-queue.md \
         templates/knowledge-base/agent-requests.md \
         templates/knowledge-base/current-sprint.md \
         templates/knowledge-base/decision-log.md \
         templates/knowledge-base/founder-notices.md \
         templates/knowledge-base/ui-component-requests.md \
         templates/knowledge-base/pre-launch-checklist.md \
         templates/knowledge-base/foundational-assumptions.md; do
  n="$(lines "$f")"
  if [ -z "$n" ]; then bad "tier-1 path — $f missing"; n=0; fi
  t1=$((t1 + n))
done
if [ "$t1" -le 600 ]; then ok "tier-1 bind-path total — $t1/600 lines"; else bad "tier-1 bind-path total — $t1 lines exceeds Rule 14's 600"; fi

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
exit 0
