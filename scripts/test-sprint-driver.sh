#!/usr/bin/env bash
# test-sprint-driver.sh — end-to-end regression fixture for the autonomous sprint driver
# (muster-sprint-run.sh + muster-sprint-format.sh). First slice of the standing framework
# regression suite: run it before any release that touches the driver or formatter.
#
# Deterministic and remote-severed: a stub `claude` (PATH-injected) emits canned stream-json,
# dirties the tree, and advances a fixture queue under a mktemp dir — no model, no network, no
# real project. Asserts on concrete post-conditions: queue step labels in the trail, token
# telemetry, --model pass-through, cap/halt messages, the run-summary table, the step-boundary
# commit floor, founder-notice echo + Founder Decisions alert, clean-tree invariant, exit codes.
# The sandbox is deleted on success and kept for inspection on failure.
set -uo pipefail
MUSTER="$(cd "$(dirname "$0")/.." && pwd)"
TEST="$(mktemp -d /tmp/muster-driver-test.XXXXXX)"
PROJ="$TEST/proj"
mkdir -p "$PROJ/knowledge-base" "$TEST/bin"
echo "fixture: $TEST"

# --- queue states (stub swaps q(n+1) in after step n) ---
cat > "$TEST/q1.md" <<'EOF'
# Orchestration Queue

## Next Step

### Step 1 — QA: fixture audit

```
Role: qa
Task: fixture step one.
```

## Upcoming

### Step 2 — PM: fixture review

(placeholder)

## Done

_(empty)_
EOF

cat > "$TEST/q2.md" <<'EOF'
# Orchestration Queue

## Next Step

### Step 2 — PM: fixture review

```
Role: pm
Model: stub-model-x
Task: fixture step two with a model override.
```

## Upcoming

### Step 3 — GATE 1: fixture gate

(placeholder)

## Done

- 2026-06-11 qa: Step 1 — fixture audit complete (HO-001)
EOF

cat > "$TEST/q3.md" <<'EOF'
# Orchestration Queue

## Next Step

### Step 3 — GATE 1: fixture gate

```
Role: halt
Founder review: fixture gate.
```

## Upcoming

## Founder Decisions

### Fixture decision
**Your call**: _[founder fills in]_

## Done

_(empty)_
EOF

cp "$TEST/q1.md" "$PROJ/knowledge-base/orchestration-queue.md"
echo "# Agent Requests" > "$PROJ/knowledge-base/agent-requests.md"; echo ".muster-sprint-logs/" > "$PROJ/.gitignore"

# --- stub claude: emits canned stream-json, dirties the tree, advances the queue ---
cat > "$TEST/bin/claude" <<EOF
#!/usr/bin/env bash
DIR="$TEST"
printf '%s\n' "\$*" >> "\$DIR/args.log"
if [ -f "\$DIR/mode-fail" ]; then                         # one-shot: die mid-step, tree dirty,
  rm -f "\$DIR/mode-fail"                                 # queue NOT advanced (interruption sim)
  echo "partial work from interrupted attempt" >> "\$PWD/deliverable.md"
  echo '{"type":"result","subtype":"error_during_execution","is_error":true,"num_turns":3,"total_cost_usd":0.10,"usage":{"output_tokens":10}}'
  exit 1
fi
if [ -f "\$DIR/mode-limit" ]; then                        # one-shot: usage-limit death (real
  rm -f "\$DIR/mode-limit"                                # payload, reset time = now → resume
  echo "limit-partial work" >> "\$PWD/deliverable.md"     # is immediate under LIMIT_BUFFER=1)
  RESET="\$(date +%I:%M%p | tr '[:upper:]' '[:lower:]' | sed 's/^0//')"
  sed "s/RESET_TIME_PLACEHOLDER/\$RESET/" "\$DIR/limit-payload.jsonl"
  exit 1
fi
if [ -f "\$DIR/noresult-from" ]; then                     # step whose number >= threshold: emit the
  cur=\$(cat "\$DIR/count" 2>/dev/null || echo 0); nxt=\$((cur+1))   # river but NO result event, exit 0,
  if [ "\$nxt" -ge "\$(cat "\$DIR/noresult-from")" ]; then          # and DO NOT advance the queue —
    echo \$nxt > "\$DIR/count"                                      # a manual Ctrl-C mid-step. The
    echo '{"type":"system","subtype":"init"}'                      # formatter writes no metrics line,
    echo '{"type":"assistant","message":{"model":"claude-stub","usage":{"input_tokens":1000,"cache_read_input_tokens":50000,"cache_creation_input_tokens":0,"output_tokens":100},"content":[{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]}}'
    exit 0                                                          # so the driver must NOT borrow the
  fi                                                               # prior step's metrics for the row.
