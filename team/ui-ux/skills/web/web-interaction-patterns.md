# Web Interaction Patterns

## Purpose
Define the overlay and engagement patterns the product uses — modals, sheets, popovers, dropdowns, tooltips, toasts, banners, confirmations, undo, disclosure, optimistic UI, drag-and-drop. The point of this skill is to *narrow the menu*: a coherent product uses a small, consistent set of patterns. The same scrappy choice repeated everywhere reads as deliberate; varied "best of" picks read as chaos. Forms have their own dedicated skill (see below). See the `web-form-patterns` skill for forms, validation, multi-step flow, autosave, file upload, date / time / range pickers, and toggle vs. switch vs. checkbox. See the `web-information-architecture` skill for navigation as a coordinated system (top nav + sidebar + breadcrumbs + tabs + command palette + URL structure). See the `web-empty-error-and-edge-states` skill for loading, empty, error, and brand-moment states (404, 500, maintenance, offline). See the `web-design-system` skill for the components these patterns are built on (Radix-based primitives owned in repo) and the motion tokens they consume. See the `web-screen-specification` skill for how interactions are documented in the spec. See UI/UX's `web-accessibility` skill for the source-of-truth on touch targets (44×44 floor), reduced-motion alternatives, and hover-only-interactivity rules — this skill cites those rules rather than restating them. See the `web-modern-react` skill for the React-side mechanics (`useTransition`, `useOptimistic`, `useActionState`). See Developer's `web-accessibility` skill for the implementation-side accessibility rules (keyboard, ARIA, focus mechanics). Target: **product UI on modern web (React 19+, Radix primitives, Tailwind v4, container queries available)**.

## The Anchor Rule

**Use the simplest interaction that gets the job done — and use the *same* simple interaction every time the job comes up.** The cost of a fragmented interaction system isn't aesthetic; it's cognitive. A user who learns "this product uses bottom sheets for secondary tasks on mobile" gets that knowledge for free on every screen. A user who encounters bottom sheets on one screen, centered modals on another, and slide-overs on a third learns nothing — every screen is novel.

This skill picks defaults. If a screen needs to break a default, that's a real conversation, not a quiet inline override.

## Forms

Forms have their own dedicated skill: the `web-form-patterns` skill. It covers layout (label-above, one-per-row), validation strategy (on blur + on submit), submission (pending state, one primary submit), multi-step flow (one route per step), autosave, conditional fields, file upload, date / time / range pickers, toggle vs. switch vs. checkbox, password fields, and autocomplete attributes. Read that skill when designing or specifying any form.

## Modals, Sheets, Popovers — Picking the Right Surface

These are different patterns, not the same pattern at different sizes. The defaults below cover 95% of cases.

| Surface | When to use | Default treatment |
|---------|------------|-------------------|
| **Dialog (centered modal)** | Critical confirmations ("Delete this account?"), short forms (≤ 3 fields), full-context tasks that must be completed before returning. Desktop only. | Radix `Dialog`. Backdrop dims background. Focus trapped. Escape and backdrop-click both close (unless task is destructive — see Confirmation section). |
| **Bottom Sheet** | The mobile equivalent of a Dialog. Same use cases on phones. | Radix `Dialog` with custom positioning, or a wrapper component. Slides up from bottom, takes most of the viewport. |
| **Slide-over (side sheet)** | Inspecting a single record without losing list context (preview pane, quick edit). | Slides in from the right. Backdrop is light or absent. Focus trapped. Common on desktop list views. |
| **Popover** | Contextual UI tied to a trigger element — date picker, color picker, action menu, share controls. | Radix `Popover`. Anchored to the trigger; closes on outside-click or Escape. Not for confirmations (no backdrop, easy to dismiss). |
| **Tooltip** | One-line explanation of an icon-only control or an ambiguous label. *Never* contains interactive elements. | Radix `Tooltip`. Appears on hover *and* keyboard focus. Touch users don't get tooltips — design icons that don't require explanation. |
| **Toast / snackbar** | Transient feedback after an action ("Saved," "Sent," "Deleted — Undo"). Self-dismisses. | Radix `Toast`. Bottom-right on desktop, bottom-center on mobile. Lives 4–6s for informational, 8–10s for action-required. |
| **Banner** | Persistent system-level message (account suspended, payment failed, scheduled maintenance). Doesn't auto-dismiss. | Top of the affected scope (page or app). One at a time. Dismissible only if action is optional. |

