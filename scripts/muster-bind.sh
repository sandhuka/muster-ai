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
# Session id: MUSTER_SESSION_ID (explicit, harness-neutral) wins over CLAUDE_CODE_SESSION_ID
# (Claude Code provides it). With NEITHER set the bind still succeeds — the per-session bind
# file is skipped (nothing could correlate it) and the bind-log line carries "nosession"; the
# bind must never be harness-gated, because boot turns a bind failure into a full ROUTE=halt.
# Assumes PWD = project root.

set -euo pipefail

ROLE="${1:-}"
INVOKER="${2:-}"

# Validate role (guide/xo are Muster's own binds — via MUSTER.md, not picker roles)
case "$ROLE" in
    pm|developer|ui-ux|qa|content|marketing|legal|research|guide|xo) ;;
    *) echo "muster-bind: invalid role '$ROLE'. Valid: pm developer ui-ux qa content marketing legal research guide xo" >&2; exit 1 ;;
esac

# Invoker — a low-stakes audit/status tag (the bind-log line + the interactive last-role gate).
# An unrecognized value must NOT halt the bind: agents in autonomous mode sometimes pass a context
# word (the step id, "sprint", the queue name) instead of the literal enum. Warn and coerce to
# `auto` — correct for the autonomous path, where this misread happens — never exit 1. Hard-failing
# here forced a wasted retry and a spurious "tool returned an error" on every autonomous bind,
# which desensitizes the operator to genuine bind failures.
case "$INVOKER" in
    interactive|env-var|auto|onboarding) ;;
    *) echo "muster-bind: unrecognized invoker '$INVOKER' — defaulting to 'auto'." >&2; INVOKER="auto" ;;
esac

# Resolve session id (see header). Empty = degraded, never fatal.
# if-statements, not `[ ] && cmd`: this script runs set -e, and a false AND-list would kill it.
SID="${MUSTER_SESSION_ID:-${CLAUDE_CODE_SESSION_ID:-}}"
if [ -z "$SID" ]; then
    echo "muster-bind: no session id (MUSTER_SESSION_ID/CLAUDE_CODE_SESSION_ID) — binding without a status-line file." >&2
fi

# 1. Write bind file (only when a session id exists to correlate it)
mkdir -p .claude
if [ -n "$SID" ]; then
    echo "$ROLE" > ".claude/.muster-bound-role.${SID}"
fi

# 2. Append bind log (knowledge-base/ must exist — fail loud if not).
# Exception: guide/xo bind in the FRAMEWORK repo too, which has no knowledge-base/ — the bind
# file (status line) is the point there; skip the log rather than fail.
if [ ! -d knowledge-base ]; then
    case "$ROLE" in
        guide|xo) exit 0 ;;
        *) echo "muster-bind: knowledge-base/ not found in PWD ($(pwd)). Run from project root." >&2; exit 1 ;;
    esac
fi
echo "$(date -Iseconds) $ROLE $INVOKER ${SID:-nosession}" >> knowledge-base/.muster-bind-log

# 3. Last-role memory (interactive only — gitignored). guide/xo never write it: it pre-selects
# the PICKER, and they aren't picker roles.
if [ "$INVOKER" = "interactive" ] && [ "$ROLE" != "guide" ] && [ "$ROLE" != "xo" ]; then
    echo "$ROLE" > .claude/.muster-last-role
fi