fi
cp "\$PWD/.muster-sprint-logs/STATUS" "\$DIR/status-during" 2>/dev/null   # mid-step snapshot
n=\$(cat "\$DIR/count" 2>/dev/null || echo 0); n=\$((n+1)); echo \$n > "\$DIR/count"
echo "step \$n output" >> "\$PWD/deliverable.md"          # leave UNCOMMITTED work (floor must catch)
cp "\$DIR/q\$((n+1)).md" "\$PWD/knowledge-base/orchestration-queue.md"
if [ "\$n" = "1" ]; then                                  # file the HO that q2's Done references,
  echo "### [2026-06-11] HO-001 — fixture handoff" >> "\$PWD/knowledge-base/agent-requests.md"  # so the lint verifies it filed
fi
if [ "\$n" = "2" ]; then
  echo "- 2026-06-11 pm: pod-build track kicked off — 4 component requests, needed by Step 30" >> "\$PWD/knowledge-base/founder-notices.md"
fi
cat <<'JSON'
{"type":"system","subtype":"init"}
{"type":"assistant","message":{"model":"claude-stub","usage":{"input_tokens":1000,"cache_read_input_tokens":50000,"cache_creation_input_tokens":0,"output_tokens":100},"content":[{"type":"tool_use","name":"Read","input":{"file_path":"a.md"}},{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]}}
{"type":"assistant","message":{"model":"claude-stub","usage":{"input_tokens":1000,"cache_read_input_tokens":149000,"cache_creation_input_tokens":0,"output_tokens":300},"content":[{"type":"text","text":"working on it"},{"type":"tool_use","name":"Edit","input":{"file_path":"b.md"}}]}}
{"type":"result","subtype":"success","is_error":false,"num_turns":7,"total_cost_usd":1.23,"usage":{"output_tokens":4321}}
JSON
exit 0
EOF
chmod +x "$TEST/bin/claude"

# Usage-limit payload — captured from a REAL limit-killed run (arogh sprint, 2026-06-11; trimmed
# to valid JSON, reset time parameterized). The classifier keys on api_error_status 429 + the
# limit result text; this is the ground truth it was built against.
cat > "$TEST/limit-payload.jsonl" <<'EOF'
{"type":"result","subtype":"success","is_error":true,"api_error_status":429,"duration_ms":2802155,"duration_api_ms":2782450,"num_turns":140,"result":"You've hit your session limit · resets RESET_TIME_PLACEHOLDER (America/Los_Angeles)","stop_reason":"stop_sequence","session_id":"aa6c0775-78a3-4e94-95f6-751f15a5770b","total_cost_usd":46.91,"usage":{"input_tokens":17808,"cache_creation_input_tokens":609376,"cache_read_input_tokens":25407405,"output_tokens":182656}}
EOF

# Fake caffeinate (PATH-injected): shadows the real one on macOS so the test never asserts real
# power state, and proves the sleep-proof guard invokes it when present. On Linux CI there is no
# real caffeinate either way — the guard's no-op path is what keeps the driver green there.
printf '#!/usr/bin/env bash\ntouch "%s/caffeinate.invoked"\n' "$TEST" > "$TEST/bin/caffeinate"
chmod +x "$TEST/bin/caffeinate"

cd "$PROJ"
git init -q && git config user.email t@t && git config user.name t
git add -A && git commit -qm init

export PATH="$TEST/bin:$PATH" MUSTER_SPRINT_ALLOW_PRIMARY=1

echo "=================== RUN A (MAX_STEPS=1 → cap) ==================="
MAX_STEPS=1 bash "$MUSTER/scripts/muster-sprint-run.sh" 2>&1 | tee "$TEST/runA.out"
echo "=================== RUN B (default → step 2 + halt) ============="
set +o pipefail
bash "$MUSTER/scripts/muster-sprint-run.sh" 2>&1 | tee "$TEST/runB.out"
DRIVER_RC="${PIPESTATUS[0]}"
set -o pipefail

echo "=================== RUN C/D (.muster/config knobs) ==============="
# Reset fixture state (queue → q1, stub counter → 0), drop a config file, commit so the tree
# starts clean. Run C: config MAX_STEPS=1 alone must cap the run. Run D: explicit env
# MAX_STEPS=2 must beat the config (run reaches the q3 gate and halts instead of capping at 1).
cp "$TEST/q1.md" "$PROJ/knowledge-base/orchestration-queue.md"
echo 0 > "$TEST/count"
mkdir -p "$PROJ/.muster"; { echo "MAX_STEPS=1"; echo "CTX_WARN_PCT=10"; } > "$PROJ/.muster/config"  # low threshold: the 15% stub step trips the hot-ctx ⚠ from run C on
git -C "$PROJ" add -A && git -C "$PROJ" commit -qm "reset for config runs"
bash "$MUSTER/scripts/muster-sprint-run.sh" 2>&1 | tee "$TEST/runC.out"
MAX_STEPS=2 bash "$MUSTER/scripts/muster-sprint-run.sh" 2>&1 | tee "$TEST/runD.out"

echo "=================== RUN E/F (interruption → continuation) ========"
# Reset state again (queue → q1, counter → 0, clean tree; .muster/config MAX_STEPS=1 still
# applies, keeping each run to one step). Run E: stub dies mid-step leaving a dirty tree and an
# unadvanced queue — the driver must hard-halt (cond 4) WITHOUT a boundary commit (interruption
# preserved). Run F: next run must detect the dirty tree at step start, print the ↻ line, and
# hand the stub the continuation preamble in its prompt args. A/B/C/D ran on clean boundaries —
# they must show no ↻.
cp "$TEST/q1.md" "$PROJ/knowledge-base/orchestration-queue.md"
echo 0 > "$TEST/count"
git -C "$PROJ" add -A && git -C "$PROJ" commit -qm "reset for continuation runs"
touch "$TEST/mode-fail"
bash "$MUSTER/scripts/muster-sprint-run.sh" 2>&1 | tee "$TEST/runE.out"
bash "$MUSTER/scripts/muster-sprint-run.sh" 2>&1 | tee "$TEST/runF.out"

echo "=================== RUN G (usage limit → auto-resume) ============"
# Queue sits at q2 after run F. The stub dies once with the captured limit payload (reset time
# stamped "now", LIMIT_BUFFER=1 keeps the sleep to ~0s), then the driver must re-enter the loop,
# re-run the same step (dirty tree → continuation preamble again), and reach the q3 gate. Run E
# already proves the fail-closed side: a generic error never resumes. Env MAX_STEPS=3 gives the
# re-attempt budget headroom.
touch "$TEST/mode-limit"
LIMIT_BUFFER=1 MAX_STEPS=3 bash "$MUSTER/scripts/muster-sprint-run.sh" 2>&1 | tee "$TEST/runG.out"

echo "=================== RUN H (interrupted step → no phantom metrics) ="
# Reset and run TWO steps: step 1 completes normally (writes a metrics line, advances q1→q2); step 2
# is interrupted (noresult-from=2 → emits its river but NO result event, exits 0, does not advance).
# The driver must show DASHES for step 2's row — NOT borrow step 1's turns/cost/ctx — and lead its
# end-block with ⚠. cond-3 then stops the run on step 3. This reproduces the device-gate Ctrl-C bug.
cp "$TEST/q1.md" "$PROJ/knowledge-base/orchestration-queue.md"
echo 0 > "$TEST/count"; echo 2 > "$TEST/noresult-from"
git -C "$PROJ" add -A && git -C "$PROJ" commit -qm "reset for no-result run"
MAX_STEPS=3 bash "$MUSTER/scripts/muster-sprint-run.sh" 2>&1 | tee "$TEST/runH.out"
rm -f "$TEST/noresult-from"
cp "$PROJ/.muster-sprint-logs/STATUS" "$TEST/runH-status"   # run I overwrites STATUS; snapshot H's final state first
git -C "$PROJ" rev-parse HEAD > "$TEST/runH-sha"            # run I adds a reset commit; commit-floor asserts against this snapshot

echo "=================== RUN I (context gate → stop) ================="
# Embedded-muster layout: the context lint only ARMS when the driver runs from a muster/ tree
# (any other location exits 3 = wiring-warn, which is what runs A–H exercise). Copy the scripts
# into $PROJ/muster/scripts and reset the queue to q1 (Role: qa) with NO agent-context for qa —
# the promoted gate must stop the run before the step is ever invoked.
mkdir -p "$PROJ/muster/scripts"
cp "$MUSTER"/scripts/*.sh "$PROJ/muster/scripts/"
cp "$MUSTER"/scripts/*.py "$PROJ/muster/scripts/" 2>/dev/null || true
touch "$PROJ/muster/system-guide.md"
cp "$TEST/q1.md" "$PROJ/knowledge-base/orchestration-queue.md"
echo 0 > "$TEST/count"
git -C "$PROJ" add -A && git -C "$PROJ" commit -qm "reset for context-gate run"
MAX_STEPS=1 bash "$PROJ/muster/scripts/muster-sprint-run.sh" 2>&1 | tee "$TEST/runI.out"

echo "=================== ASSERTIONS ==================="
pass=0; fail=0
ok(){ if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

ok "A: role-first step header"            'grep -aq "▶ QA · Step 1" "$TEST/runA.out" && grep -aq "  QA: fixture audit" "$TEST/runA.out"'
ok "A: telemetry on ✓ line"               'grep -aq "peak ctx 150k/1M 15% · out 4k" "$TEST/runA.out"'
ok "A: activity compression line"         'grep -aq "📖 ×1 · ✏️  ×1 · 🧪 ×1" "$TEST/runA.out"'
ok "A: cap message self-explains"         'grep -aq "Run cap reached (MAX_STEPS=1) — cost circuit-breaker" "$TEST/runA.out"'
ok "A: cap names next queue step"         'grep -aq "next: Step 2 — PM: fixture review" "$TEST/runA.out"'
ok "A: summary stop reason = run cap"     'grep -aq "stopped: run cap" "$TEST/runA.out"'
ok "A: run budget header"                 'grep -aq "run budget: 1 steps" "$TEST/runA.out"'
ok "B: role-first header + model tag"     'grep -aq "▶ PM · Step 2  \[stub-model-x\]" "$TEST/runB.out"'
ok "B: --model passed to claude"          'grep -aq -- "--model stub-model-x" "$TEST/args.log"'
ok "B: step 1 got NO --model flag"        '! head -1 "$TEST/args.log" | grep -aq -- "--model"'
ok "B: halt block + wave-review guidance" 'grep -aq "HALT — Step 3 — GATE 1: fixture gate" "$TEST/runB.out" && grep -aq "wave-review.md" "$TEST/runB.out"'
ok "B: summary has halt row"              'grep -aq "Step 3 — GATE 1: fixture gate.*halt" "$TEST/runB.out"'
ok "B: summary totals line"               'grep -aq "1 steps · 7 turns · \$1.23 · out 4k.* stopped: halt" "$TEST/runB.out"'
ok "commit floor: 7 boundary commits"     '[ "$(git -C "$PROJ" log --oneline | grep -ac "step-boundary sweep")" = "7" ]'
ok "commit floor: messages carry labels"  '[ -n "$(git -C "$PROJ" log --format=%s | grep -a "sweep — Step 2")" ]'
ok "commit floor: Rule-16 subjects (role prefix)" '[ "$(git -C "$PROJ" log --format=%s | grep -ac "^[a-z-]*: step-boundary sweep")" = "7" ]'
ok "commit floor: sweep passes commit lint" 'git -C "$PROJ" log --format=%s -1 "$(cat "$TEST/runH-sha")" | grep -aq "step-boundary sweep" && (cd "$PROJ" && bash "$MUSTER/scripts/muster-lint-commit.sh" "$(cat "$TEST/runH-sha")")'
ok "commit floor: shows swept paths"      'grep -aq "step-boundary commit · swept" "$TEST/runA.out" && grep -aq "deliverable.md" "$TEST/runA.out"'
ok "per-step wall-clock in end-block"     'grep -aq "✓ QA · [0-9]" "$TEST/runA.out" && grep -aq "run so far:" "$TEST/runA.out"'
ok "step-progress: role + advance + HO"   'grep -aq "✓ QA · .* advanced → Step 2 — PM: fixture review (PM) · handoff HO-001 filed ✓" "$TEST/runA.out"'
ok "step-progress: no-handoff = advance only" 'grep -a "advanced → Step 3 — GATE 1" "$TEST/runB.out" | grep -avq "handoff"'
ok "step-progress: closing rule per step" 'grep -aq "^───" "$TEST/runA.out"'
ok "color: no ANSI in non-TTY logs"       '! grep -aq "$(printf '"'"'\033'"'"')" "$TEST/runA.out"'
ok "no-result step: ⚠ marker not ✓"       'grep -aq "⚠ PM · " "$TEST/runH.out"'
ok "no-result step: dashes, not stale"    '! grep -aq "Step 2 — PM: fixture review.*1.23" "$TEST/runH.out"'
ok "ctx-warn: fires past threshold"       'grep -aq "⚠ ctx ran hot: peak 15% (≥ 10%)" "$TEST/runC.out"'
ok "ctx-warn: silent under default"       '! grep -aq "ctx ran hot" "$TEST/runA.out" && ! grep -aq "ctx ran hot" "$TEST/runB.out"'
ok "clean tree at end"                    '[ -z "$(git -C "$PROJ" status --porcelain)" ]'
ok "metrics files written"                '[ "$(cat "$PROJ"/.muster-sprint-logs/run-*.metrics | wc -l | tr -d " ")" = "9" ]'
ok "B: founder notice echoed loudly"      'grep -aq "📣 FOUNDER NOTICE" "$TEST/runB.out" && grep -aq "pod-build track" "$TEST/runB.out"'
ok "B: notice counted in run summary"     'grep -aq "1 founder notice(s) this run" "$TEST/runB.out"'
ok "B: Founder Decisions change alert"    'grep -aq "Founder Decisions. changed" "$TEST/runB.out"'
ok "A: no notice noise on quiet steps"    '! grep -aq "FOUNDER NOTICE" "$TEST/runA.out"'
ok "driver exits 0"                       '[ "$DRIVER_RC" = "0" ]'
ok "sleep-proof: caffeinate invoked"      '[ -f "$TEST/caffeinate.invoked" ]'
ok "C: config MAX_STEPS=1 respected"      'grep -aq "Run cap reached (MAX_STEPS=1)" "$TEST/runC.out"'
ok "D: env MAX_STEPS beats config"        'grep -aq "HALT — Step 3 — GATE 1: fixture gate" "$TEST/runD.out" && ! grep -aq "MAX_STEPS=1" "$TEST/runD.out"'
ok "E: mid-step death → hard halt"        'grep -aq "claude exited non-zero" "$TEST/runE.out" && grep -aq "stopped: error (non-zero exit)" "$TEST/runE.out"'
ok "F: ↻ continuation line"               'grep -aq "↻ dirty tree — continuation preamble added" "$TEST/runF.out"'
ok "F+G: preamble exactly on dirty starts" '[ "$(grep -ac "Do NOT start over" "$TEST/args.log")" = "2" ]'
ok "wrapper enforces foreground test-gating" 'grep -aq "FOREGROUND and BLOCKING" "$TEST/args.log"'
ok "A–D: no ↻ on clean boundaries"        '! grep -aq "↻" "$TEST/runA.out" && ! grep -aq "↻" "$TEST/runB.out" && ! grep -aq "↻" "$TEST/runC.out" && ! grep -aq "↻" "$TEST/runD.out"'
ok "G: ⏸ limit line with resume time"     'grep -aq "⏸ usage limit — sleeping until" "$TEST/runG.out"'
ok "G: same step re-ran after resume"     '[ "$(grep -ac "▶ PM · Step 2" "$TEST/runG.out")" = "2" ]'
ok "G: run bridged the limit to the gate" 'grep -aq "stopped: halt" "$TEST/runG.out"'
ok "STATUS: running state mid-step"       'grep -aq "state: running step" "$TEST/status-during"'
ok "STATUS: carries the queue label"      'grep -aq "step: Step 1 — QA: fixture audit" "$TEST/status-during"'
ok "STATUS: final state = summary reason" 'grep -aq "state: halted: step did not advance" "$TEST/runH-status"'
ok "I: context gate stops the run"        'grep -aq "⛔ Context gate" "$TEST/runI.out"'
ok "I: STATUS carries the gate reason"    'grep -aq "halted: context gate" "$PROJ/.muster-sprint-logs/STATUS"'
ok "I: A–H stayed warn-only (wiring)"     '! grep -aq "⛔ Context gate" "$TEST/runA.out"'

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed   (fixture: $TEST)"
if [ "$fail" -eq 0 ]; then
  cd / && rm -rf "$TEST"   # green run: the sandbox has no further value
  exit 0
fi
echo "Sandbox kept for inspection: $TEST"
exit 1
