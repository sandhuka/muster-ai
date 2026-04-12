# Backend API Design

## Purpose
API contract design methodology between the iOS client and Supabase Edge Functions. This covers the contract patterns -- see `team/developer/skills/backend-supabase-edge-functions.md` for Edge Function implementation. See `team/developer/skills/ios-networking.md` for client-side contract consumption (Swift Codable structs). See `team/developer/skills/backend-typescript.md` for TypeScript type definitions. See `knowledge-base/architecture.md` Section 7 for the Edge Function contract specification (AlgorithmInput/RoutineResponse).

## Request/Response Contracts
- **JSON everywhere**: All Edge Function communication uses JSON. No form data, no multipart, no query params for complex inputs.
- **snake_case keys**: Match PostgreSQL column naming convention. iOS client uses `JSONDecoder` with `.convertFromSnakeCase` key strategy -- zero manual mapping.
- **Type parity**: Every request/response type has a TypeScript interface (server) and a Swift Codable struct (client). Field names, types, and optionality must match exactly (adjusted for language convention).
- **Response envelope**: All responses use a consistent wrapper:
  ```json
  { "data": { ... }, "error": null, "meta": { "request_id": "uuid", "timestamp": "iso8601" } }
  ```
  On error: `data` is null, `error` is populated. On success: `error` is null, `data` is populated. Client can always check `error != null` first.
- **Null vs absent**: Use `null` for explicitly empty values (e.g., `exercise_id: null` for manual entries). Omit fields only if they are truly optional and the client handles absence.

## Error Response Format
- Consistent error structure across all endpoints:
  ```json
  {
    "data": null,
    "error": { "code": "VALIDATION_ERROR", "message": "Human-readable description", "details": [{ "field": "goal", "issue": "invalid enum value" }] },
    "meta": { "request_id": "uuid" }
  }
  ```
- Error codes (string enums, not HTTP status codes):
  - `VALIDATION_ERROR` (400) -- input failed schema validation
  - `UNAUTHORIZED` (401) -- missing or invalid auth token
  - `FORBIDDEN` (403) -- valid auth but insufficient permissions
  - `NOT_FOUND` (404) -- requested resource does not exist
  - `CONFLICT` (409) -- duplicate operation (idempotency check caught it)
  - `INTERNAL_ERROR` (500) -- unexpected server failure
- The `details` array is optional -- include for validation errors (per-field breakdown), omit for auth/server errors.
- `request_id` in every response (UUID generated per request) -- enables log correlation for debugging.

## Versioning Strategy
- URL path versioning: `/v1/generate-routine`, `/v1/migrate-data`.
- No breaking changes within a version. Breaking change = new version (`/v2/`).
- **Breaking**: removing a field, changing a field type, changing optional to required, renaming a field.
- **Non-breaking**: adding a new optional field, adding a new endpoint, adding a new enum value (if client handles unknown values gracefully).
- For MVP: start at `/v1/`. Do not pre-create `/v2/` -- add it when there is a real need.
- Edge Function naming matches version: `supabase/functions/v1-generate-routine/index.ts` or handle versioning via URL routing in a single function.

## Pagination
- Use cursor-based pagination for list endpoints (workout history):
  ```json
  { "data": { "items": [...], "cursor": "2026-03-28T10:00:00Z", "has_more": true }, "error": null }
  ```
- Cursor is the `completed_at` timestamp of the last item (natural ordering for workout history).
- Page size: client sends `limit` param (default 20, max 100).
- Client sends `cursor` from previous response to get next page.
- Why cursor over offset: offset pagination breaks when new records are inserted (items shift). Cursor is stable.
- For MVP: only workout history needs pagination. Other endpoints return single objects or small arrays.

## Idempotency
- **Client-generated UUIDs**: Every record created by the client has a UUID primary key generated on the client device. The server uses `ON CONFLICT (id) DO NOTHING` for inserts.
- **Why**: Network retries are inevitable (timeout, retry, duplicate request). Without idempotency, the same workout gets recorded twice.
- **Implementation**: Client sends UUID in the request body. Server inserts with that UUID. On conflict (duplicate UUID), the insert is silently skipped and the existing record is returned.
- **Scope**: Focus idempotency on data-mutating operations (workout completion, data migration). For operations like `generate-routine`, idempotency is less critical (generating a new routine twice is harmless).

## Offline Sync and Conflict Resolution
- **Queue model**: When offline, the iOS client queues mutations locally (SwiftData `OfflineMutation` model). On reconnect, replays in FIFO order.
- **Conflict rules** (two rules, no ambiguity):
  1. **Server wins for plan/schedule data**: If both client and server modified a workout plan while offline, the server version is authoritative (it has the latest algorithm output).
  2. **Client wins for user-generated data**: Workout completions, exercise skips, and preference changes originate on the user's device -- the device is the source of truth for what the user actually did.
- **Conflict detection**: Compare `updated_at` timestamps. If the server's `updated_at` is newer than the client's last-seen timestamp, a conflict exists. Apply the appropriate rule above.
- **Retry strategy**: Exponential backoff (1s, 2s, 4s), max 3 retries per mutation, then queue for next app open. Never retry indefinitely.

## Principles
1. **Envelope everything**: Every response -- success or error -- uses the same `{ data, error, meta }` wrapper. The client has exactly one parsing path, not a different shape per endpoint. This eliminates an entire class of client-side bugs.
2. **Contract-first development**: Define the TypeScript interface and Swift struct BEFORE writing the Edge Function logic. The contract is the spec -- both sides implement against it. Mismatches are caught at compile time, not in production.
3. **Cursor over offset**: Always use cursor-based pagination. Offset pagination is simpler to implement but breaks under concurrent writes (items shift between pages). Cursor pagination is stable and performs better on large datasets.
4. **Two conflict rules, not a framework**: Keep conflict resolution dead simple -- server wins for system-generated data, client wins for user-generated data. Do not build a CRDT or vector clock. Two rules cover every case in this app.
