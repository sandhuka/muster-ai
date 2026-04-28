# Web Testing

## Purpose
Define the testing strategy for modern Next.js + React 19 web apps: the test pyramid, Vitest patterns, React Testing Library principles, testing Server Components and Server Actions, Playwright E2E, mocking discipline, coverage targets. The architecture from `web-architecture.md` makes testing tractable; this skill is how to use the seams it provides. See `team/developer/skills/web-architecture.md` for the dependency-injection pattern that makes tests work without mocking the universe. See `team/developer/skills/web-best-practices.md` for the quality gates that enforce these tests in CI. See `team/developer/skills/web-modern-react.md` for the component patterns being tested. Target: **Vitest 2+, React Testing Library 16+, Playwright 1.45+, Testing Library/jest-dom**.

## Testing Philosophy

The framework's testing posture in one line: **test behavior, not implementation, at the layer where the behavior lives.**

What this means concretely:

- **Test domain logic with pure unit tests.** No mocks. No setup. Pure functions in, results out.
- **Test application logic (actions, queries) with deps-substitution tests.** Real validation, real orchestration, fake infrastructure.
- **Test components with RTL — query by what users see, assert on what users experience.** Don't test internal state, props, or render counts.
- **Test full flows with Playwright.** The shape that matters most for users is the shape we exercise least often, with the highest-fidelity tool.
- **Don't test the framework.** React, Next.js, TanStack Query, Zustand are tested by their maintainers. Test how your code uses them, not the libraries themselves.

The tests that catch the most bugs are domain tests (instant, deterministic, exhaustive) and Playwright tests (real browser, real flow). Component tests are the middle layer — necessary but expensive, kept focused on behavior the user cares about.

## The Test Pyramid

| Layer | Tool | Speed | Coverage target | What lives here |
|-------|------|-------|-----------------|-----------------|
| Domain (pure functions) | Vitest | <10ms each | 90%+ | Business invariants, calculations, state transitions, domain validation |
| Application (actions, queries) | Vitest with `deps` substitution | 10-50ms each | 80%+ for actions touched | Server Action behavior, validation, orchestration |
| Hooks | Vitest + RTL `renderHook` | 10-100ms each | 70%+ for non-trivial hooks | Custom hook contracts |
| Components | Vitest + React Testing Library | 50-500ms each | Touched code per PR; avoid coverage targets | User-visible behavior of complex components |
| E2E | Playwright | 1-10s each | Critical paths only (~10-30 specs total) | Sign-up, key conversion flows, payment, anything irreversible |

The pyramid shape: lots of fast unit tests at the bottom, fewer slow E2E tests at the top. **Reject the inverted pyramid** — codebases with hundreds of slow component tests and few unit tests are usually trying to test domain logic through the UI, which is where the architecture has rotted.

## Vitest Setup

```ts
// vitest.config.ts
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "node:path";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { "@": path.resolve(__dirname, "./src") },
  },
  test: {
    globals: true,
    environment: "jsdom",
    setupFiles: ["./test/setup.ts"],
    include: ["src/**/*.{test,spec}.{ts,tsx}"],
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"],
      exclude: ["**/*.test.*", "**/test/**", "**/.next/**", "**/node_modules/**"],
    },
  },
});
```

```ts
// test/setup.ts
import "@testing-library/jest-dom/vitest";
import { afterEach, vi } from "vitest";
import { cleanup } from "@testing-library/react";

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});
```

Test files live next to the code they test (`invoice-form.test.tsx` next to `invoice-form.tsx`), not in a separate `tests/` folder. The colocation makes "what's tested" obvious and refactors atomic.

## Domain Tests

The cleanest tier — pure inputs, pure outputs, no setup.

```ts
// features/invoicing/domain.test.ts
import { describe, it, expect } from "vitest";
import { isOverdue, totalCents, makeInvoice } from "./domain";

describe("totalCents", () => {
  it("sums quantity × unitPrice across line items", () => {
    const invoice = makeInvoice({
      lineItems: [
        { description: "A", quantity: 2, unitPriceCents: 500 },
        { description: "B", quantity: 1, unitPriceCents: 250 },
      ],
    });
    expect(totalCents(invoice)).toBe(1250);
  });

  it("returns zero for an invoice with no line items", () => {
    const invoice = makeInvoice({ lineItems: [] });
    expect(totalCents(invoice)).toBe(0);
  });
});

describe("isOverdue", () => {
  it("returns false for paid invoices regardless of due date", () => {
    const invoice = makeInvoice({ status: "paid", dueAt: new Date("2020-01-01") });
    expect(isOverdue(invoice, new Date("2030-01-01"))).toBe(false);
  });

  it("returns true for unpaid invoices past due", () => {
    const invoice = makeInvoice({ status: "sent", dueAt: new Date("2020-01-01") });
    expect(isOverdue(invoice, new Date("2025-01-01"))).toBe(true);
  });
});
```

