# Web Empty, Error, and Edge States

## Purpose
Define the design of the states that aren't the happy path: empty states (with their distinct origins), errors (recoverable, irrecoverable, permission, maintenance, offline), 404 / 500 / 403 / maintenance pages as brand moments, recovery patterns, retry semantics, and the message voice that distinguishes a calm product from a frustrating one. This is the surface where vibes-coded LLM output is most consistently bad — generic "No data found 🤷" with stock illustrations, "Something went wrong" with no recovery path, 404s that send the user back to the homepage with no context. Apple-quality empty and error states are designed deliberately, treated as brand moments, and follow distinct shapes per origin. See `team/ui-ux/skills/web-design-system.md` for the tokens these states consume. See `team/ui-ux/skills/web-content-hierarchy.md` for the content discipline applied to these states (one CTA, one sentence, restraint). See `team/ui-ux/skills/web-interaction-patterns.md` for the toast / banner / inline-message patterns that surface transient errors. See `team/ui-ux/skills/web-data-display.md` for table-specific empty states (a major use site). See `team/ui-ux/skills/web-onboarding-flows.md` for empty states that overlap with first-run experience. See `team/developer/skills/web-observability.md` for the implementation-side error-envelope and `error.tsx` mechanics. Target: **product UI on web — every screen has these states, and the design owes them as much care as the content state**.

## The Anchor: Empty Is Not "Wrong"

The prevailing failure mode is treating empty and error states as fallbacks — afterthoughts handled with a one-size-fits-all "No data" + spinner-of-the-day. The Apple-quality stance: **empty is a state, not an error; error is a moment, not a failure.** Both are part of the product's voice. A calm 404 with a clear path forward earns more trust than a maximalist content page that breaks ungracefully.

Two implications:

1. **Different empty states for different origins.** "Never had content" and "filter emptied it" and "you don't have permission" are three different problems with three different recoveries. One empty-state component can't serve all three honestly.
2. **Errors have voice.** "Something went wrong" is generic; "We couldn't reach the billing service. Try again, or check status.example.com." is specific. The latter is the Apple-quality default.

## Empty State Taxonomy

There are at least five distinct empty shapes. Each has its own origin, its own copy, its own CTA. The screen spec must say which apply.

### 1. Never-Had-Content (first run / cold start)
- **When**: User has never created any of this thing yet.
- **Tone**: Inviting, brief, action-forward. This is part of onboarding-by-stealth.
- **Layout**: Centered single-column. One sentence framing the value. One primary CTA that creates the first item.
- **Example copy**: "No invoices yet. Create your first to get started." → CTA: "New invoice."
- **Illustration**: Optional. If used, must be designed (custom, brand-consistent, restrained). Stock illustration is worse than none. Apple's empty states are usually illustration-free with strong typography.

### 2. You-Emptied-It (you just deleted everything)
- **When**: User had content, then archived/deleted/cleared all of it. The empty is fresh and self-caused.
- **Tone**: Acknowledgment + offer to undo or to create new.
- **Layout**: Same as never-had-content but with a different copy and an additional secondary CTA.
- **Example copy**: "All invoices archived. Show archived | New invoice."
- **Distinction from #1**: The user *knows* they emptied it; don't pretend they're a first-time user.

### 3. No-Search-Results
- **When**: User searched and the query returned no matches.
- **Tone**: Specific, helpful, blameless. Show the query.
- **Layout**: Centered. Reference the query verbatim. Suggest a specific next step (clear search, broaden, check spelling).
- **Example copy**: `No invoices matching "frobnicate". Try a different search or clear the search.` → CTA: "Clear search."
- **Distinction from #1**: The data exists; this query just didn't match. Don't show "Create new" as the primary CTA — they were searching, not creating.

### 4. Filter-Emptied-It (filters removed all matches)
- **When**: User applied filters that produced zero matches.
- **Tone**: Specific, with the filters surfaced.
- **Layout**: List the active filters as removable chips; primary CTA is "Clear filters." Optionally, "Show all without filters."
- **Example copy**: "No invoices match these filters. [chip: Status: Overdue ×] [chip: Amount: > $1000 ×]" → CTA: "Clear all filters."
- **Distinction from #3**: User was browsing with filters, not searching for a term. Different recovery path.

