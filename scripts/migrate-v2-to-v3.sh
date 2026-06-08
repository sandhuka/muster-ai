#!/usr/bin/env bash
set -euo pipefail

# Muster — Migrate v2 → v3
#
# Updates an existing Muster v2 project to v3 (role-binding, status-line,
# /rebind, MUSTER_ROLE env var). Run from the project root.
# (Autonomous sprint execution is v4 — see migrate-v3-to-v4.sh.)
#
# Usage:
#   bash muster/scripts/migrate-v2-to-v3.sh
#   bash muster/scripts/migrate-v2-to-v3.sh --resume
#   bash muster/scripts/migrate-v2-to-v3.sh --dry-run   # show what would change, don't touch files
#
# What this does:
#   - Adds .claude/agents/pm.md (PM bootloader — PM is now a peer agent)
#   - Adds .claude/statusline.sh + chmod +x
#   - Adds or merges .claude/settings.json (statusLine wired)
#   - Adds .claude/skills/rebind/ (the /rebind slash command)
#   - Adds knowledge-base/agent-context/pm.md if missing
#   - Updates .gitignore with v3 entries (.muster-bound-role.*, .muster-last-role)
#   - Replaces the bootstrap routing block in CLAUDE.md with the v3 version
#     (preserves everything outside the BOOTSTRAP markers)
#
# What this does NOT do:
#   - Bump the muster submodule pointer (do that yourself: cd muster && git checkout main && git pull)
#   - Touch knowledge-base content (current-sprint, decision-log, agent-requests, etc. — preserved as-is)
#   - Modify your existing .claude/settings.json if it already has a statusLine field
#
# Idempotent: re-running produces the same result without errors.

STATE_FILE=".muster-migration-state.json"

# ---------- argument parsing ----------
RESUME=0
DRY_RUN=0

while [ $# -gt 0 ]; do
    case "$1" in
        --resume)   RESUME=1; shift ;;
        --dry-run)  DRY_RUN=1; shift ;;
        -h|--help)
            cat <<'HELP_EOF'
Muster — Migrate v2 → v3

Updates an existing Muster v2 project to v3. Run from the project root.

Usage:
  bash muster/scripts/migrate-v2-to-v3.sh
  bash muster/scripts/migrate-v2-to-v3.sh --resume      Continue an interrupted run
  bash muster/scripts/migrate-v2-to-v3.sh --dry-run     Show what would change without modifying files
  bash muster/scripts/migrate-v2-to-v3.sh -h | --help   Show this help

Run from your project root (where CLAUDE.md and the muster/ submodule live).
HELP_EOF
            exit 0 ;;
        *)
            echo "Unknown arg: $1" >&2
            exit 1 ;;
    esac
done

# ---------- color helpers ----------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; GREEN=$'\033[32m'; CYAN=$'\033[36m'
    YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
    BOLD=''; DIM=''; GREEN=''; CYAN=''; YELLOW=''; RED=''; RESET=''
fi

say() { printf "%s\n" "$*"; }
err() { printf "%sError:%s %s\n" "$RED$BOLD" "$RESET" "$*" >&2; }
warn() { printf "%sWarning:%s %s\n" "$YELLOW$BOLD" "$RESET" "$*"; }

section_header() {
    printf "\n%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n" "$CYAN$BOLD" "$RESET"
    printf "%s  %s%s\n" "$CYAN$BOLD" "$1" "$RESET"
    printf "%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n\n" "$CYAN$BOLD" "$RESET"
}

substep_done() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf "  %s[dry-run]%s %s%s%s %s\n" "$DIM" "$RESET" "$BOLD" "$1" "$RESET" "$2"
    else
        printf "  %s✓%s %s%s%s %s\n" "$GREEN$BOLD" "$RESET" "$BOLD" "$1" "$RESET" "$2"
    fi
}

substep_skip() {
    printf "  %s·%s %s%s%s %s %s(%s)%s\n" "$DIM" "$RESET" "$BOLD" "$1" "$RESET" "$2" "$DIM" "$3" "$RESET"
}

iso_now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

