#!/usr/bin/env bash
# migrate-v1-to-v2.sh — upgrade a Muster v1 project to v2.
#
# Run from the project root (NOT from inside muster/):
#   bash muster/scripts/migrate-v1-to-v2.sh
#
# What changes between v1 and v2:
#   - knowledge-base/agent-context/.populated is now a required routing signal
#   - .claude/agents/<7>.md gain a HALT check for unpopulated agent-context state
#   - Project root CLAUDE.md replaces "System Bootstrap" block with slim routing block
#
# Safety:
#   - First action is a tarball backup of everything that could be touched.
#   - CLAUDE.md edit shows a diff and asks before writing.
#   - Idempotent: re-running on a v2 project exits cleanly.
#   - Rollback: tar xzf .muster-archive/v1-backup-<timestamp>.tar.gz -C .

set -euo pipefail

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NOW_FILE_SAFE="$(printf '%s' "$NOW" | tr ':' '-')"

ARCHIVE_DIR=".muster-archive"
BACKUP_TARBALL="$ARCHIVE_DIR/v1-backup-$NOW_FILE_SAFE.tar.gz"
CLAUDE_BACKUP="$ARCHIVE_DIR/CLAUDE.md.pre-v2"

POPULATED="knowledge-base/agent-context/.populated"
PROJECT_CLAUDE="CLAUDE.md"
TEMPLATES_AGENTS_DIR="muster/templates/.claude/agents"
TEMPLATES_CLAUDE="muster/templates/CLAUDE.md"

V1_START_MARKER="<!-- MUSTER SYSTEM BOOTSTRAP — DO NOT REMOVE OR MODIFY THIS SECTION -->"
V1_END_MARKER="<!-- END MUSTER SYSTEM BOOTSTRAP -->"
V2_START_MARKER="<!-- MUSTER BOOTSTRAP — DO NOT REMOVE -->"
V2_END_MARKER="<!-- END BOOTSTRAP -->"

# ---------- colors ----------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
    CYAN=$'\033[36m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
    RED=; GREEN=; YELLOW=; CYAN=; BOLD=; DIM=; RESET=
fi

say()  { printf '%s\n' "$*"; }
err()  { printf '%sERROR:%s %s\n' "$RED$BOLD" "$RESET" "$*" >&2; }
ok()   { printf '%s✓%s %s\n' "$GREEN$BOLD" "$RESET" "$*"; }
info() { printf '%sℹ%s %s\n' "$CYAN" "$RESET" "$*"; }
warn() { printf '%s!%s %s\n' "$YELLOW$BOLD" "$RESET" "$*"; }

# ---------- pre-flight ----------

if [ ! -d "muster" ]; then
    err "muster/ directory not found. Run from your project root, not from inside muster/."
    exit 1
fi

if [ ! -f "$TEMPLATES_CLAUDE" ] || [ ! -d "$TEMPLATES_AGENTS_DIR" ]; then
    err "Cannot find v2 templates inside muster/."
    err "Update the muster submodule first:"
    err "  git submodule update --remote muster"
    exit 1
fi

if [ ! -d "knowledge-base" ] || [ ! -d ".claude/agents" ] || [ ! -f "$PROJECT_CLAUDE" ]; then
    err "This doesn't look like a Muster project."
    err "Expected: knowledge-base/, .claude/agents/, CLAUDE.md at the current directory."
    exit 1
fi

# Idempotency: detect already-v2
if [ -f "$POPULATED" ] && grep -q '"version"[[:space:]]*:[[:space:]]*"2"' "$POPULATED"; then
    ok "Already on v2. Nothing to do."
    exit 0
fi

# Detect partial-v2 (file exists with version 1 — testing branch users)
PARTIAL_V2=0
if [ -f "$POPULATED" ]; then
    if grep -q '"version"[[:space:]]*:[[:space:]]*"1"' "$POPULATED"; then
        PARTIAL_V2=1
        info "Found v1-schema .populated — will upgrade in place."
    else
        err ".populated exists but version field is unexpected."
        err "Inspect $POPULATED manually and resolve before re-running."
        exit 1
    fi
fi

# ---------- validate CLAUDE.md BEFORE doing anything ----------

if ! grep -qF "$V1_START_MARKER" "$PROJECT_CLAUDE" && ! grep -qF "$V2_START_MARKER" "$PROJECT_CLAUDE"; then
    err "Cannot find any Muster bootstrap markers in $PROJECT_CLAUDE."
    err "This usually means the file was customized beyond the auto-migration scope."
    err "Manual instructions: muster/MIGRATING-V1-TO-V2.md"
    exit 1
fi

