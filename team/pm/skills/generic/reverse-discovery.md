# Reverse Discovery (Existing-Project Onboarding)

## Purpose
Procedural methodology for PM to conduct existing-project onboarding — the reverse of Muster's greenfield discovery flow. This skill runs once per project, takes ~120-140 minutes of founder-attended time, and produces a populated knowledge base + Sprint 1 plan. See `team/developer/skills/generic/codebase-audit.md` for the Developer-side audit procedure this skill invokes; see `team/pm/skills/generic/context-cascading.md` for the JIT cascade applied to Sprint 1 agents at the end of this flow; see `team/pm/skills/generic/sprint-planning.md` for the standard sprint planning this skill hands off to.

## When This Skill Runs

PM reads this skill when:
1. At session start, PM reads `knowledge-base/agent-context/.populated` (per Root Claude bootstrap behavior) and finds it has **any `null` entries**.
2. Before producing any user-facing output, PM must have this skill loaded. This is mandatory — see CLAUDE.md bootstrap behavior for the rule.

**Missing-skill fallback**: if this file is missing or unreadable when PM attempts the read, PM halts with:
> "Muster onboarding skill not found at `muster/team/pm/skills/generic/reverse-discovery.md`. Check submodule version with `git submodule status muster`, pull latest with `git submodule update --remote muster`, or re-run `scripts/setup-existing-project.sh`. Onboarding cannot proceed without this skill."

Do not silently skip, do not improvise.

## User-Facing Stage Numbering (READ BEFORE ANNOUNCING ANYTHING)

The 11 phases below are **internal**. They include housekeeping (CLAUDE.md merge, `.claude/agents/` merge, cleanup) that the founder doesn't track as work. **Never announce "Phase N" to the founder** — it produces jarring jumps (e.g., "Phase 1 → Phase 4" looks like 2 and 3 were skipped). Use **Stage 1-6** instead, matching the agenda the founder saw in the Phase 1 orientation message.

| Internal phase(s) | User-facing label |
|---|---|
| Phase 4 | **Stage 1: Brain-dump** |
| Phase 5 + Phase 6 | **Stage 2: Code audit** |
| Phase 7 | **Stage 3: Audit review** |
| Phase 8 | **Stage 4: Questionnaire** |
| Phase 9 | **Stage 5: Draft review** |
| Phase 10 | **Stage 6: Sprint 1 plan** |

Phases 2, 3, and 11 are **housekeeping** — announce as plain prose with no Stage label (e.g., *"Just checking for a pre-Muster CLAUDE.md to merge — none found, moving on."*).

### Stage-transition format (verbatim structure)

When transitioning between user-visible stages, use this exact markdown structure. It mirrors the setup-script's terminal aesthetic (cyan-bold section headers, green-bold ✓ on completion) via Claude Code's markdown rendering:

```
---

## ✓ Stage [N-1]: [Name] complete

[1-line summary of what got captured / saved / decided]

---

## Stage N: [Name] (~[time] · [your role])

[Stage intro / instruction]
```

`[your role]` is one of: *focus*, *mostly waiting*, *quick check*. Examples:
- `## Stage 2: Code audit (~15 min · mostly waiting)`
- `## Stage 3: Audit review (~20 min · your focus)`
- `## Stage 6: Sprint 1 plan (~5 min · quick check)`

The `---` divider before AND after the completion line creates the same visual break the script's `━━━` dividers do for Step 1 / Step 2. The `✓` glyph mirrors the script's green checkmarks.

## Phase 1: Pre-Merge Orientation (T+4, ~90 seconds, non-skippable)

Deliver this verbatim (substitute the product name if the founder has already identified their domain). Markdown formatting is intentional — Claude Code renders it for visual hierarchy.

