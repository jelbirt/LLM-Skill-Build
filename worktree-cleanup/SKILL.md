---
name: worktree-cleanup
description: Tear down finished git worktrees safely - verify each branch is merged and its tree is clean, then remove the worktree, delete the branch, and prune. Sweeps every merged-and-clean worktree at once, or targets one branch. Use when the user wants to clean up, tear down, close out, or remove a worktree or workstream, says "worktree cleanup", "sweep merged worktrees", "remove finished worktrees", or asks to delete a finished branch's directory. Delegates to the repo's own scripts/rm-worktree.sh when one exists, and otherwise runs the equivalent gated steps directly.
argument-hint: [branch, or "sweep" to find all merged worktrees; defaults to sweep]
model: sonnet
---

# worktree-cleanup

Close out finished workstreams: remove the worktree directory, delete the
local branch, and prune worktree metadata — only for branches that are
merged and trees that are clean. Decide *what* to tear down, confirm with
the user, then do it.

## Instructions

1. **Orient.** From the repo's main checkout, determine the default branch
   (`git symbolic-ref refs/remotes/origin/HEAD`, falling back to whichever
   of `main`/`master` exists — the symref is often unset on a fresh clone
   even when a remote is configured) and whether the repo provides a
   teardown script at `scripts/rm-worktree.sh`. If it does, that script owns
   the safety gates and every removal goes through it; if not, run the
   equivalent steps yourself in step 4.

2. **Resolve targets.** If `$ARGUMENTS` names a branch, that is the only
   candidate. Otherwise (or on "sweep"), walk `git worktree list --porcelain`
   and skip entries with no `branch` line (detached HEAD or bare) plus the
   main checkout itself. For each remaining worktree, check both:
   - **Merged** — `git merge-base --is-ancestor refs/heads/{branch}
     refs/heads/{default-branch}` (fully-qualified: a bare name lets a
     same-named tag win the lookup), falling back to
     `gh pr list --state merged --head {branch}` to catch squash-merges,
     which the ancestor check cannot see. For the manual path in step 4
     this check is the sole authority on "merged" — the delete acts on its
     verdict and nothing later re-asks. (The script path re-checks via the
     script's own gate, which is why gh-verified squash-merges need
     `--force` there.)
   - **Clean** — `git -C {dir} status --porcelain` succeeds AND prints
     nothing. Capture the output and the exit code separately: a status
     command that FAILS also prints nothing, and reading that as "clean"
     skips the gate. A failing status is a refusal, not a pass.

3. **Present the plan and get confirmation.** List candidates with branch,
   directory, and merge evidence (ancestor vs merged PR number); then list
   every worktree SKIPPED with the reason — unmerged, dirty, or it is the
   worktree this session is running in. Git refuses to remove the directory
   you are standing in; hand that one to a session in another checkout or
   run from the main checkout. State plainly that removal destroys anything
   untracked-and-ignored inside the directory (virtualenvs, copied `.env`
   files, build output). Symlinks are removed but their targets are not.
   Never remove anything before the user confirms.

4. **Tear down each confirmed branch** from the main checkout:
   - With a teardown script: `scripts/rm-worktree.sh {branch}`. Add
     `--force` only for a squash-merge you verified via PR state in step 2,
     and `--delete-remote` only if the user asked — GitHub's "delete branch
     after merge" setting usually handled it already.
   - Without one: `git worktree remove {dir}`, then `git branch -D {branch}`,
     then `git worktree prune`. `-D`, not `-d`: the removal is irreversible
     by the time the branch delete runs, so nothing after it may veto — the
     merged check in step 2 is the sole authority, and it already accepted
     both ancestor-merged and PR-verified squash-merged branches. `-d` asks
     a DIFFERENT question (reachable from HEAD or upstream) and, when the
     two disagree — which a squash-merge admitted via `gh pr list`
     typically produces, always once the remote branch is deleted and
     pruned — it refuses only after the worktree is already gone,
     leaving the branch orphaned and prune never run. Run one branch at a
     time and stop on the first failure rather than escalating to `--force`.

5. **Report.** What was removed, what remains (`git worktree list`), and
   every candidate skipped or refused by a gate.

## Notes

- Never tear down the main checkout, and never delete a branch that is not
  merged — flag unmerged or dirty workstreams for the user instead.
- A failing gate is information, not an obstacle. Report it; do not work
  around it with `--force` or `rm -rf` unless the user explicitly asks
  after seeing the reason. (`-D` after the step-2 gates have passed is the
  standard delete, not an escalation; `-D` to override a gate that
  REFUSED is the thing that needs an explicit user ask.)