state_has_step() {
    [ -f "$STATE_FILE" ] && grep -q "\"$1\"" "$STATE_FILE"
}

write_state() {
    [ "$DRY_RUN" -eq 1 ] && return 0
    local steps_json=""
    for s in "$@"; do
        if [ -n "$steps_json" ]; then steps_json="$steps_json, "; fi
        steps_json="$steps_json\"$s\""
    done
    cat > "$STATE_FILE" <<EOF
{
  "version": "1",
  "started_at": "${STARTED_AT:-$(iso_now)}",
  "last_step_at": "$(iso_now)",
  "steps_completed": [$steps_json]
}
EOF
}

# ---------- precondition checks ----------
section_header "Migration precondition checks"

if [ ! -f "CLAUDE.md" ]; then
    err "No CLAUDE.md found. Run this script from your project root (the directory with CLAUDE.md and the muster/ submodule)."
    exit 1
fi

if [ ! -d "muster" ]; then
    err "No muster/ submodule found. This script requires an existing v2 muster project."
    exit 1
fi

if [ ! -d "muster/templates" ]; then
    err "muster/templates/ missing. Update the muster submodule first: cd muster && git checkout main && git pull && cd .."
    exit 1
fi

if [ ! -f "muster/templates/.claude/agents/pm.md" ]; then
    err "muster/templates/.claude/agents/pm.md not found. The muster submodule is on a v2 commit."
    err "Update first: cd muster && git checkout main && git pull && cd .."
    err "(Or for the v3 dev branch: cd muster && git checkout feat/v3-role-binding && git pull && cd ..)"
    exit 1
fi

if [ ! -f "knowledge-base/agent-context/.populated" ]; then
    err "knowledge-base/agent-context/.populated missing. This is not a valid Muster project state."
    exit 1
fi

substep_done "0.1" "CLAUDE.md found"
substep_done "0.2" "muster/ submodule present"
substep_done "0.3" "muster/templates/ has v3 artifacts (pm.md, statusline.sh, etc.)"
substep_done "0.4" "knowledge-base/agent-context/.populated exists"

# Check if already v3 (idempotency safety)
if grep -q "Role Binding" CLAUDE.md && [ -f ".claude/agents/pm.md" ] && [ -f ".claude/statusline.sh" ]; then
    say ""
    warn "This project appears to already be on v3 (CLAUDE.md has 'Role Binding', pm.md and statusline.sh exist)."
    warn "Continuing in idempotent mode — re-application of v3 artifacts."
    say ""
fi

# ---------- resume validation ----------
if [ "$RESUME" -eq 1 ]; then
    if [ ! -f "$STATE_FILE" ]; then
        err "--resume given, but no $STATE_FILE found. Start a fresh migration without --resume."
        exit 1
    fi
    say "Resuming migration (started $(grep -o '"started_at": *"[^"]*"' "$STATE_FILE" | sed 's/.*"\([^"]*\)"/\1/'))."
    STARTED_AT=$(grep -o '"started_at": *"[^"]*"' "$STATE_FILE" | sed 's/.*"\([^"]*\)"/\1/')
else
    STARTED_AT="$(iso_now)"
fi

# ---------- migration steps ----------
section_header "Step 1: Add v3 artifacts"

# 1.1 PM bootloader
if [ "$RESUME" -eq 1 ] && state_has_step "pm_bootloader"; then
    substep_done "1.1" "Add .claude/agents/pm.md (already done in prior run)"
elif [ -f ".claude/agents/pm.md" ]; then
    substep_skip "1.1" "Add .claude/agents/pm.md" "already exists"
else
    if [ "$DRY_RUN" -eq 0 ]; then
        cp muster/templates/.claude/agents/pm.md .claude/agents/pm.md
    fi
    substep_done "1.1" "Add .claude/agents/pm.md (PM bootloader)"
fi

# 1.2 PM agent-context
if [ -f "knowledge-base/agent-context/pm.md" ]; then
    substep_skip "1.2" "Add knowledge-base/agent-context/pm.md" "already exists"
