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

**Model pin:** default new skills to `model: sonnet` to cut invocation cost, unless the skill's core job benefits from the main session's own model (often a stronger tier like Opus or Fable) - decide per skill, don't apply blindly. The dividing line that keeps recurring: **does the skill check work against a known rubric, or judge semantics?** Matching a diff against a defined checklist (WCAG criteria, known perf anti-patterns, tool output) is cheap-tier work. Deciding whether something is *actually* a defect - reasoning across files, separating a real problem from a plausible-looking nitpick - is where tier shows, and it is worth paying for wherever a miss is not caught downstream.

Prefer inherit over a hard pin to a strong tier (`model: opus`): a pin caps the skill at that tier even when the session runs on a stronger one. Pin down deliberately; never pin up.

Confirmed exceptions to the sonnet default, and why:
- `prune-test-suite` - exact logic/text comparison between tests and source; a cheaper tier risks missing subtle drift.
- `audit`, `audit-fix` - in-depth, project-wide weakness analysis and remediation against broader project goals; this benefits from the stronger reasoning of whatever model is driving the main session.
- `handoff` - reads the current session's own state and must be unflatteringly honest about what is unfinished; a cheaper tier is likelier to paper over the gaps that make a handoff worth writing.
- `kickoff` - the generated prompt drives an entire successor session, so its quality compounds downstream.
- `commit` - the one-commit-vs-split call is a judgment on real diffs, not a mechanical grouping.
- `repo-adopt` - writes executable bash with safety gates and a starter CLAUDE.md for a repo it has just met.
- `math-research` - literature review, complexity bounds, and numerical-stability judgment; a cheaper tier is likelier to produce plausible recall than a traceable citation.
- `prompt-engineer` - the output is itself a prompt that drives another session, agent, or product surface, so its quality compounds downstream (same reasoning as `kickoff`); grounding research done mid-skill should also run at the session's own tier.
- `session-report` - same reasoning as `handoff`, one step sharper: the report is merged into a session that will act on it, so an unverified claim presented as a finished one gets acted on. Separating "verified" from "believed" is judgment, not transcription.

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