CLAUDE_ALREADY_V2=0
if grep -qF "$V2_START_MARKER" "$PROJECT_CLAUDE"; then
    CLAUDE_ALREADY_V2=1
    info "$PROJECT_CLAUDE already has v2 markers — skipping CLAUDE.md patch."
else
    if ! grep -qF "$V1_END_MARKER" "$PROJECT_CLAUDE"; then
        err "Found v1 START marker but missing v1 END marker in $PROJECT_CLAUDE."
        err "Manual instructions: muster/MIGRATING-V1-TO-V2.md"
        exit 1
    fi

fi

# ---------- banner + confirm ----------

say ""
say "${BOLD}${CYAN}Muster v1 → v2 Migration${RESET}"
say ""
say "Will modify these files (backups taken first):"
say "  - $PROJECT_CLAUDE                    (replace bootstrap block with slim routing block)"
say "  - .claude/agents/<7 specialists>.md  (insert one HALT-check line per file; +1 bootstrap line for developer)"
say "  - $POPULATED  (create — required v2 routing signal)"
say ""
say "Backups:"
say "  - $BACKUP_TARBALL  (full tarball — rollback target)"
say "  - $CLAUDE_BACKUP  (v1 CLAUDE.md, individual copy)"
say ""
say "${DIM}Rollback if anything goes wrong:${RESET}"
say "${DIM}  rm -f $POPULATED && tar xzf $BACKUP_TARBALL -C .${RESET}"
say ""
printf "Proceed? [y/N] "
read -r CONFIRM < /dev/tty
case "$CONFIRM" in
    y|Y|yes|YES) ;;
    *) say "Aborted. No changes made."; exit 0 ;;
esac

# ---------- tarball backup ----------

mkdir -p "$ARCHIVE_DIR"
TAR_TARGETS=()
[ -f "$PROJECT_CLAUDE" ] && TAR_TARGETS+=("$PROJECT_CLAUDE")
[ -d ".claude/agents" ] && TAR_TARGETS+=(".claude/agents")
[ -d "knowledge-base/agent-context" ] && TAR_TARGETS+=("knowledge-base/agent-context")

tar czf "$BACKUP_TARBALL" "${TAR_TARGETS[@]}"
ok "Backup created: $BACKUP_TARBALL"

# ---------- create / upgrade .populated ----------

say ""
info "Creating ${POPULATED}…"

mkdir -p "knowledge-base/agent-context"

# Heuristic: agent-context file is "filled" iff its first line no longer contains "[Project Name]".
# Templates ship with `# <Role> Context — [Project Name]` as line 1; users overwrite that on populate.
agent_timestamp() {
    local file="$1"
    if [ ! -f "$file" ]; then
        printf 'null'
        return
    fi
    if head -1 "$file" | grep -qF "[Project Name]"; then
        printf 'null'
    else
        printf '"%s"' "$NOW"
    fi
}

CONTENT_TS=$(agent_timestamp "knowledge-base/agent-context/content.md")
DEVELOPER_TS=$(agent_timestamp "knowledge-base/agent-context/developer.md")
LEGAL_TS=$(agent_timestamp "knowledge-base/agent-context/legal.md")
MARKETING_TS=$(agent_timestamp "knowledge-base/agent-context/marketing.md")
QA_TS=$(agent_timestamp "knowledge-base/agent-context/qa.md")
RESEARCH_TS=$(agent_timestamp "knowledge-base/agent-context/research.md")
UIUX_TS=$(agent_timestamp "knowledge-base/agent-context/ui-ux.md")

cat > "$POPULATED" <<EOF
{
  "version": "2",
  "onboarded_at": "$NOW",
  "onboarding_complete_at": "$NOW",
  "agents": {
    "pm": "$NOW",
    "developer": $DEVELOPER_TS,
    "ui-ux": $UIUX_TS,
    "content": $CONTENT_TS,
    "qa": $QA_TS,
    "research": $RESEARCH_TS,
    "marketing": $MARKETING_TS,
    "legal": $LEGAL_TS
  },
  "lock": null
}
EOF
ok ".populated written ($POPULATED)"

say ""
info "Per-agent populate state (null entries trigger JIT populate on first invocation):"
for agent in content developer legal marketing qa research ui-ux; do
    file="knowledge-base/agent-context/$agent.md"
    ts=$(agent_timestamp "$file")
    if [ "$ts" = "null" ]; then
        say "  ${DIM}$agent: null  (still unfilled template — agent-context will populate on first use)${RESET}"
    else
        say "  ${GREEN}$agent: timestamped${RESET}"
    fi
done

