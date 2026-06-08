#!/usr/bin/env bash
# Create an isolated worktree, run the loop there, leave it for review.
set -euo pipefail
BRANCH="sprint/auto-$(date +%Y%m%d-%H%M%S)"
WT="../$(basename "$PWD")-${BRANCH//\//-}"
git worktree add "$WT" -b "$BRANCH"
# `git worktree add` checks out the superproject but NOT its submodules, so the new worktree's
# muster/ would be empty and `bash muster/scripts/...` below would fail. Populate it from the
# committed pointer. (No-op in a project that has no submodules.) NOTE: this checks out the
# COMMITTED submodule SHA — if you bumped muster to a different ref, commit that pointer in the
# project first, or the sandbox runs the old version.
git -C "$WT" submodule update --init --recursive
echo "Sandbox: $WT (branch $BRANCH)"
( cd "$WT" && bash muster/scripts/muster-sprint-run.sh )
echo "Review: git -C \"$WT\" diff main"
echo "Merge:  git merge $BRANCH   |   Discard: git worktree remove \"$WT\" && git branch -D $BRANCH"
