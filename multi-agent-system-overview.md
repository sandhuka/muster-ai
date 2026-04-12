# Multi-Agent System for Claude Code — Complete Overview

A guide for setting up and running a team of AI agents coordinated through persistent files.

---

## Directory Structure — Where Everything Lives

Muster uses a **two-repo architecture**: the framework (shared, reusable) and the project (product-specific).

### Framework Repo (Muster)
```
muster-ai/
├── CLAUDE.md                          # FRAMEWORK BRAIN — rules, protocols, agent roster, PM mode
├── system-guide.md                    # Templates, extensibility docs, verification checklist
├── multi-agent-system-overview.md     # This file — high-level system architecture
├── README.md                          # Public-facing docs
├── LICENSE
│
├── team/                              # AGENT BRAINS + METHODOLOGY
│   ├── pm/
│   │   ├── CLAUDE.md                  # PM brain — role definition, skill index
│   │   └── skills/
│   │       └── generic/               # PM methodology skills
│   │           ├── agent-management.md
│   │           ├── context-cascading.md
│   │           ├── decision-making.md
│   │           ├── sprint-planning.md
│   │           └── ...
│   │
│   ├── developer/
│   │   ├── CLAUDE.md                  # Dev brain — role definition, skill index
│   │   └── skills/
│   │       ├── generic/               # Cross-platform methodology
│   │       ├── ios/                   # iOS-specific skills
│   │       ├── backend/               # Backend-specific skills
│   │       ├── android/               # Android-specific skills (future)
│   │       └── web/                   # Web-specific skills (future)
│   │
│   ├── ui-ux/
│   │   ├── CLAUDE.md
│   │   └── skills/
│   │       ├── generic/
│   │       └── ios/
│   │
│   └── ... (content, marketing, legal, qa, research)
│
├── templates/                         # Everything a new project needs
│   ├── .claude/agents/                # Canonical bootloader files
│   ├── CLAUDE.md                      # Project CLAUDE.md with placeholders
│   └── knowledge-base/               # Pre-structured KB templates
│       ├── agent-context/             # Per-agent context templates
│       └── ...                        # Protocol + product file templates
│
└── scripts/
    └── setup-project.sh               # Scaffolds a new project repo
```

### Project Repo (Your Product)
```
my-project/
├── .claude/
│   └── agents/                        # AGENT STARTUP CONFIGS
│       ├── developer.md               # What Claude reads when you say @developer
│       ├── ui-ux.md                   # What Claude reads when you say @ui-ux
│       └── ...                        # Each file: ~30 lines of boot instructions
│
├── CLAUDE.md                          # PROJECT BRAIN — product info, overrides
│                                      # First line: "Read muster/CLAUDE.md"
│
├── muster/                            # ← Git submodule → muster-ai repo
│
├── knowledge-base/                    # SHARED SOURCE OF TRUTH
│   │
│   │  # ── Per-Agent Context ──
│   ├── agent-context/
│   │   ├── developer.md               # Filtered product context for developer
│   │   ├── ui-ux.md                   # Filtered product context for designer
│   │   └── ...                        # PM writes; agents read at startup
│   │
│   │  # ── Core Product Docs ──
│   ├── product-spec.md                # Full product specification
│   ├── brand-guidelines.md            # Brand identity, personality, visual direction
│   ├── brand-voice-guide.md           # Detailed voice/tone rules
│   ├── architecture.md                # Technical architecture
│   │
│   │  # ── Sprint & Coordination ──
│   ├── current-sprint.md              # Task board: who's doing what, status
│   ├── orchestration-queue.md         # Turn-by-turn: which agent to invoke NEXT
│   ├── agent-requests.md              # Inter-agent messages: requests + handoffs
│   ├── decision-log.md                # Every decision with rationale + files touched
│   │
│   │  # ── Cross-Cutting ──
│   ├── foundational-assumptions.md    # System-wide assumptions with touchpoint lists
│   ├── pre-launch-checklist.md        # Deferred items that block release milestones
│   ├── ui-component-requests.md       # Shared UI library component tracker
│   ├── design-system-reference.md     # UI library tokens/components reference
│   │
│   │  # ── Agent Deliverables ──
│   ├── design-specs/                  # UI/UX wireframes and screen specs
│   ├── legal/                         # Legal drafts
│   └── research/                      # RESEARCH-OWNED (PM cannot write here)
│       ├── product-brief.md
│       ├── market-landscape.md
│       ├── competitive-analysis.md
│       ├── change-log.md              # PM ↔ Research communication channel
│       └── ...
│
└── src/                               # ACTUAL APP CODE (your project)
    └── ...                            # Structure depends on your stack
```

