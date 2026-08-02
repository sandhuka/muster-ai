# Email Copy

## Purpose
Define the methodology for writing email content — transactional emails (v1.0), lifecycle sequences, and campaign emails (post-MVP). See the `brand-voice` skill for voice application. See the `sensitive-health-copy` skill for missed-session and lapsed-user tone rules. See the `notification-copy` skill for related short-form copy patterns.

## Transactional Emails (v1.0)

These are triggered by system events via Supabase Auth. They must ship with MVP.

### Account Creation Confirmation
- **Trigger**: User creates account at subscription purchase (F-PRO-5)
- **Subject**: "Welcome to [Product Name] Premium"
- **Body structure**: Confirmation of account creation → what premium unlocks (1-2 sentences) → link to app → support contact
- **Tone**: Warm, confident, brief. This is not a sales email — they already bought.
- **Do not include**: Feature lists, tutorials, onboarding content (the app handles that)

### Password Reset
- **Trigger**: User requests password reset
- **Subject**: "Reset your [Product Name] password"
- **Body structure**: Direct instruction → reset link → expiry note → "if you didn't request this, ignore"
- **Tone**: Purely functional. No marketing, no personality.
- **Security**: Never reveal whether the email is associated with an account

### Email Confirmation
- **Trigger**: Supabase Auth email verification
- **Subject**: "Confirm your email — [Product Name]"
- **Body structure**: One sentence context → confirm link → expiry note
- **Tone**: Functional, minimal

### Transactional Email Rules
- Subject line under 50 characters
- Body under 100 words — transactional emails are not content surfaces
- Must include: [Product Name] logo/wordmark, support email in footer, unsubscribe link (CAN-SPAM, even for transactional)
- No promotional content in transactional emails (Apple and email providers penalize this)
- Plain text fallback for all HTML emails

## Lifecycle Sequences (Post-MVP)

Templates for when email marketing is added. Write templates during MVP, deploy post-launch.

### Welcome Sequence (Post-Subscription)
3 emails over 7 days. Goal: activate premium features and build habit.

| Day | Subject Pattern | Content Focus |
|-----|----------------|---------------|
| 0 | "Welcome to [Product Name] Premium" | Account confirmation (transactional — see above) |
| 3 | "Your week so far" | Recap their first few sessions, highlight the "why" (recovery logic, discipline balance) |
| 7 | "Your first week, reviewed" | Weekly summary, streak status, one premium feature highlight (e.g., weekly plan) |

### Win-Back Sequence (Lapsed Users)
Triggered after 14+ days of inactivity. Goal: re-engage without guilt.

| Email | Subject Pattern | Content Focus |
|-------|----------------|---------------|
| 1 (Day 14) | "Your routine is ready" | Simple — their next routine is waiting, no guilt |
| 2 (Day 21) | "Still here when you are" | Empathetic — acknowledge life gets busy, mention the algorithm adjusts for breaks |
| 3 (Day 30) | "A fresh start anytime" | Final touch — mention recovery reset after long absence, low-commitment CTA |

**Rules**:
- Never guilt-trip: no "We miss you!", no "Don't give up!"
- Max 3 emails in a win-back sequence — after that, reduce to monthly digest only
- Always include one-click unsubscribe

### Cancellation / Downgrade
- **Trigger**: Subscription expires (Apple webhook)
- **Subject**: "Your premium access has ended"
- **Body**: Factual — what changes (cloud sync stops, smart scheduling limited to 2/week), what stays (local data, free features). Resubscribe link. No emotional manipulation.
- **Do not include**: "Last chance!" discounts, guilt language, or countdown urgency

## Email Writing Standards

### Subject Lines
- Under 50 characters (35-45 ideal for mobile)
- No ALL CAPS words, no excessive punctuation
- Descriptive: tells the user what's inside, not teases
- One emoji max, only if it adds clarity (not decoration)

### Body Copy
- Scannable: short paragraphs (2-3 sentences max), bullet points for lists
- One primary CTA per email — don't compete for attention
- CTA button text describes the action: "See Your Routine" not "Click Here"
- Mobile-first: assume the email is read on a phone

### Footer Requirements
- Unsubscribe link (required by CAN-SPAM for all commercial email)
- Support email address
- Company name and physical address (CAN-SPAM requirement)
- Privacy policy link

## Principles

1. **Transactional emails are trust infrastructure**: The password reset and account confirmation emails are the first emails the user receives. If they feel spammy or unprofessional, trust erodes before the product relationship begins.
2. **Respect the inbox**: Every email must earn its place. If it doesn't help the user do something or know something useful, don't send it.
3. **The algorithm adjusts, and so do we**: Win-back messaging should mirror the product's philosophy — [Product Name] adapts to missed days, and so should the emails. No guilt, just readiness.
