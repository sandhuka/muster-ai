#!/usr/bin/env bash
# muster-sprint-run.sh — drive the orchestration queue to completion autonomously.
# RUN INSIDE A GIT WORKTREE. Never on your main checkout with --dangerously-skip-permissions.
# Reuses MUSTER_ROLE=auto: each step binds the role named in the queue's Next Step, executes,
# files its handoff, and advances the queue itself. The loop only reads + honors stop signals.
set -uo pipefail

# --- Tier-1 deterministic guard: refuse to run on the primary checkout. ---
# Sourced from a shared file so the resume wrapper enforces the identical guard (no drift).
# Fail CLOSED: a missing/unreadable guard file must refuse to run, not bypass the guard.
source "$(dirname "$0")/muster-guard-worktree.sh" || { echo "⛔ worktree guard missing — refusing to run."; exit 1; }

# Project knobs: ./.muster/config (plain KNOB=value lines, committed so worktrees inherit it)
# supplies project defaults for the driver's env knobs. Precedence: explicit env at invocation >
# config > built-in default — invocation env is captured before the source and re-applied after,
# so a config line can never override what the user typed on the command line.
if [ -f ./.muster/config ]; then
  _inv_env="$(declare -p MAX_STEPS MAX_TURNS ANTHROPIC_MODEL KEEP_RUNS LIMIT_RESUME_AT CTX_WARN_PCT MUSTER_COLOR 2>/dev/null)"
  . ./.muster/config
  eval "$_inv_env"
  export ANTHROPIC_MODEL 2>/dev/null || true   # claude reads it from env; config-set needs the export
fi

QUEUE="knowledge-base/orchestration-queue.md"
MAX_STEPS="${MAX_STEPS:-30}"          # hard cap — cost circuit-breaker
MAX_TURNS="${MAX_TURNS:-150}"         # per-step model-turn budget — raise for heavy steps
LIMIT_BUFFER="${LIMIT_BUFFER:-300}"   # seconds past a stated usage-limit reset before resuming
CTX_WARN_PCT="${CTX_WARN_PCT:-80}"    # peak-ctx % above which a step is flagged as running hot (0 = off)

# Glance-color: ON by default in a terminal (the founder watches the live trail). Opt out with
# MUSTER_COLOR=0 or the NO_COLOR convention; force on with MUSTER_COLOR=1. When output is NOT a
# TTY and MUSTER_COLOR is unset, color stays off so redirected / piped .log files don't get ANSI.
# Role is shown in its agent color; the driver's own key tokens are bolded.
if   [ "${MUSTER_COLOR:-}" = 0 ] || [ -n "${NO_COLOR:-}" ]; then C_ON=0
elif [ "${MUSTER_COLOR:-}" = 1 ];                            then C_ON=1
elif [ -t 1 ];                                              then C_ON=1
else                                                              C_ON=0
fi
role_ansi(){ case "$1" in   # per-agent console color (mirrors muster's agent palette)
    pm) printf '35';; developer) printf '34';; ui-ux) printf '36';; qa) printf '32';;
    content) printf '33';; marketing) printf '95';; legal) printf '31';; research) printf '94';;
    halt) printf '91';; *) printf '37';; esac; }
paint(){ # $1 = ansi code(s) e.g. "34;1"   $2 = text   — passthrough when color is off
  if [ "$C_ON" = 1 ]; then printf '\033[%sm%s\033[0m' "$1" "$2"; else printf '%s' "$2"; fi; }
[ -f "$QUEUE" ] || { echo "No queue at $QUEUE — run from a project root."; exit 1; }

# Fail fast on an unpopulated/partial muster checkout. `git worktree add` does not check out
# submodules, so a worktree's muster/ can be empty (the sandbox helper inits it; this guards the
# manual-worktree and partial-checkout paths). Resolved relative to THIS script so it never
# false-fails when muster IS the repo — the framework's own tree has system-guide.md at its root.
[ -f "$(dirname "$0")/../system-guide.md" ] || {
  echo "⛔ muster/ appears unpopulated in this worktree."
  echo "   Run: git submodule update --init --recursive"
  exit 1
}

