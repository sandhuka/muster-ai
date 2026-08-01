# Getting Started with Muster

This guide walks you through setup to your first sprint. If you haven't read the [README](README.md) yet, start there for a quick overview of what Muster is and how it works.

**Already have a project with existing code?** This guide is for greenfield starts (new products from zero). For adopting Muster into an existing codebase, use [adopting-existing-project.md](adopting-existing-project.md) instead — it handles reverse discovery, archives your existing `CLAUDE.md` if any, and works against your current code.

Total founder-attended time: about **1-2 hours** spread across ~3 Claude sessions over a day or two. The script runs in a couple of minutes; the rest is a brief orientation, sharing your product idea, market research (Research agent does the work), an evaluation step, draft review, and Sprint 1 planning.

**One-time cost** — future Muster updates pull in via `git submodule update` (plus `bash muster/scripts/muster-update.sh` to converge the few platform-level files) without repeating Discovery.

---

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed and running
- Git installed
- Terminal access

## Step 1 — Scaffold Your Project

```bash
cd ~/Desktop
curl -fsSL https://raw.githubusercontent.com/thinkArhant/muster-ai/main/scripts/setup-project.sh | bash -s your-app-name
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

> Let's start Discovery.

**Any first message works** — Claude reads `.populated` on the first message it processes, detects greenfield first-session state, and PM is auto-bound (picker is suppressed for the welcome). The Discovery welcome fires and asks for your product idea — describe it then, not before. (If you include the idea in your first message, PM still captures it correctly; you'll just see the welcome prompt for it first.)

**Status line check**: after a moment, the bottom of your terminal should show `[muster: pm]` — confirms PM is bound for this session.

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

From here, you follow the orchestration queue. For each step:

1. Open a Claude session — picker fires
2. Pick the role the queue says is next (e.g., Build → Developer)
3. Paste the queue's prompt block
4. The bound role executes the work, files a handoff, promotes the next step

Warm multi-tab — one tab per role you're actively working with — is the **Manual** way to run a sprint, and a good default: PM tab for planning and review, specialist tabs for execution. The status line `[muster: <role>]` keeps each tab clearly identified. You can also have PM spawn each step as a subagent (**Assisted**), or let a script walk the queue unattended in a worktree (**Autonomous**). See [operating-modes.md](operating-modes.md) for when to pick each.

Power-user shortcut: `MUSTER_ROLE=<role> claude` skips the picker. `MUSTER_ROLE=auto claude --dangerously-skip-permissions "execute next step"` runs the queue's next step autonomously — the primitive behind Autonomous mode.

---

## The Mental Model

Think of yourself as the "runner" — PM is the brain, you're the hands.

- **You** make the final calls. You drive sessions and answer the picker.
- **PM-bound session** plans sprints, coordinates agents, makes product decisions. Open a Claude session and pick PM (Coordination → PM in the picker).
- **Specialist-bound sessions** do the domain work. Open a session and pick the role per the orchestration queue. Run multiple in parallel when tasks are independent.

**Where everything lives:**
- `muster/` — The framework (agent brains, skills, methodology). You don't edit this.
- `knowledge-base/` — Your project's source of truth (product spec, decisions, sprint tasks, research). PM manages this.
- `.claude/agents/` — Framework-owned stubs for all 8 roles; each hops to `muster/team/<role>/bootloader.md` (picker binds read the bootloader directly; `Agent({subagent_type: "<role>"})` enters via the stub).
- `.claude/skills/rebind/` — `/rebind` slash command for swapping roles mid-session.
- `.claude/skills/muster/` — `/muster` slash command for framework help (the Guide).
- `.claude/statusline.sh` — Status-line script showing which role this session is bound to.

---

## Framework help — the Guide

Type `/muster` in any tab for how-Muster-works questions — which mode to use, why a run stopped, tuning `.muster/config` budgets, upgrading to a newer version. The Guide answers process questions and routes product questions (specs, decisions, sprint content) to PM. In a role-bound tab, `/muster` answers once without changing what that tab is bound to.

## What's Next

- [architecture-and-design.md](architecture-and-design.md) — Deep dive into the architecture, data flow, and context management
- [system-guide.md](system-guide.md) — Templates, extensibility, adding new agents or skills
