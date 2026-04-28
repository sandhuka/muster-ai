# Migrating from Muster v1 to v2

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

The script halts if it can't safely auto-patch `CLAUDE.md`. Two cases trigger this:

1. The v1 `<!-- MUSTER SYSTEM BOOTSTRAP — DO NOT REMOVE OR MODIFY THIS SECTION -->` markers are absent (you removed them or rewrote the file).
2. There's non-blank content above the start marker (the slim routing block must be at the very top of the file, before anything else).

In either case:

1. Open `CLAUDE.md`.
2. Make sure the file starts with the exact contents of `muster/templates/CLAUDE.md` from line 1 through the `<!-- END BOOTSTRAP -->` line. Copy that block verbatim — don't paraphrase. The phrasing is load-bearing for routing.
3. Below that block, keep your existing project content (Product Information, Project-Specific Rules, etc.). Strip the old "System Bootstrap (Required)" section if it survived the edit.
4. Save, then re-run `bash muster/scripts/migrate-v1-to-v2.sh`. The script will detect the v2 markers, skip the `CLAUDE.md` patch, and continue with the `.populated` and specialist refresh.

## What the script does NOT touch

- `knowledge-base/` files (other than creating `agent-context/.populated`). All your decisions, sprints, specs, brand guidelines, research — untouched.
- `agent-context/<name>.md` files. Their content is preserved as-is; the script only reads them to decide whether to set the agent's `.populated` timestamp to now or null.
- The body of `.claude/agents/<name>.md` files. Only the new HALT-check line is inserted — your existing role definition, tool list, and any customizations stay exactly as they were.
- Your project code, git history, anything outside `CLAUDE.md` / `.claude/agents/` / `knowledge-base/agent-context/`.

## After migration

- Open a new Claude Code session in the project. PM Mode should route to **steady-state** (no halt, no welcome).
- If an agent's `.populated` entry is null and you invoke it, you'll see a brief "populating <agent> context (~30s, one-time)…" note as PM JIT-populates. This is normal.
- The `.muster-archive/` backups can be deleted once you've confirmed v2 is working.
