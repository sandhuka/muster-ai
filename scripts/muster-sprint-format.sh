#!/usr/bin/env bash
# muster-sprint-format.sh — render Claude Code stream-json (stdin) as a human-readable trail.
#
# Usage:  claude ... --output-format stream-json | muster-sprint-format.sh [RAW_LOG] [METRICS]
#   stdin — the stream-json event stream
#   $1    — optional path; each raw JSONL event is appended there (full-fidelity debug log)
#   $2    — optional path; ONE machine-readable line is appended per step at the result event
#           (turns|cost|ctx%|out|outraw) — the driver renders the run-summary table from it
#
# PRESENTATION ONLY. This script must NEVER fail or exit non-zero: the driver keys its stop
# conditions off claude's exit code (PIPESTATUS[0]), not this formatter's. A bad/partial line
# is skipped, never fatal. If jq is missing, it passes raw lines through so nothing is lost.
#
# Live river: one line per event, paths kept — they ARE the diagnostic trail. At step end, two
# closing lines: a compact activity summary (icon ×count) and the metrics line:
#     📖 ×6 · ✏️ ×4 · 🧪 ×2
#   ✓ 74 turns · $4.05 · peak ctx 188k/1M 19% · out 21k  (success)
# Peak ctx = the largest single prompt the step sent (input + cache read + cache creation on its
# biggest turn) — the "how full did the window get" step-sizing signal. Deliberately NOT total
# input tokens: every turn re-sends the conversation (mostly cache reads), so total input is
# inflated by turn count and measures cost, not size. out = total output tokens (result event).
# Window for the %: the 4.6+ frontier generation (Opus 4.6/4.7/4.8, Sonnet 4.6, Fable 5) ships a
# 1M window by default, so unknown/new model ids resolve to 1M; only Haiku and the legacy
# 4.5-and-earlier families are 200k. Absent usage -> the telemetry segment is omitted entirely
# (graceful degradation, never an error).

RAWLOG="${1:-}"
METRICS="${2:-}"

# Byte semantics, deliberately: macOS ships bash 3.2, whose multibyte-aware case-glob matching
# and ${var%...} trimming silently corrupt emoji under a UTF-8 locale (observed: a leading F0
# byte eaten, counters not matching). LC_ALL=C makes every string op a byte op — UTF-8 output
# passes through untouched, and jq is locale-independent for JSON either way.
export LC_ALL=C

if ! command -v jq >/dev/null 2>&1; then
  # No jq — don't lose the trail; still capture raw if a log path was given.
  if [ -n "$RAWLOG" ]; then tee -a "$RAWLOG"; else cat; fi
  exit 0
fi

# @@U / @@R are internal sentinels (usage sample / result), consumed below — never printed.
# Display text lines can't collide: they are always emitted with a leading two-space indent.
JQ_PROG='
if .type=="system" and (.subtype=="init") then
  "  ⚙  session start"