### 5. Permission-Denied (you can't see this)
- **When**: User authenticated but doesn't have permission to access this resource or section.
- **Tone**: Direct, blameless, with a recovery path.
- **Layout**: Centered. Explain *why* succinctly. CTA: contact the admin who can grant access, or return to a section they have access to.
- **Example copy**: "You don't have access to this project. Ask the project owner to invite you." → CTA: "Back to projects" / secondary: "Request access."
- **Distinction from 404**: The resource exists; the user can't see it. Don't show 404 — that's misleading and a security smell (404 vs 403 reveals existence in some contexts; that's a legal/security call, not a UX one — coordinate with the Developer agent).

### Optional sixth: Loading-Failed (transient empty)
- **When**: Data fetch failed but the underlying state isn't truly empty.
- **Tone**: Apologetic and recoverable.
- **Layout**: Inline error within the empty surface. CTA: retry.
- **Example copy**: "Couldn't load invoices. Try again." → CTA: "Retry."
- **Distinction**: Not an empty state proper — the table *might* have data, we just don't know. Don't show "Create new" — the user shouldn't create over what they can't see.

### The Decision Rule

**Pick the shape by origin, not by severity.** The user got here from somewhere — the recovery has to point back to that somewhere. A user who searched needs a clear-search affordance; a user who filtered needs a clear-filter affordance; a user who has never had content needs a create-first affordance. The shape is determined by *what the user just did*, not by how empty the screen feels.

### The Per-Screen Discipline

In the screen spec, every screen with a list/table/feed must explicitly address all applicable empty states. The default of "we'll show 'No data' " is a defect.

A reasonable spec pattern:

```markdown
### Empty State Coverage
- **Never-had-content**: "No team members yet. Invite your first." → CTA: "Invite member"
- **No-search-results**: "No team members matching '<query>'. Clear search to see all." → CTA: "Clear search"
- **Filter-emptied-it**: "No team members match these filters. <chips>" → CTA: "Clear filters"
- **Permission-denied**: N/A (this screen is owner-gated; non-owners are redirected at the layout)
- **Loading-failed**: Inline retry within the table area
```

## Error State Taxonomy

Errors break into categories by recoverability and severity. Each maps to a specific design surface.

| Category | Examples | Surface | User recovery |
|----------|----------|--------|---------------|
| **Validation** (form-level) | Invalid email, password too short, required field empty | Inline next to the field | Fix the input |
| **Recoverable transient** | Network blip, server timeout, brief API error | Inline retry within the affected component, or toast | Retry |
| **Recoverable persistent** | Quota exceeded, expired session, payment method declined | Banner (account-level) or inline with explanation | Resolve the underlying state (upgrade, sign in, update payment) |
| **Irrecoverable for this user** | Permission denied (403), resource not found (404), feature removed (410) | Full page (`error.tsx` / `not-found.tsx`) or empty-state | Navigate elsewhere, contact support |
| **Server-broken** | 500, 502, 503 | Full page (`error.tsx`) or banner if scoped | Retry, check status page, wait |
| **Maintenance** | Scheduled downtime, database migration | Full-page maintenance screen with ETA | Wait |
| **Offline** | No network connection | Banner at top + offline-friendly degraded view | Restore connection |

### Recovery Pattern Per Category

**Validation errors** live in the form. See `team/ui-ux/skills/web-form-patterns.md`. The summary: error message below the field, in `text-caption text-danger`, specific and actionable, never "Invalid input."

**Recoverable transient errors** (the user just clicked something and it briefly failed):
- Inline within the failing component if the rest of the screen is fine.
- Toast if the rest of the screen is fine and the error doesn't block the next action.
- Retry CTA visible. Don't auto-retry silently more than once — users should know their action failed.
- If retry is automatic with backoff (e.g., reconnecting WebSocket), show the state explicitly: "Reconnecting…"

**Recoverable persistent errors** (something is wrong with the account state):
- Banner at the top of the affected scope. Persistent until resolved.
- Specific: "Your trial ends in 3 days." not "Action required."
- Single CTA toward resolution: "Add payment method."

