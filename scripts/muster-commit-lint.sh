#!/usr/bin/env bash
# DEPRECATED shim — renamed to muster-lint-commit.sh (lint-family naming); remove next major.
echo "muster: muster-commit-lint.sh is deprecated — use muster-lint-commit.sh" >&2
exec bash "$(dirname "$0")/muster-lint-commit.sh" "$@"