Rules:
- **One `describe` per public function**, one `it` per behavior. Test names read like specifications.
- **Use a builder pattern** (`makeInvoice({ ... })`) for test data. See "Test Data Builders" below.
- **Test both happy and edge cases.** What happens at boundaries (empty array, zero, negative, far-future date)?
- **No mocks.** Domain code has no I/O — there's nothing to mock.

## Application Tests (Server Actions and Queries)

Real validation, real orchestration, fake infrastructure via the `deps` parameter.

```ts
// features/invoicing/actions.test.ts
import { describe, it, expect, vi } from "vitest";
import { createInvoice } from "./actions";
import type { Deps } from "@/lib/deps";

function makeTestDeps(overrides?: Partial<Pick<Deps, "invoiceRepository" | "now">>) {
  const save = vi.fn().mockResolvedValue(undefined);
  const findById = vi.fn();
  const list = vi.fn().mockResolvedValue([]);
  return {
    save,
    findById,
    list,
    deps: {
      invoiceRepository: { save, findById, list },
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

  it("saves and returns the new invoice on valid input", async () => {
    const { deps, save } = makeTestDeps();
    const formData = new FormData();
    formData.set("customerId", "cust_abc");
    formData.set("dueAt", "2026-02-01");

    const result = await createInvoice(formData, deps);

    expect(result.ok).toBe(true);
    expect(save).toHaveBeenCalledOnce();
  });
});
```

Rules:
- **No `vi.mock("@/lib/db.postgres", ...)`.** The deps parameter substitutes infrastructure cleanly without module gymnastics.
- **Validation runs for real.** A failed schema parse should return errors, not throw — and the test confirms it.
- **Return values, not side effects, are the primary assertion.** Then verify side effects (e.g., `save` was called) as secondary.
- **Test the discriminated-union shape.** Both `ok: true` and `ok: false` paths get coverage.

## React Testing Library Principles

RTL exists to push you toward testing what users see. The principles:

1. **Query by accessible role first**, by label second, by text third, by test ID last (only when nothing else fits).
2. **No `enzyme`-style `shallow`.** Render the actual component tree.
3. **Don't query by class names or DOM structure.** Both are implementation details.
4. **`userEvent` for interactions**, not `fireEvent`. `userEvent` simulates real browser sequences.
5. **`findBy*`** for things that appear async; **`getBy*`** for things that should already be present; **`queryBy*`** when asserting absence.

```tsx
// features/invoicing/components/invoice-form.test.tsx
import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { InvoiceForm } from "./invoice-form";

describe("InvoiceForm", () => {
  it("shows validation error when customer ID is empty", async () => {
    const user = userEvent.setup();
    render(<InvoiceForm action={vi.fn()} />);

    await user.click(screen.getByRole("button", { name: /create/i }));

    expect(await screen.findByRole("alert")).toHaveTextContent(/customer/i);
  });

  it("submits with valid data", async () => {
    const action = vi.fn();
    const user = userEvent.setup();
    render(<InvoiceForm action={action} />);

    await user.type(screen.getByLabelText(/customer/i), "cust_abc");
    await user.click(screen.getByRole("button", { name: /create/i }));

    expect(action).toHaveBeenCalledOnce();
  });
});
```

Forbidden in component tests:
- **Querying by `data-testid`** unless no accessible alternative exists. If you can't find a button by its role and name, that's an accessibility bug — fix it.
- **`act(() => { ... })`** wrapping. RTL handles act internally for `userEvent` and async queries.
- **Snapshotting markup.** Snapshot tests catch nothing meaningful and pass after every "I'll just regenerate" change. Allowed only for stable, intentionally-versioned output (e.g., generated SVG).

## Testing Server Components

Server Components are async and run server-side. They can't be rendered with `render()` directly. Two approaches:

### Render the resolved output (preferred for unit testing)

Awaiting the component returns its tree, which can be passed to RTL.

```tsx
import { render, screen } from "@testing-library/react";
import { InvoiceList } from "./invoice-list";

it("renders invoices for a customer", async () => {
  // Server Component — await it to get the JSX tree
  const tree = await InvoiceList({ customerId: makeCustomerId("cust_abc") });
  render(tree);

  expect(screen.getByText(/inv_001/i)).toBeInTheDocument();
});
```

This requires the component's data fetching to be substitutable — typically by passing the data fetch through `deps` (queries pattern) so tests provide a fake.

### Test the data layer separately

Often more useful: test the query function (with `deps`) and trust React's render pipeline to produce the right JSX.

