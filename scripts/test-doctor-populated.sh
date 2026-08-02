#!/usr/bin/env bash
# test-doctor-populated.sh — fixture gate for muster-doctor-populated.sh (state-file doctor).
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/muster-doc-test.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT

PROJ="$SBX/proj"
mkdir -p "$PROJ/muster/scripts" "$PROJ/muster/templates/knowledge-base/agent-context" "$PROJ/knowledge-base/agent-context"
for s in muster-doctor-populated.sh muster-read-populated.sh; do cp "$SRC/scripts/$s" "$PROJ/muster/scripts/"; done
cp "$SRC/templates/knowledge-base/agent-context/.populated" "$PROJ/muster/templates/knowledge-base/agent-context/"
touch "$PROJ/muster/system-guide.md"
DOC="$PROJ/muster/scripts/muster-doctor-populated.sh"

n=0; fails=0
t(){ local name="$1" wrc="$2" want="$3"
  n=$((n+1))
  local out rc; out="$(cd "$PROJ" && bash "$DOC" 2>&1)"; rc=$?
  if [ "$rc" = "$wrc" ] && printf '%s\n' "$out" | grep -qF -- "$want"; then echo "PASS: $name"
  else fails=$((fails+1)); echo "FAIL: $name (rc=$rc want=$wrc)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fi
}
POPF="$PROJ/knowledge-base/agent-context/.populated"
goodpop(){ cat > "$POPF" <<'EOF'
{
  "version": "2",
  "onboarded_at": "2026-07-01T10:00:00Z",
  "onboarding_complete_at": null,
  "agents": {
    "developer": "2026-01-01T09:00:00Z",
    "ui-ux": null,
    "content": null,
    "qa": null,
    "research": null,
    "marketing": null,
    "legal": null,
    "pm": "2026-01-01T09:00:00Z"
  },
  "lock": null
}
EOF
}

# missing file -> FAIL
rm -f "$POPF"
t missing-file-fails 1 "FAIL: knowledge-base/agent-context/.populated missing"

# healthy state -> OK
goodpop
t healthy-ok 0 "OK: .populated is healthy"

# bad version -> FAIL
sed 's/"version": "2"/"version": "9"/' "$POPF" > "$POPF.t" && mv "$POPF.t" "$POPF"
t bad-version-fails 1 'version is'
goodpop

# missing roster role -> FAIL
grep -v '"legal"' "$POPF" > "$POPF.t" && mv "$POPF.t" "$POPF"
t missing-role-fails 1 'agents block missing role "legal"'
goodpop

# unknown extra role -> FAIL
sed 's/"pm": "2026-01-01T09:00:00Z"/"pm": "2026-01-01T09:00:00Z",\n    "intern": null/' "$POPF" > "$POPF.t" && mv "$POPF.t" "$POPF"
t unknown-role-fails 1 'unknown key "intern"'
goodpop

# junk timestamp -> FAIL
sed 's/"onboarded_at": "2026-07-01T10:00:00Z"/"onboarded_at": "yesterday"/' "$POPF" > "$POPF.t" && mv "$POPF.t" "$POPF"
t junk-timestamp-fails 1 "onboarded_at is 'yesterday'"
goodpop

# stale lock -> WARN, exit 0
sed 's/"lock": null/"lock": {"agent": "pm", "since": "2026-01-01T00:00:00Z"}/' "$POPF" > "$POPF.t" && mv "$POPF.t" "$POPF"
t stale-lock-warns 0 "populate lock is STALE"
goodpop

# looks-reset: template copy + real board content -> WARN
cp "$PROJ/muster/templates/knowledge-base/agent-context/.populated" "$POPF"
printf '## Active Requests\n### 2026-07-30 REQ-9 — real thing\n' > "$PROJ/knowledge-base/agent-requests.md"
t looks-reset-warns 0 "byte-identical to the template but the project has real board content"
rm -f "$PROJ/knowledge-base/agent-requests.md"
goodpop

# boot-log patterns: dropped handshake + unresolved jit -> WARNs
cat > "$PROJ/knowledge-base/.muster-boot-log" <<'EOF'
2026-07-30T10:00:00 session=aaa phase=1 route=pick last=-
2026-07-30T10:05:00 session=bbb phase=1 route=pick last=developer
2026-07-30T10:05:30 session=bbb phase=2 route=bind role=qa invoker=interactive
2026-07-30T11:00:00 session=ccc phase=1 route=jit target=legal invoker=env-var
EOF
t dropped-handshake-warns 0 "1 picker session(s) with no phase-2 bind"
t unresolved-jit-warns 0 "1 JIT detour(s) never followed by a bind"

echo "----"
if [ "$fails" -eq 0 ]; then echo "RESULT: $n/$n passed"; exit 0
else echo "RESULT: $((n-fails))/$n passed — $fails FAILED"; exit 1; fi
