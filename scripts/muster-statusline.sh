#!/bin/bash
# muster-statusline.sh — action: render the harness status line from the session bind file (family: verb — answers, never mutates).
#
# Reads .claude/.muster-bound-role.<session-id> where <session-id> comes from
# Claude Code's session identifier. Resolution order:
#   1. session_id field from JSON on stdin (canonical Claude Code mechanism)
#   2. $CLAUDE_CODE_SESSION_ID env var (fallback for variants that expose it)
#
# Bind file is written by the priority-zero check (onboarding paths force-bind
# PM) or by the picker bind step (steady-state / greenfield-ongoing paths).
# Both writers use $CLAUDE_CODE_SESSION_ID since it IS exposed to Bash tool
# subprocesses spawned by Claude Code, even when not exposed to status-line
# subprocesses. Reader/writer converge on the same UUID via different sources.
#
# Output:
#   [muster: <role>]     — bind file present with role name
#   [muster: unbound]    — session resolved but no bind file
#   [muster: no-session] — no session_id resolvable from stdin or env
#
# Wired via the project-level .claude/statusline.sh stub (exec hop); cwd is the project root.

# Read stdin if available (Claude Code passes JSON here)
JSON_INPUT=""
if [ ! -t 0 ]; then
    JSON_INPUT=$(cat)
fi

SESSION_ID=""

# Method 1 (canonical): parse session_id from stdin JSON
if [ -n "$JSON_INPUT" ]; then
    if command -v jq >/dev/null 2>&1; then
        SESSION_ID=$(echo "$JSON_INPUT" | jq -r '.session_id // empty' 2>/dev/null)
    else
        # No-jq fallback: extract via grep+sed (fragile but no deps)
        SESSION_ID=$(echo "$JSON_INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' | head -1)
    fi
fi

# Method 2 (fallback): env vars (MUSTER_SESSION_ID = the harness-neutral override muster-bind.sh honors)
if [ -z "$SESSION_ID" ]; then
    SESSION_ID="${MUSTER_SESSION_ID:-${CLAUDE_CODE_SESSION_ID:-}}"
fi

if [ -z "$SESSION_ID" ]; then
    echo "[muster: no-session]"
    exit 0
fi

FILE=".claude/.muster-bound-role.$SESSION_ID"

if [ -f "$FILE" ]; then
    # Strip all whitespace (trailing newline from echo, malformed content)
    ROLE=$(cat "$FILE" 2>/dev/null | tr -d '[:space:]')
    if [ -n "$ROLE" ]; then
        echo "[muster: $ROLE]"
    else
        echo "[muster: unbound]"
    fi
else
    echo "[muster: unbound]"
fi
