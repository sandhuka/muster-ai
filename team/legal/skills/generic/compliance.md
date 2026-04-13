# Compliance Guidelines

## Purpose
Identify regulatory requirements that apply to the product and provide compliance checklists for new features. See `team/legal/skills/terms-privacy.md` for how compliance requirements flow into legal documents. See `team/legal/skills/app-store-review.md` for Apple-specific review compliance. See `team/legal/skills/fitness-claims-advertising.md` for FTC claim review methodology.

## Data Privacy Regulations

### GDPR (EU Users)
- Lawful basis required for every data type (consent, legitimate interest, or contract)
- Explicit consent required for health-adjacent data ([your product's sensitive data types — e.g., health metrics, behavioral data, biometric data])
- Rights: access, deletion, portability, rectification, objection — response within 30 days
- Data Processing Agreements required with every third-party processor (backend providers, analytics, CDN)
- Privacy by design: data minimization, purpose limitation, storage limitation
- Cross-border transfer safeguards if servers are outside EU (Standard Contractual Clauses)

### CCPA/CPRA (California)
- Disclose categories of data collected, purpose, and third parties receiving it
- Right to delete, right to know, right to opt out of sale/sharing
- "Do Not Sell or Share My Personal Information" link required if applicable
- Financial incentive disclosure if offering data-for-service exchanges (e.g., free tier collects more data)
- 45-day response window for consumer requests

### COPPA (Under-13 Users)
- If the product could attract children: implement age gate and verifiable parental consent
- Safest approach: set minimum age to 13+ in App Store settings and enforce during onboarding
- Never collect data from users known to be under 13 without parental consent

### Apple ATT (App Tracking Transparency)
- Must prompt ATT before any cross-app tracking or IDFA access
- ~75% of users opt out — design analytics to work without IDFA
- ATT not required if all tracking is first-party and stays on-device

## Health & Wellness App Regulations

### FDA — General Wellness Exemption
- Apps that promote general wellness (exercise, fitness, weight management, mental health, nutrition) are **exempt** from medical device regulation
- Exemption applies when the app: (1) makes only general wellness claims, (2) presents low risk to users, (3) does not diagnose, treat, cure, or prevent disease
- **Triggers that void the exemption**: prescribing activity for a medical condition, claiming to treat injury/illness, integrating clinical data (blood pressure, glucose) for treatment decisions, providing rehabilitation or therapeutic protocols
- Monitor FDA digital health guidance updates annually — the boundary shifts
- **If your app is NOT health/wellness**: skip this section. FDA general wellness exemption is only relevant to health-adjacent products

### FTC — Truthful Advertising
- All product claims must be truthful, substantiated, and not misleading
- Endorsements must reflect honest opinions with material connection disclosures
- Specific rules for fitness claims covered in `team/legal/skills/fitness-claims-advertising.md`

### HIPAA
- Applies only if handling Protected Health Information (PHI) from covered entities
- General consumer fitness apps are **not** HIPAA-covered unless they integrate with EHR systems, insurance, or healthcare providers
- If integrating HealthKit: Apple requires HealthKit data not be used for advertising or sold — but HealthKit alone does not trigger HIPAA

### Consumer Health Data Laws (Non-HIPAA)
State laws increasingly regulate health-adjacent data from fitness apps even when HIPAA does not apply:
- **Washington My Health My Data Act**: Treats [health-adjacent behavioral data — e.g., workout history, body metrics, fitness goals, sleep data, nutrition logs] as "consumer health data." Requires consent before collection, right to delete, restrictions on selling/sharing. Applies to any app with WA users — no revenue or size threshold.
- **Connecticut, Nevada, and emerging state laws**: Similar consumer health data protections expanding across states. Monitor legislative updates quarterly.
- **FTC Health Breach Notification Rule**: Applies to non-HIPAA apps that handle health-related data. If a breach occurs, the FTC requires notification to affected users, the FTC, and (if 500+ people) the media.

**Practical impact for cloud-backed tiers**: If your product stores health-adjacent data on remote servers, these laws apply. Requires: (1) explicit consent at the point data moves from local to cloud, (2) a breach response plan, (3) privacy policy language that meets state-specific requirements beyond CCPA.

## Two-Tier Architecture Compliance

When a product has fundamentally different data practices by tier (e.g., local-only free vs. cloud-backed premium):

| Concern | Local-Only Tier | Cloud-Backed Tier |
|---------|----------------|-------------------|
| Data controller | User controls their own data (on-device) | Company is data controller |
| Privacy policy applicability | Minimal — no data leaves device | Full privacy policy applies |
| GDPR/CCPA rights | Not applicable (no server-side data) | Full rights apply |
| Data breach notification | Not applicable | Required (72 hrs GDPR, varies by state) |
| DPA requirements | None | Required with all processors |
| Deletion compliance | App deletion = data deletion | Must provide in-app deletion + server-side wipe |
| Migration consent | N/A | Must disclose what migrates when user upgrades from local → cloud |

## Compliance Checklist for New Features

- [ ] Does this feature collect new data types? → Update privacy policy and App Privacy labels
- [ ] Does this feature make health/wellness claims? → Route through `fitness-claims-advertising.md` review
- [ ] Does this feature share data with a new third party? → Execute DPA, update privacy policy
- [ ] Does this feature target a new geography? → Check local privacy laws (GDPR, PIPEDA, LGPD, etc.)
- [ ] Does this feature involve user-generated content? → Review content moderation and IP licensing needs
- [ ] Does this feature integrate with health data sources (HealthKit, wearables, EHR)? → Re-assess FDA exemption and HIPAA applicability
- [ ] Does this feature change the free/premium data boundary? → Update two-tier privacy disclosures

## Principles

1. **Local-first is a privacy advantage**: A local-only tier is the strongest possible privacy posture — no server, no breach, no DPA. Preserve this advantage and communicate it clearly.
2. **Health-adjacent ≠ medical**: Fitness apps occupy a specific regulatory lane. Stay in it by never crossing into diagnosis, treatment, or clinical claims. The FDA exemption is valuable — protect it.
3. **Compliance is not legal counsel**: This agent provides informed guidance. Always recommend professional legal review for legally binding documents, regulatory filings, or situations with significant exposure.
