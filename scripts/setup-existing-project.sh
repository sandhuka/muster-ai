#!/usr/bin/env bash
set -euo pipefail

# Muster — Existing Project Setup Script
#
# Adds Muster to an existing project. Runs in the current directory.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/sandhuka/muster-ai/main/scripts/setup-existing-project.sh | bash
#   ./setup-existing-project.sh
#   ./setup-existing-project.sh --resume        # continue an interrupted run
#   ./setup-existing-project.sh --muster-url <url>

DEFAULT_MUSTER_URL="https://github.com/sandhuka/muster-ai.git"
STATE_FILE=".muster-setup-state.json"
ARCHIVE_DIR=".muster-archive"

# ---------- argument parsing ----------
RESUME=0
MUSTER_URL="$DEFAULT_MUSTER_URL"

while [ $# -gt 0 ]; do
    case "$1" in
        --resume)           RESUME=1; shift ;;
        --muster-url)       MUSTER_URL="$2"; shift 2 ;;
        -h|--help)
            sed -n '3,10p' "${BASH_SOURCE[0]:-$0}" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *)                  echo "Unknown arg: $1"; exit 1 ;;
    esac
done

# ---------- helpers ----------
say() { printf "%s\n" "$*"; }
err() { printf "Error: %s\n" "$*" >&2; }

prompt_input() {
    # Read one line of input from /dev/tty so that `curl | bash` still works.
    local prompt="$1" answer
    printf "%s" "$prompt" > /dev/tty
    read -r answer < /dev/tty
    printf "%s" "$answer"
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

# ---------- resume validation ----------
if [ "$RESUME" -eq 1 ]; then
    if [ ! -f "$STATE_FILE" ]; then
        err "--resume given, but no $STATE_FILE found. Remove --resume to start fresh."
        exit 1
    fi
    REPO_SHAPE="$(read_repo_shape)"
    STARTED_AT="$(read_started_at)"
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

Your repo shape (git organization):
  (1) Single git repo — any surfaces and tiers inside (monorepo,
      frontend+backend colocated, single-surface product; all the same)
  (2) Multi-repo parent — multiple git repos sitting inside a parent folder
  (3) Cancel — I want to read the guide first

PROMPT

    CHOICE="$(prompt_input "> ")"
    case "$CHOICE" in
        1) REPO_SHAPE="single" ;;
        2) REPO_SHAPE="multi-repo-parent" ;;
        3) say "Cancelled. See muster/adopting-existing-project.md for the guide."; exit 0 ;;
        *) err "Invalid choice. Re-run and pick 1, 2, or 3."; exit 1 ;;
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

# ---------- step: archive_existing ----------
if ! state_has_step "archive_existing"; then
    say ""
    say "Step: archive existing CLAUDE.md / .claude/agents (if any)"

    mkdir -p "$ARCHIVE_DIR"

    if [ -f "CLAUDE.md" ]; then
        if [ -f "$ARCHIVE_DIR/CLAUDE.md.pre-muster" ]; then
            err "$ARCHIVE_DIR/CLAUDE.md.pre-muster already exists. Resolve manually."
            exit 1
        fi
        mv CLAUDE.md "$ARCHIVE_DIR/CLAUDE.md.pre-muster"
        say "  Archived CLAUDE.md -> $ARCHIVE_DIR/CLAUDE.md.pre-muster"
    fi

    if [ -d ".claude/agents" ]; then
        if [ -d "$ARCHIVE_DIR/claude-agents.pre-muster" ]; then
            err "$ARCHIVE_DIR/claude-agents.pre-muster already exists. Resolve manually."
            exit 1
        fi
        mv .claude/agents "$ARCHIVE_DIR/claude-agents.pre-muster"
        say "  Archived .claude/agents/ -> $ARCHIVE_DIR/claude-agents.pre-muster/"
    fi

    write_state "$REPO_SHAPE" archive_existing
fi

