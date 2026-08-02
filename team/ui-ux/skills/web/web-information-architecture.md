# Web Information Architecture

## Purpose
Define the design of the product's navigation system as a *coordinated whole* — site map, URL structure, the relationship between top nav, sidebar, breadcrumbs, tabs, and the **command palette (cmd-K)** that has become the modern primary navigation surface for productivity-class web. The site map is a UX artifact, not just an engineering one. URLs are a UX surface (shareability, back-button, route-as-state), and routes that don't think about this fail in ways that compound. See the `web-design-system` skill for the tokens nav components consume. See the `web-content-hierarchy` skill for per-screen hierarchy (what's primary on a screen) — this skill is the *cross-screen* counterpart (how screens compose). See the `web-interaction-patterns` skill for the individual nav-component patterns (top nav, sidebar, bottom nav, breadcrumbs, tabs as widgets); IA is how those widgets compose into a system. See the `web-screen-specification` skill for how route context is documented per screen. See the `web-nextjs-app-router` skill for the routing primitives (App Router, route groups, parallel/intercepting routes) IA decisions are implemented through. Target: **product UI on web — multi-screen products with > ~5 destinations, where IA decisions accumulate into a real system**.

## The Anchor: IA Is a System, Not a Component Decision

Most product navigation fails not because any single component is wrong but because the components don't agree. A top nav, sidebar, breadcrumbs, search, and command palette all compete for the user's attention to "find things"; if the system doesn't decide which is the primary path for which task, the user does it on every interaction — and the product feels louder than it is.

The IA design's job is to **decide once, per product, what each surface is for**:

- The **top nav** is for primary destinations (≤ 6).
- The **sidebar** is for secondary navigation within a section.
- **Breadcrumbs** are for retracing position in a deep hierarchy.
- **Tabs** are for switching views *within* a screen.
- The **command palette** is for the fast path — what power users use after they learn the product.
- **Search** is for finding content by content (not by location).

Pick which exist in the product, decide what each one *is for*, and make the others stop trying to do that job. Apple's marketing pages have a top nav and search; their App Store has a tab bar + search; iCloud has a sidebar + Spotlight-style search; none of them try to compose all of these simultaneously. **The decision is which to omit, not which to include.**

## URL as UX

The URL is a UX surface and behaves like one:

- **It's shareable.** A user pasting a URL into Slack must arrive at the exact view they were looking at. State that's not in the URL is state the user can't share.
- **It's back-buttonable.** Pressing back must return to the previous meaningful state. If clicking three filters left the URL unchanged, the back button now skips three states the user thinks they performed.
- **It's deep-linkable.** A notification email pointing at a specific record must land directly there. URLs that require navigation to reach a state are URLs that are functionally not addressable.
- **It's bookmarkable.** A user who returns to a saved URL daily must arrive at the working state, not at a default screen that requires re-filtering.
- **It's analyzable.** Funnel events keyed by URL are far more reliable than events keyed by component renders. Routes that consolidate many states into one URL lose this for free.

Concretely: filters, sort order, search query, selected tab, opened modal — all belong in the URL. Things that don't: ephemeral UI state (a hover popover, a toast, a temporary loading indicator), private state the user shouldn't bookmark.

```
✅ /invoices?status=overdue&sort=due_asc&page=2
✅ /invoices/[id]                           ← deep link to record
✅ /invoices/[id]/mark-paid                 ← intercepting route: opens as modal over /invoices,
                                              renders as full page on direct navigation
❌ /invoices                                ← all state hidden in client memory
❌ /invoices/[id]?modal=mark-paid           ← query-param modal is a different (lesser) pattern,
                                              not how App Router intercepting routes work
```

App Router's intercepting + parallel routes (the `web-nextjs-app-router` skill) implement this via folder convention: a `(.)mark-paid` segment in `/invoices` intercepts navigation while a sibling `mark-paid/page.tsx` exists at `/invoices/[id]/mark-paid` as the full-page fallback. **Design implication: every modal route's content must work both as a modal and as a full page**, because direct navigation lands on the fallback. Spec the modal layout *and* the full-page layout (often the same component, occasionally with chrome differences). The *design* decision that "modals get URLs" is what enables this; the platform handles the rest.

### Route-Naming Discipline

- **Lowercase, kebab-case, no trailing slash.** `/billing-history` not `/Billing/History/`.
- **Route names are nouns or verbs at boundaries.** `/invoices` (collection), `/invoices/[id]` (item), `/invoices/new` (verb). Avoid `/manage-invoices`, `/view-billing` — UI verbosity leaking into the URL.
- **Route groups (`(marketing)`, `(app)`)** organize routing without affecting URLs. Use them to colocate layouts, not to decorate paths.
- **Localized routes get a locale prefix** (`/en/invoices`, `/de/rechnungen`) — see deferred i18n skill. Don't omit; retrofitting is painful.

## The Top Nav: 4–6 Primary Destinations

The top nav lists the product's primary destinations. Discipline:

- **4–6 entries maximum.** More means primary is undefined; the design owes a decision somewhere.
- **No "Home" link if the logo navigates home.** Redundant.
- **No "Menu" or "More" overflow on desktop unless the nav genuinely overflows.** Hiding 2 of 7 destinations behind "More" is a smell — the 2 that got hidden weren't really primary.
- **Active state per route segment, not per exact path.** Visiting `/invoices/123` highlights "Invoices" in the top nav.
- **Account, notifications, search are right-aligned utility area, not destinations** — distinct visual treatment from primary nav.

Mobile collapse: the primary destinations move into a bottom nav (3–5) or a hamburger sheet. Hamburger on phones is acceptable; **hamburger on desktop is an anti-pattern** when the nav fits horizontally — it hides discoverable destinations to save pixels that aren't needed.

## The Sidebar: Secondary Navigation Within a Section

The sidebar is for navigation *within* a primary destination ("within Invoices: Drafts / Sent / Paid / Archived"). It is not a second top nav — never put primary destinations there if they're already in the top nav.

- **Two levels of nesting maximum.** Beyond two, the user is navigating a tree, and the answer is a different IA — not more nesting.
- **Width: ~16rem (256px) expanded, ~3.5rem (56px) collapsed** to icon-only. Collapse state persists per user.
- **On `md` breakpoint and above** for desktop apps. Below `md`, sidebar collapses to a sheet behind a hamburger or to a bottom nav, depending on the product.
- **Group related entries under a heading.** Headings are caption-sized, muted text — they organize, they don't compete with destination labels.
- **Counts and badges sparingly.** A red `(3)` next to "Inbox" is meaningful; a `(127)` next to "All projects" is decoration.

When a product has both a top nav and a sidebar (Linear, Vercel, GitHub), the top nav is for cross-section destinations (Issues / Projects / Roadmap) and the sidebar is for within-section navigation (within Issues: views, filters, saved searches). The two coordinate; they don't repeat.

## Bottom Nav: Mobile Primary, Mutually Exclusive

Bottom nav is the phone equivalent of a top nav. 3–5 destinations, equal weight, current location highlighted. It is mutually exclusive with top-nav-as-primary-on-mobile:

- If the mobile shell uses bottom nav, the top of the screen has only the page title and a single utility action (search, notifications, or account).
- If the mobile shell uses a top nav (collapsed to hamburger), bottom nav is omitted.

Pick one. Both at once produces a chrome-heavy phone surface with very little space for content.

## Breadcrumbs: Use Sparingly

Breadcrumbs are for **deep hierarchies where the user needs to retrace position**. Common in admin tools (`Users / [User] / Permissions / [Role]`), file browsers, e-commerce categories. **Almost never needed in flat product apps** — most modern products are 1–2 levels deep, and the back button or a "Back to X" link is enough.

When breadcrumbs are correct:
- Last item is the current page (not a link).
- Truncate intelligently when long (`Home / … / Customer / Invoice 1042`).
- Don't repeat what the page title already says — breadcrumbs are wayfinding, the title is identification.

When they're wrong: breadcrumbs on a flat app, breadcrumbs on a single-level section, breadcrumbs as a *substitute* for clear page titles.

## Tabs: Within-Screen View Switching

Tabs switch views of the *same* content (Overview / Activity / Settings within a record detail). Not for navigating to different things. See the `web-interaction-patterns` skill for the tab component pattern; IA-side rules:

- **2–5 tabs.** Beyond 5 the layout breaks; consider drill-in or separate routes.
- **Tabs that map to URL state** (`?tab=activity`) get linkability and back-button support. Reach for this whenever tabs represent meaningful destinations.
- **Don't use tabs as primary navigation.** Tabs at the top of a page that switch to entirely different products is a top-nav in disguise — and a worse one (less discoverable, no global active state).

## The Command Palette (cmd-K): The Modern Fast Path

In 2026, the command palette is **table-stakes for any productivity-class web product**. Linear, Notion, Vercel, Raycast, GitHub, Stripe, Slack — the pattern is universal. Users who learn the product live in cmd-K; it is the fast path that lets the visible navigation stay sparse.

### What Belongs in the Command Palette

| Category | Examples |
|----------|----------|
| **Navigation** | Jump to any page, project, record by name |
| **Actions** | "Create new invoice," "Archive this project," "Invite teammate" |
| **Search** | Full-text across the product (records, content, settings) |
| **Recent** | Most recently visited records (top of the unfocused state) |
| **Theme / preferences** | "Switch to dark theme," "Change language" |

### Discipline

- **Trigger: ⌘K on macOS, Ctrl+K on Windows/Linux.** Show the keyboard shortcut hint in any UI that opens it. Optional secondary trigger: clicking a search-input affordance in the top nav.
- **Single input field, single result list.** Don't grow tabs inside the palette ("Pages / Actions / Search"); fuzzy-match across categories with category labels in results. *Prefix-driven scope shifting* — typing `>` to scope to actions, `#` to projects, `@` to people (Linear / Notion / Raycast pattern) — is the forward-compatible refinement and does not violate the no-tabs rule. It's mode-shifting via input, not chrome-tabbing within the palette.
- **Empty state shows recents and most-common actions**, not "Type to search."
- **Keyboard-driven by default**: ↑↓ to move, Enter to select, Esc to close. Mouse works but is secondary.
- **Result rows are typed**: icon (page / action / record), name, secondary metadata (path, last edited), keyboard shortcut if applicable.
- **Server-search for records when the local set is too large**. Debounced 200ms.
- **Command palette is a route or a modal?** Modal — opening it shouldn't lose the user's place. But the palette can *navigate to* routes. Don't make the palette itself a route.

### When the Command Palette Is the *Wrong* Default

Consumer products with non-power users (most marketing sites, casual apps, e-commerce) don't need cmd-K. The pattern is for products where users will return repeatedly and want a fast path. A consumer app where 80% of sessions are < 60 seconds doesn't pay back the implementation cost.

That's the call: cmd-K when users return; cmd-K omitted when they don't.

## Search: Finding by Content

Search is distinct from navigation:

- **Navigation** finds things by *where they are*.
- **Search** finds things by *what they contain*.

A product needs both. Search lives:

- In the top nav (always present, often a collapsed icon that expands).
- Or as the primary surface of the command palette (combined navigation + action + search).
- Or as a dedicated route (`/search?q=foo`) for full-page search results with filters.

Most products combine all three. Apple's products use Spotlight-style search heavily; the App Store's search is a primary tab. Search in modern web is not optional unless the product is very small.

### Search-Result Discipline

- Empty query state: show recent searches, suggestions, or the last few visited.
- Loading: skeleton results, not a spinner.
- No results: see the `web-empty-error-and-edge-states` skill → No-search-results.
- Result shape mirrors source: a record result looks like a row from the source table; a content result shows a snippet with the matched term highlighted.

## Modal State and Intercepting Routes

When a modal opens to show a record (e.g., "Quick view" of an invoice over an invoice list), the modal state belongs in the URL via App Router's intercepting routes (`@modal` slot). The user can:

- Bookmark the modal-open state.
- Share it.
- Refresh and land on the full-page version (the intercepted route is the fallback).
- Press back to close the modal.

This is non-obvious and requires deliberate IA design. The decision: which modals are URL-stateful, which are ephemeral. Defaults:

- **URL-stateful**: any modal showing a specific resource (record detail, settings panel, share sheet for a specific item).
- **Ephemeral**: confirmation dialogs, command palette, transient popovers.

Spec each modal in the screen spec as one or the other.

## Back-Button as Contract

Pressing back must return to the previous meaningful state. Rules:

- **Filter changes push history.** Back undoes the filter, doesn't leave the page.
- **Modal opens push history.** Back closes the modal, doesn't leave the page.
- **Tab switches push history when tabs map to URL.** Back returns to the previous tab.
- **Routine state changes (sort change, page paginate) push history.** Back returns to previous sort or page.

Anti-pattern: "smart" back buttons in the UI that try to predict where the user wants to go. The browser back button is the contract; in-product back buttons should match its behavior or be relabeled ("Up to project," "Close detail"). A back arrow that goes somewhere unexpected is the most disorienting kind of bug.

## Navigation State Persistence

Per-user state to persist across sessions:

| State | Persistence |
|-------|------------|
| Sidebar collapsed/expanded | Cookie (so server can render correctly on first paint) |
| Active section / last visited route | Cookie (for "return to where I was" on next sign-in) |
| Density mode for tables | localStorage or server preference |
| Saved filters per table | Server (multi-device) |
| Recent items in cmd-K | localStorage |
| Theme (light/dark) | Cookie (server-rendered without flash) |

Per-user state to *not* persist:

| State | Reason |
|-------|--------|
| Specific filter values (last applied) | These belong in URL; if the user wants to save them, that's "Save view" |
| Scroll position within a route | The browser handles this; don't override |
| Modal open state | Ephemeral or URL-driven, never persisted |

## IA Audit: The Health Check

A product's IA is healthy when:

- **A new user can name the product's primary destinations after 30 seconds** of looking at the top nav or sidebar.
- **A returning user reaches their most-common task in ≤ 2 clicks** from any starting screen — or 0 clicks via cmd-K.
- **Pasting any URL into a fresh tab** lands at the exact view it represents.
- **Pressing back** always returns to the previous meaningful state.
- **The user can find any record they remember by name** via search or cmd-K within 5 seconds.

If any of these fail, the IA owes a decision.

## Apple-Quality References

- **Apple's marketing pages**: 7 destinations in top nav (Store, Mac, iPad, iPhone, Watch, AirPods, TV & Home), search icon, Bag icon. Sparse, predictable, search-prominent.
- **App Store on web**: tab-bar IA (Discover / Apps / Arcade / Search), product pages have URL state for screenshots and reviews.
- **iCloud.com**: sidebar nav (Mail / Drive / Photos / Notes / Reminders / Calendar / Pages / Numbers / Keynote), each app gets its own internal IA.
- **Apple Support**: search-first, then categorized navigation, breadcrumbs only inside deep article hierarchies.

What's consistent across all of them: small primary nav, search prominent, no carousels, no overflow menus on desktop, URL stability.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **9 top-nav links plus 7 sidebar links plus no command palette.** | Discovery is harder, not easier — every link competes. Power users have no fast path. | Prune top nav to 4–6, sidebar to grouped < 2 levels, ship cmd-K. |
| **Hamburger menu on desktop when nav fits horizontally.** | Hides discoverable destinations to save pixels you don't need. Ubiquitous SaaS regression. | Show the nav. Hamburger is a phone pattern. |
| **Filters stored only in component state.** | Not shareable, not bookmarkable, not back-buttonable, not analytics-friendly. | Filters in URL. Always. |
| **Modal state without a URL.** | Refresh closes the modal; share-link doesn't open it; back button leaves the screen. | Intercepting routes for resource-detail modals. Ephemeral modals (confirms, palette) stay URL-less. |
| **"Smart" in-product back button that predicts where the user wants to go.** | Disorientation. The browser back button is the contract. | In-product back arrows match browser back, or are relabeled ("Up to project"). |
| **Breadcrumbs on a flat product app.** | Wayfinding for a hierarchy that doesn't exist. | Remove. Page title is enough. |
| **Tabs used as primary navigation.** | A top nav in disguise — less discoverable, no global active state. | Use top nav for primary destinations; tabs for within-screen view switching. |
| **Persisting filter values across sessions.** | User returns to a stale view they didn't explicitly save. Confusing. | URL holds the active filter. "Saved views" is a separate, explicit concept. |
| **Top nav with a "More" overflow menu on desktop hiding 2 of 7 destinations.** | The 2 that got hidden weren't really primary; the design is dodging the pruning decision. | Cut to 5; the omitted 2 belong elsewhere (account menu, secondary IA, removed). |
| **Cmd-K that opens a modal full of category tabs.** | Defeats the speed of the command palette. The point is type-and-go. | Single input, fuzzy-match across categories, category labels in results. |
| **Cmd-K shortcut that's discoverable only by power users.** | The fast path is hidden from the people who need it most (returning users not yet expert). | Show "⌘K" hint in search affordances; prompt with the shortcut once after 2nd visit. |
| **Routes that don't match the IA.** Sidebar shows "Settings → Billing → History" but URL is `/account-settings/billing-history?view=transactions`. | URL doesn't reflect the navigation; deep links don't make sense. | URL structure mirrors the IA tree. `/settings/billing/history`. |
| **Page titles that don't match nav labels.** Sidebar says "Inbox," page title is "All Messages — Personal Account." | Inconsistency; user can't verify they're where they thought they were. | Same word in nav, in page title, in URL segment. |
| **No "What's here?" empty state for an empty section.** Sidebar lists "Projects" → user clicks → blank table. | The empty section is its own state; needs a CTA toward populating it. | See the `web-empty-error-and-edge-states` skill → never-had-content. |

## Output

An IA design produces:

1. **Site map** in `knowledge-base/design-specs/site-map.md` — text-based tree of all routes, with brief one-liner per leaf indicating purpose. Updated as the product grows.
2. **Navigation system spec** in `knowledge-base/design-specs/navigation.md` — top nav contents, sidebar contents (per section), bottom nav contents (mobile), command-palette contents, breadcrumb scope, search scope. Updated when IA changes.
3. **URL convention reference** appended to `knowledge-base/design-specs/site-map.md` — the URL-naming rules above as applied to this product, plus the list of which modals are URL-stateful.

These are the inputs to per-screen specs (the `web-screen-specification` skill); each screen spec's Route Context section pulls from them.

## Principles

1. **IA is a system. Pick what each surface is for, then let the others stop trying to do that job.** Top nav for primary, sidebar for secondary-within-section, breadcrumbs for deep hierarchies, tabs for within-screen views, cmd-K for the fast path, search for content. Decide once.

2. **The URL is a UX surface.** Shareability, back-buttonability, bookmarkability, deep-linkability, analyzability — all flow from URL state. Filters, sort, search, selected tab, opened resource modal: all in the URL.

3. **Cmd-K is table-stakes for productivity-class web in 2026.** Sparse visible navigation works because power users don't use the visible navigation. Ship the palette; the rest of the IA gets to be smaller.

4. **Decide what to omit.** A nav surface every product wants will compete with the others if all are present. Apple's products omit aggressively — App Store has no breadcrumbs, iCloud has no top nav, marketing pages have no sidebar. The omission is the design.

5. **The back button is a contract.** Every meaningful state change pushes history. In-product back buttons match browser back, or are relabeled to indicate they don't.

6. **Routes match the IA tree.** URL structure mirrors the navigation hierarchy. Page title, nav label, and URL segment use the same word.

7. **Persist what's about the user; URL-encode what's about the view.** Sidebar collapse is per-user; filter values are per-view. Mixing them produces stale state on return and unshareable links.

8. **Healthy IA passes the audit.** A new user names primaries in 30s; a returning user reaches their most-common task in ≤ 2 clicks or 0 with cmd-K; URLs are deep-linkable; back is reliable; search finds anything by name in 5s. If the audit fails, the IA owes a decision before more screens ship.
