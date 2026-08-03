#!/usr/bin/env bash
#
# install-agent-skills.sh — reproducible install of the addyosmani/agent-skills
# development pipeline into ~/.claude, with this repo's port modifications.
#
# Upstream:  https://github.com/addyosmani/agent-skills  (MIT)
# Pinned at: 70b7506ce90e200cb47645ddb3f6b8e84fecc047  (vendored 2026-07-07)
#
# Installs (25 files):
#   - 14 skills  -> ~/.claude/skills/     (Define: interview-me, idea-refine,
#     spec-driven-development · Plan: planning-and-task-breakdown · Build:
#     incremental-implementation, test-driven-development,
#     debugging-and-error-recovery, doubt-driven-development · Verify:
#     browser-testing-with-devtools · Review: code-review-and-quality,
#     security-and-hardening, performance-optimization, code-simplification ·
#     Ship: shipping-and-launch)
#   - 8 commands -> ~/.claude/commands/   (/spec /plan /build /test
#     /review-gate /code-simplify /webperf /ship)
#   - 3 personas -> ~/.claude/agents/     (security-auditor, test-engineer,
#     web-performance-auditor). code-reviewer is deliberately NOT installed —
#     the user-level ~/.claude/agents/code-reviewer.md takes precedence by
#     upstream's own design (see ship.md "Persona resolution").
#
# Port modifications applied to the upstream files before install:
#   1. Strip the `agent-skills:` plugin-namespace prefix from command files so
#      skill references resolve as plain ~/.claude/skills folders.
#   2. Add `model: sonnet` to 3 mechanical skills (code-simplification,
#      browser-testing-with-devtools, performance-optimization) and 1 persona
#      (web-performance-auditor) — each works from a known rubric of
#      anti-patterns rather than judging semantics from scratch, and each is
#      scoped to a single diff with a mandated verify step. Everything else
#      inherits the session model: spec/plan/build/review quality compounds
#      downstream, and review is the last line of defense under the
#      one-pass-per-diff policy, so a missed defect is not caught anywhere else.
#   3. Rename command review.md -> review-gate.md (Claude Code's built-in
#      /review shadows a user command of the same name).
#   4. Bundle upstream's shared references/*.md checklists into each installed
#      skill folder that cites them, so `references/...` mentions resolve
#      relative to the skill directory.
#
# NOTE: re-running OVERWRITES the 25 installed files. Never hand-edit the
# installed copies — to customize an imported skill, graduate it into this
# repo as your own folder, remove it from the lists below, and install it
# with scripts/install.sh instead.
#
# Usage:
#   scripts/install-agent-skills.sh            # install at the pinned SHA
#   scripts/install-agent-skills.sh --latest   # use upstream HEAD; prints the
#                                              # new SHA so you can review and
#                                              # update the pin above
#
# CLAUDE_DIR overrides the install root (default ~/.claude) — used for testing.

set -euo pipefail

UPSTREAM="https://github.com/addyosmani/agent-skills.git"
PIN="70b7506ce90e200cb47645ddb3f6b8e84fecc047"

SKILLS=(
  interview-me idea-refine spec-driven-development
  planning-and-task-breakdown
  incremental-implementation test-driven-development
  debugging-and-error-recovery doubt-driven-development
  browser-testing-with-devtools
  code-review-and-quality security-and-hardening
  performance-optimization code-simplification
  shipping-and-launch
)
SONNET_SKILLS=(code-simplification browser-testing-with-devtools performance-optimization)
AGENTS=(security-auditor test-engineer web-performance-auditor)
SONNET_AGENTS=(web-performance-auditor)

claude_dir="${CLAUDE_DIR:-$HOME/.claude}"
latest=0
[ "${1:-}" = "--latest" ] && latest=1

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Cloning $UPSTREAM ..."
git clone --quiet "$UPSTREAM" "$tmp/upstream"
if [ "$latest" -eq 1 ]; then
  sha="$(git -C "$tmp/upstream" rev-parse HEAD)"
  echo "Using upstream HEAD: $sha"
  [ "$sha" != "$PIN" ] && echo "  (differs from pin $PIN — review the diff, then update PIN in this script)"
else
  git -C "$tmp/upstream" checkout --quiet --detach "$PIN"
  echo "Checked out pinned SHA: $PIN"
fi
src="$tmp/upstream"

# Mod 1: strip plugin namespace in command files.
sed -i 's/agent-skills://g' "$src"/.claude/commands/*.md

# Mod 2: pin cheap-model candidates to Sonnet (insert before closing '---').
pin_sonnet() {
  awk 'NR>1 && /^---[[:space:]]*$/ && !done {print "model: sonnet"; done=1} {print}' \
    "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}
for s in "${SONNET_SKILLS[@]}"; do pin_sonnet "$src/skills/$s/SKILL.md"; done
for a in "${SONNET_AGENTS[@]}"; do pin_sonnet "$src/agents/$a.md"; done

# Mod 3: /review is shadowed by Claude Code's built-in — install as /review-gate.
mv "$src/.claude/commands/review.md" "$src/.claude/commands/review-gate.md"

# Install.
mkdir -p "$claude_dir/skills" "$claude_dir/commands" "$claude_dir/agents"
for s in "${SKILLS[@]}"; do
  rm -rf "$claude_dir/skills/$s"
  cp -r "$src/skills/$s" "$claude_dir/skills/$s"
  # Mod 4: bundle shared reference checklists where cited.
  if grep -q 'references/' "$claude_dir/skills/$s/SKILL.md"; then
    mkdir -p "$claude_dir/skills/$s/references"
    cp "$src"/references/*.md "$claude_dir/skills/$s/references/"
  fi
  echo "  skill   $s"
done
for f in "$src"/.claude/commands/*.md; do
  cp "$f" "$claude_dir/commands/$(basename "$f")"
  echo "  command /$(basename "$f" .md)"
done
for a in "${AGENTS[@]}"; do
  cp "$src/agents/$a.md" "$claude_dir/agents/$a.md"
  echo "  agent   $a"
done

echo
echo "Installed ${#SKILLS[@]} skills, 8 commands, ${#AGENTS[@]} agents into $claude_dir"
echo "FULLY quit and relaunch Claude Code so new skills/commands appear in the / menu."
