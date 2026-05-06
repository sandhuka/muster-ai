# Web Form Patterns

## Purpose
Define how forms are designed on the web — layout, label position, validation strategy, submission, multi-step flow, autosave, conditional fields, file upload, date / time / range pickers, and the toggle / switch / checkbox decision that the Stack Overflow median routinely gets wrong. Forms are where the product asks the user to give it something; the friction the form imposes is the friction the user pays for the product. Apple-quality forms are rare on the web because most products treat forms as a UI dumping ground rather than a craft. See `team/ui-ux/skills/web-design-system.md` for the tokens forms consume (control padding, radius, focus ring, type scale). See `team/ui-ux/skills/web-interaction-patterns.md` for adjacent patterns (dropdowns, modals, popovers used by form controls). See `team/ui-ux/skills/web-accessibility.md` for the design-side a11y rules forms must enforce (label semantics, error association, autocomplete intent, contrast). See `team/ui-ux/skills/web-empty-error-and-edge-states.md` for validation-error voice and recovery patterns. See `team/ui-ux/skills/web-onboarding-flows.md` for the sign-up form rules (1–2 fields max, progressive profiling) — those override generic form rules during onboarding. See `team/developer/skills/web-modern-react.md` for the React 19+ mechanics (`useActionState`, `useFormStatus`, Server Actions); see `team/developer/skills/web-accessibility.md` for the implementation-side a11y mechanics (`useId`, `aria-invalid`, `aria-describedby`, `autoComplete`). Target: **product UI on web — any screen that collects input from the user (sign-up, settings, billing, content creation, search, multi-step flows)**.

## The Anchor: One Field Per Decision

Every field is a question the product asks the user. Every question has a cost (attention, typing, looking up information). The form's job is to ask only what's needed, in the order the user can answer, with the least friction per field.

Two implications:

1. **Cut fields ruthlessly.** Every field that isn't load-bearing for the next product step is friction the user pays for nothing. Ask later, ask conditionally, or don't ask. Marketing wants this data; the user doesn't owe it.
2. **The form's structure is a hierarchy decision.** Field order, grouping, conditional reveals — all are hierarchy choices. See `team/ui-ux/skills/web-content-hierarchy.md` for the parent discipline; this skill applies it inside forms.

## Layout

### One Field Per Row (Default)

Default to single-column. Multi-column only when fields are *intrinsically grouped* and the grouping aids comprehension:

| Multi-column appropriate | Multi-column inappropriate |
|--------------------------|---------------------------|
| First name + Last name | Email + Password (different concepts; stack) |
| City + State + Zip | Two unrelated short fields side-by-side to "save space" |
| Card number + Expiry + CVC | Different settings put on the same row because they fit |
| Start date + End date | Form fields placed in columns to mimic a desktop spreadsheet layout |

The test: would a user filling out the form linearly expect to land on these fields together? If yes, multi-column. If no, stack.

Multi-column drops to single-column at small viewports — use container queries (`@container`) so the form adapts to its container, not the viewport. See `team/ui-ux/skills/web-responsive-patterns.md`.

### Labels Above Fields, Always

Labels go above the field, never as placeholder-only and never to the side (right or left). Placeholder-as-label fails on three axes:

- **Accessibility**: the label disappears when the user types; screen readers may not announce it; users can't review what they entered.
- **Autofill**: browsers and password managers identify fields by `<label>`; inline-only labels lose autofill.
- **Cognitive load**: the user fills the field, then forgets what it was for; reviewing is harder; errors are ambiguous.

Side labels (left of field) save vertical space at the cost of scanning rhythm — the eye has to bounce horizontally to read the form. Stack vertically. The vertical-rhythm cost is small; the readability gain is large.

```
✅ Label above:
   Email
   ┌─────────────────────┐
   │ user@example.com    │
   └─────────────────────┘

❌ Placeholder-as-label:
   ┌─────────────────────┐
   │ Email               │
   └─────────────────────┘

❌ Label to the side:
   Email   ┌─────────────────────┐
           │                     │
           └─────────────────────┘
```

