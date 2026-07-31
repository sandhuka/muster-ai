#!/usr/bin/env bash
# DEPRECATED shim — renamed to muster-lint-requests.sh (lint-family naming); remove next major.
echo "muster: muster-requests-lint.sh is deprecated — use muster-lint-requests.sh" >&2
exec bash "$(dirname "$0")/muster-lint-requests.sh" "$@"
