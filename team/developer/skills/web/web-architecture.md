# Web Architecture (Next.js App Router)

## Purpose
Define the layered architecture for modern Next.js features: server/client boundary discipline, folder structure, domain isolation, dependency injection, testability seams, and anti-patterns. See `team/developer/skills/web-best-practices.md` for the underlying philosophy. See `team/developer/skills/web-modern-react.md` for RSC and Server Action API patterns. See `team/developer/skills/web-state-management.md` for client and server state discipline. See `team/developer/skills/web-testing.md` for how to exercise the seams established here. Target: **Next.js 15+, React 19+, TypeScript 5.5+, Node.js 20+**.

## Core Layers

| Layer | Responsibility | Dependencies |
|-------|---------------|-------------|
| Presentation | Render state, forward intents — Server Components and Client Components | Application + Domain (read-only data shapes) |
| Application | Orchestrate use cases, validate inputs, coordinate side effects — Server Actions, Route Handlers, server-side queries | Domain + Infrastructure (via interfaces) |
| Domain | Pure business logic, entities, invariants — no React, no HTTP, no DB | Nothing external (pure-function libs only: zod, date-fns) |
| Infrastructure | Side-effect boundaries — DB, third-party APIs, time, file I/O, randomness | Domain (implements interfaces declared there) |

Dependencies point **inward only**. Domain depends on nothing external. Infrastructure implements interfaces defined alongside domain. Application orchestrates both. Presentation consumes application outputs.

The compiler should reject any wrong-direction import. Enforce with `eslint-plugin-boundaries` (or `import/no-restricted-paths`) per layer. Architectural rot starts as a single quietly-tolerated leak.

Server Components live in the presentation layer but execute server-side. They may call application or domain code directly (same process). Client Components run in the browser and reach the application layer only via Server Actions or route handlers — never importing server-only modules.

## The Server/Client Boundary

The single most important architectural decision in modern Next.js: **default to the server**. A component is a Server Component unless it needs interactivity, browser APIs, or client-only state.

| Component type | Use when |
|----------------|----------|
| Server Component (default, no directive) | Reads data, renders content, no event handlers, no hooks beyond `use` |
| Client Component (`"use client"`) | Has event handlers (`onClick`, `onChange`), uses `useState`/`useReducer`/`useEffect`, accesses browser APIs (`window`, `localStorage`), wraps a third-party client library |

**Rule of thumb:** push `"use client"` as deep in the tree as it can go. A page is a Server Component containing one small interactive island, not a page-level Client Component containing a server-fetched data dump.

```tsx
// Wrong: page is client, every child has to be a client component
"use client";
export default function DashboardPage() {
  const data = useDataFromSomewhere();
  return <div>...</div>;
}

// Right: page is server, only the interactive piece is client
import { fetchDashboard } from "@/features/dashboard/queries";
import { DashboardActions } from "@/features/dashboard/components/dashboard-actions";

export default async function DashboardPage() {
  const data = await fetchDashboard();
  return (
    <div>
      <DashboardSummary data={data} />
      <DashboardActions data={data} /> {/* interactive island */}
    </div>
  );
}
```

Pass plain serializable data across the boundary — strings, numbers, plain objects, arrays, `Date` (React 19+). Not function references, class instances, `Map`/`Set`, or anything that carries a closure.

## Folder Structure

Group by **domain**, not by technical type. The folder structure should mirror the product structure, so adding a feature touches one folder and ripples nowhere else.

```
src/
  app/                              # Next.js App Router (presentation)
    (marketing)/                    # Route group: marketing pages, no auth
      page.tsx
      pricing/page.tsx
    (app)/                          # Route group: authenticated app
      layout.tsx                    # Auth guard, app chrome
      dashboard/page.tsx
      invoicing/[invoiceId]/page.tsx
    api/                            # Route handlers (when REST is required)
  features/                         # Domain-grouped feature code
    invoicing/
      components/                   # Feature-scoped components
        invoice-list.tsx            # Server Component
        invoice-form.tsx            # Client Component (`"use client"`)
      actions.ts                    # Server actions (application)
      queries.ts                    # Server-side reads (application)
      domain.ts                     # Pure business logic (domain)
      schema.ts                     # Zod schemas (domain validation)
    auth/
      ...same shape...
  lib/                              # Cross-feature primitives + infrastructure
    db.ts                           # DB interface
    db.postgres.ts                  # Live DB implementation
    auth.ts
    logger.ts
    time.ts                         # Time abstraction (so tests can fake now())
  components/
    ui/                             # Design-system primitives (Tailwind + shadcn-style)
      button.tsx
      input.tsx
  styles/
    globals.css
```

