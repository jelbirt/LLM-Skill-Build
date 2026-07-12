# Authoring conventions

How skills in this repo are written. Kept short on purpose.

## Layout

- One skill per folder. Folder name is **kebab-case** and becomes the `/command` name.
- Only `SKILL.md` is required. Optional: `scripts/`, `references/`, `assets/`.
- Start from [`_template/SKILL.md`](_template/SKILL.md) (or run `/new-skill`).

## Frontmatter

Required (portable Agent Skills standard):

- `name` — **must match the folder name**. Max 64 chars, lowercase letters / numbers / hyphens, no leading/trailing/consecutive hyphens. Must **not** contain the reserved words `anthropic` or `claude`, or XML tags (a claude.ai/API rule).
- `description` — **max 1024 chars**, non-empty. What it does + when to use it. Must **not** contain XML tags (angle-bracket content) — use `[brackets]` or quotes for placeholders. Avoid a literal `: ` (colon-space) in an unquoted value; it can break YAML parsing.

Do **not** put `license` in frontmatter (or other portable-only keys like `metadata` / `compatibility`). Claude Code accepts only its own documented keys and will **silently hide the skill from the `/` menu** if it sees an unrecognized key. The repo's license lives in the top-level [`LICENSE`](LICENSE) file instead.

Claude Code's accepted optional keys: `when_to_use`, `argument-hint`, `arguments`, `allowed-tools`, `disallowed-tools`, `disable-model-invocation`, `user-invocable`, `model`, `effort`, `context`, `agent`, `hooks`, `paths`, `shell`. The linter flags any key outside this set.

**Model pin:** default new skills to `model: sonnet` to cut invocation cost, unless the skill's core job is correctness-critical reasoning (e.g. exact logic/text comparison) where inheriting the session's model is safer than forcing a cheaper tier - decide per skill, don't apply blindly.

**Tags in the body (hygiene, not a hard rule):** raw `<angle>` / XML-style tags are forbidden only in `name`/`description`. In the body they're allowed — conventional git notation like `git switch <branch>` is fine — but since the body is injected into an LLM context, prefer `{braces}` or backticks for placeholders where practical. The linter *warns* on body tags rather than failing.

## Quality checklist

Before committing a skill, confirm:

- [ ] **One clear job.** If it does two things, split it.
- [ ] **`name` matches the folder name** and contains no reserved words (`anthropic`/`claude`) or XML tags.
- [ ] **Description leads with the key use case** and contains natural trigger phrases a user would actually type. Lean slightly *pushy* — skills under-trigger.
- [ ] **Description ≤ 1024 characters.**
- [ ] **Body < 500 lines** (ideally < ~5000 tokens). Long reference material lives in `references/` and is linked, not inlined.
- [ ] **No secrets / keys / tokens.** This is public git — treat `SKILL.md` like source code.
- [ ] **Dogfooded.** Used in real work at least once before publish.
- [ ] **Validated.** `scripts/validate.sh <skill-folder>` passes.

## Good vs. weak descriptions

```
# Weak — won't trigger
description: Helps with PRs.

# Good — what + when + trigger words
description: Summarizes a pull request from its diff and comments. Use when
  the user asks to review a PR, wants a PR summary, or asks what a PR changes.
```

## Two char limits — don't confuse them

- **1024** — hard cap on the `description` field (portable standard). The lint enforces this.
- **1536** — Claude Code's truncation of the *combined* `description` + `when_to_use` in the skill listing display. Configurable; not a field cap.
