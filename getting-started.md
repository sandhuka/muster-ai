# Getting Started with Muster

This guide walks you through setup to your first sprint. If you haven't read the [README](README.md) yet, start there for a quick overview of what Muster is and how it works.

**Already have a project with existing code?** This guide is for greenfield starts (new products from zero). For adopting Muster into an existing codebase, use [adopting-existing-project.md](adopting-existing-project.md) instead — it handles reverse discovery, archives your existing `CLAUDE.md` if any, and works against your current code.

Total founder-attended time: about **1-2 hours** spread across ~3 Claude sessions over a day or two. The script runs in a couple of minutes; the rest is a brief orientation, sharing your product idea, market research (Research agent does the work), an evaluation step, draft review, and Sprint 1 planning.

**One-time cost** — future Muster updates pull in via `git submodule update` without repeating Discovery.

---

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed and running
- Git installed
- Terminal access

## Step 1 — Scaffold Your Project

```bash
cd ~/Desktop
curl -fsSL https://raw.githubusercontent.com/sandhuka/muster-ai/main/scripts/setup-project.sh | bash -s your-app-name
```

This creates `~/Desktop/your-app-name/` with everything scaffolded — knowledge-base templates, agent configs, project CLAUDE.md, and an initial git commit. The script adds Muster as a git submodule automatically.

The script ends with a "MUSTER SETUP COMPLETE" banner and a Step 2 quick-start that tells you exactly what to type in Claude.

### What the script will NOT do
- Touch anything outside the new project directory
- Make external network calls beyond the git submodule clone

### If the script was interrupted mid-run

```bash
cd ~/Desktop/your-app-name
./muster/scripts/setup-project.sh --resume
```

Reads `.muster-setup-state.json` and picks up where it stopped.

## Step 2 — Open Claude Code and kick off Discovery

```bash
cd ~/Desktop/your-app-name
claude
```

Then send Claude this first message:

> Here's my product idea: [describe it]. Kick off Discovery.

**Any first message works** — PM reads `.populated` on the first message it processes, detects greenfield first-session state, and fires the Discovery welcome. What matters is that you send *something*. Claude Code sessions wait for user input before reading project files.

## What to Expect

Discovery runs as **5 user-visible stages** spread across ~3 Claude sessions. Total founder-attended time: ~1-2 hours.

| Stage | Time | Session | Your role |
|-------|------|---------|-----------|
| Welcome | ~2 min | Session 1 | Read the agenda; type "go" or share your idea to begin |
| **Stage 1 — Idea share** · *Highest leverage* | ~10 min | Session 1 | Tell Claude about your product idea |
| **Stage 2 — Market research** · *Mostly waiting* | ~15-30 min | Session 2 (separate) | Invoke `@research`; Research investigates |
| **Stage 3 — Go/no-go decision** · *Your focus* | ~10 min | Session 3 | Read research, accept GO / CONDITIONAL / NO-GO recommendation |
| **Stage 4 — Draft review** · *Read & confirm* | ~15 min | Session 3 (continued) | Read product-spec / brand / assumptions Claude has drafted |
| **Stage 5 — Sprint 1 plan** · *Quick decision* | ~5 min | Session 3 (continued) | Name your first feature; we start working |

## Tips for the High-Leverage Steps

### The idea share (Stage 1)

This is where most of your leverage comes from. Claude will ask you to share everything you know about the product idea — what problem, who it's for, why now, what you've tried, what you hate about competitors, what "done" looks like. No structure needed. Paste URLs, drop docs, ramble.

Take 10-15 minutes if you can. The more you share, the sharper Research's investigation will be in Stage 2.

**Sensitive content**: before pasting, scan your text for competitor analysis, partnership details, or internal model specifics. The brief is tracked in git by default, so anything sensitive should be redacted or flagged for Claude to keep out of the brief.

### The go/no-go decision (Stage 3)

When Research returns with their findings, Claude scores the research on 6 dimensions: market opportunity, competitive position, user insight quality, technical feasibility, founder fit, and revenue/monetization clarity. The recommendation is GO / CONDITIONAL / NO-GO with explicit reasoning.

If the score recommends CONDITIONAL or NO-GO, don't override casually. Slow-down moments at this gate may save you weeks of building the wrong thing. Push back on a specific dimension if you disagree — but expect Claude to push back if your pushback isn't backed by signal.

### Steady-state (after Discovery)

From here, you follow the queue directly: open each step in `knowledge-base/orchestration-queue.md`, copy the prompt, and invoke the listed specialist (**Option B — direct**). You only return to Root Claude/PM (**Option A — PM-mediated**) at planning and handoff-review moments: scope changes, sprint retros, reviewing a completed deliverable, or when the queue points back to PM. See `muster/system-guide.md` → Invocation Patterns for the full distinction.

---

## The Mental Model

Think of yourself as the "runner" — PM is the brain, you're the hands.

- **You** make the final calls. You talk to the PM.
- **Root Claude (PM)** plans sprints, coordinates agents, makes product decisions. You talk to Root Claude directly — it IS the PM.
- **Specialist agents** do the domain work. You invoke them when the PM tells you to, one at a time or in parallel when tasks are independent.

**Where everything lives:**
- `muster/` — The framework (agent brains, skills, methodology). You don't edit this.
- `knowledge-base/` — Your project's source of truth (product spec, decisions, sprint tasks, research). PM manages this.
- `.claude/agents/` — The agent configs that let you invoke `@research`, `@developer`, etc.

---

## What's Next

- [architecture-and-design.md](architecture-and-design.md) — Deep dive into the architecture, data flow, and context management
- [system-guide.md](system-guide.md) — Templates, extensibility, adding new agents or skills
