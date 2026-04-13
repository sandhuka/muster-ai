# Cross-File Consistency Audit

## Purpose
Systematic cross-file validation at sprint boundaries. Catches inconsistencies between product-spec, architecture, design specs, agent-context files, and legal docs before they become implementation bugs.

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
Grep for known drift terms. Maintain a product-specific watchlist of terms that have been renamed or clarified. Common drift patterns:
- Infrastructure terms that changed (e.g., old service name vs. current service name)
- Content format terms that evolved (e.g., old format name vs. current format name)
- Architecture qualifiers that need precision (e.g., "fully local" may need scoping to "user data fully local" if some assets load remotely)
- `FOUNDER INPUT NEEDED` — check if any reference decisions already made (grep decision-log.md for the topic)

Check your product skill file for the specific watchlist.

### 3. Data Model Field Alignment
Compare the canonical data model in product-spec vs the implementation schema in architecture.md. Verify:
- All product-spec enum values exist in architecture enum definitions
- Field names match (or have documented mapping)
- Nullable/required matches between local models and [backend] schema

### 4. Foundational Assumption Touchpoint Verification
Read `foundational-assumptions.md`. For each active assumption, spot-check the 2 most critical touchpoint files listed. Verify the file actually reflects the assumption's statement. Prioritize assumptions that affect the free/premium boundary, infrastructure dependencies, and platform version targets.

### 5. Design Spec ↔ Product Spec Alignment
For each design spec the Developer will consume in the upcoming sprint:
- Verify feature IDs match product-spec
- Verify acceptance criteria are not contradicted
- Verify TA component references exist in `design-system-reference.md`

### 6. Consumer Agent Task Reference Accuracy
Read the consuming agent's agent-context file (`knowledge-base/agent-context/<agent>.md`), usually Developer. For each current task:
- Verify every "Key refs" file path exists
- Verify section numbers point to the correct content
- Verify orchestration queue prompt matches CLAUDE.md task acceptance criteria

## Output
QA files findings as a request in `agent-requests.md` (Type: request, To: PM). PM fixes in place. If no issues found, QA notes "consistency audit: clean" in the session handoff.
