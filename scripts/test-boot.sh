#!/usr/bin/env bash
# test-boot.sh — fixture gate for muster-boot.sh + muster-read-queue.sh (the routing contract).
# Proves every ROUTE (halt/framework/onboarding/bind/jit/pick) on BOTH repo layouts, env-var
# precedence, auto-mode queue parsing (incl. 'Role: halt' founder gates), JIT, corrupt-state
# fail-closed halts, cwd-independence, and the non-PM NOTICE side-scan. Runs in a throwaway
# sandbox — never touches the real repo state.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/muster-boot-test.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT
export CLAUDE_CODE_SESSION_ID=boot-fixture

# --- sandbox: project layout (muster embedded at muster/) ---
PROJ="$SBX/proj"
mkdir -p "$PROJ/muster/scripts" "$PROJ/muster/team/pm/skills/generic" \
         "$PROJ/knowledge-base/agent-context" "$PROJ/.claude/agents"
for s in muster-boot.sh muster-read-queue.sh muster-read-populated.sh muster-bind.sh muster-housekeeping.sh muster-list-open-items.sh; do
  cp "$SRC/scripts/$s" "$PROJ/muster/scripts/"
done
touch "$PROJ/muster/system-guide.md"
echo stub > "$PROJ/muster/team/pm/skills/generic/reverse-discovery.md"
echo stub > "$PROJ/muster/team/pm/skills/generic/greenfield-discovery.md"
for r in pm developer ui-ux qa content marketing legal research; do echo stub > "$PROJ/.claude/agents/$r.md"; done

pop(){ # $1=onboarded $2=complete $3=agents.pm $4=agents.developer
  cat > "$PROJ/knowledge-base/agent-context/.populated" <<EOF
{
  "version": "2",
  "onboarded_at": $1,
  "onboarding_complete_at": $2,
  "agents": {
    "developer": $4,
    "ui-ux": "2026-01-01",
    "content": "2026-01-01",
    "qa": "2026-01-01",
    "research": "2026-01-01",
    "marketing": "2026-01-01",
    "legal": "2026-01-01",
    "pm": $3
  },
  "lock": null
}
EOF
}
queue(){ cat > "$PROJ/knowledge-base/orchestration-queue.md"; }

n=0; fails=0
run(){ (cd "${T_CWD:-$PROJ}" && env -u MUSTER_ROLE ${MR:+MUSTER_ROLE="$MR"} bash "$@" 2>&1); }
t(){ # $1=name $2=expected-first-line-prefix; rest = command
  local name="$1" want="$2"; shift 2
  n=$((n+1))
  local out first; out="$(run "$@")"; first="$(printf '%s\n' "$out" | head -1)"
  case "$first" in
    "$want"*) echo "PASS: $name" ;;
    *) fails=$((fails+1)); echo "FAIL: $name"; echo "  want: $want"; printf '%s\n' "$out" | sed 's/^/  got:  /' ;;
  esac
}
tgrep(){ # $1=name $2=pattern that must appear on SOME output line; rest = command
  local name="$1" want="$2"; shift 2
  n=$((n+1))
  local out; out="$(run "$@")"
  if printf '%s\n' "$out" | grep -F -- "$want" >/dev/null; then echo "PASS: $name"
  else fails=$((fails+1)); echo "FAIL: $name"; echo "  want line containing: $want"; printf '%s\n' "$out" | sed 's/^/  got:  /'; fi
}
BOOT="muster/scripts/muster-boot.sh"
RQ="muster/scripts/muster-read-queue.sh"

# --- halts: uninitialized / pre-v2 / corrupt state (fail-closed) ---
rm -rf "$PROJ/knowledge-base"
t halt-uninitialized 'ROUTE=halt MSG="Muster setup incomplete' "$BOOT"
mkdir -p "$PROJ/knowledge-base"
t halt-pre-v2 'ROUTE=halt MSG="Pre-v2' "$BOOT"
mkdir -p "$PROJ/knowledge-base/agent-context"
echo '<<<<<<< merge garbage' > "$PROJ/knowledge-base/agent-context/.populated"
t halt-corrupt-populated 'ROUTE=halt MSG="Invalid .populated' "$BOOT"
cat > "$PROJ/knowledge-base/agent-context/.populated" <<'EOF'
{
  "version": "2",
  "onboarded_at": "2026-07-01",
  "onboarding_complete_at": "2026-07-02",
  "agents": GARBAGE,
  "lock": null
}
EOF
MR=developer t halt-mangled-agents 'ROUTE=halt MSG="Invalid .populated (agents block unreadable)' "$BOOT"