### Modal vs. Page

**Default to a page.** A modal interrupts; a page is the user's locus. Reach for a modal only when:
- The task is short (under 30 seconds) and full-context.
- The user shouldn't lose their current screen state (e.g., a quick edit on a list item).
- The action is critical and confirmation is required.

A modal that contains five sections, six fields, and three subroutes is a page in a costume. Convert it.

### Mobile Modal Treatment
On mobile (< `md` breakpoint), centered dialogs become bottom sheets. This is not a "shrink the dialog" change — it's a different shape. Bottom sheets:
- Anchor to the bottom edge (familiar from iOS, Android, and modern web).
- Take most of the viewport height (or use detents for partial sheets).
- Have a drag handle at the top, draggable to dismiss.
- Spring into place using `--spring-snappy` (or `--spring-gentle` for non-urgent open) from the design-system motion tokens — physical-feeling slide, not a cubic-bezier slide. Under `prefers-reduced-motion: reduce`, the spring is replaced with instant appearance.

Specify both shapes in the screen spec; don't leave it to the implementation.

### Modal Anti-Patterns
- Modals that open modals. The user loses orientation; back-button handling becomes ambiguous. Restructure to a sequence of pages or an inline expansion.
- Modals with their own scroll container *and* page scroll behind. Trap scroll inside the modal — the page should not scroll while the modal is open.
- Tooltip-style content in a popover. If the user can interact with it, it's a popover; if it's just text, it's a tooltip. Mixing them produces awkward components.

### Modal Background Inertness
Use the `inert` attribute on the page background while a modal is open — it removes everything outside the modal from focus order, click handling, and assistive-tech navigation in one declaration. This is the modern correct pattern; it replaces the older juggling of `aria-hidden` on the background plus `tabindex="-1"` on every focusable descendant. Radix `Dialog` handles this internally; if you compose a custom overlay, declare `inert` on the background scope.

### Modal vs. Route — URL State

Modals showing a *specific resource* (record detail, settings panel, share sheet for a specific item) should be URL-stateful via App Router's intercepting routes (`@modal` slot). The user can bookmark, share, refresh, and use back-button to close. Ephemeral modals (confirmation dialogs, command palette, transient popovers) stay URL-less. Spec each modal as one or the other. See the `web-information-architecture` skill → Modal State and Intercepting Routes.

## Dropdowns: Select, Combobox, Menu

Three distinct components. The Stack Overflow median answer treats them as one ("just use a `<select>` for everything"); the Apple-quality answer picks the right one.

| Component | Behavior | Use when |
|-----------|---------|----------|
| **`<Select>`** (Radix Select) | Picker for one of N predefined values. No search by default. | < ~12 options. State, country (use a combobox for country actually), tier, status. |
| **`<Combobox>`** (Radix or `react-aria` Combobox) | Picker with text search and optional async loading. | > ~12 options, or when the value space is large or unbounded (city, customer name, tag). |
| **`<DropdownMenu>`** (Radix DropdownMenu) | Action menu — each item triggers a different action, not a value selection. | "More actions" overflow, user account menu, contextual right-click-style menus. |

Differences matter for accessibility, keyboard behavior, and screen reader announcement. A `<DropdownMenu>` styled to look like a `<Select>` confuses everyone.

### Native `<select>` Edge Case
Native `<select>` is correct on mobile in many cases — it opens the OS-native picker, which is faster and more familiar than any custom UI. For pure single-value pickers with a small number of options, the native control is often the right answer. Don't reach for Radix `Select` reflexively if `<select>` would work. Reserve the custom component for cases where styling, search, or grouping is genuinely needed.

## Tooltips

Tooltips are almost always a hint that something else is wrong. Before adding a tooltip, ask:
1. Can the icon be paired with a text label instead? Usually yes — and now there's no tooltip needed.
2. Is the explanation a single short phrase? If it's more than one short sentence, it's not a tooltip — it's a popover or a help link.
3. Does the user need to read it on every interaction, or once? If once, an onboarding tip or in-context help is better.

