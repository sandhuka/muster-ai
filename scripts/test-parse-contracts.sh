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
need "$C" '<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->' "muster-update.sh bootstrap-block sync (absorbed add-bootstrap-permissions.sh)"
need "$C" '<!-- END BOOTSTRAP -->'                    "muster-update.sh bootstrap-block sync"
need "$C" 'muster-boot.sh'                            "the bootstrap itself — seeded first tool call"

# ---- Wave-8 fleet audit: pre-existing scripts' anchors, pinned ----

# boot's bind route requires each role's submodule bootloader to exist by exact name; the
# platform stub at .claude/agents/<role>.md is the Agent({subagent_type}) entry point and must
# hop to that same bootloader (the shim seam). A stub whose frontmatter restricts tools MUST
# grant Read — otherwise the subagent cannot follow its own hop instruction (bricked at birth);
# no tools line = unrestricted = fine.
for role in pm developer ui-ux qa content marketing legal research; do
  needfile "team/$role/bootloader.md" "muster-boot.sh bind route (READ= target), .claude/agents/$role.md stub hop"
  needfile "templates/.claude/agents/$role.md" "setup-project.sh + setup-existing-project.sh seed, Agent({subagent_type}) entry stub"
  need "templates/.claude/agents/$role.md" "muster/team/$role/bootloader.md" "stub -> bootloader hop (assisted mode startup)"
  stub="templates/.claude/agents/$role.md"
  if grep -q '^tools:' "$stub" 2>/dev/null && ! grep -q '^tools:.*Read' "$stub" 2>/dev/null; then
    fail=$((fail+1)); echo "FAIL: $stub restricts tools without Read — stub cannot read its bootloader"
  else
    pass=$((pass+1)); echo "PASS: $stub grants Read (or is unrestricted)"
  fi
done

# status-line chain: the bind-file NAME is the writer<->reader contract — muster-bind.sh writes
# it, muster-statusline.sh and muster-bound-role.sh read it, housekeeping prunes it by glob.
# The seeded .claude/statusline.sh is a framework-owned stub that must hop to the submodule.
need scripts/muster-statusline.sh '.muster-bound-role.' "muster-bind.sh writer <-> muster-statusline.sh/muster-bound-role.sh readers, muster-housekeeping.sh prune glob"
need templates/.claude/statusline.sh 'muster/scripts/muster-statusline.sh' "statusline stub exec hop -> muster-statusline.sh"
need templates/.claude/statusline.sh '[muster: submodule missing]' "statusline stub degrade contract (test-muster-agent.sh)"

# seeded slash-command stubs hop to submodule contracts — the heading/paragraph each stub
# names must keep existing, and each stub must keep naming it
need MUSTER.md 'Invocation — Bind or Consult'  "templates/.claude/skills/muster stub hop target"
need CLAUDE.md '**`/rebind`**'                 "templates/.claude/skills/rebind stub hop target"
need templates/.claude/skills/muster/SKILL.md 'Invocation — Bind or Consult' "stub -> MUSTER.md hop"
need templates/.claude/skills/rebind/SKILL.md 'Role Binding'                 "stub -> muster/CLAUDE.md hop"

# settings template shape: both setup scripts awk-strip the statusLine block when a user-level
# statusline exists — the block-open line and the permissions key are their parse anchors
need templates/.claude/settings.json '"statusLine": {' "setup-project.sh + setup-existing-project.sh statusLine strip"
need templates/.claude/settings.json '"permissions"'   "setup-project.sh + setup-existing-project.sh permissions seed, muster-update.sh union merge"

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

# lint-step: the step-body field contract's source of truth is the planning skill's Queue Step
# Format (the seeded queue template deliberately carries no field example — audit fact)
SP=team/pm/skills/generic/sprint-planning.md
need "$SP" '**Deliverable:**'   "muster-lint-step.sh field contract (bold form; plain form is live convention)"
need "$SP" '**On completion:**' "muster-lint-step.sh field contract"
need "$SP" 'Role: halt'         "muster-lint-step.sh gate check + muster-sprint-run.sh halt stop"
need "$SP" 'wave-review.md'     "muster-lint-step.sh halt-gate pointer check"

# lint-sprint: the wave-table is THE board format (founder-ruled) — its header row is the
# anchor, taught in the skill and seeded in the template
need "$SP" '| Step | Role | Deliverable | Verification |' "muster-lint-sprint.sh row parsing (taught format)"
need templates/knowledge-base/current-sprint.md '| Step | Role | Deliverable | Verification |' "muster-lint-sprint.sh row parsing (seeded format)"

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
