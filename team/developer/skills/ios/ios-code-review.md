# iOS Code Review

## Purpose
Define a systematic review process for SwiftUI/iOS code. Use when reviewing PRs, auditing existing code, or validating implementation quality. See individual skill files referenced in each step for the specific rules to check against.

## Review Process

Run these checks in order. For partial reviews, load only the relevant skill files.

| Step | Focus | Reference Skill |
|------|-------|-----------------|
| 1 | Modern API — flag deprecated APIs, suggest replacements | `ios-modern-api.md` |
| 2 | Views & composition — subview extraction, body complexity, view vs computed property | `ios-swiftui.md` (View Composition) |
| 3 | Data flow & state — @Observable usage, state ownership, binding patterns | `ios-swiftui.md` (State Management) |
| 4 | Navigation & presentation — NavigationStack, sheets, alerts | `ios-swiftui.md` (Navigation, Presentation) |
| 5 | Design & HIG — platform patterns, system styling, flexible layout | `ios-best-practices.md` (HIG) |
| 6 | Accessibility — Dynamic Type, VoiceOver, Reduce Motion, color | `ios-accessibility.md` |
| 7 | Performance — view identity, lazy loading, initializer weight | `ios-swiftui.md` (Performance) |
| 8 | Swift standards — naming, concurrency, modern API | `ios-code-standards.md` + `ios-modern-api.md` (Swift API) |
| 9 | Code hygiene — secrets, localization, error handling, linting | `ios-code-standards.md` + `ios-security.md` (secrets, keychain) |

## Output Format

Organize findings by file. For each issue:
1. State the file and relevant line(s)
2. Name the rule being violated
3. Show a brief before/after code fix

Skip files with no issues. End with a prioritized summary of the most impactful changes.

```
### FileName.swift

**Line 12: [Rule violated]**
// Before
<problematic code>

// After
<fixed code>

### Summary
1. **[Category] (high):** Description of issue
2. **[Category] (medium):** Description of issue
```

## SwiftData Review (if project uses SwiftData)

Run these additional checks on any code touching SwiftData models or queries.

| Step | Focus | Reference Skill |
|------|-------|-----------------|
| S1 | Core rules — relationships, delete rules, saving, concurrency, property restrictions | `ios-swiftdata.md` (Model Definitions through Concurrency) |
| S2 | Predicates — flag dangerous patterns that crash at runtime | `ios-swiftdata.md` (Predicates) |
| S3 | CloudKit constraints (if applicable) — uniqueness, optionality, eventual consistency | `ios-swiftdata.md` (CloudKit) |
| S4 | Indexing opportunities — frequently queried properties | `ios-swiftdata.md` (Indexing) |
| S5 | Class inheritance — schema setup, predicate filtering | `ios-swiftdata.md` (Class Inheritance) |

## Concurrency Review (if PR touches async/actor/Task code)

Grep for these hotspots and inspect using the referenced sections.

| Hotspot | What to check | Reference |
|---------|---------------|-----------|
| `DispatchQueue` | Should it be `@MainActor`, `@concurrent`, or task group? GCD OK in low-level/framework code | `ios-concurrency.md` (GCD Equivalents) |
| `Task.detached` | Rarely correct — should it be `Task {}` or structured concurrency? | `ios-concurrency.md` (Unstructured) |
| `Task {}` in a loop | Should be a task group | `ios-concurrency.md` (Structured) |
| `withCheckedContinuation` | Resumed exactly once on every path? | `ios-concurrency.md` (Bridging) |
| `AsyncStream` (closure form) | Use `makeStream(of:)`. Continuation finished in all paths? | `ios-concurrency.md` (AsyncStream) |
| `@unchecked Sendable` | Provably thread-safe? Or silencing a real race? | `ios-concurrency.md` (@unchecked Sendable) |
| `MainActor.run {}` | Already on MainActor? Function should just be `@MainActor`? | `ios-concurrency.md` (Global State) |
| Actor methods with `await` | Reentrancy: state read → await → stale write? Force unwrap after await? | `ios-concurrency.md` (Actor Reentrancy) |

## Testing Review (if PR includes tests)

Run these checks on test code.

| Step | Focus | Reference Skill |
|------|-------|-----------------|
| T1 | Core conventions — structs not classes, @Test not test prefix, #expect/#require not XCTAssert, init not setUp | `ios-testing.md` (Core Rules, Assertions) |
| T2 | Test structure — independence, parameterized tests, tags, no XCTest in unit/integration tests | `ios-testing.md` (Parameterized Tests, Tags) |
| T3 | Async patterns — confirmation usage, time limits (.minutes only), actor isolation, network mocking | `ios-testing.md` (Async Testing, Network Mocking) |
| T4 | Additional features — raw identifiers, exit tests, attachments, test scoping traits | `ios-testing.md` (Additional Features) |

## Partial Reviews

- **Quick API check**: Steps 1, 8 only
- **Accessibility audit**: Steps 5, 6 only
- **Performance review**: Steps 2, 7 only
- **Concurrency review**: Hotspot grep table
- **SwiftData review**: Steps S1-S2 (+ S3 if CloudKit)
- **Testing review**: Steps T1-T4
- **New feature review**: All 9 steps + applicable Concurrency/SwiftData/Testing steps

## Principles

1. **Report only genuine problems**: Do not nitpick or invent issues. If code works correctly and follows modern patterns, say so.

2. **Prioritize by impact**: Accessibility and correctness issues outrank style preferences. Order the summary by what matters most to users and stability.

3. **Show, don't just tell**: Every finding must include a concrete before/after fix. Abstract advice without a code example is not actionable.
