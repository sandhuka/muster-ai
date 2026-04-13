# Deliverable Review Skill

## Purpose
Methodology for reviewing agent handoffs filed in `knowledge-base/agent-requests.md`. Complements `agent-management.md` (stale thresholds, revision escalation) and `decision-making.md` (accept/reject autonomy). The agent's pre-handoff self-review checklist lives in `knowledge-base/system-guide.md` — this skill is the PM's independent verification.

## Universal Review Checklist
Run every item against every deliverable, regardless of producing agent.

1. **Terminology match**: Grep the deliverable for terms that contradict `product-spec.md` and `foundational-assumptions.md`. Common drift patterns: "CDN" vs. "Supabase Storage", "video clips" vs. "looping animations", "clip stitching" vs. "asset pipeline".
2. **Feature ID validation**: Every F-XXX-N referenced must exist in `product-spec.md`. A phantom ID means the agent hallucinated scope.
3. **Acceptance criteria**: Compare against acceptance criteria in `current-sprint.md`. Every criterion must be addressed — partial coverage is a revision.
4. **Cross-reference accuracy**: Spot-check at least 2 citations to other knowledge-base docs. Confirm the referenced section exists and says what the deliverable claims.
5. **Internal consistency**: Scan for contradictions within the deliverable (e.g., a data model describing fields the API section doesn't use).
6. **Foundational assumptions**: Check against active assumptions in `foundational-assumptions.md`. Flag violations even if the agent didn't mention assumptions.
7. **Scope boundaries**: No features, tiers, or platforms outside current MVP scope without PM approval.

## Per-Agent Review Focus

### Developer
- Architecture patterns match `architecture.md` (layers, naming, data flow)
- **Model/struct drift**: Diff any code structs or data models against their `architecture.md` definitions. Flag type mismatches, renamed fields, or missing properties — update the doc or the code before accepting.
- No custom UI — all interface code uses shared UI library components and tokens
- Edge cases addressed (offline, empty states, error handling, migration paths)
- Performance implications called out for O(n)+ operations on user-facing paths

### UI/UX
- Only tokens from `design-system-reference.md` (project's design token convention — e.g., Color.primary, Font.heading, Spacing.medium)
- Missing components filed in `ui-component-requests.md` before or alongside the handoff
- Flows cover error, empty, and loading states — not just the happy path

### Content
- Voice and tone match `brand-guidelines.md` and character personalities
- Copy length fits UI context (buttons, cards, notifications have tight limits)
- No health claims that could create liability
- **Copy change cascade**: If the Content agent changed placeholder or pre-approved copy text to different final copy (e.g., "Want another session?" became "Add another session"), grep the repo for the old text and update all references. Content copy is quoted verbatim in design specs, product spec, agent-context files, orchestration queue prompts, and QA acceptance criteria. A copy change that isn't cascaded causes the Developer to implement the wrong text or QA to test against stale copy

### Legal
- Cites specific regulations or App Store guidelines, not general caution
- Drafts are actionable (ready for founder review), not frameworks
- Scope matches actual data practices, not generic boilerplate

### Marketing
- Claims substantiated by research files or product-spec
- Metrics grounded in research benchmarks
- Channel recommendations account for solo-founder resource constraints

### QA
- Covers all acceptance criteria from `product-spec.md` for in-scope features
- Device/OS matrix specified, not assumed
- Regression scope defined

### Research
- Distinguishes data-backed findings from analyst judgment
- Sources cited and verifiable
- Actionable next steps — PM should be able to decide immediately after reading

## Review Depth Calibration

**Accept**: All 7 checklist items pass, per-agent focus areas clean.

**Accept with notes**: Minor issues that don't block downstream work (1-2 terminology inconsistencies in non-critical sections, formatting). Add notes to revision log, set status to `done`. Don't force a revision cycle for cosmetic issues.

**Request revision**: Any checklist failure that would propagate to downstream agents or the founder. List every issue in a single revision note — never trickle issues across multiple rounds.

## Post-Accept Housekeeping

After accepting a handoff (status → `done` or PM reviewer checked), PM must immediately:

1. **Mark the producing agent's task `[x] DONE`** in their agent-context file (`knowledge-base/agent-context/<agent>.md`) Current Tasks section, with date and HO reference.
2. **Add to `current-sprint.md` Done table** if not already there.

These updates prevent agent-context files from going stale — the agent-context file is what the agent reads on next invocation, so unchecked tasks cause it to re-attempt completed work or misunderstand its current state.

3. **Sprint/wave close-out sweep**: When closing multiple handoffs or completing a wave/sprint, grep all `knowledge-base/agent-context/*.md` files for `- [ ]` and cross-check each against `current-sprint.md` Done table. Every task in Done must be `[x]` in the agent's agent-context file. This catches the batch-update gap where individual post-accept updates are skipped during rapid multi-handoff processing.

## One-Pass Rule

1. **Full read first.** Read the entire deliverable before noting issues. A flag on page 2 may be resolved on page 5.
2. **All source docs, not just the obvious one.** Check against product-spec, foundational-assumptions, brand-guidelines (terminology), and domain-specific docs (architecture.md, design-system-reference.md).
3. **Scope boundaries last.** Scope creep is easiest to spot after you understand what the deliverable does.

## Review Principles
- **The agent's self-review is not your review.** PM review catches cross-document alignment issues the agent may not have context for.
- **One revision with all issues beats three with one each.** Every revision cycle costs a full agent session. Batch ruthlessly.
- **Accept-with-notes is underused; revision is overused.** If the issue won't cause downstream agents to produce wrong output, it's a note, not a revision.
- **Review for correctness, not style.** Reformatting agent output to match preferences is PM scope creep.
