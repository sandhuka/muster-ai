# Proposal: Session-Level Role Binding for Muster

**Status:** Reviewed by founder — approved for muster team implementation
**Author:** Arogh founder (via Root Claude)
**Date:** 2026-05-09
**Origin project:** Arogh (iOS fitness app, solo founder + AI agent team)

---

## TL;DR

Muster's current model treats Root Claude as the always-on PM and specialist agents as stateless subagents invoked on demand. For users who work in a **multi-tab, one-role-per-tab** pattern, this model produces high token waste and breaks conversational continuity for specialist work. We propose replacing the implicit "PM is default" model with an **explicit role picker at session start** — every Claude Code tab is bound to exactly one muster role for its lifetime, chosen via `AskUserQuestion` on first interaction.

We surface real trade-offs, mitigations, and open questions. The muster team should stress-test this against other workflows (multi-project users, casual users, automated/CI users) before adopting.

---

## 1. Problem Statement

### 1.1 Origin scenario

While working on the Arogh project, the following scenario surfaced repeatedly:

1. Founder asks PM (Root Claude) to coordinate a fix for several bugs.
2. PM cascades context to the developer subagent, which is invoked via the `Agent` tool.
3. Developer subagent reads its briefing chain (5+ files: muster brain file, agent-context, agent-requests, design specs, relevant code), produces a handoff, returns.
4. Founder notices something in the result — has a follow-up question or a small fix to direct.
5. Root Claude spawns a **fresh** developer subagent (the only mechanism available — the `Agent` tool always spawns stateless instances; `SendMessage` is referenced in tool docs but is not exposed in standard Claude Code).
6. The fresh developer re-reads the entire briefing chain to answer one question or make a five-line fix.

The cost of step 5–6 is wildly disproportionate to the work being done. Empirically, ~60% of tokens in a follow-up turn are re-briefing tokens that could have been amortized.

### 1.2 The user's actual workflow

The founder operates in a multi-tab terminal pattern:

- **Tab 1 (PM):** Root Claude as PM. Talks to founder, plans, coordinates, writes to agent-context files, manages orchestration-queue.
- **Tab 2 (Developer):** Opened when developer work is needed. Founder pastes the prompt from orchestration-queue. Developer does the work, files handoff.
- **Tab 3 (UI-UX):** Same pattern when design work is needed.
- **Tab 4 (QA):** Same when test work is needed.

Cross-tab coordination is handled via **muster's existing file-based protocol** (`agent-requests.md`, `orchestration-queue.md`) — when one specialist completes its work, the founder switches back to the PM tab and tells PM "developer is done." PM reads the handoff files, decides the next step, and the founder opens the next tab.

This workflow is the design muster was effectively built around, but **muster's session-level mechanics don't match it.** Specifically:
- Tab 1 (PM) works perfectly — Root Claude is PM by default.
- Tabs 2/3/4 currently rely on the `Agent` subagent system, which doesn't preserve continuity within a tab. Each follow-up question to the developer in Tab 2 spawns a brand-new developer with no memory of prior turns.

The result: Tabs 2/3/4 are not really "developer tabs" or "UI-UX tabs" — they're just "PM tabs that keep invoking specialist subagents." The mental model the founder uses doesn't match the implementation.

### 1.3 Why existing mitigations fall short

Several incremental mitigations were considered (detailed in §3 below). None solve the core problem:

