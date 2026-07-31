---
description: Re-fire the role-picker mid-session and bind to a new role
allowed-tools: Read, AskUserQuestion, Bash(bash muster/scripts/muster-boot.sh), Bash(bash muster/scripts/muster-boot.sh:*)
---

# /rebind — Mid-session role re-binding

Use when you picked the wrong role at session start, finished one role's work and want to switch in-tab, or need a temporary role switch.

## Steps

1. Run `bash muster/scripts/muster-boot.sh` and obey its `ROUTE=` line (full contract: `muster/CLAUDE.md` → Role Binding). On `ROUTE=pick`, fire the two-step picker from the printed `GROUP=` lines, then run the `AFTER_PICK=` command with the picked role. A `ROUTE=onboarding` result means onboarding is still active and boot has re-bound PM — tell the user re-binding away from the discovery flow isn't available until onboarding completes.
2. Declare *"Re-binding to <Role> for this session."* and read `.claude/agents/<role>.md` (the bootloader handles brain file + agent-context + queue + requests + role-specific reads). Surface any `NOTICE=` line from boot as a one-line aside.

## After /rebind completes

The conversation continues. Previous turns remain in context (they happened, can be referenced), but the operative role for new responses is the rebound one. The status-line indicator updates to `[muster: <new-role>]` on next refresh.
