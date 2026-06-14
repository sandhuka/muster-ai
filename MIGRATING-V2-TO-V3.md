# Migrating from Muster v2 to v3

v3 introduces an **explicit role-picker** that fires at session start, replacing v2's implicit "Root Claude is PM" model. PM becomes a peer agent like the other seven; every session binds to one role for its lifetime.

This guide covers what's new, how to migrate (one script), and what changes in your project files.

---

> **Easiest path — let the Guide coach you.** Bump the submodule first
> (`cd muster && git checkout main && git pull && cd ..`), then tell Claude: *"Read
> `muster/MUSTER.md` and act as the Guide; coach me through upgrading this project to the latest
> Muster."* The Guide handles backups, rehearses the chain on a copy first, and verifies each
> step. The manual steps below are the fallback if you'd rather drive it yourself.

## What's new in v3

| Feature | What it does |
|---|---|
| **Role picker** | Two-step picker (group → role) fires at session start. Pick PM, Developer, UI/UX, QA, Content, Marketing, Legal, or Research. Bound for the session lifetime. |
| **Status line** | `[muster: <role>]` at the bottom of your terminal. Always know which role this session is bound to. |
| **`/rebind`** | Slash command to re-fire the picker mid-session if you bound the wrong role. |
| **`MUSTER_ROLE` env var** | Skip the picker for scripts/CI: `MUSTER_ROLE=developer claude "..."`. Halts on invalid value (no silent fallback). |
| **`MUSTER_ROLE=auto`** | Reads the orchestration queue's Next Step, parses the `@<role>` prefix, binds, executes. The runtime primitive for autonomous orchestration loops. |
| **PM as peer agent** | PM has its own `.claude/agents/pm.md` bootloader. Same shape as the other seven specialists. Invokable as a subagent via `Agent({subagent_type: "pm"})`. |
| **Onboarding carve-outs** | Greenfield first session and existing-project onboarding skip the picker and force-bind PM (so the discovery skills can drive end-to-end without picker friction). |

---

## Why migrate

- **No more re-briefing cost on follow-up turns** — when you stay in a role-bound tab, follow-up questions don't spawn fresh subagents that re-read all context. The session keeps its conversational continuity.
- **Multi-tab workflow becomes first-class** — open one tab per active role; status line keeps each tab clearly identified.
- **Autonomous orchestration unlocked** — `MUSTER_ROLE=auto` makes a daemon-driven product-build loop trivial (5 lines of bash).
- **Backward-compatible single-tab workflow** — `@<role>` prefix in queue prompts still spawns subagents from a PM tab; v3 just adds modes, doesn't take any away.

---

## Prerequisites

- Existing Muster v2 project (CLAUDE.md present, `muster/` submodule, `knowledge-base/agent-context/.populated`)
- `jq` recommended for automatic settings.json merge (most dev machines have it via `brew install jq` or `apt install jq`). Without jq, the script halts with manual-merge instructions.

---

## Migration steps

### 1. Update the muster submodule

```bash
cd your-project/
cd muster
git checkout main
git pull
cd ..
```

### 2. Run the migration script

```bash
# Recommended: dry-run first to see what will change
bash muster/scripts/migrate-v2-to-v3.sh --dry-run

# Then for real
bash muster/scripts/migrate-v2-to-v3.sh
```

The script is **idempotent** — re-running on an already-migrated project produces the same result without errors. If it halts mid-way, re-run with `--resume`.

### 3. Review the diff

```bash
git status
git diff
```

You should see new files in `.claude/` and `knowledge-base/agent-context/`, an updated `.gitignore`, and a replaced bootstrap block in `CLAUDE.md` (everything outside the `<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->` markers is preserved).

### 4. Have PM populate the new agent-context/pm.md

The migration creates `knowledge-base/agent-context/pm.md` from the template, but it's a placeholder. Open Claude in your project, pick PM via the picker, and ask:

> Populate your agent-context with the current product state (tech stack, target user, monetization, current sprint focus, key references).

PM will read your existing knowledge-base files and fill in the template.

### 5. Commit

```bash
git add muster .claude knowledge-base/agent-context/pm.md .gitignore CLAUDE.md
git commit -m "migrate muster v2 → v3 (role-picker, status line, /rebind)"
```

### 6. Verify in a session

Open Claude in your project. Expected:
- The role picker fires (two-step: group → role)
- Pick a role; status line shows `[muster: <role>]` at the bottom
- The bound role behaves correctly (PM does PM work; specialists do their work)

---

## What the migration script changes

| Path | Change | Why |
|---|---|---|
| `.claude/agents/pm.md` | **NEW** — PM bootloader | PM is now a peer agent with its own startup config |
| `.claude/statusline.sh` | **NEW** (executable) | Status line script — reads `$CLAUDE_CODE_SESSION_ID`, displays `[muster: <role>]` |
| `.claude/settings.json` | **NEW** if missing, or **merged** if exists without `statusLine`, or **preserved** if has `statusLine` | Wires the status line into Claude Code |
| `.claude/skills/rebind/SKILL.md` | **NEW** | The `/rebind` slash command for mid-session role swap |
| `knowledge-base/agent-context/pm.md` | **NEW** if missing | PM's filtered project context (placeholder until PM populates) |
| `.gitignore` | **+2 entries**: `.claude/.muster-bound-role.*`, `.claude/.muster-last-role` | Bind file + last-role memory are session-local |
| `CLAUDE.md` (bootstrap block) | **REPLACED** — content between `<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->` markers | Routes to v3 picker / discovery skills |