else
    if [ "$DRY_RUN" -eq 0 ]; then
        cp muster/templates/knowledge-base/agent-context/pm.md knowledge-base/agent-context/pm.md
    fi
    substep_done "1.2" "Add knowledge-base/agent-context/pm.md (template — fill in product context)"
fi

# 1.3 Status line script
# Priority: project-level > user-level > muster default
HAS_USER_STATUSLINE=0
if [ -f "$HOME/.claude/settings.json" ] && grep -q '"statusLine"' "$HOME/.claude/settings.json" 2>/dev/null; then
    HAS_USER_STATUSLINE=1
fi

if [ -f ".claude/statusline.sh" ]; then
    if cmp -s ".claude/statusline.sh" "muster/templates/.claude/statusline.sh" 2>/dev/null; then
        substep_skip "1.3" "Add .claude/statusline.sh" "already matches muster template (idempotent skip)"
    else
        substep_skip "1.3" "Add .claude/statusline.sh" "custom statusline preserved"
        if [ "$DRY_RUN" -eq 0 ]; then
            warn ""
            warn "Your existing .claude/statusline.sh has been preserved (it differs from muster's template)."
            warn "To get the muster bound-role indicator alongside your existing output, add this to your statusline.sh:"
            warn ""
            warn "    JSON_INPUT=\$(cat)"
            warn "    MUSTER=\$(echo \"\$JSON_INPUT\" | bash muster/scripts/muster-bound-role.sh)"
            warn "    echo \"\$YOUR_OUTPUT [muster: \$MUSTER]\""
            warn ""
            warn "See muster/scripts/muster-bound-role.sh for full integration options."
            warn ""
        fi
    fi
elif [ "$HAS_USER_STATUSLINE" -eq 1 ]; then
    substep_skip "1.3" "Add .claude/statusline.sh" "user-level statusline detected — not creating project-level"
    if [ "$DRY_RUN" -eq 0 ]; then
        warn ""
        warn "Detected user-level statusline at ~/.claude/settings.json."
        warn "NOT creating project-level .claude/statusline.sh or .claude/settings.json"
        warn "(would override your user-level statusline for this project)."
        warn ""
        warn "To get the muster bound-role indicator alongside your user-level output,"
        warn "edit your user-level statusline script (e.g. ~/.claude/statusline-command.sh)"
        warn "to add this snippet:"
        warn ""
        warn "    JSON_INPUT=\$(cat)"
        warn "    YOUR_OUTPUT=\"...your existing line...\""
        warn "    if [ -f \"muster/scripts/muster-bound-role.sh\" ]; then"
        warn "      MUSTER=\$(echo \"\$JSON_INPUT\" | bash muster/scripts/muster-bound-role.sh)"
        warn "      echo \"\$YOUR_OUTPUT [muster: \$MUSTER]\""
        warn "    else"
        warn "      echo \"\$YOUR_OUTPUT\""
        warn "    fi"
        warn ""
        warn "The if-check makes the statusline graceful in non-muster projects."
        warn ""
    fi
else
    if [ "$DRY_RUN" -eq 0 ]; then
        cp muster/templates/.claude/statusline.sh .claude/statusline.sh
        chmod +x .claude/statusline.sh
        if [ ! -x ".claude/statusline.sh" ]; then
            err "chmod +x failed on .claude/statusline.sh — filesystem may not support executable bit (NTFS/FAT?). Status line will not work until fixed."
            exit 1
        fi
    fi
    substep_done "1.3" "Add .claude/statusline.sh (executable)"
fi

# 1.4 Rebind skill
if [ -d ".claude/skills/rebind" ]; then
    substep_skip "1.4" "Add .claude/skills/rebind/" "already exists"