> # ✨ Welcome — let's set up your AI team
>
> Over the next ~2 hours, we're going to turn your project into a place where **a coordinated team of specialist AI agents** can actually work together — knowing your product, your code, and your decisions, sprint after sprint.
>
> ## What you're getting
>
> Seven specialists — **Developer, UI/UX, QA, Content, Marketing, Legal, Research** — coordinated by me as your product manager. Every decision logged. Every sprint planned. No re-explaining your product to a fresh AI chat ever again.
>
> **Why it's worth the next 2 hours:** every sprint after this one is fast. The agents already know your product. You spend your time shipping, not re-onboarding.
>
> ## How today works (6 stages)
>
> - **Stage 1 — Brain-dump** (~25 min) · *Highest leverage* — Tell me everything you know about the product. Paste docs, ramble, drop links.
> - **Stage 2 — Code audit** (~15 min) · *Mostly waiting* — I read through your codebase.
> - **Stage 3 — Audit review** (~20 min) · *Your focus* — We walk through what I found together.
> - **Stage 4 — Questionnaire** (~15 min) — I ask about anything the brain-dump didn't cover.
> - **Stage 5 — Draft review** (~15 min) — You read the product spec / brand guidelines / assumptions I've drafted.
> - **Stage 6 — Sprint 1 plan** (~5 min) — You name the first feature; we start working.
>
> ## One thing before we begin
>
> In **Stage 3**, every claim I make about your code will be tagged `[verified]` (I saw it directly) or `[inferred]` (I guessed from patterns — file names, imports, directory structure). I'll ask you to confirm or correct each `[inferred]` row.
>
> **Why slow down here:** approve a wrong guess and your team builds on a bad assumption — rework surfaces days later. The tag is your one signal to pause. Everything else moves fast.
>
> ---
>
> **Ready?** Say *"go"* — or jump straight in with your first thoughts about the product. The more you share, the less the team has to guess.

**Rationale**: lead with value framing ("let's set up your AI team", future-state benefit) before agenda; agenda before technical concept; technical concept anchored by single concrete consequence, not front-loaded as anxiety. Markdown rendering creates visual rhythm in the terminal — section headers, agenda list with inline middle-dot annotations, divider before kickoff. Human-psychology levers: ownership ("your AI team"), reciprocity (PM does the heavy lifting, founder reviews), specificity (clear timeboxes), loss reframe (the time is deposited toward future speed, not spent), social proof avoided (would feel hollow). Total ~210 words; experienced founders scan in 30 seconds and proceed. Honesty preserved: no overclaiming, single concrete failure mode for `[inferred]` discipline, gentle close.

## Phase 2: CLAUDE.md Content-Triage + Merge (T+6)

Executes only if `.muster-archive/CLAUDE.md.pre-muster` exists (founder had an existing CLAUDE.md before setup).

### 2.1 Content triage pass (before rule classification)

PM identifies content in the archived CLAUDE.md that semantically belongs in a different knowledge-base file and offers to route it:

| Content pattern | Destination file |
|-----------------|------------------|
| Brand tone, voice, writing style, persona | `knowledge-base/brand-voice-guide.md` |
| Visual / color / spacing / typography guidelines | `knowledge-base/brand-guidelines.md` |
| Testing philosophy or strategy | `knowledge-base/test-strategy.md` |
| Architecture or system-design notes | `knowledge-base/architecture.md` (merged with audit output later in Phase 8) |
| Foundational product assumptions | `knowledge-base/foundational-assumptions.md` |

**Batch-by-destination approval** (symmetric to orthogonal-rule batch in 2.2): when multiple items route to the same destination, PM presents them grouped:
> "5 items route to `brand-voice-guide.md`. Review list: [quoted excerpts]. Approve all routing, review item-by-item, or reject all?"

One decision for homogeneous destinations; per-item only for mixed or ambiguous cases.

**Rule 15 compliance is mandatory**: routed content lands in destination files as **current truth**, restructured into the destination's native format. No "From user's original CLAUDE.md:" attribution, no "originally in CLAUDE.md," no "added during onboarding" phrasings. Destination files (`brand-voice-guide.md`, `brand-guidelines.md`, `test-strategy.md`, `architecture.md`, `foundational-assumptions.md`) are all Rule 15 durable artifacts. Merge history lives in git commit messages and `.muster-archive/`, not in the durable files.

For `brand-voice-guide.md` and `test-strategy.md` specifically: PM writes a stub if the triage produced content, but defers to Content (for brand-voice) or QA (for test-strategy) for final authoring via Task tool invocation in Phase 8.

### 2.2 Rule classification pass

After triage, whatever CLAUDE.md content remains is classified. Enumerate every user-custom rule, instruction, or behavioral directive. Classify each:

