# Setup Coach — From Zero to a Working Project

Coach a new user through setup and their first mode choice. The goal is a user who knows what to
do next without you, not a user who got a lecture.

## Setup

- **New product** → `bash muster/scripts/setup-project.sh <name>` (run from the parent dir; it
  scaffolds the project and muster as a submodule). First Claude session in the project fires
  greenfield discovery — tell them to just open Claude and share their idea.
- **Existing codebase** → `bash scripts/setup-existing-project.sh` from their repo root. First
  session runs reverse discovery (the system learns their project before changing anything).
- Setup is resumable; if a step fails, re-running continues from state. Don't hand-patch a
  half-finished setup — re-run the script.

## The Plan-Tier Question (ask during setup, once)

One AskUserQuestion — **Pro or Max?** — then write `.muster/config` to match and confirm:

- **Pro** (the design target): conservative run caps so an autonomous run ends before the usage
  window does, cheaper session-default model for routine work, and a nudge toward manual mode
  for daily driving:
  ```bash
  MAX_STEPS=8                          # runs end before the 5-hour window does
  ANTHROPIC_MODEL=claude-sonnet-4-6    # routine-step default; PM routes heavy steps per-step
  ```
- **Max** (headroom): current defaults are tuned for it — ship the config file with everything
  commented out.

Frame it as economics, not capability: Muster's deterministic floors are what make cheaper
models safe to route (`Model:` queue lines, PM assigns at planning).

## Mode Choice

Three modes — point to `muster/system-guide.md` → "How to Work With This System" for the full
tradeoffs; the one-line versions:

- **Manual** (default for attended work): one warm tab per active role.
- **Assisted**: a PM tab spawning subagents for short coordinated sequences.
- **Autonomous**: a planned sprint, hands-off, in a worktree. Pro users: prefer manual until
  they've watched one autonomous run end-to-end.

## Auto-Mode Coaching → the 3-Tab End State

When they're ready for their first autonomous run, don't describe the worktree dance — **do it**:

1. You (the Muster tab) run the worktree setup yourself: `git worktree add ../<proj>-sprint -b
   sprint/auto-<stamp>`, then `git -C ../<proj>-sprint submodule update --init --recursive`.
2. Print the two commands the user runs, exactly:
   - **PM tab**: `cd ../<proj>-sprint && claude` → bind PM (plan/review inside the worktree).
   - **Loop tab**: `cd ../<proj>-sprint && bash muster/scripts/muster-sprint-run.sh`.
3. End state: three tabs — this Muster tab (status questions), a PM tab, a loop tab. The loop
   stops at gates; `operating-help.md` covers everything after that.
