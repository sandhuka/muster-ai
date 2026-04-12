# Release Checklist

## Purpose
Define the pre-release, TestFlight, App Store submission, and post-release checks that gate every release. See `team/qa/skills/test-strategy.md` for regression requirements that must pass before release and `knowledge-base/current-sprint.md` for sprint completion gates.

## Pre-Release (Before TestFlight Build)
- [ ] All sprint tasks marked complete by assigned agents
- [ ] Automated test suite passes: unit + integration (CI green)
- [ ] Full manual regression pass on staging build
- [ ] No open Critical or High severity bugs
- [ ] Performance benchmarks within targets (launch time, memory, battery)
- [ ] Accessibility audit pass (VoiceOver, Dynamic Type, contrast)
- [ ] Legal review complete for any new product claims or data collection changes
- [ ] Content review: all new copy proofread, brand voice consistent
- [ ] App Store metadata updated: screenshots, description, "What's New" text
- [ ] Privacy "nutrition labels" updated if data practices changed

## TestFlight / Internal Release
- [ ] TestFlight build uploaded and distributed to internal testers
- [ ] 24-48 hour soak test period (monitor crashes, ANRs, performance)
- [ ] Key stakeholder sign-off (founder/PM)
- [ ] Beta tester feedback reviewed and critical issues addressed

## App Store Submission
- [ ] Phased rollout enabled (start at 10% or 20%)
- [ ] Monitoring dashboards active: crash rate, API errors, app ratings
- [ ] Support team briefed on new features and known issues
- [ ] Rollback plan documented (what to do if critical issue found)

## Post-Release (First 48 Hours)
- [ ] Monitor crash-free rate (target: >99.5%)
- [ ] Monitor app store reviews for new issues
- [ ] Check server-side metrics (API latency, error rates)
- [ ] Increase rollout percentage if metrics healthy (10% → 50% → 100%)
- [ ] Update knowledge-base/decision-log.md with release notes
- [ ] Update knowledge-base/current-sprint.md to close out sprint
