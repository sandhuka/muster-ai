# Muster

**A multi-agent product team that runs inside Claude Code.**

![Muster sprint status — PM coordinating multiple agents across a real iOS project](assets/sprint-status.png)

Muster coordinates specialized AI agents — PM, Developer, UI/UX, Content, Marketing, Research, Legal, QA — through persistent markdown files. No external frameworks. No API dependencies. Just Claude Code and the filesystem.

```
You (Founder) --> Root Claude (PM) --> Dev | UI/UX | Content | Marketing | Legal | QA | Research
```

The PM reads everything. Each specialist reads only what's relevant to their current task. That's the core idea.

## The problem

Most multi-agent frameworks optimize for agent **communication** — how agents pass messages to each other. The real bottleneck is **context**. Claude Code agents forget everything between sessions. If you're building a product across design, dev, legal, marketing, and QA, you need persistent memory and a way to keep each agent focused on what matters.

## How Muster solves it

### Three-tier reading model

Each agent reads roughly 80 lines at startup — its role, filtered product context, and the current task. Full docs are loaded on demand. Files meant for other agents are never loaded at all.

### PM as context translator

When a decision is made, the PM doesn't tell every agent to go read the decision log. The PM updates each agent's context file with only what *that* agent needs. Decisions cascade through filtered summaries, not shared inboxes.

### Files as persistent memory

Agent brains, orchestration queues, handoff logs, and decision records persist as markdown. No session starts from zero — every agent picks up where the last one left off.

### Self-improving skills

During sprint planning, the PM scans for methodology gaps. New skills are classified as generic or product-specific. Generic skills are contributed back to the framework, so every project makes Muster sharper for the next one.

## Quick start

### New project

```bash
curl -fsSL https://raw.githubusercontent.com/sandhuka/muster-ai/main/scripts/setup-project.sh | bash -s my-project
cd ~/Desktop/my-project
claude
```

Tell Root Claude your product idea. Claude opens with a brief welcome and walks you through five Discovery stages — idea share, market research, go/no-go decision, draft review, Sprint 1 plan. Total founder time is **~1–2 hours across ~3 sessions** over a day or two.

See [getting-started.md](getting-started.md) for the full walkthrough.

### Existing project

If you already have code — a mobile app you've been building for months, a web app with real users, a backend service, a CLI tool — Muster has a dedicated adoption path. It reverse-discovers your product into a populated knowledge base and plans Sprint 1. Takes about two hours of focused time.

```bash
cd ~/path/to/your-existing-project
curl -fsSL https://raw.githubusercontent.com/sandhuka/muster-ai/main/scripts/setup-existing-project.sh | bash
```

See [adopting-existing-project.md](adopting-existing-project.md) for the full walkthrough.

## How it works

You describe your idea to Root Claude — which is the PM. The PM sends Research to investigate the market, then writes the product spec, plans a sprint, and queues up agent tasks if the idea is viable.

You invoke agents following the PM's sequence — one at a time, or in parallel across separate terminals when tasks are independent. Each agent reads its filtered context, does the work, files a handoff, and promotes the next step. Repeat until shipped.

## Agent roster

| Agent | Role |
|-------|------|
| **PM (Root Claude)** | Plans sprints, cascades context, reviews deliverables, makes decisions |
| **Research** | Market analysis, competitive teardowns, user insights, product validation |
| **Developer** | Production code, architecture, testing — iOS, backend, and generic skills |
| **UI/UX** | Wireframes, user flows, component specs, design tokens |
| **Content** | In-app copy, blog, email, store listings, help docs |
| **Marketing** | Growth strategy, campaigns, user acquisition, analytics |
| **Legal** | Compliance, privacy, terms of service, IP protection (guidance, not legal advice) |
| **QA** | Test strategy, bug tracking, release validation |

## How is this different?

| | CrewAI / AutoGen / LangGraph | Muster |
|---|---|---|
| **Solves** | Agent communication | Agent memory and context efficiency |
| **Built on** | Python libraries, API layers | Markdown files and Claude Code |
| **Requires** | Code to define agents | No code — file-based configuration |
| **Built from** | Framework design theory | A real iOS app, mid-build |
| **Includes** | Agent orchestration primitives | Operational patterns — growth caps, cascade lag prevention, decision autonomy, pre-handoff self-review |
| **Improves** | Manual updates by maintainers | Projects discover skill gaps and contribute generic skills back to the framework |

## Architecture

Muster uses a two-repo model.

```
my-project/
├── .claude/agents/        # Agent startup configs (invoke with @developer, @research, ...)
├── CLAUDE.md              # Product info + project-specific rules
├── muster/                # <-- Git submodule (this repo)
├── knowledge-base/
│   ├── agent-context/     # Per-agent filtered product context (PM writes, agents read)
│   ├── product-spec.md
│   ├── orchestration-queue.md
│   └── agent-requests.md
└── src/                   # Your code
```

**Muster** (this repo) contains agent roles, skills, and protocols — shared across all projects via git submodule. **Your project** contains product context, knowledge base, and source code. One framework, many projects.

## Documentation

| Doc | What it covers | Read when |
|-----|---------------|-----------|
| [getting-started.md](getting-started.md) | Step-by-step setup and first sprint | Setting up a new (greenfield) project |
| [adopting-existing-project.md](adopting-existing-project.md) | Reverse-discovery onboarding for projects with existing code | Adopting Muster into an existing codebase |
| [architecture-and-design.md](architecture-and-design.md) | Architecture deep dive — data flow, context management, agent communication | Evaluating whether to adopt Muster |
| [system-guide.md](system-guide.md) | Templates, extensibility, verification checklist | Adding agents, skills, or modifying the framework |
| [MIGRATING-V1-TO-V2.md](MIGRATING-V1-TO-V2.md) | One-shot migration for projects set up before v2 | A `muster/` update halted with "Pre-v2 Muster setup detected" |

## Stay updated

Star or watch this repo for release notifications on GitHub. For major version notes — new agents, new skills, framework improvements — [subscribe to email updates](https://buttondown.com/muster-ai). Release notes only.

## License

MIT License. See [LICENSE](LICENSE).
