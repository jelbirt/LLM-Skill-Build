#!/usr/bin/env bash
#
# sync-profile-readme.sh — keep the project table in a GitHub profile README in
# step with the account's pinned repositories.
#
# Usage:
#   sync-profile-readme.sh [--readme PATH] [--user LOGIN] [--write]
#
#   --readme PATH   profile README (or the directory holding it). Default: the
#                   README.md of the current repo, which must be LOGIN/LOGIN.
#   --user LOGIN    GitHub account whose pins to read. Default: `gh api user`.
#   --write         apply the change. Without it, this is a dry run.
#
# Contract:
#   * Only the lines between the PROJECTS:START and PROJECTS:END markers are
#     touched. Everything outside them is copied through byte for byte.
#   * A row carrying the SYNCED marker was written by this script and is
#     regenerated from the repo's GitHub description on every run.
#   * A row WITHOUT that marker is hand-written and is never rewritten.
#   * No row is ever deleted. A repo that is no longer pinned keeps its row and
#     is reported, so removing it stays an explicit human edit.
#   * Newly pinned repos are appended after the last pinned row.
#
# Exit status: 0 success (see the RESULT line), 1 error.
# Requires bash 4+, gh, and diffutils.

set -uo pipefail

START_MARKER='<!-- PROJECTS:START -->'
END_MARKER='<!-- PROJECTS:END -->'
SYNCED_MARKER='<!-- synced -->'
DEFAULT_HEADER='| Project | What it is |'
DEFAULT_SEPARATOR='| :--- | :--- |'
MAX_PINS=6

readme=''
user=''
do_write=0
tmp=''
stage=''

die() { printf 'error: %s\n' "$1" >&2; [ $# -gt 1 ] && printf '  fix: %s\n' "$2" >&2; exit 1; }
note() { printf '%s\n' "$1"; }
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
usage() { awk 'NR>1 && /^#/ { sub(/^#[[:space:]]?/, ""); print; next } NR>1 { exit }' "$0"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --readme) readme="${2:-}"; shift 2 || die "--readme needs a path" ;;
    --user)   user="${2:-}";   shift 2 || die "--user needs a login" ;;
    --write)  do_write=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" "run with --help" ;;
  esac
done

# --- preflight ---------------------------------------------------------------

# Associative arrays are bash 4+; stock macOS ships 3.2, where a string
# subscript silently evaluates to index 0 and every lookup would "match".
[ "${BASH_VERSINFO[0]:-0}" -ge 4 ] \
  || die "this script needs bash 4 or newer (found ${BASH_VERSION:-unknown})" \
         "on macOS: 'brew install bash', then run this script with that bash"

command -v gh >/dev/null 2>&1 \
  || die "the GitHub CLI (gh) is not installed" "install it from https://cli.github.com and run 'gh auth login'"
command -v diff >/dev/null 2>&1 && command -v cmp >/dev/null 2>&1 \
  || die "diff and cmp are required, and one of them is missing" \
         "install diffutils (Debian/Ubuntu: 'sudo apt install diffutils')"
gh auth status >/dev/null 2>&1 \
  || die "gh is installed but not authenticated" "run 'gh auth login'"

if [ -z "$user" ]; then
  user="$(gh api user --jq .login 2>/dev/null)" \
    || die "could not read your GitHub login from gh" "run 'gh auth login', or pass --user LOGIN"
fi
printf '%s' "$user" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$' \
  || die "'$user' is not a valid GitHub login" "pass --user with the account name only, not a URL"
user_lc="$(lower "$user")"

# --- locate the README -------------------------------------------------------

if [ -n "$readme" ]; then
  [ -d "$readme" ] && readme="$readme/README.md"
  [ -f "$readme" ] || die "no README at $readme" "pass --readme with the path to the profile README.md"
