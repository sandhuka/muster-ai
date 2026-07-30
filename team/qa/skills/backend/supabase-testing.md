# Supabase Testing

## Purpose
Define backend/Supabase-specific testing methodology for the product. Covers Auth, RLS, Edge Functions, database schema, Storage, data migration, and offline sync. See the `test-strategy` skill for general testing levels and the two-tier test design that frames these backend tests.

## Test Environment Setup

### Local Development (Supabase CLI)
- Run `supabase start` to spin up local Postgres, Auth, Storage, and Edge Functions.
- Local environment uses `supabase/migrations/20260328000001_initial_schema.sql` automatically.
- Local Auth auto-confirms accounts (no email verification needed).
- Use `supabase db reset` between test runs for a clean state.
- Edge Functions run locally via `supabase functions serve` with `--env-file .env.local`.

### Remote (Staging Project)
- Staging project mirrors production schema. Apply migrations with `supabase db push`.
- Use throwaway email addresses for test accounts (e.g., `test+<uuid>@[your-domain].com`).
- Clean up test data after each run. Never test against the production project.

### Key Credentials for Testing
- **Anon key**: Public, included in iOS bundle. Used for unauthenticated requests and initial auth calls.
- **Service role key**: Secret, never in client code. Used only in Edge Functions (`createAdminClient`). Test that this key is absent from any client-side artifact.
- **User JWT**: Obtained after sign-in. Passed in `Authorization: Bearer <token>` header. RLS evaluates `auth.uid()` from this token.

---

## 1. Auth Testing

### Sign Up (Email/Password)
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Happy path sign-up | POST to `auth/v1/signup` with valid email + password | 200, user object returned, `id` is a UUID, session tokens present |
| Duplicate email | Sign up with an already-registered email | Error response (Supabase returns 400 or redirect based on config) |
| Weak password | Sign up with password < 6 chars | 422 or 400, descriptive error |
| Invalid email format | Sign up with `notanemail` | 422 or 400, descriptive error |
| Auto-confirm enabled | Sign up, then immediately call `getUser()` | User is confirmed, no email verification step required |

### Sign In
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Happy path sign-in | POST to `auth/v1/token?grant_type=password` with valid credentials | 200, access_token + refresh_token returned |
| Wrong password | Sign in with incorrect password | 400, "Invalid login credentials" |
| Non-existent email | Sign in with unregistered email | 400, same generic error (no email enumeration) |
| Sign in returns profile-linked user | Sign in, extract `user.id`, query `user_profiles` with that ID | Profile row exists if previously created |

### Sign Out
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Sign out invalidates session | Sign out, then call `getUser()` with the old access token | 401 Unauthorized |
| Sign out is idempotent | Call sign-out twice | Second call succeeds or returns benign error, no crash |

### Password Reset
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Reset request accepted | POST to `auth/v1/recover` with registered email | 200 (Supabase sends reset email in production; in local dev, check Inbucket at `localhost:54324`) |
| Reset with unknown email | POST with unregistered email | 200 (no email enumeration leak -- same response) |

### Session Token Refresh
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Refresh before expiry | Call `auth.refreshSession()` with valid refresh token | New access_token returned, old one still works briefly |
| Refresh after access token expiry | Wait for access token to expire (default 3600s; use short-lived token in test config), then refresh | New tokens issued, API calls work again |
| Refresh with revoked token | Sign out (which revokes refresh token), then attempt refresh | 401, refresh denied |

### Expired Session Handling
| Test Case | Steps | Expected |
|-----------|-------|----------|
| API call with expired JWT | Manually craft or wait for an expired access token, call `generate-routine` | 401 from Edge Function |
| iOS client auto-refresh | Simulate expired access token in the Supabase Swift client | Client automatically refreshes and retries the request transparently |

---

## 2. RLS Policy Testing

### User Isolation
Test with two users (User A and User B), each signed in with their own JWT.

