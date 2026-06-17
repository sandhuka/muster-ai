# Operating Help — Live Run Triage

The Guide's most-used skill: a run is going (or just stopped) and the user wants to know what's
happening and what to do. Two rules govern every answer here.

## Rule 1 — Files Are the Only Source of Truth

**Conversation memory is a stale cache.** The run advances in other processes and other tabs
while this conversation idles. Before answering ANY run-status question, re-read the thin
surface (Rule 2) — never answer from memory of an earlier turn, and never expect the user to
narrate state between tabs. An answer from memory isn't a fast answer; it's a wrong answer with
good latency.

## Rule 2 — The Cheap-Read Ladder

Stop at the first rung that answers. All paths relative to the **worktree** the run lives in:

1. **`.muster-sprint-logs/STATUS`** (~8 lines) — run id, state (running/complete/halted +
   reason), current step, last completed step's telemetry, totals. Covers the *mid-step* state
   nothing else shows. Most questions end here.
2. **Queue `## Next Step`** (~15 lines, `knowledge-base/orchestration-queue.md`) — what's next /
   where it stopped.
3. **Trail tail** — last ~20 lines of the newest `.muster-sprint-logs/run-*.log` + its
   `.metrics` — what just happened, what it cost.
4. **`knowledge-base/founder-notices.md`** — anything the agents flagged for the human.
5. **Raw `.jsonl`** — ONLY for deep debugging of a specific identified failure.

A typical status question costs under ~50 lines. Reading the raw jsonl or spelunking the
worktree to answer "where is the run?" is the anti-pattern this ladder exists to kill.

## Reading a Stop

The driver stops for exactly these reasons (details: `muster/system-guide.md` → Autonomous
Sprint Execution — read the section, don't recite this list from memory):

- **sprint complete** — Next Step has no fenced block. Done; **review the sprint branch and merge
  it deliberately**. The whole run lives in an isolated `git worktree` on its own branch — every
  step-boundary commit lands there, never on the user's main line — so nothing counts until they
  `git merge`, or they discard the branch wholesale (`git worktree remove`). That branch isolation
  IS the review-before-it-counts gate; the per-step commit floor is a within-sandbox checkpoint, not
  a write to their working branch. (A user who wants to gate per-step commits is usually missing
  that this is already sandboxed — point them here, not at a knob.)
- **halt (`Role: halt`)** — founder checkpoint. Wave gate → verdict in
  `knowledge-base/wave-review.md`, then `bash muster/scripts/muster-sprint-resume.sh` from the
  worktree. PM escalation → answer `## Founder Decisions` in the queue, re-run the driver.
- **step did not advance / queue guard / handoff lint** — integrity stops; the trail names the
  file to inspect.
- **error (non-zero exit)** — the driver auto-resumes usage-limit stalls itself (`⏸` trail
  line); anything else stopped for the founder. Re-run is safe: state didn't advance.
- **run cap (`MAX_STEPS`)** — budget, not failure. Re-run for a fresh budget, or raise the knob
  (`config-knobs.md`).

## Manual Recovery Moves

- **Re-run is free** — file state makes the driver continue from where it stopped; no resume
  flag. (Gate halts are the exception: use `muster-sprint-resume.sh` so PM processes the
  verdict.)
- **Delayed start** (machine should start a run later): from the loop tab, inside the worktree —
  `caffeinate -i bash -c 'sleep <secs> && bash muster/scripts/muster-sprint-run.sh'`.
- **Interrupted mid-step** (power, kill, crash): just re-run — the driver detects leftover
  uncommitted work and instructs the next agent to continue, not restart (`↻` trail line).
  Discarding partial work instead is the user's manual call (`git checkout .`), never yours.
- **Long / overnight runs**: keep the lid open and on AC. The idle-sleep guard (`caffeinate -i`)
  holds off *idle* timeout only — not lid-close or low-battery sleep. If the machine does sleep,
  nothing is lost: the step is resumable, just re-run on wake (same mid-step continuation).
- **Hand-holding a stuck step**: drive it in a warm role tab inside the worktree — but only
  while the loop is stopped, and PM closes out before the loop resumes (`system-guide.md` →
  Mixing modes).
