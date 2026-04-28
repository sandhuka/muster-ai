# Web CI/CD

## Purpose
Make the quality discipline established across the other web skills *enforced* rather than aspirational. GitHub Actions pipeline, branch protection, feature flags, Conventional Commits, Renovate, instant rollback paired with expand-contract migrations. Without this skill, the gates exist in markdown but a determined developer can merge anything. With it, the discipline is mechanical. See `team/developer/skills/web-best-practices.md` for the 10-item PR quality-gate checklist this skill enforces. See `team/developer/skills/web-testing.md` for the test matrix wired here. See `team/developer/skills/web-performance-engineering.md` for bundle baseline + Lighthouse CI. See `team/developer/skills/web-data-layer.md` for expand-contract migrations that make rollback safe. See `team/developer/skills/web-security.md` for secret scanning and dependency security pieces. See `team/developer/skills/web-observability.md` for tying releases to Sentry. Target: **GitHub Actions, Vercel, pnpm 9+, Node.js 20+**.

## The Pipeline (GitHub Actions)

A single PR workflow runs every gate. Failures block merge.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

env:
  PNPM_VERSION: 9
  NODE_VERSION: 20

jobs:
  install:
    runs-on: ubuntu-latest
    outputs:
      cache-hit: ${{ steps.pnpm-cache.outputs.cache-hit }}
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: ${{ env.PNPM_VERSION }} }
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: pnpm
      - run: pnpm install --frozen-lockfile

  typecheck:
    needs: install
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: ${{ env.PNPM_VERSION }} }
      - uses: actions/setup-node@v4
        with: { node-version: ${{ env.NODE_VERSION }}, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm tsc --noEmit

  lint:
    needs: install
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: ${{ env.PNPM_VERSION }} }
      - uses: actions/setup-node@v4
        with: { node-version: ${{ env.NODE_VERSION }}, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint --max-warnings 0

  test:
    needs: install
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: ${{ env.PNPM_VERSION }} }
      - uses: actions/setup-node@v4
        with: { node-version: ${{ env.NODE_VERSION }}, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm test:unit --coverage
      - uses: codecov/codecov-action@v4
        with: { token: ${{ secrets.CODECOV_TOKEN }}, fail_ci_if_error: true }

  e2e-smoke:
    needs: install
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: ${{ env.PNPM_VERSION }} }
      - uses: actions/setup-node@v4
        with: { node-version: ${{ env.NODE_VERSION }}, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm exec playwright install --with-deps chromium
      - run: pnpm test:e2e --project=chromium --grep "@smoke"

  bundle-check:
    needs: install
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: ${{ env.PNPM_VERSION }} }
      - uses: actions/setup-node@v4
        with: { node-version: ${{ env.NODE_VERSION }}, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm build
      - run: node scripts/bundle-diff.mjs
        env:
          BASELINE_PATH: bundle-baseline.json
          THRESHOLD_BYTES: 10240

  lighthouse:
    needs: install
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
      - name: Wait for Vercel preview
        uses: patrickedqvist/wait-for-vercel-preview@v1.3.1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          max_timeout: 600
        id: preview
      - uses: treosh/lighthouse-ci-action@v12
        with:
          urls: |
            ${{ steps.preview.outputs.url }}
            ${{ steps.preview.outputs.url }}/dashboard
          configPath: .lighthouserc.json
          uploadArtifacts: true
```

```jsonc
// .lighthouserc.json
{
  "ci": {
    "collect": { "numberOfRuns": 3 },
    "assert": {
      "assertions": {
        "categories:performance": ["error", { "minScore": 0.9 }],
        "categories:accessibility": ["error", { "minScore": 1.0 }],
        "first-contentful-paint": ["error", { "maxNumericValue": 2000 }],
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }],
        "interaction-to-next-paint": ["error", { "maxNumericValue": 200 }]
      }
    }
  }
}
```

What each job enforces:

| Job | Maps to quality gate from |
|-----|--------------------------|
| typecheck | `web-best-practices.md` #1 (zero TS errors) |
| lint | `web-best-practices.md` #2 (zero warnings, ESLint clean) |
| test | `web-testing.md` (unit pyramid + coverage thresholds) |
| e2e-smoke | `web-testing.md` (critical-path E2E, ~10-30 specs total; PR runs a `@smoke` subset) |
| bundle-check | `web-best-practices.md` #6 + `web-performance-engineering.md` (bundle delta vs baseline) |
| lighthouse | `web-best-practices.md` #4 (Web Vitals against the actual Vercel preview) + `web-accessibility.md` (axe via Lighthouse a11y category at 1.0) |

Rules:
- **Jobs run in parallel.** Each step caches `pnpm install` via `setup-node`'s pnpm cache.
- **No job may be skipped on PRs.** All 6 are required for merge.
- **Lighthouse runs against the live preview deploy**, not a local server. Real network conditions, real CDN, real edge functions.
- **Coverage uploads to Codecov** with `fail_ci_if_error: true` — CI fails if upload fails (no silent coverage drift).
- **`pnpm install --frozen-lockfile`** in every job. No silent dependency drift.

## Branch Protection (GitHub Settings)

The pipeline enforces gates only if branch protection requires them. Configure on `main`:

- ✅ **Require a pull request before merging.**
- ✅ **Require approvals** (1 minimum; 2 for security-sensitive repos).
- ✅ **Dismiss stale pull request approvals when new commits are pushed.**
- ✅ **Require status checks to pass before merging** — select all 6 jobs from the pipeline.
- ✅ **Require branches to be up to date before merging.**
- ✅ **Require conversation resolution before merging.**
- ✅ **Require linear history** (forces rebase or squash; rejects merge commits).
- ✅ **Restrict who can push to matching branches** — empty list (no one pushes directly).
- ✅ **Allow force pushes: NO. Allow deletions: NO.**

Plus repo-level security:

- ✅ **Secret scanning enabled.** Push protection blocks commits containing detected secrets.
- ✅ **Dependabot alerts enabled.**
- ✅ **Code scanning** (CodeQL) enabled for JS/TS.
- ✅ **Private vulnerability reporting enabled.**

These settings are admin configuration — solo founders skip them until the first incident. For an Apple-quality framework, they're non-negotiable from day one.

## Feature Flags

The mechanism for shipping risky changes safely. Anchor on **Vercel Flags** (or Statsig if richer experimentation is needed).

```ts
// lib/flags.ts
import { unstable_flag as flag } from "@vercel/flags/next";
import { getSession } from "@/lib/auth/session";