```ts
import { listInvoicesForCustomer } from "./queries";

it("returns invoices in due-date order", async () => {
  const { deps } = makeTestDeps({ /* fixtures */ });
  const result = await listInvoicesForCustomer(makeCustomerId("c1"), deps);
  expect(result.map((i) => i.id)).toEqual(["inv_old", "inv_new"]);
});
```

If the query is right and the rendering is straightforward, you don't need a separate component test for every list view.

### What NOT to do

- Don't try to mock `next/headers` or `next/cookies`. If a Server Component reads them, refactor to take the value as a prop or via `deps`.
- Don't replicate SSR. End-to-end tests via Playwright cover the rendering pipeline.

## Testing Custom Hooks

`renderHook` from RTL drives a hook in a test component.

```ts
import { renderHook, act } from "@testing-library/react";
import { useInvoiceFilter } from "./use-invoice-filter";

describe("useInvoiceFilter", () => {
  it("updates filter on setFilter", () => {
    const { result } = renderHook(() => useInvoiceFilter({ status: ["draft"] }));

    act(() => result.current.setFilter({ status: ["sent"] }));

    expect(result.current.filter.status).toEqual(["sent"]);
  });

  it("resets to initial filter on reset", () => {
    const initial = { status: ["draft"] };
    const { result } = renderHook(() => useInvoiceFilter(initial));

    act(() => result.current.setFilter({ status: ["sent"] }));
    act(() => result.current.reset());

    expect(result.current.filter).toEqual(initial);
  });
});
```

Rules:
- **`act()` only here** — `renderHook` doesn't auto-wrap; manual `act` is required around state-changing calls.
- **Test the contract**, not internals. The hook's exported API is what matters.
- **Wrap with providers** when the hook depends on Context (`renderHook(..., { wrapper })`).

## Playwright E2E

Playwright drives a real browser through real flows. Reserve E2E for:
- Critical paths a regression in would directly hurt revenue or trust (sign-up, checkout, password reset).
- Cross-component interactions (e.g., a form submission that updates a list elsewhere).
- Integration with the full Next.js rendering pipeline (SSR, streaming, redirects).

Don't try to E2E-test every page. The pyramid says ~10-30 E2E specs total, even for substantial apps.

```ts
// e2e/sign-up.spec.ts
import { test, expect } from "@playwright/test";

test("new user signs up and lands on dashboard", async ({ page }) => {
  await page.goto("/sign-up");
  await page.getByLabel(/email/i).fill("test@example.com");
  await page.getByLabel(/password/i).fill("hunter2hunter2");
  await page.getByRole("button", { name: /create account/i }).click();

  await expect(page).toHaveURL("/dashboard");
  await expect(page.getByRole("heading", { name: /welcome/i })).toBeVisible();
});
```

### Configuration

```ts
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL ?? "http://localhost:3000",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "webkit",   use: { ...devices["Desktop Safari"] } },
    { name: "mobile",   use: { ...devices["iPhone 14"] } },
  ],
  webServer: {
    command: "pnpm build && pnpm start",
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
});
```

Rules:
- **Test against a production build**, not dev. Dev-only behavior (Strict Mode double-invocations, hot reload) doesn't ship.
- **Test on Chromium + WebKit minimum.** Safari has its own rendering quirks; catching them only at production deploy is too late.
- **Use the same query patterns as RTL** — `getByRole`, `getByLabel`. Skills carry over.
- **Use trace and screenshot on failure**, not always — they're heavy.
- **Don't share auth state across tests carelessly.** Use `storageState` or per-test sign-in. Tests that mutate shared user data are flaky.

## Test Data Builders

Avoid fixture sprawl. Build test data with factory functions that take partial overrides.

```ts
// features/invoicing/test-builders.ts
import type { Invoice, InvoiceId, CustomerId, LineItem } from "./domain";

export function makeInvoice(overrides: Partial<Invoice> = {}): Invoice {
  return {
    id: "inv_test_001" as InvoiceId,
    customerId: "cust_test_001" as CustomerId,
    lineItems: [makeLineItem()],
    status: "draft",
    dueAt: new Date("2026-12-31"),
    ...overrides,
  };
}

export function makeLineItem(overrides: Partial<LineItem> = {}): LineItem {
  return { description: "Test item", quantity: 1, unitPriceCents: 1000, ...overrides };
}
```

Rules:
- **Builders live next to the domain**, exported as `make<Entity>`. Reusable across all test layers.
- **Sane defaults, easy overrides.** A test calls `makeInvoice({ status: "paid" })` to express intent.
- **No randomization in defaults.** Deterministic IDs, dates, values. Random data masks bugs.
- **No fixture files.** A `fixtures.json` of pre-built invoices is fragile and hard to read; builders express what each test cares about.

## Mocking Strategy

The architecture in `web-architecture.md` minimizes the need for mocks. When mocks ARE needed:

| What you might want to mock | Right approach |
|----------------------------|----------------|
| Database, external APIs, file system | `deps` parameter substitution. No module mocks. |
| `Date.now()` / current time | `deps.now: () => new Date(...)`. |
| Random / UUID | Inject a `randomId: () => string` in `deps`. |
| Environment variables | Set in `vitest.config.ts` `define` or test setup. |
| `next/router`, `next/navigation` | RTL `vi.mock` only when component imports them directly. Prefer passing navigation actions in via props. |
| Network responses (fetch) | Use `msw` (Mock Service Worker) for client-fetched code paths. Handle requests at the network boundary, not by mocking `fetch`. |

What you should NOT mock:
- **Your own domain code.** Domain functions are pure — call them with real inputs.
- **React hooks.** Render the component or hook with the right props/context, don't mock `useState`.
- **TanStack Query internals.** Provide a real `QueryClient` configured for tests.

## Coverage Targets and CI

| Layer | Coverage target | Enforcement |
|-------|----------------|-------------|
| Domain | 90% lines, 90% branches | Hard fail in CI |
| Application (actions, queries) | 80% on touched files in PR | Hard fail in CI |
| Components | No global target — test what's behavior-rich | Code review |
| Hooks | 70% on non-trivial hooks | Code review |
| E2E (critical paths) | All flagged critical paths green | Hard fail in CI |

Coverage targets are floors, not ceilings. 100% coverage from worthless tests is worse than 80% coverage from valuable ones.

CI matrix:
- **PR**: Vitest run + Playwright (chromium only, fast feedback) + coverage report uploaded.
- **Main / merge**: Vitest + Playwright (all browsers) + coverage gate enforcement.
- **Nightly**: Full Playwright on all browsers + visual regression (if configured).

## Anti-Patterns

1. **Testing implementation details.** Asserting on internal state, prop names, render counts, hook call order. If a refactor that doesn't change behavior breaks the test, the test is wrong.
2. **Snapshot tests as primary assertion.** They catch nothing meaningful and pass after lazy regeneration. Use only for stable, intentionally-versioned text outputs.
3. **One mega-test per feature.** A 200-line test with 30 assertions across 8 setup steps. Split into `it` blocks per behavior.
4. **`vi.mock` for everything.** Module mocking is brittle and decouples tests from real behavior. Use `deps` substitution; mock at the network boundary (`msw`) or runtime boundary (time, randomness) only.
5. **Querying by `data-testid` reflexively.** Skipping accessibility queries hides accessibility bugs. Test IDs are last resort, not first.
6. **Testing through the UI what should be a unit test.** Calculating tax via `render(<TaxComponent />)` instead of `expect(calculateTax(...)).toBe(...)`. Push tests as low in the pyramid as the behavior allows.
7. **Inverted pyramid.** 200 component tests, 5 unit tests. Slow CI, brittle suite, behavior is hard to localize. Push toward more domain/application tests.
8. **Skipping cleanup.** Forgetting `cleanup()` after each test leaks state across tests; flakiness ensues.
9. **Real network calls in tests.** Always intercept via `msw` or via `deps` substitution. A test that hits the real network is flaky by design.
10. **Coverage as the goal.** Writing tests to hit a number rather than to verify behavior. The number is a smoke detector, not a target.
11. **Tests that depend on order or shared state.** Each test should pass in isolation and in any order. State that survives across tests is a flaky test waiting to happen.
12. **`waitFor` everywhere.** If a test needs `waitFor` to pass intermittently, the assertion is wrong. Use `findBy` for async appearance; assert sync state directly.

## Principles

1. **Test behavior, not implementation.** What does the user see, what does the contract guarantee — those are tests. How the component achieves it is internal.

2. **Push tests as low in the pyramid as the behavior allows.** Domain tests are instant, deterministic, and exhaustive. Component and E2E tests are necessary but expensive — use them where they add value (rendering, real-flow integration), not for what could be a pure function call.

3. **Architecture is the testing budget.** The dependency-injection pattern in `web-architecture.md` is what makes tests fast and readable. If a function is hard to test, the architecture is broken — not the test.

4. **No mocking the universe.** `deps` substitution covers DB, time, randomness. `msw` covers network. Beyond those, mocks indicate the code is fighting its own seams.

5. **Builders, not fixtures.** A `makeInvoice({ status: "paid" })` reads as a spec; a `fixtures/paid-invoice.json` is mystery data the reader has to dig up.

6. **RTL queries match accessible UX.** If your test can't find a button by its role and name, the button isn't accessible. Tests double as a11y smoke detection.

7. **Coverage is a smoke detector, not a goal.** A high-quality test suite naturally hits high coverage on the layers that matter (domain, application). Chasing coverage on layers where it doesn't matter (UI markup) produces tests no one trusts.
