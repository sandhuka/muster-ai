# Product Evaluation Framework

## Purpose

Structured evaluation of research deliverables against go/no-go criteria. This skill sits between research delivery and the go/no-go decision. It produces a scored recommendation that feeds into the Decision Autonomy Matrix (`decision-making.md`) — PM decides alone on clear cases, escalates to the founder on ambiguous or high-stakes ones. After a GO verdict, PM proceeds to `product-spec-writing.md` to create the product spec.

**Input**: Completed `knowledge-base/research/product-brief.md` and supporting files (`market-landscape.md`, `competitive-analysis.md`, `user-insights.md`).

**Output**: Structured evaluation with dimension scores, verdict, rationale, and kill criteria — presented directly to the founder in the PM session.

## When to Use

- Research agent has delivered product-brief.md and supporting files
- Founder asks PM for a go/no-go recommendation
- PM needs to evaluate whether research findings support pursuing a product idea

## Step 1: Gather Founder Operating Parameters

Before evaluating, PM must understand the founder's operating context. These parameters shape every evaluation dimension. Check if the founder has already provided them; if not, ask before proceeding.

- **Timeline to MVP**: How long does the founder have to ship a testable product?
- **Team & resources**: Solo + AI agents? Small team? Budget constraints?
- **Risk tolerance**: Test fast and kill, or invest deeply in one bet?
- **Success definition**: What does the founder consider traction? (revenue, users, retention, waitlist, other?)

Store these once per founder. Reuse across evaluations — only re-ask if the founder's situation changes.

## Step 2: Evaluate Against Six Dimensions

Score each dimension 1-10 with brief rationale. Every score must cite specific findings from research files. If evidence is missing for a dimension, note the gap — do not guess.

### 1. Market Signal Strength
- Is the market real and sized? (TAM/SAM/SOM from market-landscape.md)
- Is the gap validated by user pain, not just absence of a product? (user-insights.md)
- Are there demand signals? (search volume, community complaints, adjacent product growth, trend data)
- Weak or missing research = low confidence score, not a pass

### 2. MVP Feasibility
- Can the core value proposition ship within the founder's stated timeline?
- Technical complexity: APIs, content/assets, third-party dependencies, regulatory requirements
- What can the AI agent team handle vs. what requires heavy founder involvement beyond product decisions?
- Flag anything that extends beyond the founder's timeline or resource constraints

### 3. Monetization Clarity
- Is there a testable revenue model for the MVP? (not "could eventually make money")
- What are users paying for today in this space? What's the pricing anchor?
- Can revenue be validated early, or does the model require scale first?
- Evaluate against the founder's success definition

### 4. Competitive Defensibility
- How long before a competitor matches the MVP?
- Moat sources: proprietary data, unique content, workflow lock-in, domain expertise, speed-to-market, network effects
- Differentiation that survives quick copying vs. durable advantage
- Reference competitive-analysis.md gap analysis

### 5. Founder Context
- What unique advantage does this founder bring to this specific problem?
- Domain knowledge, personal connection to the problem, unique insight, existing audience, technical edge
- If not provided in the brief or conversation, ask the founder before scoring this dimension

### 6. Traction Testability
- Can success/failure be measured post-launch within the founder's timeline?
- Are there concrete metrics the founder can track? (downloads, retention, revenue, engagement)
- Can kill criteria be defined upfront? What threshold means continue vs. pivot/stop?
- If traction can't be concretely defined, the idea isn't concrete enough yet

## Step 3: Synthesize and Recommend

### Scoring
- Compute the average across all 6 dimensions (1-10 each)
- Flag any dimension scoring **≤ 3** as a **critical weakness** — a single critical weakness can override a high average
- Flag any dimension scoring **≤ 5** as a **concern** requiring mitigation

### Verdict Logic
- **GO**: Average ≥ 7, no critical weaknesses, monetization ≥ 5, feasibility ≥ 5
- **CONDITIONAL**: Average ≥ 5, resolvable concerns identified, path to resolution is clear
- **NO-GO**: Average < 5, or any critical weakness without clear mitigation, or feasibility below founder's stated constraints

