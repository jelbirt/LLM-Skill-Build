#!/usr/bin/env bash
#
# install.sh — install skills from this repo into your personal skills dir
# (~/.claude/skills/) so Claude Code can load them.
#
# Lints each skill first and refuses to install one that fails validation, so a
# broken skill never reaches your menu. Copies by default; pass --symlink to link
# instead (repo stays the single source of truth — edits apply with no re-copy).
#
# Usage:
#   scripts/install.sh <skill> [<skill> ...] [--symlink]
#   scripts/install.sh --all [--symlink]
#
# After installing, FULLY quit and relaunch Claude Code so the / menu picks up
# newly added skills (live-reload covers edits to already-loaded skills, but a
# brand-new skill needs a restart to appear in the menu).

set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

symlink=0
do_all=0
skills=()
for a in "$@"; do
  case "$a" in
    --symlink) symlink=1 ;;
    --all)     do_all=1 ;;
    -*)        echo "unknown option: $a" >&2; exit 2 ;;
    *)         skills+=("${a%/}") ;;
  esac
done

if [ "$do_all" -eq 1 ]; then
  skills=()
  for d in "$repo_root"/*/SKILL.md; do
    [ -e "$d" ] || continue
    n="$(basename "$(dirname "$d")")"
    [ "$n" = "_template" ] && continue
    skills+=("$n")
  done
fi

if [ "${#skills[@]}" -eq 0 ]; then
  echo "usage: $(basename "$0") <skill> [...] [--symlink]   |   $(basename "$0") --all [--symlink]" >&2
  exit 2
fi

mkdir -p "$dest"
installed=0
for s in "${skills[@]}"; do
  src="$repo_root/$s"
  if [ ! -f "$src/SKILL.md" ]; then echo "skip $s: no SKILL.md at $src" >&2; continue; fi
  echo "== $s =="
  if ! "$repo_root/scripts/validate.sh" "$src" >/tmp/install-lint.out 2>&1; then
    echo "  lint FAILED — not installing. Run: scripts/validate.sh $s" >&2
    sed 's/^/    /' /tmp/install-lint.out >&2
    continue
  fi
  rm -rf "$dest/$s"
  if [ "$symlink" -eq 1 ]; then
    ln -s "$src" "$dest/$s"; echo "  symlinked -> $dest/$s"
  else
    cp -r "$src" "$dest/$s"; echo "  copied   -> $dest/$s"
  fi
  installed=$((installed + 1))
done

echo
echo "installed $installed skill(s) into $dest"
echo "Now FULLY quit and relaunch Claude Code so new skills appear in the / menu."
