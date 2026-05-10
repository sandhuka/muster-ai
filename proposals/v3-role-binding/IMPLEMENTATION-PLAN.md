# Muster v3 Role-Binding — Implementation Plan

**Status:** Active — execution starts after founder sign-off on this plan
**Companion doc:** `MUSTER-PROPOSAL-session-role-binding.md` (the spec — read first)
**Author:** Arogh founder (via Root Claude)
**Date:** 2026-05-10

---

## Pre-flight decisions (founder-confirmed)

| Decision | Choice | Implication |
|---|---|---|
| Rollout strategy | Direct on v3 branch, no flag-gating | Big-bang merge when ready. Cleaner code (no permanent v2/v3 branches in code). Rollback via `git revert` of the merge commit + revert of the Arogh submodule pointer bump. |
| Dogfood target | Arogh, via separate submodule branch | Arogh's `develop` branch stays on muster main during development. A separate Arogh branch (`feat/muster-v3-dogfood`) points the muster submodule at the v3 dev branch. If broken, abandon that Arogh branch — `develop` is unaffected. |
| Smoke-test target | Throwaway sample project | Created during Phase 0. Used for fast iteration before exposing v3 to Arogh's real state. |
| Prototype scope | All 8 roles at once | Trade-off accepted: 8× surface area for bugs in exchange for one-shot migration. Mitigation: PM symmetrization is sequenced separately from the other 7 (PM is the most invasive change; isolate it). |

---

## Branch setup

**Muster repo** (`/Users/kanwarsandhu/Desktop/arogh/muster/`):
- Create `feat/v3-role-binding` branched from `main`. All v3 work lives here.
- Two-commit protocol per muster CLAUDE.md Rule 13 applies for every change: commit + push inside submodule, then commit pointer bump in the consuming project (sample project initially, Arogh dogfood branch later).

**Arogh repo** (`/Users/kanwarsandhu/Desktop/arogh/`):
- Stay on `develop` for normal product work. Do NOT bump the muster submodule on `develop` until v3 is merged to muster main and verified.
- When ready to dogfood: branch `feat/muster-v3-dogfood` from `develop`, point submodule at `feat/v3-role-binding`, use that branch for sprint work during dogfood phase.

**Sample project** (created in Phase 0, location TBD — recommend `/Users/kanwarsandhu/Desktop/muster-v3-sandbox/`):
- Fresh `setup-project.sh` invocation pointing at the v3 branch.
- Used exclusively for smoke tests. Disposable.

---

## Phase 0 — Baseline & branch setup

**Goal:** Capture the v2 starting state and create the working branches. No code changes yet.

**Steps:**
1. Document v2 baseline in this file (see "v2 baseline reference" section at the bottom). Used for regression comparison.
2. Create `feat/v3-role-binding` in muster repo.
3. Create the sample project: `bash muster/scripts/setup-project.sh muster-v3-sandbox` in `/Users/kanwarsandhu/Desktop/`. Point its muster submodule at the new branch.
4. Verify sample project works under v2 behavior (PM tab boots, can invoke developer subagent). This is the "before" picture.

**Verification:**
- [ ] Branch exists in muster repo
- [ ] Sample project exists, submodule points at v3 branch
- [ ] Sample project's v2-behavior PM bootstrap works (read `.populated`, monitoring files, etc.)

**Rollback:** Delete branch and sample project. Zero blast radius.

---

## Phase 1 — Foundation: muster CLAUDE.md restructure

**Goal:** Replace "PM Mode (Built-in)" with "Role Binding (Explicit)" in muster's framework brain. This is documentation/rule restructure — picker logic wired in Phase 3.

**Files touched:**
- `muster/CLAUDE.md`

**Steps:**
1. Add new section "Role Binding (Explicit)" replacing "PM Mode (Built-in)" (currently L55-94).
2. Restructure the priority-zero check (currently L59-64) to add picker-fire logic:
   - After existing `.populated` routing, if path is steady-state or greenfield-ongoing, fire picker.
   - Greenfield-first-session AND onboarding-active paths skip picker (force-bind PM).