### The Design Principle Behind This Structure

There are **five layers**, each with a clear purpose:

```
Layer 1: .claude/agents/              STARTUP CONFIGS     "What to read when invoked"
Layer 2: muster/team/<agent>/         AGENT IDENTITY       "Who I am, how I work" (shared)
Layer 3: knowledge-base/agent-context/ FILTERED CONTEXT    "What I need to know about THIS project"
Layer 4: knowledge-base/              SHARED TRUTH         "What the product IS"
Layer 5: src/ (your code)             ACTUAL CODE          "The thing being built"
```

**Why separate framework from project?** Agent roles, skills, and protocols are the same regardless of what product you're building. The framework (Muster) is shared via a git submodule. Product context lives in the project repo. One framework, many projects.

**Why agent-context files?** Each agent gets a slim (12-40 line) file with only the product details relevant to their role. The PM reads the full knowledge-base and translates it into each agent's context file. Agents almost never need to read the full knowledge-base docs — they get what they need from their context file.

**Why are skills separate from the agent brain?** Skills are *methodology* — how to write a test plan, how to do a competitive analysis. They rarely change. The agent brain is *identity* — role definition, generic relationships. Skills are loaded only when the current task matches.

---

## The Core Problem This Solves

Claude Code has a context window. Every conversation starts fresh. Agents forget everything. If you're building a product with multiple specialties (design, dev, legal, marketing, QA), you need a way to:

1. **Preserve context** across sessions — so agents pick up where they left off
2. **Coordinate work** between agents — so the developer knows what the designer decided
3. **Manage the context window** — so agents don't waste tokens reading irrelevant files
4. **Scale** — so adding a new agent or product doesn't break the system

This framework solves all four using **files as persistent memory**.

---

## System Architecture Flowchart

```
                         +-----------------------+
                         |      FOUNDER          |
                         |  (You, in terminal)   |
                         +----------+------------+
                                    |
                          Talks to Root Claude
                          (which IS the PM)
                                    |
                         +----------v------------+
                         |    ROOT CLAUDE (PM)    |
                         |                        |
                         |  - Plans sprints       |
                         |  - Makes decisions     |
                         |  - Cascades context    |
                         |  - Reviews deliverables|
                         |  - Updates all agents  |
                         +----------+-------------+
                                    |
              Writes to agent-context files (knowledge-base/agent-context/)
              Writes to knowledge-base/ (source of truth)
                                    |
         +------+------+------+----+----+------+------+
         |      |      |      |         |      |      |
         v      v      v      v         v      v      v
      +-----+-----+-----+-----+  +-----+-----+-----+-----+
      | Res | Dev | UI/ | Con |  | Mkt | Leg | QA  |     |
      |     |     | UX  | tent|  |     | al  |     |     |
      +--+--+--+--+--+--+--+--+  +--+--+--+--+--+--+     |
         |     |     |     |         |     |     |         |
         +-----+-----+-----+---------+-----+-----+        |
                         |                                 |
              Each agent reads on startup:                 |
              1. muster/CLAUDE.md (system rules)           |
              2. muster/team/<name>/CLAUDE.md (role)       |
              3. agent-context/<name>.md (product context)  |
              4. orchestration-queue.md (their task)        |
              5. agent-requests.md (messages to them)       |
                                                           |
         +------------------------------------------------+
         |
         v
    +-------------------------------------------------+
    |              KNOWLEDGE BASE (Shared)             |
    |                                                  |
    |  product-spec.md        brand-guidelines.md      |
    |  architecture.md        current-sprint.md        |
    |  decision-log.md        agent-requests.md        |
    |  orchestration-queue.md foundational-assumptions  |
    |  agent-context/         design-specs/             |
    |  legal/                                           |
    |  research/  (owned by Research agent only)        |
    +-------------------------------------------------+
```

