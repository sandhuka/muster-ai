# Web Onboarding Flows

## Purpose
Define the behavioral and structural design of web onboarding: anonymous-first by default, motivation before commitment, progressive profiling, permission-ask timing, sign-in mechanics (passkeys / social / magic link), activation-event identification, and the discipline that distinguishes a flow that converts from one that leaks. Web onboarding is fundamentally different from mobile-app onboarding — there is no install gate, no app-store review, and abandonment is one tab-close away. Designing for that loose grip is the job. See `team/ui-ux/skills/web-content-hierarchy.md` for the per-screen hierarchy ladder (one question per screen). See `team/ui-ux/skills/web-interaction-patterns.md` for forms, modals, and validation patterns. See `team/ui-ux/skills/web-screen-specification.md` for how each onboarding screen is specified. See `team/ui-ux/skills/web-accessibility.md` for the focus, keyboard, and screen-reader requirements that onboarding flows must meet from screen one. See `team/developer/skills/web-auth.md` for the implementation-side auth mechanics (sessions, requireUser, RBAC). Target: **product onboarding for SaaS, productivity tools, content products, and consumer apps. Not transactional checkouts (separate domain — different psychology, different patterns).**

## The Anchor: Onboarding Is the Product's First Impression

A user's relationship with the product starts at the first onboarding screen. Everything before the activation event ("aha moment") is friction; everything that *isn't required* to reach activation is friction the design owes the user.

The onboarding designer's job is to remove every step that doesn't serve activation, sequence what remains by motivation curve (high-momentum first, friction-heavy after value), and design every screen as if the user might leave on the next one (because they might).

Two truths that anchor every decision:

1. **The fastest onboarding wins.** Conversion-rate research is consistent across categories — every additional onboarding step costs ~5–20% of completions. If a step doesn't directly enable activation, prove its necessity or remove it.
2. **The user owes the product nothing.** No deserving them, no "if they really wanted it they'd…", no friction-as-filter. Every screen must justify itself in the user's terms.

## Anonymous-First Onboarding

The web's distinguishing onboarding pattern. **Demonstrate value before asking for sign-up.** Mobile apps can't easily — the install gate has already happened. Web can — and should — let the user do something meaningful before any auth.

| Product type | Anonymous-first treatment |
|--------------|--------------------------|
| Content product (newsletter, blog, news) | Read freely; sign up for personalization, save, comment |
| Productivity tool (notes, task list, design tool) | Try the core tool with no sign-up; sign up to save, sync, share |
| Generative tool (AI writer, image generator, code tool) | First N generations free; sign up to continue |
| Data tool (analytics, dashboard, reporting) | Demo workspace with sample data; sign up to connect own data |
| Marketplace / social | Browse anonymously; sign up to participate |
| B2B SaaS with strong demo | Live demo workspace; sign up to invite team |

