# iOS Swift Concurrency

## Purpose
Define Swift concurrency patterns, actor usage, structured/unstructured concurrency, cancellation, async streams, callback bridging, and common bug patterns for iOS development. Target: Swift 6.2+ with strict concurrency. See the `ios-modern-api` skill for quick deprecated-vs-modern API flags. See Developer's `ios-testing` skill for async test patterns with Swift Testing.

## Actor Reentrancy
The #1 concurrency bug LLMs produce. After every `await` inside an actor, all assumptions about actor state are invalidated — other calls may have run during the suspension.

- **Never assume state is unchanged after `await`**. Capture async results into locals before writing back to actor state
- For deduplication, store in-flight `Task` handles in a dictionary keyed by request identifier. Return the existing task if one is already running. Clean up the entry in both success and error paths
- Force unwraps on actor state after `await` are prime crash targets — another caller may have set the value to nil

## Actors
- Custom actors introduce a serialized access boundary — external callers must use `await`, values crossing must be `Sendable`
- Flag actor types that own little mutable state or mostly forward work — simpler alternatives (value types, locks) may be better
- `assertIsolated()` on global actors halts in debug builds if not on the expected executor — useful for debugging, compiled out of release

## Global State & @MainActor
- Global/static mutable variables need explicit isolation: `@MainActor` for UI-related state, `@unchecked Sendable` only for types with proven internal locking
- `@MainActor` propagates to: subclasses, property wrapper storage, protocol conformances (including SwiftUI `View`), extensions. Does NOT propagate to closures passed to non-isolated functions
- Don't redundantly annotate when inference already applies — check target settings for default main-actor isolation
- `isolated` parameters: accept any actor instance and run on its executor without tying the function to a specific actor

## Swift 6.2 Changes
- **Default main-actor isolation**: Per-module setting. Most declarations implicitly `@MainActor`. Networking/async I/O still runs off main actor (external modules). Check target settings before flagging missing annotations
- **`nonisolated` async stays on caller's actor**: Plain async helpers no longer auto-offload to background. If background execution is needed, use `@concurrent`
- **`@concurrent`**: Explicit opt-in to leave caller's actor for CPU-heavy work (parsing, image processing, compression). Not for ordinary async I/O
- **Global-actor isolated conformances**: `extension MyType: @MainActor SomeProtocol {}` — compiler rejects wrong-isolation usage
- **`Task.immediate`**: Starts running synchronously on caller's executor up to first suspension. Task groups get `addImmediateTask()`. Use only when immediate start is the point
- **`isolated deinit`**: Runs deinit on the class's actor. Required when teardown touches actor-protected state
- **Priority escalation**: `withTaskPriorityEscalationHandler`, `escalatePriority(to:)` — usually automatic, manual is advanced
- **Task naming**: `Task(name: "MyTask") { }` and `group.addTask(name:)` — debugging aids for logs and tracing

## Structured Concurrency
- **`async let`** for fixed number of different-type operations. **Task groups** for dynamic same-type operations
- **Task groups over loops**: `for item in items { Task { } }` is almost always wrong — use `withThrowingTaskGroup` for cancellation, error collection, and awaiting all results
- **`withDiscardingTaskGroup`**: For side-effect-only child tasks — avoids result accumulation in memory
- **Concurrency limiting**: Launch initial batch of N tasks, replenish from iterator as each completes
- **Partial results**: Catch errors inside each child task to prevent group-wide cancellation. Return `Result` tuples
- **Type inference**: Sometimes need explicit `of:` parameter for complex return types

## Unstructured Concurrency
- `Task {}` inherits caller's actor isolation and priority. `Task.detached {}` does not — rarely correct, prefer `Task {}` with explicit isolation changes or structured concurrency
- **When `Task {}` is a code smell**: inside `onAppear()` (use `.task()`), bridging sync→async when caller could be async, ignoring return value of throwing task (error silently lost)
- Handle errors inside Task closures — show alert, log, or propagate via `@State`

## Cancellation
- Cancellation is **cooperative** — setting the flag does nothing unless code checks it
- **Propagation**: Parent→children automatic (structured). Unstructured tasks need explicit `.cancel()` on stored handle
- **Checking**: `try Task.checkCancellation()` in throwing contexts, `Task.isCancelled` for bool check. CPU-bound loops with no `await` need explicit checks
- **`withTaskCancellationHandler`**: Bridges Swift cancellation to legacy cancel mechanisms. `onCancel` fires immediately, any thread
- **SwiftUI `.task()`**: Cancels automatically on view disappear — primary reason to prefer over `onAppear()` + `Task {}`
- **Stored tasks**: Cancel previous before starting new one. Cancel in `deinit`
- **CancellationError**: Filter out before handling other errors — it's a normal lifecycle event, not an error to show users

## AsyncStream
- Use `AsyncStream.makeStream(of:)` factory — not the closure-based initializer
- **Continuation lifecycle**: Finish exactly once. Zero finishes = consumer hangs forever. `onTermination` for cleanup when consumer stops listening
- **Buffering**: Default is `.unbounded` (memory risk). Use `.bufferingNewest(n)` or `.bufferingOldest(n)` for high-throughput producers
- **`for await` and cancellation**: Loop auto-stops on task cancellation or stream finish. Post-loop code still runs — handle cleanup there
- **Single consumer only**. For multiple consumers, broadcast via `@Observable`

