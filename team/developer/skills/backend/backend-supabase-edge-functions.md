# Supabase Edge Functions

## Purpose
Development patterns for Supabase Edge Functions (Deno runtime). Covers project structure, request handling, deployment, and local development. See `team/developer/skills/backend-typescript.md` for Deno/TypeScript language patterns. See `team/developer/skills/backend-api-design.md` for request/response contract design. See `team/developer/skills/backend-supabase-auth.md` for auth verification in functions. See `knowledge-base/architecture.md` Section 7 for the Edge Function contract specification.

## Project Structure
Each function lives in `supabase/functions/<function-name>/index.ts`. Shared code in `supabase/functions/_shared/` (underscore prefix prevents deployment as a function). Import map at `supabase/functions/import_map.json` is shared across all functions.

```
supabase/
├── functions/
│   ├── import_map.json
│   ├── _shared/
│   │   ├── supabase-client.ts    # Reusable Supabase client factory
│   │   ├── cors.ts               # CORS headers helper
│   │   └── types.ts              # Shared request/response types
│   ├── generate-routine/
│   │   └── index.ts
│   └── migrate-data/
│       └── index.ts
├── migrations/
└── seed.sql
```

## Request Handling
- Entry point: `Deno.serve(async (req: Request) => { ... })`
- Reject wrong methods early: `if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 })`
- Parse body with `await req.json()` inside try/catch (malformed JSON returns 400)
- Validate with `zod` before any business logic:
  ```typescript
  import { z } from "zod";
  const InputSchema = z.object({ goal: z.enum(["build_strength", "improve_flexibility"]), fitness_level: z.enum(["beginner", "intermediate", "advanced"]) });
  const parsed = InputSchema.safeParse(body);
  if (!parsed.success) return errorResponse(400, "Invalid input", parsed.error.issues);
  ```
- Extract auth user for premium-only endpoints:
  ```typescript
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: req.headers.get("Authorization")! } }
  });
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) return errorResponse(401, "Unauthorized");
  ```

## Response Formatting
Always return JSON with a consistent envelope. Keep response payload under 50KB (architecture constraint).

```typescript
// Success
return new Response(JSON.stringify({ data: routineResult, error: null }), {
  status: 200, headers: { "Content-Type": "application/json", ...corsHeaders }
});

// Error helper
function errorResponse(status: number, message: string, details?: unknown) {
  return new Response(JSON.stringify({ data: null, error: { code: status, message, details } }), {
    status, headers: { "Content-Type": "application/json", ...corsHeaders }
  });
}
```

Status codes: 200 success, 400 validation, 401 unauthorized, 404 not found, 500 internal.

## Error Handling
- Wrap the entire handler in try/catch. Uncaught exceptions return 500 with a generic message.
- Log errors server-side: `console.error("generate-routine error:", error)` (visible in Dashboard Logs).
- Expected errors (validation, auth, not-found): structured error response with specific status code.
- Unexpected errors (DB connection, timeout): 500 with generic "Internal server error", full error logged.
- Never expose internal details (table names, SQL errors, stack traces) to the client.

## Secrets & Environment Variables
- Set via CLI: `supabase secrets set KEY=value`. Access: `Deno.env.get("KEY")`.
- `SUPABASE_URL` and `SUPABASE_ANON_KEY` are auto-set by Supabase.
- `SUPABASE_SERVICE_ROLE_KEY` must be set manually for admin operations.
- Never log secret values. Never include them in error responses.
- Use non-null assertion on `Deno.env.get()` only for guaranteed-present vars.

## CORS Configuration
Shared helper (required for browser-based testing and Supabase Dashboard):

```typescript
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
```

Handle preflight: `if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })`. Include `corsHeaders` in every response. For production, consider restricting `Allow-Origin` (low priority for native iOS client).

## Local Development
- Start local Supabase: `supabase start` (requires Docker).
- Serve functions: `supabase functions serve` (hot-reloads on changes).
- Local URL: `http://localhost:54321/functions/v1/<function-name>`.
- Test: `curl -X POST http://localhost:54321/functions/v1/generate-routine -H "Authorization: Bearer <local-anon-key>" -H "Content-Type: application/json" -d '{"goal":"build_strength"}'`
- Local keys are printed by `supabase start`. Set local secrets: `supabase secrets set --env-file .env.local`.

## Deployment
- Single function: `supabase functions deploy generate-routine`. All functions: `supabase functions deploy`.
- Verify in Supabase Dashboard under Edge Functions for status and logs.
- Secrets set via `supabase secrets set` persist across deployments.
- Functions deploy globally on Deno Deploy. No downtime — atomic replacement.

## Principles
1. **Validate at the gate**: Every function validates input with `zod` before business logic. Invalid requests get 400 before touching the database. This is the API boundary — trust nothing from the client.
2. **Lean functions, fast cold starts**: One operation per function. Minimize imports — every dependency increases cold start time. Shared utilities go in `_shared/`, but only import what you use.
3. **Structured errors, never raw exceptions**: Every error path returns JSON with status code, message, and optional details. Log full errors server-side, return sanitized versions to the client.
4. **Idempotent by design**: Functions that create or modify data handle duplicate requests gracefully (client-generated UUIDs for deduplication). Network retries are inevitable — never create duplicate records.
