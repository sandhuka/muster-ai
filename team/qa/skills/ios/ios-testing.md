# iOS Testing Methodology

## Purpose
Define iOS-specific testing patterns for reviewing developer test code and writing test plans. Covers the Swift Testing framework (primary), XCUITest (UI automation), SwiftData persistence testing, StoreKit 2 subscription testing, SwiftUI validation, performance profiling, and network mocking. See `team/qa/skills/test-strategy.md` for testing levels, coverage targets, and device matrix. See `team/developer/skills/ios-testing.md` for the developer's testing standards that QA validates against.

## Framework Selection

| Scope | Framework | Notes |
|-------|-----------|-------|
| Unit tests | Swift Testing | Structs, `@Test`, `#expect`/`#require`. No XCTest. |
| Integration tests | Swift Testing | Feature flows, API contract validation. |
| UI tests | XCUITest (XCTest) | Swift Testing does not support UI tests. |
| Performance benchmarks | XCTest `measure` | Swift Testing has no equivalent. |

QA should flag any PR that uses XCTest for unit/integration tests or Swift Testing for UI tests.

---

## 1. Swift Testing Fundamentals

### Test Structure
Tests use structs (not classes), `@Test` annotation (not `test` prefix), and `init()` for setup (not `setUp()`/`tearDown()`):

```swift
struct WorkoutRecordTests {
    let repository: WorkoutRepository
    let container: ModelContainer

    init() async throws {
        container = try ModelContainer(
            for: WorkoutRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        repository = LocalWorkoutRepository(modelContext: container.mainContext)
    }

    @Test func completedWorkoutPersistsAllFields() async throws {
        let record = WorkoutRecord(/* ... */)
        try await repository.save(record)
        let fetched = try #require(await repository.fetch(id: record.id))
        #expect(fetched.discipline == .strength)
        #expect(fetched.source == .smart)
    }
}
```

### QA Review Checklist for Swift Testing Code
- Structs not classes (classes are allowed but structs are preferred)
- No `XCTAssert*` calls -- must use `#expect` / `#require`
- No `test` prefix on method names
- `init()` for setup, no `setUp()`/`tearDown()`
- `#require` used for preconditions (unwrapping, guard conditions), `#expect` for assertions
- `#expect(!condition)` must NOT be used -- require `#expect(condition == false)` instead (macro expansion gives useless failure messages with `!`)
- Error assertions name the specific error: `#expect(throws: AlgorithmError.noExercisesAvailable)` not `#expect(throws: Error.self)`
- Tests are independent -- no shared mutable state, no ordering dependency
- Parameterized tests used to reduce duplication where appropriate (max 2 argument collections; 2 collections = Cartesian product)

### Async Testing
- Tests can be `async throws` directly
- `confirmation(expectedCount:)` for verifying async events fire the expected number of times
- `confirmation(expectedCount: 0)` to assert an event never fires (e.g., paywall trigger should NOT fire on yoga access)
- Time limits: `.timeLimit(.minutes(N))` only -- `.seconds()` does not exist in Swift Testing
- Actor-isolated tests: mark `@MainActor` when testing `@MainActor`-bound ViewModels

### Tags to Expect
Verify developers use tags for test categorization. Recommended tags for this project:
- `.networking` -- Supabase calls, asset loading, offline sync
- `.slow` -- Performance tests, migration tests
- `.edgeCase` -- Boundary conditions, counter resets
- `.smoke` -- Critical path subset for hotfix validation

---

## 2. XCUITest (UI Automation)

### Launch Arguments for Test Configuration
Use launch arguments to control app state during UI tests. Verify these are defined in the test target and respected by the app:

```swift
let app = XCUIApplication()
app.launchArguments += [
    "--uitesting",                    // app detects test mode
    "--reset-onboarding",             // force onboarding flow
    "--subscription-state", "free",   // or "premium"
    "--smart-counter", "2",           // simulate exhausted smart slots
    "--skip-health-disclaimer"        // bypass for non-disclaimer tests
]
app.launch()
```