**Not touched**: `knowledge-base/` content (current-sprint, decision-log, agent-requests, product-spec, etc.). All v2 state preserved.

---

## Settings.json + statusline — the tricky cases

The migration script preserves any existing customization at three levels of priority. Highest priority wins.

### Priority 1: Project-level `.claude/statusline.sh` exists
Migration preserves it; never overwrites. If file matches muster's template exactly → idempotent skip. If file differs → script prints a snippet you can paste into your custom statusline to also show `[muster: <role>]`.

### Priority 2: User-level statusline (`~/.claude/settings.json` has `statusLine`)
This is the case for users who configured a global statusline that shows in all their Claude sessions (a common power-user setup). Migration **does NOT install project-level** `.claude/statusline.sh` or `.claude/settings.json` — doing so would override your user-level config for this project (Claude Code's project-level settings take precedence over user-level).

Instead, the script prints integration instructions: edit your user-level statusline script (typically `~/.claude/statusline-command.sh` or wherever your `~/.claude/settings.json` `statusLine.command` points) to add:

```bash
JSON_INPUT=$(cat)
YOUR_OUTPUT="...your existing line..."
if [ -f "muster/scripts/muster-bound-role.sh" ]; then
  MUSTER=$(echo "$JSON_INPUT" | bash muster/scripts/muster-bound-role.sh)
  echo "$YOUR_OUTPUT [muster: $MUSTER]"
else
  echo "$YOUR_OUTPUT"
fi
```

The if-check makes your statusline graceful in non-muster projects (no error if `muster-bound-role.sh` doesn't exist).

### Priority 3: No project-level OR user-level statusline
Migration installs muster's `.claude/statusline.sh` and `.claude/settings.json` cleanly.

### Settings.json conflict cases (when no user-level statusline)
If you don't have user-level statusline, the script handles project-level settings.json in three sub-cases:
1. **No `.claude/settings.json`** → script copies the v3 template
2. **Has settings.json without `statusLine`** → script uses `jq` to deep-merge the v3 statusLine block in. Your existing fields (`model`, `env`, `hooks`, etc.) are preserved
3. **Has settings.json WITH `statusLine`** → script skips and preserves your existing config

If `jq` is not installed, the script halts in case 2 with manual-merge instructions. Install jq (`brew install jq` / `apt install jq` / `dnf install jq`) and re-run.

---

## Troubleshooting

### "muster/templates/.claude/agents/pm.md not found"

Your muster submodule is still on a v2 commit. Update first:

```bash
cd muster && git checkout main && git pull && cd ..
```

### "CLAUDE.md missing BOOTSTRAP markers"

Your project's CLAUDE.md doesn't have the `<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->` and `<!-- END BOOTSTRAP -->` comment markers. The script can't safely auto-replace the routing block without them. Manually replace your routing block with the v3 version from `muster/templates/CLAUDE.md`, then re-run.

### "chmod +x failed on .claude/statusline.sh"

Your filesystem doesn't support the executable bit (NTFS via WSL, FAT, etc.). The status line won't work until fixed. Either move your project to a POSIX filesystem or manually wire `bash .claude/statusline.sh` somewhere instead.

### Migration interrupted mid-run

```bash
bash muster/scripts/migrate-v2-to-v3.sh --resume
```

The script writes `.muster-migration-state.json` after each step; `--resume` picks up where it stopped.

### Already migrated, want to re-apply

The script detects already-v3 state and continues idempotently. Just re-run without flags. All "Add" steps will skip with "(already exists)" and the routing block re-replacement is a no-op when content matches.

### Want to undo

Migration changes are tracked by git. To roll back:

```bash
git checkout CLAUDE.md .gitignore
git clean -fd .claude/agents/pm.md .claude/statusline.sh .claude/skills/rebind/ .claude/settings.json knowledge-base/agent-context/pm.md
cd muster && git checkout <previous-v2-commit-sha> && cd ..
```

(Substitute `<previous-v2-commit-sha>` with the muster submodule commit you were on before — find it in your git history.)

---

## After migration: workflow changes

| Task | v2 way | v3 way |
|---|---|---|
| Open a Claude session for PM work | Open Claude (Root Claude IS PM) | Open Claude → picker fires → Coordination → PM |
| Open a Claude session for Developer work | Open Claude → invoke `@developer` subagent | Open a new tab → picker fires → Build → Developer |
| Skip the picker | n/a | `MUSTER_ROLE=developer claude "..."` |
| Run a step autonomously | n/a | `MUSTER_ROLE=auto claude --dangerously-skip-permissions "execute next step"` |
| Switch role mid-session | Close tab, reopen as different role | `/rebind` |
| Know which role this session is | Mental tracking | Status line `[muster: <role>]` |

The `@<role>` prefix in `orchestration-queue.md` prompts still works in both single-tab and multi-tab modes — see `muster/CLAUDE.md` "@-mention prefix" rule for the routing details.

---

## Need help?

- See [README.md](README.md) for v3 overview
- See [getting-started.md](getting-started.md) for the new project workflow
- See [system-guide.md](system-guide.md) → Invocation Patterns for the three v3 modes (interactive picker, env-var bind, MUSTER_ROLE=auto)
- See [architecture-and-design.md](architecture-and-design.md) for the picker mechanism and bootloader flow
