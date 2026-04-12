# iOS MVVM Architecture

## Purpose
Define the MVVM pattern for iOS features: ViewModel structure, state modeling, dependency injection, navigation ownership, and anti-patterns. See `team/developer/skills/ios-swiftui.md` for SwiftUI API patterns (@Observable, NavigationStack, presentation). See `team/developer/skills/ios-best-practices.md` for project-level folder structure and hybrid local/cloud architecture. See `team/developer/skills/ios-concurrency.md` for async/concurrency rules. Target: **iOS 26+, Swift 6.2+**.

## Core Boundaries

| Layer | Responsibility | Dependencies |
|-------|---------------|-------------|
| Model | Domain entities, business rules | None (UI-framework independent) |
| View | Render state, forward user intents | ViewModel only |
| ViewModel | Own presentation state, map domain→view data, coordinate effects | UseCases/Repositories/Services (via protocols) |
| Services/Repositories | Side-effect boundaries (network, persistence, analytics) | Domain layer |

Views never call services directly. ViewModels never import SwiftUI or reference presentation APIs.

## State Modeling

Use explicit state types — never model loading/error as boolean combinations.

```swift
enum Loadable<Value: Equatable>: Equatable {
    case idle, loading, loaded(Value), failed(String)
}

struct FeedState: Equatable {
    var load: Loadable<Void> = .idle
    var items: [FeedItemViewData] = []
    var isRefreshing = false
    var toast: ToastState?
}
```

- Expose dedicated `ViewData` structs for display concerns — keep domain models out of views
- One source of truth in the ViewModel. Never duplicate state with `@State` in the view
- Use `Equatable` conformance on state types for testability

## ViewModel Pattern

`@Observable` + `@MainActor`. Own task handles, cancel stale work.

```swift
@MainActor
@Observable
final class FeedViewModel {
    private(set) var state = FeedState()

    private let repository: FeedRepository
    private var loadTask: Task<Void, Never>?

    init(repository: FeedRepository) {
        self.repository = repository
    }

    func onAppear() {
        guard case .idle = state.load else { return }
        load()
    }

    func load() {
        loadTask?.cancel()
        state.load = .loading
        loadTask = Task {
            do {
                let page = try await repository.fetchPage(cursor: nil)
                try Task.checkCancellation()
                state.items = page.items.map(FeedItemViewData.init)
                state.load = .loaded(())
            } catch is CancellationError { }
            catch { state.load = .failed(error.localizedDescription) }
        }
    }

    deinit { loadTask?.cancel() }
}
```

Key rules:
- `private(set)` on state — views read, only ViewModel mutates
- Cancel previous task before starting new request (prevents stale overwrite)
- `try Task.checkCancellation()` after every `await` before writing state
- Filter `CancellationError` — it's lifecycle, not an error to surface
- Cancel stored tasks in `deinit`
- For expensive mapping, move CPU work off main actor. See `team/developer/skills/ios-concurrency.md` (@concurrent, Task.detached)

## Dependency Injection

Inject protocol abstractions into ViewModel constructors.

```swift
protocol FeedRepository: Sendable {
    func fetchPage(cursor: String?) async throws -> FeedPage
}
```

**Feature assembly** — simple wiring per feature:
```swift
enum FeedAssembly {
    static func makeViewModel() -> FeedViewModel {
        FeedViewModel(repository: LiveFeedRepository(api: .live))
    }
}
```

**Composition root** — when shared dependencies grow:
```swift
@MainActor
final class AppContainer {
    private let dependencies: AppDependencies

    func makeFeedViewModel() -> FeedViewModel {
        FeedViewModel(repository: dependencies.feedRepository)
    }
}
```

**Dual-backend coordinator** — switches between local and remote based on subscription state (see `team/developer/skills/ios-best-practices.md` for hybrid local/cloud architecture):
```swift
struct FeedRepositoryCoordinator: FeedRepository {
    private let local: FeedRepository
    private let remote: FeedRepository
    private let subscriptionState: SubscriptionState

    func fetchPage(cursor: String?) async throws -> FeedPage {
        switch subscriptionState.tier {
        case .free: return try await local.fetchPage(cursor: cursor)
        case .premium: return try await remote.fetchPage(cursor: cursor)
        }
    }
}
```

Start with feature assembly. Evolve to a composition root when dependency graphs become shared across features.

## View Wiring

```swift
struct FeedView: View {
    @State private var viewModel: FeedViewModel

    init(viewModel: FeedViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        List(viewModel.state.items) { item in
            Text(item.title)
        }
        .task { viewModel.onAppear() }
    }
}
```

- `@State` owns the ViewModel instance (see `team/developer/skills/ios-swiftui.md` State Management)
- Use `.task {}` for lifecycle — not `onAppear()` with `Task {}`
- Keep `body` declarative — all logic lives in ViewModel methods

## Navigation Ownership

ViewModel decides *where*, routing layer decides *how*. Model destinations as enums. See `team/developer/skills/ios-swiftui.md` (Navigation) for NavigationStack API rules.

