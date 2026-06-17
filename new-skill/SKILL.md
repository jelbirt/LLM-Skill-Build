---
name: new-skill
description: Scaffold a new Agent Skill — interview for intent, then create the folder and a conventions-following SKILL.md with valid, pre-filled frontmatter, and lint it. Use whenever the user wants to create, start, scaffold, or bootstrap a skill, says "new skill", "make a skill for…", "turn this into a skill", or is about to hand-write a SKILL.md. Prefer this over writing a SKILL.md from scratch so the name, description, and layout follow conventions. For heavy eval/benchmark-driven iteration, hand off to skill-creator instead.
license: Apache-2.0
argument-hint: [skill-name]
---

# new-skill

Scaffold one new skill, fast and correctly. The goal is a valid, dogfood-ready
skill folder on disk in a single interaction — not a full eval loop. If the user
wants rigorous, benchmark-driven iteration, point them at the `skill-creator` skill.

The skill name may be passed as an argument (`$ARGUMENTS`). If absent, ask for it.

## 1. Capture intent

Ask only what you can't infer from the conversation (if the user just said "turn
this into a skill", mine the history first). Keep it to a short interview:

1. **One job** — what should this skill enable, in one sentence? If it's two jobs, split into two skills.
2. **Triggers** — what would a user actually *say or be doing* when this should fire? Collect real phrasings.
3. **Output** — what should the skill produce or do (format, steps, side effects)?
4. **Support files** — does it need a `scripts/` helper, `references/` docs, or `assets/`? Usually no.

## 2. Settle the name

The folder name = the `name` field = the `/command`. It must be:

- kebab-case: lowercase `a-z`, `0-9`, hyphens; no leading/trailing/consecutive hyphens; ≤ 64 chars
- distinct from existing skills (check siblings / installed skills)

Confirm the name with the user before writing anything.

## 3. Locate where to write it

Determine the repo root:

- **In this skills repo** (the common case): `${CLAUDE_SKILL_DIR}/..` — check for `CONVENTIONS.md` and `_template/` there. New skills go as siblings: `<repo-root>/<name>/`.
- **Standalone** (this skill installed on its own elsewhere): default to `./<name>/` in the current project, or ask the user where the skill should live.

## 4. Write the SKILL.md

Create `<target>/<name>/SKILL.md`. Prefer copying `<repo-root>/_template/SKILL.md`
and filling it in. If the template isn't reachable (standalone use), write this skeleton:

```markdown
---
name: <folder-name>
description: <what it does>. Use when <natural trigger phrases the user would say>.
license: Apache-2.0
---

# <Title>

<One line: the single job.>

## Instructions

<Imperative steps. State what to do, not why — the body stays in context across
turns once invoked, so every line is recurring cost.>

1. ...
2. ...
3. <output / what to return>
```

Crafting the **description** (this is the trigger and the most important field):

- Lead with the **key use case**, then *what* it does, then *when* — woven with the
  real trigger phrases from step 1.
- Lean **slightly pushy** — skills under-trigger. e.g. append "Use this whenever the
  user mentions X, Y, or Z, even if they don't explicitly ask for it."
- Keep it **≤ 1024 characters** (hard cap in the portable standard).
- Don't put "when to use" anywhere but the description.

Crafting the **body**: imperative, concise, under 500 lines. Briefly explain *why*
a step matters rather than stacking rigid ALL-CAPS MUSTs — the model follows
reasoning better than rules. Move anything long into `references/` and link it.

If support files are needed, create the `scripts/` / `references/` / `assets/`
dirs and reference them from SKILL.md using `${CLAUDE_SKILL_DIR}/...` so paths
resolve wherever the skill is installed.

## 5. Lint it

After the SKILL.md is written, run the repo linter with the Bash tool (do NOT use a
`` !`...` `` injection block for this — those run when this skill loads, before the
new skill exists, so they would lint nothing). If `<repo-root>/scripts/validate.sh`
exists, run:

```bash
bash "${CLAUDE_SKILL_DIR}/../scripts/validate.sh" <name>
```

If the validator isn't reachable (standalone use), verify by hand against this checklist:

- [ ] `name` matches the folder; valid kebab-case; ≤ 64 chars
- [ ] `description` non-empty, ≤ 1024 chars, leads with use case + trigger phrases
- [ ] body < 500 lines
- [ ] no secrets/keys committed
- [ ] one clear job

Fix anything that fails and re-check.

## 6. Wrap up

- If an `IDEAS.md` exists at the repo root, offer to update this skill's row (set its
  status to `building`, or add a new row if it wasn't listed).
- If a `README.md` with a skills table exists at the repo root, offer to add a row for
  the new skill (name, one-line description, install command).
- Remind the user to **dogfood it in real work before publishing** — that's the cheapest test.
- Tell them how to invoke it (`/<name>`) and how others install it
  (`cp -r <name> ~/.claude/skills/`).
- If they want trigger-accuracy tuning or benchmark-grade evals, hand off to the
  `skill-creator` skill — this skill intentionally stops at a solid, linted draft.
