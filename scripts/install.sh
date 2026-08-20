#!/usr/bin/env bash
#
# install.sh — install skills and agent personas from this repo into your
# personal Claude config (~/.claude/) so Claude Code can load them.
#
# Two artifact types, because a persona is not a skill:
#   - skill  : a folder containing SKILL.md   -> ~/.claude/skills/<name>/
#   - agent  : a single file agents/<name>.md -> ~/.claude/agents/<name>.md
#
# Lints each artifact first and refuses to install one that fails validation, so
# a broken skill or persona never reaches your menu. Copies by default; pass
# --symlink to link instead (repo stays the single source of truth — edits apply
# with no re-copy).
#
# Usage:
#   scripts/install.sh <name> [<name> ...] [--symlink]   # skill or agent, by name
#   scripts/install.sh --all     [--symlink]             # every skill + every agent
#   scripts/install.sh --skills  [--symlink]             # skills only
#   scripts/install.sh --agents  [--symlink]             # agent personas only
#
# After installing, FULLY quit and relaunch Claude Code so the / menu picks up
# newly added skills (live-reload covers edits to already-loaded skills, but a
# brand-new skill needs a restart to appear in the menu).

set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest_skills="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
dest_agents="${CLAUDE_AGENTS_DIR:-$HOME/.claude/agents}"

usage() {
  echo "usage: $(basename "$0") <name> [...] [--symlink]" >&2
  echo "       $(basename "$0") --all | --skills | --agents [--symlink]" >&2
}

symlink=0
do_all=0
do_skills=0
do_agents=0
names=()
for a in "$@"; do
  case "$a" in
    --symlink) symlink=1 ;;
    --all)     do_all=1 ;;
    --skills)  do_skills=1 ;;
    --agents)  do_agents=1 ;;
    -*)        echo "unknown option: $a" >&2; usage; exit 2 ;;
    *)         names+=("${a%/}") ;;
  esac
done

skills=()
agents=()

collect_skills() {
  for d in "$repo_root"/*/SKILL.md; do
    [ -e "$d" ] || continue
    n="$(basename "$(dirname "$d")")"
    [ "$n" = "_template" ] && continue
    skills+=("$n")
  done
}

collect_agents() {
  for f in "$repo_root"/agents/*.md; do
    [ -e "$f" ] || continue
    n="$(basename "$f" .md)"
    [ "$n" = "README" ] && continue
    agents+=("$n")
  done
}

[ "$do_all" -eq 1 ] && { collect_skills; collect_agents; }
[ "$do_skills" -eq 1 ] && collect_skills
[ "$do_agents" -eq 1 ] && collect_agents

# Resolve each positional name to a skill folder or an agent file.
if [ "${#names[@]}" -gt 0 ]; then
  for n in "${names[@]}"; do
    if [ -f "$repo_root/$n/SKILL.md" ]; then
      skills+=("$n")
    elif [ -f "$repo_root/agents/$n.md" ]; then
      agents+=("$n")
    else
      echo "skip $n: no $n/SKILL.md and no agents/$n.md" >&2
    fi
  done
fi

if [ "${#skills[@]}" -eq 0 ] && [ "${#agents[@]}" -eq 0 ]; then
  usage
  exit 2
fi

# A persona has no SKILL.md, so validate.sh does not apply. Check the contract
# Claude Code actually requires: YAML frontmatter carrying a name that matches
# the filename (that name is the subagent_type callers dispatch on — a mismatch
# silently fails to resolve) and a non-empty description.
lint_agent() {
  local f="$1" n="$2" fm_name errs=0
  if ! head -1 "$f" | grep -q '^---$'; then
    echo "    missing YAML frontmatter (first line must be ---)"
    errs=1
  fi
  fm_name="$(sed -n '2,40{/^---$/q;s/^name:[[:space:]]*//p;}' "$f" | head -1)"
  if [ -z "$fm_name" ]; then
    echo "    frontmatter missing 'name:'"
    errs=1
  elif [ "$fm_name" != "$n" ]; then
    echo "    frontmatter name '$fm_name' does not match filename '$n'"
    errs=1
  fi
  if ! sed -n '2,40{/^---$/q;/^description:[[:space:]]*./p;}' "$f" | grep -q .; then
    echo "    frontmatter missing 'description:'"
    errs=1
  fi
  return $errs
}

installed=0
failed=0

if [ "${#skills[@]}" -gt 0 ]; then
  mkdir -p "$dest_skills"
  for s in "${skills[@]}"; do
    src="$repo_root/$s"
    if [ ! -f "$src/SKILL.md" ]; then echo "skip $s: no SKILL.md at $src" >&2; continue; fi
    echo "== skill $s =="
    if ! "$repo_root/scripts/validate.sh" "$src" >/tmp/install-lint.out 2>&1; then
      echo "  lint FAILED — not installing. Run: scripts/validate.sh $s" >&2
      sed 's/^/    /' /tmp/install-lint.out >&2
      failed=$((failed + 1))
      continue
    fi
    rm -rf "$dest_skills/$s"
    if [ "$symlink" -eq 1 ]; then
      ln -s "$src" "$dest_skills/$s"; echo "  symlinked -> $dest_skills/$s"
    else
      cp -r "$src" "$dest_skills/$s"; echo "  copied    -> $dest_skills/$s"
    fi
    installed=$((installed + 1))
  done
fi

if [ "${#agents[@]}" -gt 0 ]; then
  mkdir -p "$dest_agents"
  for a in "${agents[@]}"; do
    src="$repo_root/agents/$a.md"
    if [ ! -f "$src" ]; then echo "skip $a: no agents/$a.md" >&2; continue; fi
    echo "== agent $a =="
    if ! lint_agent "$src" "$a" >/tmp/install-lint.out 2>&1; then
      echo "  lint FAILED — not installing." >&2
      cat /tmp/install-lint.out >&2
      failed=$((failed + 1))
      continue
    fi
    rm -f "$dest_agents/$a.md"
    if [ "$symlink" -eq 1 ]; then
      ln -s "$src" "$dest_agents/$a.md"; echo "  symlinked -> $dest_agents/$a.md"
    else
      cp "$src" "$dest_agents/$a.md"; echo "  copied    -> $dest_agents/$a.md"
    fi
    installed=$((installed + 1))
  done
fi

echo
echo "installed $installed artifact(s)  (skills -> $dest_skills, agents -> $dest_agents)"
echo "Now FULLY quit and relaunch Claude Code so new skills/agents appear in the / menu."

if [ "$failed" -gt 0 ]; then
  echo "$failed artifact(s) failed lint and were NOT installed" >&2
  exit 1
fi
exit 0
