#!/usr/bin/env bash
# muster-check-context.sh — action: the role startup gate (family: verb — answers, never mutates).
#
# Replaces the verbatim-halt prose duplicated across all 8 role bootloaders. The halt handshake
# only works if the halt string is emitted EXACTLY (PM's JIT-populate detection keys on it) — a
# model reliably adds a helpful preamble; a script cannot. The bootloader contract is one line:
# run this FIRST; `OK`/`OK-BOOTSTRAP` → continue; anything else → your ENTIRE response is the
# script's output, verbatim, nothing else.
#
# Output (stdout, exit code):
#   OK            (0)  role context is populated — continue startup
#   OK-BOOTSTRAP  (0)  developer only: onboarding audit-brief exists + context null — bootstrap mode
#   HALT: ...     (1)  the exact role-appropriate halt string to relay verbatim
# Usage errors (bad role / not a project) exit 3 — those are wiring bugs, not halts.
#
# Usage: bash muster/scripts/muster-check-context.sh <role>
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ "$(basename "$MUSTER_ROOT")" != "muster" ]; then
  echo "muster-check-context: not inside a project (muster tree not at <project>/muster/)" >&2; exit 3
fi
cd "$MUSTER_ROOT/.."

ROLE="${1:-}"
case "$ROLE" in
  pm|developer|ui-ux|qa|content|marketing|legal|research) ;;
  *) echo "usage: muster-check-context.sh <pm|developer|ui-ux|qa|content|marketing|legal|research>" >&2; exit 3 ;;
esac

source "$SCRIPT_DIR/muster-read-populated.sh"
STATE="$(pop_key "$ROLE" agents)"   # timestamp | "null" | "" (missing file/key — fail closed)

# Developer-only bootstrap carve-out: the onboarding code audit runs BEFORE developer context
# exists (the audit is what feeds it) — signalled by the audit-brief's presence.
if [ "$ROLE" = "developer" ] && [ "$STATE" = "null" ] && [ -f knowledge-base/.muster-onboarding/audit-brief.md ]; then
  echo "OK-BOOTSTRAP"; exit 0
fi

if [ "$STATE" != "null" ] && [ -n "$STATE" ]; then
  echo "OK"; exit 0
fi

# Halt strings are the handshake — change them ONLY in lockstep with their consumers
# (PM JIT-populate detection in CLAUDE.md / context-cascading.md).
if [ "$ROLE" = "pm" ]; then
  echo "HALT: PM not initialized. Run scripts/setup-project.sh or scripts/setup-existing-project.sh."
else
  echo "HALT: agent-context null. PM: run JIT populate per context-cascading.md, then re-invoke."
fi
exit 1