### Confidence Rating
- **8-10**: Research is thorough, signals align, recommendation is strong
- **5-7**: Research has gaps or signals are mixed — recommendation has caveats
- **1-4**: Research is thin or contradictory — recommendation is tentative, more research may be needed before deciding

## Step 4: Produce the Evaluation Output

Present to the founder using this template:

```
## Product Evaluation — [Product Name]

### Founder Operating Parameters
- Timeline: [stated timeline]
- Resources: [team/budget]
- Risk tolerance: [stated preference]
- Success definition: [stated metrics]

### Dimension Scores
| Dimension | Score | Key Evidence |
|-----------|-------|-------------|
| Market Signal Strength | X/10 | [1-line cite from research] |
| MVP Feasibility | X/10 | [1-line cite from research] |
| Monetization Clarity | X/10 | [1-line cite from research] |
| Competitive Defensibility | X/10 | [1-line cite from research] |
| Founder Context | X/10 | [1-line cite from research] |
| Traction Testability | X/10 | [1-line cite from research] |
| **Average** | **X/10** | |

### Verdict: [GO / CONDITIONAL / NO-GO]
**Confidence**: X/10 — [why this confidence level]

### Rationale
[2-3 paragraphs: strongest arguments for and against. Evidence-driven, not diplomatic.
If research is thin or contradictory, say so explicitly. Present both sides — what
supports the verdict and what challenges it.]

### MVP Feasibility Sketch (GO or CONDITIONAL only)
[What the MVP would include/exclude to test the core value proposition within the
founder's stated timeline. High-level scope, not a full spec.]

### Kill Criteria (mandatory for GO and CONDITIONAL)
[Specific metrics + thresholds + timeframe for evaluating post-launch traction.
Example: "500 downloads + 20% D7 retention within 60 days of launch."
The founder may adjust these — but they must exist before proceeding.]

### Key Risks
1. [Risk] — Mitigation: [action]
2. [Risk] — Mitigation: [action]
3. [Risk] — Mitigation: [action]

### If NO-GO: Path to Reconsideration
[What would need to change — market shift, new data, different approach, resolved
blocker — to make this idea worth revisiting. Be specific.]
```

## After the Verdict

- **GO**: PM proceeds to `product-spec-writing.md` to create the product spec from the research deliverables. Log the decision in `decision-log.md`.
- **CONDITIONAL**: PM escalates to Founder Decisions in `orchestration-queue.md` with the specific conditions to resolve. The evaluation is the artifact the founder reviews.
- **NO-GO**: PM logs the decision in `decision-log.md` with rationale. Research files are preserved as a record — they may inform future evaluations.
- The Decision Autonomy Matrix (`decision-making.md`) determines whether PM decides alone (clear, high-confidence verdict) or escalates (ambiguous or high-stakes). GO/NO-GO on milestone gates always escalates to the founder.

## Evaluation Principles

- **Evidence over intuition.** Every score must cite research findings. "Feels like a good market" is not a score justification.
- **Direct over diplomatic.** If the research says the market is small, say the market is small. Don't frame a NO-GO as "an opportunity to revisit later" when the evidence says stop.
- **Founder parameters over PM assumptions.** Evaluate against what the founder stated, not what PM thinks is optimal. A 12-month timeline is valid if that's the founder's constraint. A high risk tolerance is valid if that's the founder's preference.
- **Thin research = low confidence, not a pass.** Missing data is a signal. Flag gaps and recommend targeted follow-up research if a gap is blocking the evaluation.
- **Kill criteria are mandatory.** No GO recommendation without defined traction metrics and thresholds. This prevents the "we'll figure out success later" trap.
- **Critical weaknesses matter more than averages.** A product with 8/10 market and 2/10 feasibility is a NO-GO, not a 5/10. The scoring system supports nuance, but a single fatal flaw is still fatal.
- **Both sides, always.** Even in a strong GO, surface the strongest counterargument. Even in a clear NO-GO, acknowledge what was promising. The founder makes better decisions with the full picture.