When tooltips are correct: identifying icon-only controls (e.g., a toolbar of icons), surfacing keyboard shortcuts, providing brief metadata (full timestamp on hover of a relative time).

When tooltips are wrong: explaining error states (use inline error messages), confirming an action (use a dialog), giving instructions (use placeholder text or helper text), or anywhere a touch user can't see them and would miss the information.

## Toasts, Banners, Inline Messages

Pick by *persistence* and *severity*.

| Pattern | Persistence | Severity | Use |
|---------|------------|---------|-----|
| **Inline message** | Persistent until state changes | Low–medium | Form field errors, empty-state explanations |
| **Toast** | Transient (4–10s, dismissible) | Low–medium | Action confirmation ("Saved"), undo affordance ("Deleted — Undo") |
| **Banner** | Persistent until dismissed or state changes | Medium–high | Account-level notices ("Your trial ends in 3 days"), system messages |
| **Dialog** | Persistent until acknowledged | High | Critical errors that block the task, destructive confirmations |

Don't escalate. A toast for a system-down event is too quiet; a dialog for "Saved" is too loud. The right severity prevents alarm fatigue and missed signals.

### One Toast Region, One Banner Slot
A page has at most one toast region and at most one banner slot. Multiple banners stacked at the top create the banner-overload anti-pattern. Multiple toasts queue; they don't stack.

## Navigation Patterns

Navigation as a *system* — how top nav, sidebar, breadcrumbs, tabs, command palette, and search compose into a coordinated whole — lives in the `web-information-architecture` skill. Read that skill for the IA-level decisions (which surfaces the product uses, what each is for, how URL state is encoded, when to add a command palette).

This section covers the per-component widget patterns. Pick the right widget; coordinate via the IA skill.

### Tabs (within a screen)
For switching between views of the *same* content (e.g., "Overview / Activity / Settings" within a record detail screen). Not for navigating to different things.

- Use `<Tabs>` (Radix) for accessibility and keyboard support.
- 2–5 tabs. More than 5 and the layout breaks; consider a different organization (drill-in, separate routes).
- Tabs that map to URL state (`?tab=activity`) get linkability and back-button support for free. Reach for this whenever the tabs represent meaningful destinations.

### Top Nav, Sidebar, Bottom Nav, Breadcrumbs
Per-widget specifications (entry counts, breakpoints, sticky behavior, mobile collapse) live in the `web-information-architecture` skill. The summary: top nav 4–6 entries, sidebar 2 levels max, bottom nav mutually exclusive with top-nav-as-primary on mobile, breadcrumbs only for deep hierarchies. Don't restate per screen; cite the IA skill.

## Confirmations and Undo

The default for destructive actions has shifted. The modern pattern: **prefer Undo over Confirm** wherever the destruction is recoverable.

| Action type | Pattern |
|------------|---------|
| Recoverable (delete a draft, archive an item, remove from list) | Action proceeds immediately. Toast appears with "Undo" button for 8–10s. State is restorable. |
| Irrecoverable (permanently delete account, charge a card, send a message) | Confirmation dialog. Type-to-confirm for the most severe (`Type "DELETE" to confirm`). |
| Frequent or batch (mark 50 items as read) | No confirmation, no undo. Friction here is harmful. |

Confirmation dialogs are expensive — they break flow, train users to click-through reflexively, and produce alarm fatigue. Use them where the cost of being wrong is genuinely high.

When using a confirmation dialog:
- The destructive action is the secondary button (typically `intent="danger"`); the safe option (cancel) is the primary or default-focused option.
- The dialog text says specifically what will be lost ("Delete the project 'Q1 Planning' and all 24 of its tasks?").
- Do *not* close on backdrop click or Escape for destructive dialogs. Require an explicit choice.

## Disclosure and Expansion

For revealing secondary content on demand.

| Pattern | When |
|---------|------|
| **Disclosure (`<details>` / Radix Disclosure)** | A single piece of content shows/hides. FAQ entries, "Advanced settings," "What is this?" |
| **Accordion** | A list of mutually exclusive disclosures (only one open at a time). Long FAQs, settings groups. |
| **Tabs** | Mutually exclusive views — but the user expects to switch frequently. |

