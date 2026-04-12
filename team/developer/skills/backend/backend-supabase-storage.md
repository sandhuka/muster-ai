# Supabase Storage

## Purpose
Storage bucket configuration, file organization, and CDN patterns for Supabase Storage. This covers the server-side setup — see `team/developer/skills/ios-best-practices.md` for client-side asset loading and cache patterns. See `team/developer/skills/backend-security.md` for storage access policy decisions. See `knowledge-base/architecture.md` Section 13 for the exercise asset pipeline specification.

## Bucket Configuration
- **Public bucket** (`exercise-assets`): World-readable, no authentication required. Used for exercise thumbnails and animation loops. Both free and premium users access this bucket
  - Create via Dashboard: Storage > New Bucket > Name: `exercise-assets` > Public: ON
  - Or via SQL: `INSERT INTO storage.buckets (id, name, public) VALUES ('exercise-assets', 'exercise-assets', true);`
- **Private buckets** (future): For user-uploaded content if needed. Requires RLS policies on `storage.objects` table. Not needed for MVP
- Public buckets have no RLS — anyone with the URL can read. This is intentional for non-sensitive content (exercise animations are not user data)
- Upload permission: restrict to service role only (admin uploads via CLI or Edge Function, never client-side for exercise assets)

## File Organization
- Convention: `{content-type}/{id}/{asset-type}.{format}`
- Exercise assets:
  ```
  exercises/str-pushup-001/thumbnail.webp
  exercises/str-pushup-001/animation.webp
  exercises/yog-warrior-002/thumbnail.webp
  exercises/yog-warrior-002/animation.webp
  ```
- File naming: lowercase, hyphenated IDs matching `exercises.json` metadata
- One directory per exercise — keeps assets co-located and easy to manage
- No nesting beyond two levels (content-type/id/) — keeps URLs simple and CDN-cacheable

## URL Construction
- Public bucket URL pattern: `{SUPABASE_URL}/storage/v1/object/public/{bucket-name}/{path}`
- Example: `https://abc123.supabase.co/storage/v1/object/public/exercise-assets/exercises/str-pushup-001/thumbnail.webp`
- In the app: `exercises.json` stores relative paths (`exercises/str-pushup-001/thumbnail.webp`). At initialization, the app resolves these against `EnvironmentConfig.supabaseURL + "/storage/v1/object/public/exercise-assets/"` to construct full URLs
- This decouples asset paths from the Supabase project URL — switching environments (dev/prod) only changes the base URL
- URL encoding: exercise IDs should use URL-safe characters only (lowercase alphanumeric + hyphens)

## Upload Policies
- Exercise assets are uploaded by the founder/admin, not by app users
- Upload method: Supabase CLI (`supabase storage cp ./local-file.webp sb://exercise-assets/exercises/id/thumbnail.webp`) or Dashboard manual upload
- Bulk upload: script with Supabase client using service role key
- Content type validation: only accept `image/webp` for this bucket
- File size limits: thumbnails < 100KB, animations < 2MB (enforce in upload script, not bucket policy for MVP)
- Overwrite strategy: re-uploading to the same path replaces the file. Use path versioning (e.g., `thumbnail-v2.webp`) only if cache invalidation is needed

## CDN & Caching
- Supabase Storage serves assets through a CDN (edge caching at global points of presence)
- Set cache headers for immutable assets:
  - `Cache-Control: public, max-age=31536000, immutable` for versioned assets (paths include version hash)
  - `Cache-Control: public, max-age=86400` for assets that may be updated (safe default for MVP)
- Supabase sets default cache headers — override via Storage API if needed post-MVP
- Cache invalidation: re-uploading a file at the same path may not immediately purge CDN cache. For instant updates, use a new path (append version suffix or hash)
- Client-side: iOS app caches downloaded assets locally (URLCache for thumbnails, Caches directory for animations). See `team/developer/skills/ios-best-practices.md`

## Principles
1. **Public for content, private for user data**: Exercise assets are non-sensitive content — public bucket is correct. Never put user-generated data in a public bucket. If user uploads are added later, use a private bucket with RLS.
2. **Relative paths, resolved at runtime**: Store only relative paths in metadata (`exercises.json`). Resolve against the environment-specific base URL at app initialization. This makes environment switching (dev/staging/prod) a config change, not a data change.
3. **Upload is admin-only**: Exercise assets are part of the content pipeline, not user-facing features. Restrict upload to service role or CLI. No client-side upload for exercise content — this simplifies security and prevents abuse.
