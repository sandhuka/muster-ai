# iOS Testing

## Purpose
Define testing standards using Swift Testing (primary) and XCTest (UI tests only) for iOS codebases. See `team/developer/skills/ios-code-standards.md` for naming conventions. See `team/developer/skills/ios-swiftdata.md` for in-memory persistence testing patterns. See `team/developer/skills/ios-modern-api.md` for concurrency rules relevant to async tests.

## Running Tests — Quiet by Default, Targeted Then Full

Test EXECUTION is free; test OUTPUT is not — every line a runner prints into the session is
context re-read on every subsequent turn, and xcodebuild is the loudest offender (thousands of
build + per-test lines per run).

- **Quiet by default**: run suites through the project's `scripts/test.sh` (raw output → log
  file; the session sees pass/fail counts, failing tests with file:line, exit code). Read the
  log only for a specific failure's detail — never ingest a full verbose run.
- **Targeted then full**: while iterating on a fix, run only the affected test class
  (`-only-testing:AppTests/UserProfileViewModelTests`). The FULL suite runs exactly once, at
  pre-closeout — one full run per step, not per iteration.
- **CI is a backstop, never the gate**: you must know the suite is green BEFORE closeout — the
  queue never advances past a red build. CI re-running the suite on push is welcome redundancy
  (its failures land in `founder-notices.md`), but waiting on CI to learn your own result is a
  closeout violation.

## Testing Pyramid
- Unit tests: 70% — ViewModels, Services, Models in isolation (Swift Testing)
- Integration tests: 20% — Feature flows, API contract validation (Swift Testing)
- UI tests: 10% — Critical user paths only (XCTest — Swift Testing does NOT support UI tests)

## Test Quality (FIRST)
Tests must be: **F**ast (hundreds per second), **I**solated (no shared state or ordering), **R**epeatable (same result every run), **S**elf-verifying (unambiguous pass/fail), **T**imely (written alongside production code).

## Test Generation Heuristics
For each function, aim to cover: happy path, boundary conditions, invalid inputs, and (if applicable) concurrency behavior.

## Swift Testing Core Rules
- Use **structs** for test suites, not classes. Classes are allowed but structs are preferred
- `@Suite` is unnecessary on most structs — any type containing `@Test` methods is automatically a suite. Only use `@Suite` to add a name or traits: `@Suite(.tags(.networking))`
- Use `init()` for setup, not `setUp()`/`tearDown()`. Suite initializers can be `async throws`. Must accept no parameters
- No `test` prefix needed on method names — `func userCanLogOut()` not `func testUserCanLogOut()`
- No need for `XCTestCase`, `XCTAssert*`, or any XCTest API in unit/integration tests

## Assertions
- `#expect(condition)` — soft assertion, test continues on failure
- `#require(condition)` — hard assertion, throws and stops the test on failure. Use for preconditions
- `try #require(optional)` — unwrap or fail (replaces `XCTUnwrap`)
- `Issue.record("message")` — manually record a failure (replaces `XCTFail`)
- **Never use `!` to negate in `#expect`/`#require`** — `#expect(!isLoggedIn)` defeats macro expansion and gives unhelpful failure messages. Use `#expect(isLoggedIn == false)` instead
- `#expect(throws: ErrorType.self) { code }` returns the error for further validation. Always name the specific error — `#expect(throws: GameError.notInstalled)` not `#expect(throws: Error.self)`
- `#expect(throws: Never.self) { code }` — assert that code does NOT throw
- For fine-grained error assertions: `do/try/catch` with `Issue.record()` on unexpected paths
- Float tolerance: use Swift Numerics `isApproximatelyEqual(to:absoluteTolerance:)` — no built-in equivalent. Do not add Swift Numerics without permission
- Add user-facing messages to `#expect`/`#require` when they clarify intent — not always needed but usually helpful
- Use `#require` for preconditions at the start of a test — if assumptions are wrong, remaining assertions are meaningless

## Parameterized Tests
- Prefer parameterized tests to reduce code while increasing coverage
- At most two argument collections — two collections form a **Cartesian product**, not pairwise
- For pairwise zipping: pass `zip(collection1, collection2)` as the arguments
- `.serialized` trait only works on parameterized tests — it has NO effect on non-parameterized tests

## Tags
Define with `@Tag`, apply with `.tags()`:
```swift
extension Tag {
    @Tag static var networking: Self
}

@Test(.tags(.networking))
func fetchProfile() async throws { }
```
Tags categorize tests across suites for filtering and running by category. Recommended tags: `.networking`, `.slow`, `.edgeCase`, `.smoke`.

## Traits
- `.bug(id: 182)` or `.bug("https://github.com/repo/issues/182")` — link tests to bug reports for context if the bug resurfaces
- `.enabled(if: condition)` / `.disabled(if: condition)` — conditional test execution
- `.timeLimit(.minutes(N))` — see Async Testing

