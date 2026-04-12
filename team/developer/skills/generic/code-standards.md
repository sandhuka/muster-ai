# Code Standards

## Purpose
Define platform-agnostic development standards: git workflow, PR process, and commit conventions. See platform-prefixed skill files (e.g., `team/developer/skills/ios-code-standards.md`) for language-specific naming, file organization, and tooling conventions.

## Git Workflow
- Branch naming: `feature/short-description`, `fix/short-description`, `refactor/short-description`
- Commit messages: imperative mood, 50-char subject, blank line, body if needed
- PR requires: description of changes, testing notes, screenshots if UI change
- Squash merge to main

## Code Review Checklist
- [ ] Error paths handled gracefully
- [ ] No hardcoded strings (use localization)
- [ ] New public APIs documented
- [ ] Unit tests for new logic
- [ ] No credentials or secrets in code
