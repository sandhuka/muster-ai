# Bug Reporting Standards

## Purpose
Define the bug report template, severity definitions, triage process, and bug lifecycle. See `team/qa/skills/test-strategy.md` for the testing methodology that generates bug findings.

## Output
Bug reports are filed in `knowledge-base/agent-requests.md` (for cross-agent visibility) or tracked in `knowledge-base/current-sprint.md` during active sprints.

## Bug Report Template
**Title**: [Screen/Feature] Brief description of the issue
**Severity**: Critical / High / Medium / Low
**Steps to Reproduce**:
1. Start from [known state]
2. [Action]
3. [Action]
4. Observe: [what happens]
**Expected Result**: [What should happen]
**Actual Result**: [What actually happens]
**Environment**: Device, OS version, app version, network conditions
**Screenshots/Video**: [Attach]
**Frequency**: Always / Often / Sometimes / Rarely / Once
**Workaround**: [If any]

## Severity Definitions
- **Critical**: App crash, data loss, security vulnerability, complete feature failure, blocks core user journey. Fix immediately, hotfix if in production.
- **High**: Major feature broken for many users, significant UX issue, poor workaround exists. Fix in current sprint.
- **Medium**: Minor feature issue, cosmetic problem affecting usability, edge case failure. Schedule for next sprint.
- **Low**: Cosmetic only, rare edge case, minor polish. Backlog, fix when convenient.

## Triage Process
1. QA files bug with severity assessment
2. PM validates severity and sets priority (severity ≠ priority — a Low severity bug on the login screen may be High priority)
3. Developer assigned based on sprint capacity and expertise
4. Developer fixes and marks for re-test
5. QA verifies fix on staging environment
6. QA closes bug or reopens with additional info

## Bug Lifecycle
Open → Triaged → Assigned → In Progress → Fixed → Verified → Closed
(or) → Reopened (if fix incomplete)
