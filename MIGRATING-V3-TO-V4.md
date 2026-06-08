# Migrating from Muster v3 to v4

v4 adds **autonomous sprint execution** — a script that walks the orchestration queue to completion unattended, in an isolated git worktree, with a fresh agent per step. Your existing Manual and Assisted workflows are unchanged; v4 only adds the hands-off mode.

This guide covers what's new, how to migrate (one pointer bump + one script), and what changes in your project files.

---

## What's new in v4

| Feature | What it does |
|---|---|
| **Sprint loop** | `muster-sprint-run.sh` walks the queue unattended — each step binds the role its Next Step names, does the work, files its handoff, and advances the queue itself. Stops on completion, a halt, a stuck step, or a non-zero exit. |
| **Two-tab worktree flow** | `muster-sprint-new.sh` creates an isolated worktree and prints its path; you run a PM tab and the loop tab inside it. `muster-sprint-sandbox.sh` is the all-in-one create-and-run shortcut. |
| **Wave gates** | PM can plan a `Role: halt` gate at the end of a wave that needs human verification. The founder writes a verdict to `wave-review.md`; `muster-sprint-resume.sh` processes it and continues. |
| **PM-sole-escalation gatekeeping** | Specialists never call the founder directly. A blocked specialist routes to PM, and only PM (or a planned wave gate) halts the loop. |
| **Observation triage** | Agents file non-blocking observations; PM triages them to `triage-log.md` without adding queue steps. |
| **Run observability** | Each step streams a live, human-readable trail and writes full logs under `.muster-sprint-logs/`. |

All v4 framework code lives in the `muster/` submodule and arrives with the pointer bump. The only project-side change is two new knowledge-base files, which the migration script seeds.

---

## Why migrate

- **Walk away from a planned sprint.** Plan the queue, place wave gates, start the loop, and review only at gates and at the end.
- **Quality holds across long sprints.** A fresh agent per step keeps every step's context bounded — no degradation, no context ceiling.
- **Your main checkout stays clean.** The loop runs in a worktree; you keep working in your primary tree while the sprint churns.
- **Nothing is taken away.** Manual (warm tabs) and Assisted (PM spawns subagents) work exactly as before. See [operating-modes.md](operating-modes.md) for when to use each.

---

## Prerequisites

- An existing Muster v3 project (CLAUDE.md present, `muster/` submodule, populated `knowledge-base/`).
- Nothing new to install — the autonomous scripts are bash and ship in the submodule.

---

## Migration steps

### 1. Bump the muster submodule to v4

All the framework code arrives here. Do this first:

```bash
cd your-project/
cd muster
git checkout main
git pull
cd ..
```

### 2. Run the migration script

```bash
# Recommended: dry-run first to see what will change
bash muster/scripts/migrate-v3-to-v4.sh --dry-run

# Then for real
bash muster/scripts/migrate-v3-to-v4.sh
```

The script seeds any new knowledge-base files your project is missing (`wave-review.md`, `triage-log.md`) and adds `.muster-sprint-logs/` to `.gitignore`. It is **idempotent** — re-running copies nothing once the files exist. It refuses to run if the submodule is still on a pre-v4 commit (the v4 framework code wouldn't be present yet), with the pointer-bump command to fix it.

### 3. Review the diff and commit

```bash
git status
git diff
```

You should see the bumped `muster/` pointer, the new `knowledge-base/wave-review.md` and `knowledge-base/triage-log.md`, and the `.gitignore` entry.

```bash
git add muster knowledge-base/wave-review.md knowledge-base/triage-log.md .gitignore
git commit -m "migrate muster v3 → v4 (autonomous sprint execution)"
```

### 4. Run your first autonomous sprint

Plan a sprint with PM, then:

```bash
bash muster/scripts/muster-sprint-new.sh    # creates the worktree, prints its path
```

Open two tabs inside that worktree — a PM tab and a loop tab (`muster-sprint-run.sh`). See [operating-modes.md](operating-modes.md) → Autonomous for the full setup, and `muster/system-guide.md` → Autonomous Sprint Execution for the mechanics.

---

## What the migration script changes

| Path | Change | Why |
|---|---|---|
| `knowledge-base/wave-review.md` | **NEW** if missing | Wave-gate I/O contract — PM writes the verification checklist, the founder writes the verdict |
| `knowledge-base/triage-log.md` | **NEW** if missing | Observation-disposition audit log |
| `.gitignore` | **+1 entry**: `.muster-sprint-logs/` | Per-run sprint logs are session-local |

**Not touched**: existing `knowledge-base/` content (orchestration-queue, decision-log, agent-requests, product-spec, etc.). Your `orchestration-queue.md` keeps its current format and self-heals to the v4 template at the next sprint planning.

---

## Troubleshooting

### "The muster submodule is on a pre-v4 commit"

The pointer bump in step 1 didn't land. Run it, then re-run the script:

```bash
cd muster && git checkout main && git pull && cd ..
```

### "No CLAUDE.md found" / "No muster/ submodule found"

Run the script from your project root — the directory that holds `CLAUDE.md` and the `muster/` submodule.

### The loop refuses to start ("never on the main checkout")

That's the worktree guard, working as intended. Run the loop from inside a sprint worktree created by `muster-sprint-new.sh` (or use `muster-sprint-sandbox.sh`), never on your primary checkout.

### Already migrated, want to re-apply

Re-run without flags. Both files skip with "already present" and the `.gitignore` entry is a no-op when present.

---

## Need help?

- See [operating-modes.md](operating-modes.md) for the three ways to run a sprint and when to use each
- See [system-guide.md](system-guide.md) → Autonomous Sprint Execution for the stop conditions, wave gates, and scripts
- See [README.md](README.md) for the v4 overview
