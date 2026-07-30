# Web Emails and System Messages

## Purpose
Define the design discipline for the messaging surfaces that live *outside* the product but inside the user's relationship with it: transactional emails (welcome / magic link / receipts / password reset / invitations / weekly digest), the rendering constraints email actually has (Outlook tables, dark-mode email rendering, image-blocked fallback, mobile-first email layout), and the cross-channel coordination between email, push notifications, and in-app messaging that prevents notification fatigue. Email is the most-overlooked product surface — vibes-coded LLM output produces emails that look broken in Outlook, fail in dark mode, stack three CTAs in a transactional notification, and contradict in-app messaging — and yet email is often the user's *most-frequent* product touchpoint outside the app itself. See the `web-design-system` skill for the tokens emails consume (with the constraint that most aren't usable directly — emails need inline values). See the `web-onboarding-flows` skill for the welcome-email + magic-link flows that sit at the edge of onboarding. See the `web-empty-error-and-edge-states` skill for the error-message voice that extends to email error notifications. See the `web-interaction-patterns` skill for the in-app toast / banner patterns email coordinates with. See the `web-marketing-and-conversion-pages` skill for marketing emails (which follow marketing voice and conversion discipline distinct from transactional). See the `web-localization-and-i18n` skill for locale-aware email rendering (date / number / currency formatting per recipient locale; subject-line plurals via ICU; sender name in the recipient's language). See the `web-security` skill for the deliverability discipline (SPF, DKIM, DMARC, BIMI verification) that the design depends on. Target: **product transactional emails (sent in response to user action or system event) + cross-channel messaging coordination**.

## The Anchor: Email Is a Product Surface, With Real Constraints

Two things are true and shape every decision in this skill:

1. **Email is part of the product.** A welcome email with a broken layout, a receipt with no line items, a magic-link email with confusing instructions — each one is a brand impression and a user-experience defect equivalent to a broken screen. Apple-quality products treat email design with the same care as in-app design.

2. **Email rendering is constrained.** No JavaScript. No external `<style>` for many clients. Outlook 2019 LTSC and Outlook on Windows (legacy) still render with Word's HTML engine — table-based layout required there. **The new Outlook for Windows** (rolling out as default since 2023) uses WebView2 / Chromium and supports flexbox, grid, and modern CSS — most of your Outlook opens in 2025–2026 are on this engine, not the legacy one. Dark-mode rendering varies (Apple Mail respects `prefers-color-scheme` reliably; Gmail's support is partial and inconsistent across mobile / web / Workspace; Outlook varies by version). Images may be blocked by default. The CSS subset that works reliably *as a fallback* across all major clients is small; modern clients support much more. Modern correct: **progressive enhancement** — table-based layout fallback for legacy clients, flex/grid enhancement for everything else.

The Apple-quality stance: design emails for the constraints from screen one, not as an afterthought translated from a web mockup.

## The Email Stack: What Works, What Doesn't

| CSS feature | Works reliably | Notes |
|-------------|---------------|-------|
| Inline styles on every element | ✅ | The default. Style externally for development; inline for sending. |
| `<style>` in `<head>` | ⚠️ | Most modern clients support; legacy Outlook (2007–2019, Outlook on Windows pre-2023) strips. Don't rely on alone. |
| Table-based layout | ✅ | Required for *legacy* Outlook (2019 LTSC, old Outlook for Windows) as a fallback. Modern clients render fine; new Outlook (WebView2-based, default since 2023) handles modern CSS. |
| Flexbox / Grid | ⚠️ | Modern clients (Apple Mail, Gmail web, new Outlook for Windows, Outlook web): yes. Legacy Outlook: no. Use as **progressive enhancement** layered over a table fallback, not as the primary layout. |
| `<img>` | ✅ | But may be blocked; design must work without. |
| `<svg>` | ⚠️ | Inconsistent support; raster fallback recommended. |
| Web fonts | ⚠️ | Apple Mail, modern Gmail support; Outlook ignores. Provide system-font fallback. |
| Media queries | ✅ | Used for responsive + dark-mode email. Most modern clients support. |
| `prefers-color-scheme` | ⚠️ | Apple Mail respects reliably. Gmail's support is partial and inconsistent across mobile / web / Workspace — don't rely on it alone for Gmail audiences. Outlook varies by version. Design explicit dark variants and accept that Gmail will sometimes apply its own auto-inversion regardless. |
| Custom properties (CSS variables) | ⚠️ | Modern clients; Outlook ignores. Don't rely. |
| Background images | ⚠️ | Outlook needs VML fallback; complex. Avoid for critical content. |
| Buttons (`<button>`) | ❌ | Don't render as buttons in email. Use styled `<a>` tags as "buttons." |
| Forms (`<input>`, `<form>`) | ❌ | Most clients strip. Email is read-only — actions are links to the product. |