## Async Testing
- Tests run in **parallel by default** — each test must be independent and order-agnostic
- `confirmation(expectedCount:)` — async work must complete before the closure ends. Either make code `async` or return the `Task` and `await task.value` before calling `confirm()`
- `confirmation(expectedCount: 0)` — asserts the event never happens
- Range-based confirmations: `confirmation(expectedCount: 5...10)` or `confirmation(expectedCount: 5...)`
- Time limits: `.timeLimit(.minutes(N))` only — **`.seconds()` does NOT exist**. Suite-level limits apply to each test individually; shorter of suite vs test limit wins
- Actor isolation: mark tests or suites `@MainActor`. `confirmation()` and `withKnownIssue()` accept `isolation:` parameter for per-closure isolation
- Callback-based APIs: wrap with `withCheckedContinuation` to bridge into async context

## Known Issues
- `withKnownIssue("description") { code }` — expects a failure, fails the test if none occurs
- `isIntermittent: true` — passes if no issue, marks expected failure if one occurs (for flaky bugs)

## Additional Features
- **Raw identifiers**: `` func `Strip HTML tags from string`() `` — suggest but don't adopt unless already used in project
- **Exit tests**: `await #expect(processExitsWith: .failure) { code }` — tests `precondition()`/`fatalError()` terminations in a subprocess
- **Attachments**: `Attachment.record(value, named: "Label")` — attach `String`, `Data`, or `Encodable` to test results for debugging. No image support before Swift 6.3. No lifetime controls
- **Test scoping traits**: Custom `TestTrait & TestScoping` for concurrency-safe shared config (e.g., `@TaskLocal` values). Apply with `@Test(.customTrait)`
- **ConditionTrait.evaluate()**: Evaluate condition traits outside of tests

## Testing SwiftUI Code
- Never test views directly — `@State` makes them behave unpredictably
- Test ViewModels or extracted business logic instead
- `@Observable` ViewModels are directly testable — create an instance and assert on properties/methods. No protocol wrapper needed
- If logic is inline in a view, extract it to a ViewModel for testability

## Dependency Injection for Testability
Avoid hidden dependencies (`UserDefaults.standard`, `URLSession.shared`, `Date()`, etc.) in production code. Inject them with sensible defaults:
- `URLSession`: protocol injection (see Network Mocking below)
- `UserDefaults`: inject with default `.standard`, test with unique suite: `UserDefaults(suiteName: "suite-\(UUID())")` + `defer { removePersistentDomain }`
- Time/randomness: inject closures or protocols to control in tests

## Verification Methods
Wrap repeated multi-assertion checks in helper functions. Pass `SourceLocation` so failures report at the test call site, not inside the helper:
```swift
func verify(_ result: Result, expected: Int, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(result.value == expected, sourceLocation: sourceLocation)
}
```
`#require` also accepts `sourceLocation:`.

## Custom Test Output
Add `CustomTestStringConvertible` conformance in the **test target only** to make custom types readable in test results. Never add in production code.

## Network Mocking
Mock networking via protocol injection — never do live networking in unit tests:
1. Define protocol matching `URLSession` methods needed: `protocol URLSessionProtocol { func data(from:) async throws -> (Data, URLResponse) }`
2. Extend `URLSession: URLSessionProtocol`
3. Create `URLSessionMock` conforming to same protocol with `testData`/`testError` properties
4. Inject mock into code under test

## Test Organization
- Mirror source folder structure in Tests/
- One test file per source file: `UserProfileViewModel.swift` → `UserProfileViewModelTests.swift`
- Shared test helpers and mock objects in `TestUtilities/`
- Mock JSON responses in `TestFixtures/`

## Coverage Targets
- Overall: 80% minimum
- Critical paths (auth, payments, sensitive data): 100%
- New code: must include tests in the same PR
- Coverage tracked per PR, ratchet up over time (never decrease)

## What to Test
- All ViewModel logic and state transitions
- Data transformations and business rules
- Network request/response parsing (use mock fixtures)
- Error handling paths
- Edge cases: empty states, max values, nil inputs, boundary conditions

## What NOT to Test
- SwiftUI view layout (use Xcode Previews instead)
- Apple framework internals
- Trivial getters/setters with no logic
- Third-party library internals

## Principles

1. **Protocol contracts over mocks**: When testing dual-backend patterns (local/remote), write shared test cases that run against both implementations via the protocol. This catches contract drift between backends.

2. **In-memory persistence for speed**: Use SwiftData in-memory `ModelContainer` for local repository tests — no mocks needed for the persistence layer, and tests run instantly.

3. **Swift Testing first, XCTest for UI only**: All new unit and integration tests use Swift Testing. XCTest is reserved exclusively for UI tests. Do not mix frameworks within the same test target unless migrating.

4. **Tests must be independent**: Parallel execution is the default. No test may depend on another test's state, ordering, or side effects. Each test creates its own state via `init()`.
