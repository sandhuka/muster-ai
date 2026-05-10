#!/bin/bash
# Muster status-line script — displays bound role from session-local file.
#
# Reads .claude/.muster-bound-role.<session-id> where <session-id> is the
# Claude Code session ID (from $CLAUDE_CODE_SESSION_ID env var). The file
# is written by the picker bind step (or env-var bind, or auto bind) per
# muster/CLAUDE.md "Role Binding" section.
#
# Output:
#   [muster: <role>]  — when bound
#   [muster: unbound] — when no bind file exists for this session
#   [muster: no-session] — when CLAUDE_CODE_SESSION_ID is missing
#
# Wired in .claude/settings.json under statusLine.command.

SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"

if [ -z "$SESSION_ID" ]; then
    echo "[muster: no-session]"
    exit 0
fi

FILE=".claude/.muster-bound-role.$SESSION_ID"

if [ -f "$FILE" ]; then
    ROLE=$(cat "$FILE" 2>/dev/null)
    if [ -n "$ROLE" ]; then
        echo "[muster: $ROLE]"
    else
        echo "[muster: unbound]"
    fi
else
    echo "[muster: unbound]"
fi
