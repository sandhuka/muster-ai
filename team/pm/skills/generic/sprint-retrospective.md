# Sprint Retrospective Skill

## Purpose
Systematic process improvement at sprint boundaries. `sprint-planning.md` covers task accounting (closeout steps 1-5); this skill covers identifying what broke, evaluating fixes, and implementing only those that earn their context weight.

## When to Run
- **End of every sprint**, after closeout in `sprint-planning.md` but before planning the next sprint.
- **After milestone gates** (beta, submission, launch) — surfaces cross-sprint patterns.

## Failure Identification
Do not rely on memory — check these sources:

| Source | What to look for |
|--------|-----------------|
| `decision-log.md` | Entries requiring 2+ revision passes or multi-file correction cascades |
| `agent-requests.md` | Stale entries (open >3 days), revision loops (3+ rounds) |
| `orchestration-queue.md` | Steps that blocked or required re-sequencing |
| Agent CLAUDE.md files | Outdated terminology, stale references, context drift from spec |

For each failure: what broke, how many agents/files it touched, whether it recurred.

## Fix Evaluation
Every proposed fix consumes context budget. Core test: **does the fix's token weight justify the failure it prevents?**

- Estimate **net new lines** across all files, **failure frequency**, and **cost per occurrence** (revision passes, blocked agents).
- 5+ net new lines → must prevent a recurring (>=1/sprint) or high-cost (3+ passes, 2+ agents blocked) failure.
- 1-2 net new lines → worth it if it prevents any identified failure.
- Uncertain → defer. Two consecutive deferrals = failure is tolerable, drop it.

## Fix Classification
Prefer lower-cost categories: checklist addition (~1-2 lines) > startup config change (~1-3 lines) > new protocol section (5-15 lines) > structural change (10+ lines, requires System Verification Checklist).

## Trim Discipline
Draft all fixes, then audit for overlap with existing protocols and cut anything that fails the token-weight test or duplicates coverage. Target: cut 40-60% of initial draft.

## Output
A single `decision-log.md` entry listing failures identified, fixes accepted (with files touched), and fixes rejected (with rationale). The accepted fixes applied directly to their target files.

## Principles
- **Process fixes are code.** They consume context, introduce maintenance burden, and can have bugs. Treat with the same rigor.
- **Frequency beats severity.** A low-severity recurring failure costs more than a high-severity one-off.
- **Existing protocols are cheaper than new ones.** One line added to `context-cascading.md` costs less than a new 15-line workflow.
- **Two retros, same failure = mandatory fix.** If it recurs, it won't self-resolve. Fix regardless of token cost.