Hard rules:
- **No `components/` pile** at the top level. Cross-feature design-system primitives live in `components/ui/`. Feature-specific components live in `features/<feature>/components/`.
- **No `hooks/`, `utils/`, `helpers/` top-level buckets.** Hooks live next to the feature that needs them. Utility functions live in `lib/<concept>.ts` named for their purpose, never named "utility."
- **Route groups** (`(marketing)`, `(app)`) organize routing without affecting URLs. Use them to colocate layouts and middleware concerns by audience.
- **Kebab-case file names**, no `index.ts` re-exports. Direct imports keep the dependency graph honest and the diff readable.

## Domain Layer

Pure functions and data types. No React, no async I/O, no platform APIs. The domain layer is the only place business invariants live.

```ts
// features/invoicing/domain.ts
import { z } from "zod";

export const InvoiceStatus = z.enum(["draft", "sent", "paid", "overdue"]);
export type InvoiceStatus = z.infer<typeof InvoiceStatus>;

// Branded types make IDs un-mixable at the type level
export type InvoiceId = string & { readonly __brand: "InvoiceId" };
export type CustomerId = string & { readonly __brand: "CustomerId" };

export interface LineItem {
  description: string;
  quantity: number;
  unitPriceCents: number;
}

export interface Invoice {
  id: InvoiceId;
  customerId: CustomerId;
  lineItems: ReadonlyArray<LineItem>;
  status: InvoiceStatus;
  dueAt: Date;
}

export const CreateInvoiceSchema = z.object({
  customerId: z.string().min(1),
  lineItems: z.array(z.object({
    description: z.string().min(1),
    quantity: z.number().int().positive(),
    unitPriceCents: z.number().int().nonnegative(),
  })).min(1),
  dueAt: z.coerce.date(),
});
export type CreateInvoiceInput = z.infer<typeof CreateInvoiceSchema>;

export function totalCents(invoice: Invoice): number {
  return invoice.lineItems.reduce((sum, item) => sum + item.quantity * item.unitPriceCents, 0);
}

export function isOverdue(invoice: Invoice, now: Date): boolean {
  if (invoice.status === "paid") return false;
  return invoice.dueAt.getTime() < now.getTime();
}
```

Rules:
- **Pure functions only.** Same inputs → same output. No `Date.now()` inside — pass `now` in. No `fetch` — return data, don't fetch it.
- **Zod schemas live here.** They are the gatekeepers for any data crossing into the domain.
- **Branded types for IDs.** Prevents passing a `CustomerId` where an `InvoiceId` is expected. Apply per concept that has identity.
- **Discriminated unions over `null`-with-error-string.** Use `Result<T, E>` shapes for things callers need to handle. Throw only for programmer errors.

## Infrastructure Layer

Side effects live here, behind interfaces.

```ts
// lib/db.ts — interface
import type { Invoice, InvoiceId, CustomerId } from "@/features/invoicing/domain";

export interface InvoiceRepository {
  findById(id: InvoiceId): Promise<Invoice | null>;
  list(customerId: CustomerId): Promise<ReadonlyArray<Invoice>>;
  save(invoice: Invoice): Promise<void>;
}

// lib/db.postgres.ts — live implementation
import { sql } from "@vercel/postgres";
import type { InvoiceRepository } from "./db";

export const liveInvoiceRepository: InvoiceRepository = {
  async findById(id) { /* ... */ },
  async list(customerId) { /* ... */ },
  async save(invoice) { /* ... */ },
};

// lib/time.ts
export function now(): Date {
  return new Date();
}
```

Rules:
- **Interfaces live in or near domain. Implementations live in `lib/`.** A domain function should be able to declare what it needs without importing the implementation.
- **One interface per concept**, not one giant `Database` god object.
- **Time, randomness, network are infrastructure too.** `lib/time.ts` exports `now()` so tests can fake it. Application code never calls `Date.now()` or `new Date()` directly.
- **No business logic in repositories.** Repositories translate between domain types and storage rows. They never decide whether something is overdue, valid, or allowed.

## Application Layer

Server Actions and Route Handlers orchestrate use cases: validate input, call domain logic, persist via infrastructure, return shaped data. Dependencies are passed explicitly via a `deps` parameter — never reached for via module-level imports inside the function body.

