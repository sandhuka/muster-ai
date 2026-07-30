# App Review & Rating Strategy

## Purpose
Systematic strategy for generating, managing, and leveraging App Store reviews. Rating is the single most important conversion factor on the listing — the difference between 4.3 and 4.7 stars means 20-30% higher conversion. Review volume feeds the ranking algorithm. Content agent owns review response copy (the `app-store-listing` skill). See the `aso-playbook` skill for how ratings feed ASO.

## Targets

| Metric | Target | Context |
|--------|--------|---------|
| Average rating | 4.7+ | Benchmark against your top 3 competitors' ratings |
| Minimum viable | 4.5 | Below this, conversion drops significantly |
| Month 1 | 50+ reviews | Social proof threshold |
| Quarter 1 | 500+ reviews | Signals traction to Apple editorial |
| Year 1 | 5,000+ reviews | Competitive with established apps |

## Review Generation

### SKStoreReviewController Timing
Apple allows max 3 prompts per 365 days per device. Space strategically:

| Prompt | Trigger | Why |
|--------|---------|-----|
| 1 | After [3rd core action — enough to experience value] | User has experienced value. Likely positive |
| 2 | After [~2 weeks of regular use — e.g., 10-15 core actions] | Regular user. High satisfaction |
| 3 | After [~2 months of use — e.g., 40-50 core actions] | Power user. Likely to write detailed review |

### Pre-Prompt Satisfaction Check
Never send users to App Store review without checking sentiment first:
1. In-app: "How's [Product Name] working for you?" (positive / neutral / negative emoji)
2. Positive → trigger SKStoreReviewController
3. Neutral/Negative → in-app feedback form with email for support follow-up

This protects rating while collecting all feedback.

### Never Prompt After
Crash, error, failed purchase, [skipped/abandoned session], immediately after upgrade prompt, within 24 hrs of a push notification.

## Review Response Strategy
Content agent owns response copy and templates — see the `app-store-listing` skill. Marketing owns the operational framework:

| Rating | Response Time | Marketing Action |
|--------|-------------|-----------------|
| 5 stars | 48 hrs | Thank via Content's templates |
| 4 stars | 48 hrs | Ask what would earn 5th star |
| 3 stars | 48 hrs | Address concern, offer support email |
| 1-2 stars | 24 hrs | Specific bug → create ticket for Developer agent. Escalate |

Never ask users to change rating (Apple guidelines). Never offer incentives. Never argue.

## Review Mining (Monthly, 30 min)
1. Read all new reviews. Categorize: feature request / bug / praise / complaint / competitor comparison
2. Patterns (3+ mentions) → feed to PM agent for roadmap input
3. Track sentiment trend monthly. Drop → diagnose (bad update? aggressive paywalling? bug?)

## Rating Recovery
If rating drops below 4.5:
1. **Diagnose** (Day 1): Read recent 1-3 stars. Check crash reports. Check if recent update caused issues
2. **Fix root cause** (Days 2-7): Bug → ship fix immediately. Paywall complaint → review prompt timing
3. **Boost positive reviews** (Days 7-14): Increase prompted reviews for engaged users. Outreach to known happy users (beta testers, social)
4. **Monitor** (Days 14-30): Weekly average should trend back to 4.5+

## Launch Review Seeding
Critical for Day 1 social proof. See `launch-playbook.md`.
- Pre-launch: email beta testers personally asking for honest Day 1 review
- Target: 10+ reviews Day 1, 30+ first week
- TestFlight reviews don't transfer — beta testers must re-review on live App Store
- Never offer incentives or script reviews