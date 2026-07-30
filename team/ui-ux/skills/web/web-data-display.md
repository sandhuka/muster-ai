# Web Data Display

## Purpose
Define how to design data-dense surfaces on the web — tables, grids, dense record lists, sortable / filterable views, row selection, inline editing, density modes, virtualization, sticky headers, frozen columns, bulk actions, summary rows. The web's most common product surface that iOS rarely encounters: admin tools, dashboards, mail clients, finance products, App Store Connect-style management UIs, audit logs, billing histories. The Stack Overflow median for this surface is "drop in react-table and call it done"; the Apple-quality answer is a small set of token-driven patterns that compose, scan well, and degrade gracefully across viewports. See the `web-design-system` skill for the tokens these patterns consume. See the `web-content-hierarchy` skill for the broader hierarchy rules; this skill applies them within data-dense surfaces. See the `web-empty-error-and-edge-states` skill for the empty / loading / error states data tables produce. See the `web-interaction-patterns` skill for overlay patterns (popover filters, action menus). See UI/UX's `web-accessibility` skill for the design-side a11y rules these patterns enforce; see Developer's `web-accessibility` skill for the implementation-side semantics (real `<table>` markup, `aria-rowcount`, screen-reader narration). Target: **product UI on web — tables, grids, and list-style data display in React 19+ / Next.js 15+ / Tailwind v4**.

## The Anchor: Table, Grid, or List?

The first decision is which surface the data wants. Picking wrong is the root cause of most data-display pathologies.

| Surface | Use when | Apple reference |
|---------|---------|----------------|
| **Table** (real `<table>`) | Each row is a record with the *same set of comparable attributes*. Users will scan columns, sort, filter, compare across rows. | App Store Connect → Sales, Mail → message list (table-row variant) |
| **Grid** (CSS Grid of cards) | Each item is a thumbnail-or-visual-first object users browse. Card content varies; comparison across attributes is secondary. | App Store → app cards, Photos → grid view |
| **List** (`<ul>` of rows or `<dl>` of pairs) | Sequential records where the dominant action is "open this one" or where attributes don't merit columns. | Mail → conversation threads, Notes → note list |

Rules:

- **Don't use cards for tabular data.** Six attribute-comparable records as cards is a table in costume — slower to scan, more pixels per row, no sort affordance. The "card grid for everything" pattern is a hallmark of vibes-coded LLM output.
- **Don't use a `<table>` for layout.** This was settled twenty years ago and should not need restating, but framework-generated layouts still occasionally do it. Tables are for tabular data only.
- **A "list" of records with consistent attributes is just a table styled with no borders.** That's a legitimate stylistic choice (Mail, Linear) but it's still a table semantically — use real `<table>` markup so screen readers and keyboard navigation work.

## Density Modes

Tables exist at three densities. The system ships all three; the user picks.

| Mode | Row height | Use |
|------|-----------|-----|
| **Comfortable** | 48–56px | Low-frequency lookup, settings, marketing-flavored tables. Default for casual users. |
| **Default** | 36–44px | The standard. Most product tables. Calibrated to Apple's reference apps (Mail, Reminders, Calendar). |
| **Compact** | 28–32px | Power-user tools where users scan many rows (audit logs, finance, observability). |

Implementation: a single `data-density` attribute on the table root drives row padding via CSS variables. **Never sacrifice the 44×44 touch-target floor on touch devices** — compact and default modes show on `(pointer: fine)` only; touch users get comfortable as the floor.

```css
[data-density="comfortable"] { --row-pad-y: 0.625rem; }  /* 10px → 48–56px row */
[data-density="default"]     { --row-pad-y: 0.375rem; }  /* 6px  → 36–44px row */
[data-density="compact"]     { --row-pad-y: 0.125rem; }  /* 2px  → 28–32px row */

@media (pointer: coarse) {
  [data-density="default"],
  [data-density="compact"] { --row-pad-y: 0.625rem; } /* clamp to comfortable on touch */
}
```

Persist the user's density choice in cookie or localStorage scoped to the table identity (or globally if the product has one canonical density). Don't reset on navigation.

## Column Architecture

### Cell Types

The system ships a small set of cell types. Each has a single way to render and sort.

