# Backend Deployment & Environments

## Purpose
Operational workflows for managing Supabase environments, migrations, and deployments. This covers the how of deploying — see the `backend-supabase-database` skill for migration SQL patterns and the `backend-supabase-edge-functions` skill for function deployment details. See the `code-standards` skill for git workflow conventions. See `knowledge-base/architecture.md` for the production schema as target state.

## Environment Strategy
- **Local development**: `supabase start` spins up a full local Supabase stack (PostgreSQL, Auth, Storage, Edge Functions) via Docker. Develop and test entirely offline
- **Production**: Linked Supabase project (us-east-1). The only remote environment for MVP
- **No staging for MVP**: A staging environment adds operational overhead for a solo founder. Use local development for all testing. Add staging when there are multiple contributors or when production data makes local testing insufficient
- **Link production**: `supabase link --project-ref <project-id>` (one-time setup). All subsequent CLI commands target this project
- **Environment parity**: Local Supabase mirrors production schema via migrations. The same migration files run in both environments. Drift = bugs

## Migration Workflow
1. Make schema changes locally (edit SQL or use Dashboard at `localhost:54323`)
2. Generate migration file: `supabase db diff --schema public -f descriptive_name`
3. Review the generated SQL in `supabase/migrations/YYYYMMDDHHMMSS_descriptive_name.sql`
4. Test locally: `supabase db reset` (drops and recreates from all migrations + seed)
5. Commit migration file to git
6. Apply to production: `supabase db push`
7. Verify: check production schema in Supabase Dashboard

- **Never edit applied migrations**: If a migration has been pushed to production, create a new corrective migration instead. Editing an applied migration causes drift between environments
- **One concern per migration**: Each migration file should address one logical change (add a table, add an index, modify a policy). Don't combine unrelated changes
- **Naming convention**: Use descriptive names: `create_user_profiles`, `add_rls_workout_history`, `add_index_completed_at`. The timestamp prefix handles ordering

## Seed Data
- Seed file: `supabase/seed.sql` — runs after migrations during `supabase db reset`
- Purpose: populate local dev with realistic test data (sample users, workout history, exercises)
- Seed data should cover:
  - At least 2 user profiles (one with workout history, one fresh)
  - 10-20 workout history records spanning 2+ weeks
  - Corresponding workout_exercises for each history record
  - All enum/text constraint values represented (every goal, fitness level, discipline)
- Keep seed data minimal but representative — enough to test all query paths
- Never include real user data or production secrets in seed files
- Seed file is committed to git (no sensitive data)

## Edge Function Deployment
- Deploy single function: `supabase functions deploy <function-name>`
- Deploy all functions: `supabase functions deploy`
- Set secrets before first deploy: `supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...`
- Verify deployment: Supabase Dashboard > Edge Functions > check status and recent invocations
- Deployments are atomic — new version replaces old with zero downtime
- Rollback: redeploy the previous git version of the function (`git checkout <commit> -- supabase/functions/<name>/index.ts && supabase functions deploy <name>`)

## Rollback Procedures
- **Schema rollback**: Write a new migration that reverses the change (e.g., `DROP TABLE`, `ALTER TABLE DROP COLUMN`). Apply with `supabase db push`. Never use `supabase db reset` on production
- **Edge Function rollback**: Check out the previous version from git and redeploy
- **Full environment rollback**: Not supported by Supabase as a single action. Roll back schema + functions individually
- **Before any production change**: Verify the change locally first. Have the rollback migration written (but not applied) before pushing the forward migration. This is your safety net

## Supabase CLI Reference
| Command | Purpose |
|---------|---------|
| `supabase start` | Start local Supabase stack (Docker) |
| `supabase stop` | Stop local stack |
| `supabase db reset` | Drop + recreate local DB from migrations + seed |
| `supabase db diff --schema public -f name` | Generate migration from local schema changes |
| `supabase db push` | Apply pending migrations to linked project |
| `supabase functions serve` | Serve Edge Functions locally (hot reload) |
| `supabase functions deploy [name]` | Deploy Edge Function(s) to production |
| `supabase secrets set KEY=value` | Set environment variable for Edge Functions |
| `supabase secrets list` | List set secrets (names only, not values) |
| `supabase link --project-ref <id>` | Link CLI to a Supabase project |
| `supabase storage cp local sb://bucket/path` | Upload file to Storage |

## Principles
1. **Local-first development**: Do all development and testing against the local Supabase stack. Production is for production. The local stack is fast, free, and resettable — use it aggressively.
2. **Migrations are the schema source of truth**: The production database schema is defined by the ordered set of migration files in git. If it's not in a migration file, it doesn't exist. Never make manual schema changes via the production Dashboard.
3. **Rollback before you push**: Write the rollback migration before applying the forward migration to production. You may never need it, but when you do, you need it immediately — not after 30 minutes of panicked SQL writing.
4. **No staging until you need it**: A solo founder running a single Supabase project doesn't need staging. Local development provides fast iteration. Add staging when the cost of a production mistake exceeds the cost of maintaining a second environment.