# --- onboarding routes (and their priority over the env var) ---
pop '"2026-07-01"' null '"2026-07-01"' '"2026-07-01"'
t onboarding-existing 'ROUTE=onboarding MODE=existing READ=muster/team/pm/skills/generic/reverse-discovery.md' "$BOOT"
MR=developer t onboarding-beats-envvar 'ROUTE=onboarding MODE=existing' "$BOOT"
pop null null null null
t onboarding-greenfield 'ROUTE=onboarding MODE=greenfield READ=muster/team/pm/skills/generic/greenfield-discovery.md' "$BOOT"
mv "$PROJ/muster/team/pm/skills/generic/greenfield-discovery.md" "$SBX/gd.bak"
t halt-skill-missing 'ROUTE=halt MSG="Greenfield Discovery skill not found' "$BOOT"
mv "$SBX/gd.bak" "$PROJ/muster/team/pm/skills/generic/greenfield-discovery.md"
pop null null '"2026-07-01"' null
t greenfield-ongoing-pick 'ROUTE=pick' "$BOOT"

# --- env-var precedence: valid / wrong-case / non-session role / garbage ---
pop '"2026-07-01"' '"2026-07-02"' '"2026-07-01"' '"2026-07-01"'
MR=developer t env-var-bind 'ROUTE=bind ROLE=developer INVOKER=env-var READ=.claude/agents/developer.md' "$BOOT"
MR=Developer t case-exact-role "ROUTE=halt MSG=\"MUSTER_ROLE='Developer'" "$BOOT"
MR=guide t guide-not-session-role "ROUTE=halt MSG=\"MUSTER_ROLE='guide'" "$BOOT"
MR=banana t invalid-role-halt "ROUTE=halt MSG=\"MUSTER_ROLE='banana'" "$BOOT"

# --- auto mode: role / pm default / trailing ws / founder gate / complete queue ---
queue <<'EOF'
# Queue
## Next Step
### Step 4 — QA pass
```
Role: qa
Do the thing.
```
## Upcoming
EOF
MR=auto t auto-role-qa 'ROUTE=bind ROLE=qa INVOKER=auto' "$BOOT"
printf '## Next Step\n```\nJust a prompt.\n```\n## Upcoming\n' | queue
MR=auto t auto-default-pm 'ROUTE=bind ROLE=pm INVOKER=auto' "$BOOT"
printf '## Next Step\n```\nRole: qa   \nprompt\n```\n## Upcoming\n' | queue
MR=auto t auto-role-trailing-ws 'ROUTE=bind ROLE=qa INVOKER=auto' "$BOOT"
printf '## Next Step\n```\nRole: halt\nGate.\n```\n## Upcoming\n' | queue
MR=auto t auto-founder-gate "ROUTE=halt MSG=\"Queue Next Step is 'Role: halt'" "$BOOT"
printf '## Next Step\n_(empty — sprint complete)_\n## Upcoming\n' | queue
MR=auto t auto-complete-halt 'ROUTE=halt MSG="MUSTER_ROLE=auto but orchestration queue has no parseable' "$BOOT"

# --- shared parser, executed directly (same file the driver sources) ---
printf '## Next Step\n```\nRole: qa\n```\n## Upcoming\n' | queue
t readqueue-role 'qa' "$RQ" role
printf '## Next Step\nno fence here\n## Upcoming\n' | queue
n=$((n+1))
if [ -z "$(run "$RQ" role)" ]; then echo "PASS: readqueue-complete-empty"
else echo "FAIL: readqueue-complete-empty"; fails=$((fails+1)); fi

# --- interactive picker + phase 2 bind ---
printf '## Next Step\n```\nRole: qa\n```\n## Upcoming\n' | queue
echo developer > "$PROJ/.claude/.muster-last-role"
t steady-pick-lastrole 'ROUTE=pick LAST_ROLE=developer' "$BOOT"
tgrep pick-afterpick-line 'AFTER_PICK=run: bash muster/scripts/muster-boot.sh' "$BOOT"
t phase2-bind 'ROUTE=bind ROLE=qa INVOKER=interactive' "$BOOT" qa
n=$((n+1))
if grep -q '^qa$' "$PROJ/.claude/.muster-last-role"; then echo "PASS: phase2-lastrole-written"
else echo "FAIL: phase2-lastrole-written"; fails=$((fails+1)); fi
tgrep phase2-invalid-role "'banana' is not a valid role" "$BOOT" banana

