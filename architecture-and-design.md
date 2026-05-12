# Architecture & Design

How Muster works under the hood — data flow, context management, agent coordination, and the design decisions behind the system.

For setup, see [getting-started.md](getting-started.md). For extending the system, see [system-guide.md](system-guide.md).

---

## Directory Structure

Muster uses a **two-repo architecture**: the framework (shared, reusable) and the project (product-specific).

### Framework Repo (Muster)
```
muster-ai/
├── CLAUDE.md                          # FRAMEWORK BRAIN — rules, protocols, agent roster, PM mode
├── README.md                          # Public-facing docs
├── getting-started.md                 # Step-by-step setup guide
├── architecture-and-design.md         # This file — architecture deep dive
├── system-guide.md                    # Templates, extensibility, verification checklist
├── LICENSE
│
├── team/                              # AGENT BRAINS + METHODOLOGY
│   ├── pm/
│   │   ├── CLAUDE.md                  # PM brain — role definition, skill index
│   │   └── skills/generic/            # PM methodology skills
│   │
│   ├── developer/
│   │   ├── CLAUDE.md                  # Dev brain — role definition, skill index
│   │   └── skills/
│   │       ├── generic/               # Cross-platform methodology
│   │       ├── ios/                   # iOS-specific skills
│   │       ├── backend/               # Backend-specific skills
│   │       ├── android/               # Android-specific skills
│   │       └── web/                   # Web-specific skills
│   │
│   └── ... (ui-ux, content, marketing, legal, qa, research)
│
├── templates/                         # Everything a new project needs
│   ├── .claude/agents/                # Canonical bootloader files
│   ├── CLAUDE.md                      # Project CLAUDE.md with placeholders
│   └── knowledge-base/               # Pre-structured KB templates
│
├── scripts/
│   ├── setup-project.sh               # Scaffolds a new (greenfield) project repo
│   ├── setup-existing-project.sh      # Adopts Muster into an existing codebase
│   └── migrate-v1-to-v2.sh            # Upgrades a pre-v2 project to v2 (creates .populated, injects HALT check, patches CLAUDE.md)
│
└── MIGRATING-V1-TO-V2.md              # User-facing migration guide for the above script
```

### Project Repo (Your Product)
```
my-project/
├── .claude/agents/                    # AGENT STARTUP CONFIGS
│   ├── developer.md                   # What Claude reads when you say @developer
│   ├── ui-ux.md                       # What Claude reads when you say @ui-ux
│   └── ...                            # Each file: ~30 lines of boot instructions
│
├── CLAUDE.md                          # PROJECT BRAIN — bootstrap routing + product info + project-specific rules
│
├── muster/                            # <-- Git submodule --> muster-ai repo
│
├── knowledge-base/                    # SHARED SOURCE OF TRUTH
│   ├── agent-context/                 # Per-agent filtered product context (PM writes, agents read)
│   ├── product-spec.md                # Full product specification
│   ├── brand-guidelines.md            # Brand identity, voice, visual direction
│   ├── architecture.md                # Technical architecture
│   ├── current-sprint.md              # Task board: who's doing what
│   ├── orchestration-queue.md         # Turn-by-turn: which agent to invoke next
│   ├── agent-requests.md              # Inter-agent communication: requests + handoffs
│   ├── decision-log.md                # Every decision with rationale + files touched
│   ├── foundational-assumptions.md    # System-wide assumptions with touchpoint lists
│   ├── pre-launch-checklist.md        # Deferred items that block release milestones
│   ├── ui-component-requests.md       # Shared UI library component tracker
│   ├── design-system-reference.md     # UI library tokens/components reference
│   ├── agent-skills/                  # Product-specific skills per agent (PM-managed)
│   ├── design-specs/                  # UI/UX wireframes and screen specs
│   ├── legal/                         # Legal drafts
│   └── research/                      # Research-owned (PM cannot write here)
│
└── src/                               # Your code
```

### The Five Layers

