#!/usr/bin/env bash
# muster-doctor-populated.sh — action: diagnose the session-routing state file (family: verb — reports, never mutates).
#
# .populated is read on the FIRST tool call of every session and routes the whole bootstrap;
# a bad one misroutes an entire session (re-fires onboarding, burns a step on a HALT) with no
# validator anywhere. This is the validator. It also graduates the boot-telemetry patterns:
# the failure shapes .muster-boot-log records (dropped picker handshakes, unresolved JIT
# detours) are detected here instead of eyeballed.
#
#   FAIL — file missing/unparseable · schema key missing · version != "2" · agents roster
#          mismatch (missing or unknown role) · non-ISO timestamp value · file gitignored
#   WARN — stale populate lock (lock.since > 15 min — safe to overwrite per
#          context-cascading.md) · active lock (< 15 min — a populate may be in flight) ·
#          file untracked in git · state identical to the shipped template while the project
#          has real board content (looks reset) · boot-log: dropped handshakes / unresolved JIT
#
# Usage: muster-doctor-populated.sh   (call sites: the Guide's run-debugging flow; any repair)
# Exit: 0 healthy (WARNs allowed) · 1 FAIL findings · 3 wiring error
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ "$(basename "$MUSTER_ROOT")" != "muster" ]; then
  echo "muster-doctor-populated: not inside a project (muster tree not at <project>/muster/)" >&2; exit 3
fi
cd "$MUSTER_ROOT/.."

POP="knowledge-base/agent-context/.populated"
TEMPLATE="$MUSTER_ROOT/templates/knowledge-base/agent-context/.populated"
REPAIR="repair against muster/templates/knowledge-base/agent-context/.populated (preserve real timestamps from git history)"
fails=0; warns=0
fail(){ echo "FAIL: $1"; fails=$((fails+1)); }
warn(){ echo "WARN: $1"; warns=$((warns+1)); }

[ -f "$POP" ] || { fail "$POP missing — every session misroutes to setup halts; $REPAIR"; echo "1 FAIL, 0 WARN"; exit 1; }

source "$SCRIPT_DIR/muster-read-populated.sh"

# Schema: the 5 top-level keys, version pinned.
for k in version onboarded_at onboarding_complete_at agents lock; do
  grep -q "\"$k\"" "$POP" || fail "schema key \"$k\" missing — $REPAIR"
done
v="$(key_ver=$(pop_key version); printf '%s' "$key_ver")"
[ "$v" = "2" ] || fail "version is '${v:-unreadable}' (expected \"2\") — $REPAIR"

# Roster: agents block keys == the 8 roles exactly.
ROSTER="pm developer ui-ux qa content marketing legal research"
agents_keys="$(awk '/"agents"[[:space:]]*:/{inag=1; next} inag && /}/{exit} inag && /"/{k=$0; sub(/^[^"]*"/,"",k); sub(/".*$/,"",k); print k}' "$POP")"
for r in $ROSTER; do
  printf '%s\n' "$agents_keys" | grep -qx "$r" || fail "agents block missing role \"$r\" — boot's JIT gate and check-context fail closed on it; $REPAIR"
done
while read -r k; do
  [ -z "$k" ] && continue
  case " $ROSTER " in *" $k "*) ;; *) fail "agents block has unknown key \"$k\" — not a roster role; $REPAIR" ;; esac
done <<< "$agents_keys"

# Timestamp shapes: null or ISO-like (YYYY-MM-DD...).
tcheck(){ # $1=label $2=value
  case "$2" in
    null|"") ;;                                  # null fine; empty already caught by schema
    20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]*) ;;
    *) fail "$1 is '$2' — not null or ISO (YYYY-MM-DD…); routing compares against null literally" ;;
  esac
}
tcheck onboarded_at "$(pop_key onboarded_at)"
tcheck onboarding_complete_at "$(pop_key onboarding_complete_at)"
for r in $ROSTER; do tcheck "agents.$r" "$(pop_key "$r" agents)"; done

# Lock: null, or {"agent":…,"since":<iso>} — stale past 15 min per context-cascading.md.
lock_line="$(grep -m1 '"lock"' "$POP" || true)"
if [ -n "$lock_line" ] && ! printf '%s' "$lock_line" | grep -q 'null'; then
  since="$(printf '%s' "$lock_line" | grep -oE '20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9:]{8}' | head -1 || true)"
  age=-1
  if [ -n "$since" ]; then
    then_epoch="$(date -d "$since" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$since" +%s 2>/dev/null || echo "")"
    [ -n "$then_epoch" ] && age=$(( ($(date +%s) - then_epoch) / 60 ))
  fi
  if [ "$age" -ge 15 ]; then warn "populate lock is STALE (${age} min old) — safe to set lock back to null (context-cascading.md)"
  elif [ "$age" -ge 0 ]; then warn "populate lock is ACTIVE (${age} min old) — a JIT populate may be in flight; wait before touching state"
  else warn "populate lock is set but its 'since' timestamp is unreadable — inspect and clear by hand"
  fi
fi

# Git visibility: routing state must travel with the repo.
if git rev-parse --git-dir >/dev/null 2>&1; then
  if git check-ignore -q "$POP" 2>/dev/null; then
    fail "$POP is GITIGNORED — teammates/worktrees get no routing state (every clone re-onboards); un-ignore and commit it"
  elif ! git ls-files --error-unmatch "$POP" >/dev/null 2>&1; then
    warn "$POP is untracked — commit it so worktrees and clones inherit routing state"
  fi
fi

# Looks-reset detection: identical to the shipped template while the board has real content.
if [ -f "$TEMPLATE" ] && cmp -s "$POP" "$TEMPLATE"; then
  if grep -qE '^### ' knowledge-base/agent-requests.md 2>/dev/null || grep -qE '^### |^\*\*20' knowledge-base/decision-log.md 2>/dev/null; then
    warn "state file is byte-identical to the template but the project has real board content — was it reset? Recover timestamps from git history"
  fi
fi

# Boot-telemetry graduation: the log's failure shapes, detected instead of eyeballed.
BLOG="knowledge-base/.muster-boot-log"
if [ -f "$BLOG" ]; then
  dropped="$(awk '
    /phase=1 route=pick/ { if (match($0, /session=[^ ]+/)) pend[substr($0, RSTART+8, RLENGTH-8)] = 1 }
    /phase=2 route=(bind|jit)/ { if (match($0, /session=[^ ]+/)) delete pend[substr($0, RSTART+8, RLENGTH-8)] }
    END { n = 0; for (s in pend) n++; print n }
  ' "$BLOG")"
  [ "${dropped:-0}" -gt 0 ] && warn "boot log shows $dropped picker session(s) with no phase-2 bind — the dropped-handshake pattern (model showed the picker, never ran AFTER_PICK)"
  unresolved="$(awk '
    /route=jit target=/ { if (match($0, /target=[^ ]+/)) pend[substr($0, RSTART+7, RLENGTH-7)]++ }
    /route=bind role=/  { if (match($0, /role=[^ ]+/))  delete pend[substr($0, RSTART+5, RLENGTH-5)] }
    END { n = 0; for (r in pend) n++; print n }
  ' "$BLOG")"
  [ "${unresolved:-0}" -gt 0 ] && warn "boot log shows $unresolved JIT detour(s) never followed by a bind for that role — populate likely abandoned mid-flight"
fi

echo "$fails FAIL, $warns WARN"
[ "$fails" -eq 0 ] && { echo "OK: .populated is healthy"; exit 0; }
exit 1