QA must verify:
- The app checks `ProcessInfo.processInfo.arguments` and configures state accordingly
- Launch arguments never leak into production builds (guard with `#if DEBUG`)
- Both `free` and `premium` subscription states are testable via arguments

### Accessibility Identifiers
All interactive elements must have accessibility identifiers for UI test element queries. QA validates:

```swift
// In production view code:
TAPrimaryButton("Start Workout")
    .accessibilityIdentifier("today_startWorkout")

// In UI test:
app.buttons["today_startWorkout"].tap()
```

Naming convention to enforce: `{screen}_{element}` (e.g., `onboarding_goalSelection`, `session_skipExercise`, `plan_upgradeButton`).

Flag any UI test that queries by label text (fragile -- breaks on copy changes) instead of accessibility identifier.

### Navigation Testing
Test the 4-tab structure (`architecture.md` Section 3):
- Tab switching preserves state (automatic with TabView, but verify)
- Settings gear accessible from every tab root
- Active workout session presents as `.fullScreenCover` and hides tab bar
- Subscription sheet presents as `.sheet` with `.large` detent
- Onboarding presents as `.fullScreenCover` on first launch
- Back navigation within each tab's `NavigationStack`

### Screenshot Capture
Enable automatic screenshots on failure in the test plan. For manual capture during specific flows:

```swift
let screenshot = app.windows.firstMatch.screenshot()
let attachment = XCTAttachment(screenshot: screenshot)
attachment.name = "onboarding-step3-equipment"
attachment.lifetime = .keepAlways
add(attachment)
```

Require screenshots at each step of critical flows (onboarding, subscription purchase, data deletion) in the UI test suite.

### Sheets, Alerts, and FullScreenCover
- Health disclaimer sheet: `.interactiveDismissDisabled(true)` -- verify swipe-to-dismiss does NOT work, only the Continue button after acknowledgment
- Subscription sheet: verify dismiss via swipe and via explicit close
- Active session fullScreenCover: verify no way to accidentally dismiss mid-workout
- System alerts (e.g., notification permissions): use `addUIInterruptionMonitor` to handle

---

## 3. SwiftData Testing

Reference: `knowledge-base/architecture.md` Section 5 (data model), `team/developer/skills/ios-swiftdata.md`.

### In-Memory ModelContainer
All persistence tests must use in-memory containers -- no disk I/O, no cleanup, full isolation:

```swift
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(
    for: UserProfile.self, WorkoutRecord.self, WorkoutExerciseRecord.self, OfflineMutation.self,
    configurations: config
)
```

QA must verify:
- Every persistence test creates its own container in `init()` -- never shared across tests
- No test reads from or writes to disk-backed storage
- All four model types from `architecture.md` Section 5 are included in the container schema

### CRUD Operation Testing
For each SwiftData model, verify tests exist for:

| Operation | What to verify |
|-----------|---------------|
| Create | All required fields set, defaults applied, `createdAt` populated |
| Read | Fetch by ID, fetch with predicate, fetch with sort/limit |
| Update | Field mutation persists after explicit `save()`, `updatedAt` changes |
| Delete | Object removed, cascade rules fire correctly |
| Bulk delete | F-PRO-4 data deletion wipes all user data in one operation |

### Relationship Cascade Verification
`WorkoutRecord` has a `.cascade` delete rule to `WorkoutExerciseRecord` (`architecture.md` Section 5). Test:
- Deleting a `WorkoutRecord` deletes all its `WorkoutExerciseRecord` children
- Deleting a `WorkoutExerciseRecord` does NOT delete its parent `WorkoutRecord`
- Nullable `exercises` array on `WorkoutRecord` handles nil correctly (v1.1 manual logging compatibility)

### Smart Counter Testing (SwiftData)
The `UserProfile.smartRoutineCountThisWeek` and `smartCounterWeekStart` fields are critical for the free tier algorithm gating. Test:
- Counter increments on routine generation, not on workout completion
- Counter resets to 0 when `smartCounterWeekStart` is before the current Monday midnight local time
- Counter reset happens at midnight Monday local time, not on first workout of the week
- Edge case: Sunday 11:59 PM workout does not reset counter; Monday 12:01 AM does
- Multiple sessions on the same day each increment the counter independently

