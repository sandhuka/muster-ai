#!/usr/bin/env bash
set -euo pipefail

# Muster — New Project Setup Script
#
# Creates a new project with Muster scaffolded — git repo, submodule,
# agent bootloaders, knowledge-base templates, and project CLAUDE.md.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/sandhuka/muster-ai/main/scripts/setup-project.sh | bash -s <project-name>
#   ./setup-project.sh <project-name>
#   ./setup-project.sh --resume                  # continue an interrupted run (run from inside the partial project dir)
#   ./setup-project.sh <project-name> --muster-url <url>

DEFAULT_MUSTER_URL="https://github.com/sandhuka/muster-ai.git"
STATE_FILE=".muster-setup-state.json"

# ---------- argument parsing ----------
RESUME=0
PROJECT_NAME=""
MUSTER_URL="$DEFAULT_MUSTER_URL"
MUSTER_BRANCH="${MUSTER_BRANCH:-}"

while [ $# -gt 0 ]; do
    case "$1" in
        --resume)           RESUME=1; shift ;;
        --muster-url)       MUSTER_URL="$2"; shift 2 ;;
        --muster-branch)    MUSTER_BRANCH="$2"; shift 2 ;;
        -h|--help)
            cat <<'HELP_EOF'
Muster — New Project Setup Script

Creates a new project with Muster scaffolded — git repo, submodule,
agent bootloaders, knowledge-base templates, and project CLAUDE.md.

Usage:
  curl -fsSL https://raw.githubusercontent.com/sandhuka/muster-ai/main/scripts/setup-project.sh | bash -s <project-name>
  ./setup-project.sh <project-name>
  ./setup-project.sh --resume                       Continue an interrupted run
                                                    (run from inside the partial project dir)
  ./setup-project.sh <project-name> --muster-url <url>

Flags:
  --resume          Continue from .muster-setup-state.json
  --muster-url      Override the Muster repo URL
  --muster-branch   Pin the Muster submodule to a specific branch (default: main)
  -h, --help        Show this help and exit
HELP_EOF
            exit 0 ;;
        -*)                 echo "Unknown arg: $1"; exit 1 ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            else
                MUSTER_URL="$1"
            fi
            shift ;;
    esac
done

# ---------- color helpers ----------
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
    local title="$1"
    printf "\n%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n" "$CYAN$BOLD" "$RESET"
    printf "%s  %s%s\n" "$CYAN$BOLD" "$title" "$RESET"
    printf "%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n\n" "$CYAN$BOLD" "$RESET"
}

substep_start() {
    printf "  %s→%s %s%s%s %s\n" "$DIM" "$RESET" "$BOLD" "$1" "$RESET" "$2"
}

substep_done() {
    printf "  %s✓%s %s%s%s %s\n" "$GREEN$BOLD" "$RESET" "$BOLD" "$1" "$RESET" "$2"
}