Use a tested email-framework library rather than rolling your own. **Default for this stack: `react-email`** (React-component model that compiles to email-safe HTML, integrates cleanly with React 19 / Next.js 15 / TS strict). Acceptable alternative for non-React stacks: MJML. Hand-rolling tables for cross-client compat is wrong by default; the frameworks have already solved the well-known compatibility traps.

## Email Layout: Mobile-First, Single Column, 600px Cap

The constraints converge on a small set of layout rules:

- **Single column.** Multi-column layouts break unpredictably across clients. Mobile users are ≥60% of email opens; single-column is the right default for them anyway.
- **Maximum width: 600px.** This is the empirically-tested cap that renders correctly across all major clients (Outlook in particular).
- **Body type: 16px minimum.** Smaller body type fails on mobile; many users read in low-light or with reading glasses.
- **Generous spacing.** Email feels different from product UI — more breathing room reads as professional. 24–32px between sections is standard.
- **Mobile-first**: design at 375px viewport first; the desktop view (600px container) gets generous side padding.

### The Skeleton

```
┌──────────────────────────────────────────────────────────────┐
│  [Logo, 24–32px high, brand color or single-color]           │
│                                                              │
│  ─────────────────────────────────────────────────────────   │
│                                                              │
│  Headline (text-h2 size, brand color, 1–2 lines max)         │
│                                                              │
│  Body paragraph in 16px regular, comfortable line-height     │
│  (1.5–1.6), readable contrast, brand-voice copy.             │
│                                                              │
│  Optional: a second paragraph if genuinely needed.           │
│                                                              │
│  ┌─────────────────────────┐                                 │
│  │  Primary action         │  ← styled <a> as a button       │
│  └─────────────────────────┘                                 │
│                                                              │
│  Optional: small text below the button if context needed.    │
│                                                              │
│  ─────────────────────────────────────────────────────────   │
│                                                              │
│  Footer:                                                     │
│  • One sentence company / product context                    │
│  • Unsubscribe link (legal requirement for marketing,        │
│    courtesy for transactional)                               │
│  • Physical address (CAN-SPAM in US)                         │
│  • Settings / preferences link                               │
└──────────────────────────────────────────────────────────────┘
```

That's it. Most transactional emails fit this skeleton. Marketing emails extend it (more sections, more imagery), but the skeleton holds.

## Subject Line and Preheader

The subject line and preheader are 80% of the email's design surface. The user decides whether to open based on these alone.

- **Subject line: 30–50 characters.** Mobile inboxes truncate around 40 characters. The most important word goes first.
- **Preheader: 50–100 characters.** The text shown next to or below the subject in the inbox preview. Many emails ship with the preheader as "View this email in your browser" — a wasted surface. Use the preheader to extend the subject's value proposition.
- **Specific over generic.** "Your receipt for order #1042" beats "Order confirmation." "Sarah invited you to Q2 Planning" beats "You have a new invitation."
- **No false urgency.** "OPEN NOW!" "Don't miss out!!" reads as spam and degrades sender reputation.
- **No emoji as the primary message.** A single emoji as accent is fine; emoji-stuffed subject lines look like phishing.
- **Sender name is product, not "noreply"**. "Linear" or "Notion" beats "noreply@notion.so." `noreply@` addresses are also user-hostile (replies bounce silently). Use a real reply-to address.

## Per-Email-Type Discipline

### Welcome Email

Sent immediately after sign-up.

- **Single primary action**: the next step toward activation. Not "explore all our features" — the *one* most important next step.
- **Brief context**: who you are, what they signed up for, what to expect next.
- **No feature dump.** Don't list every feature in the welcome email; users skim. One CTA, one paragraph of framing.
- **Tone matches the product's voice** — warmer than a receipt, more personal than a marketing blast.

### Magic Link

Sent in response to a sign-in attempt.

