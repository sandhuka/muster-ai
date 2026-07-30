# Supabase Auth Configuration

## Purpose
Server-side authentication configuration and patterns for Supabase Auth. See the `ios-networking` skill for client-side auth integration (Swift SDK). See the `backend-security` skill for auth-related security design. See `knowledge-base/architecture.md` Section 9 for the full authentication and subscription flow.

## Auth Setup & Configuration
- Provider: Email/password (only provider for MVP)
- Enable in Supabase Dashboard: Authentication > Providers > Email
- Email confirmation: disable for MVP (reduces friction at subscription time) -- revisit post-launch
- Password requirements: minimum 8 characters (Supabase default, adequate for MVP)
- Auto-confirm: enable (skips email verification step)
- OAuth providers (Apple Sign-In, Google): deferred to post-MVP. Architecture supports adding providers without schema changes
- Rate limiting: Supabase applies built-in rate limits on auth endpoints (default: 30 requests/hour per IP for sign-up)

## JWT & Session Management
- Supabase Auth issues JWTs on sign-in with `auth.uid()` embedded as the `sub` claim
- JWT lifetime: 3600 seconds default (1 hour). Supabase SDK handles automatic refresh using the refresh token
- In Edge Functions, extract the user from the request:
  ```typescript
  const authHeader = req.headers.get("Authorization");
  const { data: { user }, error } = await supabase.auth.getUser(authHeader?.replace("Bearer ", ""));
  ```
- `auth.uid()` in RLS policies reads directly from the JWT -- no additional DB lookup
- Never decode JWTs manually in Edge Functions -- always use `supabase.auth.getUser()` which validates the token server-side
- Refresh tokens are long-lived and stored securely by the client (iOS Keychain via supabase-swift SDK)

## Service Role vs Anon Key
- **Anon key**: Public, safe to embed in client app. All operations gated by RLS policies. This is what the iOS app uses
- **Service role key**: Full database access, bypasses RLS. NEVER in client code. Only in Edge Function environment variables (`Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")`)
- Use service role in Edge Functions for:
  - Admin operations (account deletion cascade, data migration validation)
  - Apple receipt validation (writing subscription state to `user_profiles`)
  - Any operation that needs to read/write across user boundaries
- Set service role key via: `supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-key`
- Create a service-role Supabase client in Edge Functions:
  ```typescript
  import { createClient } from "@supabase/supabase-js";
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );
  ```

## Deferred Auth Pattern
- Free tier users have NO account, NO authentication, NO server-side data
- Auth is triggered ONLY at subscription purchase time (StoreKit 2 transaction success -> present sign-up screen)
- Implications for backend:
  - All RLS-protected tables are premium-only (free users never touch them)
  - The public Storage bucket (exercise assets) requires no auth -- free users access it directly
  - Edge Functions (algorithm endpoint) require a valid auth token -- free users never call them
  - No anonymous auth -- free users are truly unauthenticated, not "anonymous users" in Supabase's model

## Apple Sign-In (Future)
- Deferred to post-MVP but architecture is ready
- Server-side flow: client sends Apple identity token -> Edge Function validates with Apple's public keys -> creates or links Supabase user via `supabase.auth.admin.createUser()` or `signInWithIdToken()`
- Requires: Apple Developer account configuration, auth provider enabled in Supabase Dashboard
- No schema changes needed -- `user_profiles.id` is already `auth.uid()` regardless of provider

## Principles
1. **Auth is a premium feature, not a prerequisite**: The app must work completely without authentication. Never add auth checks to flows that free users touch. The only auth gate is the subscription purchase.
2. **Service role is a loaded gun**: Treat the service role key like a database root password. It bypasses all RLS. Only use it in Edge Functions for operations that genuinely need cross-user access. Log every service-role operation for audit.
3. **Validate server-side, trust nothing from the client**: Apple receipts, subscription status, and user identity must all be validated server-side. The client's claim of "I'm premium" is not authoritative -- the server checks the receipt and sets the subscription state.
4. **JWT extraction, not decoding**: In Edge Functions, use `supabase.auth.getUser()` to validate and extract user identity. Never manually parse JWTs -- the SDK handles signature verification, expiration checks, and token refresh.
