#!/usr/bin/env bash
# muster-sprint-new.sh — create an isolated sprint worktree and print its path, WITHOUT running
# the loop. Use this for the two-tab autonomous flow: create the worktree first, open an
# interactive PM tab INSIDE it (plan / handle halts), then run the loop in a second tab — also
# inside it. Both tabs share the worktree's tree, so PM's edits reach the loop with no syncing.
#
# For the all-in-one "create worktree + run loop" path (no interactive PM tab), use
# muster-sprint-sandbox.sh instead.
set -euo pipefail
BRANCH="sprint/auto-$(date +%Y%m%d-%H%M%S)"
WT="../$(basename "$PWD")-${BRANCH//\//-}"
git worktree add "$WT" -b "$BRANCH"
# `git worktree add` checks out the superproject but NOT its submodules, so the new worktree's
# muster/ would be empty and `bash muster/scripts/...` below would fail. Populate it from the
# committed pointer. (No-op in a project that has no submodules.) NOTE: this checks out the
# COMMITTED submodule SHA — if you bumped muster to a different ref, commit that pointer in the
# project first, or the worktree runs the old version.
git -C "$WT" submodule update --init --recursive
echo "Worktree ready: $WT (branch $BRANCH)"
echo
echo "Next — open two tabs, BOTH inside the worktree:"
echo "  PM tab:   cd \"$WT\" && MUSTER_ROLE=pm claude --dangerously-skip-permissions \"Bind to PM for this session and run your startup, then wait for my input.\"   # auto-binds PM, skips perms; plan / resolve halts"
echo "  Loop tab: cd \"$WT\" && bash muster/scripts/muster-sprint-run.sh"
echo
echo "Review: git -C \"$WT\" diff main"
echo "Discard: git worktree remove \"$WT\" && git branch -D $BRANCH"
