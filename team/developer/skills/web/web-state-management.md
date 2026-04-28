# Web State Management

## Purpose
Define the discipline for state in a modern web app: which kind of state goes where, the libraries that own each, the patterns that work, the patterns that break codebases. See `team/developer/skills/web-architecture.md` for layer boundaries (server state crosses through Server Actions and queries). See `team/developer/skills/web-modern-react.md` for `useState`/`useReducer`/`useEffect` rules. See `team/developer/skills/web-best-practices.md` for stack defaults. Target: **React 19+, Next.js 15+, TanStack Query 5+, Zustand 5+, react-hook-form 7+ with Zod resolver**.

## The Five Kinds of State

State management goes wrong when teams treat all state as one thing. There are five kinds, each with the right home.

| Kind | Examples | Home | Why |
|------|----------|------|-----|
| **Server state** | Fetched data (invoices, users, posts) | TanStack Query | Cache, revalidation, optimistic updates, retries done right |
| **Global client state** | Theme, sidebar collapsed, in-app toasts, draft data | Zustand | Minimal API, no provider trees, selector-based subscriptions |
| **Local component state** | Form fields, modal open/closed, hover/focus | `useState` / `useReducer` | Scope-limited, no global coupling |
| **URL state** | Search query, filter selections, current tab, pagination | `useSearchParams` + Server Components | Shareable, back-button-friendly, server-renderable |
| **Form state** | Field values, validation errors, dirty/touched, submission | `react-hook-form` + Zod resolver | Uncontrolled by default (perf), schema-driven validation |

The single largest anti-pattern in real codebases is putting one kind of state into the wrong home — server data into Zustand, URL state into local React state, form state into a custom reducer. Each home is opinionated for a reason.

## Decision Tree

When adding new state, walk this:

1. **Is the data fetched from the server?** → Server state (TanStack Query) for client-fetched, or Server Component data fetching for SSR.
2. **Should the URL reflect this state?** (Shareable link, back button, browser refresh.) → URL state (`useSearchParams`).
3. **Is the data only meaningful inside one component subtree?** → Local component state (`useState`/`useReducer`).
4. **Is it form input being collected for submission?** → Form state (`react-hook-form`).
5. **Is it global to the app — needed across unrelated trees?** → Global client state (Zustand).

If you can't put state cleanly in one of these, the question is usually wrong. Re-frame the data flow until it fits.

## Server State (TanStack Query)

TanStack Query owns everything fetched over the network from client code. Cache, revalidation, optimistic updates, retries, request deduplication — handled.

**Note:** Most data in a Next.js App Router app should be fetched in Server Components, not via TanStack Query. Reach for Query only when the data is genuinely client-fetched (after user interaction, real-time updates, infinite scroll, complex client-side caching needs).

### Query keys

Query keys are arrays. Structure them hierarchically and consistently — they become the cache index.

```ts
// features/invoicing/queries.ts (client-side)
import { queryOptions } from "@tanstack/react-query";
import { fetchInvoiceList, fetchInvoice } from "./api";
import type { CustomerId, InvoiceId } from "./domain";

export const invoiceQueries = {
  all: () => ["invoices"] as const,
  lists: () => [...invoiceQueries.all(), "list"] as const,
  list: (customerId: CustomerId) =>
    queryOptions({
      queryKey: [...invoiceQueries.lists(), { customerId }] as const,
      queryFn: () => fetchInvoiceList(customerId),
      staleTime: 30_000,
    }),
  details: () => [...invoiceQueries.all(), "detail"] as const,
  detail: (id: InvoiceId) =>
    queryOptions({
      queryKey: [...invoiceQueries.details(), id] as const,
      queryFn: () => fetchInvoice(id),
      staleTime: 60_000,
    }),
};
```

The factory pattern keeps query keys typed, lets you invalidate aggregates (`queryClient.invalidateQueries({ queryKey: invoiceQueries.lists() })`), and makes the cache structure obvious.

### Using queries

```tsx
"use client";
import { useQuery } from "@tanstack/react-query";
import { invoiceQueries } from "../queries";

export function InvoiceListClient({ customerId }: { customerId: CustomerId }) {
  const { data, isPending, error } = useQuery(invoiceQueries.list(customerId));

  if (isPending) return <Skeleton />;
  if (error) return <ErrorState error={error} />;
  return <InvoiceList invoices={data} />;
}
```