---

## How Data Flows

```
DECISION MADE (by Founder + PM)
        |
        v
+------------------+     +----------------------+     +---------------------+
| decision-log.md  | --> | product-spec.md      | --> | agent-context/      |
| (audit trail)    |     | brand-guidelines.md  |     | <agent>.md          |
|                  |     | architecture.md      |     | (PM updates with    |
|                  |     | (source of truth)    |     |  only what THEY     |
|                  |     |                      |     |  need to know)      |
+------------------+     +----------------------+     +---------------------+
                                                              |
                                                              v
                                                      Agent reads context
                                                      file at startup
                                                      and starts working
                                                              |
                                                              v
                                                      Agent produces
                                                      deliverable
                                                              |
                                                              v
                                                    +-------------------+
                                                    | agent-requests.md |
                                                    | (handoff filed)   |
                                                    +--------+----------+
                                                             |
                                                             v
                                                    PM reviews handoff
                                                    Accepts / Requests revision
                                                             |
                                                             v
                                                    orchestration-queue.md
                                                    (next agent promoted)
```

---

## The File System — What Each File Does

### Framework Files (in Muster repo, shared via submodule)

| File | Purpose | Who writes it |
|------|---------|---------------|
| `muster/CLAUDE.md` | System rules, protocols, agent roster, PM mode, communication standards | Framework maintainer |
| `muster/team/<name>/CLAUDE.md` | Agent role definition, generic cross-agent relationships, skill index | Framework maintainer |
| `muster/team/<name>/skills/{generic,platform}/*.md` | Domain methodology — how to do the work (stable, rarely changes) | Framework maintainer |
| `muster/system-guide.md` | Templates, extensibility docs, verification checklist | Framework maintainer |

### Project Files (in your product repo)

| File | Purpose | Who writes it |
|------|---------|---------------|
| `.claude/agents/<name>.md` | Startup config — tells Claude Code what files to read when agent is invoked | Copied from Muster templates |
| `CLAUDE.md` | Product info, tech stack, project-specific overrides | Founder + PM |
| `knowledge-base/agent-context/<name>.md` | Filtered product context for each agent | PM |
| `knowledge-base/product-spec.md` | Full product specification | PM |
| `knowledge-base/brand-guidelines.md` | Brand identity, voice, visual direction | PM |
| `knowledge-base/architecture.md` | Technical architecture | Developer produces, PM reviews |
| `knowledge-base/current-sprint.md` | Full task board — what's assigned, status, acceptance criteria | PM |
| `knowledge-base/orchestration-queue.md` | Turn-by-turn execution sequence — tells you which agent to invoke next | PM populates; agents update on completion |
| `knowledge-base/agent-requests.md` | Inter-agent communication — requests and handoffs | All agents |
| `knowledge-base/decision-log.md` | Every product decision with rationale and affected files | PM (any agent can append) |
| `knowledge-base/foundational-assumptions.md` | Cross-cutting assumptions with touchpoint lists | PM |
| `knowledge-base/design-specs/` | Screen wireframes and component specs | UI/UX agent |
| `knowledge-base/legal/` | Privacy policy, ToS drafts | Legal agent |
| `knowledge-base/research/` | Market research, competitive analysis, product brief | Research agent (PM cannot write here except change-log.md) |

---

## The Orchestration Loop (How You Actually Work)