Use the lightest pattern that fits. Don't reach for an accordion if a single disclosure works.

### "Read More" / Truncation
For long body text, truncating with a "Read more" link is appropriate when the truncated state contains the gist (first 2–4 lines). Don't truncate so aggressively that the user can't decide whether to expand.

## Optimistic UI

Use `useOptimistic` (React 19+) for actions where:
- The success outcome is predictable.
- The user expects immediate feedback.
- Reversal on failure is acceptable (a brief revert with an error toast).

Examples: liking a post, adding to a list, toggling a setting, sending a chat message, drag-and-drop reordering.

Do *not* use optimistic UI for:
- Actions whose result depends on server-computed values (timestamps, IDs) the UI can't predict.
- Destructive actions where a wrong assumption is jarring (e.g., "deleted" optimistically but it failed — the user thinks it's gone and acts accordingly).
- Payment, irreversible state changes, anything the user must see confirmed before continuing.

For sober actions, show a pending state and wait for the server. The friction is correct.

## Drag and Drop

Use sparingly. When the use case is genuine (reordering a list, dragging a file, moving a kanban card):

- Use `@dnd-kit` or `react-aria` Drag and Drop. Both expose accessible keyboard alternatives — drag-and-drop *must* have a keyboard equivalent (typically arrow keys with a "grab" key like Space).
- Visual feedback at every stage: drag handle visible, hover state on draggable items, drop-target highlight, ghost element under the cursor.
- Confirm drop with a brief animation (snap into place over `--duration-short`); revert with a smooth animation if the drop failed validation.
- Specify the keyboard alternative in the spec — it's not implementation trivia, it's a design decision.

## Loading, Empty, and Error States

These have their own dedicated skill: the `web-empty-error-and-edge-states` skill. It covers the empty-state taxonomy (never-had-content / you-emptied-it / no-search-results / filter-emptied-it / permission-denied), error categories (validation / recoverable / irrecoverable / maintenance / offline), brand-moment 404 / 500 / 403 / maintenance pages, recovery patterns (autosave + restore, optimistic rollback), retry semantics, error-message voice, and skeleton-vs-spinner-vs-nothing decision rules. Read that skill for any state that isn't the happy path.

## Animation and Motion

The motion vocabulary is small. From `tokens.css`:
- `--duration-instant: 100ms` — micro-feedback (button press, tab switch).
- `--duration-short: 200ms` — most UI transitions (modal open, fade in, hover).
- `--duration-medium: 300ms` — emphasized transitions (page-level, important state changes).
- `--ease-standard: cubic-bezier(0.2, 0, 0, 1)` — default for nearly everything.
- `--ease-emphasized: cubic-bezier(0.3, 0, 0, 1)` — for transitions that should feel deliberate.

Reach for these tokens in every component. Magic numbers (`transition-all duration-150`) are defects; the system should look coherent because every component pulls from the same vocabulary.

### Reduced Motion
Every animated component must respect `prefers-reduced-motion: reduce`. The full per-pattern alternative table (decoration motion, functional motion, vestibular safety) lives in UI/UX's `web-accessibility` skill → Motion and Animation. Cite that table in screen specs; don't restate. Summary: decoration disabled, functional motion instant or near-instant, parallax/autoplay/marquee disabled entirely.

### View Transitions API
For route-level transitions (cross-page animations), the View Transitions API is the modern correct mechanism. Use sparingly — most route changes don't need a custom transition; the default (instant) is appropriate. Reserve transitions for moments where *continuity matters* (a list-item expanding into a detail view, a hero image persisting between pages).

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **Modal stacks** (a modal opens another modal). | Users lose orientation; back-button behavior is undefined; focus trap nesting is fragile. | Restructure to a sequence of pages or to inline expansion. |
| **Auto-focusing search or first input on page load.** Page mounts; focus jumps into an input. | Steals keyboard focus from users who landed via a link; scrolls page on mobile; breaks back-button restoration of scroll position. | Don't auto-focus on page load. Reserve auto-focus for clearly modal contexts (a search dialog the user just opened, a form they navigated to specifically). |
| **Scroll-driven entrance animations on every section ("AOS-style").** Sections fade-and-translate in as they enter the viewport. | Slows perceived performance, fights `prefers-reduced-motion` even when the handler exists, masks layout shifts as "design," screams template. Apple doesn't do it. | Default to no entrance animation. Reserve subtle reveals for genuinely curated marketing sections, with reduced-motion alternatives. Never on product UI. |
| **Tooltip with interactive content.** Buttons or links inside a tooltip. | Users can't reach them on touch; pointer users have to "race the tooltip" to interact before it dismisses. | Use a popover for interactive content, a tooltip for text only. |
| **Confirmation dialog for every delete.** A click-to-confirm dance for trivially recoverable actions. | Trains users to dismiss confirmations reflexively, missing the genuinely critical ones. | Default to undo (toast with "Undo" for 8–10s). Reserve confirmations for irrecoverable actions. |
| **Hover-to-discover patterns on touch devices.** See UI/UX's `web-accessibility` skill → Anti-Patterns → Hover-only interactivity for the canonical statement. | Touch users have no hover. They never discover the controls. | Show controls persistently on touch (`@media (pointer: coarse)`); hide on hover only on `(hover: hover)` devices. |
| **Custom select reproducing a native dropdown for no reason.** Radix `Select` for a 5-option country/state picker on mobile. | Native `<select>` opens the OS picker, which is faster and more familiar. Custom UI fights muscle memory. | Native `<select>` for simple single-value pickers. Reserve custom for search, grouping, or async loading. |
| **Toast for every action.** "Saved!" toast on every keystroke of an autosave. | Toast fatigue. Users tune them out. The genuinely important toast is missed. | Inline status indicator for autosave ("Saved" caption, briefly). Toast for actions that took user effort and may have unexpected outcome. |
| **Carousels and auto-rotating banners.** Auto-advancing hero rotators, cycling promo banners. | Click-through rates drop sharply after slide 1; users mentally tune them out; accessibility is a constant struggle. | Pick the one message. If you can't, that's a strategy problem upstream. |
| **Animation that ignores reduced-motion.** Mount fades, shimmers, parallax all play regardless of user preference. | Motion-sensitive users experience real harm. | Every animation has a reduced-motion alternative documented in the spec. Default to "no animation" rather than "no preference handler." |
| **Drag-and-drop without a keyboard alternative.** Reordering only works with a mouse. | Keyboard users are locked out of the feature. | Specify the keyboard interaction in the spec (Space to grab, arrows to move, Space to drop, Escape to cancel). |
| **Magic-number durations.** `transition-all duration-150` scattered across components. | The product feels inconsistent because no two animations share timing. | Reference motion tokens (`--duration-short`, `--ease-standard`). Adding a new duration is a token decision. |

## Principles

1. **Pick the simplest pattern that works.** A page beats a modal. A native select beats a custom one. A disclosure beats an accordion. Reach for complexity only when the simple pattern genuinely doesn't fit.

2. **Use the same pattern every time.** Consistency is a feature. A product where every screen reaches for "the best" pattern reads as inconsistent; a product that uses the same five patterns everywhere reads as deliberate.

3. **Mobile and desktop interactions are different shapes, not different sizes.** Bottom sheets on mobile, centered dialogs on desktop. Different gestures, different defaults. Specify both — don't shrink one into the other.

4. **Static state must signal interactivity.** Hover and focus refine; they never reveal interactivity that wasn't already visible. Touch users don't get hover; design the static state to work for them.

5. **Prefer undo over confirm.** Friction belongs at irrecoverable actions, not at every recoverable one. Undo is the modern correct pattern and the right default; confirmation dialogs are reserved for genuinely high-stakes calls.

6. **Tooltips are evidence of an unsolved design problem.** Before adding one, check whether the icon should be paired with a text label, the explanation belongs in helper text, or the surface needs an in-context onboarding hint. Tooltips are correct only as the last resort for icon-only controls and brief metadata; touch users never see them, so they must never be load-bearing.

7. **Motion respects preference.** Every animation has a reduced-motion alternative. The default for users with `prefers-reduced-motion: reduce` is "no decoration motion, instant or near-instant functional motion." This is a design call, not an implementation footnote.

8. **One toast region, one banner slot, one primary CTA.** Multiple competing transient or persistent UI elements compound into noise. Constrain the surfaces and the product reads as confident.
