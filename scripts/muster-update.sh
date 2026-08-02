#!/usr/bin/env bash
# muster-update.sh — action: converge project-level framework-owned files after a submodule bump (family: verb — acts, idempotently).
#
# The one command after `git -C muster pull` — and usually optional even then: picker and
# autonomous sessions read their protocols straight from the submodule, so a bare bump already
# updates them. This converges the platform-located, framework-owned surfaces that cannot ride
# the submodule (harness-parsed files at fixed paths):
#   .claude/agents/*.md stubs · .claude/statusline.sh stub · .claude/skills/<seeded>/SKILL.md ·
#   CLAUDE.md bootstrap block (marker-bounded) · settings.json permissions.allow (jq union —
#   every user key and entry preserved) · .gitignore boot-log line · .muster/seeded-version
#   stamp (written LAST, only on a fully-✓ run — a crashed run keeps the drift NOTICE alive).
# NEVER touches knowledge-base/, .muster/config, scripts/test.sh, or any project content.
# Missing framework-owned files are CREATED (a release adding a role is just another reseed).
#
# Refuses on a dirty git tree (git is the undo for everything this script overwrites). The
# muster/ submodule pointer is exempt from that check — the normal flow is:
#   git -C muster pull && bash muster/scripts/muster-update.sh && git add -A && git commit
#
# Usage (from the project root):
#   bash muster/scripts/muster-update.sh            # apply
#   bash muster/scripts/muster-update.sh --dry-run  # preview, writes nothing, ignores dirt
# Exit: 0 = converged (or already current) · 1 = refused / one or more steps ✗
set -uo pipefail

DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown arg: $arg" >&2; exit 1 ;;
    esac
done

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
else BOLD=''; DIM=''; GREEN=''; YELLOW=''; RED=''; RESET=''; fi
say(){ printf "%s\n" "$*"; }
ok(){   printf "  %s✓%s %s\n" "$GREEN$BOLD" "$RESET" "$1"; }
cur(){  printf "  %s·%s %s %s(current)%s\n" "$DIM" "$RESET" "$1" "$DIM" "$RESET"; }
warn(){ printf "  %s⚠%s %s\n" "$YELLOW" "$RESET" "$1"; }
bad(){  printf "  %s✗%s %s\n" "$RED$BOLD" "$RESET" "$1"; FAILED=1; }
FAILED=0

# ---------- preflight ----------
if [ ! -d "muster" ] || [ ! -f "CLAUDE.md" ]; then
    echo "Run from the project root (must have muster/ and CLAUDE.md)." >&2; exit 1
fi
if [ ! -f "muster/VERSION" ] || [ ! -d "muster/templates" ]; then
    echo "muster/ checkout incomplete (no VERSION/templates). Run: git submodule update --init" >&2; exit 1
