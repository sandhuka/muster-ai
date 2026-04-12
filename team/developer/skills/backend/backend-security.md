# Backend Security

## Purpose
Security design patterns and decision-making for the Supabase backend. This covers when and why to apply security measures -- see `team/developer/skills/backend-supabase-database.md` for RLS SQL syntax and `team/developer/skills/backend-supabase-auth.md` for auth configuration. See `team/developer/skills/ios-security.md` for client-side security (Keychain, biometrics). See `knowledge-base/architecture.md` Section 8 for RLS policy details and `knowledge-base/legal/privacy-policy-draft.md` for data privacy requirements.

## RLS Policy Design Patterns

1. **Deny by default**: When RLS is enabled on a table with no policies, all rows are invisible. Start from zero access and add policies explicitly.

2. **Per-user isolation**: Every user-facing table gets a policy matching `auth.uid() = user_id`. This is the foundational pattern -- no user can read or modify another user's data.

3. **Join-based child policies**: For child tables without a direct `user_id` column (e.g., `workout_exercises`), use an EXISTS subquery joining to the parent table. See `team/developer/skills/backend-supabase-database.md` for the SQL syntax.

4. **Operation-specific policies**: Use `FOR SELECT`, `FOR INSERT`, `FOR UPDATE`, `FOR DELETE` when different operations need different rules. Example: users can INSERT and SELECT their own data but cannot DELETE workout history (soft-delete via app logic instead).

5. **Service role bypass**: The service role key bypasses ALL RLS. This is by design -- use it only in Edge Functions for admin operations. Never expose it to the client.

6. **Testing RLS**: Test with the anon key (should be blocked without auth), with a valid user JWT (should see only own data), and with service role (should see everything). Cover all three in integration tests.

## API Security

1. **Input validation**: Validate every Edge Function input with `zod` before processing. Reject invalid requests with 400 -- never pass unvalidated input to a database query.

2. **Parameterized queries**: Always use Supabase client methods (`.select()`, `.insert()`, `.eq()`) which parameterize automatically. Never construct SQL strings with template literals or string concatenation.

3. **Rate limiting**: Supabase applies built-in rate limits on auth endpoints. For Edge Functions, rely on Supabase's infrastructure rate limiting for MVP. Add application-level rate limiting (per-user, per-endpoint) if abuse patterns emerge post-launch.

4. **Response sanitization**: Never expose internal errors (SQL error messages, table names, stack traces) to the client. Log the full error server-side, return a generic error message to the client.

5. **Request size limits**: Deno's `req.json()` has a default body size limit. For the algorithm endpoint, enforce the 50KB payload limit explicitly by checking `Content-Length` header before parsing.

## Secrets Management

1. **Service role key**: Set via `supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...`. Access via `Deno.env.get()` in Edge Functions. Never log, never include in responses, never commit to git.

2. **API keys in client**: Only the anon key goes in the iOS app (stored in `.xcconfig`, accessed via `EnvironmentConfig`). The anon key is safe to "expose" because all access is RLS-gated.

3. **Git exclusions**: `.xcconfig` files, `.env` files, and any file containing keys must be in `.gitignore`. Commit only `.xcconfig.template` with placeholder values.

4. **Key rotation**: If a service role key is compromised, rotate immediately in Supabase Dashboard (Settings > API) and update via `supabase secrets set`. Anon key rotation is less critical (RLS protects data) but should still be rotated if leaked alongside other credentials.

## Access Control (Free vs Premium)

1. **Free tier**: No authentication, no server-side user data. Free users interact with Supabase Storage public bucket (exercise assets -- no auth needed) and nothing else on the server. All user data is local (SwiftData).

2. **Premium tier**: Authenticated users with full server access -- RLS-protected PostgreSQL tables (user_profiles, workout_history, workout_exercises), Edge Functions (algorithm generation, data migration), and Supabase Storage public bucket (same as free -- no difference for assets).

3. **Subscription validation**: StoreKit 2 transaction is the source of truth on the client. Server-side: validate Apple receipt via Edge Function before granting premium database access. Store `subscription_tier` and `subscription_expires_at` in `user_profiles`.

4. **Downgrade handling**: When subscription expires, the client reverts to free-tier behavior (local algorithm, no sync). Server data is retained (not deleted) -- user can re-subscribe and resume. RLS still protects the data even if the client has a stale JWT.

## Apple Receipt Validation

1. **Flow**: Client sends Apple receipt data to Edge Function (with service role) which validates receipt with Apple's servers and updates `user_profiles.subscription_tier` and `subscription_expires_at`.

2. **Server-side only**: Never trust the client's claim of subscription status. The client can check `Transaction.currentEntitlements` for UI, but the server must independently validate.

3. **Validation endpoint**: Apple's App Store Server API v2. Use server-to-server notifications for real-time subscription events (renewal, cancellation, refund).

4. **Store receipt data**: Save encrypted `apple_receipt_data` in `user_profiles` for re-validation if needed.

5. **Edge cases**: Handle receipt validation failure gracefully -- do not revoke access immediately on a single failure. Retry validation, and only downgrade after persistent failure (e.g., 3 consecutive failed validations over 24 hours).

## Principles

1. **Defense in depth**: RLS is the last line of defense, not the only line. Validate input in Edge Functions, parameterize queries, sanitize responses, AND enforce RLS. Each layer catches what the others miss.

2. **Least privilege by default**: Every key, policy, and permission should grant the minimum access needed. Anon key for client operations, service role only in Edge Functions for admin tasks. No table should be accessible without an explicit policy.

3. **Free tier touches nothing sensitive**: Free users have zero server-side footprint for user data. They access only the public Storage bucket. This simplifies the security model -- if a free user somehow sends a request to an RLS-protected endpoint, RLS blocks it because there is no `auth.uid()`.

4. **Log security events**: Every service-role operation, every failed auth attempt, every receipt validation should be logged server-side. These logs are the audit trail for investigating security incidents.
