#!/usr/bin/env bash
# muster-lint-context.sh — lint: the Next Step context gate (family: lint — reports OK/FAIL, never mutates).
#
# Rule (was prose in sprint-planning.md): never run a queue step for an agent whose
# agent-context Current Tasks has no real inlined tasks — a cold agent with a pointer-only
# context file improvises scope, and nothing catches it until the handoff is wrong.
#
# POSITIVE-evidence design (field-verified against live projects): populated files legitimately
# KEEP the seeded pointer line and use varied shapes (### sprint headings, bold standing-note
# paragraphs), so "grep for the template string" would false-flag real files and a rephrased
# pointer would silently pass. Instead: the `## Current Tasks` section must contain at least one
# CONTENT line — non-blank, non-HTML-comment, and not a pointer-ish line (starts with
# See/Check/Refer/Read AND mentions current-sprint.md). Both silent-pass modes become loud.
#
# PM exemption: pm's template explicitly sanctions an empty Current Tasks (PM coordinates
# rather than executes; duties live in the queue) — for pm only, file existence passes.
#
# Usage: muster-lint-context.sh [role]
#   no arg  -> gate the CURRENT queue Next Step's role (muster-read-queue.sh); a complete
#              queue or a 'Role: halt' founder gate has no agent step -> OK.
#   <role>  -> check that role's context file directly.
# Exit: 0 OK · 1 FAIL (reason printed, names the PM fix) · 3 usage/wiring error
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ "$(basename "$MUSTER_ROOT")" != "muster" ]; then
  echo "muster-lint-context: not inside a project (muster tree not at <project>/muster/)" >&2; exit 3
fi
cd "$MUSTER_ROOT/.."

ROLE="${1:-}"
if [ -z "$ROLE" ]; then
  ROLE="$(bash "$SCRIPT_DIR/muster-read-queue.sh" role 2>/dev/null || true)"
  if [ -z "$ROLE" ]; then echo "OK: queue has no bindable Next Step — nothing to gate"; exit 0; fi
  if [ "$ROLE" = "halt" ]; then echo "OK: Next Step is a founder gate (Role: halt) — no agent context to gate"; exit 0; fi
fi
case "$ROLE" in
  pm|developer|ui-ux|qa|content|marketing|legal|research) ;;
  *) echo "muster-lint-context: unknown role '$ROLE' (queue Role: line or arg). Valid: pm developer ui-ux qa content marketing legal research" >&2; exit 3 ;;
esac

CTX="knowledge-base/agent-context/$ROLE.md"
if [ ! -f "$CTX" ]; then
  echo "FAIL: $CTX missing — PM must create it (seed from muster/templates/knowledge-base/agent-context/ and populate per context-cascading.md)"; exit 1
fi

if [ "$ROLE" = "pm" ]; then
  echo "OK: pm context file exists (pm's Current Tasks may legitimately be empty)"; exit 0
fi

# Count CONTENT lines in ## Current Tasks: strip the section bounds, HTML comments
# (multi-line aware), blanks, and pointer-ish lines. What remains is evidence of population.
n="$(awk '
  /^## Current Tasks/ {insec=1; next}
  insec && /^## /     {insec=0}
  !insec              {next}
  incomment           { if ($0 ~ /-->/) incomment=0; next }
  /<!--/ && !/-->/    { incomment=1; next }
  /<!--.*-->/         { next }
  /^[[:space:]]*$/    { next }
  {
    l = tolower($0)
    if (l ~ /^[[:space:]]*(see|check|refer|read)[^.]*current-sprint\.md/) next
    count++
  }
  END { print count+0 }
' "$CTX")"

if [ "${n:-0}" -gt 0 ]; then
  echo "OK: $ROLE context populated ($n content lines in Current Tasks)"; exit 0
fi

# Distinguish a missing section from an unpopulated one, for a precise fix message.
if ! grep -q '^## Current Tasks' "$CTX"; then
  echo "FAIL: $CTX has no '## Current Tasks' section — restore it from the template and populate per context-cascading.md"; exit 1
fi
echo "FAIL: $CTX Current Tasks has no real tasks (pointer/comments only) — PM must inline this step's tasks per context-cascading.md before the step runs"
exit 1
