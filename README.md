# LLM Skill Build

A small, curated set of focused [Agent Skills](https://agentskills.io) for Claude Code and other skills-compatible agents. Each skill does **one clear job**, is dogfooded in real work before publishing, and follows the portable Agent Skills standard so it works across multiple agent tools.

## Skills

| Skill | What it does | Install |
| :---- | :----------- | :------ |
| [`new-skill`](new-skill/) | Interview + scaffold a new, conventions-following skill, then lint it. | `cp -r new-skill ~/.claude/skills/` |
| [`git-undo`](git-undo/) | Diagnose a git mistake and walk you through safe recovery, flagging destructive steps. | `cp -r git-undo ~/.claude/skills/` |
| [`sidebar`](sidebar/) | Answer a tangential side question by delegating it to a subagent, keeping the research out of your main context. | `cp -r sidebar ~/.claude/skills/` |
| [`hone-skill`](hone-skill/) | Improve an existing skill — analyze it, apply targeted edits for a requested improvement, then re-lint and validate. | `cp -r hone-skill ~/.claude/skills/` |

<!-- As skills ship, add a row: | [`name`](name/) | one line | `cp -r name ~/.claude/skills/` | -->

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