**Irrecoverable errors** (404, 403, 410): full pages — see "Brand Moments" below.

**Server-broken errors**: scoped to the failed component if possible (a single Server Action failing → inline error in that section), full-page only if the whole route can't render. Always include `error.digest` (or equivalent correlation ID) for support.

**Maintenance**: scheduled and announced; full-page with ETA; status-page link.

**Offline**: `navigator.onLine` is a coarse hint — it reports network-interface state, not internet reachability. It returns `true` on captive-portal hotel WiFi, on local-network-but-no-internet, and during intermittent connectivity. Designing a banner that flips on `navigator.onLine` alone produces a banner that flickers on captive portals and stays "online" when the user can't actually reach the server.

The Apple-bar pattern: pair `navigator.onLine` (instant signal) with **a periodic fetch heartbeat to a known endpoint** (truth signal) and a Service Worker that intercepts requests and surfaces network failures. Show the offline banner only when the heartbeat fails *or* `navigator.onLine` is false — and only after a brief debounce (1–2s) so a single packet drop doesn't trigger the UI. Restore: hide the banner when the heartbeat recovers (not just when `navigator.onLine` flips). Implementation lives in `team/developer/skills/web-observability.md`; the design intent (banner reflects *real* connectivity, not interface state) is set here.

### Error Message Voice

Apple-quality error messages are:

- **Specific.** Name the failed thing. "We couldn't reach the billing service" beats "Network error."
- **Blameless.** "We couldn't…" not "You did…" Don't blame the user for failures that aren't their fault.
- **Actionable.** Include the next step. "Try again" / "Update payment method" / "Contact support."
- **Brief.** One sentence, occasionally two.
- **Honest.** Don't say "Don't worry, this is normal" when it isn't. Don't promise "Try again later" if there's no later — say what's actually happening.

Bad:
> Oops! Something went wrong. Please try again.

Better:
> We couldn't load your invoices. Try again, or check status.example.com.

Best (with context):
> We couldn't load your invoices — the billing service is responding slowly. Retrying automatically… [Retry now]

The boundary with the Content agent: voice belongs to Content; the *structure* (one sentence, specific, actionable, blameless) is UI/UX's. Specs ship with placeholder copy and the structural rules; Content fills in with the brand voice.

## 404 / 500 / 403 / Maintenance as Brand Moments

The 404 page is the most-visited "error" page on most products. Apple's marketing 404 is a brief, on-brand page with a clear path forward. So is GitHub's. So is Stripe's. **A bad 404 page is a brand failure on a high-traffic surface** — it deserves design care.

### 404 (Not Found)
- **Tone**: Brief, on-brand, calm. No long copy.
- **Layout**: Centered. Page title ("Page not found" or product-specific equivalent), one-sentence framing, primary CTA back to a useful place (home or the section they were trying to reach).
- **Don't**: Long apologies, ASCII art, jokes that don't match the brand, autoplaying video.
- **Do**: Search input if the product is search-friendly (so users can find what they were looking for). Recently visited (if signed in).

### 403 (Forbidden / Permission Denied)
- See empty state #5 if scoped within a screen. If the user navigates directly to a forbidden URL, full-page 403 with same shape as 404 but different copy ("You don't have access to this page.").
- Distinguish from 404 in copy and (often) in HTTP status. Don't pretend forbidden resources don't exist unless there's a specific security reason.

### 500 / 502 / 503 (Server Errors)
- **Tone**: Apologetic, brief, with what we know. "Something on our side broke. We've been notified."
- **Layout**: Centered. Page title, one-sentence framing, primary CTA to retry or go home, secondary link to status page if there is one.
- **Include**: Error reference ID (`error.digest`) for support correlation, in muted small text at the bottom: `Reference: a3f72c1b`. This is non-negotiable — without it, support tickets are guesswork.

### Maintenance (503 Scheduled)
- **Tone**: Calm, factual, with timing.
- **Layout**: Centered. "We'll be back at HH:MM UTC." or "We'll be back in about 30 minutes." Primary action is none — the user just waits. Optional: link to status page or social handle for updates.

