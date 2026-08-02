# Subscription & Monetization Copy

## Purpose
Define the methodology for writing all subscription-related copy: paywall screens, plan comparisons, price display, trial language, renewal and cancellation flows, Apple compliance disclosures, and subscription state messaging. See the `brand-voice` skill for voice rules and upgrade prompt patterns. See the `notification-copy` skill for paywall prompt rotation strategy. See the `ux-writing` skill for state-based copy patterns and character budgets. See the `app-store-review` skill for Apple 3.1.2 compliance requirements. See `knowledge-base/product-spec.md` Section 5H for subscription feature specs and paywall trigger rules.

## Paywall Screen Copy

The paywall is a product screen, not a sales pitch. It explains what premium does, shows the price, and lets the user decide. No pressure, no tricks.

### Screen Structure

| Element | Budget (EN) | Budget (i18n) | Purpose |
|---------|-------------|---------------|---------|
| Headline | 40 chars | 56 chars | What premium gives you — one clear statement |
| Supporting text | 80 chars | 112 chars | One sentence expanding the headline |
| Feature comparison | 4-6 rows | See below | Side-by-side free vs. premium |
| Price display | See pricing section | -- | Monthly and annual with savings |
| Primary CTA | 20 chars | 28 chars | Subscribe action |
| Secondary CTA | 20 chars | 28 chars | Dismiss or restore |
| Apple disclosure | See compliance section | -- | Auto-renewal terms |

### Headline Patterns

Lead with the benefit, not the tier name. The user knows they are on the free tier.

| Pattern | Example | Chars |
|---------|---------|-------|
| Unlock + benefit | "Unlock smart scheduling every day" | 35 |
| Question + answer | "Ready for recovery-aware routines?" | 36 |
| Statement of value | "Your routine, smarter every session" | 37 |

Avoid: "Go Premium", "Upgrade to PRO", "Get the full experience" -- these describe the transaction, not the benefit.

### Supporting Text

One sentence that adds specificity to the headline. Not a second headline.

- "Premium uses your full workout history to plan every session around recovery and goals."
- "The algorithm tracks every muscle group and schedules your week automatically."

### CTA Buttons

| Button | Copy | Notes |
|--------|------|-------|
| Primary (subscribe) | "Subscribe" or "Start premium" | Sentence case, no exclamation mark |
| Secondary (dismiss) | "Not now" | Neutral. Never "No thanks" (implies the user should be thankful) |
| Restore | "Restore purchases" | Always visible, no account required |

## Plan Comparison Copy

The comparison should inform the decision, not manipulate it. The free tier is a real product -- do not undermine it to push upgrades.

### Feature Labels

| Feature | Free Label | Premium Label |
|---------|------------|---------------|
| Exercise library | "Full library -- all 3 disciplines" | "Full library -- all 3 disciplines" |
| Smart routines | "2 smart routines per week" | "Smart scheduling on every session" |
| Recovery tracking | "1-session recovery memory" | "Full recovery tracking across sessions" |
| Exercise variety | "3-session anti-repeat filter" | "3-session anti-repeat filter" |
| Weekly plan | "Workout history view" | "Recovery-aware 7-day plan" |
| Progress analytics | "Basic progress tracking" | "Advanced progress analytics" |
| Manual logging | -- | "Log workouts from outside the app" |
| Cloud sync | -- | "Sync across all your devices" |

### Rules

- Show features the free tier includes. "Full library -- all 3 disciplines" appears on both columns. This is not a mistake -- it communicates that the free tier is generous.
- Describe what each tier does in plain language. "2 smart routines per week" is informative. A checkmark with no explanation is not.
- Never use a red X or "locked" icon on the free column. Use a dash (--) for features that are premium-only, or omit them from the free column entirely.
- Never label the free tier as "Basic" or "Limited." It is "Free."
- Premium features use the same descriptive style -- "Full recovery tracking across sessions" not just a green checkmark.

## Price Display and Anchoring

### Price Format

Always show both plans. Annual first (it is the better value and should be the default selection).

| Plan | Display Format | Example |
|------|---------------|---------|
| Annual | Price per year + price per month equivalent | "$[annual_price]/year ($[monthly_equivalent]/month)" |
| Monthly | Price per month | "$[monthly_price]/month" |

### Savings Framing

- State the savings as a fact, not as urgency: "Save [X]% with annual" or "$[annual_price]/year -- that's $[monthly_equivalent]/month"
- Never: "Save [X]% -- limited time!", "Best value!!", "Most popular"
- The annual plan can be visually highlighted (border, subtle badge) but the copy itself should be factual, not promotional

### Apple-Compliant Price Display

