# iOS SwiftUI Patterns

## Purpose
Define SwiftUI view composition, state management, navigation, presentation, and performance patterns for iOS development. See the `ios-mvvm` skill for the MVVM pattern (ViewModel structure, DI, navigation ownership). See the `ios-best-practices` skill for project-level architecture (feature modules, hybrid local/cloud). See the `ios-modern-api` skill for deprecated vs modern API replacements. See the `ios-accessibility` skill for accessibility requirements.

## State Management
**Primary pattern — `@Observable`:**
- Use `@Observable` classes for all shared/model state. Must be annotated `@MainActor` (flag if missing, unless project uses MainActor default isolation)
- `@State` — owns the observable instance in the view that creates it. Must be `private`
- `@Bindable` — creates bindings to properties of an `@Observable` object
- `@Environment` — injects shared observable instances from ancestor views
- `@State` can also cache expensive non-observable objects (e.g., `CIContext`) — uses `@State` as persistent storage without change tracking

**Legacy (avoid unless required):**
- `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `ObservableObject`, `@Published` — do not use. These are legacy APIs superseded by @Observable

**Bindings:**
- Avoid `Binding(get:set:)` in view body — use `@State`/`@Binding` + `onChange()` to trigger effects
- Numeric input: `TextField("Score", value: $score, format: .number)` + `.keyboardType(.numberPad)` for integers, `.decimalPad` for floats. The modifier alone is not sufficient

**Data patterns:**
- Structs should conform to `Identifiable` rather than using `id: \.property` in SwiftUI
- Never use `@AppStorage` inside an `@Observable` class (even with `@ObservationIgnored`) — it won't trigger view updates

## View Composition
- Extract subviews as dedicated `View` structs in their own files — not computed properties or methods returning `some View` (even with `@ViewBuilder`)
- Flag `body` properties that are excessively long
- Keep view bodies declarative — move business logic to ViewModels. Logic should not live inline in `task()`, `onAppear()`, or `body`
- Button actions should be extracted into separate methods: `Button("Label", action: myAction)` over inline closures
- Use `ViewBuilder` for conditional/dynamic content helpers within a feature

## Navigation
- Use `NavigationStack` with value-based `NavigationPath` for programmatic navigation
- Define `Hashable` route enums per feature: `enum OnboardingRoute: Hashable { case step1, step2, ... }`
- Use `.navigationDestination(for:)` to map routes to views — register once per data type, flag duplicates
- Never mix `navigationDestination(for:)` and `NavigationLink(destination:)` in the same navigation hierarchy — causes significant problems
- `TabView` for top-level navigation with `NavigationStack` inside each tab. Use enum-based `TabView(selection:)` — not integer or string

## Presentation
- `sheet(item:)` over `sheet(isPresented:)` when presenting optional data — safely unwraps the optional. Use `sheet(item: $item, content: SomeView.init)` shorthand when the view takes the item as its only parameter
- `confirmationDialog()` must be attached to the UI element that triggers it (enables correct Liquid Glass animation source in iOS 26)
- Alerts with a single "OK" dismiss button: omit the button entirely — `.alert("Title", isPresented: $show) { }`
- Dismiss modals via `@Environment(\.dismiss)`

## Previews
- Every view file includes at least one `#Preview`
- Use mock data and in-memory containers — previews must work without network or device state
- Create preview helpers in a shared `PreviewContent/` directory for reusable mock data

## Performance
- **Ternary over branching**: Use ternary expressions to toggle modifier values — avoids `_ConditionalContent`, preserves structural identity, and prevents view recreation
- **No AnyView**: Use `@ViewBuilder`, `Group`, or generics instead
- **Dedicated subviews over computed properties**: Breaking views into separate `View` structs is more efficient than computed properties or methods. `@ViewBuilder` on a property does not solve this
- **Lightweight initializers**: Keep view `init()` simple — move non-trivial work to `task()` modifier
- **Logic out of body**: Sorting, filtering, and transforms should be moved out of `body` — it's called frequently
- **No expensive inline transforms**: Avoid `items.filter { }` in `List`/`ForEach` initializers when repeated. Derive transformed data with `let`, or cache in `@State` only if you own explicit invalidation logic
- **Lazy stacks for large data**: Use `LazyVStack`/`LazyHStack` — flag eager stacks with many children
- **Store built views, not closures**: Prefer `@ViewBuilder let content: Content` over `let content: () -> Content`

## Principles

1. **@Observable is the primary pattern**: All shared state uses `@Observable` classes with `@MainActor`. Legacy property wrappers (`@StateObject`, `@ObservedObject`, `@EnvironmentObject`) are for backward compatibility only.

2. **Declarative views, imperative ViewModels**: Views describe what to show. ViewModels decide what to do. Business logic in `body`, `task()`, or `onAppear()` closures is a code smell — extract it.

3. **Value-based navigation**: Use typed route enums with `NavigationStack`. Never mix old and new navigation APIs in the same hierarchy. This makes navigation testable and programmatically controllable.