### Mutations and optimistic updates

```tsx
"use client";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { markInvoicePaid } from "../actions";
import { invoiceQueries } from "../queries";

export function useMarkPaid(invoiceId: InvoiceId) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () => markInvoicePaid(invoiceId),
    onMutate: async () => {
      await qc.cancelQueries({ queryKey: invoiceQueries.detail(invoiceId).queryKey });
      const previous = qc.getQueryData(invoiceQueries.detail(invoiceId).queryKey);
      qc.setQueryData(invoiceQueries.detail(invoiceId).queryKey, (old) =>
        old ? { ...old, status: "paid" } : old,
      );
      return { previous };
    },
    onError: (_err, _vars, context) => {
      if (context?.previous) {
        qc.setQueryData(invoiceQueries.detail(invoiceId).queryKey, context.previous);
      }
    },
    onSettled: () => {
      qc.invalidateQueries({ queryKey: invoiceQueries.all() });
    },
  });
}
```

The pattern: cancel in-flight, snapshot, optimistically update, rollback on error, invalidate on settle.

### Configuration defaults

```tsx
// app/providers.tsx
"use client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,        // 30s — most data isn't fresh-needed
      gcTime: 5 * 60_000,       // 5 min — release inactive caches
      retry: 1,                 // one retry, then surface error
      refetchOnWindowFocus: false, // off by default; enable per-query if needed
    },
    mutations: { retry: 0 },    // mutations never auto-retry
  },
});
```

Pick defaults that match your app's data freshness; default-everything-on (the library's defaults) creates surprising network behavior in development.

### Rules

- **Server state lives in TanStack Query, never in Zustand.** This is the single most common mis-categorization.
- **Use the query options factory pattern.** Type-safe keys, easy hierarchical invalidation.
- **`staleTime` per query type, not globally.** Some data is fresh for seconds, some for minutes.
- **Optimistic updates need rollback in `onError`.** Half-applied optimism corrupts UX.
- **Invalidate after Server Actions too.** When a Server Action mutates, the action calls `revalidatePath`/`revalidateTag` for SSR data; the client also calls `qc.invalidateQueries` for any TanStack Query caches that overlap.

## Global Client State (Zustand)

Zustand owns global client-only state — values that need to be readable from unrelated component subtrees, but are not server data.

### Slice pattern

For anything beyond a tiny store, split into slices and compose.

```ts
// lib/stores/ui.ts
import { create } from "zustand";
import { persist } from "zustand/middleware";

interface UISlice {
  sidebarOpen: boolean;
  toggleSidebar: () => void;
  theme: "light" | "dark" | "system";
  setTheme: (theme: "light" | "dark" | "system") => void;
}

export const useUI = create<UISlice>()(
  persist(
    (set) => ({
      sidebarOpen: true,
      toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
      theme: "system",
      setTheme: (theme) => set({ theme }),
    }),
    { name: "ui-state" },
  ),
);
```

### Selector-based reads

Always read with a selector. Reading the whole store re-renders on every change.

```tsx
// Wrong — re-renders on any store update
const ui = useUI();
return <div>{ui.theme}</div>;

// Right — re-renders only when theme changes
const theme = useUI((s) => s.theme);
return <div>{theme}</div>;
```

### Multiple stores by domain

Don't put everything in one giant store. Split by concern: `useUI`, `useDraftInvoice`, `useNotifications`. Each store is focused and has a clear purpose.

### Persist middleware

`zustand/middleware`'s `persist` writes to `localStorage` (or `sessionStorage`). Use it for state that should survive reload — theme preference, sidebar collapse state, in-progress drafts. Don't persist server data (TanStack Query handles that better) or sensitive data.

### Rules

- **Zustand for global client state, never for server data.** TanStack Query handles server cache.
- **Read with selectors.** `useStore((s) => s.x)` instead of `const { x } = useStore()`.
- **Split stores by domain.** Multiple small stores beat one monolith.
- **Keep actions next to state.** Each store exposes its actions; components don't reach into store internals.
- **No async fetching inside Zustand stores.** Server state is TanStack Query's job; Zustand is synchronous local state.

