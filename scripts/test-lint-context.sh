#!/usr/bin/env bash
# test-lint-context.sh — fixture gate for muster-lint-context.sh (the Next Step context gate).
# Pins the positive-evidence design: populated files that KEEP the seeded pointer pass, varied
# real-world shapes pass, and every silent-pass mode (rephrased pointer, old template wording,
# comment-only) fails LOUD. Sandboxed.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/muster-ctx-test.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT

PROJ="$SBX/proj"
mkdir -p "$PROJ/muster/scripts" "$PROJ/knowledge-base/agent-context"
for s in muster-lint-context.sh muster-read-queue.sh; do cp "$SRC/scripts/$s" "$PROJ/muster/scripts/"; done
touch "$PROJ/muster/system-guide.md"

n=0; fails=0
t(){ # $1=name $2=want-exit $3=want-first-line-prefix ; rest = args to the lint
  local name="$1" wrc="$2" want="$3"; shift 3
  n=$((n+1))
  local out rc; out="$(cd "${T_CWD:-$PROJ}" && bash "$PROJ/muster/scripts/muster-lint-context.sh" "$@" 2>&1)"; rc=$?
  local first; first="$(printf '%s\n' "$out" | head -1)"
  if [ "$rc" = "$wrc" ] && case "$first" in "$want"*) true ;; *) false ;; esac; then echo "PASS: $name"
  else fails=$((fails+1)); echo "FAIL: $name (rc=$rc want=$wrc)"; printf '%s\n' "$out" | sed 's/^/  got: /'; fi
}
ctx(){ cat > "$PROJ/knowledge-base/agent-context/$1.md"; }

# fresh template shape (pointer only) -> FAIL
ctx qa <<'EOF'
# QA — Agent Context
## Current Tasks
<!-- PM-MANAGED: PM updates at sprint planning, task completion, priority changes -->
<!-- Keep 3-5 active tasks max. Move completed to Recently Completed (keep last 5). -->

See `knowledge-base/current-sprint.md` for current sprint tasks.

## Product Context
Stuff.
EOF
t unpopulated-template 1 "FAIL: knowledge-base/agent-context/qa.md Current Tasks has no real tasks" qa

# populated but pointer line KEPT (live-project shape) -> OK
ctx qa <<'EOF'
# QA — Agent Context
## Current Tasks
<!-- PM-MANAGED -->
See `knowledge-base/current-sprint.md` for current sprint tasks.

### Sprint 9 — your steps: 3 · 6 · 14 (full prompts in orchestration-queue.md)
Run the extended net before any engine change.

## Product Context
EOF
t populated-keeps-pointer 0 "OK: qa context populated" qa

# bold-paragraph standing notes, no ### headings (live-project developer shape) -> OK
ctx developer <<'EOF'
# Developer — Agent Context
## Current Tasks
**⚠️ Headless-session note:** substance lives in current-sprint.md; read it.
**🔁 Quality Discipline:** plan first, stress-test, then build.

## Product Context
EOF
t populated-bold-paragraphs 0 "OK: developer context populated" developer

# rephrased pointer ONLY (the silent-pass trap) -> FAIL
ctx content <<'EOF'
# Content — Agent Context
## Current Tasks
Check `knowledge-base/current-sprint.md` for your tasks this sprint.

## Product Context
EOF
t rephrased-pointer-fails 1 "FAIL: knowledge-base/agent-context/content.md Current Tasks has no real tasks" content

# old/alternate template wording -> FAIL
ctx legal <<'EOF'
# Legal
## Current Tasks
Refer to knowledge-base/current-sprint.md for current sprint tasks.
## Product Context
EOF
t old-wording-fails 1 "FAIL:" legal

# comment-only section (incl. multi-line comment) -> FAIL
ctx research <<'EOF'
# Research
## Current Tasks
<!-- PM updates at sprint planning
     across multiple lines -->
## Product Context
EOF
t comment-only-fails 1 "FAIL:" research

# section missing entirely -> FAIL with the precise message
ctx marketing <<'EOF'
# Marketing
## Product Context
Stuff.
EOF
t section-missing 1 "FAIL: knowledge-base/agent-context/marketing.md has no '## Current Tasks'" marketing

# file missing -> FAIL
rm -f "$PROJ/knowledge-base/agent-context/ui-ux.md"
t file-missing 1 "FAIL: knowledge-base/agent-context/ui-ux.md missing" ui-ux

# pm exemption: file exists, empty Current Tasks -> OK
ctx pm <<'EOF'
# PM
## Current Tasks
<!-- rare — PM coordinates rather than executes -->
## Product Context
EOF
t pm-exempt 0 "OK: pm context file exists" pm

# no-arg mode: gate the queue's Next Step role
printf '## Next Step\n```\nRole: qa\nDo.\n```\n## Upcoming\n' > "$PROJ/knowledge-base/orchestration-queue.md"
t queue-mode-gates-role 0 "OK: qa context populated"
printf '## Next Step\n```\nRole: content\nDo.\n```\n## Upcoming\n' > "$PROJ/knowledge-base/orchestration-queue.md"
t queue-mode-catches-fail 1 "FAIL: knowledge-base/agent-context/content.md"
printf '## Next Step\n_(sprint complete)_\n## Upcoming\n' > "$PROJ/knowledge-base/orchestration-queue.md"
t queue-complete-ok 0 "OK: queue has no bindable Next Step"
printf '## Next Step\n```\nRole: halt\nGate.\n```\n## Upcoming\n' > "$PROJ/knowledge-base/orchestration-queue.md"
t founder-gate-ok 0 "OK: Next Step is a founder gate"

# bad role arg -> usage
t bad-role-usage 3 "muster-lint-context: unknown role" banana

# cwd-independence
mkdir -p "$PROJ/src/deep"
T_CWD="$PROJ/src/deep" t cwd-independent 0 "OK: qa context populated" qa

echo "----"
if [ "$fails" -eq 0 ]; then echo "RESULT: $n/$n passed"; exit 0
else echo "RESULT: $((n-fails))/$n passed — $fails FAILED"; exit 1; fi
