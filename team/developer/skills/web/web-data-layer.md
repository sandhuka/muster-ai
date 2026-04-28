# Web Data Layer (Drizzle + Repositories)

## Purpose
Define the Infrastructure layer that `web-architecture.md` only sketches: ORM choice (Drizzle as default, with explicit Prisma rejection), the Repository pattern with `Result<T, RepositoryError>` returns, serverless connection-pooling reality on Vercel, migrations via drizzle-kit, the expand-contract pattern for backward-compatible deploys, transaction discipline with explicit isolation levels, N+1 prevention at the repository layer, and the rule that ORM imports never appear outside `lib/`. See `team/developer/skills/web-architecture.md` for layer boundaries (this skill is the concrete contents of one layer). See `team/developer/skills/web-best-practices.md` for `DATABASE_URL` env validation. See `team/developer/skills/web-security.md` for SQL-injection (Drizzle parameterizes by default; never reach for raw string interpolation). See `team/developer/skills/web-cicd.md` for the deploy-rollback discipline that pairs with expand-contract. Target: **Drizzle ORM 0.34+, Postgres 14+, Node.js 20+**.

## ORM Choice: Drizzle

**Default: Drizzle.** SQL-first, type-safe, zero codegen step, no runtime binary, edge-compatible.

**Rejected: Prisma.** Reasons that hold in 2026:

- **Binary engine** — Prisma ships a Rust binary that runs out-of-process. Adds startup latency on Vercel cold starts and complicates edge-runtime deployments.
- **Codegen step** — Prisma generates a client on every schema change. The generated code is checked into `node_modules`, drifts from the schema in dev, and the generation step is one more thing to fail in CI.
- **Bundle size** — the runtime client is heavy.
- **SQL escape hatch is awkward** — Prisma's `$queryRaw` is type-loose; complex queries fight the abstraction.

Drizzle does what Prisma does well (type-safe queries, schema as TypeScript) without those costs. SQL-first means complex queries stay readable and the abstraction never gets in the way.

```ts
// db/schema.ts
import { pgTable, uuid, varchar, integer, timestamp, pgEnum } from "drizzle-orm/pg-core";

export const invoiceStatus = pgEnum("invoice_status", ["draft", "sent", "paid", "overdue"]);

export const invoices = pgTable("invoices", {
  id: uuid("id").primaryKey().defaultRandom(),
  customerId: uuid("customer_id").notNull().references(() => customers.id),
  status: invoiceStatus("status").notNull().default("draft"),
  totalCents: integer("total_cents").notNull(),
  dueAt: timestamp("due_at", { withTimezone: true }).notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
});

export const customers = pgTable("customers", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull(),
  email: varchar("email", { length: 255 }).notNull().unique(),
});
```

The schema in TypeScript is the source of truth. drizzle-kit generates SQL migrations from it.

## Connection Pooling on Serverless

This is the most acute footgun in the data layer. **A naïve `pg.Pool` exhausts database connections under serverless load.** Each Vercel function invocation starts a fresh pool; Postgres has finite connections (typically 100-200); 50 concurrent invocations × 10-connection pools each = connection-exhausted database.

The viable answers, in order of preference:

### Option 1: Neon HTTP serverless driver (preferred)

Neon's `@neondatabase/serverless` driver makes each query an HTTP request. No persistent connection per function instance. Scales to thousands of concurrent functions without configuration.

```ts
// lib/db.ts
import { neon } from "@neondatabase/serverless";
import { drizzle } from "drizzle-orm/neon-http";
import { env } from "./env";
import * as schema from "@/db/schema";

const sql = neon(env.DATABASE_URL);
export const db = drizzle(sql, { schema });
```

Trade-offs:
- HTTP-per-query has higher per-query latency than a persistent connection (~30ms overhead).
- Mostly invisible because most queries are I/O-bound on the database side; the round-trip overhead is small in absolute terms.
- Transactions across multiple statements need the WebSocket variant (`neon` with `Pool` + `drizzle/neon-serverless`) — see Transaction Discipline below.

### Option 2: Vercel Postgres (managed Neon under the hood)

Same characteristics as Neon HTTP, plus Vercel-managed provisioning.

### Option 3: PgBouncer in transaction-pool mode

If using a non-Neon Postgres (RDS, Supabase, self-hosted), put PgBouncer in front:

```
[Vercel functions] -- TCP --> [PgBouncer transaction pool] -- TCP --> [Postgres]
```

