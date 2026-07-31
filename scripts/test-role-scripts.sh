#!/usr/bin/env bash
# test-role-scripts.sh — fixture gate for the Wave 2 role-floor scripts:
# muster-check-context.sh (startup gate), muster-list-open-items.sh --for (comms check),
# muster-advance-queue.sh (session-completion queue advance). Sandboxed; brutal on the
# advance mutation: fence-embedded fake headings, cap overflow, refusal paths, self-check.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/muster-role-test.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT

PROJ="$SBX/proj"
mkdir -p "$PROJ/muster/scripts" "$PROJ/knowledge-base/agent-context" "$PROJ/knowledge-base/.muster-onboarding"
for s in muster-check-context.sh muster-read-populated.sh muster-advance-queue.sh \
         muster-read-queue.sh muster-queue-lint.sh muster-list-open-items.sh; do
  cp "$SRC/scripts/$s" "$PROJ/muster/scripts/"
done
touch "$PROJ/muster/system-guide.md"

n=0; fails=0
ok(){ n=$((n+1)); echo "PASS: $1"; }
ko(){ n=$((n+1)); fails=$((fails+1)); echo "FAIL: $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/  got: /'; }
assert_eq(){ [ "$2" = "$3" ] && ok "$1" || ko "$1" "want [$3] got [$2]"; }
assert_has(){ printf '%s\n' "$3" | grep -qF -- "$2" && ok "$1" || ko "$1" "$3"; }
assert_not(){ printf '%s\n' "$3" | grep -qF -- "$2" && ko "$1" "$3" || ok "$1"; }

pop(){ # $1 = developer value, $2 = pm value
  cat > "$PROJ/knowledge-base/agent-context/.populated" <<EOF
{
  "version": "2",
  "onboarded_at": "2026-07-01",
  "onboarding_complete_at": "2026-07-02",
  "agents": {
    "developer": $1,
    "ui-ux": "2026-01-01",
    "content": "2026-01-01",
    "qa": null,
    "research": "2026-01-01",
    "marketing": "2026-01-01",
    "legal": "2026-01-01",
    "pm": $2
  },
  "lock": null
}
EOF
}

# ============ muster-check-context.sh ============
CC="muster/scripts/muster-check-context.sh"
pop '"2026-01-01"' '"2026-01-01"'
out="$(cd "$PROJ" && bash $CC developer)"; assert_eq "cc-populated-ok" "$out" "OK"
out="$(cd "$PROJ" && bash $CC qa; echo "rc=$?")"
assert_has "cc-specialist-halt" "HALT: agent-context null. PM: run JIT populate per context-cascading.md, then re-invoke." "$out"
assert_has "cc-specialist-halt-rc" "rc=1" "$out"
pop 'null' 'null'
out="$(cd "$PROJ" && bash $CC pm || true)"
assert_has "cc-pm-halt-variant" "HALT: PM not initialized. Run scripts/setup-project.sh or scripts/setup-existing-project.sh." "$out"
touch "$PROJ/knowledge-base/.muster-onboarding/audit-brief.md"
out="$(cd "$PROJ" && bash $CC developer)"; assert_eq "cc-developer-bootstrap" "$out" "OK-BOOTSTRAP"
out="$(cd "$PROJ" && bash $CC qa || true)"; assert_has "cc-bootstrap-not-qa" "HALT: agent-context null" "$out"
rm -f "$PROJ/knowledge-base/.muster-onboarding/audit-brief.md"
rm -f "$PROJ/knowledge-base/agent-context/.populated"
out="$(cd "$PROJ" && bash $CC developer || true)"; assert_has "cc-missing-file-halts" "HALT: agent-context null" "$out"
(cd "$PROJ" && bash $CC banana 2>/dev/null); assert_eq "cc-bad-role-usage" "$?" "3"
pop '"2026-01-01"' '"2026-01-01"'

# ============ muster-list-open-items.sh --for ============
LOI="muster/scripts/muster-list-open-items.sh"
OLD="$(date -v-9d +%F 2>/dev/null || date -d '9 days ago' +%F)"
cat > "$PROJ/knowledge-base/agent-requests.md" <<EOF
# Agent Requests & Handoffs

## Active Requests
### $OLD REQ-31 — Old open ask for developer
**Type:** request
**From:** QA
**To:** Developer
**Status:** open

### 2026-07-30 REQ-32 — Ask for PM
**Type:** request
**From:** Developer
**To:** PM
**Status:** open

### 2026-07-30 REQ-33 — Already answered
**Type:** request
**From:** QA
**To:** Developer
**Status:** done

## Active Handoffs
### 2026-07-30 HO-41 — Spec for review
**Type:** handoff
**Producer:** UI/UX
**Status:** in-review
**Reviewers:**
- [ ] Developer — pending
- [x] QA — done (2026-07-30: "Fine.")

### 2026-07-29 HO-42 — Dev build sent back
**Type:** handoff
**Producer:** Developer
**Status:** needs-revision
**Reviewers:**
- [ ] QA — needs-revision (2026-07-30: "Broken.")

### 2026-07-30 HO-43 — For UI/UX eyes
**Type:** handoff
**Producer:** Content
**Status:** in-review
**Reviewers:**
- [ ] UI/UX — pending

## Resolved (Last 10)
EOF
out="$(cd "$PROJ" && bash $LOI --for developer)"
assert_has "loi-to-me-open"        "REQ-31" "$out"
assert_has "loi-stale-tag"         "STALE(>5d)" "$out"
assert_not "loi-not-others-req"    "REQ-32" "$out"
assert_not "loi-not-done-req"      "REQ-33" "$out"
assert_has "loi-review-pending"    "HO-41" "$out"
assert_has "loi-my-needs-revision" "HO-42" "$out"
assert_not "loi-not-others-review" "HO-43" "$out"
out="$(cd "$PROJ" && bash $LOI --for ui-ux)"
assert_has "loi-tolerant-uiux"     "HO-43" "$out"
assert_not "loi-uiux-not-dev"      "HO-41" "$out"
out="$(cd "$PROJ" && bash $LOI --for qa)"
assert_not "loi-ticked-not-pending" "HO-41" "$out"
out="$(cd "$PROJ" && bash $LOI)"
assert_has "loi-legacy-mode-intact" "Open items at sprint boundary" "$out"

# ============ muster-advance-queue.sh ============
AQ="muster/scripts/muster-advance-queue.sh"
QF="$PROJ/knowledge-base/orchestration-queue.md"
TODAY="$(date +%F)"
seed_queue(){ cat > "$QF" <<'EOF'
# Orchestration Queue

## Founder Decisions
<!-- Agents add questions requiring founder input here. -->

## Next Step
<!-- The single next agent invocation. -->

### Step 4 — Developer: build the widget
```
Role: developer
Build it.
## Fake heading inside fence
### Step 99 — decoy
```

## Upcoming

### Step 5 — QA: verify the widget
```
Role: qa
Verify it.
```

### Step 6 — PM: closeout
```
Role: pm
Close out.
```

## Done (Last 10)
<!-- Completed steps, newest at the top. -->
- 2026-07-28 Developer: prior thing (HO-40)
- 2026-07-27 PM: planning
EOF
}

# happy path: advance developer step, promote QA step
seed_queue
out="$(cd "$PROJ" && bash $AQ developer "widget built (HO-44)")"
assert_has "aq-ok"            "OK: step moved to Done" "$out"
assert_has "aq-promoted-label" "Step 5 — QA: verify the widget" "$out"
q="$(cat "$QF")"
assert_has "aq-done-entry"     "- $TODAY Developer: widget built (HO-44)" "$q"
assert_not "aq-old-step-gone"  "Build it." "$q"
top_done="$(awk '/^## Done/{f=1;next} f&&/^- /{print;exit}' "$QF")"
assert_eq  "aq-done-newest-first" "$top_done" "- $TODAY Developer: widget built (HO-44)"
role_now="$(cd "$PROJ" && bash muster/scripts/muster-read-queue.sh role)"
assert_eq  "aq-next-role-now-qa" "$role_now" "qa"
assert_has "aq-upcoming-keeps-rest" "Step 6 — PM: closeout" "$q"
assert_has "aq-ns-comment-kept" "The single next agent invocation" "$q"
(cd "$PROJ" && bash muster/scripts/muster-queue-lint.sh >/dev/null 2>&1); assert_eq "aq-lint-green-after" "$?" "0"

# refusal: wrong role — queue must be byte-identical after
cp "$QF" "$SBX/before"
out="$(cd "$PROJ" && bash $AQ developer "not my step" || true)"
assert_has "aq-refuse-wrong-role" "REFUSED: Next Step is Role: qa" "$out"
cmp -s "$QF" "$SBX/before" && ok "aq-refused-untouched" || ko "aq-refused-untouched"

# last step -> sprint complete; driver sees completion
out="$(cd "$PROJ" && bash $AQ qa "verified (HO-45)")"
out="$(cd "$PROJ" && bash $AQ pm "sprint closed")"
assert_has "aq-complete-msg" "sprint complete" "$out"
role_now="$(cd "$PROJ" && bash muster/scripts/muster-read-queue.sh role)"
assert_eq "aq-driver-sees-complete" "$role_now" ""
(cd "$PROJ" && bash muster/scripts/muster-queue-lint.sh >/dev/null 2>&1); assert_eq "aq-lint-green-idle" "$?" "0"

# empty Next Step -> refuse
out="$(cd "$PROJ" && bash $AQ pm "again" || true)"
assert_has "aq-refuse-empty" "REFUSED: Next Step has no fenced step" "$out"

# Role: halt -> refuse
seed_queue
printf '## Next Step\n```\nRole: halt\nGate.\n```\n## Upcoming\n\n## Done (Last 10)\n' > "$QF"
out="$(cd "$PROJ" && bash $AQ pm "x" || true)"
assert_has "aq-refuse-halt-gate" "founder gate" "$out"

# done cap: 10 bullets stay 10, oldest dropped
seed_queue
{ awk '/^## Done/{print; for(i=1;i<=10;i++) printf "- 2026-07-%02d Developer: old entry %d (HO-%d)\n", i+10, i, i; next} {print}' "$QF" > "$SBX/q2" && mv "$SBX/q2" "$QF"; }
out="$(cd "$PROJ" && bash $AQ developer "newest (HO-50)")"
cnt="$(awk '/^## Done/{f=1;next} f&&/^## /{f=0} f&&/^- /{c++} END{print c+0}' "$QF")"
assert_eq  "aq-done-cap-10" "$cnt" "10"
assert_has "aq-cap-keeps-newest" "newest (HO-50)" "$(cat "$QF")"
assert_not "aq-cap-drops-oldest" "old entry 10" "$(cat "$QF")"

# summary with quotes and backslashes survives literally
seed_queue
out="$(cd "$PROJ" && bash $AQ developer 'fix \n "quoted" & done (HO-51)')"
assert_has "aq-summary-literal" 'fix \n "quoted" & done (HO-51)' "$(cat "$QF")"

# WARN on specialist summary without HO ref; PM exempt
seed_queue
out="$(cd "$PROJ" && bash $AQ developer "no ref here")"
assert_has "aq-warn-no-ho" "WARN: summary has no HO-NNN" "$out"
seed_queue
printf '## Next Step\n\n### Step 1 — PM: plan\n```\nRole: pm\nPlan.\n```\n\n## Upcoming\n\n## Done (Last 10)\n' > "$QF"
out="$(cd "$PROJ" && bash $AQ pm "planned the sprint")"
assert_not "aq-pm-no-warn" "WARN:" "$out"

# PM preamble notes / separators in Next Step survive the advance (only the step is excised)
seed_queue
awk '/^## Next Step/{print; print "> **Gate note from the founder — keep me.**"; print ""; print "---"; next} {print}' "$QF" > "$SBX/q3" && mv "$SBX/q3" "$QF"
out="$(cd "$PROJ" && bash $AQ developer "built (HO-60)")"
q="$(cat "$QF")"
assert_has "aq-preamble-note-kept" "Gate note from the founder — keep me." "$q"
assert_has "aq-preamble-hr-kept" "---" "$q"
assert_not "aq-preamble-step-gone" "Build it." "$q"
(cd "$PROJ" && bash muster/scripts/muster-queue-lint.sh >/dev/null 2>&1); assert_eq "aq-preamble-lint-green" "$?" "0"

# cwd-independence + usage
seed_queue
mkdir -p "$PROJ/src/deep"
out="$(cd "$PROJ/src/deep" && bash ../../$AQ developer "from deep (HO-52)")"
assert_has "aq-cwd-independent" "OK: step moved to Done" "$out"
(cd "$PROJ" && bash $AQ 2>/dev/null); assert_eq "aq-usage-exit" "$?" "3"

echo "----"
if [ "$fails" -eq 0 ]; then echo "RESULT: $n/$n passed"; exit 0
else echo "RESULT: $((n-fails))/$n passed — $fails FAILED"; exit 1; fi
