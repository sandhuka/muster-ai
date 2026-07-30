# iOS Architecture & Platform Guidelines

## Purpose
Define high-level architecture patterns, project structure, and Apple platform guidelines for iOS development. See the `ios-mvvm` skill for the detailed MVVM pattern (ViewModel structure, state modeling, DI, navigation ownership). See the `ios-code-standards` skill for Swift conventions, the `ios-swiftui` skill for view patterns, and the `ios-swiftdata` skill for persistence.

## Architecture
- SwiftUI-first for all new views
- MVVM architecture with clear separation of concerns
- Use Swift concurrency (async/await, actors) over Combine where possible
- Protocol-oriented design for testability and dependency injection
- Feature-based module structure, not layer-based

## Design for Evolution
Build so the axes the product will grow along are cheap to extend — and let the compiler, not a future code-read, catch a half-done extension.
- **Exhaustive `switch`, no `default`.** Switch over an enum with every case spelled out and no `default`. Adding a case then *fails the build* at every unhandled site — the compiler becomes the extension checklist. A `default` (or `@unknown default` on your own enum) silences exactly that signal.
- **Author behavior in data tables, not branches.** When behavior varies by a value, drive it from a parameter table keyed by that value, so a new value is a table row — not a new `case` threaded through the engine.
- **One source-of-truth accessor.** A mapping like enum→label or enum→icon lives in a single accessor, never duplicated across files. Duplication is an SSoT violation and an N-site edit on every extension, and the compiler can't catch the copy you missed.
- **Orchestrator/delegate split** so a genuinely new behavior is a new delegate, not a rewrite of the core.

**Anti-patterns to flag in review:** a hardcoded literal where an enum or predicate belongs (silently wrong on extension, uncatchable by the compiler); the same enum mapping duplicated across N files.

## Code Organization
```
ProjectName/
├── App/                    # App entry point, configuration
├── Features/               # Feature modules
│   ├── Onboarding/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Models/
│   │   └── Services/
│   ├── Dashboard/
│   ├── FeatureB/
│   └── Profile/
├── Core/                   # Shared utilities, extensions, protocols
│   ├── Networking/
│   ├── Storage/
│   ├── Design/             # Design tokens, shared UI components
│   └── Extensions/
└── Resources/              # Assets, localization, fonts
```

## Hybrid Local/Cloud Architecture
Patterns for apps that run fully local for free users and connect to a backend for premium:

- **Deferred authentication**: Auth is a premium feature, not a prerequisite. The app must work completely without an account. See the `ios-networking` skill for auth implementation
- **Repository pattern with dual backends**: Define a protocol for each data domain. Provide a local implementation and a remote implementation. A coordinator switches between them based on subscription state. Free users never hit the network for repository, auth, or algorithm calls — but both tiers make network calls to Supabase Storage for exercise asset loading (public bucket, no auth required, cached locally after first load)
- **One-shot data migration**: When a free user subscribes, migrate all local data to the backend in a single transaction. Keep local data as fallback. Mark migration as complete to prevent re-migration. Handle partial failure gracefully — retry or roll back, never leave data inconsistent. See the `ios-swiftdata` skill for migration implementation
- **Offline caching (premium)**: Cache latest data locally. Queue mutations when offline and sync on reconnect. Conflict resolution: server wins for plan data, client wins for user-generated data (user's device is source of truth for what they actually did). See the `ios-networking` skill for sync patterns
- **Two-track algorithm**: Free algorithm runs on-device (subset of rules). Premium algorithm runs server-side. Both take the same input shape and return the same output shape — the difference is rule complexity, not API contract

## Asset Loading
Patterns for exercise asset loading from Supabase Storage:

- **Bundled metadata only**: Ship `exercises.json` (exercise catalog metadata) in the app bundle. Thumbnails and animations are served from Supabase Storage (public bucket, no auth required for any tier). See the `backend-supabase-storage` skill for bucket configuration and URL construction
- **URL resolution**: `exercises.json` stores relative paths (e.g., `exercises/str-pushup-001/thumbnail.webp`). At initialization, resolve against `EnvironmentConfig` base URL to construct full Supabase Storage URLs
- **Thumbnail loading**: Load thumbnails from Supabase Storage on demand. Cache via `URLCache`. Show placeholder silhouette while loading (10s timeout)
- **Animation loading**: Animated WebP loops are larger — load on demand from Supabase Storage. Show static thumbnail immediately, crossfade to animation when loaded
- **Pre-fetch strategy**: When a routine is generated, pre-fetch all animations for the routine immediately — not when the user opens them. Trigger on screen load, not on user action. For browsing (Library), pre-fetch visible cell animations as the user scrolls (lazy image loading pattern)
- **Cache management**: Cache thumbnails via URLCache. Cache animations in the app's Caches directory (system can purge if storage is low). Use URL-based cache keys. Set a reasonable max cache size and evict LRU

## Build Environments

Two environments minimum: **Debug** and **Production**. All environment-specific values live in `.xcconfig` files, flow through `Info.plist`, and are accessed via `Bundle.main` at runtime. No secrets hardcoded in source, no `#if DEBUG` scattered through feature code.

### .xcconfig Files

One per environment, excluded from git (add to `.gitignore`):

```
# Config/Debug.xcconfig
BACKEND_URL = https:/$()/dev-backend.example.com
BACKEND_API_KEY = dev-api-key-here
API_BASE_URL = https:/$()/dev-api.example.com
```

```
# Config/Release.xcconfig
BACKEND_URL = https:/$()/prod-backend.example.com
BACKEND_API_KEY = prod-api-key-here
API_BASE_URL = https:/$()/api.example.com
```

Assign in Xcode: Project → Info → Configurations → Debug uses `Debug.xcconfig`, Release uses `Release.xcconfig`.

Provide a `.xcconfig.template` (checked into git) so other developers know which keys to define.

### Info.plist Keys

Reference the build settings in `Info.plist` (or the target's Info tab):

```xml
<key>BACKEND_URL</key>
<string>$(BACKEND_URL)</string>
<key>BACKEND_API_KEY</key>
<string>$(BACKEND_API_KEY)</string>
<key>API_BASE_URL</key>
<string>$(API_BASE_URL)</string>
```

### Runtime Access

Read values from `Bundle.main` once at launch. Centralize in a single config type:

```swift
struct EnvironmentConfig {
    let backendURL: URL
    let backendAPIKey: String
    let apiBaseURL: URL

    static let current: EnvironmentConfig = {
        guard let backendURL = Bundle.main.object(forInfoDictionaryKey: "BACKEND_URL") as? String,
              let apiKey = Bundle.main.object(forInfoDictionaryKey: "BACKEND_API_KEY") as? String,
              let apiBase = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String else {
            fatalError("Missing environment config — check .xcconfig and Info.plist keys")
        }
        return EnvironmentConfig(
            backendURL: URL(string: backendURL)!,
            backendAPIKey: apiKey,
            apiBaseURL: URL(string: apiBase)!
        )
    }()
}
```

### Environment Detection

```swift
enum AppEnvironment {
    case debug, production

    static var current: AppEnvironment {
        #if DEBUG
        .debug
        #else
        .production
        #endif
    }
}
```

- **Debug** (Xcode run): Points to dev backend. Console logging, console analytics. See the `ios-observability` skill
- **Production** (Release build, TestFlight, App Store): Points to production backend. Vendor logging, vendor analytics
- Feed `EnvironmentConfig.current` and `AppEnvironment.current` into the composition root (`AppContainer` in the `ios-mvvm` skill) — they drive networking, observability, and any environment-specific behavior
- `.xcconfig` files must be in `.gitignore` — commit only the `.xcconfig.template` with placeholder values
- Never add a staging/QA environment "just in case" — add it when there's a real need

## Apple HIG Compliance
- Follow platform navigation patterns (NavigationStack, TabView)
- Respect system dark mode / light mode via semantic colors
- Use SF Symbols for iconography where possible
- Avoid fixed frames — prefer flexible sizing for device and Dynamic Type compatibility. See the `ios-modern-api` skill for `UIScreen.main.bounds` alternatives
- See the `ios-accessibility` skill for accessibility requirements (Dynamic Type, VoiceOver, Reduce Motion, color differentiation, tap targets)

## Platform Integrations
- Request only the specific data types and permissions you need
- Handle authorization gracefully (user may deny specific types)
- Always perform I/O on background queues
- Display data with appropriate units and precision
- Never store sensitive user data on external servers without explicit consent

## Principles

1. **Local-first for free**: The free tier must work completely without network calls or authentication. Every feature must have a functioning local path.

2. **Protocol abstraction for testability**: Define protocols for every data domain. This enables dual backends, in-memory test containers, and clean dependency injection — because the two-tier architecture demands it.

3. **Pre-fetch early, not late**: Pre-fetch assets when content is generated, not when the user requests playback. The screen load is the trigger, not the user tap.

4. **Bundle metadata, fetch assets**: Exercise metadata (`exercises.json`) ships in the bundle. Thumbnails and animations load from Supabase Storage with thumbnail-to-animation crossfade. Never show a blank frame.