### Required, Optional, Helper, Error

- **Required indicator**: small `*` next to the label. *Only if the form has a mix of required and optional fields* — if everything is required, `*` everywhere is noise. Don't use the word "(required)" — `*` is the convention and is screen-reader-aware via the label semantics.
- **Optional indicator**: never. Optional is the *absence* of `*`. Adding "(optional)" creates noise; remove the optional fields instead if you can.
- **Helper text** below the field, in `text-caption text-text-muted`. For non-error guidance: "We'll never share this." or "8+ characters, including a number." Visible at all times, not on hover.
- **Error text** below the field, in `text-caption text-danger`. Linked via `aria-describedby` (developer's job). Visible *and* announced to assistive tech.

The order under the field: helper text first (always visible), error text second (replaces helper or appears below it depending on layout — pick one and ship consistently across the product).

### Field Grouping

For sets of related fields (address, payment, preferences), use `<fieldset>` with a `<legend>`. The legend is the group's heading. Style the legend consistently with section headings (`text-h3` or `text-body` semibold, depending on the form's overall hierarchy).

Fieldsets prevent ambiguity in screen-reader narration ("Billing address — Street: …") and signal the group visually.

## Validation

The default for inline validation: **on blur.** Not on every keystroke, not only on submit.

| Strategy | When |
|----------|------|
| **On blur** (after the user leaves the field) | Default. The user has finished thinking about that field. Validate then. |
| **On submit** (server-side, returned via Server Action result) | Always, regardless of inline validation. The server is the source of truth. |
| **As the user types** | Rare exception. Only for *live constraints the user can see resolve in real time*: password strength meter, character counter approaching budget, "this username is available." Not for "invalid email format" — that punishes typing in progress. |

### Error Message Discipline

Apple-quality error messages are specific and actionable. See `team/ui-ux/skills/web-empty-error-and-edge-states.md` → Error Message Voice for the full discipline. Form-specific summary:

- **Specific**: name what's wrong. "Email must include an @." not "Invalid email."
- **Actionable**: tell the user what to do. "Use 8 or more characters" not "Password too weak."
- **Blameless**: "This field is required" or "Add an email address" — not "You forgot the email."
- **Brief**: one sentence. Two only when the constraint is genuinely complex.
- **Inline**: appear next to the failing field, not as a toast or summary at the top (those are *additional* aids for long forms, not replacements).

### Submit-Time Errors

When submission fails server-side, the response should populate field-level errors via the form-action result. Don't show a generic toast for a field-level error — populate the field. Reserve toasts for genuinely action-level errors ("We couldn't save — try again.").

For long forms with errors at submit, scroll-to-first-error and focus it. The user must know where the problem is.

## Submission

### Pending State

Submit buttons have a visible pending state. The label changes ("Sign up" → "Signing up…") and the button is disabled. Use `useActionState` (React 19+) or `useTransition` for the pending flag. The button's width should be stable across states (no layout shift between "Sign up" and "Signing up…") — use a fixed width or padded label.

Don't show a separate global spinner overlay for form submission unless the action takes more than ~3 seconds (rare for product forms — server actions should be fast).

### One Primary Submit

A form has *one* primary action: "Save," "Sign up," "Continue," "Send." It's the only primary-styled button.

Cancel, secondary actions, "Save as draft," "Reset" — all are visually subordinate (ghost button or text link). They should not visually compete with the primary submit.

The primary submit is at the bottom of the form (or at the bottom-right on multi-column desktop layouts) — *never* at the top, where it appears before the user has filled the form.

### After Submission

Successful submission lands the user *somewhere*. Three patterns:

| Pattern | When |
|---------|------|
| **Redirect** to the resulting state (a new record, a confirmation page) | Most common. The form completed; the user is done with it. |
| **Inline confirmation** (the form area shows a success state) | When the form is part of a settings page and the user might immediately edit again. |
| **Toast + form reset** (form clears, toast confirms) | For repeat-submission forms (add a tag, send a quick message). |