| Test Case | Steps | Expected |
|-----------|-------|----------|
| User A reads own profile | User A queries `user_profiles` | Returns only User A's row |
| User A cannot read User B's profile | User A queries `user_profiles` filtered by User B's ID | Empty result (RLS filters it out, no error) |
| User A reads own workouts | User A queries `workout_history` | Returns only User A's workouts |
| User A cannot read User B's workouts | User A queries `workout_history` with `user_id = B.id` | Empty result |
| User A reads own exercises | User A queries `workout_exercises` joined through their workouts | Returns only exercises belonging to User A's workouts |
| Cross-user exercise access blocked | User A queries `workout_exercises` with a `workout_id` owned by User B | Empty result (join-based RLS blocks it) |
| User A inserts into own profile | User A inserts a `user_profiles` row with `id = A.uid` | Success |
| User A cannot insert as User B | User A inserts a `user_profiles` row with `id = B.uid` | RLS violation error |
| No direct DELETE on user_profiles | User A attempts `DELETE FROM user_profiles WHERE id = A.uid` | Fails -- no DELETE policy exists; deletion goes through `delete_user_data` RPC |

### Anon Key vs Authenticated Key
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Anon key cannot read user_profiles | Query `user_profiles` with anon key (no JWT) | Empty result or 401 (RLS blocks because `auth.uid()` is null) |
| Anon key cannot read workout_history | Same, for workout_history | Empty / blocked |
| Anon key cannot insert | Attempt insert into any RLS-protected table with anon key | Fails |

### delete_user_data RPC (SECURITY DEFINER)
This function runs with the owner's privileges, bypassing RLS. It is called from the `delete-user-data` Edge Function using the service role key.

| Test Case | Steps | Expected |
|-----------|-------|----------|
| Deletes all user data | Create user with profile, 3 workouts, 10 exercises. Call `delete_user_data(user_id)` via admin client | `user_profiles` row gone. All `workout_history` rows gone. All `workout_exercises` rows gone. Returns `{ success: true, deleted_workouts: 3 }` |
| Handles user with no workouts | Create user with profile only. Call RPC | `{ success: true, deleted_workouts: 0 }`. Profile row gone |
| Does not affect other users | User A and User B both have data. Delete User A | User B's data untouched (verify all 3 tables) |
| Cannot be called with anon key directly | Call the RPC from a client using only the anon key | Should fail -- the RPC is SECURITY DEFINER but the Edge Function gates on auth |

### migrate_user_data RPC (Atomicity)
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Happy path migration | Call with valid profile, 2 workouts, 5 exercises | All rows inserted. Returns `{ success: true }` |
| Invalid profile data (bad enum) | Pass `goal: "invalid_value"` | CHECK constraint violation. Transaction rolls back. No partial data in any table |
| Invalid exercise FK | Pass exercise with `workout_id` that does not match any workout in `p_workouts` | FK violation. Full rollback. Verify `user_profiles` row was also rolled back |
| Duplicate profile ID | Call migration twice with same user ID | Second call fails (PK conflict on `user_profiles`). First migration data untouched |
| Empty workouts array | Call with valid profile but empty `p_workouts` and `p_exercises` | Profile inserted, no workouts or exercises. Returns `{ success: true }` |
| Partial workout data | Omit a required field (e.g., `discipline` null) | NOT NULL violation. Full rollback -- no profile, no workouts, no exercises |
| RLS applies (not SECURITY DEFINER) | User A calls `migrate_user_data` with `p_profile.id = B.uid` | RLS blocks the insert into `user_profiles` because `auth.uid() != B.uid` |

---

## 3. Edge Function Testing

### generate-routine

**Source**: `supabase/functions/generate-routine/index.ts`
**Status**: Scaffold (placeholder logic; real algorithm in Sprint 2)