PgBouncer multiplexes thousands of incoming connections onto a small pool of upstream connections. Configure `pool_mode=transaction`. Connection from the function side opens fast; the upstream connection is borrowed only for the duration of a transaction.

Caveats:
- Some Postgres features don't work in transaction-pool mode: prepared statements, session-level settings, advisory locks. Disable prepared-statement caching in your driver.
- One more thing to operate.

### Option 4: Direct `pg` Pool (only for non-serverless deployments)

If deploying to a long-running Node server (Render, Railway, Fly.io, your own VPS), a regular `pg.Pool` is fine — connections are reused across requests. **Never use this directly on Vercel.**

```ts
// lib/db.ts (long-running server only)
import { Pool } from "pg";
import { drizzle } from "drizzle-orm/node-postgres";

const pool = new Pool({ connectionString: env.DATABASE_URL, max: 20 });
export const db = drizzle(pool);
```

### Rule

Default to **Option 1 (Neon HTTP)** for new projects. The cold-start and connection story is correct out of the box. Switch to Option 2/3 if a project requires a different Postgres host. Option 4 is for non-serverless deployments only and gets a rationale logged in `decision-log.md`.

## Repository Pattern with `Result<T, RepositoryError>`

Repositories are the only files that import the ORM. They translate between domain types and storage rows. They return `Result<T, RepositoryError>` — **never throw** for expected failure modes.

```ts
// features/invoicing/repository.ts
import { eq, and, desc } from "drizzle-orm";
import { db } from "@/lib/db";
import { invoices } from "@/db/schema";
import type { Invoice, InvoiceId, CustomerId } from "./domain";
import { rowToInvoice } from "./mappers";

export type RepositoryError =
  | { kind: "not-found" }
  | { kind: "constraint-violation"; constraint: string }
  | { kind: "connection-failed"; cause: unknown };

export type Result<T, E = RepositoryError> =
  | { ok: true; value: T }
  | { ok: false; error: E };

export interface InvoiceRepository {
  findById(id: InvoiceId): Promise<Result<Invoice>>;
  list(customerId: CustomerId): Promise<Result<ReadonlyArray<Invoice>>>;
  save(invoice: Invoice): Promise<Result<void>>;
  delete(id: InvoiceId): Promise<Result<void>>;
}

export const liveInvoiceRepository: InvoiceRepository = {
  async findById(id) {
    try {
      const [row] = await db.select().from(invoices).where(eq(invoices.id, id)).limit(1);
      if (!row) return { ok: false, error: { kind: "not-found" } };
      return { ok: true, value: rowToInvoice(row) };
    } catch (cause) {
      return { ok: false, error: { kind: "connection-failed", cause } };
    }
  },
  async list(customerId) {
    try {
      const rows = await db.select().from(invoices)
        .where(eq(invoices.customerId, customerId))
        .orderBy(desc(invoices.dueAt));
      return { ok: true, value: rows.map(rowToInvoice) };
    } catch (cause) {
      return { ok: false, error: { kind: "connection-failed", cause } };
    }
  },
  async save(invoice) {
    try {
      await db.insert(invoices).values(invoiceToRow(invoice))
        .onConflictDoUpdate({ target: invoices.id, set: invoiceToRowUpdate(invoice) });
      return { ok: true, value: undefined };
    } catch (cause) {
      if (isConstraintError(cause)) {
        return { ok: false, error: { kind: "constraint-violation", constraint: extractConstraint(cause) } };
      }
      return { ok: false, error: { kind: "connection-failed", cause } };
    }
  },
  async delete(id) {
    try {
      const result = await db.delete(invoices).where(eq(invoices.id, id));
      if (result.rowCount === 0) return { ok: false, error: { kind: "not-found" } };
      return { ok: true, value: undefined };
    } catch (cause) {
      return { ok: false, error: { kind: "connection-failed", cause } };
    }
  },
};
```

```ts
// features/invoicing/mappers.ts (between domain types and DB rows)
import type { Invoice, InvoiceId, CustomerId, InvoiceStatus } from "./domain";

export function rowToInvoice(row: typeof invoices.$inferSelect): Invoice {
  return {
    id: row.id as InvoiceId,
    customerId: row.customerId as CustomerId,
    status: row.status as InvoiceStatus,
    totalCents: row.totalCents,
    dueAt: row.dueAt,
  };
}
```

