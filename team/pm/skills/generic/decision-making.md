# Decision Making Framework

## Decision Types and Their Impact

### Strategic Decisions
Product direction, target audience, monetization, brand positioning.
- Log in decision-log.md
- Update product-spec.md or brand-guidelines.md
- Update ALL agents' Product Context

### Feature Decisions
New features, feature changes, deprecations, scope changes.
- Log in decision-log.md
- Update product-spec.md
- Update AFFECTED agents' Product Context and Current Tasks
- Update architecture.md if technical implications

### Tactical Decisions
Sprint priorities, task assignments, timeline adjustments.
- Update current-sprint.md
- Update affected agents' Current Tasks and Cross-Agent Dependencies

### Operational Decisions
Process changes, tool choices, workflow adjustments.
- Update relevant skill files
- Log in decision-log.md if significant

## Decision Template
When making a decision with the founder, capture:
1. **Context**: What situation prompted this decision?
2. **Options considered**: What alternatives were evaluated?
3. **Decision**: What was decided and why?
4. **Impact**: Which agents/areas are affected?
5. **Action items**: What needs to happen next and who does it?
6. **Risks**: What could go wrong? Mitigation?

## Prioritization Framework (ICE)
Use for feature decisions:
- **Impact** (1-10): How much will this move the needle?
- **Confidence** (1-10): How sure are we this will work?
- **Ease** (1-10): How easy is this to implement?
- Score = (I + C + E) / 3
- Rank features by score, adjust for strategic alignment

## Risk Flags
Automatically loop in additional agents when a decision involves:
- Legal/compliance implications → Legal agent
- User data handling → Legal + Developer agents
- Public-facing claims with regulatory implications → Legal + Marketing + Content agents
- Breaking technical changes → Developer + QA agents
- Brand-facing changes → Content + Marketing + UI/UX agents

## Scope Change Protocol
A scope change is any addition, removal, or re-scoping of a feature after the sprint has started or the spec has been baselined.

**When a scope change is proposed:**
1. Classify it: Is this a new feature request, a feature change, or a priority shift?
2. Apply the ICE score. If Impact < 6 or Ease < 4, defer to backlog unless strategically critical.
3. Assess sprint impact: Does this displace a current task? Which agent is affected?
4. Decide: Accept (this sprint), Defer (next sprint or backlog), or Reject (log rationale).
5. If accepted: Update `product-spec.md`, update affected agents' CLAUDE.md, update `current-sprint.md`, log in `decision-log.md`.

**When to pause and request research instead of deciding:**
- The decision affects monetization, pricing, or conversion mechanics
- The decision introduces a new user segment or changes the target persona
- The decision requires validating a technical constraint (e.g., "can the animation pipeline support this format?")
- Conflicting signals exist in the research and a judgment call could be wrong

To request research: add an entry to `knowledge-base/research/change-log.md` with `status: needs-research`, a clear question, and which spec section is blocked.

## Decision Autonomy Matrix

Defines what the PM decides alone vs. what requires founder approval.

### PM Decides Alone
- Task sequencing within a sprint
- Agent task assignment
- Spec clarifications that do not change scope
- Accepting/rejecting agent deliverables against defined acceptance criteria
- Sprint timing adjustments (extending a task, reordering)
- Bug severity classification
- Research interpretation when recommendation is clear and unanimous

### PM Escalates to Founder
- Feature scope changes (adding/removing from MVP)
- Monetization or pricing changes
- Brand positioning changes
- Architecture decisions with long-term lock-in
- Legal compliance interpretation
- Research interpretation when ambiguous or high-stakes
- Any decision where PM confidence is below 7/10
- Spending decisions (paid tools, services)
- Go/no-go on milestone gates

### How to Escalate
When the PM encounters a decision requiring founder input, add an entry to the **Founder Decisions** section of `knowledge-base/orchestration-queue.md` using this format:

```
### [Decision title]
**Context**: [1-2 lines — what happened and why this needs a call]
**PM Recommendation**: [what PM thinks and why]
**Blocked**: [which agent/step can't proceed until this is resolved]
**Your call**: [founder edits this line with their answer]
```

**Surfacing rule**: When you write a Founder Decision, you must also tell the founder directly in the current session output — do not just write to the file silently. State the decision title, your recommendation, and what's blocked. The file entry is the record; the session output is the alert.

The founder responds by editing the file directly or in the next PM session. PM reads the response on its next invocation and acts on it.

## Decision Principles
- **Log decisions in real time, not retrospectively.** A decision without a log entry didn't happen — future agents and sprints will re-litigate it.
- **Distinguish reversible from irreversible.** Low-reversibility decisions (architecture, monetization structure, brand positioning) warrant more deliberation and documentation. High-reversibility decisions (copy, task order, visual tweaks) can be made quickly.
- **Don't decide what research can answer better.** If the confidence score for an ICE evaluation would change significantly with more data, request the research. A fast bad decision costs more than a short research delay.
- **Update all affected surfaces after every decision.** A decision that only lives in `decision-log.md` is incomplete. The spec, guidelines, or agent files that are affected must also reflect the change. When writing the decision log entry, populate the **Touched** field with every file and section you modified -- this forces you to enumerate update locations at write time and makes missed locations visible before the entry is finalized.