## Local Component State (`useState` / `useReducer`)

The default for state that doesn't need to escape one component subtree.

### `useState` for simple state

```tsx
const [open, setOpen] = useState(false);
const [searchQuery, setSearchQuery] = useState("");
```

### `useReducer` for related state

When 3+ pieces of state change together (multi-step form, complex toggle states), `useReducer` keeps transitions explicit.

```tsx
type FilterState = {
  status: InvoiceStatus[];
  dateRange: { from: Date; to: Date } | null;
  searchQuery: string;
};
type FilterAction =
  | { type: "set-status"; status: InvoiceStatus[] }
  | { type: "set-date-range"; range: { from: Date; to: Date } | null }
  | { type: "set-search"; query: string }
  | { type: "reset" };

function filterReducer(state: FilterState, action: FilterAction): FilterState {
  switch (action.type) {
    case "set-status":     return { ...state, status: action.status };
    case "set-date-range": return { ...state, dateRange: action.range };
    case "set-search":     return { ...state, searchQuery: action.query };
    case "reset":          return initialFilter;
    default:               return assertNever(action);
  }
}

const [filter, dispatch] = useReducer(filterReducer, initialFilter);
```

### Rules

- **`useState` is the default.** Don't reach for `useReducer` until 3+ related state pieces actually exist.
- **State that's needed in one place stays in that place.** If a parent doesn't need to know, don't lift it.
- **Initialize with a function for expensive initial state**: `useState(() => buildInitialState(props))`.
- **Don't sync local state to props via `useEffect`.** Pass a `key` to remount the component instead.

## URL State

URL state lives in the URL. Search query, filters, current tab, page number, sort order — anything a user might want to share via link or restore via refresh.

### Reading URL state

In Server Components, `searchParams` is a Promise (Next.js 15+):

```tsx
// app/invoicing/page.tsx
type Props = { searchParams: Promise<{ status?: string; q?: string }> };

export default async function InvoicingPage({ searchParams }: Props) {
  const { status, q } = await searchParams;
  const filter = FilterSchema.safeParse({ status, q });
  const invoices = await listInvoices(filter.success ? filter.data : {});
  return <InvoiceList invoices={invoices} />;
}
```

In Client Components, use `useSearchParams`:

```tsx
"use client";
import { useSearchParams, usePathname, useRouter } from "next/navigation";

export function StatusFilter() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();
  const status = searchParams.get("status") ?? "all";

  function setStatus(next: string) {
    const params = new URLSearchParams(searchParams);
    if (next === "all") params.delete("status");
    else params.set("status", next);
    router.push(`${pathname}?${params.toString()}`, { scroll: false });
  }

  return <Select value={status} onChange={setStatus} />;
}
```

### Rules

- **Validate searchParams with Zod** at the boundary, same as route params.
- **`router.push(..., { scroll: false })`** when a filter change shouldn't scroll to top.
- **Use `useTransition`** wrapping `router.push` for smooth filter changes — see `web-modern-react.md`.
- **Don't store sensitive data in URL.** Auth tokens, personal info, anything not safe in browser history.
- **One source of truth.** If the URL has the value, the URL is authoritative — don't also keep it in `useState` and try to sync.

## Form State (react-hook-form + Zod)

Forms have their own state lifecycle: field values, errors, touched/dirty, submission state. `react-hook-form` handles all of it without re-rendering the entire form on every keystroke.

### Pattern

```tsx
"use client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { CreateInvoiceSchema, type CreateInvoiceInput } from "../domain";
import { createInvoice } from "../actions";
import { useTransition } from "react";

export function InvoiceForm() {
  const [pending, startTransition] = useTransition();
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<CreateInvoiceInput>({
    resolver: zodResolver(CreateInvoiceSchema),
    defaultValues: { customerId: "", lineItems: [], dueAt: new Date() },
  });

  function onSubmit(data: CreateInvoiceInput) {
    const formData = toFormData(data);
    startTransition(() => createInvoice(formData));
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register("customerId")} aria-invalid={!!errors.customerId} />
      {errors.customerId && <p role="alert">{errors.customerId.message}</p>}
      <button disabled={pending}>{pending ? "Creating…" : "Create"}</button>
    </form>
  );
}
```

