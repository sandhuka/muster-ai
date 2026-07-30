---
description: Re-fire the role-picker mid-session and bind to a new role
allowed-tools: Read, Write, Edit, Bash(echo *), Bash(cat *), Bash(date *), AskUserQuestion
---

# /rebind — Mid-session role re-binding

Re-execute the role-picker mechanism from `muster/CLAUDE.md` "Role Binding" section, then update the session's bound-role state. Conversation context is preserved; subsequent responses operate as the new role.

## Use cases

- You picked the wrong role at session start (e.g., picked Developer but actually need PM).
- You finished one role's work in this tab and want to switch instead of opening a new tab.
- You're in a long-running session and need to switch roles temporarily.

## Steps (execute in order)

1. **Onboarding safety check**: read `knowledge-base/agent-context/.populated`. If `onboarded_at` is set AND `onboarding_complete_at` is null (existing-project onboarding active) OR `onboarded_at` is null AND `agents.pm` is null (greenfield first session), warn the user: *"Onboarding flow is active. Re-binding may interrupt the discovery skill. Continue?"* — confirm via AskUserQuestion before proceeding.

2. **Fire two-step picker** per `muster/CLAUDE.md` Role-picker mechanism step 2:
   - Q1 (role group): Coordination | Build | Communicate | Validate
   - Q2 (role within group):
     - Coordination → PM (single-option short-circuit)
     - Build → Developer | UI-UX | QA
     - Communicate → Content | Marketing
     - Validate → Research | Legal

3. **JIT populate check** per step 3: if `.populated.agents.<picked-role>` is null, force-bind PM, run JIT populate per `muster/team/pm/skills/generic/context-cascading.md`, then re-fire picker.

4. **Bind step** per step 4:
   - Declare visibly: *"Re-binding to <Role> for this session."*
   - Read `.claude/agents/<role>.md` (the bootloader handles brain file + agent-context + queue + requests + role-specific reads)
   - Overwrite the bind file: `echo "<role>" > .claude/.muster-bound-role.$CLAUDE_CODE_SESSION_ID`

5. **Last-role memory** per step 5: write the new role name to `.claude/.muster-last-role` (interactive — `/rebind` is always user-invoked).

6. **Bind log** per step 6: append to `knowledge-base/.muster-bind-log`:
   ```bash
   echo "$(date -Iseconds) <role> interactive $CLAUDE_CODE_SESSION_ID" >> knowledge-base/.muster-bind-log
   ```

7. **Non-PM side-scan** if newly-bound role is not PM: run the side-scan per `muster/CLAUDE.md` "Non-PM bind side-scan" section. Count stale items in `agent-requests.md` and unanswered Founder Decisions in `orchestration-queue.md`. Surface the one-liner notice if anything stale.

## After /rebind completes

The conversation continues. Previous turns remain in context (they happened, can be referenced), but the operative role for new responses is the rebound one. The status-line indicator updates to `[muster: <new-role>]` on next refresh.