- Always display the actual price charged by Apple (from StoreKit), never a hardcoded string. Prices vary by region and currency.
- Show billing frequency with every price: "$[price]/month" not just "$[price]"
- If showing a per-month equivalent for the annual plan, label it clearly: "$[annual_price]/year ($[monthly_equivalent]/month)" -- the parenthetical prevents confusion about what is actually charged

## Trial Language (Deferred to v1.0.1)

> **Status**: Not shipping in MVP. Templates written and ready for post-launch implementation. Do not surface any trial copy in v1.0.

### Trial CTA (When Implemented)

| Element | Copy | Notes |
|---------|------|-------|
| CTA button | "Start 7-day free trial" | Explicit duration in the button itself |
| Supporting text | "Try premium free for 7 days. Cancel anytime before it ends." | |
| What happens next | "After your trial, premium renews at [price]/[period]." | StoreKit price, not hardcoded |

### Trial End Messaging (When Implemented)

| Timing | Copy |
|--------|------|
| 2 days before trial ends | "Your free trial ends in 2 days. Premium renews at [price]/[period] unless you cancel." |
| Trial ended (converted) | "Welcome to premium. Your subscription renews [date]." |
| Trial ended (not converted) | "Your trial has ended. Your routines continue -- smart scheduling is available with premium." |

### Rules for Trial Copy

