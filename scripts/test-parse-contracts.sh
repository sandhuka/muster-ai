#!/usr/bin/env bash
# test-parse-contracts.sh — the anchor-contract floor (CI gate).
#
# Scripts parse files by grepping for ANCHORS (section headings, markers, JSON keys). A script
# is only as safe as the guarantee that its anchors exist in the files it parses — and the
# files every project starts from are the templates. This gate pins each (anchor -> template)
# pair and names the consuming script, so renaming a section or reshaping a template breaks CI
# with a message that says which script contract it just broke, instead of silently breaking
# every project seeded afterward.
#
# EXTENSION RULE (add here whenever a script gains a new anchor): one `need` line per anchor,
# consumer script(s) named in the comment. A fleet-wide audit of pre-existing scripts' anchors
# is planned as its own wave — this file is where its findings land.
set -uo pipefail
cd "$(dirname "$0")/.."

pass=0; fail=0
need(){ # $1=file $2=literal anchor $3=consumers
  if grep -qF -- "$2" "$1" 2>/dev/null; then
    pass=$((pass+1)); echo "PASS: $1 ⊃ '$2'  ($3)"
  else
    fail=$((fail+1)); echo "FAIL: $1 lost anchor '$2' — breaks: $3"
  fi
}

Q=templates/knowledge-base/orchestration-queue.md
need "$Q" '## Next Step'         "muster-read-queue.sh (driver+boot+advance), muster-queue-lint.sh"
need "$Q" '## Upcoming'          "muster-read-queue.sh section boundary, muster-advance-queue.sh promotion"
need "$Q" '## Done'              "muster-advance-queue.sh insertion+cap, muster-lint-handoff.sh recent-entry"
need "$Q" '## Founder Decisions' "muster-boot.sh notice_line, muster-sprint-run.sh mid-run alert"

R=templates/knowledge-base/agent-requests.md
need "$R" '## Active Requests'   "muster-list-open-items.sh (both modes)"
need "$R" '## Active Handoffs'   "muster-list-open-items.sh (both modes), muster-requests-lint.sh"
need "$R" '## Resolved'          "muster-lint-handoff.sh resolved-bullet scan, muster-requests-lint.sh"

P=templates/knowledge-base/agent-context/.populated
need "$P" '"onboarded_at"'            "muster-boot.sh routing (muster-read-populated.sh)"
need "$P" '"onboarding_complete_at"'  "muster-boot.sh routing (muster-read-populated.sh)"
need "$P" '"agents"'                  "muster-boot.sh JIT gate, muster-check-context.sh"
for role in pm developer ui-ux qa content marketing legal research; do
  need "$P" "\"$role\"" "muster-check-context.sh $role, muster-boot.sh JIT gate"
done

for role in pm developer ui-ux qa content marketing legal research; do
  need "templates/knowledge-base/agent-context/$role.md" '## Current Tasks' "muster-lint-context.sh section scan"
done
need templates/knowledge-base/agent-context/developer.md 'current-sprint.md` for current sprint tasks' "muster-lint-context.sh pointer-ish classification (representative seed wording)"

# File-level contracts: muster-lint-durability.sh scans a NAMED durable set — if a template is
# renamed, new projects silently leave the lint's scope. Pin the seeded names that exist as
# templates (migration-path.md and design-specs/ are project-created, not seeded — not pinned).
needfile(){
  if [ -f "$1" ]; then pass=$((pass+1)); echo "PASS: $1 exists  ($2)"
  else fail=$((fail+1)); echo "FAIL: $1 missing/renamed — breaks: $2"; fi
}
for f in product-spec.md architecture.md foundational-assumptions.md brand-guidelines.md \
         brand-voice-guide.md test-strategy.md design-patterns.md; do
  needfile "templates/knowledge-base/$f" "muster-lint-durability.sh durable-set scope"
done

C=templates/CLAUDE.md
need "$C" '<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->' "add-bootstrap-permissions.sh block replacement"
need "$C" '<!-- END BOOTSTRAP -->'                    "add-bootstrap-permissions.sh block replacement"
need "$C" 'muster-boot.sh'                            "the bootstrap itself — seeded first tool call"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