```ts
// lib/deps.ts — single registry of live infrastructure
import { liveInvoiceRepository } from "./db.postgres";
import { now } from "./time";
import type { InvoiceRepository } from "./db";

export interface Deps {
  invoiceRepository: InvoiceRepository;
  now: () => Date;
  // Add new infrastructure here as features need it.
}

export const liveDeps: Deps = {
  invoiceRepository: liveInvoiceRepository,
  now,
};
```

```ts
// features/invoicing/actions.ts
"use server";

import { revalidatePath } from "next/cache";
import { liveDeps, type Deps } from "@/lib/deps";
import { CreateInvoiceSchema, makeInvoice, type Invoice } from "./domain";
import { zodErrorToFieldMap } from "@/lib/format";

type CreateInvoiceResult =
  | { ok: true; invoice: Invoice }
  | { ok: false; errors: Record<string, string> };

export async function createInvoice(
  formData: FormData,
  deps: Pick<Deps, "invoiceRepository" | "now"> = liveDeps,
): Promise<CreateInvoiceResult> {
  const parsed = CreateInvoiceSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) {
    return { ok: false, errors: zodErrorToFieldMap(parsed.error) };
  }

  const invoice = makeInvoice(parsed.data, { now: deps.now() });
  await deps.invoiceRepository.save(invoice);
  revalidatePath("/invoicing");
  return { ok: true, invoice };
}
```

Rules:
- **Take primitive input, return serializable output.** `FormData` or plain objects in; discriminated-union results out (`{ ok: true, ... } | { ok: false, ... }`). No thrown errors crossing the client boundary.
- **Validate at the boundary.** Zod parses input before any domain logic runs. Once data passes the schema, the rest of the function trusts the types.
- **No business logic in actions.** Actions orchestrate domain calls; domain decides.
- **One action per use case.** A 200-line action is a missing layer. Extract orchestration steps to domain functions or split into multiple actions.
- **Explicit `deps` parameter, defaulting to `liveDeps`.** Each action declares the subset of `Deps` it actually uses via `Pick<Deps, ...>`. Client code calls `createInvoice(formData)` and the default kicks in. Tests call `createInvoice(formData, testDeps)` and substitute. No `vi.mock`, no module-system gymnastics — the dependency seam lives in the function signature.

Route handlers (`app/api/<path>/route.ts`) follow the same pattern when REST is required — webhooks, third-party SDK callbacks, mobile clients sharing the API. Same `deps` parameter convention.

## Presentation Layer

```tsx
// features/invoicing/queries.ts
import { liveInvoiceRepository } from "@/lib/db.postgres";
import type { CustomerId, Invoice } from "./domain";

export async function listInvoices(customerId: CustomerId): Promise<ReadonlyArray<Invoice>> {
  return liveInvoiceRepository.list(customerId);
}

// features/invoicing/components/invoice-list.tsx (Server Component)
import { listInvoices } from "../queries";
import { totalCents, type CustomerId } from "../domain";
import { formatCents } from "@/lib/format";
import { InvoiceRowActions } from "./invoice-row-actions";

export async function InvoiceList({ customerId }: { customerId: CustomerId }) {
  const invoices = await listInvoices(customerId);
  return (
    <ul>
      {invoices.map((invoice) => (
        <li key={invoice.id}>
          <span>{invoice.id}</span>
          <span>{formatCents(totalCents(invoice))}</span>
          <InvoiceRowActions invoiceId={invoice.id} /> {/* interactive island */}
        </li>
      ))}
    </ul>
  );
}

// features/invoicing/components/invoice-row-actions.tsx (Client Component)
"use client";

import { useTransition } from "react";
import { markInvoicePaid } from "../actions";
import type { InvoiceId } from "../domain";

export function InvoiceRowActions({ invoiceId }: { invoiceId: InvoiceId }) {
  const [pending, startTransition] = useTransition();
  return (
    <button
      disabled={pending}
      onClick={() => startTransition(() => markInvoicePaid(invoiceId))}
    >
      Mark paid
    </button>
  );
}
```

Rules:
- **Server Components await their own data.** No `useEffect` to fetch on mount, no `useQuery` in a Server Component.
- **Client Components are interactivity islands.** Smallest possible scope. They consume props from server-rendered parents.
- **No business logic in components.** Components decide what to render, never whether something is allowed/valid/overdue. Compute via domain functions.
- **Pass primitive data across the boundary.** Strings, numbers, plain objects, arrays, `Date` (React 19+). Not functions, not class instances.

## Dependency Rules (the dependency graph)