- **Replaces Muster Rule X** — user's rule semantically overrides a specific Muster rule
- **Adds to Muster** — user's rule is net-new behavior Muster doesn't cover
- **Orthogonal** — user's rule is unrelated to Muster protocols (preferences, formatting, style)
- **Conflicts** — user's rule is incompatible with a Muster rule and one must win

### 2.3 Two-tier decision flow (prevent fatigue, preserve safety)

- **Orthogonal** rules: batch-approved. Cannot conflict with Muster by definition. Present as a list; one decision ("approve all?").
- **Adds** rules: batch-approved unless founder wants to review; they add behavior without displacing anything.
- **Replaces / Conflicts** rules: **per-rule decision required**. No batch. Each needs individual acknowledgement: keep-user / keep-muster / merge-both / edit. These are where silent precedence loss actually hurts.

### 2.4 Three-section output template

Merged CLAUDE.md has exactly three sections:

1. `## Muster Framework` — preserved from Muster template verbatim. This is a **pointer**, not a copy of the 15 rules. Contains a short description of Muster, a directive to read `muster/CLAUDE.md` for authoritative rules, the submodule-missing fallback instruction, PM mode section, and system reference. Never copy the 15 rules here.
2. `## Product Information` — from founder-provided content (triage leftovers + brain-dump + questionnaire + audit will fill this later).
3. `## Project-Specific Rules` — user-authored rules from classification. Current-truth format: "Rule 9 (this project): [rule text]." No "overridden by" or "changed from" phrasings.

Present unified diff + any routed-content files to founder. Founder approves, edits, or rejects. On approval, PM writes the final files. `.muster-archive/CLAUDE.md.pre-muster` remains for reference.

## Phase 3: `.claude/agents/` Merge (T+24)

Executes only if `.muster-archive/claude-agents.pre-muster/` exists.