Rules:
- **One repository file per aggregate**, not per table. An `Invoice` aggregate may persist into `invoices` and `invoice_line_items` tables; one `InvoiceRepository` owns both.
- **Mappers in a separate file** (`mappers.ts`). Translation between row shape and domain shape stays out of repository methods. Repositories orchestrate; mappers convert.
- **`Result<T, RepositoryError>` returns**. Never throw for expected outcomes. The few cases that justify throwing (programmer errors like "the row exists but is malformed") let the surrounding error boundary catch.
- **Repositories import from `@/db/schema`** (the Drizzle schema definitions). They're the only files that do — see "ORM Containment" below.
- **Domain types in domain, row types in `db/`.** Mappers cross the boundary. Domain types never expose Drizzle's `$inferSelect`/`$inferInsert` shapes.

## Migrations: drizzle-kit + Versioned SQL

Generate migrations from schema changes; commit the SQL files to git.

```jsonc
// drizzle.config.ts
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./src/db/schema.ts",
  out: "./drizzle",
  dialect: "postgresql",
  dbCredentials: { url: process.env.DATABASE_URL! },
  verbose: true,
  strict: true,
});
```

Workflow:

```bash
# Edit src/db/schema.ts
pnpm drizzle-kit generate     # creates drizzle/0001_<name>.sql
git add drizzle/0001_*.sql    # commit the SQL
pnpm drizzle-kit migrate      # apply to current DATABASE_URL
```