fi
command -v jq >/dev/null 2>&1 || { echo "jq is required (brew/apt/dnf install jq)." >&2; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repository — git is the undo; refusing." >&2; exit 1; }

VERSION="$(tr -d '[:space:]' < muster/VERSION)"
STAMP=""; [ -f .muster/seeded-version ] && STAMP="$(tr -d '[:space:]' < .muster/seeded-version)"

# dirty-tree refusal (real runs only) — submodule pointer exempt, see header
if [ "$DRY_RUN" -eq 0 ]; then
    DIRT="$(git status --porcelain -- . ':(exclude)muster' 2>/dev/null)"
    if [ -n "$DIRT" ]; then
        echo "Working tree has uncommitted changes — commit them first (git is the undo for" >&2
        echo "everything this script overwrites), then re-run. Dirty paths:" >&2
        printf '%s\n' "$DIRT" | sed 's/^/  /' >&2
        exit 1
    fi
fi

say ""
say "${BOLD}muster-update — converging project to muster $VERSION${RESET}${DIM}$( [ "$DRY_RUN" -eq 1 ] && echo '  (dry run)')${RESET}"
if [ -n "$STAMP" ] && [ "$STAMP" != "$VERSION" ] && [ "$(printf '%s\n%s\n' "$STAMP" "$VERSION" | sort -V | tail -1)" = "$STAMP" ]; then
    warn "stamp $STAMP is NEWER than muster $VERSION — this looks like a submodule rollback; converging anyway"
fi
say ""

# converge one framework-owned file: $1=src template  $2=dest  $3=label
seed(){
    if [ -f "$2" ] && cmp -s "$1" "$2"; then cur "$3"; return; fi
    local verb="update"; [ -f "$2" ] || verb="create"
    if [ "$DRY_RUN" -eq 1 ]; then ok "would $verb $3"; return; fi
    mkdir -p "$(dirname "$2")" && cp "$1" "$2" && ok "${verb}d $3" || bad "$3 — copy failed"
}

# ---------- 1. agent stubs ----------
say "${BOLD}1.${RESET} .claude/agents/ stubs"
for t in muster/templates/.claude/agents/*.md; do
    seed "$t" ".claude/agents/$(basename "$t")" ".claude/agents/$(basename "$t")"
done

# ---------- 2. statusline stub ----------
say "${BOLD}2.${RESET} .claude/statusline.sh stub"
SL=muster/templates/.claude/statusline.sh
if [ -f .claude/statusline.sh ]; then
    seed "$SL" .claude/statusline.sh ".claude/statusline.sh"
    [ "$DRY_RUN" -eq 1 ] || chmod +x .claude/statusline.sh
elif [ -f .claude/settings.json ] && grep -q 'statusline\.sh' .claude/settings.json 2>/dev/null; then
    seed "$SL" .claude/statusline.sh ".claude/statusline.sh"
    [ "$DRY_RUN" -eq 1 ] || chmod +x .claude/statusline.sh
else
    cur "skipped — no project statusline (user-level statusline setup choice respected)"
fi

# ---------- 3. seeded skills ----------
say "${BOLD}3.${RESET} .claude/skills/ seeded stubs (user-added skills untouched)"
for d in muster/templates/.claude/skills/*/; do
    n="$(basename "$d")"
    seed "$d/SKILL.md" ".claude/skills/$n/SKILL.md" ".claude/skills/$n/SKILL.md"
done

# ---------- 4. CLAUDE.md bootstrap block (marker-bounded; project sections preserved) ----------
say "${BOLD}4.${RESET} CLAUDE.md bootstrap block"
M1='<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->'; M2='<!-- END BOOTSTRAP -->'
if ! grep -qF "$M1" CLAUDE.md || ! grep -qF "$M2" CLAUDE.md; then
    bad "CLAUDE.md is missing the BOOTSTRAP markers — copy the block from muster/templates/CLAUDE.md manually, then re-run"
else
    NEWB="$(mktemp)"; CURB="$(mktemp)"
    awk "/$M1/{f=1} f{print} /$M2/{f=0; exit}" muster/templates/CLAUDE.md > "$NEWB"
    awk "/$M1/{f=1} f{print} /$M2/{f=0; exit}" CLAUDE.md > "$CURB"
    if cmp -s "$NEWB" "$CURB"; then cur "bootstrap block"
    elif [ "$DRY_RUN" -eq 1 ]; then ok "would replace bootstrap block (between markers only)"
    else
        T="$(mktemp)"
        awk -v new_file="$NEWB" "
            /$M1/ { while ((getline line < new_file) > 0) print line; close(new_file); skip=1; next }
            /$M2/ { skip=0; next }
            !skip { print }
        " CLAUDE.md > "$T" && mv "$T" CLAUDE.md && ok "replaced bootstrap block" || bad "bootstrap block replace failed"
    fi
    rm -f "$NEWB" "$CURB"
fi

# ---------- 5. settings.json permissions (union with the template — the template IS the list) ----------
say "${BOLD}5.${RESET} .claude/settings.json permissions"
TALLOW="$(jq '.permissions.allow // []' muster/templates/.claude/settings.json)"
if [ -f .claude/settings.json ]; then
    MISSING="$(jq --argjson t "$TALLOW" '($t - (.permissions.allow // [])) | length' .claude/settings.json)"
    if [ "$MISSING" = "0" ]; then cur "all template pre-approvals present"
    elif [ "$DRY_RUN" -eq 1 ]; then ok "would add $MISSING pre-approval entry/entries (user entries + keys preserved)"
    else
        T="$(mktemp)"
        jq --argjson t "$TALLOW" '.permissions = (.permissions // {}) | .permissions.allow = ((.permissions.allow // []) + $t | unique)' \
            .claude/settings.json > "$T" && mv "$T" .claude/settings.json && ok "added $MISSING pre-approval entry/entries" || bad "settings merge failed"
    fi
elif [ -s "$HOME/.claude/settings.json" ] && [ "$(jq 'length' "$HOME/.claude/settings.json" 2>/dev/null || echo 0)" -gt 0 ]; then
    warn "no project settings.json and your user-level one has content — creating a project file"
    warn "would override it. Merge the permissions.allow entries from"
    warn "muster/templates/.claude/settings.json into $HOME/.claude/settings.json yourself."
else
    if [ "$DRY_RUN" -eq 1 ]; then ok "would create .claude/settings.json from template"
    else mkdir -p .claude && cp muster/templates/.claude/settings.json .claude/settings.json && ok "created .claude/settings.json from template" || bad "settings create failed"; fi
fi

# ---------- 6. gitignore ----------
say "${BOLD}6.${RESET} .gitignore boot-log entry"
BL="knowledge-base/.muster-boot-log"
if grep -qxF "$BL" .gitignore 2>/dev/null; then cur ".gitignore"
elif [ "$DRY_RUN" -eq 1 ]; then ok "would append $BL"
else touch .gitignore && printf '%s\n' "$BL" >> .gitignore && ok "appended $BL" || bad ".gitignore append failed"; fi

# ---------- stamp (LAST — only a fully-✓ run silences the drift NOTICE) ----------
say ""
if [ "$FAILED" -ne 0 ]; then
    say "${RED}${BOLD}Incomplete.${RESET} Fix the ✗ steps above and re-run; the drift NOTICE stays on until a clean run."
    exit 1
fi
if [ "$DRY_RUN" -eq 1 ]; then
    say "${BOLD}Dry run complete.${RESET} Re-run without --dry-run to apply."
elif [ "$STAMP" = "$VERSION" ]; then
    say "${GREEN}${BOLD}Current.${RESET} Project already seeded at muster $VERSION."
else
    mkdir -p .muster && printf '%s\n' "$VERSION" > .muster/seeded-version \
        && say "${GREEN}${BOLD}Done.${RESET} Project converged to muster $VERSION (stamp written). Commit when ready:" \
        && say "  git add -A && git commit -m \"chore: muster update to $VERSION\"" \
        || { say "${RED}stamp write failed${RESET}"; exit 1; }
fi
exit 0
