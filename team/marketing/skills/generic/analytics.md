# Analytics & Measurement

## Purpose
Core KPIs, cohort analysis, attribution, funnel diagnostics, and testing standards. Analytics is the feedback loop for all other marketing skills. See `team/marketing/skills/growth-strategy.md` for unit economics and `knowledge-base/product-spec.md` for product success metrics.

## Core KPIs

**North Star**: Weekly Active Routines Completed (target: 2.5+/user/week). Combines activation, engagement, and satisfaction in one metric.

| Category | Metric | 90-Day Target | Year 1 Target |
|----------|--------|--------------|--------------|
| Health | Crash-free rate | >99.5% | >99.5% |
| Health | App Store rating | 4.5+ | 4.7+ |
| Growth | Downloads | 10K+ | 100K+ |
| Growth | D1 / D7 / D30 retention | 40% / 18% / 10% | 45% / 22% / 14% |
| Growth | WAU/MAU stickiness | 25%+ | 30%+ |
| Revenue | Free-to-paid conversion | 3%+ | 5%+ |
| Revenue | MRR | $500+ | $10K+ |
| Revenue | Monthly churn | <8% | <6% |
| Revenue | Annual:monthly ratio | 40%+ annual | 60%+ annual |

## Reporting Cadence

| Frequency | Focus | Time |
|-----------|-------|------|
| Daily | Downloads, DAU, crash rate, new reviews | 5 min |
| Weekly | Retention curves, activation funnel, revenue, channel CPA | 30 min |
| Monthly | Full funnel, cohort analysis, LTV trending, channel ROI, review sentiment | 2 hrs |
| Quarterly | Strategy review, competitive analysis, projections, budget reallocation | Half day |

## Cohort Analysis
Segment users into cohorts to answer "are we getting better over time?"

**Primary cohorts**: Install week (compare D7/D30 across weeks), acquisition channel (compare retention and LTV), onboarding completion (complete vs. incomplete), first-session behavior (completed routine vs. didn't — 2-3x retention difference).

**What to look for**: Improving retention curves across weekly cohorts. Channel quality divergence (if Meta users retain 50% less than Apple Search Ads, adjust targeting). Onboarding completion <60% = fix onboarding before scaling acquisition.

## iOS Attribution in the ATT Era
Expect 30-40% ATT opt-in for a fitness app.

| Method | Accuracy | Use For |
|--------|----------|---------|
| Apple Search Ads API | Deterministic (100%) | Apple Search Ads — unaffected by ATT |
| SKAdNetwork 4.0 | Aggregated, 24-48 hr delay | Meta, TikTok, Google campaigns |
| UTM parameters | Exact for web | Landing page, email, social bio links |
| Referral codes | Exact | Influencer, user referrals |
| App Store Connect | First-party, aggregated | Organic vs. paid split, source type |

**Triangulation**: Platform-reported installs over-report by 20-40%. Compare to App Store Connect totals. Organic lift above baseline ≈ paid campaign impact. Add "How did you hear about us?" to post-onboarding for qualitative channel mix.

**SKAN setup**: Map conversion values — fine values 0-63 encode install → onboarding → first routine → subscription. Configure all 3 postback windows (0-2, 3-7, 8-35 days).

## Tool Recommendations

| Tool | Purpose | Cost | When |
|------|---------|------|------|
| App Store Connect | Downloads, impressions, conversion, sources | Free | Day 1 |
| RevenueCat | Subscription analytics, paywall A/B testing | Free to $2.5K MRR | Day 1 |
| Mixpanel or Amplitude | Events, funnels, retention, cohorts | Free tier to 100K users | Day 1 |
| Superwall | Paywall A/B testing, remote config | Free to 250 conversions/mo | When optimizing conversion |
| AppTweak or Sensor Tower | ASO keyword tracking | $70-100/mo | Month 2+ |

Don't buy: enterprise attribution suites (Appsflyer, Adjust) — overkill pre-100K. Don't overlap: pick ONE event analytics platform.

## Funnel Diagnostic Playbook

### Downloads Below Target

| Cause | Diagnostic | Fix |
|-------|-----------|-----|
| Low impressions | App Store Connect impressions | ASO keywords (`aso-playbook.md`) |
| Low conversion | Impression-to-install rate | Screenshot/subtitle A/B testing |
| Paid underperforming | CPA by campaign | Adjust bids/creative (`paid-acquisition.md`) |

### D7 Retention Below 18%

| Cause | Diagnostic | Fix |
|-------|-----------|-----|
| Onboarding incomplete | Onboarding completion rate | Simplify flow, reduce steps |
| First routine not completed | First-routine completion rate | Investigate length, difficulty, quality |
| No return trigger | D2-D6 session frequency | Push timing, email day-3 nudge |

### Conversion Below 3%

| Cause | Diagnostic | Fix |
|-------|-----------|-----|
| Paywall not seen | Paywall impression rate | Surface at natural value moments |
| Paywall not converting | Paywall conversion rate | A/B test design/copy (Superwall) |
| Price resistance | Pricing page drop-off | Annual-first presentation, anchoring |

### Churn Above 8%

| Cause | Diagnostic | Fix |
|-------|-----------|-----|
| Routine quality | Routines/user/week trend | Algorithm improvement |
| Billing issues | Involuntary churn rate | Grace period, retry logic |
| Competitor launch | Category trends | Counter-positioning |

## Data Thresholds Before Acting

| Decision | Min Sample | Min Duration |
|----------|-----------|-------------|
| Kill ad creative | 500 impressions, 0 conversions | 3 days |
| Scale paid channel | 50+ conversions | 7 days |
| Change onboarding | 200+ per variant | 14 days |
| Change paywall | 100+ views per variant | 14 days |
| Change push strategy | 500+ recipients | 7 days |

At <1K users: supplement with user interviews (5-10), session recordings, support ticket patterns, and review analysis. Trust strong qualitative signals at low volume.

## A/B Testing Standards
- One variable at a time. Minimum 7 days (full weekly cycle). Define success metric and MDE before launch
- Priority: (1) paywall design, (2) onboarding flow, (3) push timing, (4) App Store screenshots, (5) email subject lines
- Document all results in `knowledge-base/decision-log.md` regardless of outcome

## Privacy-First Analytics
Collect: anonymous events (screen views, taps, routine completions), device metadata (iOS version, model, locale), aggregated usage patterns. Never collect: location data, HealthKit data beyond routine assembly, browsing outside the app. Declare accurately in App Store privacy nutrition labels — review with Legal agent before submission.