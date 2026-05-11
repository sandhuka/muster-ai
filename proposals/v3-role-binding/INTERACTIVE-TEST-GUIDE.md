# v3 Interactive Test Guide

Companion to `IMPLEMENTATION-PLAN.md` Phase 10. The 20 interactive tests, with concrete steps, plus three fast-track strategies (Minimum / Recommended / Comprehensive) so you can pick the right depth for the time you have.

**Pre-test setup** (do once before any session):
```bash
# Make sure sandbox is on latest v3
git -C /Users/kanwarsandhu/Desktop/muster-v3-sandbox/muster pull origin feat/v3-role-binding
```

The sandbox at `/Users/kanwarsandhu/Desktop/muster-v3-sandbox/` is currently in greenfield-first state.

---

## The 20 tests — full catalog

### Greenfield welcome path (the time-expensive one)

#### I1 — Fresh greenfield, first session: welcome fires
**State setup**: sandbox `.populated` shows `onboarded_at: null, agents.pm: null` (current state).
**Steps**:
1. `cd ~/Desktop/muster-v3-sandbox && claude`
2. Type any first message (e.g., "let's go")
3. **Expect**: Welcome message appears; PM is bound (no picker fires); status line shows `[muster: pm]`; Stage 1 prompt asks for product idea.
**Pass criteria**: Welcome triggers, no picker prompt, status line correct.
**Full Discovery time**: 1-2 hours across 3 sessions (idea share → research → go/no-go → spec drafting → Sprint 1).
**Fast-track**: Stop after seeing the welcome (don't actually do Discovery). Total time: ~2 min.

#### I17 — Greenfield-first does NOT trigger pm.md halt (verifies Phase 2 audit-fix)
**Subset of I1**. The fact that the welcome fires (instead of `HALT: PM not initialized`) proves the carve-out works.
**Pass criteria**: Same as I1 — welcome appears.

#### I3 — Existing-project onboarding active: reverse-discovery Phase 1 fires
**State setup**: requires a project that ran `setup-existing-project.sh` but didn't complete Phase 11.
**Steps**:
1. Create a minimal fake existing project: `mkdir -p /tmp/fake-existing-project && cd /tmp/fake-existing-project && git init && echo "test code" > main.py`
2. Run `bash /Users/kanwarsandhu/Desktop/muster-ai/scripts/setup-existing-project.sh` (will scaffold + set `onboarded_at`)
3. `claude` and send "let's go"
4. **Expect**: PM bound (no picker), reverse-discovery Phase 1 orientation message fires.
**Pass criteria**: Orientation message appears.
**Fast-track**: skip after Phase 1 fires (don't run all 11 phases). Total time: ~3 min.

---

### Picker mechanism (the meat)

#### I4 — Steady-state: picker fires
**State setup**: project where both `onboarded_at` AND `onboarding_complete_at` are timestamps. Easiest: manually edit sandbox `.populated`.
**Steps**:
1. `cd ~/Desktop/muster-v3-sandbox`
2. Edit `knowledge-base/agent-context/.populated` — set `onboarded_at` and `onboarding_complete_at` to fake timestamps (e.g., `"2026-01-01T00:00:00Z"`)
3. Set all `agents.<role>` to fake timestamps too (so JIT populate doesn't fire)
4. `claude`
5. Type "hello"
6. **Expect**: Two-step picker fires (Q1: Coordination/Build/Communicate/Validate)
**Pass criteria**: Picker fires before any other response.

#### I5 — PM bind via Coordination → PM (single-option short-circuit)
**Steps** (continue from I4):
7. Pick "Coordination"
8. **Expect**: No second question (PM is the only Coordination option — short-circuits); Claude declares "Binding to PM for this session"; status line shows `[muster: pm]`; PM monitoring duties run.
**Pass criteria**: Single-option short-circuit works, monitoring fires.

#### I6 — Each of 7 specialists binds correctly
**Steps**: Open 7 separate sessions, pick a different group → role each time:
- Build → Developer (color: green)
- Build → UI-UX (color: purple)
- Build → QA (color: red)
- Communicate → Content (color: pink)
- Communicate → Marketing (color: orange)
- Validate → Research (color: blue)
- Validate → Legal (color: yellow)

**Pass criteria**: Each session binds correctly; status line shows correct role.
**Fast-track**: Test 1-2 specialists representatively, trust pattern for others (all bootloaders share structure). Time: ~3 min instead of 7.

#### I13 — `/rebind` mid-session swaps role
**Steps** (continue from any bound session):
1. Type `/rebind`
2. **Expect**: Picker re-fires
3. Pick a different role
4. **Expect**: Claude declares "Re-binding to <Role> for this session"; status line updates
**Pass criteria**: Picker re-fires, role changes, status line refreshes.

---

### Env var contract (`MUSTER_ROLE`)

#### I7 — `MUSTER_ROLE=developer` skips picker, binds directly
**Steps**:
```bash
cd ~/Desktop/muster-v3-sandbox
MUSTER_ROLE=developer claude "what's my next task"
```
**Expect**: No picker fires; Claude is Developer; reads developer's bootloader; status line shows `[muster: developer]`.
**Pass criteria**: Picker skipped, correct role bound.

#### I8 — `MUSTER_ROLE=auto` with populated queue
**State setup**: orchestration-queue.md must have a Next Step with @-prefix. If sandbox queue is empty, manually add:
```markdown
## Next Step

### 2026-05-10 Developer: test task

` ` `
@developer

Tell me what you'd do for this test task.
` ` `
```
**Steps**:
```bash
MUSTER_ROLE=auto claude "execute next step"
```
**Expect**: Reads queue, parses `@developer`, binds Developer, executes the task.
**Pass criteria**: Correct role auto-detected from queue.

#### I9 — `MUSTER_ROLE=invalid` halts
**Steps**:
```bash
MUSTER_ROLE=foo claude "anything"
```
**Expect**: Halt with error: `"MUSTER_ROLE='foo' is not a valid role. Valid: pm, developer, ui-ux, qa, content, marketing, legal, research, auto. Halt."`
**Pass criteria**: Explicit halt message, no fallthrough to picker.

#### I10 — `MUSTER_ROLE=auto` with empty queue
**Steps**: Empty the orchestration-queue.md `## Next Step` section, then:
```bash
MUSTER_ROLE=auto claude "anything"
```
**Expect**: Halt: `"MUSTER_ROLE=auto but orchestration queue has no parseable Next Step. Cannot determine role. Halt."`
**Pass criteria**: Explicit halt, no silent default.

---

### Subagent isolation

#### I11 — Cross-role consult: subagent doesn't fire picker
**Steps** (in any role-bound session):
1. Ask Claude: "Spawn a UI-UX subagent and ask it about button design conventions."
2. Claude invokes `Agent({subagent_type: "ui-ux", prompt: "..."})`.
3. **Expect**: UI-UX subagent runs WITHOUT firing the picker; returns its answer.
**Pass criteria**: No recursive picker, subagent works normally.

#### I12 — Same-role parallel: developer-bound spawns developer subagent
**Steps** (in Developer-bound session):
1. Ask: "Spawn a Developer subagent in parallel to look at file X."
2. **Expect**: Developer subagent runs in isolation; no recursive picker.
**Pass criteria**: Same-role parallel spawn works.

---

### @-mention prefix routing (Phase 4 follow-up rule)

#### I18 — Matching prefix: bound role executes directly
**Steps**:
1. In a Developer-bound tab, paste:
```
@developer

Tell me what you'd build for the pre-workout cue overlay.
```
2. **Expect**: Bound Developer treats `@developer` as informational, executes the task body directly. NO subagent spawn.
**Pass criteria**: Task executed in the bound session, not delegated to subagent.

#### I19 — Non-matching prefix: spawns subagent
**Steps**:
1. In a PM-bound tab, paste:
```
@developer

Tell me what you'd build for the pre-workout cue overlay.
```
2. **Expect**: PM spawns Developer subagent via Agent tool with the task body.
**Pass criteria**: Subagent spawned, task delegated.

#### I20 — Plain message (no @-mention): normal request
**Steps**:
1. In any bound tab, type a plain message: "what's my next task"
2. **Expect**: Bound role responds directly to user. No subagent spawn.
**Pass criteria**: Normal conversation continues.

---

### Concurrency, JIT, housekeeping

#### I14 — Two terminals open simultaneously, each shows own role
**Steps**:
1. Open Terminal A: `cd ~/Desktop/muster-v3-sandbox && claude` → pick PM
2. Open Terminal B (separate window): `cd ~/Desktop/muster-v3-sandbox && claude` → pick Developer
3. **Expect**: Terminal A status line shows `[muster: pm]`; Terminal B shows `[muster: developer]`. No collision.
**Pass criteria**: Each session shows its own role.

#### I15 — Picker bind with null `.populated.agents.<role>` triggers JIT
**Steps**:
1. In sandbox, manually edit `.populated` and set ONE specialist (e.g., `"qa": null`)
2. `claude` → picker fires
3. Pick QA
4. **Expect**: JIT populate fires (force-binds PM, populates QA agent-context, then re-fires picker)
**Pass criteria**: User-transparent JIT, ends bound to QA.

#### I16 — Stale PID/session files pruned at session start
**Steps**:
1. In sandbox: `touch -t 202003010000 .claude/.muster-bound-role.fake-old-session` (very old file)
2. `claude` (any first message)
3. **Expect**: Old file deleted by session-start housekeeping
**Steps**:
4. Verify: `ls .claude/.muster-bound-role.fake-old-session` should fail (file gone).
**Pass criteria**: Old file gone after session start.

---

### I2 — Greenfield-ongoing: picker fires after Stage 1.3 sets agents.pm
**State**: This is the state after I1 Stage 1.3 — `onboarded_at: null` AND `agents.pm: timestamp`. Manually set this in sandbox if you didn't run Discovery: edit `.populated` and set `agents.pm` to a fake timestamp.
**Steps**:
1. `claude` in sandbox
2. **Expect**: Picker fires (greenfield-ongoing path).
**Pass criteria**: Picker fires.

---

## Fast-track strategies — pick your time budget

### Tier 1: MINIMUM (~10 minutes) — proves v3 works end-to-end
Run only these to gain confidence v3 fundamentally works:

1. **I1-truncated** (~2 min): open sandbox, see welcome fire, close. Proves greenfield-first carve-out + I17.
2. **I4 + I5** (~2 min, one session): manually fast-forward sandbox to steady-state via .populated edit, open Claude, verify picker fires, pick PM, verify monitoring + status line.
3. **I7** (~1 min): `MUSTER_ROLE=developer claude "test"` — verify env var works.
4. **I8** (~2 min): seed queue with one @developer step, run `MUSTER_ROLE=auto`, verify it picks up.
5. **I9** (~1 min): `MUSTER_ROLE=foo claude` — verify halt.
6. **I13** (~1 min): in any bound session, `/rebind` → verify picker re-fires.
7. **I14** (~1 min): open two terminals, verify status lines independent.

**Coverage**: priority-zero (greenfield-first + steady-state), picker mechanism, env var (valid + invalid + auto), /rebind, concurrency.
**Misses**: full Discovery flow, onboarding flow, JIT populate, all 7 specialists individually, @-mention rule, subagent isolation. These are well-documented and lower-risk; failures here would be subtle behavior issues rather than "v3 broken".

### Tier 2: RECOMMENDED (~30 minutes) — gold-standard pre-merge confidence
Tier 1 + add:

8. **I6 (Developer + UI-UX)** (~2 min): bind Developer in one session, UI-UX in another — verify two specialists work, colors differ.
9. **I10** (~1 min): empty queue, `MUSTER_ROLE=auto` — verify halt.
10. **I11 + I12** (~2 min): from Developer session, spawn UI-UX subagent (cross-role) and Developer subagent (same-role parallel) — verify both work without picker recursion.
11. **I15** (~3 min): null one specialist's .populated entry, pick it via picker, verify JIT populate fires.
12. **I16** (~1 min): create stale bound-role file, open new session, verify pruned.
13. **I18 + I19 + I20** (~3 min): @-mention rule end-to-end (matching, non-matching, plain).
14. **I3-truncated** (~3 min): create fake existing project, run setup-existing-project.sh, open Claude, verify orientation fires, abandon.

**Coverage**: everything except full Discovery and 5 of the 7 specialist-specific bootloader tests (which share structure — testing 2 reps the pattern).
**Confidence level**: high. Catches all design-level v3 bugs.

### Tier 3: COMPREHENSIVE (~2-3 hours) — full Discovery validation
Tier 2 + add:

15. **I1 full**: actually do Discovery. Idea share + research + go/no-go + draft review + Sprint 1 plan. ~1-2 hours across 3 sessions.
16. **I6 all 7**: bind each specialist individually.

**Coverage**: complete v3 surface area.
**When to do this**: only if you suspect there might be subtle bugs in the discovery flow under v3 (low likelihood — discovery flow is unchanged from v2, only the carve-out around it is new).

---

## Recommended path

**For pre-merge confidence: Tier 2 (~30 minutes)**.

Tier 1 is fine if you're time-constrained, but it leaves the @-mention rule (most novel v3 behavior) unverified. Adding the 5 minutes for I18-I20 catches the case that's most likely to surprise users.

**Tier 3 is overkill for v3 cutover** — Discovery itself didn't change in v3; only the carve-out around it. Trust the carve-out audit and skip the full Discovery run.

---

## Time-saving tricks

1. **Manually fast-forward `.populated` instead of running Discovery**:
   ```bash
   # Sandbox is at greenfield-first. To test steady-state without running Discovery:
   cd ~/Desktop/muster-v3-sandbox
   cat > knowledge-base/agent-context/.populated <<'EOF'
   {
     "version": "2",
     "onboarded_at": "2026-01-01T00:00:00Z",
     "onboarding_complete_at": "2026-01-15T00:00:00Z",
     "agents": {
       "pm": "2026-01-15T00:00:00Z",
       "developer": "2026-01-15T00:00:00Z",
       "ui-ux": "2026-01-15T00:00:00Z",
       "qa": "2026-01-15T00:00:00Z",
       "content": "2026-01-15T00:00:00Z",
       "marketing": "2026-01-15T00:00:00Z",
       "legal": "2026-01-15T00:00:00Z",
       "research": "2026-01-15T00:00:00Z"
     },
     "lock": null
   }
   EOF
   ```
   This lets you test steady-state picker behavior in seconds. Reset to greenfield by setting all to null again.

2. **Batch tests in single sessions where possible**:
   - One PM-bound session can verify I5, I11 (spawn subagent from PM), I13 (/rebind)
   - One Developer-bound session can verify I12 (parallel), I18 (matching @-prefix), I20 (plain)

3. **Use multiple terminals for concurrency tests** (I14): one new tab per test scenario to avoid setup overhead.

4. **Have helper scripts ready** for env var tests:
   ```bash
   # Test all 4 env-var paths quickly
   MUSTER_ROLE=developer claude "say hi" &
   MUSTER_ROLE=foo claude "say hi" 2>&1 | head -3
   MUSTER_ROLE=auto claude "say hi" 2>&1 | head -3
   ```

5. **For I3 (existing-project onboarding)**: create the smallest possible fake project (`mkdir test-existing && cd test-existing && git init && touch main.py`) — running setup-existing-project.sh on this is fastest. Don't waste time on a realistic project.

6. **Reset between tests** rather than rebuilding sandboxes:
   ```bash
   # Reset bound-role state
   rm /Users/kanwarsandhu/Desktop/muster-v3-sandbox/.claude/.muster-bound-role.* 2>/dev/null
   rm /Users/kanwarsandhu/Desktop/muster-v3-sandbox/.claude/.muster-last-role 2>/dev/null
   ```

---

## After running interactive tests

1. Mark each test as pass/fail in `IMPLEMENTATION-PLAN.md` Phase 10 test matrix
2. If any fail: capture the failure mode, file as bug in muster `feat/v3-role-binding` branch
3. If all pass: proceed to Phase 11 (Arogh dogfood) → Phase 12 (cutover to muster main)