### Offline
- **Detection**: `navigator.onLine` + `online`/`offline` events. Hooks like `useOnline()` that wrap this are common but the state belongs at app shell, not per component.
- **Surface**: Persistent banner at the top: "You're offline. Some features are unavailable."
- **Degrade gracefully**: Show cached data with a "Last updated 5 min ago" timestamp; queue actions for retry on reconnect; disable actions that require connectivity.
- **Restore**: Banner changes to "Back online. Updating…" briefly, then disappears.

## Recovery Patterns

### Autosave + Restore
For long-form content (compositions, settings, multi-step forms), autosave + a "we lost your draft" recovery is the difference between a forgiving product and a punishing one.

- **Autosave silently** every 1–3 seconds during typing, debounced. Save on blur. Save on visibility change (tab background).
- **Indicator**: caption-sized "Saving…" → "Saved" with a subtle transition. Not a toast; not a modal; just inline text.
- **On crash / accidental close**: next visit, restore the unsaved version with a banner: "Restored your unsaved draft from 5 min ago." with "Restore" / "Discard" actions.

### Optimistic Update with Rollback
When an action fails after an optimistic update, the rollback must be visible. Don't just revert silently.

- Update UI immediately (`useOptimistic`).
- On failure, revert UI to actual state with a brief animation (so the user sees the revert).
- Show a toast: "Couldn't archive — try again." with a retry button.
- The user must know their action didn't succeed; silent rollback is the worst option.

### Retry Semantics
- **Manual retry** for actions the user initiated. Always offered after a recoverable failure.
- **Automatic retry with backoff** for background operations the user didn't initiate. Show the state ("Reconnecting…" / "Syncing in 5s…"). Cap the retry count and surface a manual fallback after 3 attempts.
- **No silent retry that succeeds** without telling the user — they need to know whether their action ultimately succeeded or failed.

## Loading States Inside Empty / Error Flow

Three patterns; pick by duration.

| Pattern | When |
|---------|------|
| **Skeleton** | Content is structured (table rows, card grid, article body) and we know the shape. Skeletons match content layout to prevent CLS. |
| **Spinner** | Action duration is unpredictable and the surface is small (button submitting, inline action). Or transient under 200ms where any UI flashes. |
| **Nothing** | Optimistic UI cases where the result appears instantly. The "loading" state is the real state, just temporarily wrong. |

Skeleton flash: if loading completes in under 200ms, show neither skeleton nor spinner. Render directly. The flash is more disruptive than the brief blank.

Skeletons must:
- Match the content layout exactly (same row count, same column structure, same spacing). A skeleton that doesn't match causes layout shift when content arrives.
- Use a subtle pulse, not a shimmer that races across the screen.
- Disable the pulse under `prefers-reduced-motion: reduce` (replace with a static muted fill).

