# iOS Code Standards

## Purpose
Define Swift naming conventions, file organization, error handling, and dependency management for iOS development. See the `code-standards` skill for git workflow and PR standards. See the `ios-best-practices` skill for architecture patterns. See the `ios-modern-api` skill for deprecated vs modern API replacements. See the `ios-security` skill for Keychain patterns and credential storage.

## Version Targeting
- Minimum deployment target: **iOS 26**
- Swift version: **6.2+** with strict concurrency
- SwiftUI-first — avoid UIKit unless explicitly requested
- Do not introduce third-party frameworks without asking first

## Naming Conventions
- Types: PascalCase (`UserProfile`, `PaymentSession`)
- Functions/Variables: camelCase (`fetchUserData`, `isLoggedIn`)
- Constants: camelCase (`maxRetryCount`, `defaultTimeout`)
- Protocols: Adjective or -able/-ing suffix (`Loadable`, `DataProviding`)
- Enums: PascalCase type, camelCase cases (`enum State { case loading, loaded, error }`)

## File Organization
- One primary type per file
- File name matches primary type name
- Extensions in separate files: `TypeName+ExtensionPurpose.swift`
- Group by feature, not by type

## Swift Standards
- Use Swift's built-in error handling (`do/try/catch`) with custom error enums conforming to `LocalizedError`
- Prefer value types (structs) over reference types (classes) where appropriate
- Use access control intentionally (`private` by default, widen as needed)
- Document public APIs with `///` doc comments
- No force unwrapping in production code — ever
- No force casts — use conditional casts (`as?`) with proper handling
- Provide meaningful error messages for user-facing errors
- Log errors with structured logging — see the `ios-observability` skill for the logging protocol and vendor isolation pattern
- Network errors: map to user-friendly messages, include retry logic
- Flag silently swallowed errors — `print(error)` instead of surfacing to user is a bug for user-triggered actions
- `@AppStorage` must never store sensitive data (usernames, passwords, tokens) — use the Keychain

## Dependencies
- Prefer Apple frameworks over third-party when comparable
- Vet third-party dependencies for active maintenance and compatible license
- Use Swift Package Manager exclusively
- Pin dependency versions for reproducible builds
- Keep dependency count minimal — each one is a maintenance burden
- If SwiftLint is configured, it must return zero warnings and zero errors

## Localization
- If using `Localizable.xcstrings`, prefer symbol keys (e.g., `"helloWorld"`) with `extractionState` set to `"manual"`, accessing via generated symbols: `Text(.helloWorld)`
- All user-facing strings must be localizable — no hardcoded strings

## Shared UI Library Convention
- Every file that renders UI must import the shared UI library
- Use library tokens, extensions, and view modifiers for all styling
- Use library components when available; if one is missing file a `needs-component` request, and if a present component's API is too stale for your need file a `needs-update` request (`knowledge-base/ui-component-requests.md`) — never create a custom replacement or compile against a stale signature; route to PM when a needed component is in either state
- Feature module naming: use `Features/<FeatureName>/` directories matching the product spec's feature identifiers
- Repository protocol pattern: each data domain has a protocol + local implementation + remote implementation

## Principles

1. **Private by default**: Start with the tightest access control and widen only when needed. This makes the public API intentional, not accidental.

2. **One type, one file**: Keeps files focused and makes navigation predictable. Extensions get their own files to keep the primary type definition clean.

3. **Apple-first dependencies**: Every third-party dependency is a maintenance burden and a potential build-time cost. Use Apple frameworks unless the third-party alternative is significantly better for the use case.
