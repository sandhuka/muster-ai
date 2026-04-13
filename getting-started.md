# Getting Started with Muster AI

---

## What Is Muster AI?

Muster AI is a framework that turns Claude Code into a team of specialized AI agents that work together to build your product — from idea to launch.

**The core idea:** Instead of one AI doing everything, you get a team with defined roles — just like a real startup team. Each agent has its own expertise, its own memory of your project, and knows how to hand work off to the next agent.

**The team:**
- **You (the founder)** — You make the final calls. You talk to the PM.
- **Root Claude (the PM)** — Your main point of contact. Plans sprints, coordinates agents, makes product decisions. You talk to Root Claude directly — it IS the PM, not a separate agent you invoke.
- **Research** — Investigates your market, competitors, and users before you build anything.
- **Developer** — Writes the code.
- **UI/UX Designer** — Designs screens and user flows.
- **Content** — Writes all copy (in-app, marketing, docs).
- **Marketing** — Growth strategy, campaigns, acquisition.
- **Legal** — Compliance, terms, privacy (guidance, not legal advice).
- **QA** — Testing strategy and bug tracking.

**How it works in practice:**
1. You describe your idea to the PM (Root Claude).
2. PM sends Research to investigate the market.
3. Research comes back with findings. PM evaluates: is this idea worth building?
4. If yes, PM writes the product spec, plans a sprint, and tells you which agent to invoke next.
5. You invoke agents one at a time, following the PM's sequence. Each agent reads its assigned tasks, does the work, and updates the queue.
6. Repeat until shipped.

**The key thing to understand:** You're the one switching between agents. The PM tells you WHO to invoke next and WHAT to say. You copy-paste the prompt, run the agent, and come back to PM when it's done. Think of yourself as the "runner" — PM is the brain, you're the hands.

**Where everything lives:**
- `muster/` — The framework itself (agent brains, skills, methodology). You don't edit this.
- `knowledge-base/` — Your project's source of truth (product spec, decisions, sprint tasks, research). PM manages this.
- `.claude/agents/` — The agent configs that let you invoke `@research`, `@developer`, etc.

---

## Setting Up Your Project

### Prerequisites
- Claude Code installed and running
- Git installed
- Terminal access

### Setup Steps

**Step 1 — Clone Muster and scaffold your project**
```bash
cd ~/Desktop
git clone https://github.com/sandhuka/muster-ai.git
cd muster-ai
./scripts/setup-project.sh your-app-name https://github.com/sandhuka/muster-ai.git
```

This creates a new directory (`your-app-name/`) with everything scaffolded — knowledge-base templates, agent configs, project CLAUDE.md, and an initial git commit.

**Step 2 — Verify the setup**

Run this from inside the new project directory to confirm everything scaffolded correctly:

```bash
cd ~/Desktop/your-app-name

# Should show 7 agent bootloaders (no pm — Root Claude IS the PM)
ls .claude/agents/
# Expected: content.md  developer.md  legal.md  marketing.md  qa.md  research.md  ui-ux.md

# Should show the project CLAUDE.md with placeholders
head -5 CLAUDE.md
# Expected: "# [Project Name]" with placeholder text

# Should show knowledge-base structure
ls knowledge-base/
# Expected: agent-context/  agent-requests.md  agent-skills/  architecture.md
#           brand-guidelines.md  brand-voice-guide.md  current-sprint.md
#           decision-log.md  decision-log-archive.md  design-patterns.md
#           design-specs/  design-system-reference.md  foundational-assumptions.md
#           legal/  orchestration-queue.md  pre-launch-checklist.md
#           product-spec.md  research/  test-strategy.md  ui-component-requests.md

# Should show 7 agent-context files (one per specialist agent, no pm)
ls knowledge-base/agent-context/
# Expected: content.md  developer.md  legal.md  marketing.md  qa.md  research.md  ui-ux.md

# Should show 8 agent-skills directories (includes pm)
ls knowledge-base/agent-skills/
# Expected: content/  developer/  legal/  marketing/  pm/  qa/  research/  ui-ux/

# Should show research templates
ls knowledge-base/research/
# Expected: app-store-intel.md  change-log.md  competitive-analysis.md
#           market-landscape.md  monetization.md  product-brief.md
#           product-candidates.md  user-insights.md

# Should show muster submodule with all agent brains and skills
ls muster/team/
# Expected: content/  developer/  legal/  marketing/  pm/  qa/  research/  ui-ux/

# Should be a clean git state (initial commit already made)
git status
# Expected: "nothing to commit, working tree clean"
```

If any of the above is missing, the setup script didn't complete correctly. Re-run from step 1.

**Step 3 — Open your project in Claude Code**
```bash
cd ~/Desktop/your-app-name
claude
```

**Step 4 — Give your idea to Root Claude**

Talk to Root Claude directly. It IS the PM. Say something like:

> "Here's my product idea: [paste your document or describe it]. Kick off the discovery phase."

Root Claude will:
- Seed the product brief with your idea
- Queue up the Research agent
- Tell you to invoke `@research` next

**Step 5 — Invoke Research**

When PM tells you to, type:
```
@research
```

Research will read your seeded idea, do web research, and produce market analysis, competitive landscape, and user insights.

**Step 6 — Come back to PM**

Exit the Research agent session. Open a new Claude Code session in the same project directory. PM will read the completed research, score the idea on 6 dimensions, and give you a GO / CONDITIONAL / NO-GO recommendation.

**Step 7 — If GO, PM plans the first sprint**

PM writes the product spec, brand guidelines, assigns tasks to agents, and populates the orchestration queue — your step-by-step playbook for who to invoke next.

From here, you just follow the queue.

---

For detailed system documentation, see `system-guide.md`. For a high-level architecture overview, see `multi-agent-system-overview.md`.
