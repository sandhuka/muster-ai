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
- Critical paths: 100% coverage (authentication, payments, health data handling)
- Integration: All API endpoints tested with mock and staging servers
- UI automation: All primary user journeys (onboarding, core loop, subscription)

## Two-Tier Test Design
Every feature with a free/premium split needs test cases for both paths:

- **Free path tests**: Verify the feature works correctly with local-only data, no auth, and the basic algorithm (rules 3,4,5,7,9). Confirm premium-gated features show the correct upgrade prompt, not an error
- **Premium path tests**: Verify the feature works with Supabase auth, full algorithm (all 10 rules), and cloud data. Test that premium-only features (recovery indicators, future day previews, weekly plan) are visible and functional
- **Gate validation**: For every gated feature, test that: (1) free users see the upgrade banner/badge, (2) tapping it opens the subscription sheet, (3) after subscribing, the feature unlocks without requiring app restart
- **Subscription state transitions**: Test upgrade (free → premium), downgrade/expiration (premium → free), restoration (re-subscribe), and the one-shot data migration (local → Supabase). Verify that downgraded users retain access to their local data and revert to basic algorithm

## Algorithm Validation Testing
How to verify the routine assembly logic produces correct results:

- **Muscle group rotation**: Given a workout history, verify the algorithm selects the expected discipline and muscle groups based on recovery windows. Test that no muscle group is trained within its minimum recovery window
- **Recovery window enforcement**: For each discipline, validate that the algorithm respects the configured recovery periods (e.g., 48 hours for strength, 24 hours for stretching). Test edge cases: what happens at exactly the recovery boundary
- **Pace scaling**: Verify that exercise difficulty/volume scales appropriately based on user fitness level and progressive overload rules
- **Rule interaction**: Test combinations of rules to ensure they don't conflict. E.g., if rule 3 (muscle rotation) and rule 7 (equipment availability) both constrain the result, verify the algorithm handles the intersection correctly
- **Regression testing**: Maintain a set of "golden" test cases — fixed inputs with known-correct outputs. Run these on every algorithm change to catch regressions. Include edge cases: new user (no history), user who missed 7 days, user with minimal equipment

## Animation Performance Testing
- **Frame rate**: Looping exercise animations should maintain 60fps during playback. Test on the lowest-supported device (iPhone SE) to catch performance issues early
- **Pre-fetch validation**: When a routine is generated, verify that all exercise animations for that routine begin pre-fetching. Confirm animations are available (cached or loaded) by the time the user reaches each exercise in the session
- **Memory consumption**: Monitor memory during a full workout session (10-15 exercises with looping animations). Verify that completed exercise animations are released from memory. Set a memory budget and flag if exceeded
- **Thumbnail fallback**: If an animation fails to load, verify the static thumbnail displays as fallback and the session continues without interruption

## Offline & Sync Testing (Premium)
- **Cached routine**: Disconnect network, verify the latest cached routine and 7-day plan are accessible. Verify the user can start and complete a session offline
- **Queued completions**: Complete a workout while offline. Reconnect and verify the completion syncs to Supabase correctly — workout history, streak data, and recovery state should all update
- **Reconnection sync**: Simulate intermittent connectivity during a session. Verify no data is lost and the queue drains correctly when stable connection returns
- **Data migration**: Test the one-shot local → Supabase migration: verify all local data (profile, history, preferences) appears in the cloud after migration. Test partial failure: if migration fails mid-way, verify it can be retried without duplicating data

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
- Minimum: iPhone SE (smallest), current iPhone (mainstream), Pro Max (largest)
- OS versions: current and current-1 (e.g., iOS 18 and iOS 17)
- Include one iPad if iPad layout is supported
- Test on physical device before each release (simulator misses performance and sensor issues)

## Testing Principles

1. **Test both tiers for every gated feature**: Every feature with a free/premium split needs test cases for both paths. A passing premium test with a missing free-path test is incomplete coverage.

2. **Golden test cases for algorithm regression**: Maintain fixed-input/known-output test cases for the routine assembly algorithm. Run on every algorithm change. Include edge cases: new user (no history), user who missed 7 days, user with minimal equipment.

3. **Test on the lowest device first**: iPhone SE is the performance floor. If animations hit 60fps and layouts fit on SE, they'll work everywhere. Testing on Pro Max first hides real-world issues.

4. **Offline is a first-class test path**: Premium offline mode (cached routine, queued completions, reconnection sync) must be tested as thoroughly as online mode — not as an afterthought.

5. **Subscription state transitions are critical paths**: Upgrade, downgrade, expiration, restoration, and the one-shot data migration are among the highest-risk flows. Test every transition and verify data integrity across each.
