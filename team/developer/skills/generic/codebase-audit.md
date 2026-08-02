# Codebase Audit (Bootstrap Mode)

## Purpose
Defines how Developer performs a shallow code audit during existing-project onboarding — a one-time, read-only pass that produces the evidence base for `knowledge-base/architecture.md`. Runs only in **bootstrap mode** (triggered by the onboarding flow), not as a standard Developer task. See the `code-standards` skill for standard development workflow. Invoked from the `reverse-discovery` skill during the onboarding audit step; output feeds the durable `knowledge-base/architecture.md`.

## Bootstrap Mode Contract

Bootstrap mode is the Developer startup path used only when PM invokes Developer for reverse-discovery onboarding. It bypasses the normal agent-context read (which would fail: `knowledge-base/agent-context/developer.md` is unpopulated at this point — this audit's output is what feeds it).

### Trigger (file-based, not prompt-text)
Bootstrap mode activates when both conditions hold at Developer's startup:
1. `knowledge-base/.muster-onboarding/audit-brief.md` exists (PM-authored before invocation)
2. `knowledge-base/agent-context/.populated` has `null` for the `developer` entry

If either condition is missing, run standard Developer startup instead. The dual-file signal prevents accidental activation by a user typing a flag in a normal `@developer` prompt.

### Tool scope (read-only plus one scoped Write)
- **Available**: Read, Grep, Glob
- **Disabled**: Edit, Bash
- **Write permitted only at two paths**:
  - `knowledge-base/.muster-onboarding/architecture-audit-notes.md` — the audit output
  - `knowledge-base/design-system-reference.md` — starter scaffold, only if existing design-system folders are detected

No other writes, no source-code modifications, no edits. This matches the setup script's "will NOT modify your source code" promise.

### Input
PM writes `knowledge-base/.muster-onboarding/audit-brief.md` before invoking Developer. The brief contains:
- Generic audit scope (what to read, what to identify — summarized below)
- A verification list of founder claims from the brain-dump (optional — empty if founder skipped the dump)
- Skipped-list disclosure requirement

### Invocation
PM invokes Developer via the Task tool with `subagent_type="developer"`. The audit is never performed inline by PM.

## Audit Procedure

### Read scope (per detected code area)
- Top-level directory tree, 2 levels deep
- Package manifest files: `package.json`, `Podfile`, `Package.swift`, `build.gradle`, `build.gradle.kts`, `requirements.txt`, `Pipfile`, `Cargo.toml`, `go.mod`, `deno.json`, `pyproject.toml`
- Top-level `README.md` / `README` if present
- 3-5 entry-point files per code area. Use whatever is idiomatic for the stack; the list below is illustrative, not exhaustive. If the project uses a stack not listed here, find the equivalent entry points (the file(s) a developer would open first to understand the app's shape):
  - **Android**: `MainActivity.kt` / `MainActivity.java`, `Application.kt`, top-level module manifests, `AndroidManifest.xml`
  - **Backend (any language)**: top-level `main.ts` / `index.ts` / `server.ts` / `app.py` / `main.py` / `main.go` / `main.rs` / `Application.java`; route definition files; middleware config
  - **CLI / library**: entry binary (`src/main.rs`, `cmd/*/main.go`, `bin/*`, `src/index.ts`); public API surface file(s)
  - **Desktop (Electron, Tauri, etc.)**: `main.ts` / `main.js` / `src-tauri/src/main.rs`; renderer entry
  - **iOS**: `*App.swift` (with `@main`), `AppDelegate.swift`, `SceneDelegate.swift`
  - **Web**: `App.tsx` / `App.jsx` / `main.ts` / `pages/_app.tsx` / `app/layout.tsx`; router / route-tree file if present
  - **Serverless functions**: function-directory index files; function config (`vercel.json`, `netlify.toml`, `wrangler.toml`, `supabase/functions/*`)
- Grep for existing design-system folders: `components/`, `ui/`, `design-system/`, `tokens/`, `theme/` (case-insensitive)
- Grep for product signals: route declarations, user-table schema (migrations or model files if obvious), external API integrations (imports of `@supabase/*`, `firebase`, known HTTP clients + hostnames), visible copy strings in entry points

### Read limits
- Do not read deep implementation files. Stay at manifest + entry-point level. If a claim requires deeper reading to verify, mark `[inferred]` with the reason rather than reading deeper — the founder resolves at review.
- Do not read `node_modules/`, `.git/`, `build/`, `DerivedData/`, `dist/`, `target/`, `Pods/`, `vendor/`, `.venv/`, or any folder that looks vendored or generated.
- Total audit should complete in 10-25 minutes of LLM time on typical projects.

### Identify
- **Technical claims**: language, framework, state management, data layer, build system, test framework
- **Product-signal claims**: inferences about what the product does and who it's for, based on route names, user-table fields, external API integrations, and visible copy strings

## Verify-or-Correct Framing

The audit brief may contain founder claims to verify. **Framing is deliberate and non-negotiable**:

- Treat each founder claim as a hypothesis to **verify or correct**, not as authoritative fact.
- For each claim, report one of:
  - `confirmation` — evidence in code matches the claim (cite file and line)
  - `contradiction` — evidence in code disagrees with the claim (cite what was found instead)
  - `no-evidence` — nothing in the audit scope speaks to this claim (do not guess)

**Why the framing matters**: a brief framed as "look for evidence of X" primes the LLM to find X even when X is wrong. A brief framed as "verify or correct X" preserves honest reporting. Example — if the founder says "we use Postgres" but the code uses SQLite, a verify-or-correct audit reports `contradiction: no Postgres drivers imported; sqlite3 present in package.json`. A look-for-evidence audit might report "inferred Postgres from a pg package reference" when that reference was an abandoned migration attempt.

## Binary Confidence Tagging

Every technical and product-signal claim in the audit output carries one of two tags:

- `[verified]` — observed in a manifest, config, import, or concrete code location. Cite the file path as evidence.
- `[inferred]` — derived from patterns (file names, directory structure, naming conventions) without reading implementation. Cite the pattern as evidence.

Three levels (high/medium/low) were considered and rejected — they drift at the medium/low boundary. Binary is sufficient for the attention-focus goal.

## Skipped-List Disclosure (mandatory)

Every audit output includes a `## Skipped` section listing what was NOT read and why. Categories:
- Vendored dependency directories (`node_modules/`, `Pods/`, `vendor/`) with approximate size if obvious
- Build artifacts and generated code (`DerivedData/`, `dist/`, `build/`, `target/`)
- DSL-heavy directories that require dedicated interpretation (`terraform/`, `fastlane/`, `expo/`, `nx-workspaces/`)
- Anything judgment-called as out-of-scope, with the reason

The founder uses this list to confirm "that's the whole surface area" at review time. Omitting the list is a protocol violation — it re-opens the polyrepo-with-vendored-deps, server-rendered monolith, mid-refactor, and DSL-heavy failure modes that shallow audits otherwise miss.

## Design System Starter Scaffold

If Grep finds any of `components/`, `ui/`, `design-system/`, `tokens/`, `theme/` folders, Developer writes a starter `knowledge-base/design-system-reference.md` listing the found folders and their top-level file structure. This unblocks Sprint 1 UI/UX work from duplicating existing components.

The starter is explicitly a scaffold — UI/UX curates it in a later sprint (task auto-queued by PM to Sprint 2 backlog). The starter must be labeled as such at the top of the file so downstream readers know it is not yet curated:

> **Starter scaffold from onboarding audit. UI/UX to curate in Sprint 2.**

If no design-system folders are detected, do not write the file.

## Handling Ambiguity

When structure is ambiguous (e.g., mid-refactor: two state libraries imported), the audit:
1. Picks the most-referenced option based on import counts
2. Records the choice explicitly in the `## Assumptions` section of the output
3. Notes the competing evidence (e.g., "Redux still imported in 12 files; Zustand in 47 — treating Zustand as current")

The founder resolves ambiguity at review; the audit does not hide it.

## Principles

1. **Honest reporting over plausible synthesis**: when evidence is insufficient, report `[inferred]` with the reason or `no-evidence` for a founder claim. Do not guess. An honest `[inferred]` is a feature; a polished `[verified]` built on weak evidence is a failure mode.
2. **Read-only, no side effects**: bootstrap mode's tool restrictions are not a suggestion. If the audit seems to require a Bash or Edit, stop and note what information would be needed rather than acquiring it by running commands. The restriction is load-bearing — it's how the setup script's "will NOT modify your source code" promise is kept.
3. **Shallow + disclosed beats deep + opaque**: reading fewer files honestly is more trustworthy than reading many and losing track. Cite every verified claim with a specific file path; every inferred claim with a specific pattern.
4. **Architecture shape, not implementation detail**: the audit describes what the product is made of, not how it works. When a Developer task later needs implementation detail for a specific feature, that task reads that file then.

## Output

Two files under `knowledge-base/`:

### `knowledge-base/.muster-onboarding/architecture-audit-notes.md` (transient; PM retires at T+140)

```markdown
# Architecture Audit Notes (Transient)

## Web (apps/web/)
| Claim | Tag | Evidence | Founder action |
|-------|-----|----------|----------------|
| Language: TypeScript 5.3 | [verified] | package.json devDependencies; tsconfig.json present | |
| Framework: Next.js 14 (App Router) | [verified] | next.config.js; app/ directory with layout.tsx | |
| State: Zustand | [inferred] | zustand in dependencies; `useStore` imports seen in pages — did not trace full state flow | |

## Backend (supabase/functions/)
| Claim | Tag | Evidence | Founder action |
|-------|-----|----------|----------------|
| Runtime: Deno | [verified] | deno.json present; Deno.serve() in function entry | |
| Database: Supabase/Postgres | [verified] | @supabase/supabase-js imported; migration files in supabase/migrations/ | |
| Auth pattern: JWT verification | [inferred] | `getUser()` calls in functions; did not verify full auth flow | |

(Additional sections per code area — iOS, Android, CLI, library, etc. — follow the same table structure.)

## Founder claims verified against code (if brief included any)
- Claim: "we use Postgres" → result: `confirmation`. Evidence: @supabase/supabase-js in deps; postgres migration files present.
- Claim: "we're migrating off Redux" → result: `confirmation`. Evidence: both redux and zustand in dependencies; zustand in 47 files, redux in 12.
- Claim: "we're mobile-first" → result: `no-evidence`. Nothing in audit scope speaks to mobile-first design — only a web app was found. Founder resolves at review.

## Skipped
- `node_modules/` (vendored JS dependencies)
- `.next/` (Next.js build output)
- `supabase/.temp/` (local Supabase state, generated)
- `terraform/` (DSL — infra not audited; separate concern)
- For iOS-heavy projects, also skip `Pods/`, `DerivedData/`, `fastlane/`; for Android, `build/`, `.gradle/`; for Python, `.venv/`, `__pycache__/`; for Rust, `target/`. Adapt the skipped list to the stack.

## Assumptions the audit made
- Mid-refactor in state management: treated Zustand as current per import counts (see Founder claims above).
- Monorepo structure: treated `apps/web/` and `supabase/functions/` as separate code areas; audited each independently.

## Product signals (for ground-truthing vs questionnaire)
- Route names: /onboarding, /dashboard, /billing, /settings
- User table fields: user_id, email, subscription_tier, team_id
- External APIs: Stripe, Segment, Supabase
- Copy strings: "Upgrade your team plan", "Invite teammates"
```

The example above uses a web + backend project. The same structure applies to iOS, Android, CLI, desktop, or any combination — headers and evidence adapt to the stack, but tag semantics (`[verified]` / `[inferred]`) and section structure are identical.

Founder action column is left empty; founder fills at review (per `reverse-discovery.md` § review-gates).

### `knowledge-base/design-system-reference.md` starter (optional)

Written only if design-system folders are detected. Top of file must contain: `> **Starter scaffold from onboarding audit. UI/UX to curate in Sprint 2.**` Lists found directories and their top-level file structure. No curation, no opinions on what should be used — just a discoverability aid for Sprint 1 Developer work.

## What This Skill Is Not

- Not a standard Developer task. Runs only in bootstrap mode, only during existing-project onboarding, only once per project.
- Not a code review. It does not evaluate code quality, style, or correctness.
- Not a substitute for reading files during real work. When a Sprint 1 task touches a specific file, the task-scoped Developer reads that file then — this audit captures shape, not internals.
- Not subject to the standard pre-handoff confidence-tagging requirement. Confidence tags are an onboarding-only construct.
