---
name: repo-adopt
description: Scaffold any repo for a parallel-workstream worktree workflow - tailored scripts/new-worktree.sh and rm-worktree.sh wired to that repo's own gitignored local state (secrets to copy, caches to share, envs to recreate), a repo-local worktree-cleanup skill, and a CI workflow built from its real test and lint commands; optionally a decisions-first PR template and a starter CLAUDE.md plus tasks/todo.md encoding a gated spec-plan-build workflow. Use whenever the user wants to adopt, onboard, or set up a repo or a brand-new project for git worktrees or parallel agent sessions, says "repo-adopt", "adopt this repo", "wire this repo for worktrees", or "set this project up for parallel sessions". Supports a dry-run that reports what it would create without writing anything.
argument-hint: [repo path] [--dry-run]
---

# repo-adopt

Point at a repo and scaffold the per-repo pieces of a parallel-workstream
workflow: branch-per-workstream worktrees (creation AND teardown), CI at the
merge point, and — when asked — a decisions-first PR template and a starter
CLAUDE.md plus tasks/todo.md. Detect, propose, confirm, then write. Never
guess silently, and never overwrite an existing file without showing a diff
first.

## 1. Inspect the target repo

The repo path may be passed as `$ARGUMENTS` (default: current directory).
With `--dry-run`, do all detection and produce the full proposed file
contents, but write nothing.

Detect, and record what you find:

1. **Sanity** — it is a git repo; note the default branch and the remote,
   if any.
2. **Gitignored local state** a bare `git worktree add` would miss — read
   `.gitignore` and check what actually exists: secrets files such as `.env`
   (copy per worktree), large data or cache directories (symlink and share),
   virtualenvs and `node_modules` (recreate, never copy). For anything
   ambiguous, **ask which way to wire it** — shared-vs-copied is a per-repo
   judgment, and a shared cache can carry operational meaning.
3. **Shared mutable state** — append-only ledgers, registries, databases:
   anything two concurrent workstreams would corrupt by writing at once. If
   found, plan a "who holds the pen" warning in the worktree script's output
   and suggest a pen-registry line in the repo's todo or state doc.
   **Check both directions across repos, not just across worktrees.** A cache
   this repo owns may have *inbound* consumers — sibling repos whose own
   gitignored directories are symlinks pointing into this checkout, or whose
   scheduled jobs invoke this repo's CLI to write it. Conversely this repo's
   shared directories may themselves be symlinks pointing *outward*. Resolve
   the symlinks rather than trusting directory names, and scan sibling repos
   for links landing here. A pen rule that says "one worktree at a time" is
   actively wrong when the real co-holder is another repo, and a fresh
   session adopting this repo cold has no way to know that. When you find
   cross-repo coupling, name the other repo and what it does — reads, writes,
   or runs a scheduled job — and ask which repo's state doc owns the pen
   registry so it is recorded once rather than duplicated into drift.
4. **Test/lint stack** — lockfiles and config (`pyproject.toml` plus
   `uv.lock`, `package.json`, `Cargo.toml`, ...) and the actual test and
   lint commands. Prefer what CLAUDE.md or the README document over
   inference.
5. **Existing artifacts** — `scripts/new-worktree.sh`,
   `scripts/rm-worktree.sh`, `.claude/skills/`, CI workflows, PR template,
   `CLAUDE.md`, `tasks/todo.md`. Never clobber; propose a diff against what
   exists instead.

## 2. Scaffold

Generate, confirming the choices flagged in step 1:

- **`scripts/new-worktree.sh`** — usage `scripts/new-worktree.sh {branch}
  [dir]`; creates the worktree from the default branch, reusing the branch
  if it already exists; then wires this repo's specific state — symlink the
  shared directories, copy the secrets files, leave envs to be recreated. A
  header comment documents WHAT is wired and WHY, plus the shared-state pen
  rule when step 1.3 found any — naming every co-holder it found, including
  other repos and scheduled jobs, since a pen rule scoped to worktrees reads
  as safe while the real conflict sits outside them. Use `set -euo pipefail`,
  set the executable
  bit, and end by echoing the new path and the repo's test command as the
  next step.
- **`scripts/rm-worktree.sh`** — the teardown mirror; usage
  `scripts/rm-worktree.sh {branch} [--force] [--delete-remote]`. Gate before
  removing anything: the branch is merged into the default branch, the tree
  is clean, the target is not the main checkout, and it is not the current
  working directory. Then, in this order: `git worktree remove {dir}`,
  `git branch -d {branch}`, `git worktree prune` — the branch delete must
  come after the worktree removal, since git refuses to delete a branch
  that is still checked out somewhere. `--force` covers squash-merged
  branches, which the merged-check cannot see (it upgrades the branch
  delete to `-D`); `--delete-remote` optionally deletes the remote branch
  as well.
- **CI workflow** (`.github/workflows/ci.yml`) — on pull_request and on push
  to the default branch; locked install (`uv sync --frozen`, `npm ci`, ...);
  then this repo's real lint, format-check, and test commands from step 1.4.
  Skip or adapt when the repo has no remote or already has CI.
- **Repo skill `worktree-cleanup`**
  (`.claude/skills/worktree-cleanup/SKILL.md`) — a thin wrapper over
  `rm-worktree.sh`: with a branch argument tear down that worktree; with no
  argument, sweep — find every merged-and-clean worktree, list them, confirm
  once, then tear down each. If the `worktree-cleanup` skill is already
  installed, copy it and adjust its notes to name this repo's wired state.
- **PR template** (`.github/pull_request_template.md`, only when asked) —
  decisions-first: decisions made, hypotheses, cost, and methodology at the
  top; mechanics (files, tests, how verified) below.
- **Starter `CLAUDE.md` plus `tasks/todo.md`** (only when asked, or offer
  it when the repo has neither — typical for a brand-new project). Encode
  the operating model, not boilerplate: the repo's test and lint commands
  (the must-be-green-before-commit bar), the parallel-workstream rules (one
  branch per workstream via `new-worktree.sh`, the default branch as review
  inbox, merge back via PRs, plus any pen or serialized state from step
  1.3), and the gated workflow (spec, plan, tasks, implement, with explicit
  owner-approval gates; PRs opened for review, never merged by the agent).
  `tasks/todo.md` starts as the current-state doc: active workstreams, next
  gates, and a pen-registry line when step 1.3 applies. Keep both to about a
  page — they are conventions, not documentation.

## 3. Verify and report

- **Dry-run:** print each proposed file in full, plus the questions you
  would have asked. Where the repo already has an equivalent, diff proposal
  against existing and say whether adoption would be a no-op.
- **Real run:** `bash -n` both scripts, create a throwaway worktree with
  `new-worktree.sh` and confirm the wiring (symlinks resolve, secrets
  copied), then tear it down with `rm-worktree.sh --force` to exercise the
  teardown path end to end. Run the lint and test commands locally to
  confirm the CI workflow's commands are real before committing anything.
- Land the changes per the target repo's own commit and review policy (read
  its CLAUDE.md): propose commits, and never auto-merge.
