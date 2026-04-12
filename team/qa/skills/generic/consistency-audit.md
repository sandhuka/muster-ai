# Cross-File Consistency Audit

## Purpose
Systematic cross-file validation at sprint boundaries. Catches inconsistencies between product-spec, architecture, design specs, agent CLAUDE.md files, and legal docs before they become implementation bugs.

## When to Run
- Before any sprint where Developer will consume knowledge-base files for new implementation
- After any cascade that touches 3+ files
- At PM's discretion before milestone gates (beta, submission)

## Audit Dimensions

### 1. Feature ID Consistency
Grep all `F-[A-Z]+-[0-9]+` across `knowledge-base/` and `team/`. Cross-reference every unique ID against `product-spec.md` Section 5. Flag:
- IDs not in product-spec (phantom IDs)
- IDs that appear in product-spec but not architecture.md feature mapping (missing from architecture)
- IDs used in one file but a different ID for the same feature in another (collision)

### 2. Terminology Drift
Grep for known drift terms. Current watchlist:
- `CDN` — should be "Supabase Storage" except when qualified as "built-in CDN" or "Supabase Storage CDN"
- `video clip`, `clip stitching` — should be "looping animation" or "animated WebP loop"
- `fully local` without qualifier — should specify "user data fully local" (exercise assets load remotely)
- `FOUNDER INPUT NEEDED` — check if any reference decisions already made (grep decision-log.md for the topic)

### 3. Data Model Field Alignment
Compare Exercise metadata schema (product-spec.md Section 5C) vs architecture.md Section 5 (SwiftData models + enums). Verify:
- All product-spec enum values exist in architecture enum definitions
- Field names match (or have documented mapping)
- Nullable/required matches between local SwiftData models and Supabase PostgreSQL schema

### 4. Foundational Assumption Touchpoint Verification
Read `foundational-assumptions.md`. For each active assumption, spot-check the 2 most critical touchpoint files listed. Verify the file actually reflects the assumption's statement. Priority: A-001 (free tier), A-002 (Supabase Storage), A-003 (iOS version).

### 5. Design Spec ↔ Product Spec Alignment
For each design spec the Developer will consume in the upcoming sprint:
- Verify feature IDs match product-spec
- Verify acceptance criteria are not contradicted
- Verify TA component references exist in `design-system-reference.md`

### 6. Consumer Agent Task Reference Accuracy
Read the consuming agent's CLAUDE.md (usually Developer). For each current task:
- Verify every "Key refs" file path exists
- Verify section numbers point to the correct content
- Verify orchestration queue prompt matches CLAUDE.md task acceptance criteria

## Output
QA files findings as a request in `agent-requests.md` (Type: request, To: PM). PM fixes in place. If no issues found, QA notes "consistency audit: clean" in the session handoff.
