#!/usr/bin/env bash
#
# validate.sh — lint a skill folder against this repo's conventions.
#
# Usage:
#   scripts/validate.sh <skill-folder> [more-folders...]
#   scripts/validate.sh --all          # validate every skill folder in the repo
#
# Wraps the official `skills-ref validate` (if installed) and adds repo-specific
# checks it doesn't cover: name == folder, description <= 1024 chars, body < 500
# lines, and a high-signal secret scan. Exits non-zero if any skill fails.

set -uo pipefail

MAX_NAME=64
MAX_DESC=1024
MAX_BODY_LINES=500

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
total_fail=0

c_red=''; c_grn=''; c_ylw=''; c_dim=''; c_rst=''
if [ -t 1 ]; then
  c_red=$'\033[31m'; c_grn=$'\033[32m'; c_ylw=$'\033[33m'; c_dim=$'\033[2m'; c_rst=$'\033[0m'
fi

# --- helpers -----------------------------------------------------------------

# Extract a single frontmatter field's value, joining block-scalar / wrapped
# continuation lines. Strips surrounding quotes and collapses whitespace.
# Args: <frontmatter-text> <field-name>
field_value() {
  printf '%s\n' "$1" | awk -v key="$2" '
    $0 ~ "^" key ":" {
      sub("^" key ":[[:space:]]*", ""); buf = $0; grabbing = 1; next
    }
    grabbing {
      # stop at the next top-level key (unindented "word:")
      if ($0 ~ /^[A-Za-z0-9_-]+:/) { grabbing = 0 }
      else { sub(/^[[:space:]]+/, " "); buf = buf $0 }
    }
    END {
      gsub(/^[[:space:]>|-]+/, "", buf)   # drop block-scalar markers / lead ws
      gsub(/[[:space:]]+$/, "", buf)
      gsub(/^["'\'']|["'\'']$/, "", buf)  # strip wrapping quotes
      print buf
    }'
}

# --- per-skill validation ----------------------------------------------------

