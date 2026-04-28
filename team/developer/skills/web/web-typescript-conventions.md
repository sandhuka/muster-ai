# Web TypeScript Conventions

## Purpose
Define TypeScript-specific rules, type-system patterns, and conventions for web development: strict config, naming, branded types, discriminated unions, exhaustive checking, Zod patterns, module organization, forbidden types. See `team/developer/skills/web-architecture.md` for layer boundaries (where types apply). See `team/developer/skills/web-best-practices.md` for the underlying "type safety as design tool" principle. See `team/developer/skills/web-modern-react.md` for React-specific type patterns. Target: **TypeScript 5.5+, strict mode**.

## Version & Strict Configuration

`tsconfig.json` MUST include all of these flags. They are not negotiable.

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "noPropertyAccessFromIndexSignature": true,
    "exactOptionalPropertyTypes": true,
    "useUnknownInCatchVariables": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "moduleResolution": "bundler",
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"]
  }
}
```

What each adds beyond `"strict": true`:

| Flag | What it catches |
|------|-----------------|
| `noUncheckedIndexedAccess` | `arr[0]` returns `T \| undefined` instead of `T` — forces nullability handling for indexed access |
| `exactOptionalPropertyTypes` | `{ x?: number }` no longer accepts `{ x: undefined }`; the field is missing or a number, never explicitly `undefined` |
| `useUnknownInCatchVariables` | `catch (e)` types `e` as `unknown`, forcing narrowing before use |
| `noPropertyAccessFromIndexSignature` | Forces bracket notation for index-signature lookups, distinguishing known fields from dynamic ones |
| `verbatimModuleSyntax` | Imports of types must use `import type`; clarifies what's erased at compile time |
| `noFallthroughCasesInSwitch` | Errors on missing `break`/`return` in switch cases |
| `noImplicitOverride` | Subclass overrides must be marked `override` |

## Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Types and interfaces | PascalCase | `Invoice`, `LineItem` |
| Type parameters | Single capital letter or PascalCase | `T`, `TItem`, `TError` |
| Variables and functions | camelCase | `totalCents`, `isOverdue` |
| Constants (true compile-time) | UPPER_SNAKE_CASE | `MAX_LINE_ITEMS`, `DEFAULT_PAGE_SIZE` |
| Constants (runtime config, computed) | camelCase | `pageSize`, `defaultLocale` |
| React components | PascalCase, named export | `InvoiceList` |
| Hooks | `use` prefix, camelCase | `useInvoices` |
| Files | kebab-case | `invoice-list.tsx`, `create-invoice.ts` |
| Zod schemas | PascalCase + `Schema` suffix | `InvoiceSchema`, `CreateInvoiceSchema` |
| Branded type marker | `__brand` field with literal string | `{ readonly __brand: "InvoiceId" }` |
| Result types | `<Action>Result` | `CreateInvoiceResult` |
| Discriminator field | `kind` or `type` (consistent within a project) | `{ kind: "loading" }` |

Avoid abbreviations except universally-understood ones (`id`, `url`, `db`). `usr`, `cfg`, `mgr` are not universally understood.

## Strict TS Rules

### No `any`
Ever. The escape hatch is `unknown` + narrowing.

```ts
// Wrong
function process(input: any) { /* ... */ }

// Right
function process(input: unknown) {
  if (typeof input === "string") { /* now string */ }
}
```

### No `// @ts-ignore` or `// @ts-expect-error`
Both indicate a TODO. If you genuinely need to suppress an error, prefer `// @ts-expect-error` with a comment explaining why and an issue link, and treat the comment as a sprint task to remove.

### No `as` assertions (with three exceptions)
Type assertions lie to the compiler. Avoid them. The narrow exceptions:

1. **Brand application after validation** — `parsed.id as InvoiceId` is acceptable when `parsed` came from a Zod schema that already validated the shape.
2. **`as const` for literal narrowing** — `["a", "b"] as const` is the literal-tuple pattern; not a lie.
3. **Type predicates inside narrowing functions** — `value is Foo` is a documented narrowing contract.

If you find yourself reaching for `as` outside these cases, the type is wrong, the validation is missing, or the function signature is too loose. Fix at the source.

### Prefer `interface` for object shapes, `type` for everything else
- `interface` for plain object shapes — supports declaration merging, slightly better error messages, signals intent.
- `type` for unions, intersections, mapped types, conditional types, function signatures, tuples.

```ts
interface Invoice { id: InvoiceId; status: InvoiceStatus; }
type InvoiceStatus = "draft" | "sent" | "paid";
type InvoiceMap = ReadonlyMap<InvoiceId, Invoice>;
```

### `readonly` everywhere it can apply
- `readonly` on interface fields when the field shouldn't change after construction (most domain types).
- `ReadonlyArray<T>` for function parameters and returned arrays the caller shouldn't mutate.
- `as const` for fixed lookup tables.

