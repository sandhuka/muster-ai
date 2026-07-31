#!/bin/bash
# muster-bound-role.sh — action: print the session's bound role for the status line (family: verb — answers, never mutates).
#
# Designed for users who have their own custom .claude/statusline.sh and want
# to add the muster bound-role indicator alongside their existing output.
#
# Usage from your statusline.sh:
#
#   #!/bin/bash
#   JSON=$(cat)
#   YOUR_INFO="..."
#   MUSTER=$(echo "$JSON" | bash muster/scripts/muster-bound-role.sh)
#   echo "$YOUR_INFO [muster: $MUSTER]"
#
# Or pass session_id explicitly:
#
#   SESSION_ID=$(echo "$JSON" | jq -r '.session_id')
#   MUSTER=$(bash muster/scripts/muster-bound-role.sh "$SESSION_ID")
#
# Output (single line, no brackets):
#   <role>     — bind file present (e.g., 'pm', 'developer')
#   unbound    — session resolved but no bind file
#   no-session — no session_id resolvable

# Argument takes precedence
SESSION_ID="${1:-}"

# Then try stdin JSON
if [ -z "$SESSION_ID" ] && [ ! -t 0 ]; then
    JSON_INPUT=$(cat)
    if [ -n "$JSON_INPUT" ]; then
        if command -v jq >/dev/null 2>&1; then
            SESSION_ID=$(echo "$JSON_INPUT" | jq -r '.session_id // empty' 2>/dev/null)
        else
            SESSION_ID=$(echo "$JSON_INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' | head -1)
        fi
    fi
fi

# Then try env vars (MUSTER_SESSION_ID = the harness-neutral override muster-bind.sh honors)
if [ -z "$SESSION_ID" ]; then
    SESSION_ID="${MUSTER_SESSION_ID:-${CLAUDE_CODE_SESSION_ID:-}}"
fi

if [ -z "$SESSION_ID" ]; then
    echo "no-session"
    exit 0
fi

FILE=".claude/.muster-bound-role.$SESSION_ID"

if [ -f "$FILE" ]; then
    ROLE=$(cat "$FILE" 2>/dev/null | tr -d '[:space:]')
    if [ -n "$ROLE" ]; then
        echo "$ROLE"
    else
        echo "unbound"
    fi
else
    echo "unbound"
fi