| Test Case | Steps | Expected |
|-----------|-------|----------|
| CORS preflight | Send OPTIONS request | 200 with `Access-Control-Allow-Origin: *` and allowed headers |
| Method not allowed | Send GET request | 405, ApiResponse envelope with error |
| No auth header | Send POST with no Authorization header | 401, `{ data: null, error: { code: 401, message: "Unauthorized" } }` |
| Invalid JWT | Send POST with `Authorization: Bearer garbage` | 401 |
| Invalid JSON body | Send POST with auth, body = `not json` | 400, message "Invalid JSON body" |
| Zod validation failure | Send POST with auth, body = `{ "goal": "invalid" }` | 400, message "Invalid input", details contains Zod issues array |
| Missing required fields | Send POST with auth, body = `{}` | 400, Zod issues list every missing field |
| Free user rejected | Create user with `subscription_tier = 'free'` in profile. Send valid request | 403, message contains "Premium subscription required" |
| Expired subscription rejected | Create user with `subscription_tier = 'premium_monthly'` and `subscription_expires_at` in the past | 403 |
| Premium user succeeds | Create user with valid premium subscription. Send valid AlgorithmInput | 200, response contains `sessionTypeLabel`, `totalDurationSeconds`, `source: "smart"`, 3 blocks (warm_up, main, cool_down) |
| Response envelope format | Every response (success and error) | Matches `ApiResponse<T>` shape: `{ data: T | null, error: { code, message, details? } | null }` |
| Content-Type header | Any response | `Content-Type: application/json` present |

**Zod Schema Boundary Tests** (from `supabase/functions/_shared/types.ts`):

| Field | Valid | Invalid |
|-------|-------|---------|
| `goal` | `"build_strength"` | `"lose_weight"` |
| `fitnessLevel` | `"beginner"` | `"expert"` |
| `equipment` | `["none", "mat"]` | `["dumbbells"]` |
| `timePreference` | `"10-15"` | `"45-60"` |
| `disciplines` | `["strength"]` (min 1) | `[]` (empty array fails min(1)) |
| `workoutPace` | `"relaxed"` | `"fast"` |
| `workoutHistory[].discipline` | `"yoga"` | `"pilates"` |
| `workoutHistory[].muscleGroupsWorked` | `["chest", "back"]` | `["abs"]` (not in MuscleGroup enum) |
| `smartRoutineCountThisWeek` | `0`, `2` | `-1` (fails min(0)), `1.5` (fails int()) |

### delete-user-data

**Source**: `supabase/functions/delete-user-data/index.ts`

| Test Case | Steps | Expected |
|-----------|-------|----------|
| CORS preflight | OPTIONS request | 200 with CORS headers |
| Method not allowed | GET request | 405 |
| No auth | POST with no Authorization | 401 |
| Happy path deletion | Authenticated user with profile + workouts + exercises | 200, `{ data: { success: true }, error: null }`. All data gone from all 3 tables. Auth account deleted |
| Auth deletion failure (orphaned record) | Simulate admin.deleteUser failure (e.g., by deleting the auth record first, then calling the endpoint) | Function still returns 200 to client (data already deleted). Logs `ORPHANED AUTH RECORD` warning |
| User with no data | Authenticated user with no profile row | RPC returns `{ success: true, deleted_workouts: 0 }`. Auth account still deleted |
| Cannot delete other users | User A calls delete-user-data | Only User A's data and auth account are deleted. User B unaffected |
| No request body required | POST with empty body | Works (user identified from JWT, no body parsed) |

### CORS Validation (Both Functions)
| Test Case | Expected |
|-----------|----------|
| `Access-Control-Allow-Origin` | `*` (per `_shared/cors.ts`) |
| `Access-Control-Allow-Headers` | Includes `authorization`, `x-client-info`, `apikey`, `content-type` |
| OPTIONS returns 200 | Not 204, not 405 |
| Non-OPTIONS responses include CORS headers | Every response (success and error) includes CORS headers |

### Error Response Format Consistency
All Edge Function error responses must use the `ApiResponse<null>` envelope:
```json
{
  "data": null,
  "error": {
    "code": <http_status>,
    "message": "<human_readable>",
    "details": <optional_object_or_null>
  }
}
```
Test every error path (401, 403, 400, 404, 405, 500) in both functions and verify this structure.

---

## 4. Database Schema Testing

### CHECK Constraint Validation
For each CHECK constraint in `20260328000001_initial_schema.sql`, attempt an insert with an invalid enum value.

