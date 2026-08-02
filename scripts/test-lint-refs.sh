#!/usr/bin/env bash
# test-lint-refs.sh — regression fixtures for muster-lint-refs.sh. Builds a throwaway muster tree
# and asserts each defect class is caught AND that a clean tree passes (a lint that can't fail is
# theater; a lint that can't pass is noise).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0

sub(){ # portable in-place sed: BSD/GNU -i syntaxes differ; tmp-file form works on both
  sed -e "$1" "$2" > "$2.tmp" && mv "$2.tmp" "$2"
}

check(){ # name expected_exit grep_substr
  local nm="$1" want="$2" sub="${3:-}"
  local out rc; out="$(cd "$T/m" && bash scripts/muster-lint-refs.sh 2>&1)"; rc=$?
  if [ "$rc" = "$want" ] && { [ -z "$sub" ] || printf '%s' "$out" | grep -qF "$sub"; }; then
    echo "PASS: $nm"; pass=$((pass+1))
  else
    echo "FAIL: $nm (rc=$rc want=$want)"; printf '%s\n' "$out" | sed 's/^/    /' | head -4; fail=$((fail+1))
  fi
}

scaffold(){ # (re)build a minimal clean tree
  rm -rf "$T/m"
  mkdir -p "$T/m/scripts" "$T/m/team/developer/skills/ios" "$T/m/team/ui-ux/skills/web" \
           "$T/m/team/developer/skills/web" "$T/m/templates/knowledge-base"
  cp "$HERE/muster-lint-refs.sh" "$T/m/scripts/"
  cat > "$T/m/team/developer/skills/ios/ios-mvvm.md" <<'EOF'
# MVVM
See the `shared-name` skill for overlap notes. Plain body.
EOF
  cat > "$T/m/team/developer/skills/web/shared-name.md" <<'EOF'
# Shared (developer copy)
EOF
  cat > "$T/m/team/ui-ux/skills/web/shared-name.md" <<'EOF'
# Shared (ui-ux copy)
See Developer's `shared-name` skill for the implementation side.
EOF
  cat > "$T/m/team/developer/CLAUDE.md" <<'EOF'
## Available Skills
- **ios-mvvm.md** — MVVM pattern
- **shared-name.md** — developer copy
EOF
  cat > "$T/m/team/ui-ux/CLAUDE.md" <<'EOF'
## Available Skills
- **shared-name.md** — ui-ux copy
EOF
  echo "# guide" > "$T/m/system-guide.md"
}

# --- 0. ambiguous unqualified citation IS a defect (ios-mvvm.md cites bare shared-name) ---
scaffold
check "ambiguous unqualified caught" 1 "is ambiguous"

# --- 1. clean tree passes (qualify the citation) ---
scaffold
sub 's/the `shared-name` skill/Developer'"'"'s `shared-name` skill/' "$T/m/team/developer/skills/ios/ios-mvvm.md"
check "clean tree passes" 0 "OK: skill citations"

# --- 2. citation to nonexistent skill ---
scaffold
sub 's/the `shared-name` skill/the `ghost` skill/' "$T/m/team/developer/skills/ios/ios-mvvm.md"
check "dangling name-citation caught" 1 "no skill named 'ghost'"

# --- 3. qualified citation naming a role that lacks the skill ---
scaffold
sub 's/the `shared-name` skill/QA'"'"'s `shared-name` skill/' "$T/m/team/developer/skills/ios/ios-mvvm.md"
check "wrong-role qualifier caught" 1 "has no skill named"

# --- 4. path-style citation in a skill body ---
scaffold
sub 's/the `shared-name` skill/Developer'"'"'s `shared-name` skill/' "$T/m/team/developer/skills/ios/ios-mvvm.md"
echo 'See `team/developer/skills/web/shared-name.md` for details.' >> "$T/m/team/ui-ux/skills/web/shared-name.md"
check "path-style citation caught" 1 "path-style skill citation"

# --- 5. skill on disk missing from index ---
scaffold
sub 's/the `shared-name` skill/Developer'"'"'s `shared-name` skill/' "$T/m/team/developer/skills/ios/ios-mvvm.md"
touch "$T/m/team/developer/skills/ios/unlisted.md"
check "unindexed skill caught" 1 "not listed as an index bullet in"

# --- 5b. a prose mention is NOT an index bullet — parity still red ---
scaffold
sub 's/the `shared-name` skill/Developer'"'"'s `shared-name` skill/' "$T/m/team/developer/skills/ios/ios-mvvm.md"
touch "$T/m/team/developer/skills/ios/unlisted.md"
echo 'We should document unlisted.md here someday.' >> "$T/m/team/developer/CLAUDE.md"
check "prose mention does not satisfy parity" 1 "not listed as an index bullet in"

# --- 5c. a longer name containing the base is NOT a match — parity still red ---
scaffold
sub 's/the `shared-name` skill/Developer'"'"'s `shared-name` skill/' "$T/m/team/developer/skills/ios/ios-mvvm.md"
touch "$T/m/team/developer/skills/ios/x.md"
echo '- **prefix-x.md** — a different skill entirely' >> "$T/m/team/developer/CLAUDE.md"
touch "$T/m/team/developer/skills/ios/prefix-x.md"
check "substring inside longer name rejected" 1 "x.md not listed as an index bullet"

# --- 6. index entry with no file on disk ---
scaffold
sub 's/the `shared-name` skill/Developer'"'"'s `shared-name` skill/' "$T/m/team/developer/skills/ios/ios-mvvm.md"
echo '- **deleted-skill.md** — gone' >> "$T/m/team/developer/CLAUDE.md"
check "dangling index entry caught" 1 "no such skill on disk"

# --- 7. fenced code blocks don't self-trip ---
scaffold
sub 's/the `shared-name` skill/Developer'"'"'s `shared-name` skill/' "$T/m/team/developer/skills/ios/ios-mvvm.md"
printf '```\nSee the `not-a-real-skill` skill inside a fence.\n```\n' >> "$T/m/team/developer/skills/ios/ios-mvvm.md"
check "fenced examples skipped" 0 ""

# --- 8. placeholder tokens skipped ---
scaffold
sub 's/the `shared-name` skill/Developer'"'"'s `shared-name` skill/' "$T/m/team/developer/skills/ios/ios-mvvm.md"
echo 'Template: See the `<sibling>` skill for [related].' >> "$T/m/team/developer/skills/ios/ios-mvvm.md"
check "placeholders skipped" 0 ""

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" = 0 ]
