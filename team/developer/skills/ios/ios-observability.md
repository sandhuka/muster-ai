# iOS Observability (Logging & Analytics)

## Purpose
Define logging and analytics patterns using protocol abstraction so the app never knows the vendor. Both follow the repository pattern: protocol → console implementation (debug) → vendor implementation (production). See `team/developer/skills/ios-mvvm.md` for the general DI and repository pattern. See `team/developer/skills/ios-code-standards.md` for error handling conventions. See `team/developer/skills/ios-security.md` for what constitutes sensitive data.

## Architecture

Both logging and analytics use the same structure:

```
Protocol (abstraction)
├── ConsoleImplementation  — debug builds, prints to Xcode console
└── VendorImplementation   — production builds, sends to third-party service
```

- The app depends only on the protocol — never on a vendor SDK
- `import VendorSDK` appears only inside the concrete vendor implementation file
- Swap implementations via build configuration or composition root — no `#if DEBUG` scattered through feature code
- If the vendor changes, update one file. The rest of the app is untouched.

## Logging

### Protocol

```swift
protocol LogService: Sendable {
    func debug(_ message: String, category: LogCategory)
    func info(_ message: String, category: LogCategory)
    func warning(_ message: String, category: LogCategory)
    func error(_ message: String, category: LogCategory, error: Error?)
}

enum LogCategory: String, Sendable {
    case network, persistence, auth, algorithm, ui, lifecycle
}
```

### Console Implementation (Debug)

```swift
import os

struct ConsoleLogService: LogService {
    private let loggers: [LogCategory: Logger]

    init(subsystem: String = Bundle.main.bundleIdentifier ?? "app") {
        loggers = Dictionary(uniqueKeysWithValues: LogCategory.allCases.map {
            ($0, Logger(subsystem: subsystem, category: $0.rawValue))
        })
    }

    func debug(_ message: String, category: LogCategory) {
        loggers[category]?.debug("\(message, privacy: .public)")
    }

    func info(_ message: String, category: LogCategory) {
        loggers[category]?.info("\(message, privacy: .public)")
    }

    func warning(_ message: String, category: LogCategory) {
        loggers[category]?.warning("\(message, privacy: .public)")
    }

    func error(_ message: String, category: LogCategory, error: Error?) {
        loggers[category]?.error("\(message, privacy: .public) \(error?.localizedDescription ?? "", privacy: .public)")
    }
}
```

### Vendor Implementation (Production)

```swift
import VendorSDK // only imported here — nowhere else in the app

struct VendorLogService: LogService {
    func debug(_ message: String, category: LogCategory) {
        // Vendor-specific debug logging
    }
    func info(_ message: String, category: LogCategory) {
        VendorSDK.log(level: .info, tag: category.rawValue, message: message)
    }
    // ... same pattern for warning, error
}
```

### Log Levels

| Level | Use for | Examples |
|-------|---------|---------|
| `debug` | Development-only detail, stripped in production | State transitions, computed values, view lifecycle |
| `info` | Notable events useful for understanding app flow | User completed onboarding, plan generated, subscription activated |
| `warning` | Unexpected but recoverable situations | Network retry, cache miss, fallback path taken |
| `error` | Failures that affect user experience | API failure, persistence error, algorithm failure |

### What to Log
- All network request/response cycles (URL, status code, duration — not body)
- State transitions in ViewModels (loading → loaded, loading → failed)
- Feature algorithm inputs/outputs (parameters, computed results)
- Subscription state changes (purchase, restore, expiration)
- Error paths with enough context to diagnose without reproduction

### What NOT to Log
- **PII**: email, name, location, device identifiers, IP addresses
- **Credentials**: tokens, passwords, API keys, keychain contents
- **Domain-sensitive data**: specific user activity details that could identify a user
- **Request/response bodies** containing user data
- Use `privacy: .private` in `os.Logger` for any value that could contain user data — redacted in release builds, visible in Console.app during debug

## Analytics

### Protocol

```swift
protocol AnalyticsService: Sendable {
    func track(_ event: AnalyticsEvent)
    func setUserProperty(_ property: String, value: String?)
}

struct AnalyticsEvent: Sendable {
    let name: String
    let parameters: [String: String]
}
```

### Console Implementation (Debug)

```swift
struct ConsoleAnalyticsService: AnalyticsService {
    func track(_ event: AnalyticsEvent) {
        print("[Analytics] \(event.name): \(event.parameters)")
    }

    func setUserProperty(_ property: String, value: String?) {
        print("[Analytics] Property \(property) = \(value ?? "nil")")
    }
}
```

### Vendor Implementation (Production)

```swift
import VendorAnalyticsSDK // only imported here

struct VendorAnalyticsService: AnalyticsService {
    func track(_ event: AnalyticsEvent) {
        VendorAnalyticsSDK.logEvent(event.name, parameters: event.parameters)
    }

    func setUserProperty(_ property: String, value: String?) {
        VendorAnalyticsSDK.setUserProperty(property, value: value)
    }
}
```

### Event Naming
- Use `snake_case` for event names: `task_completed`, `subscription_purchased`, `onboarding_step_completed`
- Prefix with feature area: `catalog_item_viewed`, `session_started`
- Keep parameter values low-cardinality (categories, enums) — not free-text or IDs
- Define events as static constants to prevent typos:

```swift
extension AnalyticsEvent {
    static func taskCompleted(category: String, duration: Int) -> Self {
        AnalyticsEvent(name: "task_completed", parameters: [
            "category": category,
            "duration_seconds": "\(duration)"
        ])
    }
}
```

### What to Track
- Onboarding funnel steps (measure drop-off)
- Core feature generation and completion
- Subscription funnel (paywall viewed → purchase started → purchase completed)
- Feature usage by screen/tab
- Error rates by category (network, persistence, business logic)

### What NOT to Track
- Anything that identifies the user personally (same PII rules as logging)
- High-frequency events that create noise (every scroll, every frame)
- Implementation details (internal state machine transitions, cache hits)

## Environment Switching

Wire in the composition root using `AppEnvironment` (see `team/developer/skills/ios-best-practices.md` Build Environments) — not with `#if DEBUG` scattered through features:

```swift
@MainActor
final class AppContainer {
    let logService: LogService
    let analyticsService: AnalyticsService

    init() {
        switch AppEnvironment.current {
        case .debug:
            logService = ConsoleLogService()
            analyticsService = ConsoleAnalyticsService()
        case .production:
            logService = VendorLogService()
            analyticsService = VendorAnalyticsService()
        }
    }
}
```

The `#if DEBUG` switch exists in exactly one place. Feature code never checks the build configuration.

## Principles

1. **Vendor isolation is absolute**: `import VendorSDK` appears in one file per vendor. The rest of the app depends on protocols. When the vendor changes — and it will — you update one concrete class and one SPM dependency. Zero feature code touched.

2. **Console in debug, vendor in production**: During development, everything goes to Xcode console via `os.Logger` (logging) or `print` (analytics). In production, everything routes to the vendor. The switch happens once in the composition root.

3. **Log for diagnosis, track for decisions**: Logging answers "what went wrong and why." Analytics answers "what are users doing and where do they drop off." Different audiences, different retention, different privacy constraints — but the same architectural pattern.

4. **PII never enters the pipeline**: Scrub at the call site, not downstream. If a value could identify a user, it doesn't get passed to `LogService` or `AnalyticsService`. Use `os.Logger` privacy levels as a safety net, not as the primary defense.
