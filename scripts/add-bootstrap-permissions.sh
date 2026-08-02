#!/usr/bin/env bash
# DEPRECATED shim — absorbed into muster-update.sh (the one post-bump converge command); remove next major.
echo "muster: add-bootstrap-permissions.sh is deprecated — use muster-update.sh" >&2
exec bash "$(dirname "$0")/muster-update.sh" "$@"
