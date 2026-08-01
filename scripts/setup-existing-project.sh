#!/usr/bin/env bash
set -euo pipefail

# Muster — Existing Project Setup Script
#
# Adds Muster to an existing project. Runs in the current directory.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/thinkArhant/muster-ai/main/scripts/setup-existing-project.sh | bash
#   ./setup-existing-project.sh
#   ./setup-existing-project.sh --resume        # continue an interrupted run
#   ./setup-existing-project.sh --muster-url <url>

DEFAULT_MUSTER_URL="https://github.com/thinkArhant/muster-ai.git"
STATE_FILE=".muster-setup-state.json"
ARCHIVE_DIR=".muster-archive"

# ---------- argument parsing ----------
RESUME=0
MUSTER_URL="$DEFAULT_MUSTER_URL"
# MUSTER_BRANCH: which branch to pin the muster submodule to.
# - empty (default) → use the remote's default branch (main)
# - set via --muster-branch <name> or MUSTER_BRANCH=<name> env var
MUSTER_BRANCH="${MUSTER_BRANCH:-}"

while [ $# -gt 0 ]; do
    case "$1" in
        --resume)           RESUME=1; shift ;;
        --muster-url)       MUSTER_URL="$2"; shift 2 ;;
        --muster-branch)    MUSTER_BRANCH="$2"; shift 2 ;;
        -h|--help)
            cat <<'HELP_EOF'
Muster — Existing Project Setup Script

Adopts Muster into an existing codebase. Operates in the current directory.

Usage:
  curl -fsSL https://raw.githubusercontent.com/thinkArhant/muster-ai/main/scripts/setup-existing-project.sh | bash
  ./setup-existing-project.sh
  ./setup-existing-project.sh --resume               Continue an interrupted run
  ./setup-existing-project.sh --muster-url <url>     Override the Muster repo URL

Flags:
  --resume          Continue from .muster-setup-state.json
  --muster-url      Override the Muster repo URL
  --muster-branch   Pin the Muster submodule to a specific branch (default: main)
  -h, --help        Show this help and exit
HELP_EOF
            exit 0 ;;
        *)                  echo "Unknown arg: $1"; exit 1 ;;
    esac
done

# ---------- color helpers ----------
# Enable ANSI colors only when stdout is a TTY and NO_COLOR is not set.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    GREEN=$'\033[32m'
    CYAN=$'\033[36m'
    YELLOW=$'\033[33m'
    RED=$'\033[31m'
    RESET=$'\033[0m'
else
    BOLD=''; DIM=''; GREEN=''; CYAN=''; YELLOW=''; RED=''; RESET=''
fi

# ---------- output helpers ----------
say() { printf "%s\n" "$*"; }
err() { printf "%sError:%s %s\n" "$RED$BOLD" "$RESET" "$*" >&2; }

section_header() {
    # Usage: section_header "Step 1: Set up Muster"
    local title="$1"
    printf "\n%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n" "$CYAN$BOLD" "$RESET"
    printf "%s  %s%s\n" "$CYAN$BOLD" "$title" "$RESET"
    printf "%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n\n" "$CYAN$BOLD" "$RESET"
}

substep_start() {
    # Usage: substep_start "1.1" "Description"
    printf "  %s→%s %s%s%s %s\n" "$DIM" "$RESET" "$BOLD" "$1" "$RESET" "$2"
}

substep_done() {
    # Usage: substep_done "1.1" "Description"
    printf "  %s✓%s %s%s%s %s\n" "$GREEN$BOLD" "$RESET" "$BOLD" "$1" "$RESET" "$2"
}

substep_skip() {
    # Usage: substep_skip "1.1" "Description" "(nothing to do)"
    printf "  %s·%s %s%s%s %s %s(%s)%s\n" "$DIM" "$RESET" "$BOLD" "$1" "$RESET" "$2" "$DIM" "$3" "$RESET"
}

completion_banner() {
    printf "\n"
    printf "%s╔════════════════════════════════════════════════════════════╗%s\n" "$GREEN$BOLD" "$RESET"
    printf "%s║                                                            ║%s\n" "$GREEN$BOLD" "$RESET"
    printf "%s║              MUSTER SETUP COMPLETE                         ║%s\n" "$GREEN$BOLD" "$RESET"
    printf "%s║                                                            ║%s\n" "$GREEN$BOLD" "$RESET"
    printf "%s╚════════════════════════════════════════════════════════════╝%s\n\n" "$GREEN$BOLD" "$RESET"
}