else
  root="$(git rev-parse --show-toplevel 2>/dev/null)" \
    || die "not inside a git repository, so the profile repo cannot be identified" \
           "cd into your $user/$user clone, or pass --readme /path/to/README.md"
  origin="$(git remote get-url origin 2>/dev/null || true)"
  origin_repo="$(basename "${origin%.git}" 2>/dev/null || true)"
  # GitHub logins are case-preserving but URLs are not, so compare folded.
  if [ "$(lower "$origin_repo")" != "$user_lc" ] && [ "$(lower "$(basename "$root")")" != "$user_lc" ]; then
    die "this repo is not $user/$user (the profile repo)" \
        "cd into your $user/$user clone, or pass --readme /path/to/README.md"
  fi
  readme="$root/README.md"
  [ -f "$readme" ] || die "no README.md at the root of $root" \
    "create README.md in $user/$user, or pass --readme with its path"
fi

# --- find the managed region -------------------------------------------------

start_line="$(grep -nF -- "$START_MARKER" "$readme" | head -1 | cut -d: -f1)"
end_line="$(grep -nF -- "$END_MARKER" "$readme" | head -1 | cut -d: -f1)"

if [ -z "$start_line" ] || [ -z "$end_line" ]; then
  printf 'error: %s has no managed region\n' "$readme" >&2
  printf '  fix: add these two markers around the project table, then re-run:\n\n' >&2
  printf '    %s\n\n    %s\n\n' "$START_MARKER" "$END_MARKER" >&2
  printf '  Everything outside them is left alone.\n' >&2
  exit 1
fi
[ "$end_line" -gt "$start_line" ] || die "$END_MARKER appears before $START_MARKER in $readme" \
  "put the start marker above the end marker"

# Read line by line rather than through $(...), which would eat the region's
# trailing blank lines. The adjacent-markers case is skipped outright because
# `sed -n '4,3p'` prints one line, not none.
region_lines=()
if [ "$((end_line - start_line))" -gt 1 ]; then
  while IFS= read -r rl; do region_lines+=("$rl"); done \
    < <(sed -n "$((start_line + 1)),$((end_line - 1))p" "$readme")
fi

# Match the region's own line endings when emitting generated rows.
cr=''
sed -n "${start_line}p" "$readme" | grep -q $'\r' && cr=$'\r'

# --- read the pinned repositories (GraphQL — REST does not expose pins) ------

query="{user(login:\"$user\"){pinnedItems(first:$MAX_PINS,types:REPOSITORY){nodes{... on Repository{name description url isArchived}}}}}"
gh_err="$(mktemp)"
if ! pins="$(gh api graphql -f query="$query" \
             --jq '.data.user.pinnedItems.nodes[] | [.name, .url, (.isArchived|tostring), ((.description // "") | gsub("[\\t\\r\\n]"; " "))] | @tsv' \
             2>"$gh_err")"; then
  msg="$(tr '\n' ' ' < "$gh_err" | sed 's/  */ /g; s/^ *//; s/ *$//')"
  rm -f "$gh_err"
  die "the GitHub GraphQL query failed — ${msg:-unknown error}" \
      "confirm the account '$user' exists, then check network access and 'gh auth status'"
fi
rm -f "$gh_err"

[ -n "$pins" ] || die "$user has no pinned repositories" \
  "pin repositories on your GitHub profile page (Customize your pins), then re-run"

# Identity is owner/name, not the bare repo name: pins may belong to other
# accounts, and a same-named repo elsewhere must not be mistaken for yours.
url_slug() { printf '%s' "$1" | sed -E 's#.*[Gg][Ii][Tt][Hh][Uu][Bb]\.com/##; s#\.git$##; s#/$##'; }