# Sleep-proof (idle only): hold off macOS *idle* sleep while the driver lives (-w $$ ties the
# assertion to this PID, auto-releasing on exit). -i covers the idle timeout ONLY — it does NOT
# prevent lid-close (clamshell) or low-battery sleep, so long unattended runs want lid-open + AC.
# A sleep that does land is non-fatal: the interrupted step is resumable (re-run on wake — the
# mid-step continuation picks up the partial work). The command -v guard makes non-mac a no-op
# (Linux analog for a future port: systemd-inhibit).
command -v caffeinate >/dev/null && caffeinate -i -w $$ &

# Path to the handoff-integrity lint (sits next to this driver).
LINT="$(dirname "$0")/muster-lint-handoff.sh"

# Observability: each step streams its work (stream-json) through a formatter that prints a
# human-readable trail AND tees a full-fidelity raw log for debugging. Presentation only — the
# loop's stop conditions still key off claude's exit code (PIPESTATUS[0]), never the formatter.
FMT="$(dirname "$0")/muster-sprint-format.sh"
LOGDIR=".muster-sprint-logs"
mkdir -p "$LOGDIR" 2>/dev/null || true
# Prune old run logs — keep the most recent KEEP_RUNS runs (each run = a .log + .jsonl pair).
# The driver owns these logs, so it prunes them here (session-start housekeeping never fires in
# the worktree/bash context the loop runs in). Count-based: debugging artifacts, kept across runs.
KEEP_RUNS="${KEEP_RUNS:-20}"
ls -1t "$LOGDIR"/run-*.log 2>/dev/null | tail -n +"$((KEEP_RUNS+1))" | while IFS= read -r old; do
  rm -f "$old" "${old%.log}.jsonl" "${old%.log}.metrics"
done
RUN_TS="$(date +%Y%m%d-%H%M%S)-$$"   # PID suffix: two runs in the same second must not share logs
HUMANLOG="$LOGDIR/run-$RUN_TS.log"     # readable trail (scannable)
RAWLOG="$LOGDIR/run-$RUN_TS.jsonl"     # full-fidelity stream-json (deep debug)
METRICS="$LOGDIR/run-$RUN_TS.metrics"  # formatter-written, one line per step — summary table source

# Trail layout: heavy rules (═) mark only the places a human decision lives — run start, a halt,
# run end. Per-step lines carry the QUEUE's own step heading; the iteration counter is plumbing
# (the MAX_STEPS circuit-breaker) and surfaces only at run start, near the cap, and when it fires.
RULE_H="═══════════════════════════════════════════════════════════"
RULE_L="───────────────────────────────────────────────────────────"
{ echo "📓 sprint trail · run-$RUN_TS  (run budget: $MAX_STEPS steps)"
  echo "   log: $HUMANLOG · raw: $RAWLOG"
  echo "$RULE_H"
  echo
} | tee -a "$HUMANLOG"

# next_block/next_role live in the shared parser (muster-boot.sh executes the same file), so the
# driver and the session bootstrap can never disagree on what the queue's Next Step says.
# Fail CLOSED like the worktree guard: a missing parser refuses to run.
source "$(dirname "$0")/muster-read-queue.sh" || { echo "⛔ queue parser missing — refusing to run."; exit 1; }