- **Single CTA**: the magic link itself. Make it a prominent button.
- **Expiration noted**: "This link expires in 15 minutes."
- **Security note**: "If you didn't request this, you can ignore this email."
- **Plain text version is critical** — many security-conscious users disable HTML; the link must work in plain text.
- **Send fast.** Magic-link emails delayed > 30 seconds produce abandoned sign-ins. Coordinate with Developer for transactional-email reliability (the `web-observability` skill).

### Password Reset

Same shape as magic link.

- **Single CTA**: the reset link.
- **Time-limited expiration**: "This link expires in 1 hour."
- **"If you didn't request this"**: clear, non-alarming. Users frequently *do* request it (forgot they did) — don't shame them.
- **Don't reveal whether the email exists in the system**. The same response goes regardless of whether the email is registered (security best practice).

### Receipt

Sent after a payment.

- **Scannable**: total prominent, line items clear, tax/shipping/discount broken out.
- **Single column for items**, with clear right-aligned amounts (use tabular figures so digits align).
- **Receipt number**: visible, copyable, useful for support.
- **Order date and payment method**: clear and present.
- **Refund / contact-support link**: in the footer; users find it when they need it.
- **No marketing in the receipt.** A receipt is transactional; bundling it with "check out our other products!" is hostile and may be illegal under CAN-SPAM (transactional emails have stricter content rules than promotional).

### Invitation

Sent when one user invites another.

- **Who invited me**: real name, real avatar if available.
- **Why**: the workspace / project / team being invited to, with brief context.
- **Single primary CTA**: "Accept invitation."
- **Expiration**: invitations should expire (security + clarity).
- **Decline option**: if invitations can be declined, link in the email; otherwise, "ignore to decline."

### Weekly / Periodic Digest

Sent on a schedule.

- **Summary first**: the value of the week in 1–2 lines. "Your team shipped 12 features this week" / "3 new comments on items you follow."
- **Top items, not everything**: 5–10 items max, with a "see all" link to the product.
- **Easy unsubscribe per digest type**: digests are the most-frequent unsubscribe driver; respect the user's preference to opt out without losing transactional emails.
- **Variable length**: a digest with no activity is shorter, not stuffed with filler.
- **Respect "no activity" weeks**: an empty digest can be skipped entirely (better) or sent as a short "It was a quiet week" (acceptable). Stuffing it with marketing fills nobody well.

### System Notifications

Sent in response to product events the user opted into (mention, comment reply, status change).

- **Subject line names the event**: "Sarah commented on Q2 Planning" not "New activity in your workspace."
- **Body shows the content**: the comment text, the status that changed, the document edited. The user shouldn't have to click through just to see what happened.
- **Single CTA back to context**: "Open in product."
- **Reply-by-email** for messages: when supported, makes the email transactional in both directions. (Implementation in the `web-security` skill → webhook signature verification.)

## Image-Blocked Fallback

Many clients (Outlook desktop, Gmail with images-off, conservative corporate IT) block images by default. The email must still work.

- **Every `<img>` has a meaningful `alt` text.** "Your product logo" or "Sarah's avatar" — not "image" or empty.
- **Critical content is text, not in an image.** A button rendered as an image is invisible if images are blocked. Render buttons as styled `<a>` tags.
- **Logo as text fallback**: if the brand logo is an image, the company name is also visible as text below or beside.
- **Test with images disabled**: Gmail's "Display images below" setting hides everything; the email should still convey the message.

## Dark-Mode Email

Email-client dark-mode handling varies wildly:

- **Apple Mail (iOS, macOS)**: respects `@media (prefers-color-scheme: dark)` reliably if you provide one; otherwise applies its own (sometimes-strange) automatic dark-mode treatment.
- **Gmail (mobile / web / Workspace)**: support is partial and inconsistent across surfaces. Some versions respect `prefers-color-scheme`; many apply their own auto-inversion regardless. Don't rely on the media query alone for Gmail audiences — explicit color settings on every styled element are what survive Gmail's inversion.
- **Outlook (desktop / web / new-Outlook-on-Windows)**: behavior varies by version; new Outlook (WebView2-based) is closer to web standards.

The pragmatic approach:

- **Design for both light and dark modes explicitly.** Set explicit `background-color` and `color` on every styled element so Gmail's automatic inversion doesn't produce unreadable combinations.
- **Use `prefers-color-scheme` media query** for clients that support it (Apple Mail), and accept that Gmail will do its own thing.
- **Test the email in both modes** in Gmail mobile, Apple Mail, and the version of Outlook your audience uses. Don't ship without this.
- **Logo dark-mode variant**: if the logo is dark on light, provide a light-on-dark variant (via `prefers-color-scheme` or via "PNG with transparent background and a fill-color hack" depending on your audience).

## Plain-Text Version

Every email must have a plain-text alternative (`Content-Type: multipart/alternative`):

- **Spam scoring**: emails without a plain-text alternative score higher in spam filters.
- **Accessibility**: some screen-reader users prefer plain text.
- **Users who disabled HTML**: rare, but a real audience.
- **Searchability**: plain text is greppable in mail clients in ways HTML isn't.

The plain-text version isn't an afterthought — it's a real email. Shape it like a brief note: greeting, message, the URL of the action (literally written out, not "click here"), sign-off.

## Cross-Channel Coordination: Email + Push + In-App

The single biggest mistake in multi-channel messaging: **the same notification across email, push, and in-app simultaneously.** The user sees the same message three times in 30 seconds and learns to ignore your notifications.

The Apple-quality coordination:

| Event severity | Email | Push | In-app |
|---------------|-------|------|--------|
| **Critical** (security, payment, account) | Yes (always; users may not have push) | Yes (immediate) | Yes (banner, persists) |
| **Important** (mention, direct message) | Optional digest; not immediate | Yes (immediate) | Yes (toast or badge) |
| **Informational** (weekly digest, activity summary) | Yes (digest) | No | Yes (subtle indicator) |
| **Marketing** (new features, content) | Yes (opt-in) | No (don't push marketing) | Yes (subtle banner, dismissible) |

Rules:

- **The same event is one notification per channel, not one per channel simultaneously.** A mention sends a push *or* an email (typically push if the user is mobile-app-active, email if not). A digest collects the day's mentions if push wasn't sent.
- **User controls per type.** Users can disable email digests independently of transactional emails; disable push for one event type and not another. Granular controls beat all-or-nothing.
- **Pre-prompt for permissions.** Push permission asked only after the user has done something the push relates to (see the `web-onboarding-flows` skill → Permission Asks).
- **Quiet hours.** Don't push at 3 AM in the user's timezone. Most products respect a 9pm–8am quiet window; some compress to even narrower.
- **Snooze and mute.** A user who's overwhelmed should be able to mute everything for a day or a week without losing the underlying notifications (catch up on return).

### Channels Beyond Email + Push + In-App

The cross-channel matrix above lists email, push, and in-app. Real product messaging fans out further; coordination matters across all of them.

#### SMS

For phone-number-auth products, OTP delivery, account-security alerts, or markets where SMS is the primary contact channel.

- **160-character segment limit** (extended messages split into multi-part). Subject line discipline doesn't apply (no subject); the *first 160 characters* are the message.
- **No formatting**: plain text. No bold, no images, no links rendered other than as the URL itself.
- **Sender ID**: products send from a registered short code (high deliverability, US-specific) or a long code (lower trust, cheaper). For US A2P traffic, register via 10DLC; non-registered SMS is increasingly throttled and may not deliver.
- **Severity floor**: SMS is intrusive. Reserve for genuinely time-critical (OTP, account security) or user-explicitly-opted-in (delivery notifications, appointment reminders). Marketing-by-SMS without explicit opt-in is illegal in most jurisdictions and a trust failure everywhere.
- **GDPR + TCPA**: explicit opt-in required for non-transactional SMS in most markets. Track and store the consent record.

The cross-channel matrix extends: SMS is the highest-severity push-class channel; use it for the things you'd push but the user can't be reached by app push (no app installed, push permission denied).

#### Web Push vs. Native Push

These are different channels with different constraints, despite the shared word "push."

| Concern | Web Push (browser) | Native push (iOS / Android app) |
|---------|-------------------|----------------------------|
| Permission model | Browser one-shot prompt; denial is often permanent | OS-level prompt; iOS allows one re-prompt after denial |
| Service worker required | Yes | No (app handles) |
| Title length | ~50 chars before truncation | ~30 chars (iOS), ~40 chars (Android) |
| Body length | ~150 chars | ~100 chars |
| Rich content (images, actions) | Limited; iOS PWA does not support actions | Full support on iOS + Android |
| Action buttons | Chromium browsers only; iOS PWA: no | Yes |
| Reliability | Depends on browser running, system online | Higher (OS handles) |

Specs that say "send a push" must say *which* push — web push to PWA installations, or native push to mobile apps. Conflating produces specs that don't ship cleanly: a "push with two action buttons" can't be web-pushed to an iOS PWA, but the spec doesn't say so until implementation.

#### Browser-Tab-Title Notifications

The `(3) Inbox – ProductName` pattern in the browser tab title is a real notification channel for in-app activity (unread mentions, queued items, processing-complete signals).

- **Update `document.title` carefully**: changing the title triggers screen-reader re-announcement on most SR setups, which can be annoying if titles change rapidly. Throttle or batch updates.
- **Pair with favicon-with-badge** (a small badge dot on the favicon) for users who have the tab in the background. Implementation: dynamic favicon swap or `<link rel="icon">` update.
- **Reset on focus**: when the user returns to the tab, clear the unread-count from both title and favicon.
- **Don't compete with the OS notification system**: title-flicker is for users who already have your tab open. OS notifications are for users who don't.

This is a small surface but a real one — the user's tab strip is the cheapest brand surface to claim.

## Voice Across Channels

Brand voice is consistent across email, push, and in-app:

- **Email**: warmer, more space for personality. Welcome, weekly digest, marketing — these are the longest-form expressions of voice.
- **Push**: terse by necessity. Subject-line discipline (30–50 characters maximum). Voice still shows through — "Sarah replied" beats "New reply."
- **In-app**: between the two. Toasts are brief; banners can be longer; both follow the brand voice.

Coordination with the Content agent: voice belongs to Content; structure (when to send what, on which channel) belongs to UI/UX. Specs ship with structural rules and copy placeholders; Content fills in the brand voice.

## Sender Discipline

Email reputation is hard-won and easy to lose. The design choices that affect deliverability:

- **Sender name** is the product, not "noreply." Clear and recognizable.
- **From-address domain** matches your product domain (proper SPF, DKIM, DMARC — Developer's responsibility, but the design implication is consistency).
- **Unsubscribe is one click**, accessible from every email. Hidden or multi-step unsubscribes generate spam complaints, which damage deliverability for everyone.
- **Send frequency**: respect the user's implicit preference. A user who opens 1 of 10 emails wants 1 a week, not 10.
- **Re-engagement attempts**: a user who hasn't opened in 6 months should be auto-pruned, not re-emailed harder.

### `List-Unsubscribe` Headers (RFC 8058)

The visible "Unsubscribe" button that appears in the Gmail / Apple Mail inbox header — the one that meaningfully reduces spam complaints — is rendered by the mail client only when the email ships with `List-Unsubscribe` and `List-Unsubscribe-Post` headers. A footer-only unsubscribe link doesn't trigger it.

```
List-Unsubscribe: <mailto:unsubscribe@example.com?subject=unsubscribe>, <https://example.com/unsubscribe?token=...>
List-Unsubscribe-Post: List-Unsubscribe=One-Click
```

Both `mailto:` and `https:` variants are now table stakes (Gmail / Yahoo / Apple Mail all surface the inbox-header button when both are present and `List-Unsubscribe-Post` is `One-Click`). The implementation is Developer-side; the design responsibility is requiring the headers on every marketing / digest email and pointing the `https:` variant at a one-click unsubscribe endpoint that doesn't ask for a confirmation.

### BIMI: Verified Brand Logo in Inbox

BIMI (Brand Indicators for Message Identification) shows your verified brand logo next to messages in the Gmail / Apple Mail / Yahoo Mail inbox list. Real estate that's invisible without setup; a brand impression on every send when configured. Requires:

- **DMARC enforcement** (`p=quarantine` or `p=reject`) — Developer-side; coordinate with the `web-security` skill.
- **A VMC (Verified Mark Certificate)** for Gmail / Apple Mail; SVG variant for Yahoo. Vendor: DigiCert / Entrust; cost ~$1–2k/year.
- **An SVG logo file that meets the BIMI spec**: SVG Tiny PS profile, square (1:1 aspect), centered subject within safe area, no transparency. **The design contribution is producing this asset**; deliverability is Developer.

Worth doing for any product with a brand investment and meaningful inbox volume — the logo in the inbox is one of the cleanest brand surfaces on the web.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **Image-only emails.** Email is one big image; no text. | Broken when images are blocked (common); inaccessible to SR users; bad for spam scoring. | Email is text-first; images are decoration. Every `<img>` has meaningful `alt` text; critical content is text. |
| **`<button>` elements in email.** Native buttons that don't render. | Outlook and many clients strip buttons; the action becomes invisible. | Styled `<a>` tags rendered to look like buttons. |
| **Multiple CTAs in transactional emails.** Receipt with "Buy more!" + "Refer a friend!" + "Update settings." | Dilutes the primary action; legally questionable (CAN-SPAM treats transactional more strictly than marketing); reads as spammy. | One primary CTA per transactional email. Marketing pitches go in marketing emails (separately opted into). |
| **"OPEN NOW!" subject lines.** All-caps, multiple exclamation points, fake urgency. | Spam-filter triggers; phishing-adjacent feel; trains users to ignore your sender. | Specific, calm, value-forward subject lines. |
| **Same notification across email + push + in-app simultaneously.** | Notification fatigue; user disables all channels. | One event = one notification per channel, coordinated by the system. Use digests for batched events. |
| **Welcome email that lists every feature.** Six bullet points, three CTAs, "explore everything we offer!" | Users skim and remember nothing. The activation event is buried. | One CTA, one paragraph, point at the next step toward activation. |
| **Receipts with marketing.** "Thanks for your order — check out our other products!" | Possibly illegal under CAN-SPAM; user trust degrades; receipts are forwarded to accounting and the marketing reads as inappropriate. | Pure transactional content. Marketing in separate, opted-in emails. |
| **Password-reset emails that reveal account existence.** "We didn't find an account for that email" → "If an account exists, we sent a link" different responses. | Leaks account-enumeration information; security failure. | Same response regardless of whether the account exists. The email simply doesn't arrive if there's no account. |
| **Magic-link emails that delay > 30 seconds.** Slow transactional pipeline. | Users abandon the sign-in; treat the system as broken. | Coordinate with Developer for transactional-email reliability. |
| **Weekly digest with no actual summary.** "Click here for updates" with no content in the email. | Defeats the purpose of a digest (which is to summarize); user clicks through, sees small updates, becomes annoyed at the email. | Real summary in the email body; the link is for the long-tail follow-through, not the summary. |
| **No plain-text version.** HTML-only emails. | Spam-score penalty; accessibility failure; some users disable HTML. | Always send `multipart/alternative` with both HTML and plain-text. |
| **Sender name "noreply@example.com" with no recognizable product.** | User doesn't recognize the sender; deletes or marks spam. | Sender name is the product; reply-to is a real address (or product-specific support address). |
| **Hidden or multi-step unsubscribe.** A "click here to manage preferences" → confusing settings page → "deselect all to unsubscribe." | Spam complaints (which damage deliverability for everyone); user marks as spam instead of fighting through unsubscribe. | One-click unsubscribe accessible from every email. |
| **Push notifications at 3 AM.** No timezone respect. | User wakes up; disables push; loses the channel forever. | Quiet hours by default (typically 9 PM – 8 AM in user's TZ); user override available. |
| **Marketing emails disguised as system notifications.** "Your weekly summary" with mostly promotional content. | Trust degrades; spam complaints; legal issues. | Honest about what's transactional, what's marketing. Separate opt-ins. |
| **"Click here" as link text.** Anchors that say "Click here" or "here" with no descriptive text. | Screen readers read links out of context; users navigating by link list hear "here, here, here." A11y + SR-discoverability failure. | Descriptive link text: "Open invoice," "Reset password," "Confirm your email." |
| **Animated GIF in transactional email.** A spinning loader or celebratory confetti GIF in a receipt. | Distracts from the action; bandwidth cost; accessibility issue (no `prefers-reduced-motion` in email). | Static images only in transactional. Animated GIF is acceptable in marketing emails when explicitly designed. |
| **Tracking pixel that renders as a broken-image icon.** When images are blocked, the pixel shows as a tiny broken-image marker in the email body. | Visible debris in the email; signals tracking; degrades trust. | Position tracking pixels in the footer or in a margin area where the broken-image marker is invisible. Or skip the pixel entirely. |
| **HTML-only React rendering of regular React components for email.** Server-side-rendering ordinary React UI components and shipping the HTML. | The output uses div / flex / modern CSS that breaks across legacy clients. | Use `react-email` primitives (table-based, email-tested) — not your product's UI components. |
| **"Don't reply to this email" instructions paired with a `noreply@` sender.** | Hostile when paired with the skill's own "real reply-to address" rule. Users do reply; replies bounce silently. | Real reply-to address; or, if a unidirectional email is genuinely correct, route the reply to a support inbox or auto-responder that opens a ticket. |
| **Template-render failure showing through.** "Hi {{first_name}}!" or "You have {{count}} new messages." | Common shipping bug; signals "this product is broken." | QA every template with realistic + edge-case (empty / null) variable values before send. Server-side validation that no `{{` survives the render. |
| **Footer-only unsubscribe with no `List-Unsubscribe` headers.** | The Gmail / Apple Mail inbox-header unsubscribe button doesn't appear; users mark spam instead. | Ship `List-Unsubscribe` + `List-Unsubscribe-Post: List-Unsubscribe=One-Click` on every marketing / digest email. |
| **No BIMI for high-volume brand sender.** A product with brand investment ships emails with no inbox-list logo. | Free brand surface ignored; competitors with BIMI look more legitimate. | Configure DMARC enforcement + VMC; ship the SVG logo file per BIMI spec. |
| **Conflating web push with native push in the spec.** "Send a push with two action buttons" specced for an iOS PWA. | iOS PWAs don't support push action buttons; the spec doesn't ship as written. | Specify which push channel (web push to PWA / browser, or native push to installed mobile app); design within that channel's actual constraints. |
| **Push permission asked on first visit.** Browser's prompt at second 5. | User clicks "Block" because they don't yet know what notifications they'd receive. Browser permanently silences. | Pre-prompt explaining value; trigger browser prompt only after the user has done something push relates to. |

## Output

An email + system-messaging design produces:

1. **Per-email-type spec** in `knowledge-base/design-specs/emails/<type>.md` — one spec per transactional email type (welcome, magic-link, receipt, password-reset, invite, digest, etc.), following an email-adapted version of the `web-screen-specification` skill (subject + preheader instead of route context; HTML + plain-text versions; image-blocked fallback noted).
2. **Cross-channel notification matrix** in `knowledge-base/design-specs/notifications.md` — table of event types × channels (email / push / in-app), with severity, default state (opt-in / opt-out), quiet-hours treatment, digest behavior.
3. **Voice rules per channel** referenced from `knowledge-base/brand-voice-guide.md` (Content owns; UI/UX provides structural framing).
4. **Email-template assets** committed to the repo (HTML files or react-email components).
5. **Test plan** for cross-client rendering — list of clients to verify (Apple Mail iOS + macOS, Gmail mobile + web, Outlook 2019 + 365, etc.) and what to test in each (light, dark, image-blocked, plain-text fallback).

## Principles

1. **Email is a product surface.** Treat it with the same design care as in-app screens. A broken receipt is a broken product moment.

2. **Email rendering is constrained — design for the constraints.** Inline styles, table-based layout, no flexbox / grid, image-blocked fallback, dark-mode variability. The constraints are real; pretending otherwise produces broken emails.

3. **Single column, 600px max, mobile-first, 16px body.** The convergent constraints across all major clients. Multi-column emails break unpredictably.

4. **One primary CTA per transactional email.** Multiple CTAs in transactional are spammy and possibly illegal. Marketing pitches go in marketing emails, separately opted into.

5. **Subject + preheader is 80% of the design.** The user decides to open based on these alone. Specific, calm, value-forward. No false urgency.

6. **Plain-text version is required.** Spam scoring, accessibility, and the rare HTML-disabled audience all need it. Shape it like a real email.

7. **Image-blocked fallback works.** Every image has meaningful alt text; critical content is text; logos have text equivalents. The email conveys the message without any image rendering.

8. **Cross-channel coordination prevents fatigue.** One event = one notification per channel, not one per channel simultaneously. User-controlled per type. Quiet hours respected. Digests for batched events.

9. **Voice is consistent across channels.** Email warmer, push terser, in-app between. Brand voice (Content's job) shows through every surface; structural framing (UI/UX's job) keeps the channels coordinated.

10. **Sender reputation is hard-won and easy to lose.** Recognizable sender name, real reply-to, one-click unsubscribe, frequency that respects engagement. Spam complaints damage deliverability for everyone — the design choices here have systemic consequences.