- Review each archived custom agent file.
- Identify custom behaviors (deviations from Muster's standard agent templates).
- Offer to merge those behaviors into the corresponding Muster agent bootloader (e.g., custom `@developer` quirks merge into the project's `.claude/agents/developer.md`).
- Custom agents that don't map to a Muster role (e.g., a user-created `@security` agent) are preserved as-is alongside Muster's agents.
- Per-agent founder approval before writing.

## Phase 4: Brain-Dump + Doc Ingest (T+30)

### 4.1 Prompt (verbatim, one prompt — wait for response)

> "Before I start looking at your code, tell me what I should know about this product. This is the highest-leverage step of the whole onboarding — every minute you spend here produces a sharper knowledge base. Talk, write, paste, drop files — no structure needed. Useful input: what it does, who it's for, what you've built, what you've tried and discarded, what you hate about competitors, what 'done' looks like, what you don't want me to assume. Take as long as you want — the more you share, the better everything downstream works. Type `done` when finished, or `skip` to move on (skip is fully supported; some founders have captured everything already, for everyone else the dump is where the time pays off)."

### 4.2 Capture

PM writes raw founder input verbatim to `knowledge-base/.muster-onboarding/founder-brain-dump.md`. This file is **transient** and **gitignored by default** (see §9.1 of the existing-project design — sensitive content may appear in dumps).

Before writing the first line, PM surfaces: "I'm about to save what you paste to a file. Take a second to check for anything sensitive (keys, secrets, internal IDs) before you share." Shifts the redaction burden to the founder at the right moment.

### 4.3 Doc ingest (interleaved, synthesize mode)

If founder pastes URLs, paths, Notion exports, or markdown files:
- Read each doc.
- Preview extracted claims: "From this doc, I extracted: [list]. Writing to these sections: [list]. Approve / reject / edit?"
- Per-doc review. Bad docs get rejected; good docs get absorbed into the structured claim list.

Reference mode and copy-in mode are rejected — they either create split sources of truth or cascade format mismatches. Synthesize + per-preview gate is the only supported mode.

### 4.4 Claim extraction

When founder types `done`, PM extracts structured claims from the raw material:
- **Product claims** → feed Phase 8 (product-spec.md draft)
- **Architecture / stack hints** → feed Phase 5 (audit brief) as claims to verify or correct
- **Anti-goals and don't-assume items** → feed Phase 8 (foundational-assumptions.md)
- **Contradictions within the dump** → surfaced explicitly: "earlier you said X, later you said Y — which is current?" Founder resolves before the claim moves downstream.

PM summarizes extracted claims back to founder for confirmation before using them downstream. This is the gate that prevents LLM mis-synthesis of long dumps.

**Dump-becomes-spec prohibition**: the dump's prose never lands verbatim in product-spec.md or any durable artifact. PM always extracts, restructures, and summarizes. The raw file is source material only. Concrete anti-example:

> ❌ product-spec.md contains: "The founder said: 'we target busy parents of 5-10 year olds who want screen-time alternatives.'"
>
> ✓ product-spec.md contains: "Target users: parents of 5-10 year olds seeking screen-time alternatives."

No >10-word run should appear verbatim between the dump and the spec.

## Phase 5: Audit Brief + Developer Invocation (T+55)

### 5.1 Write audit-brief.md

PM writes `knowledge-base/.muster-onboarding/audit-brief.md`:

```markdown
# Audit Brief (Bootstrap Mode Input)

## Audit scope
Read top-level dirs (2 levels), package manifests, 3-5 entry-point files per code area (platform, service, package — whatever the project's natural units are). Grep for design-system folders and product signals. Do not read vendored/generated dirs.

## Founder claims to verify or correct (if any)
- "[quoted claim 1]" — verify or correct against code; report `confirmation` / `contradiction` / `no-evidence` with cited evidence
- "[quoted claim 2]" — same
- ...

## Skipped-list disclosure requirement
Output must include `## Skipped` section listing what was NOT read and why.

## Output path
Write final audit to: `knowledge-base/.muster-onboarding/architecture-audit-notes.md`
If design-system folders detected, also write starter `knowledge-base/design-system-reference.md` with "Starter scaffold from onboarding audit. UI/UX to curate in Sprint 2." header.
```

Framing is deliberate — claims to **verify or correct**, not evidence to find. See `codebase-audit.md` for the framing rationale.

### 5.2 Invoke Developer

Invoke via Task tool with `subagent_type="developer"`. The audit is never performed inline by Root Claude — bootstrap mode's tool restrictions depend on this invocation pattern.

Wait for Developer's audit to complete (~10-25 min LLM time). Developer writes to `.muster-onboarding/architecture-audit-notes.md` (and optionally `design-system-reference.md` starter). Bootstrap mode tool restrictions keep the audit read-only.

## Phase 6: Audit Review + Architecture Finalize (T+75)

### 6.1 Surface-area confirmation

Present the `## Skipped` section from audit-notes to founder:
> "Here's what the audit did NOT read: [list]. Does this cover your whole codebase? Any subsystem missing?"

Founder confirms. This catches polyrepo-with-vendored, mid-refactor, and DSL-heavy cases that shallow audit otherwise misses.

### 6.2 Per-item forcing function

Walk founder through every `[inferred]` row. For each, founder must type one of:
- `verified` — claim is correct
- `wrong: <correction>` — claim is wrong; correction provided
- `don't-know` — founder genuinely doesn't know

"Approve all" is **not offered** for `[inferred]` rows. `[verified]` rows don't require action (founder can still override).

### 6.3 Finalize architecture.md

After all rows are resolved:
- `verified` claims → stay in `knowledge-base/architecture.md`
- `wrong: X` claims → corrected to X in `architecture.md`
- `don't-know` claims → **removed from `architecture.md`** and appended to `knowledge-base/pre-launch-checklist.md` as "Verify [X] before launch." Rule 10 governs milestone-gate review.

**Do NOT write don't-know items to `foundational-assumptions.md`** — that file is Rule 15 durable and must describe current-truth only. `pre-launch-checklist.md` is the right destination.

Architecture.md is written as current-truth, no `[verified]` / `[inferred]` tags, no archaeology. Tags and audit notes stay in the transient `architecture-audit-notes.md` until cleanup at Phase 11.

## Phase 7: Adaptive Questionnaire (T+97)

### 7.1 Pre-fill from brain-dump

For each of the 12 questionnaire items, check if a brain-dump extracted claim already answers it. If yes, pre-fill with "Based on what you said earlier: [quote]. Confirm / edit / replace." If no, ask fresh.

On a verbose brain-dump, the questionnaire can shrink to 3-5 real questions. On `skip`, all 12 are asked.

### 7.2 Questions (stable reference list)

1. One-line elevator pitch: what is this product?
2. Who is it for? (1-3 sentences)
3. What's the core problem it solves?
4. What's built already? (1-3 bullets)
5. What's NOT built yet but planned? (1-3 bullets)
6. Monetization model (free / freemium / subscription / paid-up-front / not-yet / other)
7. Platforms live today (iOS / Android / web / backend — deployed vs in-progress)
8. Primary platform — if one leads, which?
9. Current state: pre-launch / beta / live-with-users / scaling
10. Team model: solo / solo + AI agents / small team / small team + AI agents
11. Next big milestone (1-2 sentences)
12. Anything the LLM should NOT assume or guess about your product?

### 7.3 Research off-ramp

At the top of the questionnaire AND at any question the founder can't answer confidently, offer:
> "Want Research to do a 20-minute market check on your positioning / users / competition? Or skip for now?"

Default is offer-not-force. If founder accepts, invoke Research via Task tool with `subagent_type="research"` and wait for their output before proceeding. Research uses `team/pm/skills/generic/product-evaluation.md` methodology.

## Phase 8: Product Synthesis (T+115)

### 8.1 PM writes (direct)
- `knowledge-base/product-spec.md` — using `team/pm/skills/generic/product-spec-writing.md`. Inputs: questionnaire answers + brain-dump extracted claims + ingested docs.
- `knowledge-base/brand-guidelines.md` — using `team/pm/skills/generic/brand-guidelines.md`. Inputs: any visual/brand content from triage + brain-dump/questionnaire.
- `knowledge-base/foundational-assumptions.md` — current-truth assumptions only. See "Foundational Assumptions Authoring" below.

### 8.2 Delegated writes (via Task tool)

- **Content writes `brand-voice-guide.md`** if Phase 2.1 triage routed brand-voice content, OR if brain-dump/questionnaire surfaced voice material. Invoke Content via Task tool with `subagent_type="content"`, pass the triage+extracted voice material as input. Content uses `team/content/skills/generic/brand-voice.md`.
- **QA writes `test-strategy.md`** if Phase 2.1 triage routed testing content. Invoke QA via Task tool with `subagent_type="qa"`, pass the triage material as input. QA uses `team/qa/skills/generic/test-strategy.md`.

If no content was routed to these destinations and nothing in the brain-dump/questionnaire covers them, skip — these files can be created in a later sprint when there's real material.

### 8.3 Foundational Assumptions Authoring (no dedicated skill — authored here)

`foundational-assumptions.md` captures cross-cutting assumptions that every agent must know. Sources:
- Anti-goals / don't-assume items from brain-dump ("We are NOT building a social network, even though we have user profiles.")
- Questionnaire item 12 answers
- Triage-routed foundational content from CLAUDE.md

**Rule 15 discipline is strict here** (foundational-assumptions.md is on Rule 15's durable list):
- Each assumption is a forward-looking current-truth statement
- No "founder said," "captured during onboarding," "inferred from X" phrasings
- If an assumption needs verification (founder is uncertain whether it holds), it goes in `pre-launch-checklist.md`, not here

**Format**:
```markdown
## <Assumption category>

- <Assumption as current-truth statement>
  - Touchpoints: <files/agents that depend on this>
```

### 8.4 Product-signal ground-truthing

Compare audit's product-signal findings (from `architecture-audit-notes.md`'s "Product signals" section) against founder's stated intent (brain-dump + questionnaire). Present divergences explicitly:
> "You said B2B SaaS targeting enterprise teams. The code has these signals: [route names: /consumer-dashboard], [user table fields: is_premium_consumer], [copy: 'invite your friends']. Do these match?"

Founder resolves any divergence before cascade. If divergence is large, PM surfaces "the audit confirmed every claim you made" as itself a signal — unusual, may indicate the audit rationalized rather than verified. Escalate if so.

### 8.5 Founder review

Present `product-spec.md`, `brand-guidelines.md`, `foundational-assumptions.md` (and any delegated-write outputs) for founder read-through. Edit invitation, not per-item forcing. Founder largely wrote these via questionnaire + brain-dump, so review is sanity check, not error hunt.

**agent-context files are not separately reviewed** — they are derived from these source docs in Phase 9 and are cheap to fix later if errors surface during Sprint 1.

## Phase 9: Agent-Context Cascade (T+133)

Use `team/pm/skills/generic/context-cascading.md` methodology. Populate agent-context files **only for the agents needed for Sprint 1** — do not populate agents whose work isn't part of the first sprint; those stay `null` and populate lazily at first invocation (per `context-cascading.md` → `## Just-in-time mode` subsection).

**Which agents are Sprint 1 agents depends on project shape**, not a fixed list. Derive from the audit output + questionnaire + the first feature/task the founder names in Phase 10:

- **Product with UI surfaces** (web app, iOS, Android, desktop): typically Developer + UI/UX + QA + Content
- **Backend-only API / service**: typically Developer + QA; maybe Legal if compliance is in scope; UI/UX and Content are `null` until a consumer surface is added
- **CLI tool**: typically Developer + QA + Content (for help text and docs); UI/UX is `null`
- **Library / SDK**: typically Developer + QA; Content if there's developer-facing documentation in scope; UI/UX is `null`
- **Marketing site / static content project**: typically UI/UX + Content + Developer; QA is often lighter-weight
- **Research-heavy pre-launch project**: Research may be a Sprint 1 agent even though it's greenfield-typical

These are defaults, not rules. If Sprint 1 task requires a specific agent, populate that agent regardless of the defaults above. When in doubt, under-populate — JIT populate handles the agents added later with no cost beyond the ~30-60 second first-invocation delay.

After writing each populated agent-context file, update `.populated` with a timestamp for that agent. `.populated.onboarded_at` must already be set from setup script init (see §7.4 schema); verify it's present before finalizing Phase 9 — Rule 11's stub-accrued decision scan depends on it.

## Phase 10: Sprint 1 Planning + Sprint 2 Backlog (T+138)

### 10.1 Sprint 1

Use `team/pm/skills/generic/sprint-planning.md`. Ask founder: "What's the first feature/task you want to tackle? I'll plan Sprint 1 around it." Populate `knowledge-base/current-sprint.md` and `knowledge-base/orchestration-queue.md` with 3-5 steps.

### 10.2 Sprint 2 backlog (auto-queued)

Append two tasks to the Sprint 2 backlog (mechanical, not founder-dependent):
- "UI/UX: curate `brand-guidelines.md` (PM-drafted starter from onboarding)"
- "UI/UX: curate `design-system-reference.md` (audit-generated starter from onboarding)"

This prevents starter scaffolds from rotting in place.

## Phase 11: End-of-Onboarding Cleanup (T+140, mandatory)

Three steps in order:

### 11.1 Rationale distillation

Scan `knowledge-base/.muster-onboarding/founder-brain-dump.md` for durable-worthy "why we chose X over Y" rationale (past decisions, trade-offs, abandoned approaches). Extract each as a `decision-log.md` entry with date and rationale. `decision-log.md` is Rule 15-exempt, so direct extraction is safe.

This preserves founder-stated reasoning that would otherwise become inaccessible once the brain-dump is archived.

### 11.2 Atomic archive move

Run a **single Bash command** to move the entire transient directory:
```bash
mv knowledge-base/.muster-onboarding/ .muster-archive/onboarding-$(date +%Y-%m-%d)/
```

One atomic operation via rename syscall. Do not iterate file-by-file via Write+Delete — interruption would leave split state.

### 11.3 Post-move verification

Verify two conditions:
1. `knowledge-base/.muster-onboarding/` no longer exists (source gone)
2. `.muster-archive/onboarding-<date>/` contains the expected files: `founder-brain-dump.md`, `architecture-audit-notes.md`, and `audit-brief.md` if those were written during onboarding

If condition 1 fails (source still exists — interrupted before mv completed): retry step 11.2 and re-verify.

If condition 1 passes but condition 2 fails (source gone, target incomplete — possible when `.muster-archive/` is on a different filesystem and `mv` fell back to copy+delete which was interrupted): flag:
> "Onboarding cleanup completed but archive is incomplete. Source directory was removed but target `.muster-archive/onboarding-<date>/` is missing expected files. Restore from source if possible, or resolve manually."

If both pass: also delete `.muster-setup-state.json` (script-generated, not in `.muster-onboarding/`). Onboarding is complete.

## Principles

1. **Founder is the source of product truth; code is the source of implementation truth**: never invert. The audit verifies or corrects founder claims against code; the founder resolves ambiguity in spec content. Neither side gets to dictate the other.
2. **Per-item forcing function > batch approval, for inferred claims**: rubber-stamping is the dominant failure mode. Design the review UX so it's physically harder to approve a wrong claim than to read it. Exception: orthogonal rules and homogeneous triage destinations batch safely by definition.
3. **Current-truth in durable files, archaeology in transient files or git**: Rule 15 applies to every durable destination (`architecture.md`, `product-spec.md`, `brand-guidelines.md`, `brand-voice-guide.md`, `foundational-assumptions.md`, `test-strategy.md`, merged CLAUDE.md). Audit history lives in `architecture-audit-notes.md` (transient, archived at cleanup); decision history lives in `decision-log.md` and git commits. Never mix.
4. **Delegate to specialists via Task tool, don't do their work inline**: Developer audits, Content writes brand-voice, QA writes test-strategy, Research fills market gaps. Always invoke via Task tool with the right `subagent_type`. Inline execution blurs boundaries and bypasses specialist skills.
5. **Single source of truth for every artifact**: no content lives in two places. Triage routes content to its proper home; synthesize-mode doc ingest prevents external references; cleanup archives transients so they don't compete with durables.
6. **Cleanup is load-bearing, not optional**: transient files left in the workspace confuse future Claude sessions. The T+140 cleanup is mandatory; the atomic-mv + verification pattern prevents partial-state regressions.

## Output

Onboarding produces this final state in the project:

### Durable knowledge-base files (stay in steady state)
- `knowledge-base/architecture.md` — current-truth architecture, resolved from audit
- `knowledge-base/product-spec.md` — product spec from questionnaire + brain-dump + docs
- `knowledge-base/brand-guidelines.md` — basic brand guidelines (PM-drafted starter, UI/UX curates in Sprint 2)
- `knowledge-base/brand-voice-guide.md` — Content-authored, if material was available
- `knowledge-base/foundational-assumptions.md` — cross-cutting current-truth assumptions
- `knowledge-base/test-strategy.md` — QA-authored, if Phase 2.1 routed testing content
- `knowledge-base/design-system-reference.md` — audit-generated starter if design system detected (UI/UX curates in Sprint 2)
- `knowledge-base/pre-launch-checklist.md` — seeded with `don't-know` items from audit review
- `knowledge-base/decision-log.md` — seeded with merge decisions, Sprint 1 scope decision, distilled brain-dump rationale
- `knowledge-base/current-sprint.md` — Sprint 1 populated
- `knowledge-base/orchestration-queue.md` — 3-5 step queue + Sprint 2 backlog with curation tasks
- `knowledge-base/agent-context/<agent>.md` — populated for Sprint 1 agents; generic templates for others
- `knowledge-base/agent-context/.populated` — `onboarded_at` set; Sprint 1 agent timestamps set; others `null`
- `CLAUDE.md` (project root) — three-section merged file with Muster Framework pointer block

### Archived (not in steady-state workspace)
- `.muster-archive/CLAUDE.md.pre-muster` — user's pre-Muster CLAUDE.md
- `.muster-archive/claude-agents.pre-muster/` — user's pre-Muster `.claude/agents/` if any
- `.muster-archive/onboarding-<date>/` — entire former `.muster-onboarding/` directory: brain-dump, audit-brief, audit-notes

### Deleted
- `.muster-setup-state.json` — script checkpoint file

## What This Skill Is Not

- Not applicable to greenfield projects. Greenfield uses the existing `getting-started.md` flow + Research discovery. This skill is for projects with existing code + docs.
- Not re-run on subsequent Muster framework updates. `git submodule update --remote muster` pulls framework updates without repeating onboarding, though major framework additions (new rules, new agents) may prompt small manual updates to the project CLAUDE.md.
- Not a substitute for deliberate product work. The output is a starter knowledge base — agents will refine it through real sprints. First-sprint deliverables validate whether the reverse discovery produced trustworthy context; revisions are expected and healthy.
