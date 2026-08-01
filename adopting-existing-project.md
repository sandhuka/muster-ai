# Adopting Muster for an Existing Project

This guide is for adding Muster to a project you've already been working on — an iOS app with 8 months of history, a web app with real users, a backend service, a CLI tool, a desktop app. If you're starting from scratch, use [getting-started.md](getting-started.md) instead.

---

## What's Different From Greenfield

Greenfield starts with Research validating your idea and PM writing specs from zero. That doesn't work when you already have code and tribal knowledge — the product already exists.

The existing-project path does **reverse discovery**: it reads what you know plus what's in the code, cross-checks the two, fills gaps with a short questionnaire, and drafts a complete knowledge base. You review, PM plans Sprint 1, done.

Total: about 2 hours of your time. **One-time cost** — future Muster updates pull in via `git submodule update` (plus `bash muster/scripts/muster-update.sh` to converge the few platform-level files) without repeating onboarding.

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed and running
- Git installed
- Your project is a git repo (or you're willing to run `git init`)
- At least some product context you can describe out loud
- About 2 hours of focused time (up to 2.5 hours for large codebases)

## Step 1 — Run the Setup Script

From inside your project directory:

```bash
cd ~/path/to/your-existing-project
curl -fsSL https://raw.githubusercontent.com/thinkArhant/muster-ai/main/scripts/setup-existing-project.sh | bash
```

The script asks one question: **what's your repo shape?**

- **Option 1 — Single git repo**: one repo for your project (monorepo with ios/web/backend subfolders; a web app with frontend + backend colocated; a single-surface product — all counted here).
- **Option 2 — Multi-repo parent**: separate repos for different platforms sitting inside a parent folder.

### What the script does
- Detects your git state (no-git / repo root / inside-larger-repo-abort)
- Offers to `git init` if the directory isn't a git repo
- Archives any existing `CLAUDE.md` and `.claude/agents/` to `.muster-archive/`
- Adds Muster as a git submodule, scaffolds templates
- Initializes `.populated` state file with `onboarded_at` timestamp
- Adds `.muster-archive/`, `.muster-setup-state.json`, `knowledge-base/.muster-onboarding/` to `.gitignore`

### What the script will NOT do
- Touch your source code
- Overwrite docs without showing you a diff first
- Cascade any context to agents until you've approved the source documents

### If the script aborts with "inside a larger git repo"

Your project folder is inside another git repo (e.g., a tracked `~/Documents/` parent, a dotfiles repo, an Obsidian vault). Muster won't install into the wrong repo — that would embed it as a submodule of a shared parent and expose your project under that parent's tracking. Move your project folder outside the parent first, then re-run. If the parent IS actually your project root, run setup from the parent instead.

### If the script was interrupted mid-run

```bash
./muster/scripts/setup-existing-project.sh --resume
```

Reads `.muster-setup-state.json` and picks up where it stopped.

## Step 2 — Open Claude Code and Kick Off

```bash
claude
```

Then send your first message to Claude. A clean starter:

> Let's start the existing-project onboarding.

**Any first message works** — PM reads `.populated` on the first message it processes, detects the existing-project state, and routes to the guided flow. What matters is that you send *something*. Claude Code sessions wait for user input before reading project files — they don't auto-start.

## What to Expect

The Claude session runs as **6 user-visible stages**, with brief housekeeping at the start and end. Total founder-attended time: ~2 hours.

| Stage | Time | Your role |
|-------|------|-----------|
| Welcome | ~2 min | Read the agenda; type "go" to begin |
| _Housekeeping (skipped if not needed)_ | ~5–25 min | Approve CLAUDE.md and `.claude/agents/` merges if you had any pre-Muster |
| **Stage 1 — Brain-dump** · *Highest leverage* | ~25 min | Tell Claude everything you know about the product |
| Stage 2 — Code audit · *Mostly waiting* | ~15 min | Audit runs; you can step away |
| **Stage 3 — Audit review** · *Your focus* | ~20 min | Resolve every `[inferred]` claim — confirm or correct |
| Stage 4 — Questionnaire | ~15 min | Answer what the brain-dump didn't cover |
| Stage 5 — Draft review | ~15 min | Read the spec / brand / assumptions Claude has drafted |
| Stage 6 — Sprint 1 plan | ~5 min | Name your first feature; we start working |
| _Cleanup (silent)_ | ~2 min | Claude archives onboarding scratch and populates Sprint 1 context |

## Tips for the High-Leverage Steps

### The brain-dump (Stage 1)

This is where most of your leverage comes from. PM will ask you to share everything you know about the product — what it does, who it's for, what you've tried and discarded, what you hate about competitors, what "done" looks like, what Claude should NOT assume. No structure needed. Paste URLs, drop docs, ramble.

Take 20-30 minutes if you can. Skip only if you have nothing beyond what the questionnaire will ask.

**Sensitive content**: before pasting, scan your text for API keys, credentials, customer data, internal identifiers. The brain-dump file is gitignored by default, but once pasted the content enters your Claude session context. Redact first.

### The audit review (Stage 3)

Developer tags every claim as `[verified]` (observed directly in code) or `[inferred]` (guessed from patterns — file names, directory structure, imports). **Every `[inferred]` row requires your explicit action**: `verified`, `wrong: <correction>`, or `don't-know`. There's no "approve all" shortcut for these. This is the forcing function that keeps bad assumptions out of your knowledge base.

A fatigued founder who types `verified` on every row without reading gets wrong context cascaded downstream — typically surfacing days later as QA writing tests against the wrong auth scheme, Developer building against the wrong database, or UI/UX specifying components for the wrong state-management library. Slow down on these rows.

Also review the **Skipped** section carefully — it lists what the audit didn't read (vendored dependencies, build artifacts, DSL folders). You must confirm "that's the whole surface area" before PM writes `architecture.md`. If the audit missed a subsystem (a background worker, an offline sync layer, a custom IPC), flag it now.

## After Onboarding

After Stage 6 (and silent cleanup), PM has written:
- A populated `knowledge-base/` — product-spec, architecture, brand-guidelines, foundational-assumptions, agent-context files for Sprint 1 agents
- Your project root `CLAUDE.md` populated with real product info (Project Name, Tagline, Tech stack, Target user, Monetization, Team model) — placeholders pulled from the synthesized product-spec, brand-guidelines, and architecture docs
- `knowledge-base/current-sprint.md` with Sprint 1 tasks
- `knowledge-base/orchestration-queue.md` with the first 3-5 steps and copy-paste prompts
- Sprint 2 backlog seeded with UI/UX curation tasks for brand-guidelines and design-system-reference (if a design system was detected)
- `knowledge-base/agent-context/.populated` with `onboarding_complete_at` timestamped — every future session takes the steady-state path (no re-reading the onboarding skill)

From here, you follow the orchestration queue — same loop as the greenfield path post-Sprint-1. Open `orchestration-queue.md`, copy the next prompt, invoke the listed agent.

## Things to Know

**First invocation of a non-Sprint-1 agent**: when you later invoke an agent that wasn't populated during onboarding (e.g., `@marketing` a few sprints in), it returns control to PM briefly (~30 seconds) while PM populates that agent's context file. You'll see a short "populating marketing context…" message, then the normal agent output. User-transparent.

**Muster framework updates**: `git submodule update --remote muster`, then `bash muster/scripts/muster-update.sh` — it converges the framework-owned project files (agent stubs, bootstrap block, pre-approvals) and never touches your knowledge base. If you skip it, the next session's boot prints a NOTICE naming that exact command. Onboarding never repeats.

**A teammate pulls the repo**: they do NOT re-run the setup script. The `.populated` state file tells Claude that setup has already been run. They just `cd` into the repo and open Claude.

**`.muster-archive/`**: contains your pre-Muster `CLAUDE.md`, archived `.claude/agents/`, and the full onboarding trail (brain-dump, audit brief, audit notes). Gitignored by default. Useful for reference; not read by Claude in steady state.

**The first Sprint 1 handoff**: expect revisions. Sprint 1 is where reverse-discovered context meets real work — if PM misread something during audit review or the questionnaire missed a detail, it surfaces here. Items 4 and 5 of the pre-handoff self-review (feature IDs, foundational assumptions) are flagged but don't block during the first post-onboarding sprint for exactly this reason. Revisions during Sprint 1 are healthy, not a sign of failure.

---

## What's Next

- [getting-started.md](getting-started.md) — The greenfield flow; useful for understanding Muster's steady-state operation after onboarding completes
- [architecture-and-design.md](architecture-and-design.md) — How agents, context, and skills work together
- [system-guide.md](system-guide.md) — Framework templates and extensibility (read when modifying the framework, not during onboarding)
