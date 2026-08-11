---
name: git-undo
description: Diagnose a git mistake and return the safe steps to undo it - the exact commands, what each does, what is reversible, and how to verify. Use whenever the user wants to undo, revert, roll back, or recover something in git, such as an accidental or wrong commit, committing to the wrong branch, an unwanted reset --hard, a bad merge or rebase, a force-push that lost work, a deleted branch, unstaging files, or "I think I lost a commit." Prefer this over ad-hoc git advice so recovery is state-aware and destructive steps are flagged and snapshotted first. If the repo is not directly accessible, ask the user to paste their git status and git reflog output.
argument-hint: [describe-the-mistake]
---

# git-undo

Help the user safely undo a git mistake. Diagnose the real state first, then give
the exact recovery commands - never guess, and never run a destructive command
without flagging it and snapshotting first.

The user's description of the mistake (if any): $ARGUMENTS

## 1. Diagnose before recommending anything

Recovery depends entirely on the actual state. Establish it first.

**If you can run git in the user's repo** (e.g. Claude Code), run these read-only
commands and read the output before saying anything:

- `git status` - staged/unstaged/untracked, current branch, ahead/behind
- `git log --oneline -20` - recent commits
- `git reflog -20` - the safety net: where HEAD has been (this is what makes most "lost" work recoverable)

**If you cannot access the repo** (e.g. the chat app's sandbox), ask the user to
paste the output of `git status` and `git reflog`. Do not recommend commands until
you have it - the wrong assumption here can cause real data loss.

Also confirm the few facts that change the safe answer, if not already clear:

- Is the bad work **committed**, or just staged/unstaged?
- Has it been **pushed**? Is the branch **shared** with others?
- Do they want to **keep the changes** (just undo the commit) or **discard them**?

## 2. Identify the situation

Map the diagnosis to one of these. Pick the safest command that fits.

| Situation | Safe recovery | Reversible? |
| :-------- | :------------ | :---------- |
| Discard changes to a tracked file (not yet committed) | `git restore {file}` | No - uncommitted edits are lost |
| Unstage a file (keep the edits) | `git restore --staged {file}` | Yes |
| Undo the last commit, keep changes staged | `git reset --soft HEAD~1` | Yes (commit is in reflog) |
| Undo the last commit, keep changes unstaged | `git reset HEAD~1` (a.k.a. `--mixed`) | Yes (reflog) |
| Fix the last commit's message / add a forgotten file | `git commit --amend` | Yes if not pushed (reflog) |
| Discard the last commit **and** its changes | snapshot first, then `git reset --hard HEAD~1` | **Destructive** - see step 3 |
| Committed to the wrong branch (not pushed) | `git switch {correct-branch}` then cherry-pick or, on the wrong branch, `git reset --hard HEAD~1` after the commit is safely on the right branch | Mixed - snapshot first |
| Undo a commit that was already **pushed/shared** | `git revert {sha}` (adds a new commit that reverses it - does not rewrite history) | Yes, and safe for shared branches |
| Recover work after a bad `reset --hard`, rebase, or merge | find the good SHA in `git reflog`, then `git reset --hard {sha}` (or `git merge --ff-only {sha}`) | Recovers if within the reflog window |
| Undo a merge that isn't pushed | `git reset --hard ORIG_HEAD` (snapshot first) | Recoverable via reflog |
| Restore a deleted branch | find its tip SHA in `git reflog`, then `git branch {name} {sha}` | Yes |
| Recover files removed by `git clean` / deleted untracked files | usually **not recoverable** via git - say so honestly; suggest editor local history / OS trash | Often no |

If the situation isn't in this table, reason from the diagnosis and the same
safety rules below.

## 3. Apply the safety discipline

This is the part that protects the user from making the mistake worse.

- **Classify every command** you recommend as reversible or destructive. Call it out explicitly.
- **Before any destructive command** (`reset --hard`, `clean -fd`, `push --force`, `checkout .`), create a snapshot the user can return to:
  - `git branch backup/before-undo` (marks the current commit), and note the current `git reflog` entry.
- **Never rewrite shared history by default.** If the bad commit was pushed to a shared branch, prefer `git revert` over `reset`/rebase. If rewriting truly is the goal and the branch is private or coordinated, use `git push --force-with-lease` (not `--force`) so you don't clobber others' work.
- **Prefer modern, intent-clear commands:** `git restore` / `git switch` over overloaded `git checkout`.
- **Don't auto-run destructive steps.** Show the command, explain the blast radius, and ask the user to confirm (or run it themselves in the chat app).

## 4. Return the recovery

Give the user, in this order:

1. **What happened** - one line naming the situation you diagnosed.
2. **The fix** - the exact command(s), copy-pasteable, in order. Mark each reversible or destructive.
3. **What each command does** - a short clause per command, so they learn, not just paste.
4. **How to verify** - what `git status` / `git log` should show afterward.
5. **The escape hatch** - if anything looks wrong, the snapshot branch or reflog SHA to return to.

Keep it calm and concrete. The user is likely stressed; precise, reassuring steps
matter more than exhaustive theory.
