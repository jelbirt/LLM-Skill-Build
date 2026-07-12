---
name: release-notes
description: Generate release notes from git history since the last tag, grouped into features, fixes, breaking changes, and improvements using conventional-commit prefixes. Use when the user wants release notes, a changelog, or a summary of what shipped since the last release - works directly from raw commit history, so it fits direct-to-main workflows or repos that don't rely on GitHub's PR-label-based release notes generator.
model: sonnet
allowed-tools: Bash(git log:*), Bash(git describe:*), Bash(git tag:*), Bash(git diff:*)
---

## Context

- Last tag: !`git describe --tags --abbrev=0 2>/dev/null || echo "No tags found"`
- Commits since last tag: !`git log $(git describe --tags --abbrev=0 2>/dev/null || echo HEAD~20)..HEAD --oneline`
- Changed files: !`git diff --stat $(git describe --tags --abbrev=0 2>/dev/null || echo HEAD~20)..HEAD`

## Task

Generate release notes from the commits above. Follow these steps:

1. Group commits by type using conventional commit prefixes or inferred categories:
   - **Features** — New functionality
   - **Fixes** — Bug fixes
   - **Breaking Changes** — Anything that breaks backwards compatibility (highlight prominently)
   - **Improvements** — Refactoring, performance, DX improvements
   - **Documentation** — Doc changes
   - **Other** — Everything else
2. Write user-friendly descriptions (not raw commit messages)
3. Omit empty categories
4. Format as markdown with this structure:

```markdown
# Release Notes — [version or date]

## Breaking Changes
- Description of breaking change

## Features
- Description of feature

## Fixes
- Description of fix

## Improvements
- Description of improvement
```

Output only the formatted release notes.