Rules:
- **Generated SQL is committed.** It's the source of truth for what runs in production. Reviewers read the SQL, not the diff in `schema.ts` — the SQL is what production sees.
- **Hand-edit the generated SQL when needed** (data migrations, complex transformations the generator can't infer). Drizzle-kit doesn't run data, only schema.
- **Migrations are append-only.** Once committed, never edited. A mistake gets a new migration that fixes it.
- **One migration per logical change.** Easier to review, easier to roll back, easier to bisect when something breaks.
- **Run `drizzle-kit migrate` from CI/CD**, not from a developer's machine. Production schema changes follow the deploy pipeline like code does.

## Expand-Contract for Backward-Compatible Deploys

The naïve approach to a schema change — "add the column AND deploy the code that uses it" — breaks zero-downtime deploys. Mid-deploy, half the instances run new code (expects the column) while the DB might not have it yet, or vice versa.

**Expand-contract**: every breaking change becomes three deploys.

### Renaming `total` to `total_cents`

**Deploy 1 (expand)**: add the new column without removing the old.

```sql
-- drizzle/0010_add_total_cents.sql
ALTER TABLE invoices ADD COLUMN total_cents INTEGER;
UPDATE invoices SET total_cents = ROUND(total * 100) WHERE total_cents IS NULL;
ALTER TABLE invoices ALTER COLUMN total_cents SET NOT NULL;
-- old `total` column still exists, still NOT NULL
```

Code change: write to BOTH columns; read from `total_cents`. Old code continues to work because `total` still exists.

```ts
// repository writes both
await db.insert(invoices).values({ total: amount, totalCents: Math.round(amount * 100), ... });
```

**Deploy 2 (transition)**: code stops writing the old column.

```ts
// repository writes only the new column
await db.insert(invoices).values({ totalCents: cents, ... });
```

The old column has stable values; new code doesn't touch it. Verify via observability that no traffic depends on `total` anymore.

**Deploy 3 (contract)**: drop the old column.

```sql
-- drizzle/0012_drop_total.sql
ALTER TABLE invoices DROP COLUMN total;
```

The column is gone. Code that referenced it is gone. Rollback to deploy 2 still works (the column wasn't being read in deploy 2 either).

Rules:
- **Three-deploy minimum for renames, type changes, and required-field additions.**
- **Backward-compatible additions are one-deploy.** Adding a nullable column or an index is safe — old code ignores it; new code uses it.
- **Backward-incompatible drops are one-deploy when the field has been unused for a release cycle.** "Unused" means no code paths read or write it; verify with observability traces, not just code search.
- **Never combine schema and behavior in one deploy** for non-additive changes. Pair every breaking schema change with the multi-deploy plan.

## Transaction Discipline

Default Postgres isolation is `READ COMMITTED`. That's right for most reads and writes, wrong for money flows and concurrency-sensitive logic.

| Isolation | Use when |
|-----------|----------|
| `READ COMMITTED` (default) | Most reads, simple writes, idempotent operations |
| `REPEATABLE READ` | A read-then-write that must see consistent state across multiple statements |
| `SERIALIZABLE` | Money transfers, inventory decrements, anything where lost updates are unacceptable |

```ts
// features/billing/repository.ts
import { db } from "@/lib/db";

async function transferFunds(fromId: AccountId, toId: AccountId, cents: number) {
  return db.transaction(
    async (tx) => {
      const [from] = await tx.select().from(accounts).where(eq(accounts.id, fromId)).for("update");
      const [to] = await tx.select().from(accounts).where(eq(accounts.id, toId)).for("update");
      if (!from || !to) throw new Error("not-found");
      if (from.balanceCents < cents) throw new Error("insufficient-funds");

      await tx.update(accounts).set({ balanceCents: from.balanceCents - cents }).where(eq(accounts.id, fromId));
      await tx.update(accounts).set({ balanceCents: to.balanceCents + cents }).where(eq(accounts.id, toId));
    },
    { isolationLevel: "serializable" },
  );
}
```

Rules:
- **`isolationLevel` declared explicitly** for any transaction touching money, inventory, sequence-critical data.
- **Use `SELECT ... FOR UPDATE`** to lock rows when reading-then-writing within a transaction (the `for("update")` Drizzle helper).
- **Keep transactions short.** Long-running transactions hold locks that starve concurrent traffic. No external API calls inside a transaction.
- **Idempotency at the application level**, not just transaction-level. A retry shouldn't double-charge — use idempotency keys at the action boundary (see `web-security.md` for webhook idempotency).
- **Catch serialization failures**. Under `SERIALIZABLE`, the DB can abort transactions that conflict; the caller retries. Drizzle surfaces these as a specific error class — wrap in a retry helper.

## N+1 Prevention at the Repository

The classic anti-pattern: render a list of invoices, then for each invoice fetch the customer. 1 query for the list + N queries for the customers = N+1.

Fix at the repository, not in the component layer:

```ts
// repository.ts — joined query
async function listWithCustomers(customerId: CustomerId): Promise<Result<ReadonlyArray<InvoiceWithCustomer>>> {
  try {
    const rows = await db
      .select({
        invoice: invoices,
        customer: customers,
      })
      .from(invoices)
      .innerJoin(customers, eq(invoices.customerId, customers.id))
      .where(eq(invoices.customerId, customerId));

    return { ok: true, value: rows.map((r) => ({ ...rowToInvoice(r.invoice), customer: rowToCustomer(r.customer) })) };
  } catch (cause) {
    return { ok: false, error: { kind: "connection-failed", cause } };
  }
}
```

Or DataLoader pattern when joins don't fit (e.g., per-row aggregates from separate tables):

```ts
// lib/dataloader.ts (per-request)
import DataLoader from "dataloader";

export function makeCustomerLoader() {
  return new DataLoader<CustomerId, Customer>(async (ids) => {
    const rows = await db.select().from(customers).where(inArray(customers.id, [...ids]));
    const map = new Map(rows.map((r) => [r.id, rowToCustomer(r)]));
    return ids.map((id) => map.get(id) ?? new Error(`Customer ${id} not found`));
  });
}
```

Rules:
- **Joins by default for has-one and has-few** relationships. The cost of one larger query beats N smaller ones.
- **DataLoader for has-many cases** that need batching across multiple component subtrees in one request. Per-request scoping (created in middleware or via `cache()`); never global.
- **The repository owns the choice**. Components never iterate and fetch — they receive a list of joined or pre-batched results from a single repository call.
- **Audit suspect endpoints with the DB query log**. A page rendering 50 entities should make a small bounded number of queries (1-3), never 50.

## ORM Containment

The single rule that keeps the architecture honest: **`drizzle-orm` and `@/db/schema` are imported only from `lib/` and `features/<x>/repository.ts`**. Anywhere else is a layer leak.

```ts
// Wrong — domain reaches into the ORM
// features/invoicing/domain.ts
import { db } from "@/lib/db"; // FORBIDDEN
import { invoices } from "@/db/schema";

export async function isOverdue(id: InvoiceId): Promise<boolean> {
  const [row] = await db.select().from(invoices).where(eq(invoices.id, id));
  // ...
}

// Wrong — Server Action reaches into the ORM directly
// features/invoicing/actions.ts
import { db } from "@/lib/db"; // FORBIDDEN
// ...

// Right — only the repository imports the ORM
// features/invoicing/repository.ts
import { db } from "@/lib/db"; // OK
```

Enforce via `eslint-plugin-boundaries`:

```jsonc
// .eslintrc — excerpt
{
  "settings": {
    "boundaries/elements": [
      { "type": "domain",         "pattern": "src/features/*/domain.ts" },
      { "type": "actions",        "pattern": "src/features/*/actions.ts" },
      { "type": "queries",        "pattern": "src/features/*/queries.ts" },
      { "type": "repository",     "pattern": "src/features/*/repository.ts" },
      { "type": "infrastructure", "pattern": "src/lib/**" },
      { "type": "schema",         "pattern": "src/db/**" }
    ]
  },
  "rules": {
    "boundaries/element-types": ["error", {
      "default": "disallow",
      "rules": [
        { "from": "domain",        "allow": ["domain"] },
        { "from": "actions",       "allow": ["domain", "repository", "infrastructure"] },
        { "from": "queries",       "allow": ["domain", "repository", "infrastructure"] },
        { "from": "repository",    "allow": ["domain", "infrastructure", "schema"] },
        { "from": "infrastructure","allow": ["infrastructure", "schema"] }
      ]
    }]
  }
}
```

The compiler (via lint) rejects ORM imports outside the allowed places. This rule alone prevents 80% of the ways data layers rot over time.

## Anti-Patterns

1. **`pg.Pool` on Vercel.** Connection exhaustion is guaranteed under load. Use Neon HTTP / Vercel Postgres / PgBouncer.
2. **Throwing from repositories.** Return `Result<T, RepositoryError>`. Throws cross layers and leak ORM details to callers.
3. **ORM imports outside `lib/` and repositories.** Domain reaches for `db.select()` is the canonical way data layers rot. Lint-enforce the boundary.
4. **Schema-and-code breaking changes in one deploy.** Half-deployed states break. Use expand-contract.
5. **Default isolation for money flows.** `READ COMMITTED` permits lost updates under concurrency. `SERIALIZABLE` for funds, inventory, balance-sensitive logic.
6. **Long-running transactions.** External API calls inside a transaction hold locks for seconds; concurrent traffic blocks. Keep transactions to in-DB work only.
7. **N+1 fetching from components.** Components iterate, call queries per row. Push the join into the repository.
8. **Migrations not committed.** `drizzle/*.sql` files belong in git. They're the production source of truth for schema, not the schema TypeScript file alone.
9. **Editing committed migrations.** Migrations are append-only. A mistake gets a new migration to fix it. Editing a committed migration silently corrupts environments that already applied the old version.
10. **`CASCADE` deletes everywhere.** They're correct sometimes; they hide ownership confusion when overused. Default to `RESTRICT` and explicit cleanup; reach for `CASCADE` deliberately.
11. **Indexes added without measurement.** Speculative indexes have write cost; some are unused. Add indexes after measuring slow queries (`EXPLAIN ANALYZE`), not preemptively.
12. **Trusting `String(unknown)` to escape SQL.** Drizzle parameterizes queries — never construct SQL with template literals. The `sql` template tag is parameterized; `${variable}` outside the tag isn't safe.
13. **One mega-table for "user data"** with a `type` column. JSON columns and discriminator tables exist to avoid this. Domain entities are separate tables; polymorphic data via JSONB or proper relationships.
14. **Connection strings hardcoded** anywhere. `DATABASE_URL` from env, validated at boot, no exceptions.

## Principles

1. **Drizzle is the default; the schema is TypeScript.** SQL-first means complex queries stay readable; type-safe means refactors propagate. The migration files are the production contract.

2. **Repositories return Results, not throws.** Expected failures are typed and handled. Throws are reserved for programmer errors that the surrounding error boundary catches.

3. **Connection pooling is a serverless concern, not an afterthought.** Pick the right driver for the runtime. Naïve pools exhaust the database; the Neon HTTP driver scales to thousands of concurrent functions.

4. **Schema changes are deploys, not commits.** Every change goes through migration generation, review of the SQL, CI application. Production schema is the production contract.

5. **Backward compatibility is the deploy-cycle default.** Expand-contract for every non-additive schema change. Rollback is only safe when the previous schema version is still queryable.

6. **Transactions are short and explicit.** Isolation level declared per transaction. No external work inside a transaction. Locks held briefly.

7. **The repository is the only place the ORM lives.** Layer leaks are how data layers rot. The boundary is lint-enforced; it never softens "just this once."
