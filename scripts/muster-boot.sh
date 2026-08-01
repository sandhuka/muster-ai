#!/usr/bin/env bash
# muster-boot.sh — action: resolve the session's route, bind the role, print ONE directive (family: verb — acts).
#
# The whole session bootstrap in one call. Replaces the priority-zero routing prose that lived
# duplicated (and drifted) in project CLAUDE.md + muster/CLAUDE.md: housekeeping, `.populated`
# routing, $MUSTER_ROLE precedence, auto-mode queue parsing, JIT gate, and the bind — resolved
# here deterministically, on any model. The model's only job is to obey the printed ROUTE= line.
# Errors surface as ROUTE=halt with a verbatim, relayable MSG — that IS the error contract.
#
# Phase 1 (no args):   bash muster/scripts/muster-boot.sh
#   Routes and, when the role is decidable (env var / auto / onboarding), binds inline.
# Phase 2 (role arg):  bash muster/scripts/muster-boot.sh <role>
#   Called after the interactive picker (or /rebind) resolves a role: JIT gate + bind + notice.
#
# Output contract (line 1 is always ROUTE=...; extra data lines follow where noted):
#   ROUTE=halt        MSG="<verbatim halt string>"
#   ROUTE=framework   MSG="framework repo — read MUSTER.md and bind per its Home Detection"
#   ROUTE=onboarding  MODE=<existing|greenfield> READ=<discovery skill>   (PM bound inline)
#   ROUTE=bind        ROLE=<role> INVOKER=<env-var|auto|interactive> READ=<bootloader> [+ NOTICE=]
#   ROUTE=jit         TARGET=<role> READ=<context-cascading skill> [+ THEN=]  (PM bound inline)
#   ROUTE=pick        LAST_ROLE=<role|-> [+ GROUP= lines + AFTER_PICK=]
set -uo pipefail

# Home detection: in a project the muster tree is ALWAYS at <project>/muster/ (framework
# contract), so the tree's basename decides — derived from THIS SCRIPT's location, never the
# caller's cwd. Any other basename = the framework repo itself, where the CLAUDE.md carve-out
# routes via MUSTER.md before boot is ever called — courtesy line only.
# (Documented edge: a framework CLONE named exactly 'muster' reads as an uninitialized project.)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ "$(basename "$MUSTER_ROOT")" != "muster" ]; then
  echo 'ROUTE=framework MSG="framework repo — read MUSTER.md and bind per its Home Detection"'
  exit 0
fi
cd "$MUSTER_ROOT/.."

POP="knowledge-base/agent-context/.populated"
ROLES="pm developer ui-ux qa content marketing legal research"
REPAIR="Repair knowledge-base/agent-context/.populated against muster/templates/knowledge-base/agent-context/.populated."

# Telemetry: one line per invocation to knowledge-base/.muster-boot-log (gitignored, rotated by
# housekeeping like the bind log). Write-only at runtime — read only when debugging: a `route=pick`
# with no phase=2 `route=bind` for the same session = dropped picker handshake; a halt keeps its
# exact message; a jit with no later bind = populate never completed. Never blocks the boot.
PHASE=1
log_route(){
  [ -d knowledge-base ] || return 0
  printf '%s session=%s phase=%s %s\n' "$(date -Iseconds)" "${MUSTER_SESSION_ID:-${CLAUDE_CODE_SESSION_ID:-unknown}}" "$PHASE" "$*" \
    >> knowledge-base/.muster-boot-log 2>/dev/null || true
}

halt(){ log_route "route=halt msg=\"$1\""; printf 'ROUTE=halt MSG="%s"\n' "$1"; exit 0; }

# Session-start housekeeping (idempotent; its own contract lives in the script).
bash "$SCRIPT_DIR/muster-housekeeping.sh" || true

# .populated parse: the shared parser (muster-check-context.sh sources the same file, so the
# routing gate and the subagent startup gate can never disagree on the state file).
# Fail CLOSED: a missing parser halts rather than misrouting on empty reads.
source "$SCRIPT_DIR/muster-read-populated.sh" 2>/dev/null || halt "muster/scripts/muster-read-populated.sh missing — update the muster submodule (git submodule update --remote muster)."
key(){ pop_key "$@"; }

if [ ! -f "$POP" ]; then
  if [ -d knowledge-base ]; then
    halt "Pre-v2 Muster setup detected. Run 'bash muster/scripts/migrate-v1-to-v2.sh' from the project root."
  fi
  halt "Muster setup incomplete. Run 'scripts/setup-project.sh <name>' (greenfield) or 'scripts/setup-existing-project.sh --resume' (existing codebase / interrupted setup)."
fi

ONBOARDED="$(key onboarded_at)"
COMPLETE="$(key onboarding_complete_at)"
AGENTS_PM="$(key pm agents)"
case "$ONBOARDED" in ""|*'{'*|*'}'*) halt "Invalid .populated (unreadable onboarded_at). $REPAIR" ;; esac
[ -n "$COMPLETE" ]  || halt "Invalid .populated (missing onboarding_complete_at). $REPAIR"
[ -n "$AGENTS_PM" ] || halt "Invalid .populated (agents block unreadable). $REPAIR"

bind(){
  bash "$SCRIPT_DIR/muster-bind.sh" "$1" "$2" || {
    printf 'ROUTE=halt MSG="bind failed for role %s — see error above"\n' "$1"; exit 1; }
}