- **Lean briefings** reduce per-call cost but each follow-up still pays a fresh-spawn overhead.
- **`memory: project` on subagents** (Claude Code's built-in feature) reduces re-reading but doesn't preserve turn-to-turn conversational state.
- **Agent Teams** (experimental) provides true continuity but at significantly higher token cost and with known reliability issues; not suitable for solo-founder workflows.
- **Acting as the role informally** (asking Root Claude to "just be the developer for this session") works but produces context bleed because Root Claude's system prompt still loads PM-Mode instructions from muster's CLAUDE.md.

---

## 2. Proposed Solution

### 2.1 Core change

Replace muster's implicit "Root Claude is PM by default" with an **explicit role-picker on first interaction in every session**.

### 2.2 Mechanism

Modify muster's CLAUDE.md priority-zero check so that, after reading `.populated`, if the current session has no role bound yet:

1. Present the user with a role selection via `AskUserQuestion`:
   - PM
   - Developer
   - UI-UX
   - QA
   - Content
   - Marketing
   - Legal
   - Research
2. User selects one option.
3. Claude reads the chosen role's brain file (`muster/team/<role>/CLAUDE.md`) and project context (`knowledge-base/agent-context/<role>.md`) — once.
4. Claude declares the binding ("I am operating as the <role> for this session").
5. Claude proceeds with the user's actual first message in the chosen role.
6. For the rest of the session/tab, Root Claude operates *as* that role — does the work directly, no `Agent` tool calls into the same role.

### 2.3 What stays the same

- File-based cross-tab coordination via `agent-requests.md`, `orchestration-queue.md`, `decision-log.md` — unchanged.
- The `Agent` subagent system still exists — for parallel work, isolation, and intra-session cross-role consults (see §4.2).
- Per-agent brain files, agent-context files, and skills directories — unchanged.
- The `.populated` JIT mechanism for first-time agent invocation — unchanged.

### 2.4 What changes

- Muster's CLAUDE.md routing logic: priority-zero check is restructured to fire role-picker before "First PM question" bootstrap.
- The "PM Mode (Built-in)" mental model in muster docs is replaced with "Role binding (explicit)".
- PM monitoring duties (resolved-handoff cleanup, ui-component-requests notification, stale-entry flagging, Founder Decisions surface) move from "first PM question of a session" to "executed at PM role-bind time, before answering first user question."
- **Visual confidence signal changes**: today, `Agent({subagent_type: "<name>"})` invocations show the agent's assigned color in the console (`muster/CLAUDE.md` L52-54: *"no color = wrong invocation"*). Role-bound primary tabs do NOT get this color — Root Claude is binding in-place (no Agent-tool spawn), so there is no agent process to color. The color signal is replaced by a persistent status-line indicator that reads the bound role from a session-local file and displays it (e.g., `[muster: developer]`) at the bottom of the terminal. This is strictly more useful than the per-spawn color flash: always visible, survives scrolling, and works for PM (which today has no color either). The Agent-tool color signal still applies for §4.2 same-role parallel subagents and §4.6 (a)/(b) cross-role consults — those mechanisms are unchanged. See §5.1 step 9 for the status-line implementation scope.

---

## 3. Approaches Considered and Rejected

### 3.1 Lean briefings + handoff-only context (current best practice)

**Idea:** When spawning a follow-up developer subagent, brief it with just the prior handoff ID instead of asking it to re-read all briefing files.

**Why it's not enough:** Reduces token waste per follow-up but doesn't address the underlying issue. Every follow-up is still a fresh spawn paying briefing overhead. Doesn't match the user's mental model of "I'm continuing my conversation with the developer."

**Verdict:** Useful as an interim mitigation. Insufficient as the long-run answer.

### 3.2 Subagent persistent memory (`memory: project` frontmatter)

**Idea:** Add `memory: project` to each specialist subagent. Claude Code auto-loads the subagent's `MEMORY.md` (first 200 lines / 25KB) on each spawn. Over time, accumulated learnings reduce briefing reads.

**Why it's not enough:** Memory ≠ continuity. The subagent still spawns fresh each turn — it just has a curated cheat-sheet of accumulated knowledge. The conversational thread is still lost. The user explicitly named this: *"this does not help me with the problem of continue chatting with the agent until it's exit."*

**Verdict:** Orthogonal improvement. Worth adopting independently. Does not solve the continuity problem.

### 3.3 Agent Teams (experimental Claude Code feature)

**Idea:** Set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Each "teammate" is a full Claude Code session with mailbox-style messaging between them. True per-teammate continuity.

**Why it's not enough:**
- Each teammate is a full session, so token cost is significantly higher than subagents.
- Known reliability issues with session resumption.
- Still experimental — API/behavior may change.
- Overkill for solo-founder workflows.

**Verdict:** Not the right tool for this use case.

### 3.4 Don't use subagents; have Root Claude "act as developer" informally

**Idea:** Founder opens a tab and says "Read `muster/team/developer/CLAUDE.md` and act as the developer for this session." Root Claude does the work directly. Full conversational continuity within the tab.

**Why it's not enough on its own — but is the seed of the proposal:**
This works today and gives true continuity. The problem is **context bleed**: muster's CLAUDE.md and the project CLAUDE.md are auto-injected into Root Claude's system prompt on every session, including PM Mode instructions, monitoring duties, hub-and-spoke rules. Even when the founder asks Root Claude to "just be the developer," the PM behaviors leak — Root Claude may proactively cascade decisions, write to agent-context files (Rule 3 violation), or run PM monitoring duties unprompted.

**Verdict:** Core insight (session-bind to a role) is correct. Implementation must be explicit, not informal, to prevent bleed.

### 3.5 PM-default + `/become-developer` overlay command

**Idea:** Keep PM as Root Claude's default. Add `/become-<role>` slash commands that override the role for the rest of the session.

**Why it's not enough:** Three compounding defects:
- **Bleed risk**: PM context is already loaded by the time the user invokes `/become-developer`. The skill can suspend PM mode in instructions, but PM-Mode text remains in the system prompt and Claude can leak on edge cases.
- **Token waste**: Every session pays the full PM-Mode read cost upfront, then has to actively suppress it after the slash command fires. The picker pays one read of the chosen role's files, period.
- **Forgetability**: User opens a dev tab, forgets to invoke `/become-developer`, starts asking dev questions to a Claude that has loaded PM Mode — silent degradation to today's broken state. The picker can't be forgotten because it auto-fires.
- **Asymmetry**: PM is the "real" role, others are overlays. This is exactly the mental model that caused the original bleed problem, just relocated.

**Verdict:** Half-measure. Rejected during founder review for the reasons above. Replaced by §3.6.

### 3.6 Explicit role picker at session start (the proposal)

**Idea:** No implicit default. Every session starts by asking the user which role this tab is for. Symmetric across all roles, including PM.

**Why this is better:**
- Eliminates context bleed: there's no implicit PM context to leak from.
- Symmetric: PM isn't special-cased. Same model for every role.
- Self-documenting: new muster users learn "every tab picks a role" immediately.
- Forces conscious choice: founder cannot accidentally ask PM questions in a developer tab without realizing they should switch tabs.
- Matches the multi-tab workflow exactly.

**Verdict:** Recommended for stress-testing.

---

## 4. Concerns and Open Questions

The muster team should weigh these before adopting.

### 4.1 PM monitoring duties placement

**Concern:** Today, PM monitoring duties (resolved-handoff cleanup, stale-entry flagging, ui-component-requests notification, Founder Decisions surface) run on the "first PM question of a session." If sessions don't auto-bind to PM, these duties only fire when a user explicitly opens a PM tab. Stale handoffs and unanswered Founder Decisions could accumulate unseen for days.

**Proposed mitigation:** When the user picks PM in the role-picker, that role's bind step explicitly runs all PM monitoring duties before answering the user's first message. This preserves today's effective behavior, just gated on explicit role selection rather than implicit PM-default.

**Open question:** Is there a category of monitoring that *must* run on every session regardless of role? If so, those need to live somewhere outside the PM bind step (perhaps in the priority-zero check itself).

### 4.2 Two coexisting invocation patterns

**Concern:** After this change, muster has two patterns for getting specialist work done:
- **Tab-level role binding** (new) — for extended work as a single role.
- **`Agent` subagent invocation** (existing) — for parallel work, isolation, or quick cross-role consults from within a bound tab.

This is good (each pattern solves a real need), but the docs need to clearly state when each applies. Without clarity, users will pick inconsistently.

**Proposed guidance:**
- Use **tab-level binding** when: you'll be doing extended work as one role; you want conversational continuity for iterative refinement; you're following the canonical multi-tab workflow.
- Use **`Agent` subagents** when: you need parallel work across roles; a role-bound session needs a quick second opinion from another role without opening a new tab; the work is genuinely one-shot and isolation is desirable.

**Resolved (founder review):** Same-role subagents from a role-bound session are **allowed** for parallel/side work, modeled on Claude Code's `/btw` pattern. Document as "permitted for parallel work; brief them well; not a substitute for role binding for follow-up work."

### 4.3 Migration cost

**Concern:** This is a non-trivial restructure of muster's CLAUDE.md. Specifically:
- Priority-zero routing logic is replaced.
- "PM Mode (Built-in)" section is removed/replaced with "Role binding (explicit)."
- Decision-log entries that reference "PM Mode" need updating (or stay as historical).
- All eight specialist agent brain files need a "you are the bound role for this session" mode added.
- Project CLAUDE.md files in existing muster projects need migration guidance.

**Estimate:** 4–8 hours of focused refactor for the muster repo. Plus migration documentation for existing muster projects.

**Open question:** Should this ship as a flag-gated v3 feature first (`MUSTER_ROLE_BINDING=1`) for opt-in adoption, or as a full v3 cutover? Flag-gated reduces risk but increases code complexity.

### 4.4 First-message friction

**Concern:** Every session now requires a role-picker interaction before the user can ask anything. For users who open a tab to ask a quick PM question, this adds one extra interaction.

**Mitigation considerations:**
- The picker can be very fast (single-key selection from a numbered list).
- If the user types a message before picking, the picker fires before the message is processed (using `AskUserQuestion` from within the priority-zero check).
- Power users could optionally bind a default role per project via a config file (e.g., `.muster-role-default = pm`), so they can skip the picker for their most-common role.

**Resolved (founder review):** Friction is acceptable in exchange for symmetric mental model and unforgettable binding. Documentation/onboarding teaches the canonical convention: **PM = first tab, specialists in subsequent tabs as the orchestration queue dictates**. The picker is a one-time-per-session cost; the alternative (`/become-<role>` slash command) trades that away for permanent asymmetry and forgetability — see §3.5.

### 4.5 Single-tab users

**Concern:** Some muster users may not use the multi-tab pattern at all — they have one tab, ask whatever they need (PM questions, developer work, design questions) within it, and rely on Root Claude to invoke specialists as subagents.

For these users, the new model is *worse*: they'd have to pick PM (since coordination is their primary need) and then invoke specialist subagents via the `Agent` tool — basically today's behavior, with one extra picker step at session start.

**Mitigation:** This is mostly a documentation issue. The role-picker should make clear: "Pick PM if you want to coordinate work and invoke specialists as needed. Pick a specialist if this tab will focus exclusively on that role's work."

**Resolved (founder review):** Multi-tab is documented as muster's canonical Option B "hot loop" already (`system-guide.md` L320-323). The convention will be taught explicitly via onboarding: PM as first tab handles coordination and subagent invocation for casual use; specialist tabs are opened only when extended same-role work is planned. Single-tab users effectively keep today's behavior with one extra picker step at session start.

### 4.6 Cross-role consults from a bound tab

**Concern:** Founder is in a developer-bound tab. Developer hits a question that genuinely needs UI-UX input (e.g., "should this animation be 200ms or 300ms?"). Options:
- (a) Open a new UI-UX tab — heavy, breaks flow.
- (b) Spawn a UI-UX subagent in the developer tab — works, but the subagent inherits the developer-bound system context, which may be confusing.
- (c) Write a request to `agent-requests.md` and switch to UI-UX tab — current pattern, slow.

**Resolved (founder review):** **(c) is the default for cross-role consults regardless of size.** Rationale: muster's core philosophy (`architecture-and-design.md` L350-354 mistake #5) is "agents communicate through files, not conversation. Conversations are ephemeral. Files persist." Defaulting to (c) ensures every cross-role decision flows through PM and updates relevant durable docs. (a) and (b) are **permitted exceptions only for throwaway trivia** where the answer wouldn't survive a `decision-log` entry anyway (e.g., "what's the TA token for warning color"). Test: if the answer would deserve a decision-log entry, route through (c). Document this stance in the muster system guide.

### 4.7 PM responsibilities that today bypass session boundaries

**Concern:** Today's PM monitoring duties include things like "reconcile resolved handoffs at session start." If the user goes a week without opening a PM tab, these reconciliations don't happen. Today's implicit-default model accidentally protects against this because almost every session starts as PM.

**Resolved (founder review):** When the user picks a non-PM role at session start, the bind step **also runs a lightweight scan** of `agent-requests.md` and `orchestration-queue.md` for stale items (>3 days open handoffs, unanswered Founder Decisions, `Status: done` entries needing cleanup) and surfaces a single one-line notice — e.g., *"PM has 3 stale handoffs and 1 Founder Decision pending — consider opening a PM tab when you're done here."* This preserves the safety net without forcing a full PM bootstrap in non-PM tabs. The scan is read-only; cleanup still happens in a PM tab.

### 4.8 What about hooks and automation?

**Concern:** Some muster users may have SessionStart hooks, automated `claude` invocations from CI, or cron-scheduled muster runs. These can't interactively answer a role-picker.

**Mitigation:** Support an environment variable or CLI flag for non-interactive role binding (`MUSTER_ROLE=developer claude ...`). The role-picker is skipped if this is set. For automated workflows, the role is declared explicitly by the invoker.

**Resolved (founder review):** Ship with `MUSTER_ROLE` env var support from v1. Behavior:
- `MUSTER_ROLE=<valid-role>` set → skip picker, bind to that role.
- `MUSTER_ROLE` unset → fire picker (interactive sessions only).
- `MUSTER_ROLE=<invalid-role>` set → **halt with explicit error**, do not silently fall through to picker. Silent fallback would hide automation bugs.

Forward-looking rationale: muster is expected to be invoked from non-Claude-Code surfaces eventually (mobile clients, CI pipelines, scheduled hooks). Designing the env-var contract now means those integrations don't require retrofitting.

### 4.9 PM symmetrization

**Concern:** PM is structurally asymmetric in muster today. It is not registered in `.claude/agents/`, not invokable as a subagent via `Agent({subagent_type: "pm"})`, and is auto-loaded into Root Claude's system prompt via the "PM Mode (Built-in)" section of `muster/CLAUDE.md`. The PM brain file (`muster/team/pm/CLAUDE.md`) is written as "you ARE Root Claude, here's how to PM" rather than "you are the PM role for this session." For the role-picker to be truly symmetric, PM has to become a peer of the other seven agents — which is a load-bearing structural change with multiple touchpoints.

**Resolved (founder review):** PM is symmetrized to peer status. Specific sub-tasks are listed in §5.1 step 8. Concrete file-level changes:
- Create `.claude/agents/pm.md` (project-level + add to `muster/templates/.claude/agents/`) with the same shape as the other seven (halt check, always-read list, session-completion protocol). The existing PM monitoring duties live here and fire at PM bind time.
- Restructure `muster/team/pm/CLAUDE.md` to drop "Root Claude IS the PM" framing. Rewrite as "you are the PM role for this session" — same voice as the other seven brain files.
- Remove "PM Mode (Built-in)" section from `muster/CLAUDE.md`. Replace with "Role Binding (Explicit)" section documenting the picker mechanism. The 8-file PM bootstrap read list (currently muster/CLAUDE.md L66-74) moves into the new PM brain file or `.claude/agents/pm.md`, fired at PM bind time.
- Update Rule 1: "PM is the hub (Root Claude)" → "PM is the hub (a role like any other; bind a tab to PM via the role picker)."
- Update Agent Roster table: PM row no longer says "Built-in — Root Claude IS the PM." Becomes a peer row.
- `.populated` `agents.pm` semantics stay intact (greenfield Stage 1.3 timestamping, JIT populate, etc.) — those are about onboarding lifecycle, not runtime role binding.

**Special carve-outs in the priority-zero check** (the picker does NOT fire in these paths; PM is force-bound and the relevant skill fires immediately):
- Greenfield first session (`onboarded_at` null AND `agents.pm` null) → force-bind PM, fire `greenfield-discovery.md` Stage 1 welcome. Picker would break the welcome flow.
- Existing-project onboarding active (`onboarded_at` set AND `onboarding_complete_at` null) → force-bind PM, fire `reverse-discovery.md` Phase 1 orientation. Picker would derail Phases 1-11.
- All other paths (steady-state, greenfield ongoing, missing/invalid `.populated`) → picker fires normally.

**Risk during implementation:** the interaction between the existing `.populated` lifecycle and the new picker is the area most likely to introduce regressions. The prototype phase (§5.2 step 1) explicitly targets PM + Developer first to surface these edges before expanding to the other six roles.

### 4.10 Stress-test findings — failure modes uncovered during founder review

Six implementation-level defects were identified during stress-testing the proposal against the autonomy vision and `--dangerously-skip-permissions` invocation patterns. All have fixes folded into §5.1 (steps 10-15).

**F1. Multi-tab `.muster-bound-role` race condition.** Proposed single-file approach has tabs overwriting each other's role. Tab 1 (PM) status line displays `developer` because Tab 2 (Developer) just wrote it — visual confidence signal lies. **Fix**: PID-suffix the file: `.claude/.muster-bound-role.<pid>`. Status-line script reads its own parent PID. See §5.1 step 10.

**F2. `AskUserQuestion` is not bypassed by `--dangerously-skip-permissions`.** That flag only skips tool permission prompts, not user-input prompts. Picker hangs forever in headless flows that forget `MUSTER_ROLE`. **Fix**: muster docs explicitly state autonomous flows MUST set `MUSTER_ROLE`; picker is interactive-mode-only. See §5.1 step 11.

**F3. Tool-permission asymmetry between picker-bound and subagent-invoked roles.** `.claude/agents/<name>.md` startup configs constrain tools per role. When picker binds Root Claude to a role, Root Claude keeps its FULL toolset; Agent-tool subagents remain tool-constrained per their config. Picker-bound legal can do things subagent-spawned legal cannot. Claude Code does not currently support mid-session tool restriction — this gap cannot be fully closed without platform support. **Fix**: document the asymmetry honestly. See §5.1 step 12.

**F4. Subagent inheritance of "fire picker" instructions.** A role-bound dev tab spawns a UI/UX subagent for cross-role consult → subagent reads muster CLAUDE.md → sees "Role Binding" section → may try to fire its own picker (recursive picker hell). **Fix**: muster CLAUDE.md "Role Binding" section explicitly states picker fires only at primary-tab session start; Agent-tool subagents bind via `subagent_type` argument and never fire the picker. See §5.1 step 13.

**F5. Picker bypass of `.populated` JIT halt path.** Today's `HALT: agent-context null` check lives in `.claude/agents/<role>.md` and fires on subagent invocation. The picker reads role brain + agent-context directly, bypassing the halt. If the picked role's `.populated` entry is null, Claude operates with empty context. **Fix**: picker logic replicates the halt check — null entry forces JIT-populate via PM bind first, then re-fires picker. See §5.1 step 14.

**F6. `AskUserQuestion` 4-option ceiling vs 8 muster roles.** The tool supports 2-4 options per question. Muster has 8 roles. A single-question picker is structurally impossible. This is a hard blocker, not polish. **Fix**: two-step picker — first question groups roles (Coordination / Build / Communicate / Validate), second question picks within group. Adds one extra interaction at session start; also serves as the W7 grouping UX clarity benefit at zero additional cost. See §5.1 step 15.

### 4.11 Autonomy vision gap

**Concern:** This proposal solves role binding for INTERACTIVE multi-tab work. It does not directly serve the long-term autonomy vision (founder ideates → product launches autonomously, with `--dangerously-skip-permissions`, minimal founder involvement). To get there, the picker is necessary but not sufficient.

**Gaps not addressed by this proposal:**
- **Orchestrator daemon** — something must read `orchestration-queue.md` and spawn the right role tab automatically. External supervisor (cron, GitHub Actions, file watcher).
- **Handoff trigger** — when a specialist finishes and updates the queue, who notifies the next role? Today: founder. Autonomous: file-watcher + auto-spawn.
- **Founder Decisions blockers** — autonomous flows hit founder-decision questions; need pause-and-notify mechanism (email, mobile push, etc.).
- **Quality gates** — auto-spawn QA after dev handoff, halt orchestrator on QA fail.
- **Cross-platform invocation surfaces** — mobile, web, CI all need API role contract beyond env var.

**Resolved (founder review):** v3 ships the picker plus `MUSTER_ROLE=auto` semantics (§5.1 step 16) which makes the picker compatible with a future orchestrator daemon. The orchestrator daemon, handoff trigger, and Founder Decisions notification layer are explicitly OUT OF SCOPE for v3 — they belong to a future muster-orchestrator workstream that builds on top of v3 role binding. Documenting the gap here so the muster team doesn't expect v3 alone to deliver autonomy.

---

## 5. Recommendation

After founder review, the proposal is **approved for implementation as muster v3**. All §4 open questions are resolved in-section above.

### 5.1 Implementation scope

The following changes constitute the v3 cutover:

1. **Priority-zero check restructure** (`muster/CLAUDE.md`): Replace the implicit "Root Claude is PM by default" model with explicit role-binding. After the existing `.populated` routing check, if no role is bound for the current session:
   - If `MUSTER_ROLE` env var is set to a valid role → bind to that role, skip picker.
   - If `MUSTER_ROLE` is set to an invalid role → halt with explicit error.
   - Otherwise → fire `AskUserQuestion` picker with all eight roles (PM, Developer, UI-UX, QA, Content, Marketing, Legal, Research).
   - On selection → read the chosen role's brain file (`muster/team/<role>/CLAUDE.md`) and project context (`knowledge-base/agent-context/<role>.md`); declare the binding; proceed with the user's first message as that role.

2. **PM Mode → Role Binding** (`muster/CLAUDE.md`): The "PM Mode (Built-in)" section is replaced with a "Role Binding (Explicit)" section. PM monitoring duties move from "first PM question of a session" to "executed at PM role-bind time." All eight roles get a "you are the bound role for this session" mode in their brain files.

3. **Non-PM bind side-scan**: When a non-PM role is selected, the bind step performs a read-only scan of `agent-requests.md` and `orchestration-queue.md` for stale items / unanswered Founder Decisions / Status:done cleanup, and surfaces a one-line notice.

4. **Cross-role consult policy** (`muster/system-guide.md`): Document option (c) (file-based via `agent-requests.md`) as the default for cross-role consults regardless of size. Permit (a)/(b) only for throwaway trivia. Include the "would this answer survive a decision-log entry" test.

5. **Same-role subagents allowed**: Document that role-bound sessions may invoke same-role subagents for parallel/side work (Claude Code `/btw` analog). Brief them well; do not use for follow-up work that role binding already handles.

6. **Onboarding update**: Documentation/onboarding teaches the canonical multi-tab convention — PM as first tab, specialist tabs in subsequent terminals as the orchestration queue dictates.

7. **Migration**: Project `CLAUDE.md` files in existing muster projects need migration guidance. Decision-log entries that reference "PM Mode" stay as historical (Rule 15 note: history belongs in transient artifacts, but decision-log is a transient artifact, so leaving the mention is consistent).

8. **PM symmetrization** (load-bearing — see §4.9 for full detail): PM is restructured from "Root Claude IS the PM" to a peer role. Specifically:
   - Create `.claude/agents/pm.md` (project + `muster/templates/`) mirroring the other seven agents' structure.
   - Rewrite `muster/team/pm/CLAUDE.md` voice from "you ARE Root Claude" to "you are the PM role for this session."
   - Remove "PM Mode (Built-in)" section from `muster/CLAUDE.md`; replace with "Role Binding (Explicit)." Move the 8-file PM bootstrap read list into the new PM brain/startup files, fired at PM bind time.
   - Update Rule 1 wording and the Agent Roster table to reflect peer status.
   - `.populated` `agents.pm` semantics unchanged (onboarding lifecycle, not runtime binding).
   - Priority-zero check carve-outs: greenfield-first-session and existing-project-onboarding paths force-bind PM (skip picker) so `greenfield-discovery.md` and `reverse-discovery.md` can fire immediately. All other paths fire the picker normally.

   Implementation note for Claude executing this work: §4.9 + step 8 here are the most error-prone part of the v3 cutover. Treat the `.populated` × picker interaction as a hot zone — verify each priority-zero path explicitly before calling implementation done.

9. **Status-line bound-role indicator**: Replace the lost agent-color confidence signal (see §2.4) with a persistent status-line display.
   - **Picker writes** the bound role to `.claude/.muster-bound-role.<pid>` (PID-suffixed per F1 fix in step 10) on selection. Force-bind paths (greenfield welcome, reverse-discovery) write `pm`. Gitignored — session-local state, not shared across teammates.
   - **Status-line script** ships as `muster/templates/.claude/statusline.sh` (or equivalent). Reads its own parent PID's bound-role file and prints `[muster: <role>]`. If the file is missing or empty, prints `[muster: unbound]` (visible signal that picker did not fire — should not happen in normal flow but useful for debugging).
   - **settings.json wiring**: muster's project setup scripts add the `statusLine` config pointing to the script. Existing projects get migration guidance to add the same.
   - **Session end**: bound-role files are pruned at next session start (step 10 cleanup). No active session-end hook required.
   - **Cross-platform**: ship a portable bash script as default; document Windows-equivalent for muster users on PowerShell.
   - **Reference**: Claude Code provides a `statusline-setup` skill for configuring this — use it during implementation rather than hand-rolling settings.json edits.

10. **Picker file: PID-suffix + startup prune** (fixes F1): bind file is `.claude/.muster-bound-role.<pid>` not a single shared file. Status-line script reads its own parent PID and finds the matching file. At session start, prune any bound-role files whose PIDs are no longer alive (5-line script — `for f in .claude/.muster-bound-role.*; do kill -0 ${f##*.} 2>/dev/null || rm "$f"; done`). Prevents accumulation if Claude exits without cleanup.

11. **Autonomous-mode contract** (fixes F2): muster CLAUDE.md and `getting-started.md` explicitly state that autonomous flows (cron, CI, hooks, headless `claude` invocations) MUST set `MUSTER_ROLE`. Picker is interactive-mode only. `--dangerously-skip-permissions` does NOT auto-answer the picker. Provide example invocations for the most common autonomous patterns (cron job, GitHub Actions step, scheduled agent via `CronCreate`).

12. **Tool-permission asymmetry documented** (fixes F3): muster `system-guide.md` adds a one-paragraph note that picker-bound roles inherit Root Claude's full toolset, while Agent-tool subagents remain tool-constrained per their `.claude/agents/<name>.md` config. Until Claude Code supports mid-session tool restriction, this asymmetry stands. Honest documentation > pretending it doesn't exist. File a Claude Code upstream feature request alongside the SendMessage ask in §5.3.

13. **Subagent picker isolation** (fixes F4): muster CLAUDE.md "Role Binding (Explicit)" section explicitly states: picker fires only at primary-tab session start. Agent-tool subagents bind via their `subagent_type` argument and never fire the picker. Prevents recursive picker hell during cross-role consults (§4.6 (a)/(b) flows) and same-role parallel work (§4.2). Also re-state the existing warning against `subagent_type="general-purpose"` so readers don't have to cross-reference §3.

14. **Picker JIT-populate handling** (fixes F5): picker logic checks `.populated.agents.<picked-role>` before reading the role's agent-context. If null, force-bind PM first to run JIT populate per `context-cascading.md` → Just-in-time mode, then re-fire picker. Mirrors the existing subagent halt-check behavior. Without this, picker silently binds to a role with empty project context.

15. **Two-step picker** (fixes F6 — required because `AskUserQuestion` supports max 4 options per question): first question groups roles (Coordination → PM; Build → Developer / UI-UX / QA; Communicate → Content / Marketing; Validate → Research / Legal). Second question picks within group. The grouping serves as W7's UX-clarity benefit at zero additional cost. PM lives alone in Coordination — single-option group, so first-question selection of "Coordination" can short-circuit straight to PM bind without firing the second question.

16. **`MUSTER_ROLE=auto` semantics** (W1 + W8 folded): when `MUSTER_ROLE=auto` is set, skip picker, read `orchestration-queue.md` Next Step entry, bind to whatever role that step assigns. If queue is empty, malformed, or Next Step is missing, halt with explicit error — NEVER silently default to PM. Makes future orchestrator daemon trivial: `MUSTER_ROLE=auto claude --dangerously-skip-permissions "execute next step"` in a loop. **Strongest single ROI item in v3** — one extra branch in the priority-zero check, unlocks the whole autonomy runtime.

17. **`/rebind` slash command** (W2): re-fire picker mid-session for "I picked the wrong role" recovery. Single skill file, ~10 lines. Re-runs steps 14 + 15 (JIT check + two-step picker), overwrites bound-role file. Does not affect conversation context — Claude is expected to switch role mid-conversation when invoked.

18. **Picker remembers last role per project** (W3): after binding, write last-selected role to `.claude/.muster-last-role` (project-level, gitignored, NOT PID-suffixed — last-role is a project preference, not a session state). Next session, picker pre-selects that as default for single-keypress confirm. Reduces friction for stable workflows.

19. **Bind log** (W5): every role bind appends one line to `knowledge-base/.muster-bind-log`: timestamp, role, invoker (`interactive` | `env-var` | `auto`), PID. Audit trail for `--dangerously-skip-permissions` autonomous mode and orchestrator daemon debugging. Cap at 500 entries; rotate to `.muster-bind-log.archive` when exceeded. Tracked in git so teammates and future-you can audit autonomous behavior.

### 5.2 Sequencing

1. Prototype the picker in muster CLAUDE.md and one role's brain file (PM + Developer).
2. Dogfood for one sprint in the originating Arogh project.
3. If stable, expand to all eight roles, ship system-guide updates, write migration notes for existing muster projects.
4. Cut as muster v3.

### 5.3 Parallel upstream asks

Independent of this proposal, file two requests with the Claude Code team:

1. **`SendMessage`-equivalent for subagent continuity** — would let any harness preserve subagent continuity across turns. This proposal is a muster-side workaround for that platform gap; the upstream fix benefits every multi-agent system, not just muster.
2. **Mid-session tool restriction API** — would close the §4.10 F3 asymmetry. Lets a session declare "for the rest of this session, my available tools are <subset>" so picker-bound roles can match the tool constraints of subagent-spawned roles.

Not blocking — ship v3 now, but don't let the proposal's existence kill the upstream asks.

### 5.4 Deferred to v3.1 (evaluated and intentionally not in v3)

Two enhancements were identified during stress-testing but excluded from v3 due to regression risk or marginal value:

- **Auto-detection of role mismatch (W4)**: if `MUSTER_ROLE=developer` but first message is clearly PM-type (`"plan the next sprint"`, `"what's our status"`), halt and surface mismatch. **Why deferred**: keyword-heuristic false positives could halt legitimate work (e.g., dev being asked to "plan the implementation" might trigger PM keyword). Build when autonomous orchestrator ships, with proper test coverage.
- **Status-line queue context enrichment (W6)**: enrich `[muster: developer]` to `[muster: developer | step 3/7 | 2 stale items]` by parsing `orchestration-queue.md` and `agent-requests.md`. **Why deferred**: markdown parsing in shell is fragile; format drift breaks status line silently. Ship simple version in v3, enrich in v3.1 once queue/requests format is locked and parser can be tested.

Both items move from "future maybe" to "v3.1 backlog" — they have specific gating conditions for being picked up.

---

## 6. Appendix: How this proposal was shaped

This proposal was developed in a single Root Claude session through iterative discussion between the Arogh founder and Root Claude. The path:

1. Founder noticed token waste on a developer follow-up (cue/pills disappearing question, post-HO-032).
2. Asked why each follow-up spawns a fresh developer.
3. Root Claude explained the `Agent` tool's stateless model and the absent `SendMessage` capability.
4. Founder asked whether Claude Code provides any first-class continuity mechanism. Research via `claude-code-guide` confirmed: no, except experimental Agent Teams.
5. Subagent `memory: project` was proposed and rejected as orthogonal.
6. "Act as developer informally" was proposed; founder pushed back due to bleed risk.
7. PM-default + `/become-X` overlay was proposed; founder identified the PM-context-bleed flaw.
8. Founder proposed the explicit role-picker design — the cleaner version.
9. This document captures the full reasoning chain so the muster team can evaluate without re-deriving it.

---

**End of proposal.**