```
+---------------------------+
| 1. Open Claude Code       |
|    (Root Claude = PM)     |
+------------+--------------+
             |
             v
+---------------------------+
| 2. PM reads monitoring    |
|    files:                 |
|    - orchestration-queue  |
|    - agent-requests       |
|    - decision-log         |
|    - current-sprint       |
+------------+--------------+
             |
             v
+---------------------------+
| 3. PM tells you:          |
|    "Next step: invoke     |
|     @developer with       |
|     this prompt: ..."     |
+------------+--------------+
             |
             v
+---------------------------+
| 4. You invoke the agent:  |
|    @developer [prompt]    |
|    (or start new session  |
|     with the agent)       |
+------------+--------------+
             |
             v
+---------------------------+
| 5. Agent reads:           |
|    - muster/CLAUDE.md     |
|    - muster/team/ brain   |
|    - agent-context file   |
|    - orchestration-queue  |
|    - agent-requests       |
|    Does the work.         |
+------------+--------------+
             |
             v
+---------------------------+
| 6. Agent files a handoff  |
|    in agent-requests.md,  |
|    updates orchestration  |
|    queue (marks done,     |
|    promotes next step)    |
+------------+--------------+
             |
             v
+---------------------------+
| 7. Back to PM (Root       |
|    Claude). Reviews the   |
|    handoff. Accepts or    |
|    requests revision.     |
+------------+--------------+
             |
             v
+---------------------------+
| 8. Repeat from step 3     |
|    until sprint is done   |
+---------------------------+
```

---

## Context Window Management — The Key Innovation

The biggest lesson learned: **agents waste most of their context window reading files they don't need.** Here's how this system prevents that:

### Three-Tier Reading Model

```
TIER 1: ALWAYS READ (every startup)          ~80-120 lines
  - muster/CLAUDE.md (system rules)
  - muster/team/<agent>/CLAUDE.md (role)
  - knowledge-base/agent-context/<agent>.md (product context)
  - orchestration-queue.md (their task)
  - agent-requests.md (messages to them)

TIER 2: READ ON DEMAND (only when needed)    varies
  - product-spec.md (only the relevant section)
  - architecture.md (only when making arch decisions)
  - design-system-reference.md (only when building UI)
  - Specific skill files (only the one for current task)

TIER 3: NEVER READ (PM handles this)         0 lines
  - Decision log (PM summarizes relevant bits in agent context)
  - Other agents' brain files or context files
  - Full product spec (agent gets a filtered summary)
```

### Why This Matters

- **Agent-context = self-sufficient summary.** Each agent's context file is 12-40 lines of filtered, role-specific context. The agent can start working after reading their brain file + context file. Full knowledge-base docs are reference material for edge cases.

- **PM is a context translator, not a forwarder.** When a decision is made, the PM doesn't tell every agent "go read the decision log." The PM updates each agent's context file with only what THAT agent needs to know.

- **Skills are indexed, not bulk-loaded.** Each agent has a skill index in their brain file listing available methodology files. They read only the 1-2 relevant to the current task.

### Growth Caps (Preventing Unbounded File Growth)

| File | Cap | Who enforces |
|------|-----|-------------|
| orchestration-queue.md Done section | Max 5 entries | Completing agent trims; PM clears at new sprint |
| agent-requests.md Resolved section | Max 10 entries | Completing agent trims |
| agent-requests.md total | Target <150 lines | Self-cleaning rules |
| Decision log | Archive at 50 entries | PM |
| Agent startup reads | <200 lines per specialist, <400 for PM | System verification checklist |

---

## How Agents Communicate

Agents never talk directly. Everything goes through `knowledge-base/agent-requests.md` with two entry types:

### 1. Requests (questions, clarifications)
```
open --> done (receiving agent responds)
```

### 2. Handoffs (completed deliverables)
```
open --> in-review --> [needs-revision --> in-review -->] done
```

Each handoff has named reviewers with individual statuses. The producing agent runs a **Pre-Handoff Self-Review Checklist** before filing (internal consistency, acceptance criteria, cross-references, foundational assumptions, open questions).

---

## How the PM Manages Everything

Root Claude IS the PM. No separate PM agent. When you ask PM-type questions (planning, status, coordination), Root Claude reads the PM files and operates in PM mode.

### PM's Key Responsibilities

1. **Sprint planning** — Break work into agent tasks, sequence by dependencies, populate orchestration queue
2. **Context cascading** — When decisions happen, update each affected agent's context file with filtered, relevant context
3. **Handoff review** — Accept or request revision on agent deliverables
4. **Decision logging** — Every decision goes to decision-log.md with rationale and list of files touched
5. **Monitoring** — Check for stale requests (>3 days), stale handoffs (>3 days in review), revision loops (3+ rounds)
6. **Founder escalation** — PM has a Decision Autonomy Matrix. Some things PM decides alone (task sequencing, spec clarifications). Some require founder input (scope changes, pricing, architecture lock-in). Escalations go to the Founder Decisions section of orchestration-queue.md.