export const newDashboard = flag({
  key: "new-dashboard",
  defaultValue: false,
  async decide() {
    const session = await getSession();
    if (!session) return false;
    if (session.roles.includes("internal")) return true;     // dogfood internally first
    if (env.NODE_ENV !== "production") return true;          // on in dev/preview
    return false;                                            // off by default in production
  },
});

export const checkoutV2 = flag({
  key: "checkout-v2",
  defaultValue: false,
  decide: () => false, // kill switch, default off
});
```

```tsx
// usage in a Server Component
import { newDashboard } from "@/lib/flags";

export default async function DashboardPage() {
  if (await newDashboard()) {
    return <NewDashboard />;
  }
  return <LegacyDashboard />;
}
```

Rules:
- **Every risky change ships behind a flag, default off.** "Risky" = changes user-visible behavior, touches money, modifies persistence, alters critical flows.
- **Kill switch ready before merge.** A flag that defaults `false` and can be toggled on without a deploy.
- **Dark-launch internally.** Roll out to internal users first; observe; widen.
- **Flags expire.** A flag that's been 100% rolled out for 2 weeks gets removed (cleanup PR). Flag debt is a real liability.
- **Don't gate authentication or core security with feature flags.** Auth checks are non-conditional; flags are for product behavior.
- **Document the flag in code.** The `decide` function is the source of truth — who sees what, when.

## Conventional Commits + Automated Changelogs

Commit messages drive automated versioning and changelog generation.

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: a user-visible feature
- `fix`: a bug fix
- `refactor`: code change that neither fixes nor adds (internal-facing only)
- `docs`: documentation
- `test`: tests
- `chore`: tooling, dependencies, CI
- `perf`: performance improvement

Examples:
```
feat(invoicing): add bulk delete action
fix(auth): expire session cookies on sign out
perf(dashboard): parallelize independent queries
chore(deps): bump next from 15.0.3 to 15.0.4
```

Breaking changes — append `!` after the type or include `BREAKING CHANGE:` footer:
```
feat(api)!: rename `userId` to `accountId` in webhook payloads

