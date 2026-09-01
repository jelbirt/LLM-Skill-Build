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

**Model pin:** default new skills to *inheriting the session model* (no `model:` key) - pin down to `model: sonnet` only when the skill's job is provably mechanical, or bounded and recurring enough that cheapness outweighs a marginal quality delta (see `digest`, `next-steps`). The dividing line that keeps recurring: **does the skill check work against a known rubric, or judge semantics?** Matching output against a defined checklist (commit prefixes, tool output, marker-delimited transforms) is cheap-tier work. Anything involving judgment, safety-critical advice, or output whose quality compounds downstream (generated prompts, skill descriptions, review verdicts) runs at the session's own tier.

(This flips the original pin-by-default policy, 2026-08: A/B bake-offs during the scaffold prune showed current bare models matching skill-guided output on judgment tasks, so the cheap-tier saving no longer covers the cost of a subtle miss. The `_template` accordingly ships with no `model:` key.)

Prefer inherit over a hard pin to a strong tier (`model: opus`) for the skill's **own** body: a pin caps the skill at that tier even when the session runs on a stronger one. Pin down deliberately; never pin up.

**Subagents a skill dispatches are a separate question, and the default flips.** The rule above governs the tier the skill's own body runs at. It does *not* govern the tier of subagents the skill launches through the Agent tool, where staying silent is actively wrong: the session model propagates to every agent spawned, so a fan-out skill multiplies the session's tier across N agents, and a skill whose whole purpose is to move work *off* the main session's budget hands that budget right back. A skill that dispatches subagents therefore **names a tier explicitly** in its dispatch instruction rather than letting inherit decide.

(Added 2026-09, after Fable-tier sessions were found propagating into every dispatched agent. The named tier is a ceiling on delegated work, not a claim that the job requires that tier: pick the lowest tier that does the job, same test as the pin-down rule above.)

Skills that name a tier for the agents they dispatch:
- `sidebar` - `opus`; the skill exists to keep research off the main session's budget.
- `flowchart` - `opus`; one exploration dispatch per request.
- `audit-fix` - `opus`; fans out one agent per file group, so the tier multiplies.
- `next-steps` - `sonnet`; bounded, frequent status review, cheapness is the point.

The same reasoning applies to persona definitions in `~/.claude/agents/` (outside this repo): an agent file with no `model:` key inherits on every invocation, so the high-frequency reviewers there name a tier as well.

Skills that keep a sonnet pin, and why:
- `release-notes` - mechanical grouping of conventional-commit prefixes.
- `worktree-cleanup` - scripted, gated teardown; the merged-and-clean check is mechanical.
- `deps-audit` - triage of audit/outdated/depcheck tool output.
- `next-steps` - bounded, frequent status review; cheapness is the point.
- `digest` - bounded read-only synthesis, runs on a schedule.
- `sync-profile-readme` - marker-delimited text transformation behind a diff gate.

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
