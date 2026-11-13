# .ledger

Private, local only. The project repo skips this folder (it is listed in the repo's local
exclude file, not in `.gitignore`), and it is its own small git repo with no remote. It is
never pushed and never copied anywhere public, unless the user says so for this folder.

- **ledger.md** is the written memory of this project's Manager session: what is in flight,
  what the user asked for and whether it was answered, what they decided, and what each
  term means.
- **Who writes:** only the Manager session (the `manager` skill). It commits each change
  with a one-line message, so `git -C .ledger log -p ledger.md` shows how the state moved.
  These commits are notes, not code: no review pass or check command.
- **Who reads:** the Manager and the project's Ask session. Workers run in worktrees, which
  do not have this folder; the Manager puts what they need in their brief.
- **Where the truth is:** git, GitHub and the code. The ledger records intent and status;
  when it disagrees with them, the Manager fixes the ledger and says so.
- **packets/** holds review packets. They are not committed.
- **packet-example.md (optional):** a packet you like; the Manager copies its shape.
- **Careful:** `git clean -ffdx` (double f) in the main checkout deletes this folder, and
  deleting or re-cloning the repo loses it. Build, package and publish tools (Python sdists,
  Docker, npm) do not read git's exclude file, so never build or publish from the main
  checkout; use a worktree or CI.