prompt_input() {
    # Read one line of input from /dev/tty so that `curl | bash` still works.
    local prompt="$1" answer
    printf "%s" "$prompt" > /dev/tty
    read -r answer < /dev/tty
    printf "%s" "$answer"
}

# Interactive single-select menu. Reads arrow keys from /dev/tty so it
# works under `curl | bash`. Falls back to a numbered prompt when stdout
# is not a TTY or /dev/tty is unreadable.
# Usage:  select_one "Header text:" "Option 1" "Option 2" ...
# Sets:   SELECTED_INDEX (0-based)
SELECTED_INDEX=0
select_one() {
    local header="$1"; shift
    local -a options=("$@")
    local n=${#options[@]}
    local selected=0

    # Fallback: no tty (piped or redirected) → numbered prompt
    if [ ! -r /dev/tty ] || [ ! -t 1 ]; then
        printf "%s\n" "$header"
        local i
        for (( i=0; i<n; i++ )); do
            printf "  (%d) %s\n" $((i+1)) "${options[$i]}"
        done
        local raw
        while :; do
            printf "> "
            IFS= read -r raw || { SELECTED_INDEX=-1; return 1; }
            case "$raw" in
                ''|*[!0-9]*) continue ;;
            esac
            if [ "$raw" -ge 1 ] && [ "$raw" -le "$n" ]; then
                SELECTED_INDEX=$((raw-1))
                return 0
            fi
        done
    fi

    local saved_stty
    saved_stty="$(stty -g < /dev/tty)"
    trap "stty '$saved_stty' < /dev/tty; printf '\033[?25h' > /dev/tty" EXIT
    trap "stty '$saved_stty' < /dev/tty; printf '\033[?25h' > /dev/tty; exit 130" INT

    stty -icanon -echo min 1 time 0 < /dev/tty
    printf '\033[?25l' > /dev/tty

    printf "%s\n\n" "$header" > /dev/tty

    local redraw_lines=$((n + 2))  # n options + blank + footer
    local first=1 i key rest

    while :; do
        if [ $first -eq 0 ]; then
            printf '\033[%dA\033[J' "$redraw_lines" > /dev/tty
        fi
        first=0
        for (( i=0; i<n; i++ )); do
            if [ $i -eq $selected ]; then
                printf "  %s❯ %s%s\n" "$CYAN$BOLD" "${options[$i]}" "$RESET" > /dev/tty
            else
                printf "    %s\n" "${options[$i]}" > /dev/tty
            fi
        done
        printf "\n  %s↑/↓ to move, Enter to select, 1-9 to pick directly%s\n" "$DIM" "$RESET" > /dev/tty

        IFS= read -rsn1 key < /dev/tty
        case "$key" in
            $'\033')
                IFS= read -rsn2 -t 1 rest < /dev/tty || true
                case "$rest" in
                    '[A') [ $selected -gt 0 ] && selected=$((selected-1)) ;;
                    '[B') [ $selected -lt $((n-1)) ] && selected=$((selected+1)) ;;
                esac
                ;;
            '')
                break
                ;;
            k|K) [ $selected -gt 0 ] && selected=$((selected-1)) ;;
            j|J) [ $selected -lt $((n-1)) ] && selected=$((selected+1)) ;;
            [1-9])
                local num=$((key - 1))
                if [ $num -ge 0 ] && [ $num -lt $n ]; then
                    selected=$num
                    break
                fi
                ;;
        esac
    done

    stty "$saved_stty" < /dev/tty
    printf '\033[?25h' > /dev/tty
    trap - EXIT INT

    # Clear the entire menu (header + blank + options + blank + footer)
    # and replace it with a single confirmation line.
    printf '\033[%dA\033[J' "$((redraw_lines + 2))" > /dev/tty
    printf "%s\n" "$header" > /dev/tty
    printf "  %s✓%s %s\n\n" "$GREEN$BOLD" "$RESET" "${options[$selected]}" > /dev/tty

    SELECTED_INDEX=$selected
    return 0
}

iso_now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

state_has_step() {
    [ -f "$STATE_FILE" ] && grep -q "\"$1\"" "$STATE_FILE"
}

write_state() {
    # Args: repo_shape, step1 step2 step3...
    local shape="$1"; shift
    local steps="$*"
    local steps_json=""
    for s in $steps; do
        if [ -n "$steps_json" ]; then steps_json="$steps_json, "; fi
        steps_json="$steps_json\"$s\""
    done
    cat > "$STATE_FILE" <<EOF
{
  "version": "1",
  "repo_shape": "$shape",
  "muster_url": "$MUSTER_URL",
  "muster_branch": "$MUSTER_BRANCH",
  "started_at": "$STARTED_AT",
  "last_step_at": "$(iso_now)",
  "steps_completed": [$steps_json]
}
EOF
}

