# Getting Started with Muster

This guide walks you through setup to your first sprint. If you haven't read the [README](README.md) yet, start there for a quick overview of what Muster is and how it works.

**Already have a project with existing code?** This guide is for greenfield starts (new products from zero). For adopting Muster into an existing codebase, use [adopting-existing-project.md](adopting-existing-project.md) instead — it handles reverse discovery, archives your existing `CLAUDE.md` if any, and works against your current code.

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

## Step 2 — Verify the Setup

```bash
cd ~/Desktop/your-app-name
ls .claude/agents/
```

You should see 7 agent files: `content.md`, `developer.md`, `legal.md`, `marketing.md`, `qa.md`, `research.md`, `ui-ux.md`. If they're there, you're good. If not, re-run the setup script.

## Step 3 — Open Your Project in Claude Code

```bash
cd ~/Desktop/your-app-name
claude
```

## Step 4 — Give Your Idea to Root Claude

Talk to Root Claude directly. It IS the PM. Say something like:

> "Here's my product idea: [paste your document or describe it]. Kick off the discovery phase."

Root Claude will:
- Seed the product brief with your idea
- Queue up the Research agent
- Tell you to invoke `@research` next

## Step 5 — Invoke Research

When PM tells you to, type:

```
@research
```

Research reads your seeded idea, does web research, and produces market analysis, competitive landscape, and user insights.

## Step 6 — Come Back to PM

Exit the Research agent session. Open a new Claude Code session in the same project directory. PM will read the completed research, score the idea on 6 dimensions, and give you a GO / CONDITIONAL / NO-GO recommendation.

## Step 7 — If GO, PM Plans the First Sprint

PM writes the product spec, brand guidelines, assigns tasks to agents, and populates the orchestration queue — your step-by-step playbook for who to invoke next.

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
