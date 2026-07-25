# muster-guard-clean-tree.sh — Tier-1 deterministic guard, meant to be SOURCED.
# Refuse to create a sprint worktree from a dirty tree. `git worktree add` checks out from HEAD,
# so uncommitted work (modified / staged / untracked files, and an uncommitted submodule-pointer
# bump) is SILENTLY ABSENT from the run — the top autonomous-launch footgun. Commit or stash first
# so it rides into the worktree via HEAD. Sourced (not executed) by muster-sprint-new.sh and
# muster-sprint-sandbox.sh so there is ONE guard that cannot drift; `exit 1` aborts the caller.
# --ignore-submodules=dirty: a hand-patched muster/ checkout (content-dirty) does NOT block, but an
# uncommitted pointer bump (the exact thing that silently makes a worktree run the OLD muster) DOES.
if [ "${MUSTER_ALLOW_DIRTY:-0}" != "1" ]; then
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "⛔ Not a git repo."; exit 1; }
  dirty="$(git status --porcelain --ignore-submodules=dirty)"
  if [ -n "$dirty" ]; then
    echo "⛔ Refusing to create a worktree: the current tree has uncommitted changes."
    echo "   git worktree add checks out from HEAD — these would be MISSING from the run:"
    printf '%s\n' "$dirty" | head -20 | sed 's/^/     /'
    n="$(printf '%s\n' "$dirty" | grep -c .)"
    if [ "$n" -gt 20 ]; then echo "     … and $((n - 20)) more"; fi
    echo "   Commit or stash first, then re-run. Deliberate scratch? MUSTER_ALLOW_DIRTY=1 to override."
    exit 1
  fi
fi