read_repo_shape() {
    # Extract repo_shape from existing state file.
    sed -n 's/.*"repo_shape": *"\([^"]*\)".*/\1/p' "$STATE_FILE" | head -n1
}

read_started_at() {
    sed -n 's/.*"started_at": *"\([^"]*\)".*/\1/p' "$STATE_FILE" | head -n1
}

read_muster_url() {
    sed -n 's/.*"muster_url": *"\([^"]*\)".*/\1/p' "$STATE_FILE" | head -n1
}

read_muster_branch() {
    sed -n 's/.*"muster_branch": *"\([^"]*\)".*/\1/p' "$STATE_FILE" | head -n1
}

# ---------- resume validation ----------
if [ "$RESUME" -eq 1 ]; then
    if [ ! -f "$STATE_FILE" ]; then
        err "--resume given, but no $STATE_FILE found. Remove --resume to start fresh."
        exit 1
    fi
    REPO_SHAPE="$(read_repo_shape)"
    STARTED_AT="$(read_started_at)"
    # Restore url/branch from state file unless explicitly overridden via flag
    if [ "$MUSTER_URL" = "$DEFAULT_MUSTER_URL" ]; then
        SAVED_URL="$(read_muster_url)"
        [ -n "$SAVED_URL" ] && MUSTER_URL="$SAVED_URL"
    fi
    if [ -z "$MUSTER_BRANCH" ]; then
        MUSTER_BRANCH="$(read_muster_branch)"
    fi
    say "Resuming prior setup (started $STARTED_AT, repo_shape=$REPO_SHAPE)."
elif [ -f "$STATE_FILE" ]; then
    err "Prior setup state detected ($STATE_FILE)."
    err "Re-run with --resume to continue, or delete $STATE_FILE to start over."
    exit 1
else
    STARTED_AT="$(iso_now)"
    REPO_SHAPE=""
fi

# ---------- first-run orientation + repo-shape prompt ----------
if [ "$RESUME" -eq 0 ]; then
    cat <<'PROMPT'

Muster setup — existing project

Estimated time: about 2 hours for a typical project (up to 2.5 hours
if your CLAUDE.md is large or your codebase has many unknowns). The
script runs in a couple of minutes; the rest is a short orientation,
a free-form brain-dump of what you know about your product, a code
audit, an adaptive questionnaire, and founder review.

This is a one-time setup. Future Muster framework updates pull in
via `git submodule update` without repeating onboarding, though
major framework additions may prompt small updates to your CLAUDE.md.

What this will do:
  - Add Muster as a git submodule
  - Scaffold knowledge-base templates and agent bootloaders
  - Archive your existing CLAUDE.md / .claude/agents (if present)
  - Hand off to Claude for guided reverse discovery

What this will NOT do:
  - Modify your source code
  - Overwrite docs without a diff + your approval
  - Cascade any context to agents until you've approved the source documents

About the repo-shape options:
  • Single git repo (most common)  — one repo for the whole project. Covers
                                     monorepos, frontend+backend colocated,
                                     and single-surface products (iOS app,
                                     web app, CLI, etc.)
  • Multi-repo parent              — separate repos for different platforms
                                     or surfaces sitting inside a parent
                                     folder

If you're not sure, pick "Single git repo" — it's the right answer
for most projects.

PROMPT

    select_one "Your repo shape (git organization):" \
        "Single git repo  (most common — pick this if unsure)" \
        "Multi-repo parent" \
        "Cancel — read the guide first"

    case "$SELECTED_INDEX" in
        0) REPO_SHAPE="single" ;;
        1) REPO_SHAPE="multi-repo-parent" ;;
        2) say "Cancelled. See muster/adopting-existing-project.md for the guide."; exit 0 ;;
        *) err "Invalid selection."; exit 1 ;;
    esac
fi

# ---------- git state detection (three-case logic) ----------
TOPLEVEL="$(git rev-parse --show-toplevel 2>/dev/null || true)"
CWD="$(pwd)"