| Table | Constraint | Valid Value | Invalid Value | Expected |
|-------|-----------|-------------|---------------|----------|
| user_profiles | valid_goal | `'build_strength'` | `'lose_weight'` | CHECK violation, insert rejected |
| user_profiles | valid_fitness_level | `'beginner'` | `'expert'` | Rejected |
| user_profiles | valid_time_preference | `'10-15'` | `'5-10'` | Rejected |
| user_profiles | valid_workout_pace | `'relaxed'` | `'fast'` | Rejected |
| user_profiles | valid_subscription_tier | `'premium_monthly'` | `'trial'` | Rejected |
| workout_history | valid_discipline | `'strength'` | `'pilates'` | Rejected |
| workout_history | valid_source | `'smart'` | `'ai'` | Rejected |
| workout_history | valid_manual_workout_type | `NULL` (allowed), `'cardio'` | `'swimming'` | Rejected |
| workout_history | valid_manual_body_area | `NULL` (allowed), `'core'` | `'arms'` | Rejected |
| workout_history | valid_manual_intensity | `NULL` (allowed), `'light'` | `'extreme'` | Rejected |
| workout_exercises | valid_exercise_status | `'completed'` | `'paused'` | Rejected |

### CASCADE Delete Verification
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Delete user_profiles cascades to workout_history | Create profile + 3 workouts. Delete profile via service role (bypassing RLS) | All 3 workout_history rows deleted |
| Delete workout_history cascades to workout_exercises | Create workout + 5 exercises. Delete the workout row | All 5 workout_exercises rows deleted |
| Full cascade chain | Create profile + workout + exercises. Delete profile | All workout_history AND workout_exercises rows deleted |
| Cascade does not cross users | User A and User B both have data. Delete User A's profile | User B's workouts and exercises untouched |

### NULL Handling
| Test Case | Steps | Expected |
|-----------|-------|----------|
| exercise_id nullable | Insert workout_exercise with `exercise_id = NULL` | Succeeds (v1.1 manual logging compatibility) |
| exercise_id with value | Insert workout_exercise with `exercise_id = 'ex_001'` | Succeeds |
| display_name nullable | Insert user_profiles with `display_name = NULL` | Succeeds |
| required fields reject NULL | Insert user_profiles with `goal = NULL` | NOT NULL violation |
| manual fields nullable | Insert workout_history with all manual fields NULL | Succeeds (non-manual entry) |
| rep_target nullable | Insert workout_exercise with `rep_target = NULL` | Succeeds (time-based exercise) |

### Index Existence Verification
Run against the database and confirm these indexes exist:

```sql
SELECT indexname FROM pg_indexes WHERE tablename IN ('workout_history', 'workout_exercises');
```

Expected indexes:
- `idx_workout_history_user_id` on `workout_history(user_id)`
- `idx_workout_history_completed_at` on `workout_history(completed_at DESC)`
- `idx_workout_exercises_workout_id` on `workout_exercises(workout_id)`

### updated_at Trigger
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Insert sets updated_at | Insert user_profiles row | `updated_at` equals `created_at` (both `now()`) |
| Update bumps updated_at | Update `display_name` on existing profile. Compare `updated_at` before and after | `updated_at` is later than before; `created_at` unchanged |
| Trigger only on user_profiles | Confirm no `updated_at` trigger on workout_history or workout_exercises | Only `set_user_profiles_updated_at` trigger exists |

---

## 5. Storage Testing

### Public Bucket Access
Exercise assets (thumbnails + looping animations) are served from a Supabase Storage public bucket. No auth is required -- both free and premium users access the same assets.

| Test Case | Steps | Expected |
|-----------|-------|----------|
| Unauthenticated access | GET a known asset URL with no auth headers | 200, file returned |
| Authenticated access | GET the same URL with a valid JWT | 200, same file (auth is accepted but not required) |
| Anon key access | GET with anon key in `apikey` header | 200 |
| Non-existent file | GET a path that does not exist | 400 or 404 (Supabase returns 400 for missing objects in public buckets) |

### Asset URL Construction
Per architecture.md Section 13, asset URLs are constructed from a base URL + relative path from `exercises.json`:

```
{SUPABASE_URL}/storage/v1/object/public/{BUCKET_NAME}/{relative_path}
```

| Test Case | Steps | Expected |
|-----------|-------|----------|
| URL pattern matches | Construct URL from `EnvironmentConfig.storageBaseURL` + exercise relative path | Resolves to valid asset |
| Thumbnail URL valid | Fetch a thumbnail URL from exercises.json, request it | 200, image data returned |
| Animation URL valid | Fetch an animation URL, request it | 200, animated WebP data returned |

### Cache Headers
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Cache-Control present | GET a public asset | Response includes `Cache-Control` header |
| CDN caching | Request same asset twice from different IP/region (if testable) | Second request served from edge cache (verify via `cf-cache-status` or `x-cache` header if available) |

### File Size Limits
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Thumbnails under budget | Check size of all thumbnail assets | Each under defined budget (establish budget based on performance testing -- recommend < 100KB) |
| Animations under budget | Check size of all animation assets | Each under defined budget (recommend < 500KB for 2-5 sec WebP loops) |

### Both Tiers Access Assets
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Free user loads thumbnails | Free user (no auth, no account) requests asset URL | 200 |
| Premium user loads thumbnails | Premium user (authenticated) requests same URL | 200, identical content |
| Free user loads animations | Same as above, with animation URL | 200 |

---

## 6. Data Migration Testing (F-PRO-5)

### Prerequisites
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Consent flow required | Attempt migration without the consent disclosure step | Migration blocked at the app level (consent screen must be shown per Privacy Policy Section 6) |
| Subscription required | Attempt migration as free user | Migration not triggered (subscription purchase is a prerequisite) |
| Account creation required | Attempt migration without `supabase.auth.signUp()` | Migration cannot proceed (no `auth.uid()` to use as profile PK) |

### Happy Path Migration
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Profile migrated | Complete migration flow with a populated local profile | `user_profiles` row exists with all mapped fields matching SwiftData values per migration-path.md schema mapping |
| Workouts migrated | Local user has 5 workouts | All 5 appear in `workout_history` with correct `user_id = auth.uid()` |
| Exercises migrated | Local user has 15 exercises across 5 workouts | All 15 in `workout_exercises` with correct `workout_id` FKs |
| Fields not migrated | Check Supabase profile | `onboardingCompletedAt`, `healthDisclaimerAcknowledgedAt`, `smartRoutineCountThisWeek`, `dataMigratedToCloud` are NOT present in Supabase row |
| Post-migration flag set | Check local `UserProfile` after migration | `dataMigratedToCloud = true` |
| Local data preserved | Check SwiftData after migration | All local records still exist (serve as offline cache) |

### Idempotency (Retry After Failure)
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Retry after network failure | Start migration, kill network mid-request, reconnect, retry | Second attempt succeeds. No duplicate rows. Data is correct |
| Retry after server error | First call returns 500 (simulate). Retry | Second call succeeds. Single set of rows in all tables |
| Double-call prevention | Call `migrateToCloud()` twice in quick succession | `dataMigratedToCloud` flag prevents second execution. Or, if the flag has not been set yet, the RPC handles the PK conflict gracefully |
| Verify no duplicates | After a retry scenario, count rows | Exactly 1 profile, N workouts, M exercises (matching local counts) |

### Schema Mapping Verification
For each row in the mapping tables in `knowledge-base/migration-path.md`:

| Check | Method |
|-------|--------|
| Enum raw values match | Compare SwiftData `goal.rawValue` with Supabase `goal` column. E.g., `FitnessGoal.buildStrength` -> `"build_strength"` |
| Array fields mapped correctly | `equipment = [.mat, .bands]` -> `equipment = '{"mat","bands"}'` in Postgres |
| Nullable fields handled | `displayName = nil` -> `display_name = NULL` |
| Timestamps formatted | `completedAt` as ISO 8601 string -> `completed_at` as `timestamptz` |
| UUIDs preserved | `WorkoutRecord.id` in SwiftData matches `workout_history.id` in Supabase |

