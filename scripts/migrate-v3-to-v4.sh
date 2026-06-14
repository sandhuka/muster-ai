#!/usr/bin/env bash
set -euo pipefail

# Muster — Migrate v3 → v4
#
# Updates an existing Muster v3 project to v4 (autonomous sprint execution: the
# sprint-loop scripts, wave gates, observation triage, and PM-sole-escalation
# gatekeeping). Run from the project root.
#
# Usage:
#   bash muster/scripts/migrate-v3-to-v4.sh
#   bash muster/scripts/migrate-v3-to-v4.sh --dry-run   # show what would change, don't touch files
#   bash muster/scripts/migrate-v3-to-v4.sh -h | --help
#
# What this does:
#   - Seeds any NEW knowledge-base template files the project is missing
#     (copy-if-absent) — wave-review.md (wave-gate I/O), triage-log.md
#     (observation-disposition audit log), and founder-notices.md (autonomous-run
#     surface). Never overwrites existing content.
#   - Seeds the .muster/config tuning file (copy-if-absent) so a migrated project
#     can set driver knobs (MAX_STEPS, MAX_TURNS, models, KEEP_RUNS) without
#     editing the submodule.
#   - Seeds NEW project-level files that live OUTSIDE the submodule and so do NOT
#     arrive on a pointer bump: .claude/skills/* (the /muster front door, /rebind)
#     and scripts/test.sh (the quiet test runner). Copy-if-absent per item; never
#     clobbers a customized skill.
#
# What this does NOT do:
#   - Bump the muster submodule pointer (do that FIRST:
#       cd muster && git checkout main && git pull && cd ..
#     ALL v4 framework code — the muster-sprint-*.sh scripts, the observation-triage
#     skill, and the gatekeeping edits to system-guide.md / decision-making.md /
#     sprint-planning.md / CLAUDE.md — lives in the submodule and arrives with the
#     pointer bump. The project-side deltas are the files this script seeds:
#     knowledge-base templates, .muster/config, .claude/skills/*, scripts/test.sh.)
#   - Touch or overwrite existing knowledge-base content (preserved as-is). Your
#     orchestration-queue.md keeps its current format; it self-heals to the v4
#     template at the next sprint planning.
#
# Idempotent: re-running copies nothing once the files exist.

# ---------- argument parsing ----------
DRY_RUN=0
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)  DRY_RUN=1; shift ;;
        -h|--help)
            cat <<'HELP_EOF'
Muster — Migrate v3 → v4

Updates an existing Muster v3 project to v4 (autonomous sprint execution).
Run from your project root (where CLAUDE.md and the muster/ submodule live).

Usage:
  bash muster/scripts/migrate-v3-to-v4.sh
  bash muster/scripts/migrate-v3-to-v4.sh --dry-run     Show what would change without modifying files
  bash muster/scripts/migrate-v3-to-v4.sh -h | --help   Show this help

Bump the muster submodule to a v4 commit FIRST:
  cd muster && git checkout main && git pull && cd ..
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

say()  { printf "%s\n" "$*"; }
err()  { printf "%sError:%s %s\n" "$RED$BOLD" "$RESET" "$*" >&2; }
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

# ---------- precondition checks ----------
section_header "Migration precondition checks"

if [ ! -f "CLAUDE.md" ]; then
    err "No CLAUDE.md found. Run this script from your project root (the directory with CLAUDE.md and the muster/ submodule)."
    exit 1
fi

if [ ! -d "muster" ]; then
    err "No muster/ submodule found. This script requires an existing Muster project."
    exit 1
fi

# A v4 muster ships the wave-review.md template. If it's absent the submodule is
# still on a pre-v4 commit — the framework code wouldn't be present either.
if [ ! -f "muster/templates/knowledge-base/wave-review.md" ]; then
    err "The muster submodule is on a pre-v4 commit (no wave-review.md template)."
    err "Bump it first: cd muster && git checkout main && git pull && cd .."
    exit 1
fi

if [ ! -d "knowledge-base" ]; then
    err "No knowledge-base/ found. This is not a valid Muster project state."
    exit 1
fi

substep_done "0.1" "CLAUDE.md found"
substep_done "0.2" "muster/ submodule present and on a v4 commit"
substep_done "0.3" "knowledge-base/ exists"

MUSTER_VERSION="$(cat muster/VERSION 2>/dev/null || echo '?')"
say ""
say "muster framework version: ${BOLD}${MUSTER_VERSION}${RESET}"

