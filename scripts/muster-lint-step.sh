#!/usr/bin/env bash
# muster-lint-step.sh — lint: queue step BODIES are cold-agent-executable (family: lint — reports OK/FAIL, never mutates).
#
# muster-lint-queue.sh proves the queue PARSES (fences, Role lines, one-step Next Step); this
# lint proves each step can be executed by a stranger with no memory — the contents half of the
# planning floor. Checks, per fenced step:
#   FAIL  specialist steps (not pm/halt) missing a required field line: Inputs / Deliverable /
#         Acceptance / On completion (bold or plain, case-insensitive; a Task line is optional —
#         the step heading carries it; live convention uses plain "Inputs:" lines)
#   FAIL  @<role> tokens anywhere in a fence — Claude Code auto-routes @-mentions to that
#         subagent when the founder pastes the step, spawning the wrong agent
#   FAIL  a malformed Model: line (must be `Model: <id>`)
#   FAIL  a Role: halt step whose fence does not cite wave-review.md (the founder verdict file —
#         a gate without the pointer strands the resume flow)
#   WARN  swallowed-notification vocabulary ("tell/notify/ask/inform the founder", "surface/flag
#         to the founder") — in an autonomous run nobody reads chat; notices must be file actions
#   WARN  session-relative references ("as discussed", "follow the existing pattern", …) — the
#         Cold-Start Sufficiency Test's known-unresolvable phrases. Sufficiency itself stays PM
#         judgment; this floors only the known failure phrases.
#   WARN  premium-model steps listed (Model: fable requires founder acceptance at planning)
#
# Usage: muster-lint-step.sh [queue-file]      (default: knowledge-base/orchestration-queue.md)
# Exit: 0 clean (warns allowed) · 1 FAIL found · 3 usage/missing file.

Q="${1:-knowledge-base/orchestration-queue.md}"
[ -f "$Q" ] || { echo "muster-lint-step: file not found: $Q"; echo "usage: muster-lint-step.sh [queue-file]"; exit 3; }

awk '
  function flush_step() {
    if (!instep) return
    label = (heading != "") ? heading : ("step ending near line " NR)
    if (role != "pm" && role != "halt" && role != "") {
      missing = ""
      if (!f_inputs)     missing = missing "Inputs, "
      if (!f_deliv)      missing = missing "Deliverable, "
      if (!f_accept)     missing = missing "Acceptance, "
      if (!f_oncomp)     missing = missing "On completion, "
      if (missing != "") {
        sub(/, $/, "", missing)
        print "FAIL: " label " — missing field line(s): " missing " (a cold agent improvises what is not stated)"
        fails++
      }
    }
    if (role == "halt" && !f_wavereview) {
      print "FAIL: " label " — Role: halt gate does not cite wave-review.md (the founder verdict file; resume strands without it)"
      fails++
    }
    instep = 0
  }
  /^### / { if (!fence) { heading = $0; sub(/^### +/, "", heading) } }
  /^```/ {
    if (!fence) { fence = 1; instep = 1; role = ""
                  f_inputs = f_deliv = f_accept = f_oncomp = f_wavereview = 0 }
    else        { fence = 0; flush_step() }
    next
  }
  fence && instep {
    l = $0
    # first Role: line ANYWHERE in the fence — the driver parser accepts a Role: line at any
    # position, so keying on line 1 only would let a blank-led step dodge every check below
    if (role == "" && l ~ /^Role:[[:space:]]*/) { role = l; sub(/^Role:[[:space:]]*/, "", role); sub(/[[:space:]]+$/, "", role) }
    low = tolower(l)
    if (low ~ /^(\*\*)?inputs?[:*]/)                          f_inputs = 1
    if (low ~ /^(\*\*)?deliverable[:*]/)                      f_deliv = 1
    if (low ~ /^(\*\*)?acceptance/)                           f_accept = 1
    if (low ~ /^(\*\*)?on[- ]completion[:*]/)                 f_oncomp = 1
    if (l ~ /wave-review\.md/)                                f_wavereview = 1
    if (l ~ /(^|[[:space:](])@(pm|developer|ui-ux|qa|content|marketing|legal|research)([[:space:]).,;:]|$)/) {
      print "FAIL: " heading " — @-mention role marker in step body (auto-routes to that subagent on paste; use Role: lines)"
      fails++
    }
    if (l ~ /^Model:/) {
      if (l !~ /^Model:[[:space:]]*[A-Za-z0-9._-]+[[:space:]]*$/) {
        print "FAIL: " heading " — malformed Model: line (expected: Model: <model-id>)"; fails++
      } else if (low ~ /fable/) {
        print "WARN: " heading " — premium model queued (" l ") — requires founder acceptance at planning"; warns++
      }
    }
    if (low ~ /(tell|notify|ask|inform) the founder/ || low ~ /(surface|flag)[a-z ]* to the founder/) {
      print "WARN: " heading " — founder-chat instruction in step body (autonomous runs swallow chat; route via founder-notices.md or PM)"
      warns++
    }
    if (low ~ /as discussed|as agreed|per our conversation|follow the existing pattern|as designed earlier|the previous session|as before,/) {
      print "WARN: " heading " — session-relative reference (unresolvable to a cold agent; cite the file or handoff instead)"
      warns++
    }
  }
  END {
    flush_step()
    print "-----------------------------------------------"
    if (fails > 0)      { print "RESULT: " fails " FAIL, " warns+0 " WARN — steps are not cold-agent-executable"; exit 1 }
    else if (warns > 0) { print "OK: step bodies pass the floor (" warns " WARN for PM judgment)"; exit 0 }
    else                { print "OK: every step body is cold-agent-executable (fields, markers, gates clean)"; exit 0 }
  }
' "$Q"
