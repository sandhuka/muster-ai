#!/usr/bin/env bash
# test-agent-cli.sh — fixture gate for muster-agent-cli.sh (the harness adapter seam).
# Pins the adapter contract: exact argv shape for agent_stream (with and without a model
# override) and agent_plain, MUSTER_ROLE in the child env, MUSTER_AGENT_CLI binary selection
# (default claude via PATH), and exit-code transparency — the driver's stop conditions and the
# resume wrapper both depend on the CLI's own status surviving the function boundary.
set -uo pipefail
MUSTER="$(cd "$(dirname "$0")/.." && pwd)"
SB="$(mktemp -d "${TMPDIR:-/tmp}/muster-agentcli-test.XXXXXX")"
trap 'rm -rf "$SB"' EXIT
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }
no(){ echo "FAIL: $1"; fail=$((fail+1)); }

# Stub CLI: records argv (one per line) + MUSTER_ROLE, exits with $STUB_RC.
mkdir -p "$SB/bin"
cat > "$SB/bin/stub-cli" <<EOF
#!/usr/bin/env bash
{ echo "ROLE=\$MUSTER_ROLE"; for a in "\$@"; do echo "\$a"; done; } > "$SB/argv"
exit "\${STUB_RC:-0}"
EOF
cp "$SB/bin/stub-cli" "$SB/bin/claude"
chmod +x "$SB/bin/stub-cli" "$SB/bin/claude"

source "$MUSTER/scripts/muster-agent-cli.sh" || { echo "FAIL: adapter did not source"; exit 1; }

want(){ # $1=name  $2=expected argv file content
  if [ "$(cat "$SB/argv")" = "$2" ]; then ok "$1"; else no "$1"; sed 's/^/  got: /' "$SB/argv"; fi
}

# agent_stream with a model override — every harness flag, in order
MUSTER_AGENT_CLI="$SB/bin/stub-cli" agent_stream auto 150 claude-opus-4-8 "do the step" >/dev/null
want "stream argv (model set)" "ROLE=auto
-p
--dangerously-skip-permissions
--max-turns
150
--model
claude-opus-4-8
--output-format
stream-json
--verbose
do the step"

# agent_stream with NO model — the --model pair must vanish entirely
MUSTER_AGENT_CLI="$SB/bin/stub-cli" agent_stream auto 150 "" "do the step" >/dev/null
want "stream argv (no model)" "ROLE=auto
-p
--dangerously-skip-permissions
--max-turns
150
--output-format
stream-json
--verbose
do the step"

# agent_plain — plain output, no stream flags
MUSTER_AGENT_CLI="$SB/bin/stub-cli" agent_plain pm 150 "process the gate" >/dev/null
want "plain argv" "ROLE=pm
-p
--dangerously-skip-permissions
--max-turns
150
process the gate"

# default binary is claude, resolved via PATH (how fixtures stub the harness)
rm -f "$SB/argv"
( PATH="$SB/bin:$PATH"; unset MUSTER_AGENT_CLI; agent_plain pm 5 "hi" >/dev/null )
grep -q "^ROLE=pm$" "$SB/argv" && ok "default binary: claude via PATH" || no "default claude not invoked"

# exit-code transparency: the CLI's status survives the function boundary untouched
MUSTER_AGENT_CLI="$SB/bin/stub-cli" STUB_RC=7 agent_plain pm 5 "hi" >/dev/null
[ $? -eq 7 ] && ok "exit code passes through (7)" || no "exit code masked"
MUSTER_AGENT_CLI="$SB/bin/stub-cli" STUB_RC=0 agent_stream auto 5 "" "hi" >/dev/null
[ $? -eq 0 ] && ok "clean exit passes through (0)" || no "clean exit not 0"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && exit 0 || exit 1