```
                ┌─────────────────┐
                │  Presentation   │
                │   app/, features│
                │    /components  │
                └───────┬─────────┘
                        │
                        ▼
                ┌─────────────────┐
                │   Application   │
                │  actions.ts,    │
                │  queries.ts,    │
                │  route.ts       │
                └────┬─────────┬──┘
                     │         │
                     ▼         ▼
            ┌────────────┐  ┌──────────────────┐
            │   Domain   │  │  Infrastructure  │
            │ domain.ts, │  │   lib/db.ts,     │
            │ schema.ts  │◀─│  lib/time.ts     │
            └────────────┘  └──────────────────┘
```

- `app/` may import `features/<x>/` (any layer) and `components/ui/`.
- `features/<x>/components/` may import same feature's `actions.ts`, `queries.ts`, `domain.ts`, `schema.ts`, plus `components/ui/` and `lib/`.
- `features/<x>/actions.ts`, `queries.ts` may import same feature's `domain.ts`, `schema.ts`, plus `lib/` infrastructure.
- `features/<x>/domain.ts` may import only `lib/` interfaces (not implementations) and external pure-function libs (zod, date-fns). No React. No `lib/db.postgres.ts`.
- **No cross-feature imports.** `features/billing/` never imports from `features/invoicing/`. If two features share something, lift it to `lib/` or a top-level `domain/` module.

## Testability Built In

Every external dependency is reachable through an interface, so tests substitute fakes without mocking the universe.

```ts
// features/invoicing/domain.test.ts
import { describe, it, expect } from "vitest";
import { isOverdue, makeInvoice } from "./domain";

describe("isOverdue", () => {
  it("returns false for paid invoices regardless of due date", () => {
    const invoice = makeInvoice({ status: "paid", dueAt: new Date("2020-01-01"), /* ... */ });
    expect(isOverdue(invoice, new Date("2030-01-01"))).toBe(false);
  });

  it("returns true for non-paid invoice past due", () => {
    const invoice = makeInvoice({ status: "sent", dueAt: new Date("2020-01-01"), /* ... */ });
    expect(isOverdue(invoice, new Date("2025-01-01"))).toBe(true);
  });
});
```

Domain tests need no setup — no DB, no React, no fetch. Just pure inputs and outputs.

```ts
// features/invoicing/actions.test.ts
import { describe, it, expect, vi } from "vitest";
import { createInvoice } from "./actions";
import type { Deps } from "@/lib/deps";

function makeTestDeps(overrides?: Partial<Pick<Deps, "invoiceRepository" | "now">>) {
  const save = vi.fn().mockResolvedValue(undefined);
  return {
    save,
    deps: {
      invoiceRepository: { save, findById: vi.fn(), list: vi.fn() },
      now: () => new Date("2026-01-01T00:00:00Z"),
      ...overrides,
    },
  };
}

describe("createInvoice", () => {
  it("returns errors for invalid input without saving", async () => {
    const { deps, save } = makeTestDeps();
    const formData = new FormData();
    formData.set("customerId", ""); // invalid
    const result = await createInvoice(formData, deps);
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.errors.customerId).toBeDefined();
    expect(save).not.toHaveBeenCalled();
  });
});
```

Action tests pass a test `deps` directly. No module mocking, no global state — the dependency seam is the function signature, so tests stay readable and refactors don't break them.

See `team/developer/skills/web-testing.md` for the full testing strategy and Playwright integration patterns.

## Where Does X Go?

When adding new code, walk this decision tree:

1. **Pure function with no I/O?** → `features/<x>/domain.ts`, or `lib/<concept>.ts` if cross-feature.
2. **Touches network, DB, file system, current time, or randomness?** → Define interface near domain. Live implementation in `lib/<concept>.<impl>.ts`.
3. **Orchestrates domain + infrastructure on the server?** → `features/<x>/actions.ts` (mutations) or `features/<x>/queries.ts` (reads).
4. **Renders UI with no business decisions?** → `features/<x>/components/`. Server Component if no event handlers; Client Component (`"use client"`) if interactive.
5. **Design-system primitive used by many features?** → `components/ui/`.
6. **A route?** → `app/<route>/page.tsx`. Server Component by default.

If something doesn't fit cleanly, the layer is missing — don't shoehorn it. Common smell: a "service" doing both orchestration and side effects. Split into application (orchestration) + infrastructure (side effects).

## Anti-Patterns

