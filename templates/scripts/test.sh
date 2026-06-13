#!/usr/bin/env bash
# test.sh — quiet test runner (muster convention: test EXECUTION is free, test OUTPUT is not).
# Runs the project's FULL suite. Raw output goes to a log file; the session sees ONLY pass/fail
# counts, failing tests with file:line, and the exit code. A verbose runner ingested into the
# conversation gets re-read on every subsequent turn — that is the expensive pattern this
# script exists to kill. Agents: read the log only for a specific failure's detail.
#
# Configure run_suite() (and tighten summarize_failures) ONCE for this project's stack:
#   web:     npx vitest run --reporter=dot 2>&1
#   backend: deno test 2>&1
#   iOS (the loudest offender — thousands of build lines per run):
#     xcodebuild test -scheme "App" -destination "platform=iOS Simulator,name=iPhone 16" 2>&1
#     # and in summarize_failures, grep the log for: "Test Case .* failed|error:|** TEST FAILED"
set -uo pipefail

LOGDIR=".test-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/run-$(date +%Y%m%d-%H%M%S).log"
ls -1t "$LOGDIR"/run-*.log 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null  # keep last 10

run_suite(){
  # REPLACE with this project's full-suite command (examples in the header).
  echo "test.sh is not configured yet — set run_suite() for this project's stack." >&2
  return 2
}

summarize_failures(){
  # Default failure extraction — covers common runner shapes; tighten to YOUR runner's exact
  # output for a sharper summary. Prints at most 20 lines, with file:line where the runner
  # provides it.
  grep -nE "FAIL|✗|✘|failed|error[: ]" "$LOG" 2>/dev/null | head -20
}

run_suite > "$LOG" 2>&1
rc=$?

echo "── test summary ─────────────────────────────"
if [ "$rc" -eq 0 ]; then
  echo "✅ suite GREEN   (raw log: $LOG)"
else
  echo "❌ suite RED (exit $rc) — failing tests:"
  summarize_failures
  echo "   raw log: $LOG — read only the failing test's section, never the whole file"
fi
exit "$rc"
