# iOS App Store & Distribution

## Purpose
Define StoreKit 2 implementation patterns, App Review guidelines, privacy labels, and submission workflow for iOS apps. See the `ios-code-standards` skill for the shared UI library convention. See `knowledge-base/legal/` for privacy policy and ToS requirements that affect App Privacy labels.

## StoreKit 2 (In-App Purchases)
- Use the modern StoreKit 2 API (`Product`, `Transaction`) — not the legacy `SKProduct` API
- Define product identifiers as constants in a single `StoreConfig` file
- Use `Product.products(for:)` to fetch available subscriptions
- Listen for transactions with `Transaction.updates` at app launch — handle renewals, expirations, and grace periods
- Verify transactions using `Transaction.currentEntitlement(for:)` — StoreKit 2 handles receipt verification on-device via JWS
- Subscription status drives the local/remote toggle: active subscription → enable Supabase auth + remote features

## Subscription Lifecycle
- **Purchase**: Present subscription options, call `product.purchase()`, await result, unlock premium features
- **Restore**: Use `AppStore.sync()` to restore purchases on new device. Surface a "Restore Purchases" button in settings
- **Expiration/Grace period**: Transaction listener detects expiration. Downgrade to free tier gracefully — local data persists, remote features disabled
- **Refund**: Handle `Transaction.revocationDate` — downgrade immediately
- **Cancellation**: User can cancel but retains access until period ends. UI should reflect this state

## App Review Guidelines (Key Rules)
- Subscriptions must clearly display price, duration, and what the user gets before purchase
- Must include "Restore Purchases" functionality
- Domain-specific disclaimers if applicable (e.g., health/fitness apps must disclaim medical advice)
- Data deletion must be available in-app (not just "email us")
- All content must be appropriate — AI-generated content included
- Login must not be required for basic functionality (aligns with deferred-auth pattern)

## App Privacy Labels
- Declare all data types collected, linked to user identity, and used for tracking
- Declare categories matching your app's data types (e.g., Health & Fitness, Identifiers, Usage Data, Contact Info)
- "Data Not Linked to You" = data collected but not associated with user identity (analytics without user ID)
- "Data Not Collected" = data that never leaves the device (free tier local-only data)
- Cross-reference with privacy policy to ensure consistency — discrepancies cause review rejection

## Submission Checklist

### Pre-Submission
- [ ] All placeholder/test content removed
- [ ] App works without network (free tier)
- [ ] Subscription purchase, restore, and cancellation flows tested in Sandbox
- [ ] Privacy policy URL set in App Store Connect (must be publicly accessible)
- [ ] App Privacy labels match actual data collection
- [ ] Domain-specific disclaimers visible before relevant user actions (if applicable)
- [ ] Data deletion functional in-app
- [ ] Dynamic Type and VoiceOver tested on at least 2 device sizes

### App Store Connect
- [ ] Screenshots for required device sizes (6.7", 6.1", optionally 5.5")
- [ ] App description, keywords, subtitle (see Marketing agent's ASO deliverable)
- [ ] Age rating questionnaire completed
- [ ] Review notes explain subscription, AI-generated content, and any non-obvious features
- [ ] Demo account provided if login is required for review (premium features)

## Principles

1. **Transparency before purchase**: Show exactly what the user gets, for how much, for how long — before any purchase action. Apple rejects apps that obscure subscription terms.

2. **Graceful downgrade**: When a subscription expires, the app must continue working on the free tier. Never lock users out of their local data or show error states — just reduce feature scope smoothly.

3. **Privacy label accuracy**: App Review cross-checks privacy labels against actual app behavior. A mismatch causes rejection. When in doubt, declare more data collection, not less.