What you must *never* do: leave the user staring at a form that simply emptied itself with no acknowledgment. They won't know if it worked.

## Multi-Step Forms

For forms that collect substantial information (sign-up flow, checkout, multi-step setup), use **routes as the step boundary** — one step per route (`/signup/account`, `/signup/profile`, `/signup/payment`).

Routes give back-button support, deep-linking to a specific step (for resume / share / debugging), analytics events for step-by-step conversion, and clean state isolation. Pagination *within* a single page (state-machine UI without route changes) loses all of these.

### Step Discipline

- **One concept per step.** Don't fit "name + email + password + plan + payment" into one step labeled "Sign up." Split. (Or, if it really is one step's worth, ask less.)
- **Progress indicator**: subtle, not dominant. Dots, a thin bar, or "Step 2 of 4." Don't let progress chrome compete with the step's primary content.
- **Back is supported** via the browser back button. In-product back link is helpful for visibility but must match browser back.
- **Persist state across steps** server-side or in a session cookie. A user who refreshes mid-flow shouldn't lose what they've filled in.
- **Final step's "Submit" creates the resource.** Earlier steps just collect; nothing is created until the final commit.

See `team/ui-ux/skills/web-onboarding-flows.md` for sign-up-specific multi-step rules (which override these generic form rules during onboarding).

## Autosave

For settings, drafts, and long-form content where the user is incrementally editing, autosave beats a "Save" button.

- **Debounce on input** (300–800ms) and save on blur. Save also on visibility change (tab background) and on `beforeunload` if changes are dirty.
- **Indicator**: caption-sized inline text — "Saving…" → "Saved" with a brief transition. Not a toast; not a modal. The user should see save state without it interrupting.
- **No sticky "Save" button** if the form autosaves. The button is misleading.
- **On failure**: persistent indicator that save failed, with retry. Don't drop the user's edits silently.
- **Conflict handling**: if another session updated the same data, show a clear warning and let the user decide which version wins. Don't silently overwrite.

For autosave + recovery, see `team/ui-ux/skills/web-empty-error-and-edge-states.md` → Recovery Patterns → Autosave + Restore.

## Conditional Fields

Fields that depend on prior answers should *appear when relevant*, not be persistently visible-and-disabled.

- **Hide entirely** when the precondition isn't met. Reveal when it is.
- **Don't disable.** Disabled fields tell the user "this exists but you can't use it" — confusing. If the field is conditionally relevant, hide it.
- **Reveal smoothly**: 200ms fade or height transition; respect `prefers-reduced-motion: reduce` (instant).
- **Maintain logical reading order** in the DOM as fields appear, so screen readers announce the new field at the right moment.

## File Upload

A common, often-poorly-designed pattern. The shape:

### Affordance

A combined drop-zone + click-to-browse + paste-to-upload component. All three trigger paths; the user picks based on context.

```
┌─────────────────────────────────────────────────┐
│                                                 │
│   ⬆  Drag a file here, or click to choose       │
│                                                 │
│   PDF, PNG, JPG up to 10MB                      │
│                                                 │
└─────────────────────────────────────────────────┘
```

- **Drop zone**: the entire affordance accepts drops. On drag-over, the border/background shifts (`border-strong`, subtle `surface-muted`) to confirm drop will land.
- **Click-to-browse**: the affordance is itself a button (`role="button"`); a hidden `<input type="file">` opens the OS picker.
- **Paste**: support `paste` events for image upload (common for screenshot workflows). Not all upload contexts need this — opt in.
- **Always show the constraints**: file types, max size. Don't make the user discover them by failing.

### During Upload