```
Layer 1: .claude/agents/               STARTUP CONFIGS     "What to read when invoked"
Layer 2: muster/team/<agent>/          AGENT IDENTITY       "Who I am, how I work" (shared)
Layer 3: knowledge-base/agent-context/ FILTERED CONTEXT     "What I need to know about THIS project"
Layer 4: knowledge-base/               SHARED TRUTH         "What the product IS"
Layer 5: src/                          ACTUAL CODE          "The thing being built"
```

**Why separate framework from project?** Agent roles, skills, and protocols are the same regardless of what product you're building. The framework is shared via git submodule. Product context lives in the project repo. One framework, many projects.

**Why agent-context files?** Each agent gets a slim (12-40 line) file with only the product details relevant to their role. The PM reads the full knowledge-base and translates it into each agent's context file. Agents almost never need to read the full docs.

**Why are skills separate from the agent brain?** Skills are *methodology* — how to write a test plan, how to do a competitive analysis. They rarely change. The agent brain is *identity* — role definition, relationships. Skills are loaded only when the current task matches.

---

## System Architecture

```
              +-----------------------+
              |      FOUNDER          |
              |  (You, in terminal)   |
              +----------+------------+
                         |
                   Opens Claude in project
                         |
                         v
              +-----------------------+
              |   ROLE PICKER fires   |  ← MUSTER_ROLE env var skips
              |   (two-step)          |    for scripts / autonomous mode
              |                       |
              |   Coordination → PM   |
              |   Build → Dev/UI-UX/QA|
              |   Communicate → Cont/Mkt
              |   Validate → Res/Legal|
              +----------+------------+
                         |
                  Bound role for session
                         |
   +-----+------+------+--+--+------+------+------+
   |     |      |      |     |      |      |      |
   v     v      v      v     v      v      v      v
  PM    Dev   UI/UX   QA   Cont   Mkt   Legal   Res
   |     |     |      |     |      |     |      |
   |     |     |      |     |      |     |      |
   |   <----- specialists read role-specific context ----->
   |
   + PM (when bound):
     - Plans sprints, makes decisions
     - Cascades context to agent-context files
     - Reviews handoffs, monitors stale items

         Each role's bootloader (.claude/agents/<role>.md) reads at bind:
         1. muster/CLAUDE.md (system rules)
         2. muster/team/<role>/CLAUDE.md (role identity + skill index)
         3. knowledge-base/agent-context/<role>.md (product context)
         4. orchestration-queue.md (their task)
         5. agent-requests.md (messages to them)
         6. role-specific extras (PM: 5 monitoring files;
            Developer/UI-UX/QA: ui-component-requests; etc.)
```

**Onboarding carve-outs**: greenfield first session and existing-project onboarding skip the picker and force-bind PM, then run the relevant discovery skill (`greenfield-discovery.md` or `reverse-discovery.md`). Picker fires for all subsequent sessions.

---

## Data Flow

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

## Context Window Management

The biggest lesson learned: **agents waste most of their context window reading files they don't need.** Here's how this system prevents that.

### Three-Tier Reading Model

```
TIER 1: ALWAYS READ (every startup)          ~80-120 lines
  - knowledge-base/agent-context/.populated (halt check — runs before
    any other read. If the agent's entry is null, the agent halts and
    returns control to PM for a one-time populate. PM re-invokes with
    the original task once populate completes. User-transparent.)
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

**Agent-context = self-sufficient summary.** Each agent's context file is 12-40 lines of filtered, role-specific context. The agent can start working after reading their brain file + context file. Full knowledge-base docs are reference material for edge cases.

**PM is a context translator, not a forwarder.** When a decision is made, the PM doesn't tell every agent "go read the decision log." The PM updates each agent's context file with only what THAT agent needs to know.

**Skills are indexed, not bulk-loaded.** Each agent has a skill index in their brain file. They read only the 1-2 skill files relevant to the current task.

### Growth Caps

Every file that agents read at startup has a size cap to prevent context window bloat:

| File | Cap | Who Enforces |
|------|-----|-------------|
| orchestration-queue.md Done section | Max 10 entries | Completing agent trims; PM clears at new sprint |
| agent-requests.md Resolved section | Max 10 entries | Completing agent trims |
| agent-requests.md total | Target <150 lines | Self-cleaning rules |
| Decision log | Archive at 50 entries | PM |
| Agent startup reads | <200 lines per specialist, <400 for PM | System verification checklist |

---

## The Orchestration Loop

```
1. Open Claude Code → picker fires → bind PM
            |
            v