| Type | Render | Align | Sort behavior |
|------|--------|-------|--------------|
| Text (short) | Truncate to one line, full value in tooltip on hover and on focus | Left | Lexicographic |
| Text (long, descriptive) | Wrap to 2 lines max with ellipsis, expand on row click | Left | Lexicographic |
| Number / amount | Tabular figures (`font-feature-settings: "tnum"`) | **Right** | Numeric |
| Currency | Tabular figures, locale-formatted, currency symbol left-aligned within right-aligned column | Right | Numeric |
| Date / timestamp | Locale-formatted; absolute on hover, relative in cell ("2h ago") | Left | Chronological |
| Status / badge | One pill with icon + label (color + shape, never color alone) | Left | By status priority |
| User / avatar | Avatar (24px) + name; avatar alone in compact mode | Left | By display name |
| Action | Icon button (single primary action) or `…` overflow menu | Right | Not sortable |
| Boolean | Checkmark or em dash (`—`); never raw "true"/"false" | Center | True-first |

Tabular figures (`tnum`) are non-negotiable for any column showing numbers — without them columns of digits don't align and the table loses scannability. This is enabled per cell, not globally, since proportional figures look better in body text.

### Column Decisions

Three rules that prevent feature-creep:

1. **Sortable columns earn it.** A column is sortable when users would actually sort by it. "Status" yes; "Notes" no. Marking every column sortable creates noise. Default sort indicators only on the active column; show a subtle hover-revealed icon on others.
2. **No more than 7–8 visible columns at default density on desktop.** More means horizontal scroll, which means the user has to remember what's off-screen. If the data has more attributes, hide the rest behind a column-picker or a row-detail expansion.
3. **Avoid "Actions" as a sortable concept.** The actions column is fixed-width, right-aligned, never sortable, never resortable.

### Column Resize and Reorder

The honest answer: most products don't need column resize or reorder. They're high-engineering-cost, high-bug-surface features that solve a problem the data layout should solve directly (better defaults). Ship them only when the product is a genuine power-user data tool (analytics, observability, spreadsheet-class). For everyday product tables, **fixed columns with smart widths beat draggable columns with bad defaults**.

When the product genuinely needs resize/reorder:
- Persist per-user state (cookie or server preference).
- Provide a "Reset columns" affordance.
- Resize handles must be 8px wide minimum and have a visible cursor change.
- Reorder uses drag-and-drop with a keyboard alternative (Space to grab, arrow keys, Space to drop) — see the `web-interaction-patterns` skill → Drag and Drop.

## Sticky Headers, Frozen Columns

### Sticky Header

For any table with more than ~10 rows or any chance of vertical scroll, the column header is `position: sticky` to the top of the table's scroll container. **Use `position: sticky`, not `fixed`** — sticky stays within the table boundary, fixed escapes it. The header background must match the surface (`bg-surface-raised`) and have a 1px bottom border so it visually separates from scrolled rows.

### Frozen First Column

For tables wider than the viewport on mobile or tablet, freeze the leftmost column (typically the row identifier — name, email, ID). Implementation uses `position: sticky` on the cell with the appropriate left offset. Frozen column needs a right-edge shadow (subtle, theme-aware) to indicate scrollable content beyond.

Don't freeze more than one column on the left. Don't freeze any column on the right in product tables — it's a niche analytics-tool pattern that confuses general audiences.

## Selection

Three selection patterns, picked by use case:

| Pattern | When | Implementation |
|---------|------|---------------|
| **None** | Read-only tables, no batch operations available | No checkboxes, no selection state |
| **Single-select (radio)** | Picker tables (e.g., choose a billing address) | Radio in first column; row click selects |
| **Multi-select (checkbox)** | Batch operations available | Checkbox in first column; header has "select all visible" + indeterminate state |

Multi-select rules:

- **"Select all" selects all *visible* rows by default.** If the user has filtered or paginated, selecting all on the current page is the right semantics. Offer a separate "Select all matching filter" action that appears in the bulk-action toolbar after first selection — and announces the count clearly ("Select all 1,247 invoices matching this filter").
- **Indeterminate state on the header checkbox** when some-but-not-all visible rows are selected. Click on indeterminate **clears the selection** (not selects all). This is the GitHub / Linear / Notion convention — opposite of the browser default for clicking an indeterminate checkbox (which sets it checked) but the right product UX (otherwise users with a partial selection accidentally select hundreds of additional rows). Pick this as the convention and ship it consistently across the product.
- **Persist selection across pagination** when data is server-paginated. Show a toast or banner: "12 selected (across 2 pages)." Clear selection on filter change unless the user explicitly opts to keep.