- Always state the trial duration in the CTA itself -- the user should never need to read fine print to know the trial length
- Always state what happens after the trial ends, including the price
- Never hide the post-trial price behind a tap, scroll, or "learn more" link
- "Free trial" is the correct term. Not "risk-free trial" (implies there was risk), not "no-commitment trial" (there is a commitment -- they will be charged if they don't cancel)

## Renewal, Restore, and Manage Subscription

### Settings Screen Copy (F-PRO-3)

| Element | Copy |
|---------|------|
| Section header | "Subscription" |
| Active status label | "Premium [Monthly/Annual]" |
| Renewal line | "Renews [date]" |
| Free status label | "Free" |
| Manage button | "Manage subscription" (deep-links to iOS Settings > Subscriptions) |
| Restore button | "Restore purchases" |
| Upgrade CTA (free users) | "View premium" |

### Restore Purchases

- Button label: "Restore purchases" -- always visible in both paywall and settings, no account required
- Success: "Purchases restored. Welcome back to premium."
- No purchases found: "No active subscription found for this Apple ID."
- Error: "Couldn't restore purchases. Check your connection and try again."

### Renewal Reminders

Apple handles renewal billing. The app surfaces renewal status factually.

- Active subscription in settings: "Renews [date]" -- no further commentary needed
- Approaching renewal (if surfaced): "Your subscription renews on [date] at [price]." -- informative, not an upsell

## Cancellation and Downgrade Flow

Cancellation happens in iOS Settings (Apple-managed). The app handles the aftermath: explaining what changes, preserving what stays.

### When Premium Expires

| Element | Copy |
|---------|------|
| Banner (first session after expiry) | "Your premium access has ended. Your routines continue with the free tier." |
| Settings status | "Free (previously Premium)" -- only show "previously Premium" for 30 days, then revert to "Free" |
| Resubscribe CTA | "View premium" |

### What Changes, What Stays

Surface this on the post-expiry banner or a dedicated "what to expect" screen accessible from settings.

| Area | What happens |
|------|-------------|
| Exercise library | "Still available -- all 3 disciplines, full library" |
| Smart routines | "2 smart routines per week (was unlimited)" |
| Workout history | "Your cloud history stays saved. View it anytime by signing in." |
| Recovery tracking | "1-session recovery memory (was full tracking)" |
| Weekly plan | "History view (smart 7-day plan paused)" |

### Rules

- Factual, not emotional. "2 smart routines per week (was unlimited)" tells the user exactly what changed. No "We'll miss you" or "Are you sure?"
- Never guilt-trip: no "You'll lose access to...", no countdown timers, no sad illustrations
- Acknowledge what they keep: the free tier is a real product. Lead with what stays, then mention what changed.
- Cloud data is preserved. Make this clear -- users fear data loss on cancellation. "Your cloud history stays saved" resolves that anxiety immediately.
- Mid-session downgrade: "Your current session continues normally. Free tier starts after this workout." (per product spec: premium features lock after the session ends)

## Apple 3.1.2 Required Disclosures in Product Voice

Apple requires specific auto-renewal disclosures on every surface where a purchase can be made. These disclosures are non-negotiable -- but they do not have to read like a legal document.

### Required Substance (From Apple)

Apple mandates that the following information appears near the subscribe button:

1. Price and billing frequency
2. Subscription auto-renews unless canceled at least 24 hours before the end of the current period
3. Account is charged for renewal within 24 hours prior to the end of the current period
4. Subscriptions are managed in iOS Settings
5. Any unused portion of a free trial is forfeited upon purchase of a subscription

### Product Voice Rewrites

Rewrite the required disclosures in the same voice as the rest of the paywall -- sentence case, short sentences, direct, helpful. The user should never feel a tonal shift between the feature comparison above and the terms below.

**v1.0 (no trial)**:

> Payment is charged to your Apple ID at confirmation. Your subscription renews automatically each [month/year] at [price] unless you turn off auto-renewal at least 24 hours before it renews. Manage or cancel anytime in iOS Settings > Subscriptions.

**v1.0.1 (with trial -- deferred)**:

> Your free trial lasts 7 days. After that, your subscription renews automatically at [price]/[period] unless you cancel at least 24 hours before it renews. Payment is charged to your Apple ID. If you subscribe during a trial, the remaining trial days are forfeited. Manage or cancel anytime in iOS Settings > Subscriptions.

### Rules

- Place disclosure text directly below the subscribe button, not behind a scroll or a "terms" link
- Use the same font weight and size as other supporting text on the screen -- never reduce it to fine print
- "[price]" and "[period]" are dynamic values from StoreKit, never hardcoded
- "Turn off auto-renewal" and "manage or cancel" are both acceptable phrasings -- the key is that the user knows where to go (iOS Settings > Subscriptions)
- This copy must also appear in the App Store description metadata (see the `app-store-listing` skill)
- Legal agent approves substance, Content agent approves voice. Both sign off before shipping.

## Subscription State Copy

The app must handle every subscription lifecycle state with clear, calm messaging. No state should leave the user confused about their access level.

### State Messages

| State | Where Shown | Copy |
|-------|-------------|------|
| Active (monthly) | Settings | "Premium monthly -- renews [date]" |
| Active (annual) | Settings | "Premium annual -- renews [date]" |
| Free | Settings | "Free" |
| Expired | Settings + banner | "Your premium access has ended." Settings: "Free." |
| Grace period | Settings | "Premium -- payment issue. Update your payment method in iOS Settings to keep premium." |
| Billing retry | Settings | "Premium -- payment pending. Apple is retrying your payment." |
| Revoked (refund) | Settings + banner | "Your subscription was refunded. You're on the free tier." |

### Grace Period and Billing Retry

Apple provides a grace period (typically 6-16 days) when a renewal payment fails. During this time, the user should retain premium access.

- Do not lock the user out during grace period or billing retry
- Inform them factually: "Update your payment method in iOS Settings to keep premium"
- Never blame the user: "Your payment failed" reads as accusatory. "Payment issue" is neutral.
- After grace period expires with no resolution, treat as expired -- use the standard expiry messaging

### State Transitions

When a user's state changes, the first session after the change should surface a brief, clear message.

| Transition | Message |
|------------|---------|
| Free to premium | "Welcome to premium. Smart scheduling is on for every session." |
| Premium to expired | "Your premium access has ended. Your routines continue with the free tier." |
| Expired to resubscribed | "Welcome back to premium. Your history and preferences are right where you left them." |
| Grace period to resolved | No message needed -- premium continues silently |
| Grace period to expired | Same as premium to expired |

## Principles

1. **Inform, never pressure**: Every subscription screen is an information surface, not a sales floor. Present the value, show the price, let the user decide. Copy that reads like a sales pitch violates the Intelligent Coach voice.

2. **The free tier is a real product**: The product's free tier includes all 3 disciplines, 2 smart routines per week, and recovery memory. Never undermine it to make premium look better. Users who feel tricked into upgrading cancel faster than users who upgrade because the value was clear.

3. **Positive framing on every surface**: "2 smart routines per week" (what you get) not "Limited to 2 smart routines" (what you lack). "Your routines continue with the free tier" (what stays) not "You've lost premium access" (what's gone). Frame every state as what the user has, not what they lost.

4. **Compliance is copy, not fine print**: Apple 3.1.2 disclosures are written in product voice, at the same font size and weight as surrounding text, placed where users naturally read. If the disclosure reads like a different product wrote it, rewrite it.

5. **Repetition demands rotation**: Paywall trigger 2 fires weekly. Any copy the user sees on a recurring basis needs a rotation pool (see the `notification-copy` skill for the variant strategy). The same message every Monday breeds annoyance, not conversion.

6. **Dynamic values, never hardcoded prices**: All prices, dates, and periods come from StoreKit or the subscription state. A hardcoded price string will be wrong in every non-US market and will break if pricing changes. Use placeholders that resolve at runtime.

7. **No dark patterns**: No fake urgency ("Last chance!"), no guilt ("You'll lose everything"), no misdirection (making the dismiss button hard to find), no confirm-shaming ("No, I don't want smarter workouts"). These tactics violate brand voice, damage trust, and increasingly trigger App Store rejection.