# ---------- inject HALT check into specialist configs ----------
#
# Surgical insertion of the v2 startup-halt line(s). v1→v2 only adds:
#   - 6 specialists: one HALT-check paragraph
#   - developer.md: that paragraph + a bootstrap-mode branch line above it
# Full-file refresh would clobber any user customizations; we just inject.

say ""
info "Adding v2 HALT check to .claude/agents/ specialists…"

# Role-name lookup (anchor line uses display name, not the slug).
role_name_for() {
    case "$1" in
        content)    printf 'Content' ;;
        developer)  printf 'Developer' ;;
        legal)      printf 'Legal' ;;
        marketing)  printf 'Marketing' ;;
        qa)         printf 'QA' ;;
        research)   printf 'Research' ;;
        ui-ux)      printf 'UI/UX Designer' ;;
    esac
}

inject_halt() {
    local agent="$1"
    local file=".claude/agents/$agent.md"
    local role; role="$(role_name_for "$agent")"
    local anchor="You are the $role agent for this project."

    if [ ! -f "$file" ]; then
        warn "  $agent.md missing — skipping (run setup-existing-project.sh to scaffold)"
        return
    fi

    # Idempotency: any existing "Startup halt" marker means injection already done
    # (or the user has the older soft-phrasing version from develop testing).
    if grep -qF "Startup halt" "$file"; then
        say "  ${DIM}$agent.md already has a HALT marker — skipped${RESET}"
        return
    fi

    if ! grep -qF "$anchor" "$file"; then
        warn "  $agent.md missing anchor line ('$anchor') — skipped"
        warn "    Manually add the HALT check from muster/templates/.claude/agents/$agent.md"
        return
    fi

    local halt_line
    halt_line="**Startup halt — FIRST action**: Read \`knowledge-base/agent-context/.populated\`. If \`agents.$agent\` is \`null\`, your ENTIRE response must be exactly: \`HALT: agent-context null. PM: run JIT populate per context-cascading.md, then re-invoke.\` — and nothing else. Do not answer the user, read other files, or self-populate (Rule 1). If it's a timestamp, continue startup."

    local tmp; tmp="$(mktemp)"
    awk -v anchor="$anchor" -v halt="$halt_line" '
        $0 == anchor && !done {
            print
            print ""
            print halt
            done = 1
            next
        }
        { print }
    ' "$file" > "$tmp" && mv "$tmp" "$file"
    say "  ${GREEN}$agent.md${RESET} — HALT check inserted"
}

inject_developer_bootstrap_and_halt() {
    local file=".claude/agents/developer.md"
    local anchor="You are the Developer agent for this project."

    if [ ! -f "$file" ]; then
        warn "  developer.md missing — skipping"
        return
    fi
    if grep -qF "Startup halt" "$file"; then
        say "  ${DIM}developer.md already has a HALT marker — skipped${RESET}"
        return
    fi
    if ! grep -qF "$anchor" "$file"; then
        warn "  developer.md missing anchor line — skipped"
        return
    fi

    local bootstrap_line
    bootstrap_line="**Bootstrap-mode branch (Developer-only)**: If BOTH \`knowledge-base/.muster-onboarding/audit-brief.md\` exists AND \`.populated.agents.developer\` is \`null\`, you are in bootstrap mode for the onboarding code audit. Skip standard startup (agent-context/developer.md is unpopulated — this audit feeds it). Read the audit-brief and \`muster/team/developer/skills/generic/codebase-audit.md\`, then follow that skill. Bootstrap tool scope: Read/Grep/Glob only — no Edit/Bash. Write only to \`.muster-onboarding/architecture-audit-notes.md\` (and \`knowledge-base/design-system-reference.md\` if a design system is detected). Return to PM when done. Otherwise skip and proceed to the halt check."

    local halt_line
    halt_line="**Startup halt — FIRST action of normal operation**: Read \`knowledge-base/agent-context/.populated\`. If \`agents.developer\` is \`null\`, your ENTIRE response must be exactly: \`HALT: agent-context null. PM: run JIT populate per context-cascading.md, then re-invoke.\` — and nothing else. Do not answer the user, read other files, or self-populate (Rule 1). If it's a timestamp, continue startup."

    local tmp; tmp="$(mktemp)"
    awk -v anchor="$anchor" -v bootstrap="$bootstrap_line" -v halt="$halt_line" '
        $0 == anchor && !done {
            print
            print ""
            print bootstrap
            print ""
            print halt
            done = 1
            next
        }
        { print }
    ' "$file" > "$tmp" && mv "$tmp" "$file"
    say "  ${GREEN}developer.md${RESET} — bootstrap-mode branch + HALT check inserted"
}

for agent in content legal marketing qa research ui-ux; do
    inject_halt "$agent"
done
inject_developer_bootstrap_and_halt

