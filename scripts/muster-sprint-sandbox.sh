#!/usr/bin/env bash
# Create an isolated worktree, run the loop there, leave it for review.
set -euo pipefail
BRANCH="sprint/auto-$(date +%Y%m%d-%H%M%S)"
WT="../$(basename "$PWD")-${BRANCH//\//-}"
git worktree add "$WT" -b "$BRANCH"
echo "Sandbox: $WT (branch $BRANCH)"
( cd "$WT" && bash muster/scripts/muster-sprint-run.sh )
echo "Review: git -C \"$WT\" diff main"
echo "Merge:  git merge $BRANCH   |   Discard: git worktree remove \"$WT\" && git branch -D $BRANCH"