notice_line(){ # deterministic non-PM side-scan: open board items + pending founder decisions
  local n fd
  [ "${1:-}" = "pm" ] && return 0   # PM runs full monitoring duties at bind — no aside needed
  n="$(bash "$SCRIPT_DIR/muster-list-open-items.sh" 2>/dev/null | grep -c '^  [^(]' || true)"
  fd="$(awk '/^## Founder Decisions/{f=1;next} f&&/^## /{f=0} f&&/^### /{c++} END{print c+0}' knowledge-base/orchestration-queue.md 2>/dev/null)"
  [ "$(( ${n:-0} + ${fd:-0} ))" -gt 0 ] && printf 'NOTICE=%s open board items, %s founder decisions pending — PM tab when convenient\n' "${n:-0}" "${fd:-0}"
  return 0
}

jit_or_bind(){ # $1=role $2=invoker — JIT gate first, then bind + the session directive
  local role="$1" invoker="$2" pstate
  pstate="$(key "$role" agents)"
  [ -n "$pstate" ] || halt "Invalid .populated (no agents entry for '$role'). $REPAIR"
  if [ "$pstate" = "null" ]; then
    bind pm "$invoker"
    log_route "route=jit target=$role invoker=$invoker"
    printf 'ROUTE=jit TARGET=%s READ=muster/team/pm/skills/generic/context-cascading.md\n' "$role"
    printf 'THEN=populate %s per Just-in-time mode, then run: bash muster/scripts/muster-boot.sh %s\n' "$role" "$role"
    exit 0
  fi
  [ -f "muster/team/$role/bootloader.md" ] || halt "Bootloader muster/team/$role/bootloader.md missing — muster checkout incomplete. Run: git submodule update --init, then retry."
  bind "$role" "$invoker"
  log_route "route=bind role=$role invoker=$invoker"
  printf 'ROUTE=bind ROLE=%s INVOKER=%s READ=muster/team/%s/bootloader.md\n' "$role" "$invoker" "$role"
  notice_line "$role"
  exit 0
}

# --- phase 2: explicit role arg (post-picker or /rebind) ---
if [ $# -ge 1 ]; then
  PHASE=2
  case " $ROLES " in *" $1 "*) ;; *) halt "'$1' is not a valid role. Valid: $ROLES." ;; esac
  jit_or_bind "$1" interactive
fi

# --- onboarding routes (priority zero — env var never overrides these) ---
if [ "$ONBOARDED" != "null" ] && [ "$COMPLETE" = "null" ]; then
  SKILL="muster/team/pm/skills/generic/reverse-discovery.md"
  [ -f "$SKILL" ] || halt "Onboarding skill not found. Run 'git submodule update --remote muster' or re-run 'scripts/setup-existing-project.sh'."
  bind pm onboarding
  log_route "route=onboarding mode=existing"
  printf 'ROUTE=onboarding MODE=existing READ=%s\n' "$SKILL"; exit 0
fi
if [ "$ONBOARDED" = "null" ] && [ "$AGENTS_PM" = "null" ]; then
  SKILL="muster/team/pm/skills/generic/greenfield-discovery.md"
  [ -f "$SKILL" ] || halt "Greenfield Discovery skill not found. Run 'git submodule update --remote muster' or re-run 'scripts/setup-project.sh'."
  bind pm onboarding
  log_route "route=onboarding mode=greenfield"
  printf 'ROUTE=onboarding MODE=greenfield READ=%s\n' "$SKILL"; exit 0
fi

# --- picker-fire paths: $MUSTER_ROLE precedence, then interactive picker ---
MR="${MUSTER_ROLE:-}"
case "$MR" in
  "") : ;;  # interactive — fall through to the picker
  auto)
    role="$(bash "$SCRIPT_DIR/muster-read-queue.sh" role)"
    [ -n "$role" ] || halt "MUSTER_ROLE=auto but orchestration queue has no parseable Next Step. Cannot determine role. Halt."
    case "$role" in
      halt) halt "Queue Next Step is 'Role: halt' — a founder gate, not a bindable step. Answer '## Founder Decisions' in knowledge-base/orchestration-queue.md, then re-plan the queue in a PM tab." ;;
    esac
    case " $ROLES " in
      *" $role "*) jit_or_bind "$role" auto ;;
      *) halt "MUSTER_ROLE=auto but Next Step names invalid role '$role'. Valid: $ROLES. Fix the queue's Role: line. Halt." ;;
    esac ;;
  *)
    case " $ROLES " in
      *" $MR "*) jit_or_bind "$MR" env-var ;;
      *) halt "MUSTER_ROLE='$MR' is not a valid role. Valid: pm, developer, ui-ux, qa, content, marketing, legal, research, auto. Halt." ;;
    esac ;;
esac

# --- interactive: emit picker data; the model runs the two-step AskUserQuestion picker ---
LAST="-"; [ -f .claude/.muster-last-role ] && LAST="$(cat .claude/.muster-last-role)"
log_route "route=pick last=$LAST"
cat <<EOF
ROUTE=pick LAST_ROLE=$LAST
GROUP=Coordination: pm
GROUP=Build: developer ui-ux qa
GROUP=Communicate: content marketing
GROUP=Validate: research legal
AFTER_PICK=run: bash muster/scripts/muster-boot.sh <picked-role>
EOF
exit 0