## Bridging Callback-Based APIs
- **Completion handlers → async**: Wrap with `withCheckedThrowingContinuation`. Resume exactly once on every path. If SDK provides async overload, use it directly
- **Delegates → AsyncStream**: Multi-value delegates map to `AsyncStream` via `makeStream(of:)`. Single-shot delegates use `withCheckedContinuation`
- **Always use checked continuations** (not unsafe) — the runtime checks catch double-resume and missing-resume bugs. Switch to unsafe only after profiling proves bottleneck
- **`MainActor.assumeIsolated()`**: Only when callback is genuinely main-actor-bound and compiler can't see it

## GCD Equivalents
| GCD | Swift Concurrency |
|-----|-------------------|
| `DispatchQueue.main.async {}` | `@MainActor` function, called with `await` |
| `DispatchQueue.global().async {}` | `@concurrent` function or task group |
| Serial `DispatchQueue` protecting state | `actor` |
| Locks (sync API required) | `Mutex` (preserves checked Sendable) or traditional locks |

GCD is still acceptable in low-level libraries, framework interop, and performance-critical synchronous sections — don't flag these blindly.

## Combine Equivalents
| Combine | Swift Concurrency |
|---------|-------------------|
| `publisher.sink {}` | `for await value in stream {}` |
| `publisher.map/filter {}` | `stream.map/filter {}` |
| `PassthroughSubject` | `AsyncStream` via `makeStream(of:)` |
| `publisher.values` | Already `AsyncSequence` — use directly |

Combine is not deprecated but Apple advises against it for new code.

## `@unchecked Sendable`
- **Legitimate**: Types with internal locking (`os_unfair_lock`, `NSLock`, `Mutex`) that are provably thread-safe
- **Red flags**: Applied to silence compiler errors without understanding why, mutable `var` properties with no sync, used as shortcut instead of restructuring
- **Check first**: Swift 6 region-based isolation may already solve the problem without `@unchecked Sendable`

## Diagnostics (Strict Concurrency Errors)
| Error | Fix (try in order) |
|-------|-------------------|
| "Sending 'x' risks data races" | Region-based isolation → `sending` parameter → make type Sendable → `nonisolated(nonsending)` → `@unchecked Sendable` (last resort) |
| "Static property not concurrency-safe" | `@MainActor` → Sendable conformance (immutable) → `nonisolated(unsafe)` (C interop only) → check target isolation settings |
| "Non-sendable capture in @Sendable closure" | Make type Sendable → restructure to avoid capture (`let id = obj.id; Task { use(id) }`) → move to same actor → `sending` parameter |
| "Conformance crosses into main actor-isolated code" | Remove type isolation OR use `@MainActor` conformance |
| "Expression is async but not marked with await" | Add `await`. If sync context, wrap in `Task {}` |
| "Main actor-isolated conformance in nonisolated context" | Move use site to same actor OR remove isolation from conformance |

## Bug Patterns
1. **Actor reentrancy check-then-act**: Read state → await → write assuming state unchanged. Fix: capture to local, use in-flight task dedup
2. **Continuation resumed zero times**: Caller hangs forever. Audit every code path
3. **Continuation resumed twice**: `CheckedContinuation` traps, `UnsafeContinuation` = undefined behavior. Guard with single-path wiring
4. **Unstructured tasks in loop**: No cancellation, no error collection. Fix: task group
5. **Swallowed errors in Task closures**: `Task { try await risky() }` — error silently lost. Handle inside closure
6. **Blocking main actor**: CPU work on `@MainActor` = UI freeze. Worse in Swift 6.2 (nonisolated async stays on caller). Fix: `@concurrent`
7. **Unbounded AsyncStream buffer**: Memory growth. Fix: `.bufferingNewest(n)`
8. **Ignoring CancellationError**: Filter out before handling — it's lifecycle, not an error
9. **`@unchecked Sendable` hiding races**: Silences compiler but race still exists at runtime

## Testing Concurrent Code
- Access actor properties via `await` in tests — don't add `nonisolated` accessors for testing
- **Testing cancellation**: Feed enough work that production code checks cancellation mid-flight, cancel task, expect `CancellationError`. Test must exercise production cancellation checks, not test-only ones
- **Race detection**: Enable Thread Sanitizer (TSan) in test scheme. Catches races static checks miss. Consider dedicated CI job (adds overhead)
- **Notification testing**: Use `Task.yield()` before posting to ensure `for await` listener is ready — prevents flaky tests

## Principles

1. **Structured over unstructured**: Prefer task groups and `async let` over `Task {}`. Structured concurrency gives you cancellation propagation, error collection, and lifetime management for free.

2. **Actors are not always the answer**: An actor is the right tool when you have mutable state accessed from multiple isolation domains. If the API must stay synchronous, use `Mutex`. If there's little mutable state, a value type may suffice. Don't reach for actors by default.

3. **Every `await` is a potential state change**: Inside actors, never assume state is the same after a suspension point. This is the single most common concurrency bug — treat every `await` as a checkpoint where the world may have changed.

4. **Cancellation is your responsibility**: The runtime sets a flag; your code must check it. CPU-bound loops, stored tasks, and legacy API bridges all need explicit cancellation handling.
