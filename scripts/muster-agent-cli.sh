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
# Provider indirection (model-portability Stage 1): MUSTER_PROVIDER_URL routes the CLI to any
# Anthropic-compatible endpoint (Kimi/GLM/DeepSeek native, or a LiteLLM/claude-code-router
# proxy); MUSTER_PROVIDER_KEY_ENV names the env var holding that provider's key — the NAME,
# never the key, so a committed .muster/config can carry it safely. Resolution happens here,
# in the seam, because ANTHROPIC_BASE_URL/ANTHROPIC_AUTH_TOKEN are harness surface.
#
# agent_stream <role> <max_turns> <model-or-''> <prompt>   — driver steps (event stream)
# agent_plain  <role> <max_turns> <prompt>                 — one-shot calls (plain output)

_provider_env(){
  if [ -n "${MUSTER_PROVIDER_URL:-}" ]; then export ANTHROPIC_BASE_URL="$MUSTER_PROVIDER_URL"; fi
  if [ -n "${MUSTER_PROVIDER_KEY_ENV:-}" ]; then
    case "$MUSTER_PROVIDER_KEY_ENV" in
      *[!A-Za-z0-9_]*|[0-9]*)
        echo "⛔ MUSTER_PROVIDER_KEY_ENV is not a valid env-var name: '$MUSTER_PROVIDER_KEY_ENV'" >&2; return 1 ;;
    esac
    eval "_pk=\"\${$MUSTER_PROVIDER_KEY_ENV:-}\""
    if [ -z "$_pk" ]; then
      echo "⛔ provider key env '\$$MUSTER_PROVIDER_KEY_ENV' is empty — export it before the run." >&2; return 1
    fi
    export ANTHROPIC_AUTH_TOKEN="$_pk"
  fi
  return 0
}

agent_stream(){
  _provider_env || return 1
  local role="$1" turns="$2" model="$3" prompt="$4"
  MUSTER_ROLE="$role" "${MUSTER_AGENT_CLI:-claude}" -p --dangerously-skip-permissions \
    --max-turns "$turns" ${model:+--model} ${model:+"$model"} \
    --output-format stream-json --verbose "$prompt"
}

agent_plain(){
  _provider_env || return 1
  local role="$1" turns="$2" prompt="$3"
  MUSTER_ROLE="$role" "${MUSTER_AGENT_CLI:-claude}" -p --dangerously-skip-permissions \
    --max-turns "$turns" "$prompt"
}