3. Update Rule 1 (currently L31): "PM is the hub (Root Claude)" → "PM is the hub (a role like any other; bind a tab to PM via the role picker)."
4. Update Agent Roster table (currently L19-29): PM row drops "Built-in — Root Claude IS the PM" framing, becomes peer.
5. Update "How to Work With This System" section (L47-50): replace PM-as-default language with picker-driven model.
6. Add the F4 isolation note: picker fires only at primary-tab session start; Agent-tool subagents bind via `subagent_type` argument and never fire the picker.
7. Add the F3 tool-asymmetry note: picker-bound roles inherit Root Claude's full toolset; subagents are tool-restricted per their config.

**Verification:**
- [ ] Read CLAUDE.md end-to-end — no orphan references to "PM Mode (Built-in)"
- [ ] Grep muster repo for "PM Mode" — every remaining hit is intentional (e.g., decision-log historical entries)
- [ ] Cross-references in `system-guide.md` and `architecture-and-design.md` still resolve (these get updated in Phase 8)
- [ ] `.populated` priority-zero routing logic in this file matches the documented carve-outs in §4.9 of the proposal

**Regression risks:**
- Existing `.claude/agents/<name>.md` startup configs reference muster CLAUDE.md by section name. If section names change without updating those references, agents may not find what they expect. Mitigation: grep all `.claude/agents/*.md` files for "PM Mode" and update to "Role Binding."
- Onboarding skills (`greenfield-discovery.md`, `reverse-discovery.md`) may reference PM Mode behaviors. Audit and update as needed.

**Two-commit protocol:** Commit in muster, push, then bump submodule pointer in sample project.

---

## Phase 2 — PM symmetrization (most invasive; isolate)

**Goal:** PM becomes a peer of the other seven agents. Create `.claude/agents/pm.md`, rewrite PM brain file voice, move bootstrap reads.

**Files touched:**
- `muster/team/pm/CLAUDE.md` (rewrite voice)
- `muster/templates/.claude/agents/pm.md` (new file)
- Sample project: `.claude/agents/pm.md` (new file, copied from template)

**Steps:**
1. Rewrite `muster/team/pm/CLAUDE.md` — strip "Root Claude IS the PM" / "you ARE Root Claude" language. Same voice as the other seven brain files: "you are the PM role for this session."
2. Create `muster/templates/.claude/agents/pm.md` modeled on the standard startup config template (see `system-guide.md` L56-90):
   - Halt check on `.populated.agents.pm` (mirrors other agents)
   - Always-read list: muster CLAUDE.md, PM brain, agent-context/pm.md (if exists — PM may not have an agent-context file in current muster; verify)
   - PM monitoring duties (currently in muster CLAUDE.md L84-89) move HERE — fire at PM bind time
   - Session-completion protocol matching other agents
3. In sample project, copy template to `.claude/agents/pm.md`.
4. Verify `.populated` schema includes PM correctly. Today, PM is in `.populated.agents.pm` (per existing schema). No schema change needed — just confirm.

