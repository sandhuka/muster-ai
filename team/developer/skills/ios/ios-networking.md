# iOS Networking & Backend Integration

## Purpose
Define patterns for Supabase client integration, authentication flows, Edge Functions, and offline sync on iOS. This file covers Supabase as the backend — adapt or replace if using a different backend provider. See `team/developer/skills/ios-best-practices.md` for the hybrid local/cloud architecture overview. See `team/developer/skills/ios-swiftdata.md` for the local-to-cloud data migration pattern.

## Supabase Client Setup
- Use the official `supabase-swift` SDK
- Initialize `SupabaseClient` once at app launch with project URL and anon key from `EnvironmentConfig` (see `team/developer/skills/ios-best-practices.md` Build Environments)
- Store the client as a singleton or inject via environment
- Never expose the service role key in the client app — anon key + Row Level Security only

## Authentication
- **Deferred auth**: No sign-in required at install or during free usage. Auth is triggered only when the user purchases a subscription
- **Email/password flow**: Use `supabase.auth.signUp()` and `supabase.auth.signIn()`. Handle email verification if enabled
- **Session persistence**: Supabase SDK handles token storage and refresh automatically. Check `supabase.auth.session` on app launch to restore state
- **Sign-out**: Clear local auth state. Local data persists (user can still use free tier)
- **Account deletion**: Must wipe server-side data (Supabase RPC or Edge Function), revoke session, and clear local auth state. Local data optionally preserved for continued free-tier use

## Edge Functions
- Use for server-side logic that free users don't need (premium algorithm, cross-device sync)
- Call via `supabase.functions.invoke("function-name", body: requestBody)`
- Define shared request/response types between client and Edge Function — same input/output shape for local and remote algorithm
- Handle function errors: network failure, auth expiry, function-level errors. Map all to user-friendly messages
- Timeout: set reasonable client-side timeout (15s for algorithm, 30s for data migration)

## Offline Handling
- **Detection**: Monitor network reachability via `NWPathMonitor`
- **Queue mutations**: When offline, persist pending operations (task completions, preference changes) to a local queue (SwiftData model)
- **Sync on reconnect**: When connectivity returns, replay the queue in order. Use idempotent operations server-side to handle duplicate replays safely
- **Conflict resolution**: Server wins for plan/schedule data. Client wins for user-generated data (user's device is source of truth for what they actually did)
- **UI feedback**: Show a subtle offline indicator. Never block the user from completing their current action because of connectivity

## API Contract Patterns
- Define Swift `Codable` structs for all request/response types
- Use `JSONDecoder` with `.convertFromSnakeCase` key strategy to match Supabase/PostgreSQL conventions
- Centralize error mapping in a single `NetworkError` enum — map HTTP status codes + Supabase error codes to user-facing messages
- Never expose raw server errors to the user

## Principles

1. **Offline-first for user actions**: The user must never be blocked from completing their current activity due to connectivity. Queue everything, sync later.

2. **Idempotent operations**: Every mutation sent to the server must be safe to replay. Use unique client-generated IDs for operations so the server can deduplicate.

3. **Auth is a premium feature**: The networking layer must gracefully handle the no-auth state. All Supabase calls should check subscription/auth state before attempting and fall back to local paths.
