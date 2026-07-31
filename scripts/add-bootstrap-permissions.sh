#!/usr/bin/env bash
# Muster — Enable scripted bootstrap (replaces inline bash commands with script calls)
#
# For existing muster projects: updates the CLAUDE.md bootstrap block to the current
# template (one `muster/scripts/muster-boot.sh` call — the single routing authority),
# and adds the matching pre-approval entries to .claude/settings.json so session
# start fires without permission prompts.
#
# Settings.json handling (three cases):
#   1. Project-level .claude/settings.json exists      → merge permissions in place
#   2. No project-level, user-level has content        → print manual-merge
#                                                        instructions for user-level
#                                                        (creating project-level
#                                                        would silently override
#                                                        user-level config)
#   3. Neither exists                                  → create project-level from
#                                                        template
#
# Idempotent. Re-running is a no-op if already applied.
#
# Usage:
#   bash muster/scripts/add-bootstrap-permissions.sh           # apply
#   bash muster/scripts/add-bootstrap-permissions.sh --dry-run # report what would change
#
# Prerequisites:
#   - Run from project root (where .claude/, knowledge-base/, muster/ live)
#   - muster submodule updated (must contain muster-boot.sh + muster-bind.sh)
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

if [ ! -f "muster/scripts/muster-boot.sh" ] || [ ! -f "muster/scripts/muster-bind.sh" ]; then
    err "muster/scripts/muster-boot.sh or muster-bind.sh missing."
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
  "Bash(bash muster/scripts/muster-boot.sh)",
  "Bash(bash muster/scripts/muster-boot.sh:*)",
  "Bash(bash muster/scripts/muster-bind.sh:*)",
  "Bash(bash muster/scripts/muster-find-skill.sh:*)",
  "Bash(bash muster/scripts/muster-check-context.sh:*)",
  "Bash(bash muster/scripts/muster-list-open-items.sh:*)",
  "Bash(bash muster/scripts/muster-advance-queue.sh:*)",
  "Bash(bash muster/scripts/muster-lint-context.sh:*)",
  "Bash(bash muster/scripts/muster-lint-durability.sh)"
]'

USER_SETTINGS="$HOME/.claude/settings.json"

# Detect what exists
PROJECT_EXISTS=0
[ -f ".claude/settings.json" ] && PROJECT_EXISTS=1

USER_KEYS=0
if [ -f "$USER_SETTINGS" ]; then
    USER_KEYS=$(jq 'length' "$USER_SETTINGS" 2>/dev/null || echo 0)
fi

if [ "$PROJECT_EXISTS" -eq 1 ]; then
    # Case 1: project-level exists — merge in place (preserves any existing fields)
    MISSING=$(jq --argjson new "$NEW_ENTRIES" '
        ($new - (.permissions.allow // [])) | length
    ' .claude/settings.json)

    if [ "$MISSING" = "0" ]; then
        skip ".claude/settings.json permissions" "all 9 entries already present"
    else
        if [ "$DRY_RUN" -eq 1 ]; then
            ok "Would add $MISSING permission entry/entries to .claude/settings.json (project-level)"
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
elif [ "$USER_KEYS" -gt 0 ]; then
    # Case 2: no project-level, user-level has content — instruct manual merge
    # (creating project-level from template would silently override user-level
    # statusline, model, theme, plugins, etc., since project-level wins)
    USER_MISSING=$(jq --argjson new "$NEW_ENTRIES" '
        ($new - (.permissions.allow // [])) | length
    ' "$USER_SETTINGS")

    if [ "$USER_MISSING" = "0" ]; then
        skip "project-level skipped" "user-level $USER_SETTINGS already has all 9 entries"
    else
        STEP2_DEFERRED=1
        say ""
        warn "Project-level .claude/settings.json does not exist."
        warn "User-level $USER_SETTINGS has $USER_KEYS top-level keys — creating a"
        warn "project-level file from the template would override your user-level"
        warn "config (statusline, model, theme, plugins, etc.) for this project."
        say ""
        say "${BOLD}Manual step:${RESET} add the following $USER_MISSING entry/entries to your"
        say "user-level settings file ($USER_SETTINGS) inside the permissions.allow"
        say "array (create the permissions section if it doesn't exist):"
        say ""
        say '  "Bash(bash muster/scripts/muster-boot.sh)",'
        say '  "Bash(bash muster/scripts/muster-boot.sh:*)",'
        say '  "Bash(bash muster/scripts/muster-bind.sh:*)",'
        say '  "Bash(bash muster/scripts/muster-find-skill.sh:*)",'
        say '  "Bash(bash muster/scripts/muster-check-context.sh:*)",'
        say '  "Bash(bash muster/scripts/muster-list-open-items.sh:*)",'
        say '  "Bash(bash muster/scripts/muster-advance-queue.sh:*)",'
        say '  "Bash(bash muster/scripts/muster-lint-context.sh:*)",'
        say '  "Bash(bash muster/scripts/muster-lint-durability.sh)"'
        say ""
        say "Paths are project-relative — these only match when CWD is inside a"
        say "muster project. Adding at user level means every muster project you"
        say "adopt gets these pre-approvals automatically; no per-project migration."
        say ""
        if [ "$DRY_RUN" -eq 1 ]; then
            ok "Would print user-level merge instructions (above)"
        else
            warn "Step 2 deferred — apply the manual step above"
        fi
    fi
else
    # Case 3: neither exists — safe to create project-level from template
    if [ "$DRY_RUN" -eq 1 ]; then
        ok "Would create .claude/settings.json with permissions block + statusLine"
    else
        cp muster/templates/.claude/settings.json .claude/settings.json
        ok "Created .claude/settings.json from template"
    fi
fi

# ---------- step 3: gitignore the boot telemetry log ----------
say ""
say "${BOLD}Step 3:${RESET} .gitignore boot-log entry"
BOOT_LOG_ENTRY="knowledge-base/.muster-boot-log"
if grep -qxF "$BOOT_LOG_ENTRY" .gitignore 2>/dev/null; then
    skip ".gitignore" "already has $BOOT_LOG_ENTRY"
elif [ "$DRY_RUN" -eq 1 ]; then
    ok "Would append $BOOT_LOG_ENTRY to .gitignore"
else
    touch .gitignore
    printf '%s\n' "$BOOT_LOG_ENTRY" >> .gitignore
    ok "Appended $BOOT_LOG_ENTRY to .gitignore"
fi

# ---------- done ----------
say ""
if [ "$DRY_RUN" -eq 1 ]; then
    say "${BOLD}Dry run complete.${RESET} Re-run without --dry-run to apply."
elif [ "${STEP2_DEFERRED:-0}" -eq 1 ]; then
    say "${YELLOW}${BOLD}Partial:${RESET} CLAUDE.md updated, but settings.json step needs your manual edit (above)."
    say "Permission prompts will continue to fire until you add the 9 entries to your user-level settings."
    say ""
    say "Commit the CLAUDE.md change when ready:"
    say "  git add CLAUDE.md"
    say "  git commit -m \"enable scripted bootstrap (CLAUDE.md side)\""
    say ""
    say "After adding the entries to $USER_SETTINGS, re-run this script to verify."
else
    say "${GREEN}${BOLD}Done.${RESET} Bootstrap permission prompts will no longer fire on session start."
    say ""
    say "Commit when ready:"
    say "  git add CLAUDE.md .claude/settings.json .gitignore"
    say "  git commit -m \"enable scripted bootstrap (suppress permission prompts)\""
fi