## Bulk Actions

When rows are selected, a bulk-action surface appears. Two patterns:

| Pattern | When |
|---------|------|
| **Toolbar replaces table header** (slide-down or fade-in over the column-header row) | Default. Most product tables. Action affordances stay close to the data. |
| **Floating action bar** (sticky at bottom of viewport) | Long-scroll tables where the header has scrolled out of view. |

Toolbar contents: count of selected items, primary actions (max 3 visible: e.g., "Archive," "Export," "Delete"), overflow menu for the rest, "Clear selection" or `×` button on the right.

Destructive bulk actions follow the `web-interaction-patterns` skill → Confirmations and Undo:
- Recoverable (archive, hide): proceed immediately, show toast with "Undo."
- Irrecoverable (permanently delete): confirmation dialog with the count ("Permanently delete 12 invoices? This cannot be undone.").

## Inline Editing

For tables where users frequently update field values (settings rows, spreadsheet-style tools), inline editing beats opening a modal. Discipline:

- **Click-to-edit, not double-click-to-edit.** Double-click is desktop-spreadsheet vocabulary that doesn't translate to web; users won't discover it.
- **Cell shows edit affordance on row hover** (subtle pencil icon or border change). Hover affordance is always backed by a static signal — see UI/UX's `web-accessibility` skill on hover-only patterns.
- **Enter or blur saves; Escape cancels.** Esc reverts to original value.
- **Validation appears inline below the cell.** If the value is invalid, the cell stays in edit mode until corrected or cancelled.
- **Save state is announced.** Brief "Saved" indicator (caption-sized, fades in 200ms, fades out 1.5s). For autosave-on-every-edit, see the `web-form-patterns` skill → Autosave.

Inline editing has a real keyboard-navigation requirement: Tab moves to the next editable cell (not the next focusable element on the page). Specify the keyboard model in the screen spec.

## Sorting and Filtering

### Sort Affordance

The active sort column has a visible indicator (▲ ascending / ▼ descending) next to its header label. Inactive sortable columns show the indicator only on hover/focus, in a muted color. Don't show indicators on non-sortable columns.

Default sort: pick the column users sort by most often (often a date — "Most recent first"). Persist the user's sort choice per table identity.

### Filter Surfaces

Three filter patterns, picked by complexity:

| Pattern | When |
|---------|------|
| **Search input** above the table | Full-text search across the table. Always present. Debounced 300ms. Shows count: "127 results." |
| **Filter chips** above the table | A small set of common filters ("All / Active / Archived"). One-click apply. Active chip is visually distinct. |
| **Filter sheet** behind a "Filters" button | Multiple complex filters (date range + status + assignee + tag). Opens as a popover or side sheet. Active-filter count badge on the button. |

Active filters are visible. A user who set a filter five minutes ago and forgot is the most common source of "where's my data?" support tickets. Surface active filters as removable chips above the table with an "X to clear" affordance, plus "Clear all filters" when more than one is active.

### Filter State in URL

Filters and sort belong in the URL (`?status=active&sort=created_desc`). This makes views shareable, back-button-restorable, and analytics-trackable. See the `web-information-architecture` skill → URL as UX.

## Pagination Patterns

Three patterns, picked by data shape:

| Pattern | When | Notes |
|---------|------|-------|
| **Pagination** (numbered pages, prev/next) | Bounded result sets, users may want to deep-link a specific page, server constraints favor pagination | Page size selector (25 / 50 / 100). Include "page X of Y" — users want to know how much data exists. |
| **"Load more" button** | Append-only feeds where users scroll then act | Preserves scroll position, doesn't break back-button, accessible. |
| **Infinite scroll** | Truly browse-only feeds (social, image grids) where scroll-and-skim is the use case | **Avoid for tables.** Breaks back-button, breaks Cmd+F, breaks footer reachability, breaks deep-linking. |

The default for most product tables is pagination. Infinite scroll is the exception and should be argued for.