```ts
interface Invoice {
  readonly id: InvoiceId;
  readonly lineItems: ReadonlyArray<LineItem>;
}
```

This isn't paranoia — it's documenting intent. A function that takes `Array<T>` claims it might mutate; `ReadonlyArray<T>` says it won't.

## Branded Types (Typed Identity)

Strings are not interchangeable. A `CustomerId` is not an `InvoiceId`. Brand them.

### The pattern

```ts
// features/invoicing/domain.ts
export type InvoiceId = string & { readonly __brand: "InvoiceId" };
export type CustomerId = string & { readonly __brand: "CustomerId" };
```

### Creating branded values

Branded values come from one of two places:

1. **Zod schema parse** (preferred — validates AND brands in one step):

```ts
export const InvoiceIdSchema = z.string().uuid().brand<"InvoiceId">();
export type InvoiceId = z.infer<typeof InvoiceIdSchema>;

const id = InvoiceIdSchema.parse(rawString); // typed InvoiceId
```

2. **Factory function** (when no schema exists, e.g., generating a fresh ID):

```ts
import { randomUUID } from "node:crypto";

export function makeInvoiceId(): InvoiceId {
  return randomUUID() as InvoiceId; // single point where the cast lives
}
```

### Rules

- **Brand every entity ID.** Customer, Invoice, User, Organization. Even if the type is `string` underneath.
- **One cast per brand, in one place.** Either the Zod schema or a factory function. Never `someString as InvoiceId` in feature code.
- **Don't brand primitives that don't have identity.** A `cents: number` doesn't need a brand; `centsToDollars(cents)` is unambiguous from the function name.

## Discriminated Unions (Result Types and State)

Discriminated unions replace `null`-with-error-string and "is loading + has error + has data" boolean soup with state types the compiler can verify.

### Result type pattern

```ts
type CreateInvoiceResult =
  | { ok: true; invoice: Invoice }
  | { ok: false; errors: Record<string, string> };

const result = await createInvoice(formData);
if (result.ok) {
  // result.invoice is typed
} else {
  // result.errors is typed
}
```

Server Actions and queries return discriminated unions, never throw across boundaries.

### State pattern

```ts
type InvoiceListState =
  | { kind: "idle" }
  | { kind: "loading" }
  | { kind: "loaded"; invoices: ReadonlyArray<Invoice> }
  | { kind: "error"; message: string };
```

Modeling state as a discriminated union eliminates impossible states (e.g., "loading AND has data AND has error").

### Exhaustive switching with `assertNever`

```ts
// lib/assert-never.ts
export function assertNever(value: never): never {
  throw new Error(`Unhandled discriminant: ${JSON.stringify(value)}`);
}
```

```ts
function renderState(state: InvoiceListState) {
  switch (state.kind) {
    case "idle":    return <Empty />;
    case "loading": return <Skeleton />;
    case "loaded":  return <List invoices={state.invoices} />;
    case "error":   return <Error message={state.message} />;
    default:        return assertNever(state); // compiler error if a case is missing
  }
}
```

When you add a new variant, every `assertNever` site fires a compile-time error. This is the value: the compiler routes every switch to be updated, you can't ship a half-handled new state.

## Zod Patterns

Zod is the validation layer at every external boundary. One library covers parsing, type inference, branding, transformation.

### Schema as the source of truth

Define the schema, infer the type from it. Don't write the type and the schema separately.

```ts
export const CreateInvoiceSchema = z.object({
  customerId: z.string().uuid().brand<"CustomerId">(),
  lineItems: z.array(z.object({
    description: z.string().min(1),
    quantity: z.number().int().positive(),
    unitPriceCents: z.number().int().nonnegative(),
  })).min(1),
  dueAt: z.coerce.date(),
});
export type CreateInvoiceInput = z.infer<typeof CreateInvoiceSchema>;
```

### `safeParse` at boundaries, not `parse`

`parse` throws. `safeParse` returns `{ success: true, data } | { success: false, error }`. Use `safeParse` at every external edge so errors become typed return values, not exceptions.

```ts
const parsed = CreateInvoiceSchema.safeParse(formData);
if (!parsed.success) {
  return { ok: false, errors: zodErrorToFieldMap(parsed.error) };
}
// parsed.data is typed and safe
```

`parse` is acceptable for internal invariants where a failure represents a programmer error (e.g., parsing a value already known to be valid in a non-test context).

### Common patterns

