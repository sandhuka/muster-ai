#!/usr/bin/env bash
# Muster — session-start housekeeping
#
# Runs at every session start (called from CLAUDE.md bootstrap).
# Two jobs:
#   1. Prune stale bound-role files older than 1 day from .claude/
#   2. Rotate knowledge-base/.muster-bind-log if it exceeds 500 lines
#
# Idempotent. Assumes PWD = project root (where .claude/ and knowledge-base/ live).
# Safe to call from non-muster projects: silently no-ops if .claude/ missing.

set -euo pipefail

# 1. Prune stale bind files (>1 day old). 2>/dev/null suppresses "no such file" if .claude missing.
find .claude -maxdepth 1 -name '.muster-bound-role.*' -mtime +0 -delete 2>/dev/null || true

# 2. Rotate bind log if oversized
LOG="knowledge-base/.muster-bind-log"
if [ -f "$LOG" ]; then
    LINES=$(wc -l < "$LOG")
    if [ "$LINES" -gt 500 ]; then
        TS=$(date +%Y%m%d-%H%M%S)
        mv -n "$LOG" "${LOG}.archive.${TS}"
    fi
fi