else
    if [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p .claude/skills
        cp -r muster/templates/.claude/skills/rebind .claude/skills/rebind
    fi
    substep_done "1.4" "Add .claude/skills/rebind/ (/rebind slash command)"
fi

write_state pm_bootloader pm_agent_context statusline rebind_skill

section_header "Step 2: Settings.json handling"

# 2.1 settings.json — skip if user-level statusline exists (already advised in step 1.3)
if [ "$HAS_USER_STATUSLINE" -eq 1 ]; then
    substep_skip "2.1" "Settings.json handling" "user-level statusline detected — not creating project-level"
elif [ ! -f ".claude/settings.json" ]; then
    if [ "$DRY_RUN" -eq 0 ]; then
        cp muster/templates/.claude/settings.json .claude/settings.json
    fi
    substep_done "2.1" "Create .claude/settings.json (no existing file → copied template)"
elif grep -q '"statusLine"' .claude/settings.json; then
    substep_skip "2.1" "Merge .claude/settings.json statusLine" "already has statusLine — preserving your config"
else
    # Has settings.json but no statusLine → merge
    if command -v jq &> /dev/null; then
        if [ "$DRY_RUN" -eq 0 ]; then
            jq -s '.[0] * .[1]' .claude/settings.json muster/templates/.claude/settings.json > .claude/settings.json.tmp
            mv .claude/settings.json.tmp .claude/settings.json
        fi
        substep_done "2.1" "Merge statusLine into existing .claude/settings.json (via jq)"
    else
        warn "jq not installed — cannot auto-merge settings.json."
        warn "Manually add the following to .claude/settings.json's top-level object:"
        cat muster/templates/.claude/settings.json | sed 's/^/    /'
        warn "Then re-run with --resume to continue."
        exit 1
    fi
fi

write_state pm_bootloader pm_agent_context statusline rebind_skill settings_json

section_header "Step 3: Update .gitignore"

V3_GITIGNORE_ENTRIES=(
    ".claude/.muster-bound-role.*"
    ".claude/.muster-last-role"
)

added_to_gitignore=0
if [ ! -f ".gitignore" ]; then
    if [ "$DRY_RUN" -eq 0 ]; then
        touch .gitignore
    fi
fi

for entry in "${V3_GITIGNORE_ENTRIES[@]}"; do
    if grep -qxF "$entry" .gitignore 2>/dev/null; then
        :  # already present
    else
        if [ "$DRY_RUN" -eq 0 ]; then
            printf "%s\n" "$entry" >> .gitignore
        fi
        added_to_gitignore=1
    fi
done

if [ "$added_to_gitignore" -eq 1 ]; then
    substep_done "3.1" "Add v3 entries to .gitignore (.muster-bound-role.*, .muster-last-role)"
else
    substep_skip "3.1" "Add v3 entries to .gitignore" "already up to date"
fi

write_state pm_bootloader pm_agent_context statusline rebind_skill settings_json gitignore

section_header "Step 4: Update CLAUDE.md routing block"

# 4.1 Replace bootstrap block
if grep -q "<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->" CLAUDE.md && grep -q "<!-- END BOOTSTRAP -->" CLAUDE.md; then
    if [ "$DRY_RUN" -eq 0 ]; then
        # Extract new block from template
        awk '/<!-- MUSTER BOOTSTRAP/,/<!-- END BOOTSTRAP/' muster/templates/CLAUDE.md > /tmp/muster-v3-bootstrap.md.$$
        # Replace between markers in user's CLAUDE.md
        awk -v new_block_file="/tmp/muster-v3-bootstrap.md.$$" '
            /<!-- MUSTER BOOTSTRAP/ {
                while ((getline line < new_block_file) > 0) print line
                close(new_block_file)
                in_block = 1
                next
            }
            /<!-- END BOOTSTRAP/ {
                in_block = 0
                next
            }
            !in_block { print }
        ' CLAUDE.md > CLAUDE.md.tmp
        mv CLAUDE.md.tmp CLAUDE.md
        rm -f /tmp/muster-v3-bootstrap.md.$$
    fi
    substep_done "4.1" "Replace CLAUDE.md bootstrap routing block with v3 version (content outside markers preserved)"
else
    err "CLAUDE.md missing BOOTSTRAP markers (<!-- MUSTER BOOTSTRAP — DO NOT REMOVE --> ... <!-- END BOOTSTRAP -->)."
    err "Cannot safely auto-update routing block. Manually replace your CLAUDE.md routing section with the v3 version from muster/templates/CLAUDE.md."
    exit 1
fi

write_state pm_bootloader pm_agent_context statusline rebind_skill settings_json gitignore claude_md_routing

# ---------- final verification ----------
# Skip in dry-run mode (nothing was changed; verification would always fail)
if [ "$DRY_RUN" -eq 0 ]; then
    section_header "Final verification"

    failures=0

    verify() {
        if eval "$2" 2>/dev/null; then
            substep_done "" "$1"
        else
            printf "  %s✗%s %s%s%s\n" "$RED$BOLD" "$RESET" "$BOLD" "$1" "$RESET"
            failures=$((failures + 1))
        fi
    }

    verify ".claude/agents/pm.md present"               "[ -f .claude/agents/pm.md ]"
    verify ".claude/skills/rebind/SKILL.md present"     "[ -f .claude/skills/rebind/SKILL.md ]"
    verify "knowledge-base/agent-context/pm.md present" "[ -f knowledge-base/agent-context/pm.md ]"
    verify ".gitignore has .muster-bound-role.*"        "grep -qxF '.claude/.muster-bound-role.*' .gitignore"
    verify ".gitignore has .muster-last-role"           "grep -qxF '.claude/.muster-last-role' .gitignore"
    verify "CLAUDE.md mentions Role Binding"            "grep -q 'Role Binding' CLAUDE.md"
    verify "CLAUDE.md no longer says 'PM Mode'"         "! grep -q 'PM Mode' CLAUDE.md"

    # Statusline + settings.json checks: only required if no user-level statusline
    if [ "$HAS_USER_STATUSLINE" -eq 0 ]; then
        verify ".claude/statusline.sh present + executable" "[ -x .claude/statusline.sh ]"
        verify ".claude/settings.json has statusLine"       "[ -f .claude/settings.json ] && grep -q statusLine .claude/settings.json"
    else
        substep_done "" ".claude/statusline.sh skipped (user-level statusline detected)"
        substep_done "" ".claude/settings.json skipped (user-level statusline detected)"
    fi

    if [ "$failures" -gt 0 ]; then
        err ""
        err "$failures verification failure(s). Migration is incomplete."
        exit 1
    fi
fi

# ---------- completion ----------
say ""
printf "%s╔════════════════════════════════════════════════════════════╗%s\n" "$GREEN$BOLD" "$RESET"
printf "%s║                                                            ║%s\n" "$GREEN$BOLD" "$RESET"
if [ "$DRY_RUN" -eq 1 ]; then
    printf "%s║         DRY RUN COMPLETE — no files modified              ║%s\n" "$GREEN$BOLD" "$RESET"
else
    printf "%s║              MIGRATION TO v3 COMPLETE                      ║%s\n" "$GREEN$BOLD" "$RESET"
fi
printf "%s║                                                            ║%s\n" "$GREEN$BOLD" "$RESET"
printf "%s╚════════════════════════════════════════════════════════════╝%s\n\n" "$GREEN$BOLD" "$RESET"

if [ "$DRY_RUN" -eq 0 ]; then
    cat <<'POST_MIGRATE_EOF'
Next steps:
  1. Review what changed:  git status / git diff
  2. (Recommended) Have PM populate knowledge-base/agent-context/pm.md
     with project-specific context (the template is just a placeholder).
     Open Claude → pick PM via picker → ask: "populate your agent-context"
  3. Bump muster submodule pointer if not already done:
       cd muster && git checkout main && git pull && cd ..
       git add muster && git commit -m "bump muster to v3"
  4. Commit the migration changes:
       git add .claude knowledge-base/agent-context/pm.md .gitignore CLAUDE.md
       git commit -m "migrate muster v2 → v3 (role-picker, status line, /rebind)"
  5. Open Claude in this project. The picker will fire (or skip if
     onboarding is somehow active). Pick a role; status line should
     show [muster: <role>] at the bottom.
  6. Optional: clean up state file:  rm .muster-migration-state.json

See muster/MIGRATING-V2-TO-V3.md for the full migration guide and
v3 feature overview.
POST_MIGRATE_EOF
fi

# Clean up state file on successful completion (not on dry run)
if [ "$DRY_RUN" -eq 0 ] && [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
fi
