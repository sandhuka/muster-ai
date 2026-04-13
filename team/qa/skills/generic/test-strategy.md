# Test Strategy

## Purpose
Define testing levels, coverage targets, environment strategy, and the device testing matrix. See `team/qa/skills/bug-reporting.md` for the bug workflow that test findings feed into and `team/qa/skills/release-checklist.md` for test gates that must pass before release.

## Testing Levels
1. **Unit**: Individual functions and methods — Developer owns, QA reviews coverage
2. **Integration**: Feature flows and API contracts — shared ownership (Dev + QA)
3. **System**: Full app testing on real devices and simulators — QA owns
4. **Acceptance**: User story validation against PM-defined acceptance criteria — QA + PM

## Test Coverage Targets
- Unit tests: 80% code coverage minimum (enforced in CI)
- Critical paths: 100% coverage (authentication, payments, [sensitive data handling])
- Integration: All API endpoints tested with mock and staging servers
- UI automation: All primary user journeys (onboarding, core loop, subscription)

## Two-Tier Test Design
Every feature with a free/premium split needs test cases for both paths:

- **Free path tests**: Verify the feature works correctly with local-only data, no auth, and any free-tier limitations on [core intelligence/features]. Confirm premium-gated features show the correct upgrade prompt, not an error
- **Premium path tests**: Verify the feature works with [backend] auth, full [feature set], and cloud data. Test that premium-only features are visible and functional
- **Gate validation**: For every gated feature, test that: (1) free users see the upgrade banner/prompt, (2) tapping it opens the subscription sheet, (3) after subscribing, the feature unlocks without requiring app restart
- **Subscription state transitions**: Test upgrade (free → premium), downgrade/expiration (premium → free), restoration (re-subscribe), and the data migration (local → cloud). Verify that downgraded users retain access to their local data and revert to free-tier behavior

## [Product Intelligence] Validation Testing
If your product has algorithmic decision-making, test that it produces correct results:

- **Core logic validation**: Given known input state, verify the algorithm selects the expected output. Test that constraints are respected (e.g., no [action] within minimum [cooldown period])
- **Constraint enforcement**: For each [constraint type], validate that the algorithm respects configured parameters. Test edge cases: what happens at exactly the boundary
- **Scaling/progression**: Verify that [difficulty/intensity/volume] scales appropriately based on user level and progression rules
- **Rule interaction**: Test combinations of rules to ensure they don't conflict. When multiple constraints apply simultaneously, verify the algorithm handles the intersection correctly
- **Regression testing**: Maintain a set of "golden" test cases — fixed inputs with known-correct outputs. Run these on every algorithm change. Include edge cases: new user (no history), returning user after extended absence, user with minimal [options/input]

## [Media/Content] Performance Testing
If your product serves rich media content:

- **Frame rate / load time**: [Media content] should maintain target performance on the lowest-supported device. Test on [minimum device] to catch performance issues early
- **Pre-fetch validation**: When [a session/experience] is generated, verify that all required [media assets] begin pre-fetching. Confirm assets are available by the time the user reaches them
- **Memory consumption**: Monitor memory during a full [session]. Verify that completed [media assets] are released from memory. Set a memory budget and flag if exceeded
- **Fallback behavior**: If [media] fails to load, verify [fallback content] displays and the experience continues without interruption

## Offline & Sync Testing (Cloud-Backed Tier)
- **Cached content**: Disconnect network, verify the latest cached [content/data] is accessible. Verify the user can complete their [core action] offline
- **Queued actions**: Complete [core action] while offline. Reconnect and verify the action syncs to [backend] correctly — all relevant data should update
- **Reconnection sync**: Simulate intermittent connectivity. Verify no data is lost and the queue drains correctly when stable connection returns
- **Data migration**: Test the local → cloud migration: verify all local data appears in the cloud after migration. Test partial failure: if migration fails mid-way, verify it can be retried without duplicating data

## Environment Strategy
- **Local/Dev**: Xcode simulators, mock data, fast iteration
- **Staging**: TestFlight builds, staging API, seed data that mirrors production patterns
- **Production**: Phased rollout (10% → 25% → 50% → 100%), feature flags for rollback

## Regression Strategy
- Automated regression suite runs on every PR (CI gate — must pass to merge)
- Full regression before each App Store release
- Smoke test suite for hotfix validation (15-minute critical path check)
- Regression suite maintained by QA, execution automated in CI

## Device Testing Matrix
- Minimum: [smallest supported device], current [mainstream device], [largest device]
- OS versions: current and current-1 (e.g., iOS 18 and iOS 17)
- Include one iPad if iPad layout is supported
- Test on physical device before each release (simulator misses performance and sensor issues)

## Testing Principles

1. **Test both tiers for every gated feature**: Every feature with a free/premium split needs test cases for both paths. A passing premium test with a missing free-path test is incomplete coverage.

2. **Golden test cases for algorithm regression**: Maintain fixed-input/known-output test cases for any algorithmic decision-making. Run on every algorithm change. Include edge cases that stress constraint interactions.

3. **Test on the lowest device first**: [Minimum supported device] is the performance floor. If [media] performs well and layouts fit on the smallest device, they'll work everywhere.

4. **Offline is a first-class test path**: Cloud-backed offline mode (cached content, queued actions, reconnection sync) must be tested as thoroughly as online mode — not as an afterthought.

5. **Subscription state transitions are critical paths**: Upgrade, downgrade, expiration, restoration, and data migration are among the highest-risk flows. Test every transition and verify data integrity across each.
