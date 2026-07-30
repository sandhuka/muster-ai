#!/usr/bin/env bash
# muster-lint-refs.sh — lint family: checks skill citations + brain-file skill indexes; reports
# OK/FAIL; exit code is the verdict; never mutates. The deterministic replacement for the manual
# "verify cross-referenced files exist" self-review step, which caught 0 of 237 broken paths.
#
# What it asserts (framework repo — run from repo root, as CI does):
#   1. CITATIONS: every canonical name-citation — ``the `<name>` skill`` or ``<Role>'s `<name>`
#      skill`` — in team/**, templates/**, system-guide.md resolves to exactly one skill file.
#      A name that exists under 2+ roles MUST use the qualified form (bare "the" is ambiguous).
#      A qualified citation's role must actually own a skill of that name.
#   2. NO PATH CITATIONS: no `team/<role>/skills/<name>.md`-style skill-file path citations remain
#      in skill bodies or KB templates (brain-file indexes + system-guide registration examples are
#      the sanctioned exceptions — they ARE the name→location map).
#   3. INDEX PARITY: every skill on disk appears in its role's brain-file "Available Skills" index,
#      and every basename the index mentions exists on disk (case-exact both ways).
#
# Usage: bash scripts/muster-lint-refs.sh    (no args; paths are repo-relative)
# Exit:  0 = clean · 1 = one or more defects (each printed) · 2 = layout error
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
[ -d team ] || { echo "lint-refs: no team/ here — run from the muster tree" >&2; exit 2; }

fails=0
fail(){ echo "FAIL: $1"; fails=$((fails+1)); }

# ---- ground truth: basename -> "role/platform" list (case-exact via real listings) ----
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
find team -type f -path '*/skills/*' -name '*.md' | sort > "$TMP/disk"
awk -F/ '{ base=$NF; sub(/\.md$/,"",base); print base "|" $2 }' "$TMP/disk" | sort -u > "$TMP/owners"

owners_of(){ grep "^$1|" "$TMP/owners" | cut -d'|' -f2 | sort -u; }

# role display-name -> directory (for qualified citations)
role_dir(){
  case "$1" in
    Developer) echo developer ;; UI/UX) echo ui-ux ;; QA) echo qa ;; PM) echo pm ;;
    Content) echo content ;; Marketing) echo marketing ;; Legal) echo legal ;;
    Research) echo research ;; *) echo "" ;;
  esac
}

# ---- corpus: where citations live ----
find team templates -type f -name '*.md' > "$TMP/corpus"
echo system-guide.md >> "$TMP/corpus"

# ---- 1. canonical citations resolve ----
checked=0
while IFS= read -r f; do
  # strip fenced code blocks so format examples never self-trip
  awk '/^```/{inf=!inf; next} !inf' "$f" > "$TMP/body"

  # unqualified: the `<name>` skill   (skip placeholder tokens containing < > { } [ ])
  grep -oE 'the \`[A-Za-z0-9._-]+\` skill' "$TMP/body" | sort -u | while IFS= read -r c; do
    name="${c#the \`}"; name="${name%\` skill}"
    case "$name" in *'<'*|*'{'*|*'['*) continue ;; esac
    n="$(owners_of "$name" | grep -c . || true)"
    if [ "$n" -eq 0 ]; then echo "U0|$f|$name"
    elif [ "$n" -gt 1 ]; then echo "U2|$f|$name"
    fi
  done >> "$TMP/hits"

  # qualified: <Role>'s `<name>` skill
  grep -oE "[A-Za-z/]+'s \`[A-Za-z0-9._-]+\` skill" "$TMP/body" | sort -u | while IFS= read -r c; do
    disp="${c%%\'s*}"; name="${c#*\`}"; name="${name%\` skill}"
    case "$name" in *'<'*|*'{'*|*'['*) continue ;; esac
    dir="$(role_dir "$disp")"
    [ -z "$dir" ] && { echo "QR|$f|$disp|$name"; continue; }
    owners_of "$name" | grep -qx "$dir" || echo "QO|$f|$disp|$name"
  done >> "$TMP/hits"
  checked=$((checked+1))
