# Muster

**A multi-agent product team that runs inside Claude Code.**

Muster coordinates specialized AI agents — PM, Developer, UI/UX, Content, Marketing, Research, Legal, QA, and growing — through persistent markdown files. No external frameworks, no API dependencies. Just Claude Code and the filesystem.

```
You (Founder) --> Root Claude (PM) --> Dev | UI/UX | Content | Marketing | Legal | QA | Research
```

The PM reads everything. Each specialist reads only what's relevant to their current task. That's the core idea.

![Muster sprint status — PM coordinating multiple agents across a real iOS project](assets/sprint-status.png)

## The Problem

Most multi-agent frameworks optimize for agent **communication** — how agents pass messages to each other. But the real bottleneck is **context**. Claude Code agents forget everything between sessions. If you're building a product with design, dev, legal, marketing, and QA, you need persistent memory and a way to keep each agent focused on what matters.

Muster solves this with three mechanisms:

- **Three-Tier Reading Model** — Agents read ~80 lines at startup (their role + filtered context + current task). Full docs are on-demand only. Irrelevant files are never loaded.
- **PM-as-Context-Translator** — When a decision is made, the PM doesn't tell every agent "go read the decision log." The PM updates each agent's context file with only what *that agent* needs.
- **Files as Persistent Memory** — Agent brains, orchestration queues, handoff logs, and decision records persist as markdown files. No session starts from zero.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/sandhuka/muster-ai/main/scripts/setup-project.sh | bash -s my-project
cd ~/Desktop/my-project
claude
```

Then tell Root Claude your product idea. It acts as your PM — plans sprints, coordinates agents, and tells you who to invoke next.

See [getting-started.md](getting-started.md) for the full step-by-step walkthrough.

## How It Works

1. You describe your idea to Root Claude (the PM)
2. PM sends Research to investigate the market
3. If viable, PM writes the product spec, plans a sprint, and queues up agent tasks
4. You invoke agents following the PM's sequence — one at a time or in parallel across separate terminals when tasks are independent
5. Each agent reads its filtered context, does the work, files a handoff, and promotes the next step
6. Repeat until shipped

## Agent Roster

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

## How Is This Different?

| | CrewAI / AutoGen / LangGraph | Muster |
|---|---|---|
| **Solves** | Agent communication | Agent memory and context efficiency |
| **Built on** | Python libraries, API layers | Markdown files and Claude Code |
| **Requires** | Code to define agents | No code — file-based configuration |
| **Built from** | Framework design theory | Real product development (an iOS app) |
| **Includes** | Agent orchestration primitives | Full operational patterns — growth caps, cascade lag prevention, decision autonomy, pre-handoff self-review |

## Architecture

Muster uses a two-repo model:

```
my-project/
├── .claude/agents/        # Agent startup configs (invoke with @developer, @research, etc.)
├── CLAUDE.md              # Your product info + overrides
├── muster/                # <-- Git submodule (this repo)
├── knowledge-base/
│   ├── agent-context/     # Per-agent filtered product context (PM writes, agents read)
│   ├── product-spec.md    # Product specification
│   ├── orchestration-queue.md  # Who to invoke next
│   ├── agent-requests.md  # Inter-agent communication (handoffs, reviews)
│   └── ...
└── src/                   # Your code
```

**Muster** (this repo) contains agent roles, skills, and protocols — shared across all projects via git submodule. **Your project** contains product context, knowledge base, and source code — one per product.

## Documentation

| Doc | What It Covers | Read When |
|-----|---------------|-----------|
| [getting-started.md](getting-started.md) | Step-by-step setup and first sprint | Setting up a new project |
| [architecture-and-design.md](architecture-and-design.md) | Architecture deep dive — data flow, context management, how agents communicate | Evaluating whether to adopt Muster |
| [system-guide.md](system-guide.md) | Templates, extensibility, verification checklist | Adding agents, skills, or modifying the framework |

## License

MIT License. See [LICENSE](LICENSE).
