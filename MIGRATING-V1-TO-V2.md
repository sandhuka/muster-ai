# Migrating from Muster v1 to v2

> **Easiest path — let the Guide coach you.** Bump the submodule first
> (`cd muster && git checkout main && git pull && cd ..`), then tell Claude: *"Read
> `muster/MUSTER.md` and act as the Guide; coach me through upgrading this project to the latest
> Muster."* The Guide handles backups, rehearses the chain on a copy first, and verifies each
> step. The manual steps below are the fallback if you'd rather drive it yourself.

## What changed

v2 introduces three things v1 didn't have:

1. **`.populated` routing signal** — `knowledge-base/agent-context/.populated` is now the file Root Claude reads first to decide what mode it's in (existing-project onboarding, greenfield first session, greenfield ongoing, steady-state). v1 had no such file.
2. **Specialist HALT check** — `.claude/agents/<7>.md` now read `.populated` first and HALT if their entry is `null`. PM catches the HALT and runs JIT populate. v1 specialists had no such guard, so they could answer with stale or unfilled context.
3. **Slim routing block in project root `CLAUDE.md`** — replaces the v1 "System Bootstrap" prose with a 10-line `.populated`-based decision table.

## How to migrate

### The 10-second path

From your project root (where your `muster/` submodule lives):

```bash
# 1. Pull the latest framework
git submodule update --remote muster

# 2. Run the migration
bash muster/scripts/migrate-v1-to-v2.sh

# 3. Restart your Claude Code session
```

The script:

- Tarballs everything it might touch into `.muster-archive/v1-backup-<timestamp>.tar.gz` (rollback target) **before** any change.
- Creates `.populated` with `version: "2"`, sets `onboarded_at` and `onboarding_complete_at` to now, sets per-agent timestamps to now if that agent's context file is filled (else null — JIT will populate on first invocation).
- **Surgically injects** the v2 HALT-check line into each of the 7 `.claude/agents/<name>.md` files (one line per file; developer.md also gets a bootstrap-mode line). Any customizations you made to those files are preserved.
- Shows you a diff of the `CLAUDE.md` change and asks before writing.
- Idempotent. Re-running on a v2 project is a no-op (skips files that already have a `Startup halt` marker).

### Rollback

If anything goes sideways:

```bash
rm -f knowledge-base/agent-context/.populated
tar xzf .muster-archive/v1-backup-<timestamp>.tar.gz -C .
```

The first line removes the v2 file the script created (tar can't restore "absence"). The second restores everything the script touched. You'll be bit-identical to your pre-migration state.

## Manual migration (heavily-customized `CLAUDE.md`)

The script halts if it can't find the v1 bootstrap markers in `CLAUDE.md` — i.e., the `<!-- MUSTER SYSTEM BOOTSTRAP — DO NOT REMOVE OR MODIFY THIS SECTION -->` and `<!-- END MUSTER SYSTEM BOOTSTRAP -->` comments are absent (you removed them or rewrote the file).

Content above the markers is fine — the script preserves anything outside the bootstrap block (project H1, custom sections, etc.).

To migrate manually:

1. Open `CLAUDE.md`.
2. Find your old "System Bootstrap (Required)" block (or wherever the v1 routing instruction lives) and replace it with the contents of `muster/templates/CLAUDE.md` from the `<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->` line through `<!-- END BOOTSTRAP -->`. Copy verbatim — phrasing is load-bearing for routing.
3. Save, then re-run `bash muster/scripts/migrate-v1-to-v2.sh`. The script will detect the v2 markers, skip the `CLAUDE.md` patch, and continue with the `.populated` and specialist refresh.

## Working files the script intentionally leaves alone

- `knowledge-base/orchestration-queue.md` — v1 entries use a free-form `**Agent**/**Task**/**Prompt**` shape; v2 uses a stricter fenced-code-block-with-`@<agent>` format. The migration does not auto-rewrite these because the conversion is lossy. Either manually type `@<agent>` when copy-pasting an existing queue entry, or ask PM to re-plan the current sprint — PM will regenerate the queue in v2 format from scratch. The migrate script prints a notice if it detects v1-format entries.

## What the script does NOT touch

- `knowledge-base/` files (other than creating `agent-context/.populated`). All your decisions, sprints, specs, brand guidelines, research — untouched.
- `agent-context/<name>.md` files. Their content is preserved as-is; the script only reads them to decide whether to set the agent's `.populated` timestamp to now or null.
- The body of `.claude/agents/<name>.md` files. Only the new HALT-check line is inserted — your existing role definition, tool list, and any customizations stay exactly as they were.
- Your project code, git history, anything outside `CLAUDE.md` / `.claude/agents/` / `knowledge-base/agent-context/`.

## After migration

- Open a new Claude Code session in the project. PM Mode should route to **steady-state** (no halt, no welcome).
- If an agent's `.populated` entry is null and you invoke it, you'll see a brief "populating <agent> context (~30s, one-time)…" note as PM JIT-populates. This is normal.
- The `.muster-archive/` backups can be deleted once you've confirmed v2 is working.
