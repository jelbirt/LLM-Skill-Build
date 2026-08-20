# LLM Skill Build

[![validate](https://github.com/jelbirt/LLM-Skill-Build/actions/workflows/validate.yml/badge.svg)](https://github.com/jelbirt/LLM-Skill-Build/actions/workflows/validate.yml)

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
| [`next-steps`](next-steps/) | Recommend prioritized next steps for the project via a token-efficient subagent that reviews repo state and the freshest roadmap docs. | `cp -r next-steps ~/.claude/skills/` |
| [`flowchart`](flowchart/) | Generate a clean, readable flowchart for a codebase, feature, or process and render it inline in chat, delegating exploration to a subagent to stay token-efficient. | `cp -r flowchart ~/.claude/skills/` |
| [`audit`](audit/) | Run a severity-organized project audit with an optional focus area; flags findings too large for quick-fixing as candidates for the spec→plan→build pipeline. | `cp -r audit ~/.claude/skills/` |
| [`audit-fix`](audit-fix/) | Implement `/audit` findings via parallel subagents with disjoint file scopes; bug fixes require a failing repro test first (Prove-It), and pipeline-sized findings are deferred rather than quick-fixed. | `cp -r audit-fix ~/.claude/skills/` |
| [`commit`](commit/) | Commit pending changes with an auto-generated message in the repo's style, splitting across commits when the diff spans unrelated concerns. | `cp -r commit ~/.claude/skills/` |
| [`handoff`](handoff/) | Emit a successor-session briefing from the current session — state left behind, promised-but-undone work, open gates, honest uncertainties. | `cp -r handoff ~/.claude/skills/` |
| [`kickoff`](kickoff/) | Turn a short workstream description into a complete, copy-ready kickoff prompt for a fresh session, with machine-checkable acceptance checks. | `cp -r kickoff ~/.claude/skills/` |
| [`worktree-cleanup`](worktree-cleanup/) | Sweep finished git worktrees — verify merged and clean, then remove the worktree, delete the branch, and prune. | `cp -r worktree-cleanup ~/.claude/skills/` |
| [`digest`](digest/) | Cross-project status digest ordered by what needs your attention: what moved, what's waiting on you, what's drifting. Read-only. | `cp -r digest ~/.claude/skills/` |
| [`repo-adopt`](repo-adopt/) | Scaffold a repo for parallel-workstream worktrees — create/teardown scripts, a one-definition green bar, CI, and a commit guard that enforces it. Handles multi-project repos. | `cp -r repo-adopt ~/.claude/skills/` |
| [`math-research`](math-research/) | Review a mathematical or algorithmic choice against the literature via a research-only subagent — cited findings, complexity bounds, stability analysis, tradeoffs. | `cp -r math-research ~/.claude/skills/` |
| [`sync-profile-readme`](sync-profile-readme/) | Regenerate a GitHub profile README's project table from your pinned repos — rewrites only the marked region, leaves hand-written rows alone, and never deletes a row. | `cp -r sync-profile-readme ~/.claude/skills/` |
| [`session-report`](session-report/) | Report this session's status up to the main session that delegated it — scope, what landed, what changed on disk, verification evidence, what's outstanding. | `cp -r session-report ~/.claude/skills/` |
| [`scaffold-audit`](scaffold-audit/) | Periodic re-audit of your entire Claude Code config — full inventory (skills, commands, agents, hooks, permissions, pins), decay triage, ground-truth A/B bake-offs, verified prune with git rollback. Makes the periodic delete-your-scaffolding ritual urged by Boris Cherny repeatable and evidence-based. | `cp -r scaffold-audit ~/.claude/skills/` |

<!-- As skills ship, add a row: | [`name`](name/) | one line | `cp -r name ~/.claude/skills/` | -->

## Third-party pipeline (installed, not vendored)

The 8-command development pipeline from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (`/spec` → `/plan` → `/build` → `/test` → `/review-gate` → `/code-simplify` → `/webperf` → `/ship`) is installed into `~/.claude/` by [`scripts/install-agent-skills.sh`](scripts/install-agent-skills.sh) — a pinned, reproducible recipe that applies this repo's small port modifications (documented in the script header). Upstream content is not vendored here; an imported skill enters this repo only once it's been personally customized, at which point it moves to a root-level folder and comes off the recipe's install list.

## Installing

Each skill is a self-contained folder; each agent persona is a single file under
[`agents/`](agents/). Install either with the same script — it lints first and
refuses to install anything that fails.

```bash
scripts/install.sh --all              # every skill + every persona
scripts/install.sh --all --symlink    # link instead of copy (repo stays source of truth)
scripts/install.sh audit git-undo     # or pick by name
scripts/install.sh --skills           # skills only
scripts/install.sh --agents           # personas only
```

Skills land in `~/.claude/skills/`, personas in `~/.claude/agents/`. Override
either with `CLAUDE_SKILLS_DIR` / `CLAUDE_AGENTS_DIR`. To scope a skill to one
project instead, copy the folder into that repo's `.claude/skills/`.

Then **fully quit and relaunch Claude Code** — new skills only enter the `/` menu
on a cold start. Invoke with `/<skill-name>`, or just describe your task and
Claude loads the skill when the description matches.

## Example

```text
> /git-undo I committed to main but meant to put it on a feature branch

Snapshot first (safe fallback): git branch backup/main-before-undo
1. git branch feature/my-work    # keep your commit on a new branch
2. git reset --hard HEAD~1       # move main back one commit (destructive — snapshot taken above)
3. git switch feature/my-work    # continue where you left off
Verify: git log --oneline -2 main feature/my-work
```

Each skill works this way: describe the situation, get state-aware steps with destructive operations flagged, or a finished artifact (scaffolded skill, digest, flowchart) where that's the skill's job.

## Repo layout

```
LLM-Skill-Build/
├── CONVENTIONS.md      # how skills here are authored + quality checklist
├── IDEAS.md            # backlog of skill candidates
├── _template/          # canonical SKILL.md starter
├── agents/             # agent personas, one <name>.md per persona
├── scripts/install.sh  # install skills + personas into ~/.claude
├── scripts/validate.sh # lint a skill folder
└── <skill-name>/       # one folder per skill
```

## Contributing / authoring

See [CONVENTIONS.md](CONVENTIONS.md). In short: one clear job, a description that
leads with natural trigger phrases (≤ 1024 chars), body under 500 lines, no secrets,
and `scripts/validate.sh <skill-folder>` passes.

## License

[Apache-2.0](LICENSE).
