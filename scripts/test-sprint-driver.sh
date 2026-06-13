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

_(empty)_
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
n=\$(cat "\$DIR/count" 2>/dev/null || echo 0); n=\$((n+1)); echo \$n > "\$DIR/count"
echo "step \$n output" >> "\$PWD/deliverable.md"          # leave UNCOMMITTED work (floor must catch)
cp "\$DIR/q\$((n+1)).md" "\$PWD/knowledge-base/orchestration-queue.md"
if [ "\$n" = "2" ]; then
  echo "- 2026-06-11 pm: pod-build track kicked off — 4 component requests, needed by Step 30" >> "\$PWD/knowledge-base/founder-notices.md"
fi
cat <<'JSON'
{"type":"system","subtype":"init"}
{"type":"assistant","message":{"model":"stub-model","usage":{"input_tokens":1000,"cache_read_input_tokens":50000,"cache_creation_input_tokens":0,"output_tokens":100},"content":[{"type":"tool_use","name":"Read","input":{"file_path":"a.md"}},{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]}}
{"type":"assistant","message":{"model":"stub-model","usage":{"input_tokens":1000,"cache_read_input_tokens":149000,"cache_creation_input_tokens":0,"output_tokens":300},"content":[{"type":"text","text":"working on it"},{"type":"tool_use","name":"Edit","input":{"file_path":"b.md"}}]}}
{"type":"result","subtype":"success","is_error":false,"num_turns":7,"total_cost_usd":1.23,"usage":{"output_tokens":4321}}
JSON
exit 0
EOF
chmod +x "$TEST/bin/claude"

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
mkdir -p "$PROJ/.muster"; echo "MAX_STEPS=1" > "$PROJ/.muster/config"
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

echo "=================== ASSERTIONS ==================="
pass=0; fail=0
ok(){ if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

ok "A: queue label on step header"        'grep -aq "▶ Step 1 — QA: fixture audit" "$TEST/runA.out"'
ok "A: telemetry on ✓ line"               'grep -aq "peak ctx 150k/200k 75% · out 4k" "$TEST/runA.out"'
ok "A: activity compression line"         'grep -aq "📖 ×1 · ✏️  ×1 · 🧪 ×1" "$TEST/runA.out"'
ok "A: cap message self-explains"         'grep -aq "Run cap reached (MAX_STEPS=1) — cost circuit-breaker" "$TEST/runA.out"'
ok "A: cap names next queue step"         'grep -aq "next: Step 2 — PM: fixture review" "$TEST/runA.out"'
ok "A: summary stop reason = run cap"     'grep -aq "stopped: run cap" "$TEST/runA.out"'
ok "A: run budget header"                 'grep -aq "run budget: 1 steps" "$TEST/runA.out"'
ok "B: model tag on step header"          'grep -aq "▶ Step 2 — PM: fixture review  \[stub-model-x\]" "$TEST/runB.out"'
ok "B: --model passed to claude"          'grep -aq -- "--model stub-model-x" "$TEST/args.log"'
ok "B: step 1 got NO --model flag"        '! head -1 "$TEST/args.log" | grep -aq -- "--model"'
ok "B: halt block + wave-review guidance" 'grep -aq "HALT — Step 3 — GATE 1: fixture gate" "$TEST/runB.out" && grep -aq "wave-review.md" "$TEST/runB.out"'
ok "B: summary has halt row"              'grep -aq "Step 3 — GATE 1: fixture gate.*halt" "$TEST/runB.out"'
ok "B: summary totals line"               'grep -aq "1 steps · 7 turns · \$1.23 · out 4k · stopped: halt" "$TEST/runB.out"'
ok "commit floor: 5 boundary commits"     '[ "$(git -C "$PROJ" log --oneline | grep -ac "sprint step boundary")" = "5" ]'
ok "commit floor: messages carry labels"  '[ -n "$(git -C "$PROJ" log --format=%s | grep -a "boundary: Step 2")" ]'
ok "clean tree at end"                    '[ -z "$(git -C "$PROJ" status --porcelain)" ]'
ok "metrics files written"                '[ "$(cat "$PROJ"/.muster-sprint-logs/run-*.metrics | wc -l | tr -d " ")" = "6" ]'
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
ok "F: stub received preamble once"       '[ "$(grep -ac "Do NOT start over" "$TEST/args.log")" = "1" ]'
ok "A–D: no ↻ on clean boundaries"        '! grep -aq "↻" "$TEST/runA.out" && ! grep -aq "↻" "$TEST/runB.out" && ! grep -aq "↻" "$TEST/runC.out" && ! grep -aq "↻" "$TEST/runD.out"'

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed   (fixture: $TEST)"
if [ "$fail" -eq 0 ]; then
  cd / && rm -rf "$TEST"   # green run: the sandbox has no further value
  exit 0
fi
echo "Sandbox kept for inspection: $TEST"
exit 1
