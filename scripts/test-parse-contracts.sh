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
# consumer script(s) named in the comment. Enforced mechanically at the bottom of this file:
# every fleet script must appear here — as a consumer of pinned anchors, or in the NO_ANCHOR
# roster (scripts whose contracts are vendor schemas, git state, or the filesystem — those are
# pinned by their FIXTURES, not by template anchors). A new script registers or consciously
# exempts itself in the same commit; there is no third option.
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
need "$Q" '## Next Step'         "muster-read-queue.sh (driver+boot+advance), muster-lint-queue.sh"
need "$Q" '## Upcoming'          "muster-read-queue.sh section boundary, muster-advance-queue.sh promotion"
need "$Q" '## Done'              "muster-advance-queue.sh insertion+cap, muster-lint-handoff.sh recent-entry"
need "$Q" '## Founder Decisions' "muster-boot.sh notice_line, muster-sprint-run.sh mid-run alert"

R=templates/knowledge-base/agent-requests.md
need "$R" '## Active Requests'   "muster-list-open-items.sh (both modes)"
need "$R" '## Active Handoffs'   "muster-list-open-items.sh (both modes), muster-lint-requests.sh"
need "$R" '## Resolved'          "muster-lint-handoff.sh resolved-bullet scan, muster-lint-requests.sh"

P=templates/knowledge-base/agent-context/.populated
need "$P" '"onboarded_at"'            "muster-boot.sh routing (muster-read-populated.sh)"
need "$P" '"onboarding_complete_at"'  "muster-boot.sh routing (muster-read-populated.sh)"
need "$P" '"agents"'                  "muster-boot.sh JIT gate, muster-check-context.sh, muster-doctor-populated.sh"
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

W=templates/knowledge-base/wave-review.md
need "$W" '## Current Wave'              "muster-lint-gate-packet.sh + muster-sprint-resume.sh gate flow"
need "$W" '**Wave:**'                    "muster-lint-gate-packet.sh active-gate detection"
need "$W" '### Notices since last gate'  "muster-lint-gate-packet.sh fold-in scaffold"
need templates/knowledge-base/founder-notices.md '- YYYY-MM-DD' "muster-lint-gate-packet.sh notice extraction (entry format)"

D=templates/knowledge-base/decision-log.md
need "$D" '**Impact**'          "muster-lint-decisions.sh field + role extraction"
need "$D" '**Touched**'         "muster-lint-decisions.sh field + path checks"
need "$D" '## Active Decisions' "decision-log structure (PM closeout archive boundary)"

C=templates/CLAUDE.md
need "$C" '<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->' "add-bootstrap-permissions.sh block replacement"
need "$C" '<!-- END BOOTSTRAP -->'                    "add-bootstrap-permissions.sh block replacement"
need "$C" 'muster-boot.sh'                            "the bootstrap itself — seeded first tool call"

# ---- Wave-8 fleet audit: pre-existing scripts' anchors, pinned ----

# boot's bind route requires each role's seeded bootloader to exist by exact name
for role in pm developer ui-ux qa content marketing legal research; do
  needfile "templates/.claude/agents/$role.md" "muster-boot.sh bind route (READ= target)"
done

# status-line chain: the bind-file NAME is the writer<->reader contract — muster-bind.sh writes
# it, the seeded statusline and muster-bound-role.sh read it, housekeeping prunes it by glob
need templates/.claude/statusline.sh '.muster-bound-role.' "muster-bind.sh writer <-> statusline/muster-bound-role.sh readers, muster-housekeeping.sh prune glob"

# lint-deps: brain-file dependency bullets are the parse anchor (live corpus, developer declares both)
need team/developer/CLAUDE.md '- Depends on:'  "muster-lint-deps.sh symmetry scan"
need team/developer/CLAUDE.md '- Provides to:' "muster-lint-deps.sh symmetry scan"

# lint-refs: the index-bullet form (^- **name.md**) is the parity anchor, both directions
need team/pm/CLAUDE.md '- **sprint-planning.md**' "muster-lint-refs.sh index parity (bullet form)"

# lint-entry: the entry field format's source of truth is system-guide's protocol templates
# (the seeded board ships empty — deliberately no example entries to pin there)
need system-guide.md '**Type:**'        "muster-lint-entry.sh field regexes (colon-inside-bold)"
need system-guide.md '**Deliverable:**' "muster-lint-entry.sh deliverable-path check"
need system-guide.md '**Reviewers:**'   "muster-lint-entry.sh reviewer checklist check"

# lint-kb-budgets: the PM-bootstrap file set it measures must exist under these exact names
needfile templates/knowledge-base/current-sprint.md "muster-lint-kb-budgets.sh watched set, one-active-sprint check"

# doctor-populated: boot writes the telemetry lines doctor's detectors parse (phase=/session=)
need scripts/muster-boot.sh 'phase=' "muster-doctor-populated.sh boot-log detectors"

# gate wrappers: each sub-script they invoke must exist by exact name (a rename that misses a
# wrapper must break CI here, not at a founder's closeout)
for s in muster-lint-queue.sh muster-lint-context.sh muster-lint-kb-budgets.sh; do
  needfile "scripts/$s" "muster-plan-gate.sh call chain"
done
for s in muster-lint-requests.sh muster-lint-entry.sh muster-lint-decisions.sh \
         muster-lint-durability.sh muster-lint-gate-packet.sh muster-list-open-items.sh; do
  needfile "scripts/$s" "muster-closeout.sh call chain"
done

# ---- extension-rule floor: every fleet script is consciously registered ----
# NO_ANCHOR roster: contracts are vendor schemas, git state, or the filesystem — pinned by
# fixtures (test-agent-cli, test-sprint-format, test-meter-prices, test-housekeeping,
# test-lint-commit, test-muster-agent), not by template anchors. Shims are deprecated wrappers.
NO_ANCHOR="muster-bind.sh muster-bound-role.sh muster-housekeeping.sh muster-guard-clean-tree.sh
muster-guard-worktree.sh muster-agent-cli.sh muster-sprint-format.sh muster-sprint-new.sh
muster-sprint-sandbox.sh muster-find-skill.sh muster-meter.py
muster-commit-lint.sh muster-lint-commit.sh muster-queue-lint.sh muster-requests-lint.sh"
SELF="scripts/test-parse-contracts.sh"
unregistered=0
for f in scripts/muster-*.sh scripts/muster-*.py; do
  b="$(basename "$f")"
  case " $(echo $NO_ANCHOR) " in *" $b "*) continue ;; esac
  if ! grep -qF "$b" "$SELF"; then
    fail=$((fail+1)); unregistered=1
    echo "FAIL: extension rule — $b is neither a registered consumer nor NO_ANCHOR-rostered here"
  fi
done
[ "$unregistered" -eq 0 ] && { pass=$((pass+1)); echo "PASS: every fleet script is registered or consciously exempt"; }

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
