# Backend Data Modeling

## Purpose
Relational schema design methodology for mobile app backends. This covers the design thinking -- see `team/developer/skills/backend-supabase-database.md` for SQL implementation syntax. See `team/developer/skills/ios-swiftdata.md` for the local SwiftData schema that mirrors the cloud schema. See `knowledge-base/architecture.md` Sections 5 and 10 for the target data model and migration flow. See `knowledge-base/legal/privacy-policy-draft.md` for data retention and deletion requirements.

## Schema Design for Mobile Apps
- **Normalize for writes, denormalize for reads**: Mobile apps read far more than they write. Normalize core tables (user_profiles, workout_history, workout_exercises) for data integrity, but consider denormalized read views for frequently-queried aggregations (e.g., weekly summary).
- **Mirror local and cloud schemas**: SwiftData models and Supabase tables must have a 1:1 field mapping to enable clean data migration. Use the same field names (Swift camelCase maps to PostgreSQL snake_case via naming convention -- no manual mapping).
- **UUID primary keys everywhere**: Both SwiftData and Supabase use UUIDs. Client generates IDs for new records (enables offline creation + deduplication on sync). Never use auto-increment -- it doesn't work across local/cloud.
- **Flat over nested for mobile queries**: Avoid deep table hierarchies. Two levels (parent -> child, e.g., workout_history -> workout_exercises) is the practical max for mobile query performance and sync simplicity.
- **Nullable means optional, not unknown**: A nullable column means "this field may not apply" (e.g., `exercise_id` nullable for manual entries in v1.1). Don't use nullable as a lazy default -- if a field should always have a value, make it NOT NULL with a sensible default.

## Audit Trails & Timestamps
- Every table gets `created_at` and `updated_at` (both `timestamptz NOT NULL DEFAULT now()`).
- `updated_at` is maintained by a database trigger (see `team/developer/skills/backend-supabase-database.md` for the trigger SQL).
- These columns serve three purposes: debugging (when was this created?), sync ordering (which version is newer?), and data retention enforcement (when was this last touched?).
- Never update `created_at` -- it is the immutable birth timestamp.
- For sync conflict resolution, `updated_at` is the tiebreaker: server timestamp wins for plan/schedule data.

## Soft Deletes & Data Retention
- **Soft delete pattern**: Add `deleted_at timestamptz NULL` to tables where data recovery may be needed. A non-null `deleted_at` means "logically deleted." Queries filter with `WHERE deleted_at IS NULL`.
- **When to soft delete vs hard delete**: Soft delete for user-initiated deletion (workout history -- user might want to undo). Hard delete for system-initiated cleanup (expired sessions, orphaned records) and GDPR/CCPA "right to be forgotten" requests.
- **Data retention periods** (per legal drafts):
  - Server logs: 90 days.
  - Inactive accounts: 24-month threshold with email notice before deletion.
  - Post-deletion backup retention: 30 days.
- **Retention enforcement**: A scheduled Edge Function or database cron (`pg_cron`) scans for accounts past the inactivity threshold. Sends warning email at 23 months, hard-deletes at 24 months.

## GDPR/CCPA Deletion Compliance
- **Account deletion flow** (F-PRO-4): User requests deletion -> Edge Function (service role) cascades delete across all tables -> confirms deletion in response.
- **Cascade strategy**: `ON DELETE CASCADE` on foreign keys handles child records automatically. For `user_profiles` deletion: workout_history cascades -> workout_exercises cascades (two-level cascade).
- **What to delete**: All rows in user_profiles, workout_history, workout_exercises for the user. Revoke Supabase Auth session. Remove any Storage objects in private buckets (none for MVP).
- **What to anonymize** (not delete): Analytics events can be retained if anonymized (strip user_id, keep aggregate data). Per legal draft: anonymized data is no longer personal data.
- **Confirmation**: The deletion RPC returns a success/failure status. Client shows confirmation. Log the deletion event server-side (without PII) for audit trail.
- **Timing**: Deletion must complete within 30 days of request per CCPA. Implement as immediate (synchronous RPC), not batched.

## Local-to-Cloud Migration Schema
- **Trigger**: User purchases subscription -> creates account -> one-time migration.
- **Mapping**: Each SwiftData model maps to one Supabase table:
  - `UserProfile` (SwiftData) -> `user_profiles` (Supabase).
  - `WorkoutRecord` (SwiftData) -> `workout_history` (Supabase).
  - `WorkoutExerciseRecord` (SwiftData) -> `workout_exercises` (Supabase).
- **Atomic batch insert**: Wrap all inserts in a single database transaction via Supabase RPC function. Either all records migrate or none do -- no partial state.
- **Deduplication**: Use client-generated UUIDs as primary keys. If migration is retried (e.g., after a network failure), the RPC uses `ON CONFLICT (id) DO NOTHING` to skip duplicates.
- **Migration flag**: `UserProfile.dataMigratedToCloud: Bool` (local SwiftData flag). Set to `true` only after successful migration confirmation from server. Prevents re-migration.
- **Consent**: Per privacy policy Section 6, data migration requires explicit user consent disclosure before proceeding.

## Principles
1. **Schema is a contract**: The database schema is a contract between the client and server. Changing a column name, type, or nullability is a breaking change that requires coordinated migration on both sides. Treat schema changes like API versioning.
2. **Delete means delete**: For GDPR/CCPA compliance, "deleted" means the data is gone -- not soft-deleted, not archived, not moved to a cold table. Use hard delete with CASCADE for deletion requests. Soft deletes are for user convenience (undo), not for compliance.
3. **Mirror, don't translate**: Local SwiftData models and Supabase tables use the same field names (adjusted for language convention: camelCase <-> snake_case). No field renaming, no structural differences. This makes migration a simple field-by-field copy, not a transformation.
4. **Client-generated IDs are non-negotiable**: In a local-first architecture, the client must be able to create records offline with globally unique IDs. Server-generated auto-increment IDs break this model. UUIDs everywhere.
