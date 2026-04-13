# Product Validation Skill

Score the product idea, assess feasibility, scope the MVP, and produce the product brief.

## ICE Scoring

For each product candidate or major feature:

- **Impact** (1-10): Value created for users and business
- **Confidence** (1-10): How sure are we about impact and feasibility estimates
- **Ease** (1-10): How easy to build and launch (10 = trivial)
- **Score** = (I + C + E) / 3

Low confidence + high impact = do more research, don't dismiss. Document in `knowledge-base/research/product-candidates.md`.

## Feasibility Check

- **Technical**: Can we build it? Hardest challenges? Platform constraints? Dev complexity (S/M/L/XL)?
- **Market**: Is the market big enough? Evidence of demand (search volume, competitor downloads, community signals)?
- **Resource**: Minimum team to execute? Critical third-party dependencies (content hosting, CDN, domain-specific assets)?
- **Content**: Where does the core content/data come from? License, produce, or partner? Identify the biggest cost/risk driver for content-dependent products.

## MVP Scope

Principles: smallest version that tests core value prop. Cut features, not quality.

1. List all features from full vision
2. Categorize: Must Have / Should Have / Nice to Have
3. MVP = Must Have only
4. Define success metrics for 30/60/90 days

Define the likely MVP scope for your product: core experience for 1-2 content categories, limited content library, basic personalization or scheduling logic. No social, no integrations, no advanced AI — just the core value proposition working reliably.

## Product Brief

Primary handoff to PM. Lives at `knowledge-base/research/product-brief.md`. Structure:

- Current State (5-10 lines)
- Problem → Solution → Target User → Core Value Prop
- Key Features (MVP scope)
- Market Opportunity (link to market-landscape.md)
- Competitive Position (link to competitive-analysis.md)
- Success Metrics (3-5 measurable outcomes, 90 days)
- Risks & Open Questions
- History

## Output Format
- Product candidates go in `knowledge-base/research/product-candidates.md`
- Final product brief goes in `knowledge-base/research/product-brief.md`
- Both use the standard research doc structure
