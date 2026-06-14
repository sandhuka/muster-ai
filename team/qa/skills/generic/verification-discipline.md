# Verification Discipline — Trust, Then Verify

## Purpose
How any role confirms work is actually done before declaring it so. A claim is not proof; a
summary is not the artifact. This is the mindset that catches the bug, the missed step, and the
"green" that was never run — across product work and framework work alike.

## The Core Rule
**Trust, then verify.** When something is reported done, green, or correct — by a teammate, a
prior session, or yourself a few turns ago — confirm it independently before you build on it.
Self-reports drift from reality, and the drift is invisible until you check.

## How To Verify
1. **Mechanical over prose.** If a thing can be checked by running something — a test, a `grep`, a
   build, a diff — run it. Don't reason about whether it's *probably* fine. A check that executes
   beats a paragraph that argues; it's the determinism the framework is built on.
2. **Go to the source of truth.** Verify against the actual files and command output — never a
   summary, a value remembered from an earlier turn, or "it should be." Re-read the file; re-run
   the command.
3. **Build the fixture if none exists.** Verifying a change to something untested? Construct a
   minimal, repeatable check instead of eyeballing it once. It costs minutes; the bug it catches
   costs a release. If a check is worth running twice, it's worth saving.
4. **Separate mechanizable from manual.** Whatever can be tested mechanically, test mechanically —
   that's most of it. Only genuinely human checks (does the real app behave, does this *feel*
   right) go to a person. Don't escalate what a script could have answered.

## By Role
- **QA** — your defining discipline. Never accept "tests pass" without the counts and the failing
  lines; re-run the suite yourself; validate the deliverable against its acceptance criteria.
- **Developer** — verify your own work before handoff. Run the affected tests (then the full suite
  once at closeout). A handoff on hope is a handoff that bounces.
- **PM** — don't rubber-stamp a handoff. Spot-check the claim against the deliverable file before
  accepting and cascading; an accepted-but-wrong handoff corrupts everything downstream.
- **XO / framework** — re-run the gates and read the diff before declaring a framework change
  shipped. A behavior without a fixture assertion isn't shipped, it's hoped.

## The Anti-Pattern
Declaring done from a green claim you didn't reproduce, a file you didn't re-read, or a path you
reasoned about but never ran. If you catch yourself writing "this should work," stop and make it
"I ran this and it works."
