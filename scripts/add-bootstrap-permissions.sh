#!/usr/bin/env bash
# Muster — Enable scripted bootstrap (replaces inline bash commands with script calls)
#
# For existing v3 muster projects: updates CLAUDE.md bootstrap block to call
# muster/scripts/muster-housekeeping.sh + muster/scripts/muster-bind.sh instead
# of inlining those commands, and adds the matching pre-approval entries to
# .claude/settings.json so they fire without permission prompts.
#
# Idempotent. Re-running is a no-op if already applied.
#
# Usage:
#   bash muster/scripts/add-bootstrap-permissions.sh           # apply
#   bash muster/scripts/add-bootstrap-permissions.sh --dry-run # report what would change
#
# Prerequisites:
#   - Run from project root (where .claude/, knowledge-base/, muster/ live)
#   - muster submodule updated (must contain muster-housekeeping.sh + muster-bind.sh)
#   - jq installed (used for clean settings.json merge)

set -euo pipefail

DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "Unknown arg: $arg" >&2; exit 1 ;;
    esac
done

# ---------- color helpers ----------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; GREEN=$'\033[32m'
    YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
    BOLD=''; DIM=''; GREEN=''; YELLOW=''; RED=''; RESET=''
fi
say() { printf "%s\n" "$*"; }
ok()  { printf "  %s✓%s %s\n" "$GREEN$BOLD" "$RESET" "$1"; }
skip(){ printf "  %s·%s %s %s(%s)%s\n" "$DIM" "$RESET" "$1" "$DIM" "$2" "$RESET"; }
warn(){ printf "  %s⚠%s %s\n" "$YELLOW" "$RESET" "$1"; }
err() { printf "%sError:%s %s\n" "$RED$BOLD" "$RESET" "$*" >&2; }

# ---------- preflight ----------
if [ ! -d ".claude" ] || [ ! -d "muster" ]; then
    err "Run from project root (must have .claude/ and muster/)."
    exit 1
fi

if [ ! -f "muster/scripts/muster-housekeeping.sh" ] || [ ! -f "muster/scripts/muster-bind.sh" ]; then
    err "muster/scripts/muster-housekeeping.sh or muster-bind.sh missing."
    err "Update the muster submodule first: cd muster && git pull && cd .."
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    err "jq is required. Install with: brew install jq  (or apt/dnf install jq)"
    exit 1
fi

if [ ! -f "CLAUDE.md" ]; then
    err "CLAUDE.md not found at project root."
    exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then
    say "${BOLD}DRY RUN — no files will be modified.${RESET}"
fi
say ""
say "${BOLD}Enabling scripted bootstrap in this project${RESET}"
say ""

# ---------- step 1: patch CLAUDE.md bootstrap block ----------
say "${BOLD}Step 1:${RESET} CLAUDE.md bootstrap block"

# Source of truth for the new bootstrap block: muster/templates/CLAUDE.md.
# We extract the block between markers from the template and use that.
if [ ! -f "muster/templates/CLAUDE.md" ]; then
    err "muster/templates/CLAUDE.md not found. Update the muster submodule."
    exit 1
fi

if ! grep -q '<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->' CLAUDE.md || \
   ! grep -q '<!-- END BOOTSTRAP -->' CLAUDE.md; then
    err "CLAUDE.md missing BOOTSTRAP markers."
    err "Cannot safely auto-replace. Manually copy block from muster/templates/CLAUDE.md and re-run."
    exit 1
fi

# Extract new block from template into a temp file (works around BSD awk limits on multi-line -v)
NEW_BLOCK_FILE=$(mktemp)
awk '/<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->/{flag=1} flag{print} /<!-- END BOOTSTRAP -->/{flag=0; exit}' \
    muster/templates/CLAUDE.md > "$NEW_BLOCK_FILE"

# Extract current block from project CLAUDE.md
CUR_BLOCK_FILE=$(mktemp)
awk '/<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->/{flag=1} flag{print} /<!-- END BOOTSTRAP -->/{flag=0; exit}' \
    CLAUDE.md > "$CUR_BLOCK_FILE"

if cmp -s "$NEW_BLOCK_FILE" "$CUR_BLOCK_FILE"; then
    skip "CLAUDE.md bootstrap block" "already up to date"
    rm -f "$NEW_BLOCK_FILE" "$CUR_BLOCK_FILE"
else
    if [ "$DRY_RUN" -eq 1 ]; then
        ok "Would replace CLAUDE.md bootstrap block (between markers)"
        rm -f "$NEW_BLOCK_FILE" "$CUR_BLOCK_FILE"
    else
        TMPFILE=$(mktemp)
        awk -v new_file="$NEW_BLOCK_FILE" '
            /<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->/ {
                while ((getline line < new_file) > 0) print line
                close(new_file)
                skip = 1
                next
            }
            /<!-- END BOOTSTRAP -->/ { skip = 0; next }
            !skip { print }
        ' CLAUDE.md > "$TMPFILE"
        mv "$TMPFILE" CLAUDE.md
        rm -f "$NEW_BLOCK_FILE" "$CUR_BLOCK_FILE"
        ok "Replaced CLAUDE.md bootstrap block"
    fi
fi

# ---------- step 2: merge pre-approvals into .claude/settings.json ----------
say ""
say "${BOLD}Step 2:${RESET} .claude/settings.json pre-approvals"

NEW_ENTRIES='[
  "Bash(bash muster/scripts/muster-housekeeping.sh)",
  "Bash(bash muster/scripts/muster-bind.sh:*)",
  "Bash(echo \"${MUSTER_ROLE:-UNSET}\")"
]'

if [ ! -f ".claude/settings.json" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
        ok "Would create .claude/settings.json with permissions block + statusLine"
    else
        # No settings.json at all — copy template (which now has both statusLine and permissions)
        cp muster/templates/.claude/settings.json .claude/settings.json
        ok "Created .claude/settings.json from template"
    fi
else
    # Check if all 3 entries already present
    MISSING=$(jq --argjson new "$NEW_ENTRIES" '
        ($new - (.permissions.allow // [])) | length
    ' .claude/settings.json)

    if [ "$MISSING" = "0" ]; then
        skip ".claude/settings.json permissions" "all 3 entries already present"
    else
        if [ "$DRY_RUN" -eq 1 ]; then
            ok "Would add $MISSING permission entry/entries to .claude/settings.json"
        else
            TMPFILE=$(mktemp)
            jq --argjson new "$NEW_ENTRIES" '
                .permissions = (.permissions // {}) |
                .permissions.allow = ((.permissions.allow // []) + $new | unique)
            ' .claude/settings.json > "$TMPFILE"
            mv "$TMPFILE" .claude/settings.json
            ok "Added $MISSING permission entry/entries to .claude/settings.json"
        fi
    fi
fi

# ---------- done ----------
say ""
if [ "$DRY_RUN" -eq 1 ]; then
    say "${BOLD}Dry run complete.${RESET} Re-run without --dry-run to apply."
else
    say "${GREEN}${BOLD}Done.${RESET} Bootstrap permission prompts will no longer fire on session start."
    say ""
    say "Commit when ready:"
    say "  git add CLAUDE.md .claude/settings.json"
    say "  git commit -m \"enable scripted bootstrap (suppress permission prompts)\""
fi