substep_skip() {
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

iso_now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

state_has_step() {
    [ -f "$STATE_FILE" ] && grep -q "\"$1\"" "$STATE_FILE"
}

write_state() {
    local steps="$*"
    local steps_json=""
    for s in $steps; do
        if [ -n "$steps_json" ]; then steps_json="$steps_json, "; fi
        steps_json="$steps_json\"$s\""
    done
    cat > "$STATE_FILE" <<EOF
{
  "version": "1",
  "project_name": "$PROJECT_NAME",
  "muster_url": "$MUSTER_URL",
  "muster_branch": "$MUSTER_BRANCH",
  "started_at": "$STARTED_AT",
  "last_step_at": "$(iso_now)",
  "steps_completed": [$steps_json]
}
EOF
}

read_project_name() {
    sed -n 's/.*"project_name": *"\([^"]*\)".*/\1/p' "$STATE_FILE" | head -n1
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
        err "--resume given, but no $STATE_FILE found in current directory."
        err "Run --resume from inside the partially-created project directory."
        exit 1
    fi
    PROJECT_NAME="$(read_project_name)"
    STARTED_AT="$(read_started_at)"
    # Restore url/branch from state file unless explicitly overridden via flag
    if [ "$MUSTER_URL" = "$DEFAULT_MUSTER_URL" ]; then
        SAVED_URL="$(read_muster_url)"
        [ -n "$SAVED_URL" ] && MUSTER_URL="$SAVED_URL"
    fi
    if [ -z "$MUSTER_BRANCH" ]; then
        MUSTER_BRANCH="$(read_muster_branch)"
    fi
    say "Resuming setup for project '$PROJECT_NAME' (started $STARTED_AT)."
elif [ -z "$PROJECT_NAME" ]; then
    err "Usage: setup-project.sh <project-name> [--muster-url <url>]"
    err "       setup-project.sh --resume     (run from inside the partial project dir)"
    exit 1
fi

# ---------- first-run intro ----------
if [ "$RESUME" -eq 0 ]; then
    cat <<'PROMPT'

Muster setup — new project

Estimated time: the script runs in a couple of minutes; the rest is
multi-session Discovery (idea share → research → evaluation → spec
drafting → Sprint 1 plan). Total founder time across sessions: ~1-2
hours of focused attention spread over a day or two.

What this will do:
  - Create a new project directory with a git repo
  - Add Muster as a git submodule
  - Scaffold knowledge-base templates and agent bootloaders
  - Hand off to Claude for guided Discovery

What this will NOT do:
  - Touch anything outside the new project directory
  - Make any external network calls beyond the git submodule clone

PROMPT
fi

# ---------- step 1.1: create_project_dir ----------
PROJECT_DIR="$(pwd)/$PROJECT_NAME"

if [ "$RESUME" -eq 0 ]; then
    if [ -d "$PROJECT_DIR" ]; then
        err "Directory '$PROJECT_DIR' already exists."
        err "Choose a different project name, or remove the existing directory."
        exit 1
    fi
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    git init -q
    STARTED_AT="$(iso_now)"
    section_header "Step 1: Set up Muster"
    substep_done "1.1" "Create project directory + git init  →  $PROJECT_DIR"
    write_state create_project_dir
else
    # Resume case: we're already in the project dir
    section_header "Step 1: Set up Muster (resuming)"
    substep_done "1.1" "Create project directory + git init"
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
    write_state create_project_dir submodule_add
else
    substep_done "1.2" "Add Muster as git submodule"
fi

# ---------- step 1.3: scaffold_templates ----------
if ! state_has_step "scaffold_templates"; then
    mkdir -p .claude/agents
    cp muster/templates/.claude/agents/*.md .claude/agents/

    # Status-line script (Phase 6 — bound-role indicator)
    # Priority: project-level > user-level > muster default
    HAS_USER_STATUSLINE=0
    if [ -f "$HOME/.claude/settings.json" ] && grep -q '"statusLine"' "$HOME/.claude/settings.json" 2>/dev/null; then
        HAS_USER_STATUSLINE=1
    fi

    if [ -f ".claude/statusline.sh" ]; then
        if cmp -s ".claude/statusline.sh" "muster/templates/.claude/statusline.sh"; then
            :
        else
            echo ""
            echo "  ⚠  .claude/statusline.sh already exists with custom content — preserving."
            echo "    To get the muster bound-role indicator alongside your existing output:"
            echo "      JSON_INPUT=\$(cat)"
            echo "      MUSTER=\$(echo \"\$JSON_INPUT\" | bash muster/scripts/muster-bound-role.sh)"
            echo "      echo \"\$YOUR_OUTPUT [muster: \$MUSTER]\""
            echo ""
        fi
    elif [ "$HAS_USER_STATUSLINE" -eq 1 ]; then
        echo ""
        echo "  ⚠  Detected user-level statusline at ~/.claude/settings.json."
        echo "    NOT creating project-level .claude/statusline.sh (would override your user-level)."
        echo "    To get muster bound-role indicator, add to your user-level statusline:"
        echo "      JSON_INPUT=\$(cat)"
        echo "      if [ -f \"muster/scripts/muster-bound-role.sh\" ]; then"
        echo "        MUSTER=\$(echo \"\$JSON_INPUT\" | bash muster/scripts/muster-bound-role.sh)"
        echo "        echo \"\$YOUR_OUTPUT [muster: \$MUSTER]\""
        echo "      else"
        echo "        echo \"\$YOUR_OUTPUT\""
        echo "      fi"
        echo ""
    else
        cp muster/templates/.claude/statusline.sh .claude/statusline.sh
        chmod +x .claude/statusline.sh
    fi

    # settings.json — only install project-level if no user-level statusline AND no project-level
    if [ "$HAS_USER_STATUSLINE" -eq 1 ]; then
        :
    elif [ -f ".claude/settings.json" ]; then
        if grep -q '"statusLine"' .claude/settings.json; then
            :
        else
            echo "  ⚠  .claude/settings.json exists without statusLine — please add statusLine config manually from muster/templates/.claude/settings.json"
        fi
    else
        cp muster/templates/.claude/settings.json .claude/settings.json
    fi

    # Slash commands / skills (Phase 7 — /rebind for mid-session role change)
    if [ -d "muster/templates/.claude/skills" ]; then
        mkdir -p .claude/skills
        cp -r muster/templates/.claude/skills/* .claude/skills/
    fi

    if [ ! -f "CLAUDE.md" ]; then
        cp muster/templates/CLAUDE.md CLAUDE.md
    fi

    cp -r muster/templates/knowledge-base .

    find . -name ".DS_Store" -delete 2>/dev/null || true

    substep_done "1.3" "Scaffold knowledge-base + agent bootloaders + status line + skills"
    write_state create_project_dir submodule_add scaffold_templates
else
    substep_done "1.3" "Scaffold knowledge-base + agent bootloaders + status line + skills"
fi

# ---------- step 1.4: initialize_populated_file ----------
# Greenfield: copy template as-is. onboarded_at + agents.pm both stay null.
# That signals "first greenfield session" — PM fires the welcome message.
# Once PM does work in Stage 1, it sets its own timestamp and subsequent
# sessions skip the welcome.
if ! state_has_step "initialize_populated_file"; then
    # Template was copied in 1.3 — verify it's there
    if [ ! -f "knowledge-base/agent-context/.populated" ]; then
        err "Template .populated not found. Resolve manually."
        exit 1
    fi
    substep_done "1.4" "Initialize .populated state file (greenfield — onboarded_at null)"
    write_state create_project_dir submodule_add scaffold_templates initialize_populated_file
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
    write_state create_project_dir submodule_add scaffold_templates initialize_populated_file agent_skills_created
else
    substep_done "1.5" "Create agent-skills/ directories"
fi

# ---------- step 1.6: gitignore_updated ----------
if ! state_has_step "gitignore_updated"; then
    GITIGNORE_ENTRIES=(
        ".DS_Store"
        "*.swp"
        "*.swo"
        "*~"
        ".muster-setup-state.json"
        ".claude/.muster-bound-role.*"
        ".claude/.muster-last-role"
        ".muster-sprint-logs/"
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
        substep_done "1.6" "Create .gitignore (added Muster entries)"
    else
        substep_skip "1.6" "Create .gitignore" "already up to date"
    fi
    write_state create_project_dir submodule_add scaffold_templates initialize_populated_file agent_skills_created gitignore_updated
else
    substep_done "1.6" "Create .gitignore"
fi

# ---------- step 1.7: initial_commit ----------
if ! state_has_step "initial_commit"; then
    git add -A
    git commit -q -m "Initial project setup with Muster AI framework

Scaffolded from muster/templates/ via setup-project.sh.
Includes agent bootloaders, knowledge-base templates, and project CLAUDE.md."
    substep_done "1.7" "Create initial commit"
    write_state create_project_dir submodule_add scaffold_templates initialize_populated_file agent_skills_created gitignore_updated initial_commit
else
    substep_done "1.7" "Create initial commit"
fi

# ---------- cleanup: remove state file on success ----------
rm -f "$STATE_FILE"

# ---------- completion banner + Step 2 ----------
completion_banner

section_header "Step 2: Open Claude Code and kick off Discovery"

printf "  Run:\n"
printf "    %scd %s%s\n" "$BOLD$CYAN" "$PROJECT_NAME" "$RESET"
printf "    %s%s%s\n\n" "$BOLD$CYAN" "claude" "$RESET"
printf "  Then send Claude this first message:\n"
printf "    %s%s%s\n\n" "$BOLD$CYAN" "Let's start Discovery." "$RESET"
printf "  %sAny first message works%s — Claude detects greenfield state on the\n" "$DIM" "$RESET"
printf "  %sfirst message and routes to the guided Discovery flow.%s\n\n" "$DIM" "$RESET"

printf "  %sWhat to expect:%s 5 stages across ~3 sessions over a day or two.\n" "$BOLD" "$RESET"
printf "  Claude opens with a brief welcome that walks you through them.\n"
printf "  Stage 1 (idea share, ~10 min) is the %shighest-leverage%s step —\n" "$YELLOW" "$RESET"
printf "  pick a time you can describe your idea without distraction.\n\n"

printf "  Full guide: %smuster/getting-started.md%s\n\n" "$CYAN" "$RESET"