declare -A pin_label=() pin_url=() pin_desc=() pin_archived=()
pin_order=()
while IFS=$'\t' read -r name url archived desc; do
  [ -n "$name" ] || continue
  slug="$(url_slug "$url")"
  key="$(lower "$slug")"
  # A pin you do not own is labelled owner/name so the row is unambiguous.
  case "$key" in "$user_lc"/*) pin_label["$key"]="$name" ;; *) pin_label["$key"]="$slug" ;; esac
  pin_url["$key"]="$url"; pin_archived["$key"]="$archived"
  # Tabs and newlines are folded to spaces in the jq above, so a literal
  # backslash is the only escape @tsv can still have doubled here.
  pin_desc["$key"]="$(printf '%s' "$desc" | sed 's/\\\\/\\/g')"
  pin_order+=("$key")
done <<< "$pins"

# --- parse the existing table ------------------------------------------------

row_line=(); row_key=(); row_label=(); row_synced=()
lead=''; trail=''; header=''; separator=''
seen_table=0; done_table=0
warns=''

is_separator() { printf '%s' "$1" | grep -Eq '^\|[[:space:]:|-]+\|[[:space:]]*$'; }

# Row identity comes from the repo URL, not the link text: a hand-written row
# may label AudioFY-Data as "AudioFY" and still be that repo's row.
row_slug() {
  printf '%s' "$1" \
    | grep -oiE 'https?://(www\.)?github\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+' \
    | head -1 | { local u=''; read -r u || true; url_slug "$u"; }
}

# Own repos read as "name"; someone else's read as "owner/name".
short_label() {
  case "$(lower "$1")" in
    '')            printf '' ;;
    "$user_lc"/*)  printf '%s' "${1#*/}" ;;
    *)             printf '%s' "$1" ;;
  esac
}

for line in ${region_lines[@]+"${region_lines[@]}"}; do
  if [ "${line:0:1}" = "|" ]; then
    [ "$done_table" -eq 1 ] && die "the managed region in $readme has content after the table" \
      "keep one table between the markers; move prose outside them"
    if [ "$seen_table" -eq 0 ]; then seen_table=1; header="$line"; continue; fi
    if [ -z "$separator" ] && is_separator "$line"; then separator="$line"; continue; fi
    slug="$(row_slug "$line")"
    row_line+=("$line")
    row_label+=("$(short_label "$slug")")
    row_key+=("$(lower "$slug")")
    if printf '%s' "$line" | grep -qiE '<!--[[:space:]]*synced[[:space:]]*-->'; then
      row_synced+=(1)
    else
      row_synced+=(0)
    fi
    [ -n "$slug" ] || warns="$warns  warn    row $((${#row_line[@]})) has no github.com link — it is kept as-is, but cannot be matched to a pin"$'\n'
  elif [ -z "${line//[[:space:]]/}" ]; then
    if [ "$seen_table" -eq 0 ]; then lead="$lead$line"$'\n'; else done_table=1; trail="$trail$line"$'\n'; fi
  else
    die "the managed region in $readme contains prose, not just a table" \
        "move that text outside the markers — this only manages a table"
  fi
done

if [ "$seen_table" -eq 0 ]; then
  header="$DEFAULT_HEADER$cr"; separator="$DEFAULT_SEPARATOR$cr"
elif [ -z "$separator" ]; then
  die "the table in the managed region has no header separator row" \
      "add a row like '$DEFAULT_SEPARATOR' under the header"
fi

# --- build the new table -----------------------------------------------------

# A generated row: link text is the repo (owner/name when someone else owns it),
# cell text is its GitHub description. Table cells are single-line, pipe-delimited.
render_row() {
  local key="$1" cell
  cell="$(printf '%s' "${pin_desc[$key]}" | tr '\t\r\n' '   ' | sed 's/|/\\|/g; s/  */ /g; s/^ //; s/ $//')"
  [ -n "$cell" ] || cell='—'
  printf '| [%s](%s) | %s %s |%s' "${pin_label[$key]}" "${pin_url[$key]}" "$cell" "$SYNCED_MARKER" "$cr"
}

# Look up a possibly-empty key without tripping "bad array subscript".
pinned_label() { [ -n "$1" ] && printf '%s' "${pin_label[$1]:-}"; }

plan=''
declare -A in_table=()

last_pinned=-1
for i in "${!row_line[@]}"; do
  [ -n "$(pinned_label "${row_key[$i]}")" ] && last_pinned="$i"
done

new_rows=()
for key in "${pin_order[@]}"; do
  found=0
  for rk in ${row_key[@]+"${row_key[@]}"}; do [ "$rk" = "$key" ] && { found=1; break; }; done
  [ "$found" -eq 1 ] && continue
  new_rows+=("$(render_row "$key")")
  plan="$plan  add     ${pin_label[$key]} (newly pinned)"$'\n'
  [ -n "${pin_desc[$key]}" ] || warns="$warns  warn    ${pin_label[$key]} has no GitHub description — write one in the repo's About field, or hand-write the row"$'\n'