## Virtualization

Virtualization (rendering only visible rows) is correct when:
- Visible row count > 200 at any density.
- Rows are uniform-height (variable-height virtualization is a known fragility).
- The table doesn't need to be searchable via Cmd+F (virtualized rows aren't in DOM).

When in scope, use a single library across the product (TanStack Virtual or react-virtuoso). Don't roll your own.

When *not* virtualizing: a 50-row table with a `position: sticky` header is faster, simpler, more accessible, and easier to debug. Default to no virtualization until profiling demands it.

## Responsive Behavior

Tables don't gracefully shrink. The right answer depends on data shape:

| Table type | Phone treatment |
|------------|----------------|
| **Reference data** (price list, comparison) | Horizontal scroll within a container with a frozen first column. Don't reflow — comparison requires column alignment. |
| **Listed records** (orders, transactions, users) | Reflow into a stack of "row cards" — each row becomes a card showing the same fields stacked vertically. Use `<ul>` of row components, not `<table>`. Maintain row click → detail navigation. |
| **Spreadsheet / dense data** (analytics, audit) | Acknowledge tablet-or-larger as the floor. Show a phone-friendly summary or chart on small viewports with a "View full data" link. |

Don't try to shrink every column at every breakpoint — the result is unreadable. Either commit to the reflow, the scroll, or the "this view requires more space" message.

The reflow pattern needs a designed row-card component, not just CSS that hides the table. It's a different shape: name + key fact prominent, secondary fields below, action menu on the right. Spec it explicitly.

## Empty, Loading, and Error States

These belong to the `web-empty-error-and-edge-states` skill. Tables produce several distinct empty shapes:

- **Never-had-content**: "No invoices yet" + CTA to create the first.
- **Filter-emptied-it**: "No invoices match these filters" + clear-filter CTA. Distinct from never-had-content.
- **No-search-results**: "No invoices matching 'frobnicate'" + clear-search CTA.
- **Permission-denied**: "You don't have access to invoices" + contact-admin CTA.
- **You-emptied-it** typically does *not* apply to record tables (records aren't usually deleted en masse from a table view — they're archived individually with undo). If the product genuinely supports table-emptying actions, model it; otherwise mark N/A in the screen spec.

Loading: skeleton rows that match the column structure. Show after 200ms (avoid skeleton flash on fast networks). Don't replace the entire table on filter change — show a subtle loading bar at the top instead, or fade the existing rows briefly.

## Accessibility

