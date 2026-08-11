#!/usr/bin/env bash
#
# install-agent-skills.sh — reproducible install of the addyosmani/agent-skills
# development pipeline into ~/.claude, with this repo's port modifications.
#
# Upstream:  https://github.com/addyosmani/agent-skills  (MIT)
# Pinned at: 70b7506ce90e200cb47645ddb3f6b8e84fecc047  (vendored 2026-07-07)
#
# Installs (22 files):
#   - 11 skills  -> ~/.claude/skills/     (Define: interview-me, idea-refine,
#     spec-driven-development · Plan: planning-and-task-breakdown · Build:
#     incremental-implementation, doubt-driven-development · Verify:
#     browser-testing-with-devtools · Review: security-and-hardening,
#     performance-optimization, code-simplification · Ship: shipping-and-launch)
#
#     test-driven-development, debugging-and-error-recovery, and
#     code-review-and-quality are deliberately NOT installed (removed
#     2026-08-10): A/B bake-offs against the bare model showed identical
#     outcomes on ground-truth fixtures — current models do these natively —
#     while security-and-hardening measurably earned its keep in the same
#     trial. Mod 5 rewrites the remaining upstream references to them.
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
#   5. Rewrite references to the three removed skills (see above) in the
#      commands, the two skills that cite them, and the shared reference
#      checklists, so nothing points at a skill that is no longer installed.
#
# NOTE: re-running OVERWRITES the 22 installed files. Never hand-edit the
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
  incremental-implementation doubt-driven-development
  browser-testing-with-devtools
  security-and-hardening
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

# Mod 5: rewrite references to the three removed skills (test-driven-development,
# debugging-and-error-recovery, code-review-and-quality) so nothing installed
# points at a skill that no longer exists. The command bodies are already
# self-contained workflows; these edits drop the invocation pointers and inline
# the one piece of guidance that would otherwise be lost.
sed -i '/^Invoke the test-driven-development skill\.$/{N;d;}' "$src/.claude/commands/test.md"
sed -i 's|Invoke the incremental-implementation skill alongside test-driven-development\.|Invoke the incremental-implementation skill.|' "$src/.claude/commands/build.md"
sed -i "s|a test can't be made to pass or the build breaks without an obvious fix → follow debugging-and-error-recovery|a test can't be made to pass or the build breaks without an obvious fix → stop and debug to the root cause; never patch symptoms to keep moving|" "$src/.claude/commands/build.md"
sed -i 's|If any step fails, follow the debugging-and-error-recovery skill\.|If any step fails, stop and debug to the root cause before continuing — reproduce the failure, isolate the cause, fix, and re-verify.|' "$src/.claude/commands/build.md"
sed -i '/^Invoke the code-review-and-quality skill\.$/{N;d;}' "$src/.claude/commands/review-gate.md"
sed -i 's|Use `code-review-and-quality` to review the result\.|Review the result with the code-reviewer agent.|' "$src/.claude/commands/code-simplify.md"
sed -i 's|- \*\*`code-review-and-quality` / `/review`\*\*: complementary\.|- **`/review-gate` / `/review`**: complementary.|' "$src/skills/doubt-driven-development/SKILL.md"
sed -i "s|- \*\*\`test-driven-development\`\*\*: TDD's RED step|- **TDD (\`/test\`)**: TDD's RED step|" "$src/skills/doubt-driven-development/SKILL.md"
sed -i 's|- \*\*`debugging-and-error-recovery`\*\*: when the reviewer surfaces a real failure mode, drop into the debugging skill to localize and fix\.|- **Debugging**: when the reviewer surfaces a real failure mode, reproduce it, localize the root cause, and fix before proceeding.|' "$src/skills/doubt-driven-development/SKILL.md"
sed -i 's|following `skills/incremental-implementation/SKILL.md` (`incremental-implementation`) and `skills/test-driven-development/SKILL.md` (`test-driven-development`)\.|following `skills/incremental-implementation/SKILL.md` (`incremental-implementation`), writing tests ahead of implementation (`/test`).|' "$src/skills/spec-driven-development/SKILL.md"
sed -i 's|The depth behind these items lives in `code-review-and-quality` (the five-axis review) and|The depth behind these items lives in the five-axis review (`/review-gate`) and|' "$src/references/definition-of-done.md"
sed -i 's|/review → code-reviewer (with code-review-and-quality skill) → report|/review → code-reviewer agent → report|' "$src/references/orchestration-patterns.md"
sed -i 's|Use alongside the `test-driven-development` skill\.|Use when writing tests ahead of implementation.|' "$src/references/testing-patterns.md"

# Guard: Mod 5's seds exit 0 even when nothing matches, so upstream drift
# (--latest, or a future pin bump) could silently reintroduce dangling
# references. Fail hard instead.
dangling="$(grep -rlE 'test-driven-development|debugging-and-error-recovery|code-review-and-quality' \
  "$src/.claude/commands" "$src/references" "${SKILLS[@]/#/$src/skills/}" || true)"
if [ -n "$dangling" ]; then
  echo "ERROR: dangling references to removed skills survived Mod 5 (upstream drift?):" >&2
  echo "$dangling" >&2
  exit 1
fi

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