# ---------- step: submodule_add ----------
if ! state_has_step "submodule_add"; then
    say ""
    say "Step: add Muster as git submodule"

    if [ -d "muster" ]; then
        err "muster/ already exists. Resolve manually (git submodule deinit / rm -rf) before resuming."
        exit 1
    fi

    git submodule add "$MUSTER_URL" muster
    write_state "$REPO_SHAPE" archive_existing submodule_add
fi

# ---------- step: scaffold_templates ----------
if ! state_has_step "scaffold_templates"; then
    say ""
    say "Step: scaffold knowledge-base + agent bootloaders"

    mkdir -p .claude/agents
    cp muster/templates/.claude/agents/*.md .claude/agents/

    if [ ! -f "CLAUDE.md" ]; then
        cp muster/templates/CLAUDE.md CLAUDE.md
    fi

    cp -r muster/templates/knowledge-base .

    # Remove template .DS_Store files if any
    find . -name ".DS_Store" -delete 2>/dev/null || true

    write_state "$REPO_SHAPE" archive_existing submodule_add scaffold_templates
fi

# ---------- step: initialize_populated_file ----------
if ! state_has_step "initialize_populated_file"; then
    say ""
    say "Step: initialize agent-context/.populated with onboarded_at"

    ONBOARDED_AT="$(iso_now)"
    # PM (Root Claude) is always "populated" — it's the populator, not a populate target.
    # All specialists start null; PM writes their entries during reverse discovery.
    cat > knowledge-base/agent-context/.populated <<EOF
{
  "version": "1",
  "onboarded_at": "$ONBOARDED_AT",
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

    write_state "$REPO_SHAPE" archive_existing submodule_add scaffold_templates initialize_populated_file
fi

# ---------- step: agent_skills_created ----------
if ! state_has_step "agent_skills_created"; then
    say ""
    say "Step: create agent-skills directories"
    for agent in content developer legal marketing pm qa research ui-ux; do
        mkdir -p "knowledge-base/agent-skills/$agent"
        touch "knowledge-base/agent-skills/$agent/.gitkeep"
    done
    write_state "$REPO_SHAPE" archive_existing submodule_add scaffold_templates initialize_populated_file agent_skills_created
fi

# ---------- step: gitignore_updated ----------
if ! state_has_step "gitignore_updated"; then
    say ""
    say "Step: update .gitignore"

    # Append only missing entries. Do not touch existing entries.
    GITIGNORE_ENTRIES=(
        ".DS_Store"
        "*.swp"
        "*.swo"
        "*~"
        ".muster-archive/"
        ".muster-setup-state.json"
        "knowledge-base/.muster-onboarding/"
    )

    touch .gitignore
    for entry in "${GITIGNORE_ENTRIES[@]}"; do
        if ! grep -qxF "$entry" .gitignore 2>/dev/null; then
            printf "%s\n" "$entry" >> .gitignore
        fi
    done

    write_state "$REPO_SHAPE" archive_existing submodule_add scaffold_templates initialize_populated_file agent_skills_created gitignore_updated
fi

# ---------- cleanup: remove state file on success ----------
rm -f "$STATE_FILE"

# ---------- final summary ----------
cat <<'DONE'

================================================================
  Muster setup complete.
================================================================

Next step:

  claude

When the session opens, Root Claude (PM) will detect existing-project
mid-onboarding, read the reverse-discovery skill, and guide you through:

  1. A short Muster orientation (~90 seconds)
  2. CLAUDE.md merge (if you had one)
  3. A free-form brain-dump about your product
  4. A shallow code audit (read-only)
  5. Per-item review of the audit
  6. An adaptive questionnaire
  7. Review of the populated knowledge-base files
  8. Sprint 1 planning

Total founder time: about 2 hours for a typical project.

If setup was interrupted mid-run, re-run with --resume to continue:

  ./setup-existing-project.sh --resume

For the full guide, see: muster/adopting-existing-project.md
DONE
