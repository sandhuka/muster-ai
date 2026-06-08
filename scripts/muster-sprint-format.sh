#!/usr/bin/env bash
# muster-sprint-format.sh — render Claude Code stream-json (stdin) as a human-readable trail.
#
# Usage:  claude ... --output-format stream-json | muster-sprint-format.sh [RAW_LOG_PATH]
#   stdin    — the stream-json event stream
#   $1       — optional path; if given, each raw JSONL event is appended there (full-fidelity
#              debug log), while the human-readable trail goes to stdout.
#
# PRESENTATION ONLY. This script must NEVER fail or exit non-zero: the driver keys its stop
# conditions off claude's exit code (PIPESTATUS[0]), not this formatter's. A bad/partial line
# is skipped, never fatal. If jq is missing, it passes raw lines through so nothing is lost.
#
# Each stream event becomes one line: 📖 read / ✏️ edit / 📝 write / 🧪 bash / 🔍 search /
# 🤖 subagent / 💬 text / ⚠️ tool error / ✓|⛔ step done (turns + cost + stop subtype).

RAWLOG="${1:-}"

if ! command -v jq >/dev/null 2>&1; then
  # No jq — don't lose the trail; still capture raw if a log path was given.
  if [ -n "$RAWLOG" ]; then tee -a "$RAWLOG"; else cat; fi
  exit 0
fi

JQ_PROG='
if .type=="system" and (.subtype=="init") then
  "  ⚙  session start"
elif .type=="assistant" then
  ( .message.content[]? |
    if .type=="text" then
      ( ((.text // "") | gsub("\\s+";" ") | gsub("^ | $";"")) as $t
        | if ($t|length)>0 then "  💬 " + ($t|.[0:200]) else empty end )
    elif .type=="tool_use" then
      ( .name as $n | (.input // {}) as $i
        | if   $n=="Read"      then "  📖 read   " + ($i.file_path // "?")
          elif $n=="Edit"      then "  ✏️  edit   " + ($i.file_path // "?")
          elif $n=="MultiEdit" then "  ✏️  edit   " + ($i.file_path // "?")
          elif $n=="Write"     then "  📝 write  " + ($i.file_path // "?")
          elif $n=="NotebookEdit" then "  ✏️  edit   " + ($i.notebook_path // "?")
          elif $n=="Bash"      then "  🧪 bash   " + (($i.command // "") | gsub("\\s+";" ") | .[0:120])
          elif $n=="Grep"      then "  🔍 grep   " + ($i.pattern // "")
          elif $n=="Glob"      then "  🔍 glob   " + ($i.pattern // "")
          elif ($n=="Task" or $n=="Agent") then "  🤖 subagent " + ($i.subagent_type // $i.description // "")
          elif $n=="TodoWrite" then "  🗒  plan update"
          else "  🔧 " + $n end )
    else empty end )
elif .type=="user" then
  ( .message.content[]? | select(.type=="tool_result")
    | if (.is_error==true) then "  ⚠️  tool returned an error" else empty end )
elif .type=="result" then
  ( (if (.is_error==true) then "  ⛔" else "  ✓" end)
    + " step done — " + ((.num_turns // 0)|tostring) + " turns, $"
    + (((.total_cost_usd // 0)*10000|round/10000)|tostring)
    + " (" + (.subtype // "?") + ")" )
else empty end
'

# Per-line so one malformed/partial line is skipped, not fatal. --unbuffered keeps it real-time.
while IFS= read -r line; do
  [ -n "$RAWLOG" ] && printf '%s\n' "$line" >> "$RAWLOG"
  [ -z "$line" ] && continue
  printf '%s\n' "$line" | jq -r --unbuffered "$JQ_PROG" 2>/dev/null || true
done

exit 0