### Option A: ViewModel-Owned Path
Simplest wiring. ViewModel holds `navigationPath` directly.

```swift
@MainActor @Observable
final class FeedViewModel {
    private(set) var state = FeedState()
    var navigationPath: [FeedDestination] = []

    func didTapItem(_ item: FeedItemViewData) {
        navigationPath.append(.detail(id: item.id))
    }
}
```

Trade-off: mixes navigation state with data/loading state. Fine for most features.

### Option B: Router-Owned Path
Keeps ViewModel focused on data. Router owns navigation state separately.

```swift
@MainActor @Observable
final class FeedRouter {
    var path: [FeedDestination] = []
    func push(_ destination: FeedDestination) { path.append(destination) }
}
```

ViewModel returns destinations without holding path state. View coordinates both.

### Sheet Presentation
Model sheets as optional ViewModel state with `Identifiable` enum:

```swift
enum FeedSheet: Identifiable {
    case compose
    case filter(current: FeedFilter)
    var id: String { /* unique per case */ }
}

// ViewModel
var activeSheet: FeedSheet?
func didTapCompose() { activeSheet = .compose }
```

Bind with `sheet(item: $viewModel.activeSheet)`.

### Deep Linking
Centralize deep link resolution in an app-level router that maps URLs to navigation destinations and applies them to existing navigation state.

### Coordinator Pattern
For UIKit-hosted or complex multi-step flows (onboarding, checkout): inject a `Coordinator` protocol into the ViewModel. The coordinator owns UIKit navigation. Avoid for pure SwiftUI features.

### Which Pattern to Choose

| Scenario | Pattern |
|----------|---------|
| Pure SwiftUI, linear flows | ViewModel-owned NavigationStack path |
| Complex feature needing clean state separation | Router-owned path |
| Sheets, alerts, confirmations | Optional state-driven presentation |
| Multi-step flows (onboarding, checkout) | Coordinator with child coordinators |
| Universal Links / push notifications | Deep link router + state-driven nav |

## Anti-Patterns

1. **God ViewModel** — networking, parsing, persistence, orchestration all in one class. Fix: extract to UseCases/Repositories
2. **Duplicate state** — `@State var items` in view AND `viewModel.state.items`. Fix: single source of truth in ViewModel
3. **Stale async overwrite** — older response replaces newer state. Fix: cancel in-flight task + check cancellation
4. **UIKit in ViewModel** — direct `UINavigationController` usage. Fix: inject Router/Coordinator protocol
5. **Heavy main-actor work** — decoding or expensive mapping blocks UI. Fix: offload CPU work with `@concurrent` or background actor, assign final state on main actor

## Testing ViewModel State Transitions

Test deterministic transitions: success (`loading→loaded`), failure (`loading→failed`), cancellation (no stale overwrite), mapping correctness (domain→ViewData).

Use protocol stubs for repositories. Avoid sleep-based tests — use controllable responses. See `team/developer/skills/ios-testing.md` for Swift Testing framework patterns.

```swift
@Test @MainActor
func loadSuccess_setsLoadedAndMapsItems() async {
    let repository = StubFeedRepository(result: .success(testPage))
    let vm = FeedViewModel(repository: repository)

    vm.load()
    await Task.yield()

    #expect(vm.state.items.map(\.title) == ["A"])
    #expect(vm.state.load == .loaded(()))
}

@Test @MainActor
func loadFailure_setsFailed() async {
    let repository = StubFeedRepository(result: .failure(TestError.offline))
    let vm = FeedViewModel(repository: repository)

    vm.load()
    await Task.yield()

    if case .failed = vm.state.load { } else {
        Issue.record("Expected failed state")
    }
}
```

## When to Prefer MVVM

| Architecture | When to prefer |
|-------------|----------------|
| **MVVM** | Screen-level state, explicit View/ViewModel boundaries, moderate complexity, team wants testable structure without a full framework |
| **MVI/TCA** | Deterministic state machines, complex effect orchestration, strict unidirectional flow |
| **Clean/VIPER** | Strict layer isolation matters more than presentation simplicity |

MVVM is lower ceremony than TCA/VIPER but not zero ceremony. Scale file splitting to actual complexity — not every feature needs `State`, `ViewData`, `Assembly`, and `Router` types up front.

## Principles

1. **Explicit state over boolean soup**: Model view state as enums and structs with `Equatable` conformance. `Loadable<T>` replaces scattered `isLoading`/`hasError`/`data` booleans — fewer invalid states, simpler tests.

2. **Cancel before you start**: Every new async operation must cancel the previous one. Check cancellation after every `await` before writing state. This is the single most common source of stale-data bugs in MVVM.

3. **Inject abstractions, not implementations**: ViewModels depend on protocols. Live implementations are wired in assembly/composition root. This enables testing, dual backends (local/remote), and clean substitution.

4. **Scale structure to complexity**: A simple settings screen needs a ViewModel and a View. A complex feed feature may need ViewData, Router, Assembly, and dedicated state types. Apply structure where it earns its keep.
