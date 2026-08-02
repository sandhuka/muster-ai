# Terms of Service & Privacy Policy Framework

## Purpose
Define the required sections and content for Terms of Service and Privacy Policy documents, including platform-specific requirements. See the `compliance` skill for regulatory requirements that feed into these documents and the `ip-protection` skill for IP clauses to include in the ToS.

## Terms of Service Must Include
- Service description and limitations (what the app does and doesn't do)
- Eligibility requirements (age minimums, geographic restrictions)
- Account creation and responsibilities
- Subscription terms: pricing, billing cycle, auto-renewal, cancellation, refunds
- Acceptable use policy
- Intellectual property rights (our content and user content)
- Product-specific disclaimers (prominently placed, not buried)
- Limitation of liability and warranty disclaimers
- Dispute resolution mechanism (arbitration clause if desired)
- Termination and suspension conditions
- Modification policy (how and when users are notified of changes)
- Governing law and jurisdiction

## Privacy Policy Must Include
- Identity of data controller and contact information
- Types of data collected (explicitly enumerated — name, email, health data, usage data, etc.)
- How each type of data is used (purpose-specific)
- Legal basis for processing (consent, legitimate interest, contract)
- Third parties data is shared with (named categories, ideally specific vendors)
- Data retention periods (specific timeframes, not "as long as necessary")
- User rights: access, correction, deletion, portability, objection
- How to exercise rights (specific process, response timeline)
- Data security measures (general description)
- International data transfers (if applicable)
- Cookie and tracking technology disclosure
- Children's privacy (COPPA compliance statement)
- Changes notification process
- Last updated date (prominently displayed)

## Two-Tier Architecture Privacy Pattern
When an app has fundamentally different data practices for free vs. premium users, the privacy policy must clearly disclose both tiers:

- **Free tier (local-only)**: Clearly state that no account is required, no data leaves the device, and all user data is stored locally using on-device storage. Explain what happens if the user deletes the app (all data is lost)
- **Premium tier (cloud-backed)**: Disclose that subscribing creates an account, what data is synced to the server, where servers are located, encryption in transit and at rest, and what third-party processors are involved ([your backend provider], Apple for payments)
- **Migration disclosure**: Explain the one-time data migration from local to cloud when a user subscribes — what is migrated, that it's a copy (local data remains), and that the user can request deletion of cloud data at any time
- **Presentation**: Use a clear two-column or tabbed format in the privacy policy so users can quickly see which practices apply to their tier. Don't bury the distinction in dense paragraphs

## Domain-Specific Disclaimer Template
Standard disclaimers for apps in regulated domains. Adapt to your specific domain:

### Health/Fitness Apps
- **Not medical advice**: "[Product Name] provides [fitness/wellness] information for educational and motivational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment."
- **Consult physician**: "Consult your physician or qualified healthcare provider before starting any new [exercise/wellness] program, especially if you have pre-existing health conditions, injuries, or are pregnant."
- **Risk acknowledgment**: "[Activity] carries inherent risks. You are responsible for [participating] within your own limits. Stop any [activity] that causes pain or discomfort and seek medical attention if needed."
- **No guarantees**: "Results vary based on individual factors. [Product Name] does not guarantee specific [fitness/health] outcomes."

### Financial Apps
- **Not financial advice**: "[Product Name] provides financial information for educational purposes only. It is not a substitute for professional financial advice."
- **Risk disclosure**: "Investing involves risk, including potential loss of principal."

### Educational Apps
- **Supplemental tool**: "[Product Name] is designed to supplement, not replace, formal [education/instruction]."

**Placement (all domains)**: Disclaimers must appear during onboarding (before the user starts the core activity), in the app settings, and in the Terms of Service. They must not be hidden behind multiple taps or presented in fine print.

## AI-Generated Content IP
Considerations for apps that use AI-generated visual content:

- **Ownership**: Clarify in ToS that all content assets (animations, character designs, visual content) are proprietary assets owned by the company. Users are granted a limited, non-exclusive, non-transferable license to view content within the app
- **Character personas as brand assets**: Character designs and names should be treated as brand assets. Consider trademark registration for character names if they become part of marketing identity
- **User license scope**: Users may not download, screenshot for redistribution, screen-record for sharing, or create derivative works from the content assets. Personal use only
- **AI generation disclosure**: No legal requirement to disclose AI generation method to end users currently, but monitor evolving regulations. Transparency is a brand value — consider voluntary disclosure if it supports brand positioning

## Apple App Store Requirements
- Privacy policy URL: required, must be publicly accessible (no login)
- App Privacy "nutrition labels": must accurately reflect all data practices
- Clearly categorize: data linked to identity, data not linked, data used for tracking
- Platform-specific data (e.g., HealthKit, SensorKit): must not be used for advertising, sold to data brokers, or shared without explicit consent

## Privacy & Terms Principles

1. **Two-tier transparency**: If the product's free tier is local-only and premium is cloud-backed — the privacy policy must make this distinction impossible to miss. Users should know exactly what changes when they subscribe.

2. **Specificity over boilerplate**: Generic legal language erodes trust. Name the data types, name the processors ([your backend provider], Apple), and give specific retention periods — not "as long as necessary."

3. **Placement matters**: Disclaimers hidden behind 3 taps don't count. Health disclaimers appear during onboarding, in settings, and in the ToS — prominently, not in fine print.

4. **Apple compliance is a hard gate**: Subscription management and account/data deletion are App Store requirements, not nice-to-haves. See `knowledge-base/product-spec.md` for your product's specific compliance features.
