---
name: hone-skill
description: Improve an existing skill - locate its SKILL.md, analyze the current state, plan and apply targeted edits to achieve a requested improvement, then re-lint and validate. Pass the target skill's name plus what you want to improve. Use whenever the user wants to hone, refine, tweak, sharpen, fix, tighten, or upgrade an existing skill, says "hone-skill", "improve the X skill", "make the X skill better", "the X skill should also handle...", or "update the description/body of skill Y". Edits in place against the repo conventions and preserves the skill's single job rather than rewriting wholesale.
argument-hint: [skill-name] [what to improve]
---

# hone-skill

Improve one existing skill: analyze it, apply targeted edits for the requested
improvement, then lint and validate. Preserve what already works — refine, don't rewrite.

The request (target skill + what to improve): $ARGUMENTS

## 1. Identify the target and the goal

- Parse the arguments for the **skill name** and the **improvement** wanted. If either is missing or ambiguous, ask before changing anything.
- Locate the skill's `SKILL.md`. Prefer the **repo source**: search the working directory and its ancestors for the folder named after the skill, sitting beside `CONVENTIONS.md`, `_template/`, and `scripts/`. That parent is `REPO_ROOT`.
- Fall back to `~/.claude/skills/NAME/SKILL.md`. If that path is a **symlink**, follow it and edit the real source so the repo stays the source of truth.
- If the skill isn't found or several match, list candidates and ask which one.

## 2. Analyze the current skill

- Read the full `SKILL.md`. Note the frontmatter (name, description, which keys), the single job it does, the body's structure and length, and any `scripts/`/`references/`.
- If `REPO_ROOT/CONVENTIONS.md` exists, read it so edits stay compliant.
- Pin down exactly what the improvement needs and where it lands: triggering (description), a step, a new edge case, tighter wording, or scope.

## 3. Plan the change

- For anything beyond a trivial wording tweak, state a **short plan** — what you'll change and why, in a few lines — before editing.
- Keep the skill to **one job**. If the request really adds a second job, say so and propose a separate skill (hand off to `/new-skill`) instead of bloating this one.
- Make **targeted edits**; don't rewrite a working skill wholesale.

## 4. Apply the edits

Edit `SKILL.md` in place, respecting the conventions:

- **description** ≤ 1024 chars, leads with the use case + real trigger phrases, no XML/angle-bracket tags, no unquoted `: ` (colon-space) that can break YAML.
- **frontmatter** uses only Claude Code-recognized keys — never add `license`, `metadata`, or `compatibility` (they silently hide the skill from the `/` menu).
- **body** under 500 lines, imperative and concise; move long material into `references/` and link it.
- If the improvement is about *triggering*, sharpen the description's trigger phrases (skills under-trigger — lean slightly pushy).

## 5. Lint and validate

- Run `REPO_ROOT/scripts/validate.sh NAME`. Fix anything it flags and re-run until clean.
- If the validator isn't reachable, hand-check against the conventions checklist (name/folder match, allowed keys, description cap, body length, no secrets, one job).
- If the skill is **symlinked** into `~/.claude/skills`, the edit is already live (body changes hot-reload). Otherwise remind the user to reinstall (`scripts/install.sh NAME`) and, for description/frontmatter changes, fully restart Claude Code to pick them up.

## 6. Report

- Summarize what changed (frontmatter vs. body), the lint result, and what's worth dogfooding next.
- Note anything you deliberately left out of scope.
- For trigger-accuracy tuning or benchmark-grade evals, hand off to the `skill-creator` skill — this skill stops at a solid, linted, improved draft.