ok "Specialist configs updated"

# ---------- patch project root CLAUDE.md ----------

if [ "$CLAUDE_ALREADY_V2" -eq 0 ]; then
    say ""
    info "Patching ${PROJECT_CLAUDE}…"

    V1_START_LINE=$(grep -nF "$V1_START_MARKER" "$PROJECT_CLAUDE" | head -1 | cut -d: -f1)
    V1_END_LINE=$(grep -nF "$V1_END_MARKER" "$PROJECT_CLAUDE" | head -1 | cut -d: -f1)

    # Pull the v2 slim block from the template — everything from start marker through end marker line.
    V2_START_LINE_T=$(grep -nF "$V2_START_MARKER" "$TEMPLATES_CLAUDE" | head -1 | cut -d: -f1)
    V2_END_LINE_T=$(grep -nF "$V2_END_MARKER" "$TEMPLATES_CLAUDE" | head -1 | cut -d: -f1)

    if [ -z "$V2_START_LINE_T" ] || [ -z "$V2_END_LINE_T" ]; then
        err "Cannot locate v2 markers in $TEMPLATES_CLAUDE. Templates may be corrupted."
        exit 1
    fi

    say ""
    say "${BOLD}Will replace lines $V1_START_LINE-$V1_END_LINE in $PROJECT_CLAUDE${RESET}"
    say ""
    say "${RED}--- removing -----------------------------------${RESET}"
    sed -n "${V1_START_LINE},${V1_END_LINE}p" "$PROJECT_CLAUDE" | sed 's/^/  /'
    say "${RED}------------------------------------------------${RESET}"
    say ""
    say "${GREEN}+++ adding -------------------------------------${RESET}"
    sed -n "${V2_START_LINE_T},${V2_END_LINE_T}p" "$TEMPLATES_CLAUDE" | sed 's/^/  /'
    say "${GREEN}------------------------------------------------${RESET}"
    say ""
    say "Everything outside the bootstrap block in your CLAUDE.md will be left untouched."
    say ""
    printf "Apply this CLAUDE.md change? [y/N] "
    read -r CONFIRM_CLAUDE < /dev/tty
    case "$CONFIRM_CLAUDE" in
        y|Y|yes|YES) ;;
        *)
            warn "Skipped CLAUDE.md patch."
            warn "Your project will not boot correctly until CLAUDE.md is updated."
            warn "Manual instructions: muster/MIGRATING-V1-TO-V2.md"
            warn "Re-run this script when ready."
            exit 0
            ;;
    esac

    cp "$PROJECT_CLAUDE" "$CLAUDE_BACKUP"

    TMP_OUT="$(mktemp)"
    {
        # Preserve any content before the v1 start marker (e.g., a project H1).
        if [ "$V1_START_LINE" -gt 1 ]; then
            sed -n "1,$((V1_START_LINE - 1))p" "$PROJECT_CLAUDE"
        fi
        # v2 slim block (replaces the v1 bootstrap block in-place).
        sed -n "${V2_START_LINE_T},${V2_END_LINE_T}p" "$TEMPLATES_CLAUDE"
        # Preserve everything after the v1 end marker.
        sed -n "$((V1_END_LINE + 1)),\$p" "$PROJECT_CLAUDE"
    } > "$TMP_OUT"
    mv "$TMP_OUT" "$PROJECT_CLAUDE"
    ok "CLAUDE.md patched (v1 backup: $CLAUDE_BACKUP)"
fi

# ---------- final summary ----------

say ""
say "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
say "${GREEN}${BOLD}║  Migration complete — project is now on v2.      ║${RESET}"
say "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
say ""
say "${BOLD}Next step:${RESET} restart your Claude Code session in this project."
say "Stale sessions won't see the new routing until reopened."
say ""
if [ -f "knowledge-base/orchestration-queue.md" ] && grep -q '\*\*Agent\*\*:' knowledge-base/orchestration-queue.md; then
    say "${YELLOW}${BOLD}!${RESET} Your orchestration-queue.md still has v1-format entries (no @<agent> tag)."
    say "  Either manually type @<agent> when copy-pasting, or ask PM to re-plan the"
    say "  current sprint — PM will regenerate the queue in v2 format."
    say ""
fi
say "Backups (kept indefinitely; safe to delete once you've confirmed v2 works):"
say "  - $BACKUP_TARBALL"
[ "$CLAUDE_ALREADY_V2" -eq 0 ] && say "  - $CLAUDE_BACKUP"
say ""
say "${DIM}Rollback at any time:${RESET}"
say "${DIM}  rm -f $POPULATED && tar xzf $BACKUP_TARBALL -C .${RESET}"
say ""