### Rules

- **Use `zodResolver` with the domain schema.** No duplicate validation rules between client and server.
- **Uncontrolled inputs by default.** `register()` keeps re-renders minimal. Reach for `Controller` only when a third-party input requires controlled state.
- **Surface errors with `aria-invalid` and `role="alert"`.** Accessibility isn't optional — see `web-accessibility.md`.
- **For server-form-action integration, prefer `useActionState`** (see `web-modern-react.md`). Use react-hook-form when you need richer client-side UX (multi-step, conditional fields, real-time validation), and fall back to `<form action={...}>` with progressive enhancement for simpler forms.

## Why Not Context for Most State

`React.Context` is a dependency-injection mechanism, not a state library. It re-renders every consumer on every value change, which is acceptable for theme/locale/auth (rare changes) and disastrous for high-frequency state.

Use Context for:
- Theme, locale, auth identity (changes rarely).
- Dependency injection for tree-scoped services.
- shadcn/ui internals (tooltip provider, dialog provider) — short trees, library-managed.

Don't use Context for:
- Anything updating multiple times per second.
- App-wide state with hundreds of consumers.
- State that needs selectors — Zustand's `useStore((s) => s.x)` is what Context lacks.

## Anti-Patterns

1. **Server data in Zustand.** Fetched data goes in TanStack Query (or Server Components). Putting it in Zustand loses caching, retries, deduplication, and invalidation guarantees.
2. **`useState` for global state.** A piece of state read by 5 unrelated components needs Zustand or the URL, not prop drilling or Context-with-`useState`.
3. **Context for high-frequency state.** Mouse position, scroll position, keystroke state. Every consumer re-renders on every change — use Zustand with selectors or local refs.
4. **`useEffect` to sync state.** Effect chains for state synchronization usually mean state lives in the wrong place. Lift, derive, or move to URL.
5. **Reading whole Zustand store.** `const store = useStore()` re-renders on every update. Always select.
6. **Manual fetching with `useEffect` in client components.** TanStack Query exists for this; manual fetching loses cache, retry, dedup.
7. **Stale form state from `useState` instead of react-hook-form.** Per-keystroke re-renders of a 30-field form is a perceptible perf hit.
8. **Mixing local state with server cache.** "I'll keep the optimistic update in `useState` and the real data in Query" — use `useOptimistic` (see `web-modern-react.md`) or Query's optimistic update pattern.
9. **Persisting sensitive or server data via `persist`.** localStorage is plaintext and shared across tabs. Don't persist auth tokens, server caches, or PII through Zustand persist.
10. **One giant Zustand store.** Split by domain. `useUI`, `useDraftInvoice`, `useNotifications` — each focused.
11. **Putting URL state in component state.** Filters, search query, tab — if it should survive a reload or be shareable, it goes in the URL.
12. **`useReducer` for two-piece state.** Boolean + number pair doesn't need a reducer. `useState` until 3+ related pieces actually exist.

## Principles

1. **Each kind of state has one home.** Server in TanStack Query (or Server Components), global client in Zustand, local in `useState`/`useReducer`, URL in `useSearchParams`, form in react-hook-form. Categorization wrong → bugs and re-render storms downstream.

2. **Server state is not client state.** Caching, retries, deduplication, revalidation are real concerns specific to data over the network. Solve them with a library that does it, not by reinventing in `useState` + `useEffect`.

3. **Read with selectors, write with actions.** Whether Zustand or `useReducer`, the pattern is the same — fine-grained subscription on read, transactional updates on write.

4. **The URL is state, treat it that way.** Filters, pagination, search query — if a user could expect to share or refresh and recover, it goes in the URL. Browser history and link sharing become free features.

5. **Forms have their own lifecycle.** `react-hook-form` exists because field-level state, validation, and submission are intricate. Don't reinvent; use the library.

6. **Context is dependency injection, not state.** Use it sparingly for tree-scoped services and rarely-changing values. Reach for Zustand when "I need this from anywhere" describes the situation.

7. **Default to local.** Most state is genuinely component-local. Lifting state up the tree is a real cost; only lift when a sibling or ancestor truly needs the value.
