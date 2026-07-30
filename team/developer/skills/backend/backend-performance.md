# Backend Performance

## Purpose
Performance measurement and optimization patterns for the Supabase backend. See the `backend-supabase-database` skill for index syntax and query patterns. See the `backend-supabase-edge-functions` skill for cold start context. See the `backend-supabase-storage` skill for CDN caching configuration. See `knowledge-base/architecture.md` Section 7 for the 5-second Edge Function budget and 50KB payload limit.

## Query Optimization
- **EXPLAIN ANALYZE**: Run `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)` on every new query during development. Look for: sequential scans on large tables (add index), nested loop joins on large result sets (consider hash join), high buffer reads (cache miss).
- **Query planner basics**: PostgreSQL chooses between sequential scan, index scan, and bitmap scan. For tables under ~1000 rows, sequential scan is often faster than index scan -- do not force indexes on small tables.
- **SELECT only what you need**: Never `SELECT *` in production queries. List explicit columns. Reduces network transfer, memory usage, and makes the query plan more efficient.
- **Batch over loop**: Never execute queries in a loop (`for each item -> query`). Use `IN` clauses, JOINs, or batch operations. One query returning 50 rows is faster than 50 queries returning 1 row each.
- **Aggregation in SQL, not code**: Use `COUNT()`, `SUM()`, `AVG()`, `GROUP BY` in PostgreSQL instead of fetching rows and aggregating in TypeScript. The database is optimized for this; your Edge Function is not.

## Connection Pooling
- **Supavisor**: Supabase's built-in connection pooler (replaces PgBouncer). All connections from Edge Functions go through Supavisor automatically.
- **Transaction mode** (default for Edge Functions): Connection returned to pool after each transaction. Best for short-lived serverless functions. Use this mode -- it is the Supabase default for Edge Functions.
- **Session mode** (for migrations): Connection persists for the entire session. Required for operations that use prepared statements or session-level settings. Use for migration scripts, not for Edge Functions.
- **Connection limits**: Free tier: 15 direct connections, 200 pooled. Pro tier: more. Edge Functions should always use the pooled connection string (port 6543, not 5432).
- **Connection string**: Use `Deno.env.get("SUPABASE_DB_URL")` in Edge Functions only when you need direct PostgreSQL access (rare -- prefer the Supabase JS client which handles pooling automatically).

## Edge Function Performance
- **Cold start**: First invocation after idle period takes longer (500ms-2s). Subsequent invocations reuse the warm instance.
- **Minimize cold start impact**: Keep imports minimal -- only import what the function uses. Avoid large dependencies (heavy ORMs, ML libraries). Use the Supabase JS client (lightweight) instead of a full PostgreSQL driver. Shared code in `_shared/` is fine -- it is bundled at deploy time, not fetched at runtime.
- **Execution budget**: 5 seconds total for the algorithm endpoint (architecture constraint). Budget allocation: auth verification ~100ms, database queries ~2-3s (the bulk), algorithm computation ~1-2s, response serialization ~50ms.
- **Payload size**: Keep responses under 50KB (architecture constraint). A typical routine response with 8-12 exercises is well within this limit. If approaching the limit, paginate or trim unnecessary fields.
- **Memory**: Edge Functions have a memory limit (varies by Supabase plan). Avoid loading large datasets into memory. Stream or paginate large result sets.

## Caching Strategies
- **Edge Function responses**: No built-in server-side caching for Edge Functions. The iOS client caches the latest routine response locally -- this is the primary cache layer.
- **Storage CDN**: Supabase Storage serves assets through a CDN with automatic edge caching. Set appropriate `Cache-Control` headers (see the `backend-supabase-storage` skill).
- **Database-level caching**: PostgreSQL has a built-in buffer cache. Frequently-accessed rows are cached in memory automatically. No manual configuration needed for MVP scale.
- **Materialized views**: For expensive read-heavy aggregations (e.g., weekly workout summary), consider PostgreSQL materialized views that refresh on schedule. Defer until query performance becomes an issue -- premature optimization for MVP.

## N+1 Prevention
- **The problem**: Fetching a list of workouts, then fetching exercises for each workout in a loop = N+1 queries.
- **Solution**: Always JOIN or batch-fetch related data in a single query. Example: `SELECT wh.*, we.* FROM workout_history wh LEFT JOIN workout_exercises we ON we.workout_id = wh.id WHERE wh.user_id = $1 ORDER BY wh.completed_at DESC LIMIT 20;`
- **Supabase JS client**: Use `.select('*, workout_exercises(*)')` for auto-joined queries -- the client generates the JOIN for you.
- **Detection**: If an Edge Function makes more than 3 database calls, review whether they can be combined. More than 5 is almost certainly an N+1.

## Timeout Budgets
| Operation | Timeout | Fallback |
|-----------|---------|----------|
| Edge Function (routine generation) | 5s total | Client falls back to cached routine, then on-device basic algorithm |
| Database query within Edge Function | 3s | Return partial result or error |
| Edge Function (plan generation) | 5s total | Client falls back to cached 7-day plan |
| PostgreSQL direct operations | 10s | Queue for retry |
| Data migration (batch insert) | 30s | Retry prompt, local data preserved as fallback |
| Storage asset download (client-side) | 10s | Show placeholder silhouette |

## Principles
1. **Measure before optimizing**: Run EXPLAIN ANALYZE on every query during development. Do not guess at performance -- measure it. Add indexes based on observed slow queries, not speculation.
2. **Cold starts are the tax, not the cost**: The real performance cost in Edge Functions is database queries, not cold starts. Optimize query count and query efficiency first. Cold start mitigation (minimal imports) is secondary.
3. **Budget your 5 seconds**: The algorithm endpoint has a hard 5-second budget. Allocate it explicitly: auth (~100ms), DB queries (~2-3s), computation (~1-2s), serialization (~50ms). If any stage exceeds its budget, investigate before adding more stages.
4. **Fewer queries, not faster queries**: Reducing query count (N+1 elimination, JOINs, batch operations) almost always yields bigger gains than optimizing individual query speed. Go from 50 queries to 1 before adding indexes.
