# Agent personas

Personas installed into `~/.claude/agents/` by [`scripts/install.sh`](../scripts/install.sh).

One persona per file, `<name>.md`, with YAML frontmatter carrying a `name` that
matches the filename and a `description`. The `name` is the `subagent_type`
callers dispatch on — if it does not match the filename, resolution fails
silently, so `install.sh` lints for it and refuses to install a mismatch.

```bash
scripts/install.sh --agents            # install every persona here
scripts/install.sh --agents --symlink  # link instead of copy
scripts/install.sh code-reviewer       # or install one by name
scripts/install.sh --all               # skills + personas together
```

## Scope

This folder is only for personas the third-party recipe does **not** install.
[`scripts/install-agent-skills.sh`](../scripts/install-agent-skills.sh) installs
`test-engineer` and `web-performance-auditor` from pinned upstream; do not add
files of those names here or the two installers will fight over the same paths.

## Pending personas

`code-reviewer` and `security-auditor` are referenced by the installed command
set but are not included here yet.

[`scripts/install-agent-skills.sh`](../scripts/install-agent-skills.sh)
deliberately skips both, on the reasoning that user-level definitions in
`~/.claude/agents/` take precedence over upstream's by design. That reasoning
holds only where those definitions already exist. On a clean install nothing
exists at any level to take precedence, and the references do not resolve.

**What depends on them:**

| Reference | Impact if missing |
| :-------- | :---------------- |
| `commands/ship.md` | Real — Phase A fans out to 3 personas, only `test-engineer` resolves |
| `skills/doubt-driven-development` | None — explicit fallback to a generic subagent |
| `agents/test-engineer.md` | None — prose only |
| `agents/web-performance-auditor.md` | None — explicitly does not invoke other personas |

**To add them,** from a machine holding the originals:

```bash
cp ~/.claude/agents/code-reviewer.md    agents/
cp ~/.claude/agents/security-auditor.md agents/   # the merged security-reviewer checklist
scripts/install.sh --agents             # lint before committing
git add agents/ && git commit && git push
```

Then any new machine is `git pull && scripts/install.sh --all --symlink`.

**Before restoring them, consider whether they earn their keep.** This repo
retired six upstream skills after A/B bake-offs showed identical outcomes
against the bare model, and `scaffold-audit` exists to make exactly that call.
Claude Code ships built-in `/code-review` and `/security-review`. A bake-off
is more consistent with how this repo is maintained than restoring on reflex.