- **Progress per file**: filename, progress bar, percent or size, cancel button. Multiple files = a list of these.
- **Don't block the form**: the user can continue editing while uploads progress. Disable the submit button while any upload is in flight.
- **Per-file failures don't fail the batch**: if one of three uploads fails, the other two succeed; show the failure inline next to that file with a retry.

### After Upload

- **Image preview** (thumbnail) inline for image uploads.
- **Filename + remove** for non-image uploads.
- **Replace, don't append**: if the field is single-file and the user uploads a second, replace; don't keep both. If multiple, append clearly.

### Implementation Note

Files should upload **directly to object storage via signed URLs**, not through the form action. The form submits with the resulting object key. See `team/developer/skills/web-security.md` → file-upload hardening. The design implication: the upload progresses *before* form submission, which is why per-file progress and the "uploads in flight" submit-disable matter.

## Date, Time, and Range Pickers

The most over-engineered category in web forms. Discipline:

### Single Date

| Pattern | When |
|---------|------|
| **Native `<input type="date">`** | Single date, no constraints beyond min/max. Mobile gets the OS-native picker (excellent); desktop gets a built-in calendar. |
| **Custom date picker** (popover + calendar grid) | Custom-styled UI, branded date display, complex constraints (disabled dates, multiple-selection). |
| **Text input with format hint** | Power-user contexts where typing the date is faster than clicking. Accept multiple formats; show a placeholder ("YYYY-MM-DD"). |

Default: native. Reach for custom only when the design genuinely needs branded calendar UI or constraints that native doesn't support.

### Time

| Pattern | When |
|---------|------|
| **Native `<input type="time">`** | Single time, default. |
| **Custom time picker** (dropdown of half-hour slots) | When you want to constrain to specific intervals (booking windows). |
| **Combined date+time as separate inputs** | Default for events / appointments. Don't try to fit both in one custom widget. |

### Date Range

Native doesn't have a date-range picker, so this is the one place where custom is the default.

- **Two date inputs side-by-side** ("From" + "To") with implicit constraint (To ≥ From). Often sufficient and accessible.
- **Single popover with two-month calendar view** for date-range UIs that need visual range selection (booking calendars, analytics date pickers). Higher engineering cost; ship when range visualization is genuinely useful.
- **Quick-select chips** ("Today," "Last 7 days," "Last 30 days," "Custom") for analytics — most users pick a preset; the custom range is the long tail.

**Range + time-zone gotcha**: `<input type="date">` produces a *wall-clock* date string (`"2026-05-15"`) — not an instant. For ranges that span time zones (an event "from May 15 PT to May 16 ET"), wall-clock dates collapse the distinction and produce silently-wrong queries. If the range represents instants in time, pair the dates with explicit zones (or a single resource-zone) per the Time Zone subsection below; if it represents wall-clock dates (a vacation, a fiscal period), the native dates are correct but the spec must say so explicitly.

### Time Zone

When the date represents an instant in time (event start, deadline), the form must address time zone:

- **Display in the user's local time zone** by default; show the time zone abbreviation explicitly: `2026-04-30 14:00 PDT`.
- **Store as UTC** server-side (Developer's call).
- **For events that are inherently in a specific zone** (a conference in Tokyo), let the user pick the zone. Default to the resource's zone.

Time-zone bugs are a constant source of subtle product failures; specify the time-zone behavior in the screen spec, not as an afterthought.

## Toggle vs. Switch vs. Checkbox

Easily-confused trio with strong semantic differences. The Stack Overflow median treats them as interchangeable; the Apple-quality answer picks deliberately.

| Control | Semantic | Effect |
|---------|---------|--------|
| **Switch** (iOS-style sliding control) | "This setting is on or off." | **Immediate effect** — the change applies the moment you toggle it. |
| **Checkbox** | "This option is selected as part of a form." | **Form-state effect** — the change applies when the form is submitted. |
| **Toggle button** (button-style on/off) | "I am in mode X." | Either, depending on context — usually immediate (filter toggle, view mode switch). |

Decision rules:

- **Settings rows that take effect immediately** (notifications on/off, dark mode, auto-save) → **Switch**. The user expects the setting to apply right away.
- **Form fields the user will submit** (T&C agreement, "Subscribe to newsletter") → **Checkbox**. The user expects nothing to happen until they hit Submit.
- **Multi-select within a form** (pick categories, pick days of the week) → **Checkbox** group.
- **Tabs / view modes / filter toggles** in a toolbar → **Toggle button**. The change affects the view immediately.

The most common mistake: using a switch for a form field. The user toggles the switch expecting an immediate effect; nothing visible happens; they assume it didn't work; they toggle again. Reserve switches for immediate-effect settings.

## Password Fields

If the product uses passwords (last-resort auth — see `team/ui-ux/skills/web-onboarding-flows.md`):

- **Single password field, no "confirm password."** Confirm fields don't prevent typos; they prevent users. Allow show/hide instead so the user can verify.
- **Show/hide button** (eye icon inside the field). Toggle accessible label ("Show password" / "Hide password"). Default to hidden.
- **Strength meter** (when relevant): live, as the user types, with specific guidance ("Add a number," "Use 8 or more characters") — not a generic "weak / medium / strong" bar that says nothing actionable.
- **`autocomplete="new-password"` on sign-up** and `autocomplete="current-password"` on sign-in. Browsers and password managers depend on this.
- **Don't restrict pasting.** Anti-pattern that breaks password managers.
- **Don't restrict character set.** Allow any printable Unicode. Restricting characters frustrates users using password managers.

## Autocomplete Attributes

`autocomplete` is the form's most underrated accessibility and UX feature. Every form field should declare its autocomplete intent so browsers and password managers can fill it correctly.

| Field | `autocomplete` value |
|-------|---------------------|
| Email | `email` |
| First name | `given-name` |
| Last name | `family-name` |
| Full name | `name` |
| Phone | `tel` |
| Street address | `street-address` |
| City | `address-level2` |
| State / region | `address-level1` |
| Postal code | `postal-code` |
| Country | `country` (for code) or `country-name` |
| Card number | `cc-number` |
| Card expiry | `cc-exp` |
| Card CVC | `cc-csc` |
| Cardholder name | `cc-name` |
| Sign-in password | `current-password` |
| Sign-up password | `new-password` |
| One-time code (SMS / TOTP) | `one-time-code` (iOS auto-fills from SMS) |

Specify these in the screen spec; the developer enforces in the markup.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **Placeholder-as-label.** Field with no visible label, just a placeholder that disappears on input. | Fails on accessibility, autofill, and review-after-typing. | Label above the field; placeholder for example values only. |
| **"Confirm password" field.** | Doesn't prevent typos; prevents users. Password managers handle it badly. | One password field with show/hide. |
| **Validate on every keystroke.** Inline error appears as the user is mid-typing. | Punishes users for typing in progress; flickering error state. | Validate on blur. Submit-time validation for the contract. As-user-types only for live constraints (strength meter, character counter, username availability). |
| **Disabled fields explaining "you can't fill this in right now."** A grayed-out field with no context. | The user doesn't know why; they have to investigate. | Hide irrelevant fields entirely. If the field is conditional, reveal when the precondition is met. |
| **Multi-step form within a single page.** State-machine UI without route changes. | Loses back-button, deep-link, analytics, refresh-recovery. | One step per route. URL-driven progress. |
| **Submit button at the top of the form.** | The user hits it before reading the form. | Submit at the bottom. |
| **Sticky "Save" button on autosaved forms.** | Misleading — there's nothing to save manually. | Inline "Saved" indicator instead. |
| **Autosave that fails silently.** Save fails, user keeps editing, work is lost on close. | Trust degrades; data loss. | Persistent failure indicator + retry; never silent. |
| **Custom date picker for a simple single-date field on mobile.** | Loses the OS-native picker which is faster and more familiar. | Native `<input type="date">`. |
| **Switch used for a form-state field.** "Subscribe to newsletter" as a switch. | User expects immediate effect; submit is required; user is confused. | Checkbox for form-state. Switch for immediate-effect settings. |
| **Required marker (`*`) on every field of an all-required form.** | Noise; the asterisks communicate nothing because they're universal. | Omit. Use `*` only when there are also optional fields. |
| **"(optional)" label on optional fields.** | Worse than nothing — implies the form is mostly required when it might not be; clutters labels. | Omit. Required gets `*`; optional is the absence of `*`. |
| **One toast for every form-validation error.** Multiple toasts stacking on submit. | Toast is the wrong surface for field-level errors; the user can't tell which field. | Errors inline next to the failing field. Toast only for genuinely action-level errors. |
| **No autocomplete attributes.** Browser doesn't know what each field is for. | Autofill doesn't work; password managers fail; form-fill is slow. | Specify `autocomplete` on every field per the table above. |
| **Restricting password characters or paste.** "Password may not contain spaces" or `onpaste="return false"`. | Breaks password managers; frustrates users; provides no real security. | Allow any characters; allow paste; let password managers do their job. |
| **Custom file-upload that sends bytes through the form action.** | Slow, blocks form submission, hits server limits, fragile. | Direct upload to object storage via signed URL; form submits the resulting key. |
| **No file-type or size constraints surfaced.** User uploads, then sees "File too large" after the upload. | Wasted bandwidth; frustrating. | Show constraints in the affordance; validate client-side before upload. |
| **Form fields in two columns "to save space" on a mobile-rendered form.** | Cramped, unreadable, fails touch targets. | One column on mobile. Multi-column only at `@md` and above, only when intrinsically grouped. |
| **Date range as two unrelated date pickers with no constraint.** End date can be before start date. | Confusing input; submission fails or produces nonsense. | Constrain end ≥ start in the input itself; show error inline if violated. |
| **Time fields without time-zone disclosure.** "Event at 14:00." | User in another zone misreads. Subtle product failures. | Show time-zone abbreviation explicitly; store UTC server-side. |

## Principles

1. **Cut fields ruthlessly.** Every field is a tax on the user's attention. Ask only what's load-bearing for the next product step. Defer the rest to progressive profiling, ask conditionally, or don't ask.

2. **Labels above the field, always.** Placeholder-as-label and side labels both fail. The vertical-rhythm cost of stacking is small; the readability and accessibility gain is large.

3. **Validate on blur, on submit. Never on keystroke (except live constraints).** Mid-typing validation punishes thinking. The blur-and-submit pattern matches user expectation.

4. **One primary submit, at the bottom.** Cancel and secondary actions are visually subordinate. Submit is never at the top. The form is read top-down; the action is at the end of the read.

5. **Multi-step is one route per step.** Routes give back-button, deep-link, analytics, refresh-recovery. State-machine pagination within a page loses all of them.

6. **Autosave for editing; explicit save for create.** Settings and drafts autosave with inline indicator. New-resource creation submits explicitly so the user knows when the resource exists.

7. **Switch for immediate-effect, checkbox for form-state.** The most common form-pattern mistake is using a switch where a checkbox belongs. The semantics differ; user expectation differs; pick deliberately.

8. **Native form controls when they fit.** `<input type="date">`, `<input type="time">`, `<select>` — these win on mobile (OS-native pickers) and on accessibility. Reach for custom only when the design genuinely needs what native doesn't provide.

9. **Autocomplete attributes are not optional.** Every field declares its autocomplete intent. Without them, autofill doesn't work, password managers fail, conversion drops measurably.

10. **File uploads go to object storage via signed URLs, not through the form.** The form submits the key after upload completes. Per-file progress, per-file failure handling, and per-file retry are required.

11. **Specific, blameless, actionable errors.** "Email must include an @." not "Invalid email." Inline next to the field. The voice belongs to Content; the structure (specific, blameless, brief) is UI/UX.