done

out=()
for i in "${!row_line[@]}"; do
  line="${row_line[$i]}"; key="${row_key[$i]}"
  pinned="$(pinned_label "$key")"
  label="$pinned"; [ -n "$label" ] || label="${row_label[$i]}"
  [ -n "$label" ] || label="(row $((i + 1)), no repo link)"

  if [ -n "$key" ] && [ -n "${in_table[$key]:-}" ]; then
    warns="$warns  warn    two rows point at $label — both are kept; delete one by hand"$'\n'
  fi
  [ -n "$key" ] && in_table["$key"]=1

  if [ -n "$pinned" ]; then
    if [ "${row_synced[$i]}" -eq 1 ]; then
      rendered="$(render_row "$key")"
      out+=("$rendered")
      if [ "$rendered" = "$line" ]; then
        plan="$plan  same    $label"$'\n'
      else
        plan="$plan  sync    $label (refreshed from its GitHub description)"$'\n'
      fi
      [ -n "${pin_desc[$key]}" ] || warns="$warns  warn    $label has no GitHub description — write one in the repo's About field, or hand-write the row"$'\n'
    else
      out+=("$line")
      plan="$plan  keep    $label (hand-written)"$'\n'
    fi
    [ "${pin_archived[$key]}" = "true" ] && warns="$warns  warn    $label is archived on GitHub — consider unpinning it"$'\n'
  else
    out+=("$line")
    if [ "${row_synced[$i]}" -eq 1 ]; then
      plan="$plan  keep    $label (in table, not pinned — keeping it; was auto-synced)"$'\n'
    else
      plan="$plan  keep    $label (in table, not pinned — keeping it)"$'\n'
    fi
  fi

  if [ "$i" -eq "$last_pinned" ] && [ "${#new_rows[@]}" -gt 0 ]; then
    out+=("${new_rows[@]}")
  fi
done

if [ "$last_pinned" -lt 0 ] && [ "${#new_rows[@]}" -gt 0 ]; then
  out+=("${new_rows[@]}")
fi

# --- assemble, diff, and (optionally) write ----------------------------------

trap 'rm -f ${tmp:+"$tmp"} ${stage:+"$stage"}' EXIT
tmp="$(mktemp)" || die "could not create a temp file" "check that TMPDIR is writable"
{
  head -n "$start_line" "$readme"
  printf '%s' "$lead"
  printf '%s\n%s\n' "$header" "$separator"
  [ "${#out[@]}" -gt 0 ] && printf '%s\n' "${out[@]}"
  printf '%s' "$trail"
  tail -n "+$end_line" "$readme"
} > "$tmp"

note "README:  $readme"
note "Account: $user (${#pin_order[@]} pinned, ${#row_line[@]} rows in the table)"
note ""
note "Plan:"
printf '%s' "$plan"
[ -n "$warns" ] && { note ""; printf '%s' "$warns"; }

if cmp -s "$tmp" "$readme"; then
  note ""
  note "RESULT: no-changes"
  exit 0
fi

note ""
note "Diff:"
diff -u --label "a/${readme##*/}" --label "b/${readme##*/}" "$readme" "$tmp"

if [ "$do_write" -eq 1 ]; then
  # Stage beside the target and rename, so a failed write cannot leave a
  # truncated profile README behind.
  dir="$(dirname "$readme")"
  stage="$(mktemp "$dir/.$(basename "$readme").XXXXXX")" \
    || die "could not create a temp file in $dir" "check that the directory is writable"
  cat "$tmp" > "$stage" || die "could not stage the new README in $dir" "check free space and permissions"
  perms="$(stat -c '%a' "$readme" 2>/dev/null || stat -f '%Lp' "$readme" 2>/dev/null || echo 644)"
  chmod "$perms" "$stage" 2>/dev/null
  mv -f "$stage" "$readme" || die "could not replace $readme" "check file permissions"
  stage=''
  note ""
  note "RESULT: written"
else
  note ""
  note "RESULT: changes-pending (nothing written; re-run with --write to apply)"
fi
