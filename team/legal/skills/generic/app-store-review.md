# App Store Review Compliance

## Purpose
Ensure the product passes Apple App Store review on first submission and maintains compliance through updates. Focused on apps with auto-renewing subscriptions, with additional guidance for health/fitness apps. See `team/legal/skills/compliance.md` for broader regulatory context. See `team/legal/skills/terms-privacy.md` for privacy policy and ToS requirements that Apple mandates.

## Health & Fitness App Review (Guideline 5.1.3)

### What Apple Scrutinizes
- Apps that provide health or fitness data must clearly disclaim that they are not medical devices
- Health/fitness claims in metadata (title, subtitle, description, screenshots) must be accurate and not misleading
- If the app collects health-related data, Apple expects a clear explanation of how it's used and stored
- Apps must not claim to diagnose, treat, or prevent medical conditions unless they are registered medical devices

### Required Disclosures
- Health/fitness disclaimer visible during onboarding (not buried in settings)
- If using HealthKit: data must not be used for advertising, sold to data brokers, or shared without explicit user consent
- If NOT using HealthKit: do not reference HealthKit in metadata or App Privacy labels

## Subscription Compliance (Guideline 3.1.2)

### Auto-Renewal Requirements
- Clearly communicate: price, billing frequency, duration of subscription period
- State that payment is charged to the user's Apple ID at confirmation of purchase
- State that subscription auto-renews unless turned off at least 24 hours before the end of the current period
- State that the account will be charged for renewal within 24 hours prior to the end of the current period
- Provide a link or instruction to manage/cancel subscriptions (deep-link to iOS Settings > Subscriptions)
- If offering a free trial: clearly state the trial duration and what happens when it ends

### Where Subscription Terms Must Appear
- App Store description (metadata)
- Paywall screen (before purchase button)
- Terms of Service document
- Apple requires all four — missing any one triggers rejection

### StoreKit 2 Requirements
- Use StoreKit 2 APIs for all in-app purchase flows
- Implement "Restore Purchases" functionality — accessible without creating an account
- Handle subscription status changes (expiry, grace period, billing retry) gracefully
- Never lock users out of content they've paid for during Apple's billing grace period

## App Privacy Labels (Section 5.1.1)

### Accuracy Requirements
- App Privacy "nutrition labels" must exactly match actual data practices — Apple audits these
- Categorize every data type: Data Used to Track You, Data Linked to You, Data Not Linked to You, Data Not Collected
- Update labels with every app update that changes data practices

### Two-Tier Architecture Labels
When free and premium tiers have different data practices:
- Labels must reflect the **superset** of all data practices across both tiers (Apple does not support per-tier labels)
- In the App Store description, clarify which data applies to which tier
- Common pitfall: listing only free-tier data practices and omitting cloud-sync data from premium tier

### Common Data Types
| Data Type | Category | Typical Classification |
|-----------|----------|----------------------|
| Email address | Contact Info | Data Linked to You |
| [Domain-specific data — e.g., health/fitness, financial, educational] | [Relevant category] | Data Linked to You (cloud tier) / Data Not Collected (local-only tier) |
| Purchase history | Purchases | Data Linked to You |
| Product interaction | Usage Data | Data Linked to You |
| Crash data | Diagnostics | Data Not Linked to You |

**Important**: If free tier is truly local-only (no analytics, no crash reporting, no network calls), you can classify those data types as "Data Not Collected." But if you add any analytics SDK that phones home, those labels must change.

## Account Deletion (Guideline 5.1.1(v))

- Apps that support account creation must also support account deletion from within the app
- Deletion must remove the account and associated data from your servers (not just deactivate)
- Must be easy to find — Apple rejects apps where deletion is hidden or requires contacting support
- Reminder to cancel subscription must appear in the deletion flow (subscription is Apple-managed, not auto-cancelled by account deletion)
- Free-tier users with no account: "Reset All Data" (local wipe) satisfies this if no server-side data exists

## Metadata Review Checklist

- [ ] App title: no misleading claims, no competitor names, no generic terms Apple flags
- [ ] Subtitle: accurately describes core function, under 30 characters
- [ ] Description: subscription terms present (price, renewal, cancellation), health disclaimer present
- [ ] Screenshots: show actual app UI (no misleading mockups), no claims not substantiated in-app
- [ ] Keywords: no competitor brand names, no medical terms if not a medical app
- [ ] App Preview video (if used): shows real app functionality, no misleading sequences
- [ ] App Privacy labels: match actual data collection practices across all tiers
- [ ] Age rating: set appropriately (fitness apps typically 4+ unless they include intense imagery)

## Pre-Submission Review Protocol

Run this before every App Store submission (initial and updates):

1. **Privacy policy URL**: publicly accessible, no login required, covers all data practices
2. **Subscription terms**: visible on paywall screen AND in App Store description
3. **Health disclaimers**: visible during onboarding, in settings, and in ToS
4. **Account deletion**: functional, accessible from settings, includes subscription cancellation reminder
5. **Restore Purchases**: functional without requiring account creation
6. **App Privacy labels**: updated to reflect any data practice changes in this release
7. **Metadata claims**: every claim in title/subtitle/description is demonstrable in-app

## Principles

1. **First submission matters**: App Store rejections delay launch by 1-3 days minimum per resubmission. Invest in getting it right the first time — the review checklist exists for this reason.
2. **Labels = superset**: Apple Privacy labels must cover all tiers, all users, all code paths. When in doubt, disclose more, not less. Under-reporting triggers rejection and erodes trust.
3. **Subscription transparency is non-negotiable**: Apple rejects aggressively on subscription disclosure. Every surface that shows a price must also show renewal terms, cancellation instructions, and trial end behavior.
