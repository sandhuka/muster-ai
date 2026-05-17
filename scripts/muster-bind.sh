#!/usr/bin/env bash
# Muster — bind a role to the current Claude Code session
#
# Called from CLAUDE.md bootstrap after picker/env-var routing resolves a role.
# Three jobs:
#   1. Write the bound role to .claude/.muster-bound-role.<session-id> (for statusline)
#   2. Append a line to knowledge-base/.muster-bind-log (audit trail)
#   3. (Interactive mode only) update .claude/.muster-last-role for picker pre-select
#
# Usage: bash muster/scripts/muster-bind.sh <role> <invoker>
#   <role>:    pm | developer | ui-ux | qa | content | marketing | legal | research
#   <invoker>: interactive | env-var | auto | onboarding
#              (onboarding = force-bound during greenfield/reverse-discovery flows)
#
# Requires $CLAUDE_CODE_SESSION_ID to be set in env (Claude Code provides this).
# Assumes PWD = project root.

set -euo pipefail

ROLE="${1:-}"
INVOKER="${2:-}"

# Validate role
case "$ROLE" in
    pm|developer|ui-ux|qa|content|marketing|legal|research) ;;
    *) echo "muster-bind: invalid role '$ROLE'. Valid: pm developer ui-ux qa content marketing legal research" >&2; exit 1 ;;
esac

# Validate invoker
case "$INVOKER" in
    interactive|env-var|auto|onboarding) ;;
    *) echo "muster-bind: invalid invoker '$INVOKER'. Valid: interactive env-var auto onboarding" >&2; exit 1 ;;
esac

# Validate session ID
if [ -z "${CLAUDE_CODE_SESSION_ID:-}" ]; then
    echo "muster-bind: CLAUDE_CODE_SESSION_ID not set in env" >&2
    exit 1
fi

# 1. Write bind file
mkdir -p .claude
echo "$ROLE" > ".claude/.muster-bound-role.${CLAUDE_CODE_SESSION_ID}"

# 2. Append bind log (knowledge-base/ must exist — fail loud if not)
if [ ! -d knowledge-base ]; then
    echo "muster-bind: knowledge-base/ not found in PWD ($(pwd)). Run from project root." >&2
    exit 1
fi
echo "$(date -Iseconds) $ROLE $INVOKER $CLAUDE_CODE_SESSION_ID" >> knowledge-base/.muster-bind-log

# 3. Last-role memory (interactive only — gitignored)
if [ "$INVOKER" = "interactive" ]; then
    echo "$ROLE" > .claude/.muster-last-role
fi