Design-side specifications (implementation in Developer's `web-accessibility` skill):

- **Use real `<table>` semantics.** `<thead>`, `<tbody>`, `<th scope="col">`, `<th scope="row">` for any row-identifier column. Never `<div role="table">` unless absolutely no other choice.
- **Headers describe their column.** Sort buttons are `<button>` inside `<th>`; current sort state communicated via `aria-sort`.
- **Selection is a checkbox**, properly labeled (`Select row "Invoice #1042"`).
- **Bulk action toolbar uses `role="toolbar"`** with a clear `aria-label` ("Bulk actions for selected invoices").
- **Row click destinations** are `<a href>` wrapping the row content (or a single anchor in a primary cell). Don't use `onClick` on `<tr>` — keyboard users can't reach it.
- **Tabular figures and column alignment** are not just visual — they make screen-reader narration sensible.
- **Keyboard navigation**: Tab moves through interactive elements; arrow keys navigate cells only in genuine spreadsheet-class tools (rare). Don't reinvent keyboard nav for product tables.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| **Cards for tabular data.** Six records of identical attributes rendered as a card grid. | Slower to scan than a table; no sort affordance; pixel-inefficient. | Use a table. Cards are for browse-grids of varied content. |
| **Every column sortable.** All header cells get the sort indicator. | Visual noise, signals indecision, dilutes the affordance for columns that genuinely benefit. | Mark only the columns users actually sort by. Hide indicators on others. |
| **No tabular figures.** Numeric columns of proportional digits. | Numbers don't line up; columns become unscannable. | `font-feature-settings: "tnum"` on numeric and currency cells. |
| **Hover-only row actions.** Action icons appear only when hovering a row. | Touch users have no hover; pointer users don't discover them; assistive tech doesn't see them until tab focus. | Show actions persistently on touch (`@media (pointer: coarse)`) or use an overflow `…` menu that's always visible. |
| **Truncation without recovery.** Cell text cut off with ellipsis and no way to see the full value. | Information silently inaccessible; users don't know it's truncated. | Show full value on hover (tooltip) and on focus; or make the row click open a detail view that shows it. |
| **Cards-disguised-as-tables for accessibility.** `<div>` grid styled to look like a table. | Loses table semantics — screen readers can't navigate by row/column, sorting doesn't announce, scope is ambiguous. | Real `<table>` with `<thead>` / `<tbody>`. Style with CSS as needed; semantics first. |
| **Infinite scroll for record tables.** Append rows as user scrolls, no pagination. | Breaks back-button, Cmd+F, footer reachability, deep-linking, scroll-position restoration. | Pagination or "Load more." Reserve infinite scroll for browse feeds. |
| **Filters with no visible state.** Active filters that aren't shown anywhere in the UI. | Users forget; "where's my data?" support tickets; loss of trust. | Active filters as removable chips above the table; "Clear all" when > 1 active. |
| **Click-anywhere-on-row to sort.** No clear sort affordance; clicking a header acts ambiguously. | Users don't discover sort; accidental sorts when trying to interact with cell content. | Header sort as `<button>` inside `<th>` with explicit indicator; click row content opens detail. |
| **Spreadsheet keyboard nav on product tables.** Arrow keys move cells in a 30-row settings table. | Unexpected; collides with browser scrolling and form inputs. | Tab navigation through interactive elements. Reserve arrow-key cell nav for genuine spreadsheet-class tools. |
| **Density mode that breaks touch targets.** Compact mode shipping on touch with 28px row height. | Fails WCAG 2.5.5; users miss taps. | Clamp compact to default on `(pointer: coarse)`. |
| **"Select all" actually selecting all on the server.** Selecting all visible silently selects 50,000 records. | Unintended bulk operations on data the user can't see. | "Select all" = visible. Offer "Select all matching" as a separate, explicit choice with the count. |
| **Resize and reorder columns shipped before they're needed.** Drag handles on every header, persistence half-built. | High maintenance, low user adoption, frequent bugs. | Default to fixed columns with good widths. Add resize/reorder when the product is a genuine power-user data tool. |
| **Empty state that just says "No data."** Same empty-state UI for every cause (never-had / filter-emptied / search-no-results). | Users can't tell *why* the table is empty or what to do. | Distinct empty states per origin. See the `web-empty-error-and-edge-states` skill. |

## Principles

1. **Pick the right surface first.** Table for comparable records, grid for visual browse, list for sequential read. Picking wrong is the root cause of most data-display pathologies; everything else is downstream.

2. **Real `<table>` semantics for tabular data.** No exceptions for "we styled it as cards" or "we used CSS Grid." If the data is rows-of-comparable-records, the markup is `<table>` and the surface inherits sort, navigation, and screen-reader behavior for free.

3. **Density modes that respect physical limits.** Three modes (comfortable / default / compact); compact never ships on touch where it would break the 44×44 floor. The system gives the user the choice; the design enforces the floor.

4. **Tabular figures everywhere there are numbers.** `tnum` is not optional. Numeric columns that don't align are unscannable.

5. **Sortability and column count are restraint exercises.** Every sortable column earns it; every visible column earns it. The default is "fewer columns, fewer sorts" — add only when use justifies.

6. **Filters and sort live in the URL.** Views are shareable, restorable, analytics-friendly by default. Filter chips above the table make active state visible.

7. **Selection semantics are explicit.** Single vs. multi vs. none, picked by use case. Multi-select-all means *visible*; matching-all is a separate, count-announced action.

8. **Pagination over infinite scroll for tables.** Infinite scroll is the exception; argue for it. Default preserves back-button, Cmd+F, footer, deep-linking.

9. **Responsive is a different shape, not a smaller table.** Reflow into row-cards for record-style data; horizontal-scroll-with-frozen-column for reference data; "view requires more space" for analytics. The reflow shape is its own designed component.

10. **Design empty states per origin, not as a fallback.** Never-had / filter-emptied / search-no-results / permission-denied are different problems with different recoveries. Treat them as such.