done < "$TMP/corpus"

if [ -s "$TMP/hits" ]; then
  sort -u "$TMP/hits" | while IFS='|' read -r kind f a b; do
    case "$kind" in
      U0) echo "FAIL: $f — cites \"the \`$a\` skill\" but no skill named '$a' exists" ;;
      U2) echo "FAIL: $f — \"the \`$a\` skill\" is ambiguous ($(owners_of "$a" | tr '\n' ' ')) — use <Role>'s \`$a\` skill" ;;
      QR) echo "FAIL: $f — unknown role \"$a\" in citation \"$a's \`$b\` skill\"" ;;
      QO) echo "FAIL: $f — \"$a's \`$b\` skill\": role $a has no skill named '$b'" ;;
    esac
  done
  fails=$((fails + $(sort -u "$TMP/hits" | wc -l)))
fi

# ---- 2. no path-style skill citations outside the sanctioned map layer ----
# Sanctioned: brain files (team/*/CLAUDE.md — they ARE the name→location map), the bootstrap/config
# layer (templates/CLAUDE.md, templates/.claude/** — routing runs before any index is in context,
# so full paths there are the map itself), and project agent-skills dirs (out of scope).
grep -rnE '(muster/)?team/[a-z-]+/skills/[A-Za-z0-9_./-]*\.md' \
     --include='*.md' team templates 2>/dev/null \
  | grep -v -E '^team/[a-z-]+/CLAUDE\.md:' \
  | grep -v -E '^templates/CLAUDE\.md:|^templates/\.claude/' \
  | grep -v 'agent-skills' \
  | while IFS= read -r line; do
      echo "FAIL: path-style skill citation (cite by name instead): ${line%%:*}:$(echo "$line" | cut -d: -f2)"
    done > "$TMP/paths"
if [ -s "$TMP/paths" ]; then cat "$TMP/paths"; fails=$((fails + $(wc -l < "$TMP/paths"))); fi

# ---- 3. index parity: disk <-> brain-file "Available Skills" ----
# NB: no `grep -q` at the end of a pipe here — with pipefail, -q's early exit SIGPIPEs the
# upstream and turns a successful match into a pipeline failure. Compare against files instead.
for r in team/*/; do
  r="${r%/}"; role="$(basename "$r")"; brain="$r/CLAUDE.md"
  [ -d "$r/skills" ] || continue
  [ -f "$brain" ] || { fail "$role has skills/ but no brain file $brain"; continue; }
  find "$r/skills" -type f -name '*.md' -exec basename {} \; | sort > "$TMP/role_disk"
  while IFS= read -r base; do
    grep -qF "$base" "$brain" || fail "index parity: $role/skills/**/$base not listed in $brain \"Available Skills\""
  done < "$TMP/role_disk"
  # reverse: every **name.md** bullet in the index exists on disk (case-exact)
  while IFS= read -r base; do
    if ! grep -qxF "$base" "$TMP/role_disk"; then
      # cross-role entries carry an explicit (`team/<other>/skills/...`) location — verify that instead
      loc="$(grep -F "$base" "$brain" | grep -oE '\(\`(muster/)?team/[a-z-]+/skills/[a-z-]+/?\`\)' | head -1 | tr -d '()\`')"
      if [ -n "$loc" ]; then
        loc="${loc#muster/}"; loc="${loc%/}"
        [ -f "$loc/$base" ] || fail "index parity: $brain lists $base at $loc/ but it is not there"
      else
        fail "index parity: $brain lists $base but $role has no such skill on disk"
      fi
    fi
  done < <(grep -oE '^\- \*\*[A-Za-z0-9._-]+\.md\*\*' "$brain" 2>/dev/null | sed 's/^- \*\*//; s/\*\*$//')
done

echo "-----------------------------------------------"
if [ "$fails" -gt 0 ]; then
  echo "RESULT: $fails defect(s) across $checked files scanned"
  exit 1
fi
echo "OK: skill citations + index parity clean ($checked files scanned)"
