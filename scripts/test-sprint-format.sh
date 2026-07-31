#!/usr/bin/env bash
# test-sprint-format.sh — fixture gate for muster-sprint-format.sh (the stream-json renderer).
# Pins the telemetry contract: the context-window table (known Claude families -> table window;
# unknown claude- ids -> frontier 1M; NON-claude ids -> NO window claim, pct "—"), the metrics
# line shape (turns|cost|pct|out|outraw), graceful degradation on absent usage / garbage input,
# and the never-fail exit-0 guarantee the driver's PIPESTATUS logic depends on.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
FMT="$SRC/scripts/muster-sprint-format.sh"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/muster-fmt-test.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT

command -v jq >/dev/null 2>&1 || { echo "FAIL: jq required for this fixture"; exit 1; }

# One assistant-usage event (model, cache_read tokens) + the closing result event.
ev(){ printf '{"type":"assistant","message":{"model":"%s","usage":{"input_tokens":1000,"cache_read_input_tokens":%s,"cache_creation_input_tokens":0,"output_tokens":100},"content":[{"type":"text","text":"working"}]}}\n' "$1" "$2"; }
RES='{"type":"result","subtype":"success","is_error":false,"num_turns":7,"total_cost_usd":1.23,"usage":{"output_tokens":4321}}'

n=0; fails=0
t(){ # $1=name $2=stdin-events $3=grep-must $4=grep-must-NOT ('' skip) $5=want-metrics-line ('' skip)
  local name="$1" events="$2" want="$3" nowant="${4:-}" wantm="${5:-}"
  n=$((n+1))
  local m="$SBX/m.$n" out rc ok=1
  out="$(printf '%s\n' "$events" | bash "$FMT" "" "$m" 2>&1)"; rc=$?
  [ "$rc" = 0 ] || ok=0
  printf '%s\n' "$out" | grep -qF -- "$want" || ok=0
  [ -n "$nowant" ] && printf '%s\n' "$out" | grep -qF -- "$nowant" && ok=0
  if [ -n "$wantm" ]; then [ "$(tail -1 "$m" 2>/dev/null)" = "$wantm" ] || ok=0; fi
  if [ "$ok" = 1 ]; then echo "PASS: $name"
  else fails=$((fails+1)); echo "FAIL: $name (rc=$rc metrics=$(tail -1 "$m" 2>/dev/null))"; printf '%s\n' "$out" | sed 's/^/  got: /'; fi
}

# window table: known families + the frontier default for unknown claude- ids
t frontier-1M   "$(ev claude-opus-4-8 149000)
$RES"  "peak ctx 150k/1M 15%"   ""  "7|1.23|15%|4k|4321"
t haiku-200k    "$(ev claude-haiku-4-5 99000)
$RES"  "peak ctx 100k/200k 50%" ""  "7|1.23|50%|4k|4321"
t legacy-200k   "$(ev claude-3-opus 99000)
$RES"  "peak ctx 100k/200k 50%"
t unknown-claude-1M "$(ev claude-futurething-9 149000)
$RES"  "peak ctx 150k/1M 15%"

# THE fix: a non-claude id must claim NO window — no /win, no %, metrics pct "—".
# A guessed 1M on a smaller foreign model reports a falsely-low % and silently disables the
# driver's hot-ctx warning; "—" is the honest degraded value the driver already skips.
t foreign-no-claim "$(ev gpt-5o 149000)
$RES"  "peak ctx 150k · out 4k" "/1M" "7|1.23|—|4k|4321"
t empty-model-no-claim "$(printf '{"type":"assistant","message":{"usage":{"input_tokens":1000,"cache_read_input_tokens":149000,"cache_creation_input_tokens":0,"output_tokens":100},"content":[{"type":"text","text":"working"}]}}')
$RES"  "peak ctx 150k · out 4k" "/1M" "7|1.23|—|4k|4321"

# degradation: no usage at all -> telemetry segment omitted entirely; garbage lines skipped
t no-usage "$RES" "✓ 7 turns · \$1.23  (success)" "peak ctx"
t garbage-skipped "not json at all
$(ev claude-opus-4-8 149000)
$RES" "peak ctx 150k/1M 15%"

echo "----"
if [ "$fails" -eq 0 ]; then echo "RESULT: $n/$n passed"; exit 0
else echo "RESULT: $((n-fails))/$n passed — $fails FAILED"; exit 1; fi
