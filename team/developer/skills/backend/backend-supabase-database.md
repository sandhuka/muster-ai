# Supabase Database (PostgreSQL)

## Purpose
SQL patterns and Supabase CLI mechanics for PostgreSQL schema work. This covers the syntax and tooling — see `team/developer/skills/backend-security.md` for RLS design decisions and `team/developer/skills/backend-data-modeling.md` for relational modeling methodology. See `knowledge-base/architecture.md` Section 5 for the target schema.

## Schema Design Rules
- All tables use `uuid` primary keys (Supabase default: `gen_random_uuid()`)
- Every table includes `created_at timestamptz NOT NULL DEFAULT now()` and `updated_at timestamptz NOT NULL DEFAULT now()`
- Use `timestamptz` (not `timestamp`) — always store timezone-aware timestamps
- Foreign keys with explicit `ON DELETE CASCADE` for child tables (e.g., `workout_exercises` -> `workout_history`)
- Use `text` for string columns (not `varchar(n)`) — PostgreSQL treats them identically, `text` avoids arbitrary limits
- Use `text[]` for arrays (e.g., `equipment text[]`, `muscle_groups text[]`)
- Nullable columns: use `NULL` only when absence of value has meaning (e.g., `exercise_id` nullable for v1.1 manual entries where no exercise is linked)
- Default column values where sensible: `DEFAULT false` for booleans, `DEFAULT 'free'` for tier columns
- Table and column names: `snake_case` (PostgreSQL convention, matches Supabase auto-generated API)

## RLS Policy SQL
- Enable RLS on every table: `ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;`
- Standard user isolation policy:
  ```sql
  CREATE POLICY "Users can only access own data"
    ON table_name
    FOR ALL
    USING (auth.uid() = user_id);
  ```
- For child tables without direct `user_id` (e.g., `workout_exercises`), use a join-based policy:
  ```sql
  CREATE POLICY "Users can only access own exercises"
    ON workout_exercises
    FOR ALL
    USING (
      EXISTS (
        SELECT 1 FROM workout_history
        WHERE workout_history.id = workout_exercises.workout_id
        AND workout_history.user_id = auth.uid()
      )
    );
  ```
- Separate policies per operation when needed: `FOR SELECT`, `FOR INSERT`, `FOR UPDATE`, `FOR DELETE`
- Insert policies use `WITH CHECK` (not `USING`):
  ```sql
  CREATE POLICY "Users insert own data"
    ON table_name
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);
  ```
- Deny by default: if RLS is enabled and no policy matches, the row is invisible

## Migrations (Supabase CLI)
- Generate migration: `supabase db diff --schema public -f migration_name`
- Apply migration: `supabase db push`
- Reset local DB: `supabase db reset` (drops and recreates from migrations + seed)
- Migration files live in `supabase/migrations/` — commit to git
- Each migration file is timestamped: `YYYYMMDDHHMMSS_migration_name.sql`
- Migrations are applied in order — never edit an applied migration, create a new one
- Test migrations locally before pushing: `supabase db reset` then verify schema

## Database Functions & RPCs
- Use `CREATE FUNCTION` for operations that must be atomic (e.g., data migration batch insert)
- Call from client via `supabase.rpc('function_name', { params })`
- Functions run with the caller's RLS context unless `SECURITY DEFINER` is specified
- `SECURITY DEFINER` functions run with the function owner's permissions — use sparingly and only for admin operations (e.g., account deletion cascade)
- Always set `SET search_path = public` on `SECURITY DEFINER` functions to prevent path injection
- Return types: use `json` or `jsonb` for complex returns, simple types for scalars

## Indexes
- Primary keys are automatically indexed
- Add indexes on foreign keys used in JOINs: `CREATE INDEX idx_workout_history_user_id ON workout_history(user_id);`
- Add indexes on columns used in WHERE/ORDER BY: `CREATE INDEX idx_workout_history_completed_at ON workout_history(completed_at DESC);`
- Composite indexes for multi-column queries: column order matters — put equality conditions first, range conditions last
- Don't over-index: each index adds write overhead. Index what you query, not everything

## Enum & Type Patterns
- Use PostgreSQL enums for fixed, application-defined value sets:
  ```sql
  CREATE TYPE fitness_goal AS ENUM ('build_strength', 'improve_flexibility', 'general_fitness', 'stress_relief', 'stay_active');
  ```
- Alternative: use `text` column with a CHECK constraint for smaller sets or when enum evolution is frequent:
  ```sql
  ALTER TABLE user_profiles ADD CONSTRAINT valid_goal
    CHECK (goal IN ('build_strength', 'improve_flexibility', 'general_fitness', 'stress_relief', 'stay_active'));
  ```
- PostgreSQL enums require a migration to add new values (`ALTER TYPE ... ADD VALUE`). CHECK constraints are easier to modify but lack type safety
- For this project: prefer `text` + CHECK constraints (per architecture.md — easier to evolve without migration headaches)
- `text[]` array columns: use `@>` operator for "contains" queries: `WHERE equipment @> ARRAY['bands']::text[]`

## Auto-Timestamp Trigger
- Create a reusable trigger function for `updated_at`:
  ```sql
  CREATE OR REPLACE FUNCTION update_updated_at()
  RETURNS TRIGGER AS $$
  BEGIN
    NEW.updated_at = now();
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql;
  ```
- Apply to each table:
  ```sql
  CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON table_name
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
  ```

## Principles
1. **RLS on every table, no exceptions**: Even if a table seems internal-only today, enable RLS. It's the last line of defense — if a client bug bypasses application logic, RLS still protects data.
2. **Migrations are append-only**: Never edit a migration that's been applied to any environment. Create a new migration to correct mistakes. This prevents drift between environments.
3. **Text over varchar, CHECK over enum**: Use `text` columns with CHECK constraints instead of PostgreSQL enums. CHECKs are easier to modify in a migration. Enums require `ALTER TYPE ... ADD VALUE` which can't run inside a transaction.
4. **Index what you query**: Don't pre-create indexes on every column. Wait until you have real query patterns, then add targeted indexes. Each index has write-time cost.
