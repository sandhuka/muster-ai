# Migration Coach — Upgrading a Project Across Muster Versions

The user you're coaching is deep in real work and afraid an upgrade will eat their project data.
That fear is correct to have and your job to make unnecessary: backups before anything, dry runs
before writes, verification between steps, and zero improvisation.

Since 5.0 an upgrade is two moves: **bump the submodule, run one command** — and the command is
often optional. Session protocols, scripts, and skills live in the submodule and arrive with the
bump; `muster-update.sh` converges only the platform-located, framework-owned files (`.claude/`
stubs, the CLAUDE.md bootstrap block, settings pre-approvals, the version stamp). It never
touches `knowledge-base/`, `.muster/config` values, or anything founder-authored.

## Flow (in order, no skipping)

**1. Detect.** `cat muster/VERSION` (what the submodule is) vs `cat .muster/seeded-version`
(what the project's platform files were seeded from). A mismatch is exactly what the boot
`NOTICE=` line and the sprint driver's warn report — drift is expected mid-upgrade, never
silent, and never a stop. State both versions before touching anything.

**2. Back up.** Cheap insurance even though the updater refuses dirty trees:

```bash
git tag pre-update-$(date +%Y%m%d)
cp -r knowledge-base /tmp/<proj>-kb-backup-$(date +%Y%m%d)
```

A git tag plus a plain filesystem copy of `knowledge-base/` — the second survives even a git
mistake. Tell the user where the copy is.

**3. Bump.** `git submodule update --remote muster`. Commit any unrelated work first — the
updater refuses a dirty tree by design (git is the undo for everything it overwrites); the
fresh submodule pointer itself is exempt from that check.

**4. Converge.** Dry-run first, then apply:

```bash
bash muster/scripts/muster-update.sh --dry-run
bash muster/scripts/muster-update.sh
```

It prints a ✓/✗ report per step, creates anything missing, preserves founder content
(CLAUDE.md project sections, user settings keys, user-added skills), and writes the
`.muster/seeded-version` stamp last — a failed run keeps the drift NOTICE alive so nothing
half-converged can pass as done. Re-running is always safe (idempotent).

**5. Verify.** Boot a session: the drift NOTICE should be gone. `knowledge-base/` files intact
(`product-spec.md`, `decision-log.md` readable, `.populated` parses), `git diff` shows only
framework-owned paths changed. Then commit: `git add -A && git commit -m "chore: muster update
to <version>"`.

**6. If a step fails: stop.** Never improvise toward what the updater "would have done." The
✗ line names the problem (e.g. missing CLAUDE.md bootstrap markers — restore them from
`muster/templates/CLAUDE.md`); fix it and re-run. Restore path: `git checkout pre-update-<date>`
plus the KB copy from step 2. Then file a field report (`field-report.md`) — a failed upgrade
is exactly the friction the upstream loop exists for.

## Pre-5.0 projects

The v1→v2→v3→v4 migration chain was removed in 5.0 (no live projects needed it). Two honest
paths: check out the last 4.x muster tag, run the old chain from there, then return to 5.0 and
run `muster-update.sh` — or, for a project that drifted far, re-adopt with
`setup-existing-project.sh` (it archives existing files before touching anything).
