#!/usr/bin/env bash
# muster-agent-cli.sh — action: invoke the agent CLI for a headless step (family: shared adapter — sourced, never run).
#
# THE adapter seam: the only place Muster shells out to an agent harness. Every
# harness-specific flag lives in this file and nowhere else — porting to a different
# agent CLI means pointing MUSTER_AGENT_CLI at a wrapper binary (or editing the two
# functions below), never hunting invocations across the fleet.
#
# MUSTER_AGENT_CLI (env/config; default: claude) names the binary. A wrapper for a
# foreign harness receives exactly the argv these functions build and must honor the
# same contract: run headlessly, honor MUSTER_ROLE in env, exit with the underlying
# agent's status. agent_stream must emit the event stream on stdout (Claude Code
# stream-json today; muster-sprint-format.sh is the parser for it).
#
# Exit-code transparency is load-bearing: each function's last command IS the CLI
# call, so its return value is the CLI's own exit code — the driver's stop conditions
# key off it via PIPESTATUS[0] and the formatter can never mask it.
#
# agent_stream <role> <max_turns> <model-or-''> <prompt>   — driver steps (event stream)
# agent_plain  <role> <max_turns> <prompt>                 — one-shot calls (plain output)

agent_stream(){
  local role="$1" turns="$2" model="$3" prompt="$4"
  MUSTER_ROLE="$role" "${MUSTER_AGENT_CLI:-claude}" -p --dangerously-skip-permissions \
    --max-turns "$turns" ${model:+--model} ${model:+"$model"} \
    --output-format stream-json --verbose "$prompt"
}

agent_plain(){
  local role="$1" turns="$2" prompt="$3"
  MUSTER_ROLE="$role" "${MUSTER_AGENT_CLI:-claude}" -p --dangerously-skip-permissions \
    --max-turns "$turns" "$prompt"
}
