# LLM Skill Build

A small, curated set of focused [Agent Skills](https://agentskills.io) for Claude Code and other skills-compatible agents. Each skill does **one clear job**, is dogfooded in real work before publishing, and follows the portable Agent Skills standard so it works across multiple agent tools.

## Skills

| Skill | What it does | Install |
| :---- | :----------- | :------ |
| [`new-skill`](new-skill/) | Interview + scaffold a new, conventions-following skill, then lint it. | `cp -r new-skill ~/.claude/skills/` |
| [`git-undo`](git-undo/) | Diagnose a git mistake and walk you through safe recovery, flagging destructive steps. | `cp -r git-undo ~/.claude/skills/` |
| [`prompt-engineer`](prompt-engineer/) | Design, diagnose, and refine prompts using a standalone structure-and-technique framework. | `cp -r prompt-engineer ~/.claude/skills/` |
| [`release-notes`](release-notes/) | Generate release notes from git history since the last tag, grouped by conventional-commit type. | `cp -r release-notes ~/.claude/skills/` |
| [`deps-audit`](deps-audit/) | Unified, prioritized dependency report across security, freshness, and unused packages. | `cp -r deps-audit ~/.claude/skills/` |
| [`prune-test-suite`](prune-test-suite/) | Review a test suite for relevance against current source, prune stale tests, and add missing coverage. | `cp -r prune-test-suite ~/.claude/skills/` |
| [`sidebar`](sidebar/) | Answer a tangential side question by delegating it to a subagent, keeping the research out of your main context. | `cp -r sidebar ~/.claude/skills/` |
| [`hone-skill`](hone-skill/) | Improve an existing skill — analyze it, apply targeted edits for a requested improvement, then re-lint and validate. | `cp -r hone-skill ~/.claude/skills/` |
| [`next-steps`](next-steps/) | Recommend prioritized next steps for the project via a token-efficient Sonnet subagent that reviews repo state and the freshest roadmap docs. | `cp -r next-steps ~/.claude/skills/` |
| [`flowchart`](flowchart/) | Generate a clean, readable flowchart for a codebase, feature, or process and render it inline in chat, delegating exploration to a subagent to stay token-efficient. | `cp -r flowchart ~/.claude/skills/` |
| [`audit`](audit/) | Run a severity-organized project audit with an optional focus area; flags findings too large for quick-fixing as candidates for the spec→plan→build pipeline. | `cp -r audit ~/.claude/skills/` |
| [`audit-fix`](audit-fix/) | Implement `/audit` findings via parallel subagents with disjoint file scopes; bug fixes require a failing repro test first (Prove-It), and pipeline-sized findings are deferred rather than quick-fixed. | `cp -r audit-fix ~/.claude/skills/` |
| [`commit`](commit/) | Commit pending changes with an auto-generated message in the repo's style, splitting across commits when the diff spans unrelated concerns. | `cp -r commit ~/.claude/skills/` |
| [`handoff`](handoff/) | Emit a successor-session briefing from the current session — state left behind, promised-but-undone work, open gates, honest uncertainties. | `cp -r handoff ~/.claude/skills/` |
| [`kickoff`](kickoff/) | Turn a short workstream description into a complete, copy-ready kickoff prompt for a fresh session, with machine-checkable acceptance checks. | `cp -r kickoff ~/.claude/skills/` |
| [`worktree-cleanup`](worktree-cleanup/) | Sweep finished git worktrees — verify merged and clean, then remove the worktree, delete the branch, and prune. | `cp -r worktree-cleanup ~/.claude/skills/` |

<!-- As skills ship, add a row: | [`name`](name/) | one line | `cp -r name ~/.claude/skills/` | -->

## Third-party pipeline (installed, not vendored)

The 8-command development pipeline from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (`/spec` → `/plan` → `/build` → `/test` → `/review-gate` → `/code-simplify` → `/webperf` → `/ship`) is installed into `~/.claude/` by [`scripts/install-agent-skills.sh`](scripts/install-agent-skills.sh) — a pinned, reproducible recipe that applies this repo's small port modifications (documented in the script header). Upstream content is not vendored here; an imported skill enters this repo only once it's been personally customized, at which point it moves to a root-level folder and comes off the recipe's install list.

## Installing a skill

Each skill is a self-contained folder. To install one:

```bash
# Personal (available in all your projects):
cp -r <skill-name> ~/.claude/skills/

# Or project-scoped (this repo/project only):
cp -r <skill-name> .claude/skills/
```

Then invoke it with `/<skill-name>`, or just describe your task — Claude loads the skill automatically when the description matches.

## Repo layout

```
LLM-Skill-Build/
├── CONVENTIONS.md      # how skills here are authored + quality checklist
├── IDEAS.md            # backlog of skill candidates
├── _template/          # canonical SKILL.md starter
├── scripts/validate.sh # lint a skill folder
└── <skill-name>/       # one folder per skill
```

## Contributing / authoring

See [CONVENTIONS.md](CONVENTIONS.md). In short: one clear job, a description that
leads with natural trigger phrases (≤ 1024 chars), body under 500 lines, no secrets,
and `scripts/validate.sh <skill-folder>` passes.

## License

[Apache-2.0](LICENSE).
