---
name: digest
description: Produce a cross-project status digest - a short, decisions-first brief synthesized from each repo's worktrees, branches, open PRs, CI state, and todo/state docs, ordered by what needs the reader's attention. Use whenever the user wants a status digest, weekly brief, Monday brief, standup summary, or cross-project status, says "digest", "weekly digest", "status brief", "what moved last week", or "where does everything stand", or when a scheduled digest run fires. Read-only - it never commits, writes files, or mutates any repo.
argument-hint: [optional repo path, parent directory, or focus area]
model: sonnet
---

# digest

One tight brief answering three questions: what moved recently, what is
waiting on the reader, and what is at risk of being forgotten. Lead with
what needs their attention, not with inventory.

## 1. Pick the scope

- If `$ARGUMENTS` names a repo, a parent directory, or a focus area, use it.
- Else if the working directory is inside a git repo, digest that repo.
- Else find candidate repos one or two levels below the working directory
  (directories containing `.git`), and list what you found before digesting
  more than a handful.

## 2. Collect — read-only, never mutate anything during a digest

1. Per repo: `git worktree list` plus `git -C {dir} status --porcelain` and
   ahead/behind counts for each worktree — branch, clean or DIRTY, drift.
   If the user has a multi-repo status helper on `PATH`, prefer it.
2. Per repo with a GitHub remote: `gh pr list --state open` (age, CI state,
   review state) and `gh pr list --state merged --limit 10` filtered to the
   digest window (default: last 7 days). Note anything red or stuck.
3. Per repo: the todo or state doc its `CLAUDE.md` points at (e.g.
   `tasks/todo.md`) — open gates, in-progress items, "awaiting owner"
   markers. Plus `git log --oneline --since='7 days ago'` on the default
   branch for what actually landed.
4. Skip repos with no activity in the window rather than reporting silence.

## 3. Compose — decisions-first, one screen

Order by what the reader should act on, not by repo:

1. **Waiting on you** — open gates, PRs awaiting review, unanswered
   questions. Each with a one-line "what happens once you decide."
2. **Moved recently** — merged PRs, closed gates, landed milestones; one
   line each naming the decision it embodied, not the file list.
3. **In flight** — active workstreams and where each stands; flag worktrees
   that look abandoned (dirty with no commits in the window).
4. **Risks / drift** — stale branches, red or stuck CI, worktrees ahead of
   origin but unpushed, anything promised in a todo doc but untouched.

Omit empty categories rather than padding them. Keep the whole digest under
~40 lines. No disclaimers or footers.

## 4. Deliver

Print the digest directly in chat. If the invocation came from a scheduled
run whose instructions name another delivery channel, use that channel too.
Do not write files and do not commit anything.
