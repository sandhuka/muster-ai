# Paid Acquisition

## Purpose
Tactical playbook for paid user acquisition: Apple Search Ads, Meta, TikTok Ads, Google App Campaigns. Paid accelerates growth once organic product-market fit is proven. See `team/marketing/skills/growth-strategy.md` for unit economics and channel sequencing, `team/marketing/skills/analytics.md` for ATT-era attribution.

## Channel Activation Order

| Channel | When to Start | Why |
|---------|--------------|-----|
| Apple Search Ads | Day 1 | Highest intent, deterministic attribution (unaffected by ATT) |
| Meta/Instagram | After 1K organic installs | Needs PMF proof; 100+ conversions for lookalike audiences |
| TikTok Ads | After 3+ organic videos with 10K+ views | Spark Ads boost organic winners |
| Google App Campaigns | After 5K installs | ML needs conversion volume to optimize |

## Apple Search Ads

### Campaign Structure

| Campaign | Keywords | Match Type | CPA Target | Budget Share |
|----------|----------|-----------|-----------|-------------|
| Brand | "[your brand name]," "[brand] app" | Exact | $[low — brand terms are cheapest] | 5-10% |
| Category | [3-5 terms that describe your core action in user language] | Exact + Broad | $[mid — your category's competitive range] | 40-50% |
| Competitor | [Top 3-5 direct competitors by brand name] | Exact | $[higher — competitor terms cost more] | 20-30% |
| Discovery | None (Search Match auto) | Auto | $[mid-high — auto-match is less precise] | 10-15% |

- **Starting bids**: Research your category's average CPA on AppTweak/Sensor Tower and bid 80-100% of that. Adjust +/-15% weekly based on CPA
- **Daily budget**: $20-50/day total. Scale winners 15-20%/week
- **Negative keywords**: [Terms that attract wrong-fit users — in-person services, wrong platform, tangential products, physical goods in your category]
- **Creative Sets**: 3-5 Custom Product Pages targeting different keyword intents — each should match the search query's mental model (someone searching for [feature A] should land on a page highlighting [feature A])
- **Seasonal**: Identify your category's 2-3 peak periods and adjust bids +30-50%. Reduce during known low-intent periods

### Scaling / Kill Rules
- Scale: increase 15-20% weekly on ad groups with CPA <target for 5+ days
- Kill: pause at 200+ impressions with 0 conversions, or CPA >2x target after $50 spend
- Never increase budget >30% in a single week

## Meta/Instagram Ads

### Audience Progression
1. **Interest targeting** (0-100 conversions): [3-5 interest categories relevant to your product]. [Age range of your core demographic], [primary market] only
2. **Lookalike** (100+ conversions): source = users who completed [your activation event]. Start 1%, test to 3%
3. **Broad** (500+ conversions): remove targeting, let Meta's ML optimize on conversion data

### Creative Strategy
Video-first. 15 seconds beats 30 seconds. Sound-off design (captions required).

| Format | Description |
|--------|-------------|
| App walkthrough (15 sec) | Screen recording: [open → core screen → primary action] |
| UGC testimonial | Creator talking to camera about the app |
| Problem → solution | "[State the user's pain point as a question]" → app demo showing the solution |
| Before/after | "[Life before your app] vs. [life after]" — show the transformation your product creates |

- Lead with pain point, not feature. "[User's frustration]?" not "[Technical capability]"
- Refresh creatives every 2-3 weeks (fatigue degrades performance 20-30%)
- **ATT impact**: expect 35-45% opt-in. Platform over-reports by 20-40%. Triangulate with App Store Connect organic lift (see `analytics.md`)

### Budget
- $30-50/day per ad set. Meta needs 50 conversions/week/ad set to exit learning phase
- Scale 20% every 3 days on winners. Kill at CPA >2x target after $100 spend

## TikTok Ads

**Primary format: Spark Ads** — boost organic content that performs well. Outperforms polished ads 2-3x because it feels native. Engagement stays on the organic post.

- Post organically → wait 24-48 hrs → boost winners as Spark Ads
- In-Feed Ads (secondary): UGC-style, first 2 seconds = hook, <30 seconds, vertical
- Audience: [age range], [category interest], iOS only, [primary market]
- Budget: $50/day minimum per ad group (TikTok's learning phase needs volume)

## Google App Campaigns

Fully automated. Provide diverse assets (5 headlines, 5 descriptions, 3-5 images, 2-3 videos); Google's ML optimizes placement.

- Optimize for [your activation event] (not just install) for higher-quality users
- Starting CPA target: set at 1.2-1.5x your Apple Search Ads CPA. Budget: $30-50/day. 2-week learning period — don't change targets during this
- Minimal manual control. Start only after 5K+ installs provide conversion data

## Budget by Growth Stage

| Stage | Monthly Budget | Primary (%) | Secondary (%) |
|-------|---------------|-------------|---------------|
| 0-1K users | $200-500 | Apple Search Ads (100%) | — |
| 1K-10K | $500-2K | Apple Search Ads (60%) | Meta (25%), Creator (15%) |
| 10K-50K | $2K-5K | Apple Search Ads (45%) | Meta (30%), TikTok (15%), Creator (10%) |
| 50K-100K | $5K-10K | Apple Search Ads (40%) | Meta (30%), TikTok (15%), Google (10%) |
| 100K+ | $10K-50K | Diversified | Budget follows ROAS |

## Weekly Optimization Routine (1 Hour)
1. Check CPA by channel — flag anything >1.5x target (15 min)
2. Pause underperformers per kill rules (10 min)
3. Scale winners per scale rules (10 min)
4. Creative health check — rising CPA or dropping CTR over 5+ days = fatigue (10 min)
5. Reallocate budget from underperforming to outperforming channels (10 min)
6. Log significant learnings in `knowledge-base/decision-log.md` (5 min)
