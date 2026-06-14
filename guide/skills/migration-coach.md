# Migration Coach — Upgrading a Project Across Muster Versions

The user you're coaching is deep in real work and afraid an upgrade will eat their project data.
That fear is correct to have and your job to make unnecessary: backups before anything, dry runs
before writes, verification between every step, and zero improvisation.

## Flow (in order, no skipping)

**1. Detect the current version.** `cat muster/VERSION` in the project (the pinned submodule's
version). Structural cross-check: no `knowledge-base/agent-context/.populated` but a
`knowledge-base/` → pre-v2. State what you found and what the path to current is before touching
anything.

**2. Back up first, always.** Even though the scripts carry their own rails:

```bash
git tag pre-migration-v<from>-$(date +%Y%m%d)
cp -r knowledge-base /tmp/<proj>-kb-backup-$(date +%Y%m%d)
```

A git tag plus a plain filesystem copy of `knowledge-base/` — the second one survives even a
git mistake. Tell the user where the copy is.

**3. Step zero: update the submodule.** `git submodule update --remote muster` (+ commit the
pointer). **The migration scripts ship with the NEW muster, not the version the project is
pinned to** — running an old checkout's scripts is the classic failure. This is why it's step
zero, not step three.

**4. Run the chain stepwise** — one script per version hop, each from `muster/scripts/`:

| Hop | Script | Its own rails |
|---|---|---|
| v1 → v2 | `migrate-v1-to-v2.sh` | Makes a tarball backup (`.muster-archive/`); diff-asks before editing CLAUDE.md |
| v2 → v3 | `migrate-v2-to-v3.sh` | Supports `--dry-run` — **always dry-run first** |
| v3 → v4 | `migrate-v3-to-v4.sh` | Supports `--dry-run` — **always dry-run first** |

For a v1 project specifically: recommend rehearsing the whole chain on a **copy** of the project
first (`cp -r` the repo, run the chain there, inspect) — it's minutes of cost against their real
fear.

**Minor bumps (same major, e.g. 4.1 → 4.2): no hop script.** Most framework code arrives with
the submodule pointer bump, but a minor can add project-level files that live OUTSIDE the
submodule (knowledge-base templates, `.claude/skills/*` like the `/muster` front door,
`scripts/test.sh`) — a bump alone never delivers those. After bumping, run the live upgrade
script (`bash muster/scripts/migrate-v3-to-v4.sh`; it doubles as "bring project files current"):
copy-if-absent, it seeds anything new and never clobbers existing files. Skipping it is why an
upgraded project can have the new framework code but be missing its `/muster` skill.

**5. Verify after EACH script, before the next.** Project data intact: `knowledge-base/` files
present and readable, `product-spec.md` / `decision-log.md` content preserved, `.populated`
parses, git status comprehensible. Don't run hop N+1 on an unverified hop N.

**6. If a script fails: stop.** Never improvise a migration by hand-editing toward what the
script "would have done." Give restore guidance —

```bash
tar xzf .muster-archive/v1-backup-*.tar.gz -C .   # v1→v2's tarball
git checkout pre-migration-v<from>-<date>          # or the tag from step 2
```

— then file a field report (`field-report.md`): a failed migration script is exactly the
friction the upstream loop exists for.