---

## 7. Offline Sync Testing (Premium)

**Note**: The `OfflineMutation` model exists in the v1.0 SwiftData schema, but the sync implementation is deferred. These test cases are defined now for use when the feature ships.

### OfflineMutation Outbox Pattern
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Mutation created on offline workout complete | Complete a workout while offline | New `OfflineMutation` record with `mutationType = .workoutCompleted`, JSON payload containing workout + exercise data, `retryCount = 0` |
| Payload completeness | Inspect the mutation JSON payload | Contains all fields needed to reconstruct the `workout_history` + `workout_exercises` inserts server-side |
| Multiple offline workouts | Complete 3 workouts offline | 3 separate `OfflineMutation` records, each with unique IDs and timestamps |

### FIFO Replay Order
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Mutations replay in creation order | Create mutations M1, M2, M3 (in that order). Reconnect | M1 syncs first, then M2, then M3 |
| Order verified on server | Check `workout_history.created_at` values | Reflect the original `completedAt` from each mutation, not the sync time |
| No reordering on partial failure | M1 succeeds, M2 fails, M3 is pending | M3 does NOT sync until M2 succeeds. Queue is strictly ordered |

### Retry with Exponential Backoff
| Test Case | Steps | Expected |
|-----------|-------|----------|
| First retry | M1 fails to sync | `retryCount` incremented to 1. Next retry after base delay (e.g., 2 seconds) |
| Exponential increase | M1 fails 3 times | Retry delays increase: ~2s, ~4s, ~8s (verify exponential pattern, exact values depend on implementation) |
| Max retry cap | M1 fails many times | Retry delay caps at a maximum (e.g., 5 minutes). Does not grow unbounded |
| Successful retry clears mutation | M1 fails twice, succeeds on third attempt | `OfflineMutation` record for M1 deleted. M2 begins syncing |

### Conflict Resolution
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Duplicate workout ID | User completes workout offline, network blip causes retry, server already has the record | Server handles gracefully (upsert or conflict detection). No duplicate workout in history |
| Profile updated offline and online | User changes display_name offline; separately, subscription updates server-side | Last-write-wins or merge strategy (define per architecture.md Section 12). No data loss |

### Data Integrity After Sync
| Test Case | Steps | Expected |
|-----------|-------|----------|
| Local matches remote | After all mutations sync, compare local SwiftData records with Supabase rows | Field-by-field match for all synced workouts and exercises |
| Mutation queue empty | After successful sync | Zero `OfflineMutation` records in local store |
| Streak data correct | Complete 3 workouts offline over 3 days, then sync | Streak calculation on server reflects the original `completedAt` dates, not the sync date |
| Workout order preserved | Sync 5 offline workouts | `order_index` on exercises and `completed_at` on workouts match local originals |

---

## Testing Principles (Supabase-Specific)

1. **Always test both client types**: `createUserClient` (RLS applies) and `createAdminClient` (bypasses RLS). A passing admin-client test does not prove the feature works for real users.

2. **Test RLS with two users minimum**: Single-user RLS tests catch nothing. Always verify User A cannot access User B's data.

3. **Test the whole cascade, not just the happy path**: `delete_user_data` and `migrate_user_data` RPCs touch multiple tables in a transaction. Test partial failures to confirm full rollback.

4. **Zod and CHECK constraints are two validation layers**: Zod catches bad input at the Edge Function boundary. CHECK constraints catch bad data at the database boundary. Test both layers independently -- Zod rejects before the query runs, CHECK rejects if Zod is ever bypassed.

5. **Local CLI and remote staging can diverge**: After any migration change, run the full schema test suite against both environments. `supabase db reset` on local does not guarantee remote is in sync.

6. **Edge Function error responses are a contract**: The iOS client parses `ApiResponse<T>`. A malformed error response (wrong shape, missing fields) will crash the client. Test every error path for envelope compliance.

7. **Storage is unauthenticated by design**: Do not add auth gates to storage tests. The public bucket is intentional (per architecture.md Section 13). Test that assets load without auth for both tiers.
