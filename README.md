# Muster

**Assemble your AI team.**

Muster is a multi-agent product management framework for [Claude Code](https://claude.ai/claude-code). It gives you a coordinated team of 8 AI agents — PM, Developer, UI/UX Designer, Content Writer, Marketing Strategist, Legal Advisor, QA Engineer, and Market Researcher — that share context, communicate through files, and build your product together.

## Why Muster?

Claude Code agents forget everything between sessions. If you're building a product that needs design, development, legal review, marketing, and QA, you need a way to:

- **Preserve context** — so agents pick up where they left off
- **Coordinate work** — so the developer knows what the designer decided
- **Manage the context window** — so agents don't waste tokens reading irrelevant files
- **Scale** — so adding a new agent or product doesn't break the system

Muster solves all four using files as persistent memory, with a PM agent (Root Claude) that reads everything and gives each specialist only what they need.

## How It Works

```
You (Founder) ←→ Root Claude (PM)
                      |
        Cascades filtered context to:
                      |
    Dev · UI/UX · Content · Marketing · Legal · QA · Research
```

- **Root Claude IS the PM** — plans sprints, makes decisions, cascades context, reviews deliverables
- **Each agent** has a role definition, platform-specific skills, and filtered product context
- **Orchestration queue** tells you which agent to invoke next
- **Agent requests** file handles all inter-agent communication (handoffs, reviews, questions)
- **Skills library** — 80+ methodology files across generic, iOS, and backend platforms

## Quick Start

### Option 1: Setup Script

```bash
git clone https://github.com/sandhuka/muster-ai.git
cd muster-ai
./scripts/setup-project.sh my-project
```

### Option 2: Manual Setup

```bash
# Create your project repo
mkdir my-project && cd my-project && git init

# Add Muster as submodule
git submodule add https://github.com/sandhuka/muster-ai.git muster

# Copy templates
mkdir -p .claude/agents
cp muster/templates/.claude/agents/*.md .claude/agents/
cp muster/templates/CLAUDE.md CLAUDE.md
cp -r muster/templates/knowledge-base .
```

### After Setup

1. Edit `CLAUDE.md` — fill in your product name, description, tech stack, target user
2. Edit `knowledge-base/agent-context/*.md` — fill in per-agent product context
3. Start discovery: `@research Here's my product idea: [description]`
4. After research completes, ask Root Claude to plan your first sprint
5. Follow the orchestration queue — invoke agents one by one

## Architecture

Muster uses a **two-repo model**:

| Repo | Contents | Sharing |
|------|----------|---------|
| **Muster** (this repo) | Agent roles, skills, protocols, templates | Public, shared via git submodule |
| **Your Project** | Product context, knowledge base, source code | Private, one per product |

```
my-project/
├── .claude/agents/          # Agent startup configs (copied from templates)
├── CLAUDE.md                # Your product info + overrides
├── muster/                  # ← Git submodule (this repo)
├── knowledge-base/
│   ├── agent-context/       # Per-agent filtered product context
│   ├── product-spec.md      # Your product specification
│   ├── orchestration-queue.md # What to do next
│   ├── agent-requests.md    # Inter-agent communication
│   └── ...
└── src/                     # Your code
```

## Agent Roster

| Agent | What They Do |
|-------|-------------|
| **PM (Root Claude)** | Plans sprints, cascades context, reviews deliverables, makes decisions |
| **Research** | Market analysis, competitive teardowns, user insights, product validation |
| **Developer** | Production code, architecture, testing — iOS, backend, and generic skills |
| **UI/UX** | Wireframes, user flows, component specs, design tokens |
| **Content** | In-app copy, blog, email, store listings, help docs |
| **Marketing** | Growth strategy, campaigns, user acquisition, analytics |
| **Legal** | Compliance, privacy, terms of service, IP protection |
| **QA** | Test strategy, bug tracking, release validation |

## Skills Library

Each agent has methodology files organized by platform:

```
team/<agent>/skills/
├── generic/     # Cross-platform methodology
├── ios/         # iOS/Swift-specific skills
├── backend/     # Backend/Supabase-specific skills
├── android/     # (future)
└── web/         # (future)
```

Currently ships with **80+ skill files** covering iOS (SwiftUI, MVVM, testing, accessibility, App Store), backend (Supabase, TypeScript, API design, security), and generic methodology (sprint planning, decision-making, brand guidelines, growth strategy, compliance).

## Key Concepts

- **Context budget** — Agents read ~80-120 lines at startup (brain + context + queue). Full knowledge-base docs are read on demand only when needed.
- **PM as context translator** — PM reads everything, then updates each agent's context file with only what they need. Agents never read the full decision log or other agents' files.
- **Orchestration queue** — PM populates at sprint planning. Each agent reads their step, does the work, marks done, promotes the next step.
- **Growth caps** — Every file has a size cap to prevent context window bloat (Done: max 5, Resolved: max 10, Decision log: archive at 50).

## Documentation

- `CLAUDE.md` — Framework rules, protocols, agent roster, PM mode
- `system-guide.md` — Templates, extensibility docs, verification checklist
- `multi-agent-system-overview.md` — Complete architecture guide with diagrams

## License

MIT License. See [LICENSE](LICENSE).