```ts
// Branded ID schemas (one per entity)
export const InvoiceIdSchema = z.string().uuid().brand<"InvoiceId">();

// Discriminated unions
export const InvoiceStatusSchema = z.enum(["draft", "sent", "paid", "overdue"]);

// Coerce for form data (everything is string)
z.coerce.number().int().positive()
z.coerce.date()
z.coerce.boolean()

// Composition
export const InvoiceSchema = z.object({
  id: InvoiceIdSchema,
  customerId: CustomerIdSchema,
  status: InvoiceStatusSchema,
  // ...
});
```

## Type Narrowing

Use narrowing utilities, not assertions, to convince the compiler.

### Type predicates for runtime checks

```ts
function isInvoice(value: unknown): value is Invoice {
  return InvoiceSchema.safeParse(value).success;
}

if (isInvoice(data)) {
  // data is typed as Invoice here
}
```

### `in` operator for tagged-object narrowing

```ts
function process(result: { ok: true; data: Foo } | { ok: false; error: Bar }) {
  if ("data" in result) { /* result.data */ }
  else { /* result.error */ }
}
```

### `instanceof` for class narrowing

```ts
catch (e) {
  if (e instanceof DatabaseError) { /* e.code */ }
  else { /* unknown */ }
}
```

### Discriminator narrowing (preferred when possible)

```ts
if (state.kind === "loaded") { /* state.invoices */ }
```

Always preferable to `in` checks because the discriminator field is explicit and exhaustive checking works.

## Module Organization

### Named exports only
Default exports break rename refactors and obscure what's exported. Use named exports for components, functions, types, schemas. The Next.js framework conventions that *require* default exports are the only exception (`page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`, `not-found.tsx`, `route.ts`, `middleware.ts`).

### No barrel files (`index.ts` re-exports)
- Slows down build and IDE.
- Hides the actual dependency graph.
- Makes "find references" return the barrel, not the source.

Import directly from the file that defines what you need.

```ts
// Wrong
import { createInvoice } from "@/features/invoicing";
// Right
import { createInvoice } from "@/features/invoicing/actions";
```

### `import type` for type-only imports

```ts
import type { Invoice, InvoiceId } from "./domain";
import { createInvoice } from "./actions";
```

`verbatimModuleSyntax` enforces this — type imports get fully erased, code imports stay.

## Forbidden Types and Patterns

| Forbidden | Why | Use instead |
|-----------|-----|-------------|
| `any` | Lies to the compiler | `unknown` + narrowing |
| `Function` | Untyped callable | `(arg: T) => U` specific signature |
| `Object` | Matches everything including primitives | `Record<string, unknown>` or specific shape |
| `{}` (empty type) | Matches anything non-null | `Record<string, unknown>` if a generic object is needed |
| `as` (outside the 3 exceptions above) | Type assertion = lie | Validation or proper signature |
| `// @ts-ignore` | Hides errors | Fix the type or use `@ts-expect-error` with explanation |
| Default exports for components/actions/queries/utils | Refactor-hostile | Named exports |
| `interface I {}` (empty extends pattern) | Provides no value | Remove or `type I = J` |
| `enum` (numeric or const enum) | Bundle bloat, runtime quirks, breaks tree-shaking | Object with `as const` or string union types |
| `namespace` | Predates ES modules | ES modules |
| `?` plus `\| undefined` (with `exactOptionalPropertyTypes`) | Redundant + ambiguous | One or the other, not both |

## JSDoc on Public APIs

Document exported functions, types, and modules that cross feature boundaries. Internal helpers don't need docs unless their name doesn't speak.

```ts
/**
 * Calculates the total amount due across all line items.
 * Returns cents to avoid floating-point arithmetic.
 *
 * @example
 * totalCents(invoice) // 12450 (i.e. $124.50)
 */
export function totalCents(invoice: Invoice): number {
  // ...
}
```

JSDoc shows up in IDE hover and auto-import previews — it's documentation that finds the reader.

## Principles

1. **The compiler is your first reviewer.** Strict mode + the additional flags above turn the type system into a static reviewer. Configure aggressively; fight every escape hatch.

2. **Types come from runtime validation, not the other way around.** Zod parses external input and produces both the runtime guarantee and the static type. Hand-written types over hand-written validators is a duplication that drifts.

3. **Brand identity, not values.** IDs are nominally typed; magnitudes (cents, percentages, milliseconds) are usually fine as plain numbers — the function name carries the meaning.

4. **Discriminated unions over boolean soup.** Model state as `{ kind: "loading" } | { kind: "loaded"; data }`, not `{ isLoading: boolean; data?: T; error?: string }`. Impossible states become impossible.

5. **Exhaustive switches via `assertNever`.** Every union switch ends with `assertNever(value)`. Adding a variant routes the compiler to every site.

6. **Named imports, no barrels.** The dependency graph stays honest, builds stay fast, refactors stay safe.

7. **`readonly` is documentation.** Marking fields and arrays readonly tells the next reader (and the compiler) what won't change. Apply liberally.