Don't use a spinner on an empty state. A spinner says "we're working on it"; an empty state says "we're not." Mixing them confuses the user about what's happening.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **One empty state for every cause.** Same component renders for never-had / filter-emptied / search-no-results. | User can't tell *why* it's empty or what to do. Different problems get the same useless answer. | Distinct empty states per origin with copy and CTA matching the recovery path. |
| **Generic stock illustration.** "undraw.co"-style art that doesn't match the brand and doesn't say anything. | Decoration without communication. Often worse than no illustration. | Either commission a custom illustration (rare, expensive) or use no illustration. Strong typography is enough. |
| **"Oops! Something went wrong."** Generic apology with no specifics, no recovery, no reference. | The user knows it went wrong; that's why they're seeing the page. The message provides nothing. | Be specific about what failed; provide a recovery path; include an error reference. |
| **404 as a redirect to homepage.** No 404 page, just a silent redirect. | User doesn't know they hit a broken link; they're now on a page they didn't ask for. | Real 404 page with framing and a path forward. |
| **Empty state with three competing CTAs.** "Create new" + "Import" + "Watch demo" + "Read docs" all at the same weight. | Decision paralysis; no primary recovery. | One primary CTA aligned with the empty state's origin. Secondary actions as text links if needed. |
| **Spinner on an empty state.** Empty surface with a spinning loader. | Says "we're loading" when we're not. User waits forever. | Empty state means we *know* it's empty. Show the empty state. Loading is a separate state. |
| **Skeleton that doesn't match content layout.** Generic gray rectangles that don't preview the structure. | Layout shifts when content loads (CLS); the preview was misleading. | Skeleton matches the actual content shape — same row count, same column widths, same spacing. |
| **Skeleton flash on fast networks.** Skeleton briefly appears for 80ms before content. | More disruptive than just rendering content directly. | Show skeleton only after 200ms delay (or wait until paint commitment). |
| **Toast for things that should be inline.** Form validation errors as toasts. | Toast disappears; user has to remember; not associated with the field. | Validation errors next to the failing field, persistent until corrected. |
| **Inline message for things that should be a banner.** Account-level "trial expired" notice buried in a form. | Important persistent state hidden in a screen-specific surface. | Banner at the top of the app shell. |
| **Auto-retry that hides errors.** Background retry succeeds without telling the user the original failed. | The user thinks their action worked; it took 8 seconds; trust degrades silently. | Visible retry state ("Reconnecting…"); brief acknowledgment when restored. |
| **Silent optimistic rollback.** Action fails, UI quietly reverts, user doesn't notice. | User believes the action succeeded; later confused that it didn't. | Visible revert + toast explaining what happened with retry. |
| **404 with autoplaying media or jokes that don't match the brand.** | Either irritating or inappropriate to the moment. | Calm, brief, on-brand. The 404 is part of the product's voice; treat it accordingly. |
| **No error reference on server errors.** "Something went wrong" with no ID for support. | Support tickets become guessing games. Engineers can't correlate logs to incidents. | Always show `error.digest` or correlation ID in muted text. |
| **Permission-denied disguised as 404.** Forbidden resources show "Page not found." | Misleading to the user; sometimes a security smell, sometimes a UX failure. Coordinate with security/legal on which one applies. | If the user has *some* access (signed in), tell them they don't have permission to *this*. Reserve 404 for genuinely missing resources. |

## Output

An empty/error state design produces:

1. **Per-screen empty/error coverage** in the screen spec (`team/ui-ux/skills/web-screen-specification.md` → States section): which empty states apply, copy or copy placeholder, CTA, illustration treatment.
2. **App-shell error pages** at `/app/not-found.tsx`, `/app/error.tsx`, `/app/maintenance/page.tsx`, `/app/offline/page.tsx` (or equivalent) — each gets its own short spec covering layout, copy, primary CTA, and (where relevant) error-reference display.
3. **Voice rules for error messages** in `knowledge-base/brand-voice-guide.md` if not already present (Content agent owns; UI/UX provides the structural rules).

## Principles

1. **Empty is a state, not an error.** Treat it with the same care as the content state. Different origins (never-had / you-emptied / no-search / filter-emptied / permission-denied) get different shapes and different recoveries.

2. **Errors have voice.** Specific, blameless, actionable, brief, honest. "We couldn't reach the billing service" beats "Network error." Generic apologies are not Apple-quality.

3. **404 / 403 / 500 / maintenance pages are brand moments.** The most-visited pages on many products are the error pages. Design them with the same craft as the marketing hero.

4. **Distinct surfaces for distinct severities.** Inline for field-level, toast for transient action feedback, banner for persistent account-level state, full page for irrecoverable. Don't escalate or de-escalate; pick the right surface.

5. **Recovery is mandatory.** Every empty and error state has a clear next step. A page with no path forward is a dead end — and a brand failure.

6. **Loading matches content.** Skeletons match content layout exactly to prevent layout shift. Show skeletons only after 200ms; render directly when faster. Don't mix loading and empty.

7. **Always include an error reference for server errors.** `error.digest` or correlation ID in muted text. Without it, support is guessing and engineers can't correlate logs.

8. **Optimistic rollback is visible.** Failed actions revert visibly with a toast explaining what happened. Silent revert is the worst option — it erodes trust over time.

9. **Voice belongs to Content; structure belongs to UI/UX.** The shape (one sentence, specific, blameless, recovery) is UI/UX. The exact phrasing per the brand is Content. Specs ship with structural rules and copy placeholders.

10. **Empty and error coverage is part of the screen spec, not a fallback.** A spec without explicit empty and error states is incomplete. The default of "we'll figure it out" produces the failures this skill is designed to prevent.
