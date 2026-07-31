#!/usr/bin/env bash
# DEPRECATED shim — renamed to muster-lint-queue.sh (lint-family naming); remove next major.
echo "muster: muster-queue-lint.sh is deprecated — use muster-lint-queue.sh" >&2
exec bash "$(dirname "$0")/muster-lint-queue.sh" "$@"