# ---------- migration step: seed missing template files ----------
section_header "Step 1: Seed missing template files (copy-if-absent)"

copied=0
gitignored=0
for src in muster/templates/knowledge-base/*; do
    # Top-level files only — subdirectories are handled at setup and have their own structure.
    [ -f "$src" ] || continue
    name="$(basename "$src")"
    dest="knowledge-base/$name"
    if [ -e "$dest" ]; then
        substep_skip "1" "$name" "already present — preserved"
    else
        [ "$DRY_RUN" -eq 0 ] && cp "$src" "$dest"
        substep_done "1" "$name (seeded from template)"
        copied=$((copied+1))
    fi
done

# .muster/config — the project-local driver tuning file (4.2). Lives at the project
# root, not under knowledge-base/, so it's seeded separately. Copy-if-absent: never
# clobber a project's own knob settings.
config_src="muster/templates/.muster/config"
if [ -f "$config_src" ]; then
    if [ -e ".muster/config" ]; then
        substep_skip "1" ".muster/config" "already present — preserved"
    else
        if [ "$DRY_RUN" -eq 0 ]; then
            mkdir -p .muster
            cp "$config_src" .muster/config
        fi
        substep_done "1" ".muster/config (seeded from template)"
        copied=$((copied+1))
    fi
fi

# .claude/skills/* — project-level slash-command skills (the /muster front door,
# /rebind). These live OUTSIDE the submodule, so a pointer bump alone never delivers
# them — they must be seeded. New in 4.2: /muster. Copy-if-absent per skill dir so a
# project's customized skill is never clobbered.
if [ -d "muster/templates/.claude/skills" ]; then
    for src in muster/templates/.claude/skills/*; do
        [ -d "$src" ] || continue
        name="$(basename "$src")"
        dest=".claude/skills/$name"
        if [ -e "$dest" ]; then
            substep_skip "1" ".claude/skills/$name" "already present — preserved"
        else
            if [ "$DRY_RUN" -eq 0 ]; then
                mkdir -p .claude/skills
                cp -r "$src" "$dest"
            fi
            substep_done "1" ".claude/skills/$name (seeded from template)"
            copied=$((copied+1))
        fi
    done
fi

# scripts/test.sh — the quiet test runner template (4.2). Copy-if-absent + executable,
# matching fresh setup.
test_src="muster/templates/scripts/test.sh"
if [ -f "$test_src" ]; then
    if [ -e "scripts/test.sh" ]; then
        substep_skip "1" "scripts/test.sh" "already present — preserved"
    else
        if [ "$DRY_RUN" -eq 0 ]; then
            mkdir -p scripts
            cp "$test_src" scripts/test.sh
            chmod +x scripts/test.sh
        fi
        substep_done "1" "scripts/test.sh (seeded from template)"
        copied=$((copied+1))
    fi
fi

# ---------- migration step: gitignore the sprint logs ----------
section_header "Step 2: Ignore autonomous sprint logs"
if grep -qxF ".muster-sprint-logs/" .gitignore 2>/dev/null; then
    substep_skip "2" ".muster-sprint-logs/" "already in .gitignore"
else
    [ "$DRY_RUN" -eq 0 ] && { touch .gitignore; printf "%s\n" ".muster-sprint-logs/" >> .gitignore; }
    substep_done "2" ".muster-sprint-logs/ (added to .gitignore)"
    gitignored=1
fi

# ---------- summary ----------
section_header "Migration complete"
if [ "$DRY_RUN" -eq 1 ]; then
    say "Dry run — no files changed. Re-run without --dry-run to apply."
elif [ "$copied" -eq 0 ] && [ "$gitignored" -eq 0 ]; then
    say "Nothing to do — knowledge-base files present and sprint logs already ignored. Project is on v4."
elif [ "$copied" -eq 0 ]; then
    say "Knowledge-base files already present; sprint logs now gitignored. Project is now on v4."
else
    say "Seeded $copied new knowledge-base file(s); sprint logs gitignored. Project is now on v4."
fi
say ""
say "Next:"
say "  - Plan a sprint with PM (it rebuilds orchestration-queue.md in the v4 template)."
say "  - Run autonomous sprints: muster/scripts/muster-sprint-new.sh (two-tab flow)"
say "    or muster/scripts/muster-sprint-sandbox.sh (all-in-one). See muster/system-guide.md"
say "    → Autonomous Sprint Execution."