elif .type=="assistant" then
  (
    ( (.message.usage? // {}) as $u
      | (($u.input_tokens//0)+($u.cache_read_input_tokens//0)+($u.cache_creation_input_tokens//0)) as $ctx
      | if $ctx > 0 then "@@U \($ctx) \(.message.model // "")" else empty end ),
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
  )
elif .type=="user" then
  ( .message.content[]? | select(.type=="tool_result")
    | if (.is_error==true) then "  ⚠️  tool returned an error" else empty end )
elif .type=="result" then
  "@@R \(.num_turns // 0)|\(((.total_cost_usd // 0)*100|round/100))|\(if .is_error==true then 1 else 0 end)|\(.subtype // "?")|\(.usage.output_tokens // 0)"
else empty end
'

PEAK=0; MODEL=""
c_read=0; c_edit=0; c_write=0; c_bash=0; c_search=0; c_agent=0; c_err=0

fmt_k(){
  case "${1:-0}" in (*[!0-9]*|"") echo "${1:-0}"; return;; esac
  if [ "$1" -ge 1000 ]; then echo "$(( ($1 + 500) / 1000 ))k"; else echo "$1"; fi
}

emit_done(){
  # $1 = "@@R turns|cost|iserr|subtype|outraw"
  local r turns cost iserr subtype outraw act mark seg pct win wl
  r="${1#@@R }"
  IFS='|' read -r turns cost iserr subtype outraw <<< "$r"
  act=""
  [ "$c_read"   -gt 0 ] && act="$act📖 ×$c_read · "
  [ "$c_edit"   -gt 0 ] && act="$act✏️  ×$c_edit · "
  [ "$c_write"  -gt 0 ] && act="$act📝 ×$c_write · "
  [ "$c_bash"   -gt 0 ] && act="$act🧪 ×$c_bash · "
  [ "$c_search" -gt 0 ] && act="$act🔍 ×$c_search · "
  [ "$c_agent"  -gt 0 ] && act="$act🤖 ×$c_agent · "
  [ "$c_err"    -gt 0 ] && act="$act⚠️  ×$c_err · "
  [ -n "$act" ] && printf '    %s\n' "${act% · }"
  mark="✓"; [ "${iserr:-0}" = "1" ] && mark="⛔"
  seg="${turns:-?} turns · \$${cost:-?}"
  pct="—"
  if [ "${PEAK:-0}" -gt 0 ]; then
    win=1000000; wl="1M"
    case "$MODEL" in
      *haiku*|*opus-4-5*|*opus-4-1*|*opus-4-0*|*sonnet-4-5*|*sonnet-4-0*|*claude-3*|*claude-2*)
        win=200000; wl="200k" ;;
    esac
    pct="$(( PEAK * 100 / win ))%"
    seg="$seg · peak ctx $(fmt_k "$PEAK")/$wl $pct · out $(fmt_k "${outraw:-0}")"
  fi
  printf '  %s %s  (%s)\n' "$mark" "$seg" "${subtype:-?}"
  [ -n "$METRICS" ] && printf '%s|%s|%s|%s|%s\n' "${turns:-0}" "${cost:-0}" "$pct" \
    "$(fmt_k "${outraw:-0}")" "${outraw:-0}" >> "$METRICS" 2>/dev/null
  return 0
}

# Per-line so one malformed/partial line is skipped, not fatal; per-line jq keeps it real-time.
while IFS= read -r line; do
  [ -n "$RAWLOG" ] && printf '%s\n' "$line" >> "$RAWLOG"
  [ -z "$line" ] && continue
  out="$(printf '%s\n' "$line" | jq -r "$JQ_PROG" 2>/dev/null)" || true
  [ -z "$out" ] && continue
  while IFS= read -r o; do
    [ -z "$o" ] && continue
    case "$o" in
      "@@U "*)
        u="${o#@@U }"; ctx="${u%% *}"; mdl="${u#* }"
        [ "$mdl" = "$u" ] && mdl=""
        case "$ctx" in (*[!0-9]*|"") ;; (*) [ "$ctx" -gt "$PEAK" ] && PEAK="$ctx";; esac
        [ -n "$mdl" ] && MODEL="$mdl"
        ;;
      "@@R "*) emit_done "$o" ;;
      *)
        case "$o" in
          *"📖 read"*)  c_read=$((c_read+1));;
          *"✏️  edit"*) c_edit=$((c_edit+1));;
          *"📝 write"*) c_write=$((c_write+1));;
          *"🧪 bash"*)  c_bash=$((c_bash+1));;
          *"🔍 "*)      c_search=$((c_search+1));;
          *"🤖 "*)      c_agent=$((c_agent+1));;
          *"⚠️"*)       c_err=$((c_err+1));;
        esac
        printf '%s\n' "$o"
        ;;
    esac
  done <<< "$out"
done

exit 0