### Schema Migration Testing
Reference: `team/developer/skills/ios-swiftdata.md` (Schema Strategy).

The initial versioned schema (e.g., `AppSchemaV1`) is the current schema. Test migration paths:
- Create data with V1 schema, apply V(N) migration, verify all fields preserved
- Test with production-like data volumes (not just single records)
- Verify nullable fields added in future versions default correctly
- Verify `VersionedSchema` + `SchemaMigrationPlan` are in place even for v1.0 (lightweight)

### @MainActor Considerations
ViewModels are `@MainActor @Observable` (`architecture.md` Section 3). Tests interacting with these must be `@MainActor`:

```swift
@Test @MainActor
func todayViewModelGeneratesRoutine() async throws {
    let vm = TodayViewModel(algorithm: mockAlgorithm, repository: mockRepo)
    await vm.generateRoutine()
    #expect(vm.currentRoutine != nil)
}
```

QA must flag any test accessing a `@MainActor` ViewModel without the `@MainActor` annotation -- it will compile but may produce data races under Swift 6.2 strict concurrency.

---

## 4. StoreKit 2 Testing

Reference: `team/developer/skills/ios-app-store.md`, `knowledge-base/architecture.md` Section 9.

### Xcode StoreKit Configuration Files
Verify the project includes a `.storekit` configuration file in the test plan for local testing without Apple sandbox:
- Two subscription products: monthly ($7.99) and annual ($49.99)
- Product identifiers match `StoreConfig` constants in production code
- Configuration enables: renewals, expiration, grace period simulation

### Sandbox vs Configuration Testing
| Test type | Environment | Use case |
|-----------|-------------|----------|
| Unit tests | StoreKit Configuration file | Fast, deterministic, CI-compatible |
| Integration tests | Sandbox (TestFlight) | Real Apple server behavior, receipt validation |
| Pre-release | Sandbox + physical device | Final verification before submission |

### Transaction.updates Listener
Verify the app registers a `Transaction.updates` listener at launch (the main `App.swift` entry point). Test scenarios:
- Renewal while app is backgrounded -- listener picks it up on foreground
- Expiration detected -- app downgrades to free tier without restart
- Revocation (refund) detected -- immediate downgrade
- Grace period entry and exit

### Subscription State Transitions
Critical path -- 100% coverage required. Test each transition end-to-end:

| From | To | Verify |
|------|------|--------|
| Free | Premium (purchase) | Auth flow triggers, account creation, local data migration, premium features unlock |
| Premium | Free (expiration) | Local data preserved, remote features disabled, algorithm switches to on-device, no error states |
| Free | Premium (restore) | `AppStore.sync()` restores entitlement, same unlock flow as purchase |
| Premium | Premium (renewal) | No interruption, subscription dates update |
| Premium | Free (refund) | `Transaction.revocationDate` triggers immediate downgrade |
| Premium (cancelled) | Grace period | Access continues, UI reflects upcoming expiration |

### Receipt Validation
StoreKit 2 uses on-device JWS verification via `Transaction.currentEntitlement(for:)`. QA verifies:
- No server-side receipt validation for MVP (StoreKit 2 handles it)
- `SubscriptionRepository` correctly maps entitlement state to `SubscriptionTier` enum
- Entitlement check runs on app launch and on `Transaction.updates` events

---

## 5. SwiftUI Testing Patterns

### ViewModel Testing (Primary Approach)
SwiftUI views should NOT be tested directly -- `@State` makes behavior unpredictable. Test the `@Observable` ViewModel instead:

```swift
@Test @MainActor
func onboardingViewModelValidatesMinimumOneDiscipline() async throws {
    let vm = OnboardingViewModel()
    vm.selectedDisciplines = []
    #expect(vm.canProceed == false, "Should block with no disciplines selected")

    vm.selectedDisciplines = [.yoga]
    #expect(vm.canProceed == true)
}
```