BREAKING CHANGE: Webhook consumers must update their parsing.
```

Wired to `changesets` for monorepos or `semantic-release` for single-package repos:

```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      # ... pnpm + node setup ...
      - run: pnpm install --frozen-lockfile
      - uses: changesets/action@v1
        with:
          publish: pnpm release
          version: pnpm version
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Rules:
- **PR titles follow Conventional Commits.** Squash-merge uses the title as the commit; the format propagates automatically.
- **Lint commit messages** with `commitlint` to reject malformed PRs.
- **Changelog regenerates automatically** from commit history. Don't hand-write release notes.

## Renovate (Dependency Automation)

```jsonc
// renovate.json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended", ":dependencyDashboard", ":semanticCommits"],
  "lockFileMaintenance": { "enabled": true, "schedule": ["before 4am on monday"] },
  "vulnerabilityAlerts": { "labels": ["security"], "automerge": false },
  "packageRules": [
    {
      "matchUpdateTypes": ["patch", "pin", "digest"],
      "automerge": true,
      "automergeType": "branch",
      "platformAutomerge": true
    },
    {
      "matchUpdateTypes": ["minor"],
      "automerge": false,
      "groupName": "minor updates"
    },
    {
      "matchUpdateTypes": ["major"],
      "automerge": false,
      "labels": ["major-update"]
    },
    {
      "matchPackagePatterns": ["^@auth/", "^next-auth", "^stripe", "^jose", "^bcrypt", "^argon2"],
      "groupName": "security-critical",
      "automerge": false,
      "schedule": ["at any time"],
      "labels": ["security"]
    },
    {
      "matchPackageNames": ["next", "react", "react-dom", "typescript"],
      "groupName": "framework-core",
      "automerge": false
    }
  ]
}
```

Rules:
- **Patch updates auto-merge** after CI passes. The risk of a patch breaking is low; the cost of manual review on every patch is high.
- **Minor and major updates** require human review. Behavior changes are possible.
- **Security-critical packages** (auth, crypto, payments) never auto-merge regardless of bump type. Human eyes always.
- **Framework core** (Next.js, React, TypeScript) never auto-merge. These have the largest blast radius.
- **`lockFileMaintenance`** runs weekly to keep transitive dependencies fresh.

## Rollback Discipline

A deploy is only safe to ship if it's safe to roll back. The pieces that make rollback work:

### Vercel-native instant rollback

Vercel keeps every deploy. Rolling back is a one-click promotion of a previous deploy to production.

```bash
# CLI alternative
vercel rollback <deployment-url> --token=$VERCEL_TOKEN
```

The CLI command is the runbook entry — every on-call engineer knows it.

### Pair with expand-contract migrations (from `web-data-layer.md`)

Rollback is **only safe** when the previous code version can still query the current schema. The rule: **every deploy is backward-compatible with the deploy before it.**

Concretely:

- Adding a column? Ship it nullable in deploy N. Code in deploy N-1 ignores it; code in deploy N writes it. Rolling back to N-1 is safe — the column exists but is unused.
- Renaming a column? Three deploys: add new (N), switch reads/writes (N+1), drop old (N+2). At any point, rolling back one deploy is safe. See `web-data-layer.md` "Expand-Contract."
- Adding a NOT NULL column? Two-step: add nullable (N), backfill + alter to NOT NULL (N+1). Don't try to do it in one migration with a default value unless the table is small.
- Dropping a column? Wait until it's been unused for a release cycle, verify via observability, then drop.

The discipline is: **never make a schema change that the previous code version can't tolerate.** Rollback should be a 30-second decision, not "do we have to fix the migration too?"

### Release tagging in Sentry (from `web-observability.md`)

Every deploy has a release tag. When errors spike post-deploy, Sentry shows "errors first appeared in release abc123." The rollback target is obvious.

### Runbook

Document the rollback procedure as a markdown file in the repo:

