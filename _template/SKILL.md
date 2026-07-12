---
name: rename-to-match-folder
description: One sentence on what this does, then when to use it with natural trigger phrases a user would actually say. Lead with the key use case. Lean slightly pushy - skills under-trigger. Max 1024 characters.
model: sonnet
---

# <Skill title>

Brief statement of the single job this skill does. (One clear job — if it does two things, split it.)

## Instructions

State what to do, imperatively. The body stays in context across turns once
invoked, so every line is recurring token cost — say what to do, not why.

1. First step.
2. Second step.
3. Output format / what to return.

## Notes (optional)

- Edge cases, "if the input is empty, say X", etc.
- Move long reference material to `references/` and link it: see [reference.md](references/reference.md).
- Reference bundled scripts portably with `${CLAUDE_SKILL_DIR}/scripts/foo.py`.
