# Wave Review
<!-- File-mediated I/O contract between the autonomous sprint loop and the founder at a wave gate. PM-owned. Tier-2: read on demand only (at a wave gate / on resume), never a startup read. -->
<!-- The loop does NOT parse this file. PM writes the Output block at the gate; the founder writes the Verdict block; PM reads the verdict on resume (muster/scripts/muster-sprint-resume.sh). Keeping human feedback here — not in the orchestration queue — is the seam a future remote/mobile bridge plugs into. -->

## Current Wave

<!-- PM writes this block when the loop hits a wave-gate halt step (or at planning). One entry per active gate; clear or archive once resumed. -->

**Wave:** [N — short name]
**Build at:** [worktree path, e.g. ../<proj>-sprint-auto-YYYYMMDD-HHMMSS]
**Verify (human-only checks):**
- [ ] [behavioral / visual check a reviewer must run the app to confirm]
- [ ] [check 2]
- [ ] [check 3]

### Notices since last gate
<!-- PM folds every live founder-notices.md entry here VERBATIM (or writes "none"). Checked by muster-lint-gate-packet.sh — a notice with no place to land depends on luck to surface. -->
none

## Verdict

<!-- Founder writes the verdict here, then runs muster/scripts/muster-sprint-resume.sh. Two forms: -->
<!-- APPROVE  — no bugs; PM removes the gate halt step and promotes the next wave's first step. -->
<!-- Bug list — PM inserts a fix step per bug, then continues. -->

**Status:** [approve | changes-requested]
**Findings:**
- [bug / finding 1 — what's wrong, where to see it]
- [bug / finding 2]