# Count the STEPS in the Next Step section = the number of fenced blocks (each step wraps its prompt
# in one ``` fence). Count fence OPENINGS via a toggle, NOT '###' headings: a step's prompt BODY may
# legitimately contain '### ' lines (e.g. a content step describing section structure), which would
# fool a heading count, but it cannot contain a ``` line (that would break the wrapping fence — so
# nested fences are unsupported by the queue convention). Same section bounding as next_block.
next_step_count(){
  awk '
    /^## Next Step/ {f=1; next}
    f && (/^## / || /^#+[[:space:]]+Upcoming[[:space:]]*$/) {f=0}
    !f {next}
    /^```/ { infence = !infence; if (infence) n++; next }   # count each fence opening = one step
    END {print n+0}
  ' "$QUEUE"
}

# Human label for a step: the first markdown heading line inside the Next Step block
# (e.g. '### Step 16 — Content: browser copy' -> 'Step 16 — Content: browser copy').
# Echoed text for the trail and commit messages ONLY — never parsed for control: step numbering
# is a PM authoring convention, not a contract (32.5 / 9-fix-2 / unnumbered fixes are legitimate).
next_label(){
  printf '%s\n' "$1" | sed -n 's/^#\{1,4\}[[:space:]]\{1,\}//p' | head -1
}

# Optional per-step model override: a 'Model: <id>' line inside the fenced block, same parsing
# pattern as 'Role:'. Absent -> empty -> no --model flag -> the session default applies. An
# invalid id makes claude exit non-zero -> stop condition 4 catches it; no validation here, and
# the value is only ever echoed into the flag — never branched on.
next_model(){
  printf '%s' "$1" | grep -m1 -i '^Model:' | sed 's/^[Mm]odel:[[:space:]]*//'
}

# Founder channels — terminal output of an autonomous step is never read by the founder, so
# "tell the founder X" executed in chat is a swallowed notification. The durable channel is
# knowledge-base/founder-notices.md (agents append dated one-line FYIs); the driver diffs it
# after each step and echoes new entries loudly. It also alerts when '## Founder Decisions'
# changes mid-run (escalated observations park there while the loop keeps running). Read-only
# diffs — the driver never writes either channel. Missing notices file = no notices (older
# projects); agents create it on first append.
NOTICES="knowledge-base/founder-notices.md"
fd_section(){ awk '/^## Founder Decisions/{f=1;next} f&&/^## /{f=0} f' "$QUEUE" 2>/dev/null | cksum; }
notices_seen="$(wc -l < "$NOTICES" 2>/dev/null | tr -d ' ')"; notices_seen="${notices_seen:-0}"
fd_snap="$(fd_section)"
notices_run=0
report_founder_channels(){
  local now fd
  now="$(wc -l < "$NOTICES" 2>/dev/null | tr -d ' ')"; now="${now:-0}"
  if [ "$now" -gt "$notices_seen" ]; then
    { echo "  📣 FOUNDER NOTICE:"
      sed -n "$((notices_seen+1)),${now}p" "$NOTICES" | sed 's/^/     /'
    } | tee -a "$HUMANLOG"
    notices_run=$((notices_run + now - notices_seen))
    notices_seen="$now"
  fi
  fd="$(fd_section)"
  if [ "$fd" != "$fd_snap" ]; then
    echo "  📌 '## Founder Decisions' changed this step — review $QUEUE" | tee -a "$HUMANLOG"
    fd_snap="$fd"
  fi
  return 0
}

# ---- limit-aware auto-resume (refines stop condition 4) ----
# A usage-limit death is mechanical and bridgeable: classify the run's FINAL result event
# against the captured real payload shape ("api_error_status":429 + a limit-text result),
# parse the stated reset time, sleep past it (+LIMIT_BUFFER), re-enter the loop. FAIL-CLOSED:
# anything uncertain (no 429, no limit text, unparseable time with no LIMIT_RESUME_AT override)
# returns 1 and the normal hard-halt path runs unchanged. 'Role: halt' gates are untouched —
# auto-resume bridges this one mechanical error class, never founder checkpoints. Proactive
# pre-step gating was stress-tested and REJECTED (no reliable usage signal; economics illusory)
# — do not add it; see limit-aware-driver IDEA / CHANGELOG.
hm_to_epoch(){ # "HH:MM" (24h, today, local) -> epoch; BSD date first, then GNU
  date -j -f "%Y-%m-%d %H:%M" "$(date +%Y-%m-%d) $1" +%s 2>/dev/null \
    || date -d "$(date +%Y-%m-%d) $1" +%s 2>/dev/null
}
epoch_hm(){ date -r "$1" +%H:%M 2>/dev/null || date -d "@$1" +%H:%M 2>/dev/null; }
limit_resume_epoch(){
  local line t h m ap now target
  line="$(grep -a '"type":"result"' "$RAWLOG" 2>/dev/null | tail -1)"
  printf '%s' "$line" | grep -q '"api_error_status":429' || return 1
  printf '%s' "$line" | grep -qi 'limit' || return 1
  now="$(date +%s)"
  # reset time as stated in the payload, e.g. "resets 4:50pm" (assumed machine-local tz)
  t="$(printf '%s' "$line" | sed -n 's/.*resets \([0-9]\{1,2\}\):\([0-9]\{2\}\)\([ap]m\).*/\1 \2 \3/p')"
  if [ -n "$t" ]; then
    read -r h m ap <<< "$t"; h=$((10#$h)); m=$((10#$m))
    [ "$ap" = "pm" ] && [ "$h" -ne 12 ] && h=$((h+12))
    [ "$ap" = "am" ] && [ "$h" -eq 12 ] && h=0
    target="$(hm_to_epoch "$(printf '%02d:%02d' "$h" "$m")")" || return 1
  elif [ -n "${LIMIT_RESUME_AT:-}" ]; then
    target="$(hm_to_epoch "$LIMIT_RESUME_AT")" || return 1
  else
    return 1
  fi
  [ -n "$target" ] || return 1
  # a reset stamped within the last ~2 min means the window just reset (resume now);
  # anything older today means the stated time is tomorrow's
  [ "$target" -lt $((now - 120)) ] && target=$((target + 86400))
  echo $((target + LIMIT_BUFFER))
}

# Run-status surface: ONE tiny overwrite-in-place file any tab reads to answer "where is the
# run?" — including the MID-step state that the trail and metrics (completed work only) cannot
# show. First rung of the Guide's cheap-read ladder (guide/skills/operating-help.md). Lives in
# $LOGDIR — gitignored and excluded from the commit floor, so it never pollutes step commits.
status_write(){ # $1 = state ("running step N" / "sleeping …" / "complete" / "halted: <reason>")
  { echo "run: run-$RUN_TS"
    echo "state: $1"
    echo "step: ${label:-—}"
    echo "step started: ${step_started:-—}"
    echo "last completed: ${last_done:-—}"
    echo "totals: $(awk -F'|' '{t+=$1; c+=$2} END {printf "%d attempt(s) · %d turns · $%.2f", NR, t, c}' "$METRICS" 2>/dev/null)"
  } > "$LOGDIR/STATUS" 2>/dev/null || true
}

# Wall-clock formatter: seconds -> compact "Hh Mm" / "Mm Ss" / "Ss". Non-numeric -> "—".
fmt_dur(){
  local s="${1:-0}" h m sec
  case "$s" in (*[!0-9]*|"") echo "—"; return;; esac
  h=$((s/3600)); m=$(((s%3600)/60)); sec=$((s%60))
  if   [ "$h" -gt 0 ]; then printf '%dh %dm' "$h" "$m"
  elif [ "$m" -gt 0 ]; then printf '%dm %ds' "$m" "$sec"
  else printf '%ds' "$sec"; fi
}

# Step-progress fragment (deterministic, end of each step): independently verify from the QUEUE +
# agent-requests.md what the agent ACTUALLY did — not its self-report. Both facts are the same
# checks the loop already enforces, surfaced HERE attached to the step that produced them so the
# founder sees protocol-followed (the sprint moved + the handoff is real), not just tokens-spent.
# (1) advancement: did '## Next Step' change from the block that just ran? — same comparison cond-3
# makes next loop. (2) handoff: the new Done entry's HO refs verified FILED via the handoff lint
# (single source of truth — no second parser). A step that files no handoff (PM/coordination) shows
# advancement only — no false warning. ECHOES a one-line fragment (no icon/indent) for the end-block
# to compose with role + time. $1 = $blk (the block that just ran).
step_progress_fragment(){
  local ran_blk="$1" new_blk next_lbl next_rl done_entry refs frag
  new_blk="$(next_block)"
  if [ "$new_blk" = "$ran_blk" ]; then
    printf '⚠ queue NOT advanced — Next Step unchanged (next loop stops)'; return 0
  fi
  next_lbl="$(next_label "$new_blk")"; next_rl="$(next_role)"
  if [ -n "$next_lbl" ]; then
    frag="advanced → $next_lbl"
    [ -n "$next_rl" ] && [ "$next_rl" != halt ] && \
      frag="$frag ($(printf '%s' "$next_rl" | tr '[:lower:]' '[:upper:]'))"
  else
    frag="advanced → queue clear (sprint may be complete)"
  fi
  # HO refs in the most-recent Done entry (what this step just wrote) — same parse the lint uses.
  done_entry="$(awk '/^## Done/{d=1;next} d&&/^## /{exit} d&&/^[[:space:]]*-/{print;exit}' "$QUEUE")"
  refs="$(printf '%s' "$done_entry" | grep -oiE 'HO-[0-9]+' | tr '[:lower:]' '[:upper:]' | sort -u | tr '\n' ' ')"
  refs="${refs% }"
  if [ -n "$refs" ]; then
    if bash "$LINT" "$QUEUE" "knowledge-base/agent-requests.md" >/dev/null 2>&1; then
      frag="$frag · handoff $refs filed ✓"
    else
      frag="$frag · ⚠ handoff $refs NOT filed (next loop stops)"
    fi
  fi
  printf '%s' "$frag"
}

step=0; prev=""; last_done=""; step_started=""
reason="interrupted"; reason_note=""; executed=0; ROWS=""; run_secs=0
status_write "starting"
while :; do
  step=$((step+1))
  if [ "$step" -gt "$MAX_STEPS" ]; then
    nl="$(next_label "$(next_block)")"
    { echo "⛔ Run cap reached (MAX_STEPS=$MAX_STEPS) — cost circuit-breaker, not an error."
      echo "   Sprint position is saved in the queue (next: ${nl:-see $QUEUE})."
      echo "   Re-run muster-sprint-run.sh to continue with a fresh $MAX_STEPS-step budget."
    } | tee -a "$HUMANLOG"
    reason="run cap"; break
  fi

  # Handoff-integrity lint (§7.8): the most-recent Done entry's HO refs must be filed.
  # Top-of-loop so it also gates resume — a missing HO must exist before proceeding.
  if ! bash "$LINT" "$QUEUE" "knowledge-base/agent-requests.md"; then
    echo "⛔ Handoff missing for most-recent Done entry — stopping for founder" | tee -a "$HUMANLOG" # cond: HO-existence
    reason="handoff lint"; break
  fi

  # Context gate (WARN-ONLY ramp): a cold agent with a pointer-only context file improvises
  # scope. Non-fatal while the lint proves itself in the field; promote to a stop condition
  # once field-green (the ramp rule — never wire a new lint fail-stop against a live corpus).
  ctx_out="$(bash "$(dirname "$0")/muster-lint-context.sh" 2>&1)" || \
    echo "⚠ context gate: ${ctx_out}" | tee -a "$HUMANLOG"

  blk="$(next_block)"
  role="$(next_role)"
  label="$(next_label "$blk")"

  if [ -z "$role" ]; then                                                                          # cond 1
    echo "✅ Next Step empty — sprint complete" | tee -a "$HUMANLOG"
    reason="sprint complete"; break
  fi
  if [ "$role" = halt ]; then                                                                      # cond 2
    { echo "$RULE_H"
      echo "⛔ HALT — ${label:-founder checkpoint}   (Role: halt)"
      echo
      echo "   The loop stopped for founder input — nothing is wrong."
      echo "   • Wave gate: review knowledge-base/wave-review.md, write your verdict in its"
      echo "     ## Verdict section, then run: bash muster/scripts/muster-sprint-resume.sh"
      echo "     (from this worktree)."
      echo "   • PM escalation: see '## Founder Decisions' in $QUEUE, answer, then re-run"
      echo "     muster-sprint-run.sh."
      echo "$RULE_H"
    } | tee -a "$HUMANLOG"
    reason="halt"; reason_note="${label:-Role: halt}"
    ROWS="${ROWS}$(printf '  %-36.36s %5s' "${label:-Role: halt}" "halt")"$'\n'
    break
  fi
  # Queue-contract guard: '## Next Step' must hold exactly ONE step. PM gate-processing of a
  # changes-requested verdict can mis-place a re-review gate as a 2nd step here; the fix's closeout
  # could then promote the wrong step and drop the gate (skipped human re-review). Catch it
  # deterministically — a mechanical integrity check, symmetric with the handoff lint (not policy).
  steps="$(next_step_count)"
  [ "${steps:-0}" -gt 1 ] && {
    { echo "⛔ '## Next Step' holds $steps steps — the contract is one step per Next Step."         # cond: one-step-per-next-step
      echo "   Extra steps (e.g. a re-review gate) belong under '## Upcoming'. Stopping for founder."
    } | tee -a "$HUMANLOG"
    reason="queue guard"; break
  }
  [ "$blk" = "$prev" ] && {                                                                         # cond 3
    echo "⛔ Next Step unchanged — agent didn't advance / failure" | tee -a "$HUMANLOG"
    reason="step did not advance"; reason_note="$label"; break
  }
  prev="$blk"

  model="$(next_model "$blk")"
  role_up="$(printf '%s' "$role" | tr '[:lower:]' '[:upper:]')"
  # Split "Step 28a — Wave 5.5 fix: …" into id + description on the ' — ' em-dash, so the header
  # leads with AGENT and the task sits on its own line (the founder's two-line start glance).
  step_id="$label"; step_desc=""
  case "$label" in *" — "*) step_id="${label%% — *}"; step_desc="${label#* — }";; esac
  { printf '%s step %s\n' "$RULE_L" "$step"
    hdr="▶ $(paint "$(role_ansi "$role");1" "$role_up") · ${step_id:-step $step}"
    [ -n "$model" ] && hdr="$hdr  $(paint 2 "[$model]")"
    printf '%s\n' "$hdr"
    [ -n "$step_desc" ] && printf '  %s\n' "$step_desc"
  } | tee -a "$HUMANLOG"
  step_started="$(date '+%Y-%m-%d %H:%M:%S')"
  step_t0="$(date +%s)"   # epoch for wall-clock — paired with step_started above
  metrics_n0="$(wc -l < "$METRICS" 2>/dev/null || echo 0)"   # metrics-line count BEFORE this step
  head_before="$(git rev-parse HEAD 2>/dev/null || true)"    # for the Rule-16 commit-subject lint
  status_write "running step $step"

  # Mid-step continuation: the commit floor guarantees a clean tree at every successful step
  # boundary, so a dirty tree at step START deterministically means an interrupted prior attempt
  # (or a manual excursion that skipped closeout — identical treatment). Prepend a continuation
  # preamble to the WRAPPER prompt (the queue file is never edited) so the fresh agent
  # inventories and continues instead of restarting. Deliberate discard stays a manual founder
  # call (git checkout .) — destructive choices are never automated.
  preamble=""
  dirty_start="$(git status --porcelain --ignore-submodules=dirty -- . ":(exclude)$LOGDIR" 2>/dev/null \
                 || git status --porcelain --ignore-submodules=dirty)"
  if [ -n "$dirty_start" ]; then
    preamble="The working tree contains uncommitted changes — almost certainly partial work \
from an interrupted previous attempt at this step. Do NOT start over. First inventory it \
(git status, git diff --stat), reconcile against the step's task, and continue from that state. \
If the changes are clearly unrelated to this step, stop and route to PM. "
    echo "  ↻ dirty tree — continuation preamble added" | tee -a "$HUMANLOG"
  fi

  # Stream the step's work through the formatter (live trail + logs). PIPESTATUS[0] is claude's
  # own exit code — the formatter/tee cannot change it, so cond-4 stays accurate (verified).
  MUSTER_ROLE=auto claude -p --dangerously-skip-permissions --max-turns "$MAX_TURNS" \
        ${model:+--model} ${model:+"$model"} \
        --output-format stream-json --verbose \
        "${preamble}Execute the current Next Step in $QUEUE end-to-end: do the work, file your handoff, \
run the Pre-Handoff Self-Review (muster/system-guide.md), and advance the queue with \
'bash muster/scripts/muster-advance-queue.sh <your-role> \"<one-line summary (HO-ref)>\"' — never \
hand-edit Next Step/Done. Commit subjects: '<role>: <outcome>' \
(lowercase role, ≤60-char outcome-first line — what got better, not mechanics; why goes in the body). PM is the sole party that calls the \
founder: if you are a specialist and hit a blocker you cannot resolve (a decision you lack \
authority for, a missing input, a bug you cannot crack, a red build), do NOT set Role: halt and \
do NOT write to '## Founder Decisions' — instead file the blocker as a PM-addressed request and \
re-point Next Step to a 'Role: pm' assessment step (see decision-making.md → Autonomous-mode \
boundary). Only PM sets Role: halt. The founder does NOT read this session's output: anything \
the founder must SEE goes in a file — append a dated one-line FYI to \
knowledge-base/founder-notices.md (parallel-track kickoffs, heads-ups, deadlines); never \
'surface' or 'tell' anything in chat. If this step's acceptance depends on a build or test, run \
it FOREGROUND and BLOCKING in one Bash call with a large explicit timeout — never run_in_background \
then end your turn to await it (this headless session has no inter-turn channel: it exits and the \
result, handoff, and queue-advance are all lost). Run the test early; reserve turn budget to await \
it, file the handoff, and advance the queue. Do NOT guess and do NOT expand sprint scope (no new queue \
steps)." | bash "$FMT" "$RAWLOG" "$METRICS" | tee -a "$HUMANLOG"
  if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    if resume_at="$(limit_resume_epoch)"; then
      buf="+$((LIMIT_BUFFER/60))m buffer"; [ "$LIMIT_BUFFER" -lt 60 ] && buf="+${LIMIT_BUFFER}s buffer"
      echo "⏸ usage limit — sleeping until $(epoch_hm "$resume_at") ($buf)" | tee -a "$HUMANLOG"
      status_write "sleeping until $(epoch_hm "$resume_at") (usage limit)"
      s=$(( resume_at - $(date +%s) ))
      [ "$s" -gt 0 ] && sleep "$s"
      prev=""   # the same Next Step re-runs on purpose — don't trip cond 3 on re-entry
      continue
    fi
    { echo "⛔ claude exited non-zero on step $step — stopping for founder"                         # cond 4
      echo "   (if this was a heavy step, it may have hit MAX_TURNS=$MAX_TURNS — raise MAX_TURNS and"
      echo "    re-run to continue, or split the step at planning. Safe to resume: state was not advanced.)"
    } | tee -a "$HUMANLOG"
    reason="error (non-zero exit)"; reason_note="$label"; break
  fi

  report_founder_channels

  step_secs=$(( $(date +%s) - step_t0 )); [ "$step_secs" -lt 0 ] && step_secs=0
  run_secs=$(( run_secs + step_secs ))
  # Did THIS step produce a result? The formatter appends a metrics line ONLY at a result event, so
  # an UNCHANGED line count means the step was interrupted/aborted before completing (a manual
  # Ctrl-C, or a crash before the result). Guard against it: a blind `tail -1` would attribute the
  # PREVIOUS step's turns/cost/ctx to this one — a phantom row (the device-gate Ctrl-C symptom).
  # A real failed step (MAX_TURNS, error result, usage-limit attempt) DOES emit a result line, so
  # its real cost still counts. Only the no-result case shows dashes and is not tallied as executed.
  metrics_n1="$(wc -l < "$METRICS" 2>/dev/null || echo 0)"
  if [ "${metrics_n1:-0}" -gt "${metrics_n0:-0}" ]; then
    executed=$((executed+1)); step_ok=1
    IFS='|' read -r mt mc mp mo _ <<< "$(tail -1 "$METRICS" 2>/dev/null)"
    mc_disp="—"; [ "$mc" != "—" ] && mc_disp="\$$mc"
  else
    step_ok=0; mt="—"; mc="—"; mc_disp="—"; mp="—"; mo="—"
  fi
  ROWS="${ROWS}$(printf '  %-36.36s %5s %8s %5s %6s %7s' "${label:-step $step}" "$mt" "$mc_disp" "$mp" "$mo" "$(fmt_dur "$step_secs")")"$'\n'
  last_done="${label:-step $step} · ${mt} turns · ${mc_disp} · out ${mo} · $(fmt_dur "$step_secs")"
  status_write "between steps"
  # End-block glance: line 1 leads with the AGENT (its color) + this step's wall-clock + the
  # VERIFIED protocol outcome (advanced + handoff filed — not the agent's claim); line 2 is the
  # cumulative burn (time/$ map to tokens — the throughput signal). run_cost from METRICS so it
  # survives a degraded metrics line. An unmeasured (interrupted) step leads with ⚠, not ✓.
  run_cost="$(awk -F'|' '{c+=$2} END {printf "%.2f", c}' "$METRICS" 2>/dev/null)"
  prog="$(step_progress_fragment "$blk")"
  mark="✓"; [ "$step_ok" = 0 ] && mark="⚠"
  echo "  $mark $(paint "$(role_ansi "$role");1" "$role_up") · $(paint 1 "$(fmt_dur "$step_secs")") · $prog" | tee -a "$HUMANLOG"
  echo "    run so far: $(fmt_dur "$run_secs") · \$${run_cost:-?} · $executed steps" | tee -a "$HUMANLOG"
  # Ctx-outlier warning: flag a hot step LIVE (the ✓ line shows the % every step, but the founder
  # shouldn't have to eyeball each one — surface a ⚠ only past the threshold). A near-full window
  # risks truncation/degraded output and is the step-sizing signal: split it at planning next time.
  # mp is the metrics pct ("19%" / "—"); skip on degraded/non-numeric or when the knob is 0 (off).
  pct_num="${mp%\%}"
  case "$pct_num" in
    ''|*[!0-9]*) ;;   # degraded ("—") or empty — nothing to compare
    *) [ "$CTX_WARN_PCT" -gt 0 ] && [ "$pct_num" -ge "$CTX_WARN_PCT" ] && \
         echo "  ⚠ ctx ran hot: peak ${pct_num}% (≥ ${CTX_WARN_PCT}%) — consider splitting this step at planning" | tee -a "$HUMANLOG" ;;
  esac

  # Step-boundary commit floor: one commit per completed step, regardless of model or whether
  # the agent's closeout remembered to commit. Agents committing their own work stays the
  # convention (and the normal case — this is then a no-op on a clean tree); the floor exists so
  # a skipped closeout commit can't blur two steps' work into one diff. --ignore-submodules=dirty
  # keeps a content-dirty muster/ checkout (e.g. a hand-patched script) from firing this every
  # step — a moved submodule POINTER still commits. Logs dir excluded defensively (gitignored).
  #
  # When it fires, SHOW what was swept rather than accusing the agent of leaving work: the floor
  # catches several non-agent cases (the most common: a moved submodule pointer the agent committed
  # *inside* but didn't `git add` in the parent). The path list lets the founder tell a real missed
  # commit from a benign pointer bump at a glance — diagnostic signal, not a false alarm.
  dirty="$(git status --porcelain --ignore-submodules=dirty -- . ":(exclude)$LOGDIR" 2>/dev/null \
           || git status --porcelain --ignore-submodules=dirty)"
  if [ -n "$dirty" ]; then
    n_dirty="$(printf '%s\n' "$dirty" | grep -c .)"
    git add -A -- . ":(exclude)$LOGDIR" 2>/dev/null || git add -A
    lbl="${label:-step $step}"
    role_lc="$(printf '%s' "${role:-pm}" | tr '[:upper:]' '[:lower:]')"
    if git commit -q -m "${role_lc}: step-boundary sweep — ${lbl:0:40}"; then
      echo "  📦 step-boundary commit · swept $n_dirty path(s) the closeout didn't commit:" | tee -a "$HUMANLOG"
      printf '%s\n' "$dirty" | head -6 | sed 's/^/       /' | tee -a "$HUMANLOG"
      [ "$n_dirty" -gt 6 ] && echo "       … and $((n_dirty-6)) more" | tee -a "$HUMANLOG"
    else
      echo "  ⚠️ step-boundary commit failed — tree left as-is for diagnosis" | tee -a "$HUMANLOG"
    fi
  fi

  # Rule-16 commit-subject lint (warn-only — style never stops a run). Covers every commit the
  # step produced, incl. the sweep above. Skipped when the step made no commits.
  if [ -n "$head_before" ] && [ "$(git rev-parse HEAD 2>/dev/null)" != "$head_before" ]; then
    if ! lint_out="$(bash "$(dirname "$0")/muster-commit-lint.sh" "$head_before..HEAD" 2>&1)"; then
      echo "  ⚠ commit subject off-convention (Rule 16): $(printf '%s' "$lint_out" | head -2 | tr '\n' ' ')" | tee -a "$HUMANLOG"
    fi
  fi

  # Near-cap warning — the only mid-run appearance of the budget counter.
  if [ "$MAX_STEPS" -ge 5 ] && [ "$step" -eq $(( MAX_STEPS * 8 / 10 )) ]; then
    echo "⚠️  run budget: $step of $MAX_STEPS steps used this run" | tee -a "$HUMANLOG"
  fi
  echo "$RULE_L" | tee -a "$HUMANLOG"   # close the step's ruled section
done

# Final status: same stop reason the summary prints.
if [ "$reason" = "sprint complete" ]; then
  status_write "complete"
else
  status_write "halted: $reason${reason_note:+ ($reason_note)}"
fi

# Run summary — per-step rows (queue labels) + totals from the metrics file, and WHY the run
# stopped. This is where step-sizing judgment happens: scan the ctx% column for outliers.
{ echo "── run summary ────────────────────────────────────────────"
  [ -n "$ROWS" ] && printf '%s' "$ROWS"
  echo "$RULE_L"
  if [ -s "$METRICS" ]; then
    awk -F'|' '{t+=$1; c+=$2; o+=$5} END {
      ok = (o>=1000) ? sprintf("%dk", int(o/1000+0.5)) : o
      printf "  %d steps · %d turns · $%.2f · out %s", NR, t, c, ok }' "$METRICS"
  else
    printf '  %d steps' "$executed"
  fi
  [ "$run_secs" -gt 0 ] && printf ' · %s wall' "$(fmt_dur "$run_secs")"
  echo " · stopped: $reason${reason_note:+ ($reason_note)}"
  if [ "$notices_run" -gt 0 ]; then
    echo "  📣 $notices_run founder notice(s) this run — read $NOTICES"
  fi
} | tee -a "$HUMANLOG"
exit 0