QA reviews must verify:
- All business logic lives in ViewModels, not inline in views
- `@Observable` ViewModels are tested by creating instances directly and asserting properties
- State transitions cover: loading, loaded, error, empty states (check for `Loadable` enum usage per `ios-mvvm.md`)

### Snapshot Testing
For visual regression, evaluate a snapshot testing library (e.g., swift-snapshot-testing). QA considerations:
- Capture baseline images for each screen in light mode, dark mode, and the smallest device (iPhone SE)
- Capture at all Dynamic Type sizes for accessibility-critical screens
- Store reference images in the test target, not the main target
- Snapshot tests are supplementary -- they catch unintended visual changes, not correctness

Note: Do not add a snapshot testing dependency without PM approval. Until then, use Xcode Previews for visual validation.

### Preview-Driven Visual Validation
For QA review of visual correctness without snapshot tests:
- Verify every screen has Xcode Preview definitions
- Previews must cover: default state, loading state, empty state, error state, free tier, premium tier
- Check previews render against both light and dark color schemes
- Verify previews use mock/sample data, not production data or live network calls

---

## 6. Performance Testing

### XCTest Measure Blocks
Performance tests use XCTest (not Swift Testing). Measure blocks run the code multiple times and report average/std deviation:

```swift
class RoutineGenerationPerformanceTests: XCTestCase {
    func testAlgorithmExecutionTime() throws {
        let algorithm = LocalAlgorithm(/* test dependencies */)
        let input = AlgorithmInput.sampleFreeUser

        measure {
            _ = algorithm.generate(from: input)
        }
    }
}
```

### Performance Budgets
Define and enforce budgets for critical operations. QA tracks these:

| Operation | Budget | Measured on |
|-----------|--------|-------------|
| App launch to interactive | < 2 seconds | Oldest supported device |
| Routine generation (on-device) | < 500ms | iPhone SE |
| Exercise animation start (cached) | < 100ms | iPhone SE |
| Exercise animation start (network) | < 3 seconds | Simulated slow network |
| Tab switch responsiveness | < 16ms (1 frame) | Any device |
| Full workout session memory | < 200MB peak | iPhone SE |

### Animation Frame Rate
Exercise animations must maintain 60fps. Test on the lowest-supported device:
- Use Instruments (Core Animation / Animation Hitches template) to measure frame drops during workout session playback
- Test scrolling the exercise library with thumbnails loading
- Test the thumbnail-to-animation crossfade transition
- Flag any frame that exceeds 16.67ms render time

### Memory Profiling
Use Instruments (Allocations / Leaks):
- Monitor memory during a full 10-15 exercise workout session
- Verify completed exercise animations are released from memory (not accumulated)
- Check for retain cycles in ViewModel → Service → Repository chains
- Verify `URLCache` respects the configured max size for asset caching
- Run Leaks instrument on the subscription purchase → migration → premium unlock flow

### Asset Loading Performance
Test against the pre-fetch strategy defined in `architecture.md` Section 13:
- When a routine is generated, all exercise animations begin pre-fetching immediately
- User should see animation (not placeholder) by the time they reach each exercise in sequence
- Test with a cold cache (first launch) and warm cache (subsequent sessions)
- Test `URLCache` hit rate after a typical usage session

---

## 7. Network Testing

### Protocol Mocking for Supabase Calls
The developer's architecture uses `URLSessionProtocol` injection (`team/developer/skills/ios-testing.md`). QA verifies:
- All network-dependent tests use `URLSessionMock` -- never live network calls in unit tests
- Mock responses use fixture JSON files stored in `TestFixtures/`
- Fixture files match the actual Supabase response format (snake_case keys, ISO 8601 dates)

### Supabase-Specific Mock Scenarios
Verify tests cover these Supabase response patterns:

| Scenario | Mock response |
|----------|--------------|
| Auth success | `{ "access_token": "...", "user": { ... } }` |
| Auth failure (wrong password) | HTTP 400, `{ "error": "invalid_grant" }` |
| Edge Function success (algorithm) | HTTP 200, routine response matching `AlgorithmOutput` |
| Edge Function timeout | No response within 15s budget |
| RLS violation (wrong user) | HTTP 403 or empty result set |
| Storage asset 404 | HTTP 404 for missing thumbnail/animation |
| Rate limit | HTTP 429 with `Retry-After` header |

