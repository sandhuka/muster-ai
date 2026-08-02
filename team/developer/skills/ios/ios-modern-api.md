# iOS Modern API Reference

## Purpose
Scannable reference of deprecated vs modern SwiftUI and Swift APIs. Use when writing or reviewing iOS code to ensure current API usage. See the `ios-swiftui` skill for architectural patterns. See the `ios-code-standards` skill for Swift conventions. Target: **iOS 26+, Swift 6.2+**.

## SwiftUI API — Use This, Not That

| Deprecated / Avoid | Modern Replacement |
|--------------------|--------------------|
| `foregroundColor()` | `foregroundStyle()` |
| `cornerRadius()` | `clipShape(.rect(cornerRadius:))` |
| `tabItem()` | `Tab` API |
| `onChange` (1-param variant) | `onChange` (0-param or 2-param variant) |
| `GeometryReader` | `containerRelativeFrame()`, `visualEffect()`, or `Layout` protocol |
| `UIImpactFeedbackGenerator` etc. | `sensoryFeedback()` |
| Manual `EnvironmentKey` + computed property | `@Entry` macro |
| `overlay(_:alignment:)` | `overlay(alignment:content:)` or `overlay { }` |
| `.navigationBarLeading/Trailing` | `.topBarLeading` / `.topBarTrailing` |
| `NavigationView` | `NavigationStack` or `NavigationSplitView` |
| `NavigationLink(destination:)` | `navigationDestination(for:)` |
| `Image("name")` | `Image(.name)` (generated symbol asset API) |
| `showsIndicators: false` | `.scrollIndicators(.hidden)` |
| `Text("A") + Text("B")` | Text interpolation: `Text("\(a)\(b)")` |
| `PreviewProvider` protocol | `#Preview` |
| `onAppear()` for async work | `task()` (auto-cancels on disappear) |
| `UIGraphicsImageRenderer` | `ImageRenderer` |
| `TextEditor` (basic multiline) | `TextField(axis: .vertical)` with `lineLimit(5...)` |
| `UIScreen.main.bounds` | `containerRelativeFrame()`, `visualEffect()`, or `GeometryReader` as last resort |
| Manual overlay for stroke on fill | Chain `.fill()` then `.stroke()` |
| Hand-wrapped `WKWebView` via `UIViewRepresentable` | Native `WebView` (iOS 26+, `import WebKit`) |

## SwiftUI — Prefer This

- `ContentUnavailableView` for empty/missing data states — use `.search` variant for search (auto-includes search term)
- `Label` over `HStack` for icon + text pairs
- Hierarchical styles (`.secondary`, `.tertiary`) over manual opacity
- `LabeledContent` in `Form` for controls like `Slider`
- `RoundedRectangle` default style is `.continuous` — don't specify it
- `bold()` over `fontWeight(.bold)` — lets the system choose correct weight for context
- Avoid `fontWeight()` scattering (`.medium`, `.semibold`) without clear reason
- SwiftUI `Color` or asset catalog colors — never UIKit `UIColor` in SwiftUI code
- `ForEach(items.enumerated(), id: \.element.id)` — no `.Array()` conversion needed
- `ObservableObject` requires explicit `import Combine` (no longer provided by SwiftUI)
- `scrollContentBackground(.visible)` for opaque, static scroll backgrounds (rendering efficiency)
- `Button("Label", action: myAction)` over `Button("Label") { myAction() }` when action is a method reference

## Swift API — Use This, Not That

| Deprecated / Avoid | Modern Replacement |
|--------------------|--------------------|
| `replacingOccurrences(of:with:)` | `replacing("a", with: "b")` |
| `FileManager` directory lookups | `URL.documentsDirectory` etc. |
| `String(format: "%.2f", value)` | `Text(value, format: .number.precision(.fractionLength(2)))` |
| Struct instances (`Circle()`) | Static member lookup (`.circle`) where possible |
| `contains()` for user-input filtering | `localizedStandardContains()` |
| `filter().count` | `count(where:)` |
| `Date()` | `Date.now` — but inject it in app/domain code (`ios-mvvm.md` → DI) |
| `"\(firstName) \(lastName)"` for names | `PersonNameComponents` with formatting |
| `if let value = value {` | `if let value {` shorthand |
| Manual date format strings | `Date(string, strategy: .iso8601)` or `Text(date, format:)` |
| Repeated sort closures | Conform type to `Comparable` |
| `"yyyy"` in date formats (user display) | `"y"` (correct across localizations) |

## Swift — Prefer This

- `Double` over `CGFloat` (except optionals and `inout` — bridging doesn't work there)
- Omit `return` for single-expression functions; use `if`/`switch` as expressions
- Automatic grammar agreement for English, French, German, Portuguese, Spanish, Italian: `Text("^[\(count) person](inflect: true)")`
- Flag silently swallowed errors (`print(error)` instead of showing alert) — user-triggered errors must be surfaced
- When `import SwiftUI` is present, `UIImage`/`NSImage` are already available — no need for `import UIKit`/`AppKit`

## Swift Concurrency (Quick Flags)

For full concurrency guidance, see the `ios-concurrency` skill.

| Deprecated / Avoid | Modern Replacement |
|--------------------|--------------------|
| `DispatchQueue.main.async {}` | `@MainActor` function |
| `DispatchQueue.global().async {}` | `@concurrent` or task group |
| `Task.sleep(nanoseconds:)` | `Task.sleep(for:)` |
| Closure-based async APIs | `async/await` variants |
| `Task.detached {}` | `Task {}` with explicit isolation, or structured concurrency |

## Animations

- Use `@Animatable` macro over manual `animatableData` — mark non-animatable properties `@AnimatableIgnored`
- Always provide a value: `.animation(.bouncy, value: score)` — never use `animation(_:)` without a value
- Chain animations via completion: `withAnimation { } completion: { withAnimation { } }` — not multiple delayed calls

## Principles

1. **Modern API by default**: If a newer API exists for the same task, use it. Deprecated APIs may still compile but will eventually break, and they miss performance optimizations in newer OS versions.

2. **Let the system do the work**: Prefer APIs that delegate to the system (grammar agreement, date formatting, hierarchical styles) over manual implementations. They handle edge cases you won't.

3. **Concurrency is non-negotiable**: Swift 6.2 strict concurrency is the baseline. No GCD, no unprotected shared state, no fire-and-forget tasks.
