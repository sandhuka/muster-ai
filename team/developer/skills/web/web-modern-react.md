# Modern React (React 19+)

## Purpose
Define modern React patterns: Server/Client component discipline, effects rules, Server Actions integration, Suspense, `useTransition`, `useOptimistic`, the `use` hook, refs as props, custom hooks, and composition. See `team/developer/skills/web-architecture.md` for layer-level server/client boundary rules. See `team/developer/skills/web-state-management.md` for state libraries (Zustand, TanStack Query). See `team/developer/skills/web-nextjs-app-router.md` for routing-level concerns. Target: **React 19+, Next.js 15+, TypeScript 5.5+**.

## Component Types

A React component on the modern web is one of three things, picked deliberately.

| Type | Directive | Renders | Use when |
|------|-----------|---------|----------|
| Server Component | none (default in App Router) | Server only | Reads data, renders content, no event handlers, no browser APIs |
| Client Component | `"use client"` at top of file | Server (initial) + Client (hydration + re-render) | Has event handlers, uses `useState`/`useReducer`/`useEffect`, accesses browser APIs (`window`, `localStorage`), wraps a third-party client library |
| Shared component | none (no `"use client"`) but written without server-only or client-only APIs | Either context (caller decides) | Pure presentational primitives — buttons, layout, typography (`components/ui/*` mostly fits here) |

Decision tree when writing a new component:

1. Does it need event handlers, hooks beyond `use`, or browser APIs? → Client Component (`"use client"`).
2. Does it fetch data or render server-only content? → Server Component (no directive).
3. Pure presentation, neither of the above? → Shared component (no directive, no client-only APIs).

A Client Component can render Server Components passed as props (`children`, slot props). The reverse — Server Component rendering a Client Component — is the common case.

## Effects Discipline

Most React bugs and most performance pathologies come from misuse of `useEffect`. Apple-level discipline: **`useEffect` is for synchronizing with external systems, nothing else**.

### When `useEffect` is correct

