# Plan-First Discipline

The front bookend to `verification-discipline.md` (the back bookend). That skill verifies finished
work before handoff; this one pressure-tests the *plan* before a line of code — so a wrong approach
gets caught when it is cheap to change, not after it has been built.

## When to use

**Non-trivial tasks only** — anything with real design surface: a new feature, a multi-file change,
a new screen or flow, an architectural choice, anything you could not hold in your head at once and
get right on the first pass. **Skip it for trivial tasks** — a copy tweak, a one-line fix, a rename,
a mechanical change with one obvious way to do it. There the planning ceremony costs more than it
saves. When genuinely unsure, treat the task as non-trivial.

## The loop: plan → stress-test → implement

1. **Plan.** Before writing code, lay out the approach: the shape of the change, the files and
   components it touches, the key decisions and *why*, the edge cases and failure modes. Concrete
   enough that implementing it is mostly transcription, not discovery.

2. **Stress-test the plan** against three questions — honestly, as if reviewing someone else's work:
   - **Gaps** — what does this miss? Edge cases, the unhappy path, failure modes, interactions with
     existing code, anything assumed but not checked.
   - **Simpler** — is there a materially simpler approach that does the same job? Fewer moving parts,
     less new surface, less to maintain. Most first plans are more complex than they need to be.
   - **Apple-ship quality** — would Apple ship this as-is, or would they refine it to be cleaner and
     simpler? Hold it to the bar in your platform best-practices skills, not to "it works."

3. **Decide.** Clears all three → implement, following the plan. Fails any → revise and stress-test
   the revised plan again.

## Bound: three rounds, then proceed

Stress-testing reliably improves a plan — a second pass surfaces options, a third sharpens them — but
it must converge, not loop forever (in an autonomous run there is no human to stop you mid-spin).
Allow up to **three** plan → stress-test rounds. If the third round still does not clear the bar,
**proceed with the best plan you have and flag the residual concern explicitly in your handoff** —
what is still unresolved and why — so the doubt surfaces to the founder in a file. Never spin a
fourth round.

## Why this is worth the tokens

Planning front-loads cheap tokens to avoid expensive ones. A stress-tested plan makes implementation
mostly transcription — little backtracking, few wrong turns built and then rebuilt. On a non-trivial
task, the rework you prevent costs far more than the plan you wrote. On a trivial task it does not —
which is exactly why this is gated to non-trivial work.