1. **Business logic inside React components.** A component computing tax, validating dates, deciding permissions. Fix: extract to domain.
2. **Direct DB access from Server Components.** A Server Component calling `db.query(...)` directly. Fix: route through application layer (`queries.ts`).
3. **God Server Action.** One action validating, orchestrating, calling three repositories, sending email, formatting response. Fix: extract orchestration steps to domain functions; keep action thin.
4. **Cross-feature imports.** `features/billing/components/foo.tsx` importing from `features/invoicing/domain.ts`. Fix: lift the shared concept to `lib/` or a top-level `domain/` module.
5. **`"use client"` at the page level.** Forces every child to be a Client Component, defeats RSC. Fix: push `"use client"` to the smallest possible interactive island.
6. **Effects for derived state.** `useEffect(() => setTotal(items.reduce(...)), [items])`. Fix: derive during render — `const total = items.reduce(...)`.
7. **Mixing server cache and client state.** Putting fetched data into Zustand or Redux. Fix: TanStack Query owns server state; Zustand owns client-only state. See `web-state-management.md`.
8. **`any` or `as` to escape the type system.** A type assertion is a TODO. Fix: validate at the boundary with Zod, then types are honest the rest of the way.
9. **Hooks for things that aren't stateful.** `useFormatCurrency()` that just calls `Intl.NumberFormat`. Fix: pure function in `lib/format.ts`.
10. **Throwing across the server/client boundary.** Server Actions throwing errors that reach client components. Fix: return discriminated-union results — `{ ok: true } | { ok: false, errors }`.
11. **Top-level `index.ts` re-exports.** `features/invoicing/index.ts` re-exporting half the feature. Fix: import directly from the file that defines what you need; the dependency graph stays honest.
12. **Default exports for components, actions, queries, or domain functions.** Default exports break rename refactors, obscure what's exported, and hurt IDE auto-import. Fix: named exports only. Exception: Next.js framework conventions that *require* default exports — `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`, `not-found.tsx`, `route.ts` handlers, `middleware.ts`. Everywhere else, named.

## When to Scale Up Structure

The `deps`-parameter-with-`liveDeps`-default pattern scales smoothly. The only thing that grows is `lib/deps.ts`.

| Stage | What changes |
|-------|--------------|
| 1-3 features, 1-2 repositories | `lib/deps.ts` has 2-4 entries. Each action declares `Pick<Deps, "x" \| "y">` for the subset it needs. |
| 5+ features, shared services (auth, email, notifications) | `lib/deps.ts` grows to 8-12 entries. Consider splitting by concern: `lib/deps.persistence.ts`, `lib/deps.messaging.ts` re-exported from `lib/deps.ts`. |
| 10+ features, multi-tenant or multi-deployment, request-scoped values | Per-request scoping. Wrap deps in `cache()` (Next.js request-memoized) or `AsyncLocalStorage` so each request gets its own tenant-scoped DB connection, current user, feature flags. The `deps` parameter convention stays the same; what's behind `liveDeps` becomes a per-request factory. |

Premature scaffolding is a smell. The `deps` convention is the dial — start with one `liveDeps` constant, scale to per-request scoping only when multi-tenancy or deployment-target switching demands it. Refactoring from a flat constant to a request-scoped factory is mechanical, not architectural.

## Principles

1. **Default to the server.** Server Components are the new default. `"use client"` is opt-in for interactivity. Pushing client boundaries deep into the tree shrinks bundle size, simplifies data flow, and makes apps feel native.

2. **Layers depend inward.** Presentation → Application → Domain. Infrastructure implements domain interfaces. The compiler should reject any wrong-direction import. This is non-negotiable — every architectural rot starts with a "small" leak the wrong way.

3. **Domain is the one true source of truth for business rules.** No business decisions in components, repositories, actions, or routes. Components render. Repositories store. Actions orchestrate. Domain decides.

4. **Validate at the edge, trust the inside.** Zod parses every external input — form submissions, API request bodies, DB row shapes when typing is loose. Once data crosses into domain, types are honest and code can trust them.

5. **Testability is a property of architecture, not a phase.** Every external dependency abstracted behind an interface, every effect (time, randomness, I/O) injectable through the `deps` parameter. Tests pass test deps directly — no `vi.mock`, no module gymnastics. If a function is hard to test, the architecture is broken — not the test.

6. **Folder structure mirrors product structure.** Adding a feature creates one folder. Removing a feature deletes one folder. The graph is shallow and obvious — a new contributor can navigate it on day one.

7. **Composition over configuration.** Small composable units beat one configurable monolith. Especially in components — props should be a minimal interface, composition is the API.
