#!/usr/bin/env bash
# muster-queue-lint.sh — deterministic structure check for orchestration-queue.md, run at sprint /
# wave planning closeout. Planning isn't "done" until the queue PARSES the way the autonomous
# driver (muster-sprint-run.sh) reads it. PM runs this and pastes the green result into the
# planning closeout (the structural analog of the test-suite gate for planning).
#
# Usage:  bash muster-queue-lint.sh [QUEUE]      (default: knowledge-base/orchestration-queue.md)
# Exit:   0 = well-formed (or idle: sprint closed / not yet chartered, nothing queued),
#         1 = one or more defects (each printed), 2 = file/usage error.
#
# WHY THIS EXISTS — two field defects it catches (Arogh Sprint-6 F-S6-1):
#   #1 run-killer: a fenceless `## Next Step` step. The driver keys COMPLETION on the ABSENCE of a
#      ``` fence in Next Step — so a fenceless step promoted to Next Step reads as "sprint complete"
#      and the driver halts mid-run. Caught here as "Next Step has no fenced block".
#   #2 unscannable: a fenced step with no heading -> the driver's label extraction (first heading in
#      the block) returns empty. Caught here as "fenced step with no heading".
#
# CONTRACT — mirrors muster-sprint-run.sh exactly (keep in sync; the fixture test pins both):
#   - Next Step block = `## Next Step` .. (next `^## ` OR any-level `Upcoming$`). Same awk as the
#     driver's next_block/next_step_count.
#   - A step = one ``` fence-pair (fence OPENINGS counted via toggle, NOT `###` headings: a prompt
#     body may legitimately contain `### ` lines; it cannot contain a ``` line).
#   - Step numbering is NOT a contract (32.5 / 9-fix-2 / unnumbered fixes are legitimate) — we assert
#     a heading EXISTS per step, never its number.
#   - Every step carries an explicit `Role: <role>` line (the convention is strict so the parse is
#     unambiguous; the driver still defaults a Role-less fenced block to `pm` as a tolerant backstop).
set -euo pipefail

QUEUE="${1:-knowledge-base/orchestration-queue.md}"
[ -f "$QUEUE" ] || { echo "queue-lint: file not found: $QUEUE" >&2; exit 2; }

# One awk pass. Two overlapping regions:
#   in_ns     — driver-exact Next Step block (for the "exactly 1 fence" assertion).
#   in_region — Next Step + the Upcoming list (for per-step heading/Role validation). Ends at the
#               first `^## ` titled neither "Next Step" nor "Upcoming" (Founder Decisions / Done).
# Failures are printed with a leading "FAIL:"; a trailing summary reports counts. Exit via the count.
awk '
  function fail(msg){ print "FAIL: " msg; fails++ }

  # --- section transitions -------------------------------------------------
  /^## Next Step[[:space:]]*$/ { in_ns=1; in_region=1; seen_ns=1; next }

  # End of the driver-exact Next Step block: next top-level `## ` OR any-level bare `Upcoming`.
  in_ns && (/^## / || /^#+[[:space:]]+Upcoming[[:space:]]*$/) { in_ns=0 }

  # End of the validated region: a `^## ` section that is neither Next Step nor Upcoming.
  in_region && /^## / && $0 !~ /^## Next Step[[:space:]]*$/ && $0 !~ /^## Upcoming[[:space:]]*$/ { in_region=0 }

  # --- fence toggle (must run before heading/role classification) ----------
  /^```/ {
    if (!in_fence) {                      # fence OPEN
      in_fence=1
      if (in_ns) ns_fences++
      if (in_region) {
        steps++
        role_in_fence=0
        if (!pending_heading) fail("fenced step with no heading (empty label) near line " NR)
        pending_heading=0
      }
    } else {                              # fence CLOSE
      in_fence=0
      if (in_region) {
        if (!role_in_fence) fail("fenced step missing a `Role:` line (ends near line " NR ")")
      }
    }
    next
  }

  # --- inside a fence: capture/validate Role: ------------------------------
  in_fence && in_region && /^[Rr]ole:/ {
    role_in_fence=1
    r=$0; sub(/^[Rr]ole:[[:space:]]*/,"",r); sub(/[[:space:]]+$/,"",r)
    if (r !~ /^(pm|developer|ui-ux|qa|content|marketing|legal|research|halt)$/)
      fail("invalid Role: \"" r "\" near line " NR " (valid: pm developer ui-ux qa content marketing legal research halt)")
    next
  }

  # --- outside a fence: a markdown heading marks a step label --------------
  # Skip the section headings themselves (Next Step / Upcoming at any level).
  !in_fence && in_region && /^#{1,4}[[:space:]]/ {
    if ($0 !~ /^#+[[:space:]]+Next Step[[:space:]]*$/ && $0 !~ /^#+[[:space:]]+Upcoming[[:space:]]*$/)
      pending_heading=1
  }

  END {
    # Distinguish the dangerous fenceless case (work queued but Next Step wont promote it) from the
    # benign idle case (sprint closed / not yet chartered — nothing queued anywhere, so a fenceless
    # Next Step is CORRECT). Flagging the idle state would cry wolf on every legitimately-closed
    # sprint. steps counts every fenced step in the region; with ns_fences==0, steps>0 means the
    # queued work lives only under Upcoming.
    if (!seen_ns)                       fail("no `## Next Step` section found")
    else if (ns_fences==0 && steps==0)  idle=1
    else if (ns_fences==0)              fail("Next Step has no fenced block but " steps " step(s) are queued under Upcoming — the driver reads the fenceless Next Step as \"sprint complete\" and halts WITHOUT running the queued work")
    else if (ns_fences>1)               fail("Next Step holds " ns_fences " fenced steps; exactly 1 is allowed (extra steps belong under `## Upcoming`)")
    if (fails>0) { print fails " defect(s) — queue is NOT well-formed"; exit 1 }
    if (idle)    { print "OK: idle — no active sprint (Next Step intentionally fenceless, nothing queued)"; exit 0 }
    print "OK: queue well-formed — Next Step = 1 fenced step; " steps " step(s) total, each with a heading + valid Role:"
  }
' "$QUEUE"