# --- JIT gate + missing bootloader (fail-closed) ---
pop '"2026-07-01"' '"2026-07-02"' '"2026-07-01"' null
MR=developer t jit-needed 'ROUTE=jit TARGET=developer READ=muster/team/pm/skills/generic/context-cascading.md' "$BOOT"
pop '"2026-07-01"' '"2026-07-02"' '"2026-07-01"' '"2026-07-01"'
mv "$PROJ/.claude/agents/developer.md" "$SBX/dev.bak"
MR=developer t halt-bootloader-missing 'ROUTE=halt MSG="Bootloader .claude/agents/developer.md missing' "$BOOT"
mv "$SBX/dev.bak" "$PROJ/.claude/agents/developer.md"

# --- NOTICE side-scan: fires for non-PM with open items, silent for PM ---
cat > "$PROJ/knowledge-base/agent-requests.md" <<'EOF'
## Active Handoffs
### 2026-07-20 — HO-9 — Thing needing review
**Status:** open
## Active Requests
## Resolved
EOF
printf '## Next Step\n```\nRole: qa\n```\n## Upcoming\n\n## Founder Decisions\n### Pick a name\n' > "$PROJ/knowledge-base/orchestration-queue.md"
tgrep notice-fires-non-pm 'NOTICE=1 open board items, 1 founder decisions pending' "$BOOT" developer
n=$((n+1))
if run "$BOOT" pm | grep -F 'NOTICE=' >/dev/null; then echo "FAIL: notice-silent-for-pm"; fails=$((fails+1))
else echo "PASS: notice-silent-for-pm"; fi
rm -f "$PROJ/knowledge-base/agent-requests.md"

# --- telemetry: every route leaves a line in .muster-boot-log; handshake is pairable ---
BLOG="$PROJ/knowledge-base/.muster-boot-log"
rm -f "$BLOG"
run "$BOOT" >/dev/null                      # ROUTE=pick (interactive, steady state)
run "$BOOT" qa >/dev/null                   # phase-2 bind (completes the handshake)
MR=banana run "$BOOT" >/dev/null            # a halt (invalid env-var role)
n=$((n+1))
if grep -q "phase=1 route=pick" "$BLOG" && grep -q "phase=2 route=bind role=qa invoker=interactive" "$BLOG"; then
  echo "PASS: telemetry-handshake-pair"
else echo "FAIL: telemetry-handshake-pair"; sed 's/^/  log: /' "$BLOG"; fails=$((fails+1)); fi
n=$((n+1))
if grep -q "route=halt msg=\"MUSTER_ROLE='banana'" "$BLOG"; then
  echo "PASS: telemetry-halt-recorded"
else echo "FAIL: telemetry-halt-recorded"; sed 's/^/  log: /' "$BLOG"; fails=$((fails+1)); fi
n=$((n+1))
if grep -q "session=boot-fixture" "$BLOG"; then
  echo "PASS: telemetry-session-id"
else echo "FAIL: telemetry-session-id"; fails=$((fails+1)); fi
rm -f "$BLOG"

# --- cwd-independence: boot from a nested subdir ---
mkdir -p "$PROJ/src/deep"
T_CWD="$PROJ/src/deep" MR=developer t cwd-independent 'ROUTE=bind ROLE=developer' "../../$BOOT"

# --- framework layout: any non-'muster' tree basename routes to MUSTER.md ---
FW="$SBX/fw"; mkdir -p "$FW/scripts"
cp "$SRC/scripts/muster-boot.sh" "$FW/scripts/"
touch "$FW/system-guide.md" "$FW/MUSTER.md"
T_CWD="$FW" t framework-route 'ROUTE=framework' "scripts/muster-boot.sh"

echo "----"
if [ "$fails" -eq 0 ]; then echo "RESULT: $n/$n passed"; exit 0
else echo "RESULT: $((n-fails))/$n passed — $fails FAILED"; exit 1; fi
