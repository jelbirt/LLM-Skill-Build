---
name: new-skill
description: Scaffold a new Agent Skill - interview for intent, then create the folder and a conventions-following SKILL.md with valid, pre-filled frontmatter, and lint it. Use whenever the user wants to create, start, scaffold, or bootstrap a skill, says "new skill", "make a skill for it", "turn this into a skill", or is about to hand-write a SKILL.md. Prefer this over writing a SKILL.md from scratch so the name, description, and layout follow conventions. For heavy eval or benchmark-driven iteration, hand off to skill-creator instead.
model: sonnet
argument-hint: [skill-name]
---

# new-skill

Scaffold one new skill, fast and correctly. The goal is a valid, dogfood-ready
skill folder on disk in a single interaction - not a full eval loop. If the user
wants rigorous, benchmark-driven iteration, point them at the skill-creator skill.

The skill name may be passed as an argument (`$ARGUMENTS`). If absent, ask for it.

## 1. Capture intent

Ask only what you cannot infer from the conversation (if the user just said "turn
this into a skill", mine the history first). Keep it to a short interview:

1. One job - what should this skill enable, in one sentence? If it is two jobs, split into two skills.
2. Triggers - what would a user actually say or be doing when this should fire? Collect real phrasings.
3. Output - what should the skill produce or do (format, steps, side effects)?
4. Support files - does it need a `scripts/` helper, `references/` docs, or `assets/`? Usually no.

## 2. Settle the name

The folder name equals the `name` field equals the slash command. It must be:

- kebab-case: lowercase a-z, 0-9, hyphens; no leading, trailing, or consecutive hyphens; 64 chars max
- free of the reserved words `anthropic` and `claude`
- distinct from existing skills (check siblings and installed skills)

Confirm the name with the user before writing anything.

## 3. Locate the repo root

The new skill should land beside the others, where the helper scripts live. This
skill is usually installed in `~/.claude/skills/` but run from inside the repo, so
find the repo from the working directory - NOT from this skill's own location:

- Search the current working directory and its ancestors for the nearest directory containing `CONVENTIONS.md`, `_template/`, and `scripts/validate.sh`. That is `REPO_ROOT`. New skills go as siblings: `REPO_ROOT/NAME/`.
- If none is found, treat it as standalone use: create `./NAME/` in the current directory (or ask where the skill should live) and use the manual checklist in step 5 instead of the repo scripts.

## 4. Write the SKILL.md

Create `TARGET/NAME/SKILL.md`. Prefer copying `REPO_ROOT/_template/SKILL.md` and
filling it in. If the template is not reachable (standalone use), write this skeleton
(replace each brace placeholder; keep it plain markdown, no angle-bracket tags):

```markdown
---
name: {folder-name}
description: {what it does}. Use when {natural trigger phrases the user would say}.
---

# {Title}

{One line: the single job.}

## Instructions

{Imperative steps. State what to do, not why - the body stays in context across
turns once invoked, so every line is recurring cost.}

1. ...
2. ...
3. {output or what to return}
```

Crafting the description (this is the trigger and the most important field):

- Lead with the key use case, then what it does, then when - woven with the real trigger phrases from step 1.
- Lean slightly pushy - skills under-trigger. e.g. append "Use this whenever the user mentions X, Y, or Z, even if they don't explicitly ask for it."
- Keep it 1024 characters max (hard cap in the portable standard).
- Use no angle-bracket or XML-tag content in the name or description - it is disallowed by claude.ai and the API. Use square brackets or quotes for placeholders.
- Avoid a literal `: ` (colon then space) in an unquoted description - it can break YAML parsing. Rephrase, or quote the whole value.
- Put "when to use" only in the description.

Frontmatter keys (this is what most often breaks loading): include ONLY keys
Claude Code recognizes - `name`, `description`, and optionally `argument-hint`,
`when_to_use`, `arguments`, `allowed-tools`, `disallowed-tools`,
`disable-model-invocation`, `user-invocable`, `model`, `effort`, `context`,
`agent`, `hooks`, `paths`, `shell`. Do NOT add `license`, `metadata`, or
`compatibility`: Claude Code silently hides a skill from the / menu if it sees an
unrecognized key. The repo's license lives in the top-level LICENSE file, not in
frontmatter.

Crafting the body: imperative, concise, under 500 lines. Briefly explain why a
step matters rather than stacking rigid all-caps rules - the model follows
reasoning better than rules. Move anything long into `references/` and link it.

If support files are needed, create the `scripts/`, `references/`, or `assets/`
dirs and reference them from SKILL.md using the `${CLAUDE_SKILL_DIR}` path prefix
so paths resolve wherever the skill is installed.

## 5. Lint it

After the SKILL.md is written, run the repo linter with the Bash tool. Do NOT use a
shell-injection block for this - injection runs when this skill loads, before the
new skill exists, so it would lint nothing. If `REPO_ROOT` was found in step 3, run:

```bash
bash REPO_ROOT/scripts/validate.sh NAME
```

If the validator is not reachable (standalone use), verify by hand against this checklist:

- name matches the folder; valid kebab-case; 64 chars max; no reserved words
- frontmatter has only Claude Code-recognized keys (no `license`, `metadata`, `compatibility`)
- description non-empty, 1024 chars max, leads with use case plus trigger phrases, no XML tags, no unquoted `: `
- body under 500 lines
- no secrets or keys committed
- one clear job

Fix anything that fails and re-check.

## 6. Install and verify it loads

Passing the linter proves the file is well-formed; it does NOT prove Claude Code
will surface it. Close that loop:

- If `REPO_ROOT/scripts/install.sh` exists, install with it (it re-lints, then copies). Add `--symlink` to keep the repo as the single source of truth:

```bash
bash REPO_ROOT/scripts/install.sh NAME
```

  Otherwise copy the folder into the personal skills dir: `cp -r NAME ~/.claude/skills/NAME`.
- Tell the user to FULLY quit and relaunch Claude Code. A brand-new skill appears in the / menu only after a restart; edits to an already-loaded skill hot-reload without one.
- Have them confirm it shows: type `/NAME`, or run `/doctor` to list discovered skills. If it does not appear, the usual cause is an unrecognized frontmatter key - re-check step 4.

## 7. Wrap up

- If an `IDEAS.md` exists at the repo root, offer to update this skill's row (set its status to building, or add a new row if it was not listed).
- If a `README.md` with a skills table exists at the repo root, offer to add a row for the new skill (name, one-line description, install command).
- Remind the user to dogfood it in real work before publishing - that is the cheapest test.
- For sharing, others install it the same way: copy the folder into `~/.claude/skills/` (or use `scripts/install.sh`), then restart.
- If they want trigger-accuracy tuning or benchmark-grade evals, hand off to the skill-creator skill - this skill intentionally stops at a solid, linted draft.