### Cascade Lag Prevention

After every decision, PM runs a quick audit:
1. Keyword scan — grep agent-context files for OLD terms that should have been updated
2. Agent context — does it still describe the old state?
3. Current tasks — do tasks need updating?
4. Cross-references — feature IDs, tier assignments changed?

---

## How It Scales

### Adding a New Agent

See `system-guide.md` for the full registration protocol with templates and safety checklist.

### Adding a New Product

1. Create a new project repo
2. Add Muster as a git submodule: `git submodule add <muster-repo-url> muster/`
3. Copy templates: `.claude/agents/`, `CLAUDE.md`, `knowledge-base/` from `muster/templates/`
4. Fill in project CLAUDE.md with product info
5. Fill in agent-context files with product context per agent
6. Start with the Research agent for discovery, then have PM cascade to all agents

Or use the setup script: `./muster-ai/scripts/setup-project.sh <project-name>`

### System Verification (After Framework Changes)

8-layer checklist in `system-guide.md`: reference integrity, skill coverage, template sync, ownership trace, context budget, growth/scalability, duplication detection, failure mode scan.

---

## Mistakes to Avoid (Learned the Hard Way)

1. **Don't dump the whole product spec into every agent.** Filter for relevance. The developer doesn't need marketing strategy. The content writer doesn't need the data model.

2. **Don't let agents read the decision log.** That's the PM's job. PM translates decisions into agent-specific context updates.

3. **Don't skip the orchestration queue.** Without it, you'll lose track of which agent to invoke next and what they should be working on.

4. **Don't let files grow unbounded.** Every file that agents read at startup needs a growth cap. A 500-line agent-requests.md burns half your context window before the agent does any work.

5. **Don't have agents communicate in conversation.** They communicate through files (agent-requests.md). Conversations are ephemeral. Files persist.

6. **Don't let parallel agents touch the same files.** You can absolutely run multiple agents in parallel across separate terminal windows — but make sure their tasks write to different files.

7. **Don't skip the pre-handoff self-review.** Agents catching their own mistakes before filing handoffs saves you review cycles.

8. **Don't forget to mirror dependencies on both sides.** If Developer waits on UI/UX for designs, BOTH agents' brain files must reflect this.

9. **Don't let the PM skip cascade lag checks.** Every decision must propagate to all affected agent-context files. A decision that only lives in the decision log will cause agents to work with stale context.

10. **Don't create new files when you can update existing ones.** File bloat = context window bloat.

---

## Quick Start Checklist

If you're setting up this system from scratch:

- [ ] Clone Muster and run `scripts/setup-project.sh <project-name>` (or set up manually)
- [ ] Fill in project `CLAUDE.md` with product info, tech stack, target user, monetization
- [ ] Fill in `knowledge-base/agent-context/*.md` files with filtered product context per agent
- [ ] Start with the Research agent for discovery: `@research Here's my product idea: [description]`
- [ ] After Research finalizes the product brief, PM cascades to all agents
- [ ] Plan your first sprint — PM sequences tasks, populates orchestration queue
- [ ] Execute: follow the orchestration queue — invoke agents one at a time or in parallel

---

## The Mental Model

Think of it as a company where:
- **Root Claude** is the PM who reads everything and tells each team member only what they need
- **Agent brain files** (in Muster) are role descriptions — same across all projects
- **Agent-context files** (in your project) are each team member's personal briefing document
- **knowledge-base/** is the company wiki (source of truth)
- **orchestration-queue.md** is the project board (who does what next)
- **agent-requests.md** is the internal messaging system (handoffs, questions)
- **skills/** are the team's playbooks (how to do specific types of work)
- **foundational-assumptions.md** is the list of "things everyone assumes are true" with instructions for what to update when one changes

The PM never asks agents to "go read everything." The PM reads everything, filters it, and updates each agent's context file with exactly what they need. That's what makes it context-window efficient.
