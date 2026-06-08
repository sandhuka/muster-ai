# Operating modes

Muster runs the same team three ways. They differ in how much you drive and how much the system drives itself — a spectrum from hands-on to hands-off. You pick per phase, and you can switch mid-sprint.

| Mode | What it is | Reach for it when |
|------|-----------|-------------------|
| **Manual** | One warm tab per role; you hop between them | You're thinking *with* one agent — planning, debugging, design iteration |
| **Assisted** | One PM tab that spawns each specialist as a subagent | You want PM to coordinate a short sequence while you watch |
| **Autonomous** | A script walks the queue unattended in a git worktree | You've planned a sprint and want to walk away |

They aren't rivals. Planning is always interactive; execution is where you choose. The rest of this doc is the detail behind that table.

---

## Manual — warm multi-tab

**What it is.** One long-lived tab per role: a PM tab, a Developer tab, a UI/UX tab. You open each, tell it to read the queue, and work. The status line shows `[muster: <role>]` so you always know which tab is which. `/rebind` swaps a tab's role without reopening.

**Pros**
- Each tab is *warm* — within a tab, follow-ups don't re-bootstrap. Deep iterative back-and-forth with one agent costs almost nothing per turn.
- Maximum manual control. You see and steer every step.
- The most token-efficient mode (you load a role's context once and keep using it).

**Cons**
- Heavy founder effort — you're the orchestrator, hopping between tabs and prompting each step.
- A tab's context grows over its life, so quality can drift on very long sessions. `/rebind` or a fresh tab resets it.
- Easy to lose track of "what's next" on a big sprint. Not unattended.

**Use when** the work is deep and hands-on with **one** agent — planning with PM, chasing a bug with Developer, iterating a design with UI/UX. This is the "I'm actively thinking *with* an agent" mode.

---

## Assisted — one PM tab, PM spawns subagents

**What it is.** A single tab bound to PM. PM plans, spawns the next agent as a subagent (`Agent({subagent_type})`), reviews the result, spawns the next — all from that one session. You stay in the conversation and can interject.

**Pros**
- One tab, no tab management.
- PM coordinates and reviews each step conversationally, so you watch the sprint progress in one place.
- You stay in the loop and can redirect between steps.

**Cons**
- PM's context grows every step — each subagent's result returns to it — so it degrades and hits the context ceiling on long sprints.
- Semi-manual: you drive PM to spawn each step.
- Not crash-resilient — the orchestration lives in PM's conversation, not in files.
- No token savings: each subagent re-reads its bootstrap, same as Autonomous, but without the walk-away payoff.

**Use when** a short sequence — a few steps — needs PM to coordinate while you watch. Good for quick cross-role work. The wrong default for long sprints.

---

## Autonomous — the sprint loop

**What it is.** A script walks the orchestration queue to completion unattended, spinning up a fresh agent per step. It runs in an isolated git **worktree** so your main checkout stays clean and usable while the sprint churns. Each step binds the role the queue names, does the work, files its handoff, and advances the queue itself; the loop only reads the queue and honors stop conditions.

### Setup — two tabs, both inside the worktree

`muster-sprint-new.sh` creates the worktree and prints its path. It does *not* start the loop. Open two tabs inside that path:

- **Tab 1 — PM.** Plan the sprint, and resolve any halts. Because this tab lives inside the worktree, PM's edits reach the loop with no syncing.
- **Tab 2 — the loop.** Run `muster-sprint-run.sh`. It walks the queue until it finishes or hits a stop condition.

You touch the run only at wave gates and halts. To continue across a gate, run `muster-sprint-resume.sh` from inside the worktree — PM processes your verdict, then the loop re-enters.

(`muster-sprint-sandbox.sh` is the all-in-one create-worktree-and-run shortcut, for when you don't want an interactive PM tab.)

### PM is your gatekeeper

Specialists never call you directly. A specialist that hits a block — a decision it lacks authority for, a missing input, a bug it can't crack, a red build — routes it to PM. PM decides handle-vs-escalate via the Decision Autonomy Matrix, and **only PM** (or a wave gate PM planned up front) halts the loop to summon you.

This keeps PM aware of every block, so the queue, decision log, and context files stay current — and it pulls you in only when a decision truly needs you or a build needs human eyes.

**Pros**
- Walk away. The sprint runs unattended; you review at gates and accept at the end.
- Bounded context per step (fresh each time) — quality doesn't degrade, there's no context ceiling, and it scales to long sprints.
- Deterministic orchestration: bash enforces the stop conditions, the worktree guard, and the handoff lint mechanically.
- Crash-resilient — all state is in files, so re-running continues from where it stopped.
- Your main checkout stays clean while the sprint runs in the worktree.

**Cons**
- The most upfront discipline — you have to plan the queue well and place wave gates.
- The least real-time control — between gates it runs on its own. Gates and stop conditions are the mitigation.
- It spends tokens on real work without you watching. You have to trust it.
- It requires the worktree discipline.

**Use when** you're executing a **well-planned sprint hands-off** — long, multi-step runs of planned, test-verifiable work, when you want to walk away. This is the "I've planned it — now build it while I do something else" mode.

**Not for** deep iterative debugging of a stubborn bug. That's warm-tab work (see mixing, below). The loop is for forward progress, not back-and-forth on a single hard problem.

---

## Choosing a mode — cost, context, quality

The modes trade **token cost** against **your time** and **output quality**. Pick on purpose, and tailor it to your token headroom (a Max plan buys very different defaults than a smaller plan).

**Manual is the most token-efficient.** Each tab is warm — you load its context once and keep working; follow-ups don't re-read the brain file. Best when tokens are tight, or the work is deep and iterative with one agent. Caveat: a tab's context grows over its life, so quality can drift on very long sessions — `/rebind` or a fresh tab resets it.

**Assisted costs more.** Every step spawns a fresh subagent that re-reads its bootstrap — no warm reuse. Each step is bounded and you stay in the loop to review. Best for a short sequence you want PM to coordinate while you watch, when you're not token-starved. It re-reads per step like Autonomous but without the walk-away payoff, so it's the wrong default for long sequences on a tight budget.

**Autonomous costs the most, and buys back your time.** Fresh process per step plus heavy unattended work is the highest spend. In return, it runs in a worktree with permissions pre-skipped — no per-step approval, no babysitting — and bounded per-step context keeps quality high across a long sprint. Best when you've planned well, want to walk away, and have the headroom.

**Quick picks**
- *Tight on tokens / no Max plan* → live in **Manual**; reserve **Autonomous** for the occasional well-scoped sprint worth the spend; don't default to **Assisted** for long sequences.
- *Tired of approving every step / want to walk away* → **Autonomous**. The token cost is the price of hands-off.
- *Want to watch and steer each step without driving every keystroke* → **Assisted**.
- *Deep, uncertain, back-and-forth work with one agent* → **Manual** (also the cheapest for it).

The honest one-liner: **Manual spends your time to save tokens; Autonomous spends tokens to save your time; Assisted sits in between.**

---

## Mixing modes

The modes work together, both **by phase** and **within a single run**.

**By phase.** Planning is always interactive — a warm PM tab, which is also Tab 1 of Autonomous. Execution is where you pick: deep, iterative, or uncertain work → **Manual**; a short coordinated sequence you'll watch → **Assisted**; a planned sprint hands-off → **Autonomous**.

**Within an autonomous run.** Because all coordination is file-mediated and the loop runs in a worktree, you can drop from Autonomous into Manual mid-sprint without breaking anything. Stop the loop, open a warm role-bound tab *inside the same worktree*, hand-hold the stuck work — most often a bug the loop keeps failing to fix — then rejoin. Two rules keep it safe:

1. **Drive manually only while the loop is stopped.** Never have the loop and a manual tab writing the same files at once.
2. **End every manual excursion with PM closeout** before you resume — hand the specialist's summary to PM so it updates the queue, decision log, and context files. This is the same PM-gatekeeping invariant, just human-initiated. Skip it and the loop resumes on stale state.

The revision cap is the built-in "this isn't converging" signal: it surfaces as a PM halt, which is your cue to take the work manual rather than round-tripping the loop on it.

**The one-liner:** warm tabs when you're building *with* an agent; autonomous when you're handing a planned sprint *to* the agents; PM-spawns for quick coordinated bits in between — and you can switch between them mid-sprint inside the worktree.

---

## See also

- [getting-started.md](getting-started.md) — setup and your first sprint
- [system-guide.md](system-guide.md) → Invocation Patterns and Autonomous Sprint Execution — the technical reference (stop conditions, wave gates, the scripts)
- [architecture-and-design.md](architecture-and-design.md) — how the picker, worktree, and file-mediated coordination fit together