```markdown
# Rollback Runbook

If production is broken:

1. Identify the bad deploy in Vercel dashboard or via Sentry release tag.
2. Click "Promote to Production" on the previous good deploy.
3. Verify error rate drops in Sentry within 2 minutes.
4. Open an incident ticket; investigate calmly.

Database migrations are expand-contract — rolling back code is safe regardless of when in the migration cycle the bad deploy landed. If a migration itself needs reverting, that's a separate procedure (rare; should not happen with expand-contract discipline).
```

The runbook lives in the repo, not in someone's head.

## The Quality-Gate Map

Where each gate from `web-best-practices.md` is enforced:

| Gate | Enforcement |
|------|-------------|
| #1 Zero TS errors | CI `typecheck` job |
| #2 Lint clean (zero warnings) | CI `lint` job (`--max-warnings 0`) |
| #3 Tests pass | CI `test` job (Vitest with coverage); `e2e-smoke` for Playwright |
| #4 Lighthouse meets budget | CI `lighthouse` job against Vercel preview |
| #5 a11y scan clean | Lighthouse a11y at 1.0 (Lighthouse CI assertion) + Playwright axe on critical-path specs |
| #6 Bundle delta within budget | CI `bundle-check` job vs `bundle-baseline.json` |
| #7 Server Actions have `deps` parameter | Code review (no automated check yet — could be a custom ESLint rule) |
| #8 Zod at every external boundary | Code review |
| #9 No `console.log` | Lint rule (`no-console`, allow `error`/`warn`) |
| #10 Folder structure matches `web-architecture.md` | `eslint-plugin-boundaries` (covered in `web-data-layer.md`) |

CI catches 7 of 10 mechanically. Code review handles the architectural ones (#7, #8). Long-term, custom ESLint rules can move some review-checks to CI.

## Anti-Patterns

1. **Branch protection without all checks required.** Allows merging with broken CI. Every job is required.
2. **Force-pushes to main allowed.** Rewrites history; breaks rollback assumptions. Always disabled.
3. **Direct pushes to main.** Bypasses every gate. Always restricted.
4. **Bundle baseline updated silently.** Growth without review accumulates. Updates require an explicit PR with rationale.
5. **Lighthouse run against `localhost`.** Misses CDN, edge, real network conditions. Always against the preview deploy.
6. **Feature flags with no expiration.** Old flags accumulate; the codebase becomes a maze of conditional behavior. Flags expire after 2 weeks at 100% rollout.
7. **Auto-merging major dependency updates.** Behavior changes possible; tests don't catch everything. Human review for minors and majors.
8. **Skipping `--frozen-lockfile`.** Allows silent drift across environments. Always frozen in CI; lockfile updates are explicit PRs.
9. **No Conventional Commits.** Hand-written changelogs drift; releases become chaotic. Commitlint + semantic-release / changesets automate it.
10. **Schema migrations bundled with breaking code changes.** Rollback impossible. Expand-contract every non-additive schema change.
11. **No release tagging in Sentry.** Errors can't be correlated to deploys. `release: VERCEL_GIT_COMMIT_SHA` in Sentry config.
12. **Rollback procedure undocumented.** When prod breaks at 2am, the on-call engineer reads the runbook, not invents a procedure. Document it.

## Principles

1. **Discipline that lives only in markdown is aspiration.** CI + branch protection make it real. Every gate is enforced; no merge bypasses without explicit override.

2. **Safe to ship means safe to roll back.** Every deploy is backward-compatible with its predecessor. Schema changes follow expand-contract. Rollback is a 30-second decision.

3. **Risky changes ship behind flags, default off.** Internal dogfood first, then progressive rollout, then full release, then flag removal. The kill switch is always one toggle away.

4. **Renovate auto-merges what's safe; humans review what isn't.** Patches mechanical, minors and majors human, security-critical never auto.

5. **Tests run against the production build, against the production deploy.** Lighthouse against the preview URL, E2E against the build, not dev.

6. **Conventional Commits drive automation.** Format the message correctly once; versioning, changelog, release notes generate themselves forever.

7. **Branch protection is non-negotiable.** Solo founders skip it until the first incident. Apple-quality means it's on from day one.