if [ -z "$TOPLEVEL" ]; then
    # Case A: not inside any git repo → offer git init
    if [ "$RESUME" -eq 0 ]; then
        say ""
        say "This directory is not a git repo."
        say "Muster tracks decisions and spec changes in git. We need a repo for that."
        INIT_ANSWER="$(prompt_input "Initialize one now? [y/n] ")"
        case "$INIT_ANSWER" in
            y|Y|yes|YES) git init -q; say "Initialized empty Git repository in $CWD" ;;
            *) err "Muster requires git. Initialize manually with 'git init' and re-run."; exit 1 ;;
        esac
    else
        err "Cannot --resume: directory is not a git repo. Something went wrong — investigate."
        exit 1
    fi
elif [ "$TOPLEVEL" != "$CWD" ]; then
    # Case C: current dir is INSIDE a larger git repo → abort
    cat >&2 <<ABORT

Error: This directory appears to be inside a larger git repo at:
    $TOPLEVEL

Muster should not be initialized inside an unrelated parent repo. Doing so
would embed Muster as a submodule of the wrong repo and stage your
knowledge-base/ under that parent's tracking.

Options:
  1. Cancel, move this folder outside $TOPLEVEL, and re-run.
  2. If $TOPLEVEL is actually your project root, re-run the script from there.

ABORT
    exit 1
fi
# Case B: current dir IS a git repo root → proceed

# ---------- knowledge-base conflict check ----------
if [ -d "knowledge-base" ] && [ "$RESUME" -eq 0 ]; then
    if [ ! -f "$STATE_FILE" ]; then
        err "knowledge-base/ already exists but no $STATE_FILE found."
        err "This may indicate a failed prior run or manual experimentation."
        err "Resolve manually (move knowledge-base/ aside or delete it) before re-running."
        exit 1
    fi
fi

section_header "Step 1: Set up Muster"

# ---------- step 1.1: archive_existing ----------
if ! state_has_step "archive_existing"; then
    mkdir -p "$ARCHIVE_DIR"
    archived_anything=0

    if [ -f "CLAUDE.md" ]; then
        if [ -f "$ARCHIVE_DIR/CLAUDE.md.pre-muster" ]; then
            err "$ARCHIVE_DIR/CLAUDE.md.pre-muster already exists. Resolve manually."
            exit 1
        fi
        mv CLAUDE.md "$ARCHIVE_DIR/CLAUDE.md.pre-muster"
        archived_anything=1
    fi

    if [ -d ".claude/agents" ]; then
        if [ -d "$ARCHIVE_DIR/claude-agents.pre-muster" ]; then
            err "$ARCHIVE_DIR/claude-agents.pre-muster already exists. Resolve manually."
            exit 1
        fi
        mv .claude/agents "$ARCHIVE_DIR/claude-agents.pre-muster"
        archived_anything=1
    fi

    if [ "$archived_anything" -eq 1 ]; then
        substep_done "1.1" "Archive existing CLAUDE.md / .claude/agents  →  $ARCHIVE_DIR/"
    else
        substep_skip "1.1" "Archive existing CLAUDE.md / .claude/agents" "nothing to archive"
    fi

    write_state "$REPO_SHAPE" archive_existing
else
    substep_done "1.1" "Archive existing CLAUDE.md / .claude/agents"
fi

# ---------- step 1.2: submodule_add ----------
if ! state_has_step "submodule_add"; then
    if [ -d "muster" ]; then
        err "muster/ already exists. Resolve manually (git submodule deinit / rm -rf) before resuming."
        exit 1
    fi

    if [ -n "$MUSTER_BRANCH" ]; then
        substep_start "1.2" "Add Muster as git submodule on branch '$MUSTER_BRANCH' (cloning — this takes a few seconds)"
        git submodule add --quiet -b "$MUSTER_BRANCH" "$MUSTER_URL" muster
    else
        substep_start "1.2" "Add Muster as git submodule (cloning — this takes a few seconds)"
        git submodule add --quiet "$MUSTER_URL" muster
    fi
    substep_done "1.2" "Add Muster as git submodule"
    write_state "$REPO_SHAPE" archive_existing submodule_add
else
    substep_done "1.2" "Add Muster as git submodule"
fi

