# TypeScript & Deno Runtime

## Purpose
TypeScript language patterns and Deno runtime essentials for Supabase Edge Functions. This is the language mastery skill — read it when writing any server-side TypeScript. See `team/developer/skills/backend-supabase-edge-functions.md` for Edge Function project structure and deployment. See `knowledge-base/architecture.md` for the Edge Function contract (Section 7).

## Deno Runtime Essentials
- Deno is the runtime for Supabase Edge Functions (not Node.js)
- Permissions model: `--allow-net`, `--allow-env`, `--allow-read` — Edge Functions run in a restricted sandbox, Supabase handles permissions
- No `node_modules` — dependencies via URL imports or import maps
- Deno uses web standard APIs: `fetch`, `Request`, `Response`, `Headers`, `URL`, `crypto`
- Built-in TypeScript support — no compilation step needed
- Top-level `await` supported natively
- `Deno.env.get("KEY")` for environment variables (secrets set via Supabase CLI or dashboard)

## Import Maps & Dependencies
- Edge Functions use `import_map.json` in the `supabase/functions/` root
- Pin dependency versions in import map — no floating versions, ever
- Prefer Deno standard library (`https://deno.land/std@{version}/`) for utilities
- Supabase client: import `createClient` from `@supabase/supabase-js` (mapped in import map)
- `zod` for runtime request validation — import via esm.sh or import map entry
- Minimize dependencies — every import increases cold start time
- Shared code across functions: place in `supabase/functions/_shared/` and import via relative path

## Type Safety Patterns
- Always enable `strict: true` in TypeScript config (Deno default)
- Prefer `unknown` over `any` — force explicit type narrowing
- Use discriminated unions for domain state:
  ```ts
  type Result<T> = { ok: true; data: T } | { ok: false; error: string }
  ```
- Define request/response types as `interface` (not `type`) for extendability
- Use `as const` for enum-like values when PostgreSQL enums map to string literals
- `Partial<T>`, `Pick<T, K>`, `Omit<T, K>` for flexible type derivation from base interfaces
- Never use `!` (non-null assertion) — handle nulls explicitly with narrowing or nullish coalescing

## Async/Await & Error Handling
- All Edge Function handlers are async — use `async/await` consistently, never raw `.then()` chains
- Never use bare `catch(e)` — always type: `catch (error: unknown)`, then narrow:
  ```ts
  catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Unknown error";
  }
  ```
- Wrap async operations in try/catch at the handler level, return structured error responses
- Use `AbortController` + `AbortSignal` for timeout enforcement on outbound requests:
  ```ts
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);
  const res = await fetch(url, { signal: controller.signal });
  clearTimeout(timeout);
  ```
- `Promise.all()` for independent concurrent operations (e.g., parallel DB queries)
- `Promise.allSettled()` when partial failure is acceptable and each result is handled independently
- Never fire-and-forget promises — always await or explicitly handle the rejection

## Principles
1. **Strict by default**: Enable all TypeScript strict checks. `unknown` over `any`, explicit null handling, no non-null assertions. Strictness catches bugs at write time, not runtime.
2. **Minimize imports**: Every dependency increases cold start latency. Use web standard APIs and Deno stdlib before reaching for third-party packages. If a utility is under 10 lines, inline it.
3. **Type the boundaries**: Request inputs and response outputs must have explicit TypeScript types with runtime validation (zod). Internal helper functions can rely on TypeScript inference.
4. **Errors are values, not exceptions**: Use the Result pattern for expected failure cases (validation errors, not-found). Reserve try/catch for truly unexpected errors (network failure, DB connection loss). This keeps error handling visible in the type system.