- Subscribing to a non-React data source (browser API, third-party library, DOM event you can't bind via JSX).
- Setting up an interval, timer, or animation frame.
- Reporting analytics on mount or on prop changes (when not handled by RSC + Server Actions).
- Imperatively focusing/scrolling a DOM node.

If the answer to "what external system am I syncing with?" is "none" — you don't need an effect.

### When `useEffect` is wrong

| Anti-pattern | Fix |
|--------------|-----|
| Deriving state from props/state | Compute during render: `const total = items.reduce(...)`. Cache via `useMemo` only if measurably expensive. |
| Resetting state on prop change | Pass a `key` to the component to remount it cleanly. |
| Communicating up to a parent | Use the event handler that triggered the change to call the parent's callback — don't `useEffect(() => onChange(value))`. |
| Initializing state from props | `useState(() => deriveFromProps(props))` (lazy initializer). |
| Fetching data on mount | Server Component `await fetch` or TanStack Query, not `useEffect(() => fetch(...))`. |
| Chaining state updates | One state update per event; if you need to chain, use a reducer or move the logic into the event handler. |

### Cleanup is not optional

If an effect subscribes, schedules, or attaches anything, the cleanup must un-do it. The mental model: every effect runs at least twice in development (Strict Mode) — your code must be idempotent.

```tsx
useEffect(() => {
  const controller = new AbortController();
  fetchSomething({ signal: controller.signal });
  return () => controller.abort();
}, []);
```

### Effect dependencies

The dependency array is not optional, never `[]` to silence the linter on a non-empty effect. If a value is used inside the effect, it goes in the array. If you don't want a value to retrigger, restructure (move the effect, derive the value, lift state).

## Server Actions

Server Actions are server-side functions callable from client code. They are the modern replacement for API routes for mutations. Architecture skill covers the deps pattern; this section covers the React side.

### Form actions (progressive enhancement)

Wire a Server Action directly to a form's `action` prop. The form works without JavaScript.

```tsx
// features/invoicing/components/invoice-form.tsx
import { createInvoice } from "../actions";

export function InvoiceForm() {
  return (
    <form action={createInvoice}>
      <input name="customerId" required />
      <input name="dueAt" type="date" required />
      <button type="submit">Create</button>
    </form>
  );
}
```

The `createInvoice` action receives `FormData` as its first argument. Validation, persistence, and `revalidatePath` happen server-side. No fetch boilerplate, no API route.

### `useActionState` for form state

When the action returns a result (success or errors), bind it via `useActionState` (renamed from `useFormState` in React 19).

```tsx
"use client";

import { useActionState } from "react";
import { createInvoice } from "../actions";

const initialState = { ok: false, errors: {} } as const;

export function InvoiceForm() {
  const [state, formAction, pending] = useActionState(createInvoice, initialState);
  return (
    <form action={formAction}>
      <input name="customerId" aria-invalid={!!state.errors?.customerId} />
      {state.errors?.customerId && <p role="alert">{state.errors.customerId}</p>}
      <button type="submit" disabled={pending}>
        {pending ? "Creating…" : "Create"}
      </button>
    </form>
  );
}
```

The `pending` flag eliminates the need for `useState` + `try/finally` to track submission state.

### `useFormStatus` for nested submit components

If the submit button is in a different component than the `<form>`, use `useFormStatus` to read pending state without prop drilling.

```tsx
"use client";

import { useFormStatus } from "react-dom";

export function SubmitButton({ label }: { label: string }) {
  const { pending } = useFormStatus();
  return <button type="submit" disabled={pending}>{pending ? "Working…" : label}</button>;
}
```

### Revalidation

Server Actions trigger router revalidation explicitly. The action decides what to invalidate.

```ts
"use server";
import { revalidatePath, revalidateTag } from "next/cache";

export async function createInvoice(/* ... */) {
  // ...persist...
  revalidatePath("/invoicing"); // invalidate a route
  revalidateTag("invoices");    // invalidate by cache tag
  return { ok: true, invoice };
}
```

The Server Component re-fetches its data on the next render, the user sees fresh data without manual refresh.

### Action rules

- **Always return a serializable result.** Discriminated union with `ok: true | false`.
- **Never throw across the client boundary.** Throws inside an action become red error boundaries.
- **Validate with Zod at the top.** Boundaries are dumb until proven safe.
- **Take a `deps` parameter** with `liveDeps` default (see `web-architecture.md`).

## Suspense and Streaming

Suspense is how React waits for async work without blocking. It pairs with Server Components for streaming.

### Strategic boundary placement

A Suspense boundary defines what content streams independently. Put boundaries around async work that can be slow, but not so granular that the page looks like it's loading in a million places.

```tsx
// app/dashboard/page.tsx
import { Suspense } from "react";

export default function DashboardPage() {
  return (
    <main>
      <DashboardHeader /> {/* sync, renders immediately */}
      <Suspense fallback={<RecentInvoicesSkeleton />}>
        <RecentInvoices /> {/* slow query, streams when ready */}
      </Suspense>
      <Suspense fallback={<MetricsSkeleton />}>
        <Metrics /> {/* parallel-streaming */}
      </Suspense>
    </main>
  );
}
```

The two `<Suspense>` boundaries fetch in parallel and stream as each completes.

### Rules for Suspense

- **One boundary per logically-independent async unit.** Header doesn't need to wait for invoices; invoices don't need to wait for metrics.
- **Match each boundary with a designed skeleton, never a spinner.** Skeletons preserve layout (no CLS), spinners over a blank area look broken.
- **Don't wrap everything in `<Suspense>`.** A boundary at the top of a page replicates the old "block on everything" behavior with extra steps.
- **`loading.tsx` at the route level** is a Suspense boundary for the entire route — sufficient for simple pages.

### Error pairing

Suspense handles loading; error boundaries handle failures. Pair them.

```tsx
import { ErrorBoundary } from "react-error-boundary";

<ErrorBoundary fallback={<RecentInvoicesError />}>
  <Suspense fallback={<RecentInvoicesSkeleton />}>
    <RecentInvoices />
  </Suspense>
</ErrorBoundary>
```

In Next.js, `error.tsx` at the route level handles route-scoped errors. For finer granularity, wrap manually.

## `useTransition` for Non-Blocking Updates

`useTransition` lets the UI stay responsive while a state update happens. The transition is interruptible — if the user triggers another, React drops the previous.

```tsx
"use client";

import { useTransition } from "react";
import { markInvoicePaid } from "../actions";

export function MarkPaidButton({ invoiceId }: { invoiceId: InvoiceId }) {
  const [pending, startTransition] = useTransition();
  return (
    <button
      disabled={pending}
      onClick={() => startTransition(() => markInvoicePaid(invoiceId))}
    >
      {pending ? "Marking…" : "Mark paid"}
    </button>
  );
}
```

When to reach for it:
- Wrapping a Server Action invocation that triggers revalidation.
- Tab switches, filter changes, search inputs that re-render expensive lists.
- Any state update that should not block typing or clicking.

## `useOptimistic` for Optimistic UI

`useOptimistic` lets you show a predicted result while the server confirms. If the action fails, React reverts.

```tsx
"use client";

import { useOptimistic } from "react";
import { addLineItem, type Invoice, type LineItem } from "../actions";

export function LineItemsList({ invoice }: { invoice: Invoice }) {
  const [optimisticItems, addOptimistic] = useOptimistic(
    invoice.lineItems,
    (current, newItem: LineItem) => [...current, newItem],
  );

  async function onAdd(formData: FormData) {
    const item = parseLineItem(formData);
    addOptimistic(item);          // instant UI update
    await addLineItem(invoice.id, formData); // server confirms
  }

  return (
    <>
      <ul>{optimisticItems.map((item) => <li key={item.id}>{item.description}</li>)}</ul>
      <form action={onAdd}><LineItemInputs /></form>
    </>
  );
}
```

Use it when:
- The action's success outcome is predictable (add to list, toggle state, update text).
- Users expect immediate feedback (chat, comments, voting, drag-drop reordering).

Don't use it when:
- The result depends on server-computed values (timestamps, IDs you can't predict).
- Failure has consequences the user must see immediately (payment, deletion).

## The `use` Hook

`use` reads a Promise or Context inside render. New in React 19, it unlocks patterns previously impossible.

### Reading a Context inside a conditional

```tsx
function LineItem({ item }: { item: LineItem }) {
  if (!item) return null;
  const theme = use(ThemeContext); // legal — only `use` permits conditional context reads
  // ...
}
```

### Reading a Promise from a Server Component to a Client Component

A Server Component can pass a Promise as a prop. A Client Component reads it with `use`, suspending until resolved.

```tsx
// app/dashboard/page.tsx (Server Component)
import { fetchUser } from "@/features/users/queries";
import { UserGreeting } from "./user-greeting";

export default function DashboardPage() {
  const userPromise = fetchUser();
  return (
    <Suspense fallback={<Skeleton />}>
      <UserGreeting userPromise={userPromise} />
    </Suspense>
  );
}

// user-greeting.tsx (Client Component)
"use client";
import { use } from "react";
import type { User } from "@/features/users/domain";

export function UserGreeting({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise);
  return <h1>Hello, {user.name}</h1>;
}
```

This pattern lets the Server Component start fetching while the Client Component handles interactivity — without prop-drilling resolved data through layers.

## Refs as Props (React 19+)

`forwardRef` is gone. Function components accept `ref` as a regular prop.

```tsx
// Old (React 18)
const Input = forwardRef<HTMLInputElement, Props>((props, ref) => (
  <input ref={ref} {...props} />
));

// New (React 19+)
export function Input({ ref, ...props }: Props & { ref?: React.Ref<HTMLInputElement> }) {
  return <input ref={ref} {...props} />;
}
```

Cleaner, less ceremony, fully typed. Don't write new components with `forwardRef`.

## Custom Hooks

A custom hook is a function that calls other hooks. Treat them as small, single-purpose utilities — not catch-all "do everything for this feature" containers.

### Rules

- **Name with `use` prefix**, camelCase. The prefix is enforceable by the rules-of-hooks linter.
- **One concern per hook.** `useInvoiceList` (data + filters + selection) is three hooks pretending to be one. Split.
- **Don't wrap pure functions in hooks.** `useFormatCurrency()` that just calls `Intl.NumberFormat` is overhead — make it a plain function.
- **Don't create hooks for one-line `useState` wrappers.** `useToggle()` that returns `[value, () => set(!value)]` adds a layer for nothing.
- **Return tuples for `[value, action]` pairs**, objects for richer APIs.

```tsx
// Good — focused, one concern
function useInvoiceFilter(initial: InvoiceFilter) {
  const [filter, setFilter] = useState(initial);
  const reset = useCallback(() => setFilter(initial), [initial]);
  return { filter, setFilter, reset };
}
```

### Rules of Hooks

The rules are non-negotiable: hooks at the top level of a component or another hook, no conditionals, no loops, no early returns before all hooks have been called. The lint rule (`react-hooks/rules-of-hooks`) catches violations — never disable it.

## Composition Patterns

### Slot props (`children` and named slots)

Composition over configuration. A `<Card>` accepts `children` instead of `title`/`description`/`footer` props for everything.

```tsx
// Configurable (worse — every variation requires a new prop)
<Card title="..." description="..." footer={<Button />} actions={<Menu />} />

// Composable (better — caller arranges what fits)
<Card>
  <CardHeader>
    <CardTitle>...</CardTitle>
    <CardActions><Menu /></CardActions>
  </CardHeader>
  <CardBody>...</CardBody>
  <CardFooter><Button /></CardFooter>
</Card>
```

### Render props for behavior, not data

When a parent has logic but the child controls rendering, pass a function. Rare in modern React (hooks usually fit better), but valid for component-as-callback patterns.

### Polymorphic `as` prop sparingly

`<Box as="section">` is occasionally useful but degrades type inference. Reach for it only when a single component genuinely needs to render different elements; otherwise prefer separate components.

## React Compiler (React 19+)

The React Compiler auto-memoizes components and values that don't change between renders. When enabled (`@react-forget` plugin), most manual `useMemo` / `useCallback` becomes redundant.

- **With React Compiler enabled:** trust it. Don't reach for `useMemo`/`useCallback` reflexively. Profile first; only memoize manually if the compiler couldn't infer (rare).
- **Without React Compiler:** `useMemo` / `useCallback` only where measurably expensive. Manual memoization for non-expensive code adds complexity for no measurable benefit.

Default for new projects: enable the compiler.

## Anti-Patterns

1. **`useEffect` for derived state.** Compute during render.
2. **`useEffect` for events.** Move logic to the event handler that triggered the state change.
3. **`useEffect` for data fetching in client components.** Use Server Components or TanStack Query.
4. **Empty dependency array `[]` on a non-empty effect.** The lint rule disagrees for a reason — fix the dependencies.
5. **`forwardRef` in new code.** Refs are props in React 19+.
6. **`useState` for server data.** TanStack Query owns the cache; `useState` is for client-only state.
7. **Reflexive `useMemo` / `useCallback`.** Without measurement, these add overhead. With React Compiler, they're nearly always redundant.
8. **Page-level `"use client"` directive.** Forces every child to client-render. Push the directive to the smallest interactive island.
9. **Throwing errors from event handlers expecting them to be caught.** React doesn't catch thrown errors in event handlers — wrap with `try/catch` or use a result type.
10. **Hooks called conditionally.** Hooks must be called in the same order every render. The linter catches this; never disable.
11. **Deep prop drilling for theme/auth/locale.** Use Context (or a Zustand selector) for true cross-cutting state, not for things that should be feature-local.
12. **Custom hooks that wrap a single `useState`.** `useToggle`, `useCounter`, `useBoolean` — overhead with no payoff. Inline the `useState`.

## Principles

1. **Server is the default rendering target.** A Client Component must justify its directive. Bundle size, time-to-interactive, and SEO are all downstream of this discipline.

2. **Effects are for external systems, not for derivation.** If you can compute it during render or in an event handler, do that. `useEffect` is a fallback, not a default.

3. **Server Actions replace API routes for mutations.** Actions get progressive enhancement, type-safe arguments and returns, and integration with `useActionState` / `useFormStatus`. API routes are for true REST surfaces (webhooks, third-party SDK callbacks).

4. **Suspense boundaries are designed, not sprinkled.** Each boundary represents a logically-independent async unit and pairs with a designed skeleton. The shape of streaming is the shape of perceived performance.

5. **Optimistic UI for predictable success, sober UI for consequential actions.** `useOptimistic` for chat messages, list adds, toggles. Spinner or full server confirmation for payments, deletions, anything irreversible.

6. **Composition over configuration.** Components accept `children` and named slots; they don't grow a thirty-prop interface. The component's API is the shape of what fits inside it.

7. **Trust the compiler.** With React Compiler enabled, don't memoize reflexively. Without it, memoize only what profiling shows is expensive. Premature memoization is technical debt with no payoff.