validate_skill() {
  local dir="${1%/}"
  local skill="$dir/SKILL.md"
  local expected fail=0
  expected="$(basename "$dir")"

  printf '\n%s== %s ==%s\n' "$c_dim" "$dir" "$c_rst"
  _err() { printf '  %s✗ %s%s\n' "$c_red" "$1" "$c_rst"; fail=1; }
  _ok()  { printf '  %s✓ %s%s\n' "$c_grn" "$1" "$c_rst"; }
  _warn(){ printf '  %s! %s%s\n' "$c_ylw" "$1" "$c_rst"; }

  if [ ! -f "$skill" ]; then
    _err "no SKILL.md found"
    total_fail=1
    return
  fi

  # 0. Official validator, if available.
  if command -v skills-ref >/dev/null 2>&1; then
    if skills-ref validate "$dir" >/tmp/skills-ref.out 2>&1; then
      _ok "skills-ref validate passed"
    else
      _err "skills-ref validate failed:"; sed 's/^/      /' /tmp/skills-ref.out
    fi
  else
    _warn "skills-ref not installed — skipping official validation (npm i -g @agentskills/skills-ref or see agentskills.io)"
  fi

  # 1. Frontmatter delimiters.
  if [ "$(head -1 "$skill")" != "---" ]; then
    _err "must start with '---' frontmatter"; total_fail=1; return
  fi
  local fm_end
  fm_end="$(awk 'NR>1 && /^---[[:space:]]*$/{print NR; exit}' "$skill")"
  if [ -z "$fm_end" ]; then
    _err "frontmatter not closed with '---'"; total_fail=1; return
  fi

  local fm body_lines name desc
  fm="$(sed -n "2,$((fm_end-1))p" "$skill")"
  body_lines="$(sed -n "$((fm_end+1)),\$p" "$skill" | wc -l | tr -d ' ')"
  name="$(field_value "$fm" name)"
  desc="$(field_value "$fm" description)"

  # 2. name
  if [ -z "$name" ]; then
    _err "missing required 'name' field"
  else
    local name_ok=1
    [ "$name" = "$expected" ] || { _err "name '$name' must match folder '$expected'"; name_ok=0; }
    [ "${#name}" -le "$MAX_NAME" ] || { _err "name is ${#name} chars (max $MAX_NAME)"; name_ok=0; }
    printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' \
      || { _err "name '$name' must be lowercase a-z/0-9/- with no leading, trailing, or consecutive hyphens"; name_ok=0; }
    if printf '%s' "$name" | grep -iqE 'anthropic|claude'; then
      _err "name '$name' contains a reserved word (anthropic/claude) — disallowed by claude.ai/API"; name_ok=0
    fi
    [ "$name_ok" -eq 1 ] && _ok "name ok ($name)"
  fi

  # 3. description
  if [ -z "$desc" ]; then
    _err "missing required 'description' field"
  else
    local desc_ok=1
    [ "${#desc}" -le "$MAX_DESC" ] || { _err "description is ${#desc} chars (max $MAX_DESC)"; desc_ok=0; }
    if printf '%s' "$desc" | grep -qE '<[^>]*>'; then
      _err "description contains angle-bracket / XML-tag content — disallowed; use [brackets] or quotes instead"; desc_ok=0
    fi
    [ "$desc_ok" -eq 1 ] && _ok "description ok (${#desc}/$MAX_DESC chars)"
  fi

  # 3b. recognized frontmatter keys (Claude Code rejects unknown keys -> skill hidden from / menu)
  local cc_keys=" name description when_to_use argument-hint arguments disable-model-invocation user-invocable allowed-tools disallowed-tools model effort context agent hooks paths shell "
  local bad_keys=""
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    case "$cc_keys" in *" $k "*) ;; *) bad_keys="$bad_keys $k" ;; esac
  done < <(printf '%s\n' "$fm" | sed -n 's/^\([A-Za-z][A-Za-z0-9_-]*\):.*$/\1/p')
  if [ -n "$bad_keys" ]; then
    _err "unrecognized frontmatter key(s):$bad_keys — Claude Code accepts only its documented keys and will hide the skill from the / menu (put 'license' in the repo LICENSE file, not frontmatter)"
  else
    _ok "frontmatter keys recognized"
  fi

  # 4. body length
  if [ "$body_lines" -ge "$MAX_BODY_LINES" ]; then
    _err "body is $body_lines lines (keep under $MAX_BODY_LINES; move detail to references/)"
  else
    _ok "body length ok ($body_lines lines)"
  fi

  # 5. secret scan (high-signal patterns, whole skill folder)
  local secret_re='-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{35}'
  local hits
  hits="$(grep -rEnI "$secret_re" "$dir" 2>/dev/null || true)"
  if [ -n "$hits" ]; then
    _err "possible secret(s) detected — do NOT commit:"; printf '%s\n' "$hits" | sed 's/^/      /'
  else
    _ok "no obvious secrets"
  fi

  [ "$fail" -eq 0 ] || total_fail=1
}

# --- arg handling ------------------------------------------------------------

if [ "$#" -eq 0 ]; then
  printf 'usage: %s <skill-folder> [...]   |   %s --all\n' "$(basename "$0")" "$(basename "$0")" >&2
  exit 2
fi

if [ "$1" = "--all" ]; then
  found=0
  for skill in "$repo_root"/*/SKILL.md; do
    [ -e "$skill" ] || continue
    dir="$(dirname "$skill")"
    [ "$(basename "$dir")" = "_template" ] && continue
    validate_skill "$dir"; found=1
  done
  [ "$found" -eq 1 ] || printf '\nNo skill folders found yet.\n'
else
  for dir in "$@"; do validate_skill "$dir"; done
fi

printf '\n'
if [ "$total_fail" -eq 0 ]; then
  printf '%sAll checks passed.%s\n' "$c_grn" "$c_rst"
  exit 0
else
  printf '%sValidation failed.%s\n' "$c_red" "$c_rst"
  exit 1
fi