**Verification:**
- [ ] PM brain file reads as "you are the PM role" — no asymmetric framing remaining
- [ ] `.claude/agents/pm.md` exists in sample project, follows the standard template structure
- [ ] PM monitoring duties are reachable from pm.md (not orphaned)
- [ ] Sample project: manually trigger a PM session (no picker yet — that's Phase 3) and verify monitoring duties fire

**Regression risks:**
- PM brain file is read by muster CLAUDE.md priority-zero check. If the path or content structure changes, the priority-zero check may break. Verify the priority-zero check still loads PM brain correctly.
- PM has no `agent-context/pm.md` today (it's the hub, not a target). Decide: create one, or have pm.md skip that read. **Recommendation**: create a minimal `agent-context/pm.md` with project context and Sprint 1 cross-references — symmetrizes fully and gives PM the same project-context model as other agents.

**Two-commit protocol:** Commit in muster (template + brain rewrite), push, bump sample project pointer, then commit `.claude/agents/pm.md` in sample project.

---

## Phase 3 — Picker mechanism core

**Goal:** Wire up the actual picker logic. Two-step picker, PID-suffix file, JIT-populate handling, carve-outs.

**Files touched:**
- `muster/CLAUDE.md` (priority-zero check picker logic)
- `muster/templates/.gitignore` (add `.claude/.muster-bound-role.*` and `.claude/.muster-last-role`)
- Sample project equivalents

**Steps:**
1. **Two-step picker** (item 15 / F6 fix): muster CLAUDE.md priority-zero check fires `AskUserQuestion` with role groups (Coordination, Build, Communicate, Validate). On group selection, fires second `AskUserQuestion` with roles in that group (or short-circuits if group has one option, like Coordination → PM).
2. **PID-suffix bound-role file** (item 10 / F1 fix): on picker selection, write role to `.claude/.muster-bound-role.<pid>` where `<pid>` is the parent process PID. Add startup-time prune: `for f in .claude/.muster-bound-role.*; do kill -0 ${f##*.} 2>/dev/null || rm "$f"; done`.
3. **JIT-populate handling** (item 14 / F5 fix): before reading the picked role's brain + agent-context, check `.populated.agents.<picked-role>`. If null, force-bind PM, run JIT populate per `context-cascading.md`, then re-fire picker.
4. **Carve-outs**: priority-zero check explicitly skips picker and force-binds PM in two paths:
   - Greenfield first session (`onboarded_at` null AND `agents.pm` null) → force-bind PM, fire `greenfield-discovery.md` welcome
   - Onboarding active (`onboarded_at` set AND `onboarding_complete_at` null) → force-bind PM, fire `reverse-discovery.md` Phase 1
5. **Subagent isolation note** is already in CLAUDE.md from Phase 1 step 6. Verify it's still there and accurate.

**Verification (smoke tests in sample project):**
- [ ] Open sample project terminal → picker fires → select Build → select Developer → Claude declares "I am operating as the Developer for this session" → reads developer brain + agent-context → ready
- [ ] Open second terminal → picker fires again → select Coordination → PM bind (short-circuit, no second question) → PM monitoring duties fire
- [ ] Manually null an agent's `.populated` entry → fire picker → verify JIT populate happens before bind
- [ ] Run `setup-project.sh` for a new greenfield project → verify picker is suppressed, welcome fires
- [ ] Resume an in-progress reverse-discovery project → verify picker is suppressed, Phase 1 fires

**Regression risks (HIGH — this is the hot zone per §4.9):**
- Picker firing when it shouldn't (during onboarding/greenfield) → derails entire onboarding flow
- Picker NOT firing when it should (in steady-state) → falls back to v2-like behavior with no role binding, status line shows "unbound"
- PID-file race conditions if multiple terminals open simultaneously → test with two terminals open at once
- JIT populate loop (picker → halt → JIT → picker → halt → ...) if PM bind fails silently
- `AskUserQuestion` blocking in non-interactive contexts where `MUSTER_ROLE` should have been set but wasn't → halt should be clear

**Two-commit protocol:** Commit + push in muster, bump pointer in sample project. Test all five smoke scenarios before declaring phase complete.

---

## Phase 4 — Other 7 roles symmetrized

**Goal:** Apply the same brain-file voice rewrite + bind-step polish to the remaining seven roles (developer, ui-ux, qa, content, marketing, legal, research).

**Files touched:**
- `muster/team/<role>/CLAUDE.md` × 7
- `muster/templates/.claude/agents/<role>.md` × 7 (review for bind-step compatibility)
- Sample project: `.claude/agents/<role>.md` × 7 (copy from updated templates)

**Steps:**
1. For each of the 7 roles: read brain file, identify any "you are invoked as a subagent" or asymmetric framing, rewrite to "you are the <role> role for this session" — symmetric with PM.
2. For each of the 7 roles: review `.claude/agents/<role>.md` startup config. Today these contain a halt check + always-read list. Verify they still work when the role is bound via picker (not via Agent tool). Likely no changes needed — the startup config is identical for both invocation paths — but confirm.
3. Update `templates/.claude/agents/<role>.md` if any changes are needed.
4. Verify each agent-context file (`knowledge-base/agent-context/<role>.md`) in sample project is populated (or null and JIT-populates correctly per Phase 3).

**Verification:**
- [ ] For each of the 8 roles: open sample project terminal, pick that role via picker, verify Claude binds and behaves as that role
- [ ] Cross-role consult: from a Developer-bound tab, invoke a UI-UX subagent via Agent tool → verify subagent does NOT fire picker (F4 isolation)
- [ ] Same-role parallel: from a Developer-bound tab, invoke a Developer subagent → verify it works (allowed per §4.2 resolution)

**Regression risks:**
- Rewriting brain file voice could change emphasis in subtle ways that affect role behavior. Mitigation: minimal-change rewrites. Don't restructure brain files; just adjust framing language.
- Halt check semantics in `.claude/agents/<role>.md` may interact differently with picker than with Agent tool. Test each path.

---

## Phase 5 — Env var contract (`MUSTER_ROLE`)

**Goal:** Implement the autonomous-mode contract. `MUSTER_ROLE=<role>` skips picker; `MUSTER_ROLE=auto` reads queue and binds; invalid value halts.

**Files touched:**
- `muster/CLAUDE.md` (priority-zero check env-var branch)

**Steps:**
1. In priority-zero check, BEFORE firing picker: read `MUSTER_ROLE` env var.
2. If unset → fire picker (existing Phase 3 behavior).
3. If set to a valid role name → skip picker, bind directly to that role. Run all the same JIT-populate checks Phase 3 picker does.
4. If set to `auto` → read `orchestration-queue.md` Next Step entry, parse the role assignment, bind to that role. If queue is empty / malformed / Next Step missing → halt with explicit error: `"MUSTER_ROLE=auto but orchestration queue has no Next Step. Cannot determine role. Halt."`.
5. If set to an invalid value → halt with explicit error: `"MUSTER_ROLE='<value>' is not a valid role. Valid: pm, developer, ui-ux, qa, content, marketing, legal, research, auto. Halt."`.

**Verification (smoke tests):**
- [ ] `MUSTER_ROLE=developer claude "what's the current task"` → no picker, Developer-bound
- [ ] `MUSTER_ROLE=foo claude "..."` → halts with clear error
- [ ] `MUSTER_ROLE=auto claude "..."` with populated queue → binds to queue's Next Step role
- [ ] `MUSTER_ROLE=auto claude "..."` with empty queue → halts with clear error
- [ ] Unset env var → picker fires (regression check on Phase 3)

**Regression risks:**
- Env var inherited from parent shell could unintentionally bind. Mitigation: document this in autonomous-mode contract; recommend `unset MUSTER_ROLE` for interactive sessions.
- Queue parsing in `auto` mode is fragile — `orchestration-queue.md` is markdown. Use a forgiving parser that extracts the role name from the Next Step entry, halts on ambiguity rather than guessing.

---

## Phase 6 — Status line bound-role indicator

**Goal:** Replace the lost agent-color signal with a persistent status-line display.

**Files touched:**
- `muster/templates/.claude/statusline.sh` (new file)
- `muster/templates/settings.json` or equivalent (add `statusLine` config)
- Sample project equivalents

**Steps:**
1. Create `muster/templates/.claude/statusline.sh`:
   ```bash
   #!/bin/bash
   PID=$PPID
   FILE=".claude/.muster-bound-role.$PID"
   if [ -f "$FILE" ]; then
     echo "[muster: $(cat "$FILE")]"
   else
     echo "[muster: unbound]"
   fi
   ```
2. Make executable: `chmod +x`.
3. Wire into Claude Code settings.json via the `statusline-setup` skill (use the skill, don't hand-roll JSON).
4. Verify in sample project: open terminal, picker binds to Developer, status line shows `[muster: developer]`.

**Verification:**
- [ ] Status line shows correct role after picker binds
- [ ] Status line shows `[muster: unbound]` if file is missing (e.g., during onboarding before bind)
- [ ] Two terminals open simultaneously each show their own role correctly (PID-suffix working)
- [ ] After session exit + new session, stale PID file is pruned at startup

**Regression risks:**
- Status line script failures could break Claude Code's status line entirely. Test with intentionally missing file, malformed file, etc.
- Cross-platform: bash works on macOS. Document Windows/PowerShell variant; ship in v3.1 if not done in v3.

---

## Phase 7 — Quality-of-life features

**Goal:** Ship `/rebind`, last-role memory, bind log, and non-PM bind side-scan.

**Files touched:**
- `muster/templates/.claude/skills/rebind.md` (new — `/rebind` slash command)
- Picker logic in muster CLAUDE.md (last-role memory, bind log, side-scan)

**Steps:**
1. **`/rebind` skill** (item 17): create as a project-level slash command skill. Re-runs the picker (Phase 3 logic), overwrites the bound-role PID file, declares new binding.
2. **Last-role memory** (item 18): on bind, write role to `.claude/.muster-last-role` (project-level, gitignored, NOT PID-suffixed). Picker reads this and pre-selects in second-step question.
3. **Bind log** (item 19): on every bind, append to `knowledge-base/.muster-bind-log`: `<timestamp> <role> <invoker> <pid>`. Cap at 500 lines; rotate to `.muster-bind-log.archive` when exceeded.
4. **Non-PM bind side-scan** (item 3): when picker binds to non-PM role, run lightweight scan of `agent-requests.md` and `orchestration-queue.md` for stale items, surface one-line notice if anything stale.

**Verification:**
- [ ] `/rebind` re-fires picker, picks new role, status line updates
- [ ] Second session: picker pre-selects last-bound role
- [ ] Every bind appears in `.muster-bind-log` with correct invoker tag
- [ ] Bind to non-PM role with stale items in queue → notice appears

**Regression risks:**
- `/rebind` mid-conversation could confuse Claude about what role it is. Test that role context loads correctly post-rebind.
- Bind log growth — verify cap + rotation works.
- Side-scan adds bind-time latency. Keep it minimal (just count entries, don't process them).

---

## Phase 8 — Documentation updates

**Goal:** Update muster's three reference docs to reflect v3 behavior. Without this, the docs lie about how the system works.

**Files touched:**
- `muster/system-guide.md`
- `muster/architecture-and-design.md`
- `muster/getting-started.md`
- `muster/README.md` (if it describes role mechanics)

**Steps:**
1. **system-guide.md updates**:
   - Tool-permission asymmetry note (item 12 / F3)
   - Cross-role consult policy: option (c) is the default; (a)/(b) are exceptions for trivia (per §4.6 resolution)
   - Same-role subagents allowed for parallel work (per §4.2 resolution)
   - Multi-tab convention onboarding language (per §4.4 resolution)
   - Picker mechanism section
   - Two-step picker structure
   - `MUSTER_ROLE` env var contract with example invocations
   - `MUSTER_ROLE=auto` semantics
2. **architecture-and-design.md updates**:
   - Update "System Architecture" diagram (currently L106-142): replace "Root Claude (PM)" with "Root Claude (bound to role via picker)"
   - Update "Orchestration Loop" diagram (L237-263): step 1 becomes "Open Claude Code → Picker fires → bind to role"
   - Update "How the PM Manages Everything" section to reflect peer-status PM
3. **getting-started.md updates**:
   - First-session walkthrough now starts with picker
   - Multi-tab convention example
   - Autonomous-mode example (`MUSTER_ROLE=auto`)
4. **README.md** if needed.
5. Add muster decision-log entry (in muster repo) recording the v2→v3 change with rationale pointer to the proposal doc.

**Verification:**
- [ ] All three docs read coherently with v3 behavior
- [ ] No stale references to "PM Mode (Built-in)"
- [ ] Diagrams updated
- [ ] Decision-log entry written

**Regression risks:** Doc-only changes — no runtime risk. But stale docs cause user confusion, which is its own regression.

---

## Phase 9 — Migration tooling for existing projects

**Goal:** Existing v2 muster projects (Arogh and any others) need to migrate. Decide: script vs doc-only.

**Files touched:**
- `muster/scripts/migrate-v2-to-v3.sh` (new, if scripted)
- `muster/MIGRATING-V2-TO-V3.md` (new — user-facing migration guide)

**Steps:**
1. Identify what an existing v2 project needs to do to adopt v3:
   - Add `.claude/agents/pm.md` (copy from v3 template)
   - Add `.claude/statusline.sh` and wire into settings.json
   - Add `.gitignore` entries for `.muster-bound-role.*` and `.muster-last-role`
   - Optionally add `knowledge-base/agent-context/pm.md` if doesn't exist
   - Update project-level `CLAUDE.md` if it has any PM-Mode references
2. **Recommendation**: write a script. The migration is mechanical and identical for every v2 project. A script reduces error vs documenting steps.
3. Write `MIGRATING-V2-TO-V3.md` modeled on `MIGRATING-V1-TO-V2.md`.
4. Test the migration on a fresh-ish v2 project (the sample project from Phase 0 if you didn't reset it; otherwise spin up a v2-vintage project).

**Verification:**
- [ ] Migration script runs cleanly on a v2 project
- [ ] Migrated project boots into v3 picker on next session
- [ ] All v2 state (current sprint, decision log, agent-requests) preserved unchanged

**Regression risks:**
- Migration script is the most likely source of project-level data loss. Test extensively. Make it idempotent (running twice produces same result).
- Document what to do if migration partially fails (e.g., script halts mid-way).

---

## Phase 10 — Sample project full smoke-test pass

**Goal:** Before exposing v3 to Arogh, verify every priority-zero path and every role bind in the sample project.

**Test matrix:**

| Scenario | Expected behavior | Pass? |
|---|---|---|
| Fresh greenfield project, first session | Picker suppressed, greenfield welcome fires | [ ] |
| Greenfield project, second session (after Stage 1.3) | Picker fires, can pick PM | [ ] |
| Existing-project onboarding active | Picker suppressed, reverse-discovery Phase 1 fires | [ ] |
| Steady-state, first interactive session | Picker fires (two-step), bind any role | [ ] |
| Each of 8 roles bound via picker | Role behaves correctly | [ ] |
| `MUSTER_ROLE=developer` | Skip picker, bind Developer | [ ] |
| `MUSTER_ROLE=auto` with populated queue | Bind to queue's Next Step role | [ ] |
| `MUSTER_ROLE=invalid` | Halt with clear error | [ ] |
| `MUSTER_ROLE=auto` with empty queue | Halt with clear error | [ ] |
| Cross-role consult from bound tab via Agent tool | Subagent runs without firing picker | [ ] |
| Same-role parallel via Agent tool | Subagent runs in isolation | [ ] |
| `/rebind` mid-session | Picker re-fires, new role bound, status line updates | [ ] |
| Two terminals open simultaneously | Each shows its own role in status line (no race) | [ ] |
| Picker bind with null `.populated` entry | JIT populate fires, then picker re-fires | [ ] |
| Stale PID files at session start | Pruned automatically | [ ] |

**Pass criteria:** All rows checked. Any failure blocks Phase 11.

---

## Phase 11 — Arogh dogfood (separate submodule branch)

**Goal:** Real-world validation in Arogh without risking `develop`.

**Steps:**
1. In Arogh repo, create `feat/muster-v3-dogfood` branched from `develop`.
2. Bump muster submodule on this branch to point at `feat/v3-role-binding`.
3. Run migration script (Phase 9) against Arogh on this branch.
4. Use this branch for at least one full sprint of normal product work.
5. Capture issues in a `MUSTER-V3-DOGFOOD-FEEDBACK.md` file at Arogh root. One entry per surprise: what happened, expected behavior, severity, fix needed.
6. Iterate on the muster v3 branch as issues surface. Each fix triggers two-commit protocol + Arogh dogfood pointer bump.

**Pass criteria:**
- Sprint completes successfully on dogfood branch
- All captured issues are either fixed or accepted as v3.1 backlog with rationale
- No data loss or workflow blockers

**Rollback:** If dogfooding surfaces blocking issues, abandon the dogfood branch. Arogh `develop` is unaffected. Continue iterating on muster v3 branch.

---

## Phase 12 — v3 cutover

**Goal:** Merge v3 to muster main, propagate to Arogh `develop`, monitor.

**Steps:**
1. Merge `feat/v3-role-binding` → muster `main`. Tag as `v3.0.0` if muster uses semver tagging.
2. In Arogh `develop`, bump muster submodule pointer to muster main (now containing v3).
3. Run migration script against Arogh `develop`.
4. Commit + push.
5. Delete `feat/muster-v3-dogfood` branch in Arogh (work is now on `develop`).
6. Update Arogh's `MEMORY.md`: change project memory entry status from "awaiting prototype" to "shipped in v3.0.0".
7. Monitor for one week. Capture any post-cutover issues.

**Rollback (if catastrophic post-merge):**
- Revert the muster submodule pointer bump on Arogh `develop`.
- Optionally revert the merge commit on muster main.
- Investigate, re-prototype on a fresh branch.

**v3.1 backlog (carry forward):**
- W4 auto-detection of role mismatch (gated on autonomous orchestrator existing)
- W6 enriched status line with queue context (gated on queue/requests format lock)
- Cross-platform status-line script (Windows/PowerShell variant)
- Upstream Claude Code asks: SendMessage capability, mid-session tool restriction API

---

## Cross-cutting concerns

### Two-commit protocol (muster Rule 13)
Every change inside `muster/` requires:
1. Commit + push inside the submodule (`cd muster && git add . && git commit -m "..." && git push`)
2. Commit the updated submodule pointer in the consuming project (`git add muster && git commit -m "..."`)

Skipping either means the change isn't visible to other clones / future sessions. Verify both commits land before declaring any phase step complete.

### Branch awareness
- All v3 dev work happens on `feat/v3-role-binding` in muster repo
- Arogh dogfooding happens on `feat/muster-v3-dogfood` in Arogh repo
- Arogh's `develop` does NOT touch v3 until Phase 12 cutover
- Verify branch before every commit (memory: "always verify current branch before committing")

### Honesty during implementation
- Report what works AND what doesn't after each phase. Don't paper over failures.
- If a smoke test fails, halt the phase and surface the failure. Do not advance.
- If a regression risk materializes, halt and discuss before continuing.

### Communication checkpoints
After each phase, report:
- What was changed (files touched)
- What was verified (which checkboxes are ticked)
- What didn't work as expected (failures, unexpected behaviors)
- What needs founder attention before the next phase

Founder explicitly reviews and approves at the end of:
- Phase 3 (picker mechanism — highest regression risk)
- Phase 5 (env var contract)
- Phase 10 (full smoke-test pass — gate to Arogh dogfood)
- Phase 11 (dogfood complete — gate to cutover)

### Test artifacts to keep
- `MUSTER-V3-DOGFOOD-FEEDBACK.md` — issues surfaced during Phase 11
- Phase 10 smoke-test matrix completion log
- v2 baseline reference (below) — for regression comparison

---

## Definition of done for v3

The v3 cutover is complete when ALL of the following are true:

- [ ] All 19 §5.1 implementation items shipped (per Phases 1-9)
- [ ] All 6 §4.10 failure modes (F1-F6) addressed and verified
- [ ] All four `.populated` priority-zero paths verified (greenfield first/ongoing, onboarding active, steady-state)
- [ ] All 8 roles bind cleanly via picker
- [ ] `MUSTER_ROLE` env var works for all branches: valid role, invalid role, `auto` with queue, `auto` without queue
- [ ] Status line displays bound role correctly with two terminals open simultaneously
- [ ] At least one Arogh sprint completed using v3 (Phase 11)
- [ ] All three muster reference docs updated (Phase 8)
- [ ] Migration script tested and works (Phase 9)
- [ ] Decision-log entry in muster repo recording v3 cutover
- [ ] v3.1 backlog captured (W4, W6, cross-platform status line, upstream asks)
- [ ] Arogh `develop` running on muster main with v3 (Phase 12)

---

## v2 baseline reference (captured Phase 0 — for regression comparison)

**v2 priority-zero behavior:** Root Claude reads `.populated`, routes on `onboarded_at` / `onboarding_complete_at` / `agents.pm` to one of four paths (existing-project onboarding, greenfield first, greenfield ongoing, steady-state). In greenfield-ongoing and steady-state paths, Root Claude implicitly acts as PM and reads 8 monitoring files on first PM question.

**v2 specialist invocation:** Founder asks PM to plan, PM populates orchestration queue, founder invokes specialist via Agent tool with `subagent_type="<role>"`. Subagent reads `.claude/agents/<role>.md` startup config, halts if `.populated.agents.<role>` is null, otherwise reads brain + agent-context + queue + requests.

**v2 PM Mode location:** `muster/CLAUDE.md` "PM Mode (Built-in)" section (currently L55-94 as of `feat/v3-role-binding` base commit).

**v2 PM monitoring trigger:** First PM-type question of a session.

**v2 visual signal:** Subagent invocations show role color in console; Root Claude (PM) has no color.

**v2 Rule 1:** "PM is the hub (Root Claude) — Root Claude acts as the PM and is the ONLY role that writes to agent-context files..."

These are the things v3 changes. Any regression test should compare v3 behavior against v2 behavior on these dimensions.
