#!/usr/bin/env bash
# muster-read-populated.sh — action: read one key from .populated (family: verb — answers, never mutates).
#
# THE single parser for knowledge-base/agent-context/.populated (flat known-shape JSON, no jq
# dependency). muster-boot.sh and muster-check-context.sh source it — routing and the subagent
# startup gate can never disagree on what the state file says.
#
# pop_key <name> [agents]: prints the raw value of "name": — null stays the literal string
# "null", timestamps lose their quotes, a missing key prints nothing (callers fail closed on
# empty). Scope "agents" restricts the match to the agents block; default matches outside it.
# Reads the file at $POP (caller sets it; defaulted below).
#
# Usage (executed): muster-read-populated.sh <key> [agents] [file]

pop_key(){
  awk -v k="\"$1\"" -v scope="${2:-top}" '
    /"agents"[[:space:]]*:/ {inag=1}
    inag && /}/ {inag=0}
    index($0, k":") || $0 ~ k"[[:space:]]*:" {
      if ((scope=="agents") != (inag==1)) next
      line=$0; sub(/^[^:]*:[[:space:]]*/,"",line); sub(/[,[:space:]]*$/,"",line)
      gsub(/"/,"",line); print line; exit
    }' "${POP:-knowledge-base/agent-context/.populated}" 2>/dev/null
}

# Executed (not sourced) -> one-shot query. Guarded so sourcing only defines the function.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -uo pipefail
  [ $# -ge 1 ] || { echo "usage: muster-read-populated.sh <key> [agents] [file]" >&2; exit 3; }
  POP="${3:-${POP:-knowledge-base/agent-context/.populated}}"
  pop_key "$1" "${2:-top}"
fi