When anonymous-first is *wrong*: regulated products (banking, healthcare), strictly multi-user (you can't really use Slack alone), or products where the entire value is personalized (a personal coach app). For these, sign-up is the first meaningful interaction — design it to be genuinely fast (passkey or social, no email-first).

### The Wall

The wall is the moment the user must sign up to continue. Place it deliberately: after the user has experienced enough value to *want* to continue. Common placements:

- After the first generated output (AI products): "Sign up to keep your generations and create more."
- After hitting a usage limit (generative or compute-heavy): "You've used your 3 free generations — sign up for 50/month."
- Before saving (productivity tools): "Sign up to save and sync."
- Before sharing or publishing (creation tools): "Sign up to share with anyone."

The wall is *not*: the first screen, the second screen, before any value is delivered, or hidden inside an interaction the user wasn't trying to perform.

## Sequencing: The Motivation Curve

Map every onboarding step to one of three categories, then sequence them.

| Category | Effect on motivation | When to schedule |
|----------|---------------------|------------------|
| **Value** (showing the product, demonstrating outcome, showing personalization) | Builds motivation | First |
| **Investment** (asking the user to make a choice, customize, commit to a goal) | Sustains motivation (commitment effect) | Middle, after value is established |
| **Friction** (sign-up, payment, permission asks, profile completion) | Drains motivation | Last possible moment, only when blocking next step |

A bad onboarding flow asks for sign-up first ("commit before knowing why"). A good flow demonstrates value, lets the user invest in setup choices (which builds psychological commitment via the IKEA effect), then gates with sign-up only at the moment further use requires it.

### The Five Stages of an Onboarding Sequence

Most successful web onboardings fit this shape. Adapt to the product's specific path to value.

1. **Welcome / Intent.** *(Optional, skip if value is self-evident.)* One screen. Set expectations. Single CTA. No carousel of features.
2. **First Value.** Get the user to produce or experience something concrete *fast*. AI tool: a generation. Notes app: a note typed. Dashboard: a workspace with sample data. Goal: under 60 seconds from landing.
3. **Personalization** (light). Two or three questions max — the questions whose answers immediately change what the user sees next. Skippable unless load-bearing for personalization.
4. **The Wall.** Sign up to continue. Single screen. One primary auth method (passkey or single social provider). Other methods behind "Other ways to sign in."
5. **Activation Setup.** Whatever single action takes the user from "signed up" to "got their aha moment." Inviting a teammate, connecting a data source, generating their first real output, importing data, etc. This is the bar — until the user does this, onboarding isn't complete.

Steps 1 and 3 are skippable depending on the product. Steps 2, 4, and 5 are the contract.

## Per-Screen Discipline

Every onboarding screen does *one* thing. The hierarchy ladder for onboarding (see `team/ui-ux/skills/web-content-hierarchy.md`) is non-negotiable here:

| Level | Content |
|-------|---------|
| Primary | The single question being asked, choice being made, or value being shown |
| Secondary | Supporting input (text field, selection options, illustration) |
| Tertiary | Progress indicator, back button |
| Hidden | Help text, "what is this?" links — available, not pushed |

What does *not* belong on an onboarding screen:
- Feature walkthroughs ("here's what our app can do")
- Marketing copy
- Multiple competing CTAs
- Sidebars or related-content panels
- Persistent navigation (the user should be focused on the current step, not browsing)

## Auth Mechanics: Picking the Sign-In Method

The modern correct stack, in priority order.

| Method | Use as primary when | Notes |
|--------|--------------------|------|
| **Passkey via Conditional UI** (WebAuthn autofill) | Default for any new product launching now | The 2025+ pattern. The user types their email; the device prompts to use a passkey if one is available — no separate "sign in with passkey" button needed. iOS, macOS, Android, Windows all support. |
| **Single social provider** (Google for B2B and consumer; Apple for consumer iOS-heavy; GitHub for dev tools) | Audience strongly overlaps the provider's user base | One button, one tap, no email entry. Don't offer 6 social providers — pick the one your audience uses most and put it first; others go behind "More options." |
| **Email magic link** | Email is genuinely the user's primary contact (newsletters, async products) | One-tap sign-in via email. Slower than passkey/social but no password. |
| **Email + password** | Compliance, enterprise sales requirement, or audience expects it | Last resort. Always offer "sign in with passkey" as an option for users who want to upgrade. |

### Conditional UI: The Modern Passkey Pattern

The default sign-in screen is a single email field plus the chosen social provider. The trick: the email field uses `autocomplete="username webauthn"` and the page calls `navigator.credentials.get({ mediation: 'conditional' })` on load. Result: when the user focuses the email field, their device offers their saved passkey as an autofill suggestion (alongside saved emails). Selecting it signs them in directly — no password screen, no separate passkey button, no extra step.

```html
<input type="email" name="email" autocomplete="username webauthn" />
```

This pattern is *invisible* to users who don't have a passkey yet (they just see normal email autofill) and *automatic* to users who do. It is the closest thing the web has to "sign in just by being you." Lead with this, not with a button-style "Sign in with passkey" — the button-style is the 2023 fallback, kept only for users whose autofill missed the passkey.

What to *not* do:
- Show all six methods on the sign-up screen with equal weight. Pick one as primary; demote the rest. Decision paralysis cuts conversion.
- Require email verification before letting the user proceed. Send the verification email, but unblock the next step. Verify when needed (e.g., before payment, before sending invitations).
- Ask for a password and a confirmation field. The confirmation field doesn't prevent typos — it prevents users. If you must ask for a password, allow show/hide and validate as the user types (this is the rare keystroke-validation case).
- Show a separate "Sign in with passkey" button as the *primary* surface. Conditional UI puts the passkey in the autofill flow; the button is a fallback for users whose autofill missed it.

### The Sign-Up Form: Two Fields Maximum

Sign-up forms collect what's needed to proceed. Two fields max:
- Email (or just a "Continue with [provider]" button if social/passkey).
- Optionally: name (only if name is needed *immediately* — for greeting, for a workspace name, for collaboration. Otherwise ask later in profile.)

Everything else (company size, role, use case, team size, industry, etc.) belongs in *progressive profiling* (next section) or, more often, doesn't belong in onboarding at all. Marketing wants this data; the user doesn't owe it during sign-up.

## Progressive Profiling

Every additional field on the sign-up form is a conversion tax. Move information collection to *after* sign-up, distributed across the natural use of the product.

| Information | When to collect |
|------------|----------------|
| Email (sign-in) | Sign-up screen |
| Display name | First time the name appears in UI (e.g., when the first message is sent, the first comment posted) — or via a one-line "What should we call you?" inside the first session |
| Workspace name | If the product is workspace-oriented, ask at workspace creation |
| Role / company size / industry | Inside an "About you" prompt the first time it's relevant for personalization, or skip permanently if not load-bearing |
| Use case / what brings you here | Better answered by tracking what the user *does* than what they *say* — usually skip |
| Goals / objectives | Only if the product personalizes around them in a way the user can perceive — otherwise it's a survey disguised as onboarding |
| Profile photo | After the user is engaged; never required |
| Phone number | Only if SMS auth or SMS notifications; never as a "just in case" |

The principle: every question is paid for in conversion. Ask only what the product genuinely uses, and ask it at the moment the use is visible.

## Cookie Consent (EU and Comparable Regimes)

For products with EU traffic (which is most products), cookie consent is the very first thing the user sees — and the way it's designed determines what every subsequent onboarding step inherits. The Apple-quality stance: **design cookie consent as the first onboarding interaction, not as an interrupting modal that fights the rest of the design.**

### What's Wrong With the Default

The vibes-coded default is an interrupting modal that:
- Covers the page on first paint, hiding the marketing message that drove the user there.
- Has "Accept all" as a giant primary button and "Reject" as a small text link — dark-pattern, often illegal.
- Triggers on every fresh visit because the user reflexively clicked the wrong choice.
- Has nothing to do with the rest of the product's voice or visual treatment.

### The Apple-Quality Pattern

- **A bottom-anchored bar or a top-anchored banner**, not a centered modal. Doesn't block content; the user can read the page while deciding.
- **Three options of equal visual weight**: "Accept all," "Reject all," "Customize." Don't make rejecting harder than accepting — that's the legal floor under GDPR and many comparable regimes.
- **No nag once chosen**: a banner closed via Accept / Reject / Customize stays closed; revisit only via an explicit settings link or on policy change.
- **Designed in the brand voice**: the same typography, the same tone, the same colors. Cookie consent is not a third-party widget; it is part of the product.
- **Persists explicit choices** (Accept / Reject / Customize) in a cookie that survives sessions; closing without choosing is *not* an explicit choice and re-prompts on next visit.
- **Loads no third-party scripts before consent** for non-essential cookies. This is a coordination point with the Developer agent — see `team/developer/skills/web-security.md` and Developer's privacy patterns.

The decision tree:

| User action | Persistence | Result this visit | Next visit |
|------------|------------|-------------------|------------|
| Accept all | Saved | All cookies set; analytics + marketing scripts load; banner closes. | Banner does not appear. |
| Reject all | Saved | Only essential cookies set; no analytics or marketing scripts. Banner closes. | Banner does not appear. |
| Customize → save | Saved | Selected categories applied; banner closes. | Banner does not appear (unless categories changed). |
| Close (X) without choosing | **Not saved** | Treat as Reject for *this* session — don't load non-essential scripts. | **Banner re-appears** — no explicit choice was made. |

This is the stricter EU-DPA reading: "ignored the banner" is not consent, and is not even a preference; the user must actually choose. Many implementations get this wrong by treating dismiss-as-reject persistently; that quietly suppresses the prompt the user never resolved.

### When Cookie Consent Isn't Required

Cookie consent under GDPR / ePrivacy is required for *non-essential* cookies — analytics, marketing, third-party embeds. A product that genuinely uses only essential cookies (session, CSRF, theme preference) doesn't need a consent banner under EU law. If you have analytics, you need the banner. If you don't, you don't. Don't ship a cookie banner "just in case" — it adds friction and signals less-trustworthy practices.

## Permission Asks (Notifications, Camera, Location, Email)

Web permission requests are one-shot. If the user denies, asking again is hostile and many browsers permanently silence the prompt. Earn the ask before requesting.

| Permission | Pre-prompt with explanation | Ask when |
|------------|----------------------------|----------|
| Notifications (Web Push) | Yes — short modal explaining what notifications the user will receive | After the user has done something the notification ties to (saved a draft, started a project, subscribed to updates). *Never* on first visit. |
| Camera / Microphone | Yes — explanation of why and what gets recorded | Right at the moment the user wants to use it (recording a video, taking a photo). Never preemptive. |
| Location | Yes — explanation of what changes with location | Right at the moment location personalizes the result (showing nearby results, setting timezone). Skippable. |
| Email marketing opt-in | Pre-checked is hostile (and often illegal under GDPR / CAN-SPAM) | Single, unchecked checkbox at sign-up, or a separate "stay updated" prompt later. Never both. |
| Calendar / contacts (OAuth) | Yes — explanation of what gets accessed and stored | At the moment the integration delivers value (scheduling, inviting). Never as part of generic sign-up. |

The *pre-prompt*: a custom modal in the product UI explaining why the permission is needed and what changes if granted. The user clicks "Continue" → the *browser* prompt appears. This pattern recovers the conversion lost to "what is this app asking for?" and lets the user say "no thanks" to your pre-prompt without permanently denying the browser permission.

## Activation Event: The Real End of Onboarding

Onboarding isn't done when the user finishes the flow. It's done when the user reaches the *activation event* — the moment they've experienced the product's value strongly enough to come back. Identify this event for the product:

| Product type | Typical activation event |
|--------------|-------------------------|
| Notes / writing tool | First note saved that the user voluntarily revisits |
| AI generation | First useful generation kept / shared / iterated on |
| Productivity / kanban | First task moved across columns |
| Analytics dashboard | First chart that surfaces a real insight |
| Collaboration tool | First message sent that gets a reply |
| Newsletter platform | First post published, or first subscriber added |

Onboarding is sequenced to push toward activation. The screen after sign-up (Stage 5) is the activation prompt — a single CTA that puts the user on the path to their first activation event.

This also makes onboarding measurable. The funnel:
1. Landing → first-value (anonymous)
2. First-value → wall reached
3. Wall reached → sign-up complete
4. Sign-up complete → activation event
5. Activation event → return visit (Day 2, Day 7)

Each step has a drop-off rate. The team's job is to identify the worst drop-off and fix the screen that produces it.

## Skip Patterns

When the user can skip a step matters.

| Step type | Skip allowed? |
|----------|--------------|
| Personalization questions (Stage 3) | Usually yes, with clear "Skip for now" link |
| Sign-up wall (Stage 4) | No — that's the wall |
| Activation setup (Stage 5) | Yes, with "Do this later" — but the product surfaces the prompt again at the next return |
| Adding a profile photo | Yes — never required |
| Inviting teammates | Yes — invite later from the workspace |
| Connecting integrations | Yes — connect when needed |

**Skip wording matters.** "Skip" sounds dismissive; "Maybe later" or "Do this later" implies the option remains open. "Skip for now" is the standard.

Don't combine "Skip" and "I'll do this later" with a sneaky default — both buttons should be clearly differentiated by visual weight (primary CTA bold, skip a text link or ghost button).

## Progress Indicators

| Onboarding length | Progress indicator |
|-------------------|-------------------|
| 1–2 screens | None — the user can see they're nearly done |
| 3–5 screens | Optional — a subtle dot indicator (●●○○○) builds momentum |
| 6+ screens | Required — but the right answer is usually "this onboarding is too long; cut it" |

Progress indicators set expectations — "I have 4 more steps" — but they also signal length. A 7-step indicator on screen 1 is its own friction. Calibrate.

## Mobile Onboarding (Responsive Web)

Onboarding on a phone is harder than on desktop. Less screen, less attention, more competing notifications, lower tolerance for forms.

- **Single-column layouts.** Always. Even on tablet. Multi-column onboarding is a desktop-first artifact.
- **Inputs sized for thumbs.** Field height ≥ 48px. Spacing between fields generous (`gap-4` minimum).
- **Native keyboard hints.** `inputMode`, `autoComplete`, and `type` set correctly so the OS shows the right keyboard (`type="email"` brings up the email keyboard, etc.).
- **Submit reachable with one thumb.** Bottom-fixed CTA on the smallest viewport when the form is short. Inline at the bottom when forms scroll.
- **Don't autoplay video.** Mobile data, autoplay restrictions, distraction.

Mobile-first onboarding (designed at 375px first, scaled up) almost always produces better desktop onboarding than the reverse — because the discipline forced by small screens removes everything that wasn't needed.

## Existing-User Edge Cases

Onboarding doesn't only run on first visit. Plan for:

- **Returning user, signed out.** Skip the welcome and personalization; go straight to sign-in.
- **Returning user, signed in but onboarding incomplete.** Resume at the last completed step.
- **Returning user, signed in, fully onboarded, comes back after dormancy.** No re-onboarding. Show a "welcome back" if appropriate (rare); usually just go to the home screen.
- **User who signed up via invitation.** Skip personalization that the inviter already provided context for; go straight to the workspace.
- **User who signs up to fix a specific need (came from a search ad for a feature).** Bias the activation prompt toward that feature. Tracking source attribution makes this possible.

Each of these is a flow variant, not a separate spec. Document the variants on the onboarding flow's screen specs as state cases.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **Sign-up wall on screen one.** "Create an account to continue" before any value has been shown. | Highest friction at the lowest motivation. Conversion cliff. | Anonymous-first onboarding; place the wall after first value (Stage 4). |
| **Multi-step sign-up form.** Email → password → name → company → role → team size → use case, all on one page or paginated. | Every field is a conversion tax. Six fields routinely cuts conversion 30–60% vs. one. | Sign-up form: 1–2 fields max. Everything else is progressive profiling. |
| **All-the-things social-auth panel.** Six provider buttons of equal weight on the sign-up screen. | Decision paralysis; user picks none and bounces. | One primary method (passkey or top-one social), "More options" behind a disclosure for the rest. |
| **Welcome carousel.** "Here's our app! [3 slides] Now sign up." | Adds 3 screens of friction with no value delivered. Skip rates approach 100%. | Skip the carousel. If the value isn't self-evident, the landing page is the wrong place to fix it. |
| **Email verification before next step.** "Check your email" blocking screen as part of sign-up. | User goes to inbox → sees other things → forgets → gone. | Send the email, unblock the next step. Verify when verification is genuinely needed (e.g., before high-value action). |
| **Pre-checked email opt-in.** "Send me product updates" checked by default. | Hostile, often illegal (GDPR), erodes trust. | Unchecked. Or skip the checkbox entirely and ask later. |
| **Notifications request on first visit.** Browser prompt at second 5. | User clicks "Block" because they don't yet know what notifications they'd get. Browser permanently silences. | Pre-prompt explaining the value; trigger the browser prompt only after the user has done something that notifications relate to. |
| **"Tell us about yourself" surveys disguised as onboarding.** Role / company size / industry / use case before the user has done anything. | Marketing-driven friction. User doesn't yet care to invest. | Skip during onboarding; collect via progressive profiling at the moment of relevance. |
| **Activation gate behind too many setup steps.** Sign up → invite team → connect integrations → import data → set goals → THEN see the product. | Most users abandon before activation. The activation event is buried. | Sequence to activation as quickly as possible; defer integrations and team invites to "later." |
| **Reset-onboarding-on-return.** User finishes 3 of 5 steps, leaves, returns — sees screen 1 again. | Repeats the friction; signals the product doesn't remember them. | Resume at the last incomplete step. Persist progress state on first action. |
| **Required profile photo / name / fields with no escape.** "Upload a photo to continue." | Friction with no proportional value. | Make optional; surface again later if relevant. |
| **Modal-only onboarding on the home screen.** A modal "tour" overlaid on the empty home screen. | Modal tours are skipped 80%+ of the time and blocked by ad blockers. The empty home screen is still empty when the modal is dismissed. | Design the empty home screen as the first onboarding step (a designed empty state with a single clear CTA toward activation). |
| **No reduced-motion handling on onboarding animations.** Welcome animation, progress transitions, success confetti — all decorative motion. | Vestibular triggers, accessibility failures, bad first impression for users who set the preference. | Specify reduced-motion alternatives (no animation or instant) for every onboarding animation. See `team/ui-ux/skills/web-accessibility.md`. |

## Output

An onboarding-flow design produces:

1. **Flow diagram** in `knowledge-base/design-specs/onboarding-flow.md` — the screen sequence, branching points, skip targets, success and error paths. Text-based (mermaid or ASCII) per the durability discipline.
2. **One screen spec per onboarding step** in `knowledge-base/design-specs/onboarding-<step>.md`, following `team/ui-ux/skills/web-screen-specification.md`.
3. **Activation event definition** in the relevant feature's section of `knowledge-base/product-spec.md` (PM owns; UI/UX provides recommendation based on flow).
4. **Funnel events list** for analytics — one event per step in the flow, plus the activation event. Marketing and PM align on these; UI/UX surfaces the full list during flow design.

## Principles

1. **Anonymous-first by default.** Demonstrate value before asking for sign-up. The web's distinguishing strength over native apps is that the install gate doesn't exist — use it.

2. **Sequence by motivation curve.** Value, then investment, then friction. The wall comes after the user wants what's behind it, not before.

3. **One question per screen.** Onboarding screens do one thing. No sidebars, no feature tours, no marketing. The hierarchy is: the question, the input, nothing else.

4. **Two fields maximum on the sign-up form.** Everything else is progressive profiling. Marketing's research questions are not the user's responsibility.

5. **Modern auth: passkey first, single social second, magic link third, password last.** Pick one as primary; demote the rest behind a disclosure.

6. **Earn every permission ask.** Pre-prompt with explanation; trigger the browser prompt only after the user has done something the permission relates to. Never on first visit.

7. **Activation, not completion, ends onboarding.** The flow ends when the user has reached the activation event — when they've experienced the value that brings them back. Track this event explicitly; it's the metric that matters.

8. **Resume, don't restart.** Persist progress on first action. A returning user who left mid-flow comes back to where they were, not to screen one. The product remembers them; the onboarding respects that.

9. **Mobile-first onboarding produces better desktop onboarding.** The discipline of designing for 375px removes everything that wasn't needed. Reverse engineering from desktop to mobile produces compromises in both directions.

10. **Every step is a conversion tax — pay it deliberately.** Each screen, each field, each permission ask, each click costs completions. Justify every one against activation; remove what doesn't earn its place.
