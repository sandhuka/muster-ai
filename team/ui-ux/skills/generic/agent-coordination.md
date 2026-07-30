# Agent Coordination Protocol

## Purpose
Define how the UI/UX agent requests input from other agents, delivers specs to downstream agents, and tracks cross-agent dependencies. This ensures no design work is blocked by missing copy, unclear requirements, or ambiguous handoffs. See the `ios-screen-specification` skill for the full spec format used in Developer handoffs.

## Communication Channels
All inter-agent communication happens through files in `knowledge-base/`:

| Channel | File | Purpose |
|---------|------|---------|
| Agent communication | `knowledge-base/agent-requests.md` | Requests (questions, asks) and handoffs (deliverable reviews) between agents |
| Component requests | `knowledge-base/ui-component-requests.md` | Request new shared UI library components from founder |
| Decision log | `knowledge-base/decision-log.md` | Record product decisions (any agent can append) |
| Sprint tasks | `knowledge-base/current-sprint.md` | Current task board (PM-managed) |

## How to Request Input from Other Agents

### Request Format
Use the standard request format in `knowledge-base/agent-requests.md` (see the comment block at the top of that file for the template). Key fields: `Type: request`, `From: UI/UX`, `To: [target agent]`, `Status: open`. See `system-guide.md` → Agent Communication Protocol for the full format specification.

### Common Requests by Target Agent

**→ PM Agent**
- Requirement clarification: "F-ONB-3 says '[user attribute]' — what are the exact options and how do they map to algorithm input?"
- Priority decisions: "Should the [secondary tab] free-tier view show a sample preview or just the upgrade banner?"
- Scope questions: "Is in-app content search needed for MVP or v1.1?"

**→ Content Agent**
- Screen copy: "Need final onboarding copy for screens F-ONB-0 through F-ONB-6. Placeholders are in the wireframe — see [link to wireframe file]. Character limits noted per field."
- Microcopy: "Need error messages for: network timeout, no items match filter, empty history view."
- Tone check: "Is this rationale string too technical? 'Upper body recovery: 36h remaining' vs 'Your upper body is still recovering from yesterday.'"

**→ Developer Agent**
- Feasibility check: "Can we do a matched geometry transition from content card in Library to the detail view? Need to know before I spec the animation."
- Technical constraint: "What's the maximum media asset file size we can load without frame drops? Affects my loading state design."
- Data availability: "Will the algorithm provide a 'confidence score' for routine recommendations? Want to show it in the rationale UI."

**→ QA Agent**
- Test guidance: "Here are the 5 states for Today screen — please include all in visual regression testing."
- Edge case identification: "What happens if the user has 0 completed sessions but premium? Should Progress show empty state or onboarding prompt?"

## How to Deliver Specs to Other Agents

### Developer Handoff Checklist
Use the Spec Quality Checklist in the `ios-screen-specification` skill — it is the authoritative handoff checklist (10 items covering tokens, states, copy, components, accessibility, responsive, and open questions). Complete every item before creating a handoff entry.

### Delivery File Location
Place completed specs in `knowledge-base/design-specs/` with naming convention:
- `[feature-id]-[screen-name].md` (e.g., `f-onb-0-welcome-screen.md`)
- `[flow-name]-user-flow.md` (e.g., `onboarding-user-flow.md`)

### Notifying Downstream Agents
For deliverable handoffs (wireframes, specs, flows), use the handoff entry format in `knowledge-base/agent-requests.md`. See `system-guide.md` → Agent Communication Protocol for the full protocol.

After placing the spec file, create a handoff entry in `knowledge-base/agent-requests.md` with the deliverable path, and list all reviewers who need to consume the spec (e.g., Developer for implementation, Content for copy, QA for test cases).

### QA Handoff
Include QA as a reviewer in the handoff entry when the spec includes:
- Expected visual states screenshot descriptions (all states)
- Interaction test scenarios (what to tap, swipe, and expected result)
- Accessibility test points (VoiceOver navigation order, Dynamic Type at xxxLarge)

## Dependency Tracking

### When You're Blocked
If you can't proceed without input from another agent:
1. File the request in `agent-requests.md` with `Blocked by this?: YES`
2. Work on non-blocked tasks in the meantime
3. Note the blocker in your next status update

### When Others Need Your Output
The PM's sprint plan defines deliverable order. Check `knowledge-base/current-sprint.md` for who's waiting on your work. Content agent needs your wireframes (with copy placeholders) before they can write final copy. Developer agent needs your full specs before implementation.

## Decision Logging
When you make a design decision that affects other agents or diverges from the product spec, append to `knowledge-base/decision-log.md`:

```markdown
## [YYYY-MM-DD] [Decision Title]
- **Agent**: UI/UX
- **Decision**: [what was decided]
- **Rationale**: [why]
- **Affects**: [which agents / which features]
- **Alternatives considered**: [what else was evaluated]
```