# ---------- step 1.3: scaffold_templates ----------
if ! state_has_step "scaffold_templates"; then
    mkdir -p .claude/agents
    cp muster/templates/.claude/agents/*.md .claude/agents/

    # Status-line script (v3 — bound-role indicator)
    # Priority: project-level > user-level > muster default
    HAS_USER_STATUSLINE=0
    if [ -f "$HOME/.claude/settings.json" ] && grep -q '"statusLine"' "$HOME/.claude/settings.json" 2>/dev/null; then
        HAS_USER_STATUSLINE=1
    fi

    if [ -f ".claude/statusline.sh" ]; then
        # Project-level already exists — preserve (highest priority)
        if cmp -s ".claude/statusline.sh" "muster/templates/.claude/statusline.sh"; then
            : # Already matches muster template — idempotent skip
        else
            echo ""
            echo "  ⚠  .claude/statusline.sh already exists with custom content — preserving."
            echo "    To get the muster bound-role indicator alongside your existing output,"
            echo "    add this to your statusline.sh (replace YOUR_OUTPUT with your existing logic):"
            echo ""
            echo "      JSON_INPUT=\$(cat)"
            echo "      MUSTER=\$(echo \"\$JSON_INPUT\" | bash muster/scripts/muster-bound-role.sh)"
            echo "      echo \"\$YOUR_OUTPUT [muster: \$MUSTER]\""
            echo ""
            echo "    See muster/scripts/muster-bound-role.sh for full integration options."
            echo ""
        fi
    elif [ "$HAS_USER_STATUSLINE" -eq 1 ]; then
        # User has user-level statusline — don't install project-level (would override)
        echo ""
        echo "  ⚠  Detected user-level statusline at ~/.claude/settings.json."
        echo "    NOT creating project-level .claude/statusline.sh or .claude/settings.json"
        echo "    (project-level config would override your user-level statusline)."
        echo ""
        echo "    To get the muster bound-role indicator alongside your user-level output,"
        echo "    edit your user-level statusline script (e.g. ~/.claude/statusline-command.sh)"
        echo "    to add this snippet:"
        echo ""
        echo "      # In your user-level statusline script:"
        echo "      JSON_INPUT=\$(cat)"
        echo "      YOUR_OUTPUT=\"...your existing line...\""
        echo "      if [ -f \"muster/scripts/muster-bound-role.sh\" ]; then"
        echo "        MUSTER=\$(echo \"\$JSON_INPUT\" | bash muster/scripts/muster-bound-role.sh)"
        echo "        echo \"\$YOUR_OUTPUT [muster: \$MUSTER]\""
        echo "      else"
        echo "        echo \"\$YOUR_OUTPUT\""
        echo "      fi"
        echo ""
        echo "    The if-check makes the statusline graceful in non-muster projects."
        echo "    See muster/scripts/muster-bound-role.sh for full integration options."
        echo ""
    else
        # No project-level, no user-level — install muster's project-level
        cp muster/templates/.claude/statusline.sh .claude/statusline.sh
        chmod +x .claude/statusline.sh
    fi

    # settings.json — the permission pre-approvals ALWAYS ship (without them every session-start
    # script fires a permission prompt); only the statusLine KEY defers to a user-level statusline.
    # awk strip, not jq (fresh machines may lack jq) — safe because we own the template shape
    # (the "statusLine" block anchor is pinned in test-parse-contracts.sh).
    if [ -f ".claude/settings.json" ]; then
        if grep -q '"statusLine"' .claude/settings.json || [ "$HAS_USER_STATUSLINE" -eq 1 ]; then
            : # statusLine handled (project- or user-level) — permissions merge is add-bootstrap-permissions.sh's job
        else
            echo "  ⚠  .claude/settings.json exists without statusLine — please add statusLine config manually from muster/templates/.claude/settings.json"
        fi
    elif [ "$HAS_USER_STATUSLINE" -eq 1 ]; then
        awk '/"statusLine": \{/{skip=1; next} skip && /^  \},$/{skip=0; next} !skip' \
            muster/templates/.claude/settings.json > .claude/settings.json
        echo "  ·  seeded .claude/settings.json with permissions only (statusLine deferred to your user-level)"
    else
        cp muster/templates/.claude/settings.json .claude/settings.json
    fi

    # Slash commands / skills (v3 — /rebind for mid-session role change)
    if [ -d "muster/templates/.claude/skills" ]; then
        mkdir -p .claude/skills
        cp -r muster/templates/.claude/skills/* .claude/skills/
    fi

    if [ ! -f "CLAUDE.md" ]; then
        cp muster/templates/CLAUDE.md CLAUDE.md
    fi

    cp -r muster/templates/knowledge-base .

    # Project knob file (v4.2 — sourced by the sprint driver; committed so worktrees inherit it)
    if [ -d "muster/templates/.muster" ] && [ ! -f ".muster/config" ]; then
        mkdir -p .muster
        cp muster/templates/.muster/config .muster/config
    fi

    # Remove template .DS_Store files if any
    find . -name ".DS_Store" -delete 2>/dev/null || true

    substep_done "1.3" "Scaffold knowledge-base + agent bootloaders + status line + skills"
    write_state "$REPO_SHAPE" archive_existing submodule_add scaffold_templates
else
    substep_done "1.3" "Scaffold knowledge-base + agent bootloaders + status line + skills"
fi

# ---------- step 1.4: initialize_populated_file ----------
if ! state_has_step "initialize_populated_file"; then
    ONBOARDED_AT="$(iso_now)"
    # PM is always "populated" — it's the populator, not a populate target.
    # All specialists start null; PM writes their entries during reverse discovery.
    cat > knowledge-base/agent-context/.populated <<EOF
{
  "version": "2",
  "onboarded_at": "$ONBOARDED_AT",
  "onboarding_complete_at": null,
  "agents": {
    "developer": null,
    "ui-ux": null,
    "content": null,
    "qa": null,
    "research": null,
    "marketing": null,
    "legal": null,
    "pm": "$ONBOARDED_AT"
  },
  "lock": null
}
EOF
    substep_done "1.4" "Initialize .populated state file (with onboarded_at)"
    write_state "$REPO_SHAPE" archive_existing submodule_add scaffold_templates initialize_populated_file
else
    substep_done "1.4" "Initialize .populated state file"
fi

# ---------- step 1.5: agent_skills_created ----------
if ! state_has_step "agent_skills_created"; then
    for agent in content developer legal marketing pm qa research ui-ux; do
        mkdir -p "knowledge-base/agent-skills/$agent"
        touch "knowledge-base/agent-skills/$agent/.gitkeep"
    done
    substep_done "1.5" "Create agent-skills/ directories (8 agents)"
    write_state "$REPO_SHAPE" archive_existing submodule_add scaffold_templates initialize_populated_file agent_skills_created
else
    substep_done "1.5" "Create agent-skills/ directories"
fi

# ---------- step 1.6: gitignore_updated ----------
if ! state_has_step "gitignore_updated"; then
    # Append only missing entries. Do not touch existing entries.
    GITIGNORE_ENTRIES=(
        ".DS_Store"
        "*.swp"
        "*.swo"
        "*~"
        ".muster-archive/"
        ".muster-setup-state.json"
        "knowledge-base/.muster-onboarding/"
        ".claude/.muster-bound-role.*"
        ".claude/.muster-last-role"
        ".muster-sprint-logs/"
        "knowledge-base/.muster-bind-log"
        "knowledge-base/.muster-boot-log"
    )

    touch .gitignore
    added_any=0
    for entry in "${GITIGNORE_ENTRIES[@]}"; do
        if ! grep -qxF "$entry" .gitignore 2>/dev/null; then
            printf "%s\n" "$entry" >> .gitignore
            added_any=1
        fi
    done
    if [ "$added_any" -eq 1 ]; then
        substep_done "1.6" "Update .gitignore (added missing Muster entries)"
    else
        substep_skip "1.6" "Update .gitignore" "already up to date"
    fi
    write_state "$REPO_SHAPE" archive_existing submodule_add scaffold_templates initialize_populated_file agent_skills_created gitignore_updated
else
    substep_done "1.6" "Update .gitignore"
fi

# ---------- cleanup: remove state file on success ----------
rm -f "$STATE_FILE"

# ---------- completion banner + Step 2 ----------
completion_banner

section_header "Step 2: Open Claude Code and kick off onboarding"

printf "  Run:\n"
printf "    %s%s%s\n\n" "$BOLD$CYAN" "claude" "$RESET"
printf "  Then send Claude this first message:\n"
printf "    %s%s%s\n\n" "$BOLD$CYAN" "Let's start the existing-project onboarding." "$RESET"
printf "  %sAny first message works%s — Claude detects state on the first\n" "$DIM" "$RESET"
printf "  %sinput and routes to the right onboarding flow.%s\n\n" "$DIM" "$RESET"

printf "  %sWhat to expect:%s ~2 hours, 6 stages. Claude opens with a brief\n" "$BOLD" "$RESET"
printf "  welcome that walks you through each one. Stage 1 (brain-dump,\n"
printf "  ~25 min) is the %shighest-leverage%s step — pick a time you can\n" "$YELLOW" "$RESET"
printf "  ramble about your product without distraction.\n\n"

printf "  Full guide: %smuster/adopting-existing-project.md%s\n\n" "$CYAN" "$RESET"