2. PM bind step reads 6 monitoring files
   (decision-log, current-sprint, ui-component-requests,
    research/change-log, agent-requests, orchestration-queue)
   plus runs PM monitoring duties (stale items, Founder Decisions)
            |
            v
3. PM tells you: "Next: open a Developer tab and paste this prompt: ..."
            |
            v
4. Open new tab → picker fires → bind Developer (or use MUSTER_ROLE=developer)
            |
            v
5. Developer bootloader loads role-specific context, executes the task
            |
            v
6. Developer files handoff in agent-requests.md,
   updates orchestration queue (marks done, promotes next step)
            |
            v
7. Back to PM tab. PM reviews the handoff. Accepts or requests revision.
            |
            v
8. Repeat from step 3 until sprint is done

Autonomous variant: MUSTER_ROLE=auto in a loop reads the queue's
Next Step, binds the listed role, executes, and exits — no founder
intervention until queue empties.
```

---

## How Agents Communicate

Agents never talk directly. Everything goes through `knowledge-base/agent-requests.md` with two entry types:

**Requests** — questions, clarifications, new work asks between agents.
```
open --> done (receiving agent responds)
```

**Handoffs** — completed deliverables needing review.
```
open --> in-review --> [needs-revision --> in-review -->] done
```

Each handoff has named reviewers with individual statuses. The producing agent runs a **Pre-Handoff Self-Review Checklist** before filing — checking internal consistency, acceptance criteria, cross-references, foundational assumptions, and open questions. See [system-guide.md](system-guide.md) for the full checklist and entry templates.

---

## How the PM Manages Everything

PM is one of the eight peer roles. A PM-bound session reads the PM bootloader (`.claude/agents/pm.md`), which loads PM brain + agent-context + 6 monitoring files, then runs PM monitoring duties before answering the user's first message.

**Key responsibilities:**
1. **Sprint planning** — Break work into agent tasks, sequence by dependencies, populate orchestration queue
2. **Context cascading** — When decisions happen, update each affected agent's context file with filtered, relevant context
3. **Handoff review** — Accept or request revision on agent deliverables
4. **Decision logging** — Every decision goes to decision-log.md with rationale and files touched
5. **Monitoring** — Check for stale requests (>3 days), stale handoffs (>3 days in review), revision loops (3+ rounds)
6. **Founder escalation** — PM has a Decision Autonomy Matrix. Some things PM decides alone (task sequencing, spec clarifications). Some require founder input (scope changes, pricing, architecture lock-in). Escalations go to the Founder Decisions section of orchestration-queue.md.

**Cascade lag prevention** — After every decision, PM audits:
1. Keyword scan — grep agent-context files for old terms that should have been updated
2. Agent context — does it still describe the old state?
3. Current tasks — do tasks need updating?
4. Cross-references — feature IDs, tier assignments changed?

---

## File Reference

### Framework Files (in Muster repo, shared via submodule)

| File | Purpose | Who Writes |
|------|---------|------------|
| `muster/CLAUDE.md` | System rules, protocols, agent roster, role-binding mechanism | Framework maintainer |
| `muster/team/<name>/CLAUDE.md` | Agent role definition, skill index | Framework maintainer |
| `muster/team/<name>/skills/` | Domain methodology — how to do the work | Framework maintainer |
| `muster/system-guide.md` | Templates, extensibility, verification checklist | Framework maintainer |

### Project Files (in your product repo)

| File | Purpose | Who Writes |
|------|---------|------------|
| `.claude/agents/<name>.md` | Startup config — what to read when invoked | Copied from templates |
| `CLAUDE.md` | Three-section project file: Muster Framework pointer (read-only), Product Information, Project-Specific Rules | Founder + PM |
| `knowledge-base/agent-context/<name>.md` | Filtered product context per agent | PM |
| `knowledge-base/agent-context/.populated` | Per-agent populate state + lifecycle anchors `onboarded_at`, `onboarding_complete_at`, and `agents.<role>` timestamps. The priority-zero check routes into one of four routing paths plus a halt case: (1) **Existing-project onboarding active** — `onboarded_at` timestamp + `onboarding_complete_at` null → force-bind PM, load `reverse-discovery.md`. No picker. (2) **Greenfield first session** — `onboarded_at` null + `agents.pm` null → force-bind PM, load `greenfield-discovery.md`, fire welcome. No picker. (3) **Greenfield ongoing / post-Discovery steady-state** — `onboarded_at` null + `agents.pm` timestamp → fire role picker. Greenfield projects remain here permanently after Stage 1.3 (they never transition to path 4). (4) **Existing-project steady-state** — `onboarded_at` AND `onboarding_complete_at` both timestamps → fire role picker. (Halt) **File missing/invalid** → halt with setup instructions. Null `agents.<role>` entries in paths 3/4 trigger JIT populate at first invocation, not re-onboarding. | Script (init); PM (updates: `agents.pm` at greenfield Stage 1.3 OR existing-project init; agent timestamps during cascade + JIT; `onboarding_complete_at` at end of reverse-discovery — applies to existing-project flow only) |
| `knowledge-base/product-spec.md` | Full product specification | PM |
| `knowledge-base/architecture.md` | Technical architecture | Developer produces, PM reviews |
| `knowledge-base/current-sprint.md` | Task board — assignments and status | PM |
| `knowledge-base/orchestration-queue.md` | Turn-by-turn execution sequence | PM populates; agents update |
| `knowledge-base/agent-requests.md` | Inter-agent communication | All agents |
| `knowledge-base/decision-log.md` | Decisions with rationale and affected files | PM (any agent can append) |
| `knowledge-base/foundational-assumptions.md` | Cross-cutting assumptions with touchpoint lists | PM |
| `knowledge-base/brand-guidelines.md` | Brand identity, voice, visual direction | PM |
| `knowledge-base/pre-launch-checklist.md` | Deferred items that block release milestones | Any agent can append; PM reviews at gates |
| `knowledge-base/ui-component-requests.md` | Shared UI library component tracker | Developer, UI/UX |
| `knowledge-base/design-system-reference.md` | UI library tokens/components reference | UI/UX produces, Developer consumes |
| `knowledge-base/agent-skills/<agent>/` | Product-specific skills per agent | PM manages directory; agents read on demand |
| `knowledge-base/research/` | Market research, competitive analysis | Research agent (PM cannot write here) |

---

## Mistakes Muster Handles for You

These pitfalls were discovered during real product development. Muster's protocols, growth caps, and orchestration patterns are specifically designed to prevent them — so you don't have to think about them.

1. **Don't dump the whole product spec into every agent.** Filter for relevance. The developer doesn't need marketing strategy. The content writer doesn't need the data model.

2. **Don't let agents read the decision log.** That's the PM's job. PM translates decisions into agent-specific context updates.

3. **Don't skip the orchestration queue.** Without it, you'll lose track of which agent to invoke next and what they should be working on.

4. **Don't let files grow unbounded.** Every file that agents read at startup needs a growth cap. A 500-line agent-requests.md burns half your context window before the agent does any work.

5. **Don't have agents communicate in conversation.** They communicate through files (agent-requests.md). Conversations are ephemeral. Files persist.

6. **Don't let parallel agents touch the same files.** You can run multiple agents in parallel across separate terminals — but make sure their tasks write to different files.

7. **Don't skip the pre-handoff self-review.** Agents catching their own mistakes before filing handoffs saves review cycles.

8. **Don't forget to mirror dependencies on both sides.** If Developer waits on UI/UX for designs, BOTH agents' brain files must reflect this.

9. **Don't let the PM skip cascade lag checks.** Every decision must propagate to all affected agent-context files. A decision that only lives in the decision log will cause agents to work with stale context.

10. **Don't create new files when you can update existing ones.** File bloat = context window bloat.
