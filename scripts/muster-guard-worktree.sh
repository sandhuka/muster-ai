# muster-guard-worktree.sh — Tier-1 deterministic guard, meant to be SOURCED.
# Refuse to run on the primary checkout before any --dangerously-skip-permissions call.
# --dangerously-skip-permissions unattended on your main tree is irreversible. Enforce the
# worktree requirement MECHANICALLY instead of trusting the operator to remember it.
# Sourced (not executed) by muster-sprint-run.sh and muster-sprint-resume.sh so there is
# ONE guard that cannot drift; `exit 1` here aborts the sourcing script.
if [ "${MUSTER_SPRINT_ALLOW_PRIMARY:-0}" != "1" ]; then
  gitdir="$(git rev-parse --git-dir 2>/dev/null)" || { echo "⛔ Not a git repo."; exit 1; }
  case "$gitdir" in
    */worktrees/*) : ;;  # linked worktree — OK
    *) echo "⛔ Refusing to run on the primary checkout (irreversible with skip-permissions)."
       echo "   Create a worktree first (scripts/muster-sprint-sandbox.sh),"
       echo "   or set MUSTER_SPRINT_ALLOW_PRIMARY=1 to override deliberately."
       exit 1 ;;
  esac
fi