### Offline/Online Transition Testing
Reference: `team/developer/skills/ios-networking.md` (Offline Handling), `architecture.md` Section 11.

Test the `NWPathMonitor`-based network detection:
- App transitions from online to offline mid-session: workout continues, mutations queue to `OfflineMutation` model
- App transitions from offline to online: queued mutations replay in order, idempotent server-side
- Intermittent connectivity: rapid on/off cycling does not corrupt queue or duplicate mutations
- UI shows offline indicator when disconnected, removes it on reconnect

### Asset Cache Testing
Reference: `architecture.md` Section 13 (exercise asset pipeline).

- First load: thumbnail fetched from Supabase Storage, cached via `URLCache`
- Second load: served from cache, no network request
- Cache eviction: when cache is full, LRU items are evicted, re-fetched on next access
- Placeholder fallback: if both cache and network fail, static placeholder silhouette displays (session must not crash or show blank frame)
- Animation pre-fetch: verify pre-fetch fires on routine generation, not on user tap

### Timeout and Retry Testing
Verify timeout budgets from `team/developer/skills/ios-networking.md`:
- Edge Function calls: 15s timeout for algorithm, 30s for data migration
- Asset loading: 10s timeout for thumbnails (per `architecture.md` Section 13)
- Retry behavior: verify retry count limits, exponential backoff if implemented
- User-facing error: verify timeout produces a user-friendly message, not a raw error

---

## 8. Code Coverage

### Xcode Coverage Configuration
- Enable code coverage in the test plan (Edit Scheme > Test > Options > Code Coverage)
- Configure to gather coverage for the main app target only, excluding test targets

### Coverage Targets

| Scope | Target | Rationale |
|-------|--------|-----------|
| Overall | 80% minimum | Enforced in CI, PR gate |
| Auth + subscription flows | 100% | Critical path: purchase, restore, downgrade, migration |
| Data deletion (F-PRO-4) | 100% | Legal requirement, App Store requirement |
| Algorithm engine | 100% | Core product value, regression risk |
| Health disclaimer flow | 100% | Legal/App Store compliance |
| New code (per PR) | Must include tests | No untested code merges. Coverage must not decrease |

### Exclusions
Exclude from coverage calculations:
- SwiftUI Preview providers (`#Preview` blocks)
- Generated code (SwiftData `@Model` macro expansions)
- `EnvironmentConfig` (reads from Bundle, tested at integration level)
- Shared UI library code (external dependency, not our test responsibility)

### Coverage Review Process
When reviewing PRs, QA checks:
- Coverage report attached or accessible
- No critical path dropped below 100%
- Overall coverage did not decrease from the previous baseline
- New files have corresponding test files (mirror structure: `UserProfileViewModel.swift` -> `UserProfileViewModelTests.swift`)

---

## Principles

1. **Swift Testing for logic, XCTest for UI and performance**: Never mix. Unit and integration tests use Swift Testing structs with `@Test`. UI automation uses `XCUITest`. Performance benchmarks use `XCTest.measure`. Flag any violation.

2. **In-memory containers, protocol mocks, fixture files**: Every test must be fast, isolated, and deterministic. SwiftData tests use in-memory `ModelContainer`. Network tests use `URLSessionProtocol` mocks. JSON fixtures match real Supabase response shapes. No live network calls, no disk I/O, no shared state.

3. **Two-tier testing is non-negotiable**: Every feature with a free/premium split needs both paths tested. Launch arguments control subscription state in UI tests. Algorithm tests cover both on-device (free) and mocked remote (premium) paths. The smart counter, recovery memory, and anti-repeat filter each need their own test cases on the free path.

4. **Performance budgets are specifications, not aspirations**: Define numeric budgets (launch time, generation time, frame rate, memory) and enforce them. Test on the lowest supported device. A budget violation is a bug, not a "nice to have" fix.
