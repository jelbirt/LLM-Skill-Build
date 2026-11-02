---
name: repo-issue-scout
description: Scout an open source repo for issues worth contributing to and return a ranked shortlist, then stop. Checks first that outside contributors can open pull requests there, learns the project's contribution rules and the evidence your past merged PRs carried, drops issues someone else has claimed, linked to an open PR, or already fixed on the default branch, verifies each survivor against current code with file:line citations, and reproduces it only where that is cheap. It is research only and never writes code, creates a branch, or posts on GitHub. Use when the user says "find something to contribute to", "scout issues in [repo]", "good first issues for me in [repo]", "what can I help with in this project", "repo-issue-scout", or names an open source repo they want to contribute to, even without naming the skill. Quick tier by default; builds and long runs are a deeper tier offered for the top picks only.
argument-hint: '[owner/repo] [quick|deep] [as @handle] [skip #N ...] [focus, e.g. "parser bugs, small fixes only"]'
---

# repo-issue-scout

Find the open issues in one repo that are worth this user's time, check each
against current code, and hand back a ranked shortlist. Then stop: the user
picks a candidate and a separate session does the work.

## Inputs

Parse `$ARGUMENTS`:

- **Repo**: the first `owner/repo` or GitHub URL. If none, use the current
  clone's `upstream` remote, else its `origin` if that is not the user's own
  fork, else ask and stop.
- **Depth**: `quick` (default) or `deep`. `deep` still runs the quick tier
  first and only lifts the ask-first rule for the top 1 or 2 candidates (see
  Deep tier).
- **Contributor**: `as @handle`, else `gh api user -q .login`.
- **Skips**: issue numbers, labels or areas the user names to exclude.
- **Focus**: any remaining text. It names the area, issue type or constraints
  the user cares about ("only the CLI", "no UI work", "something I can finish
  in a weekend", "performance issues"). Apply it twice: when filtering (drop
  what it rules out, and say how many it dropped) and when ranking (what
  matches it ranks higher). If it conflicts with what the repo needs most, say
  so rather than silently following one.

## Standing rules

- **Research only.** Never write code, create or switch a branch, commit, or
  post anything on GitHub: no comments, issues, PRs, reviews or reactions.
  `gh` is used for reads only.
- **Never touch the user's running services** or their clone's working tree.
  Read code through `git show {ref}:{path}` or a detached worktree in the
  scratchpad, removed at the end.
- **Quick tier is the default.** Read-only triage, plus reproductions that
  need no build and finish within about 5 minutes. Any build, any download
  over a few hundred MB, and any run expected to take longer is ask-first.
- **Every number in the report comes from a command run this session**, or is
  labelled an estimate.
- **Plain language**, no jargon. No em dashes or en dashes anywhere in the
  output.
- **A question from the user mid-run is a question.** Answer it and keep
  going. If it suggests they may want a change of course, ask in one line;
  do not stop jobs or cut scope on a guess.

## Phase 0: Setup

1. Set `R={owner}/{repo}` and the contributor. Get the default branch:
   `gh api repos/$R -q .default_branch`.
2. **Notes folder**: `~/repo-issue-scout/{owner}-{repo}/` unless the user names
   another. Read the newest earlier `scout-*.md` there, if any. Carry forward
   only its durable rejects (fixed in a commit, epic, owner-only, blocking
   label) unless the issue was updated since. Re-check claim and open-PR
   rejects every run: a PR closing or a claim lapsing does not always bump the
   issue's update time.
3. **Find a clone.** Look for a local clone with a remote pointing at `R`
   (check the current directory, then `~/{repo}` and `~/src/{repo}`). If found,
   `git fetch {remote} {default}` and read code from `{remote}/{default}`. If
   none, check the size first (`gh api repos/$R --jq .size`, in KB; over a few
   hundred MB is ask-first), then make a blobless clone with no checkout in
   the notes folder, since all code is read with `git show`:
   `git clone --filter=blob:none --no-checkout https://github.com/$R {notes}/src`.
   It is kept between runs; give its size in the report.

## Phase 1: Gate on PR access

Run these before any issue triage. All are read-only.

1. `gh api repos/$R --jq '{archived, has_pull_requests, pull_request_creation_policy, pushed_at, web_commit_signoff_required}'`.
   `pull_request_creation_policy` other than `all`, `archived: true`, or
   `has_pull_requests: false` means outsiders cannot open PRs.
2. Recent PRs from outsiders:
   `gh api "repos/$R/pulls?state=all&per_page=50" --jq '.[] | [.number, .user.login, .author_association, .created_at, .state, .merged_at] | @tsv'`.
   Outsiders are `CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, `FIRST_TIMER` and
   `NONE`. None in the last 14 days is a risk to report, not a block on its
   own (small repos are quiet). Outsider PRs that are consistently closed
   without merge are a block signal.
3. Refusals: `gh search issues --include-prs --repo $R collaborator --limit 20`
   and the same for the phrases `'"PRs disabled"'` and
   `'"cannot open a pull request"'` (inner quotes keep them phrases); read any
   hit from the last 90 days. Refusals usually sit on closed outsider PRs.
4. **Gates in the docs.** Do phase 2 step 1 (read the guides) now, and judge
   them here: no outside contributions, a CLA, DCO sign-off, issue-first or
   design-first rules, an AI policy. An outright ban on AI-assisted PRs is a
   block, since this skill's user works through an agent; limits or
   disclosure rules are gates.
5. Activity: the last push, and the date of the last merged PR
   (`gh pr list -R $R --state merged --search 'sort:updated-desc' --limit 5 --json mergedAt`,
   then take the latest).

If a block signal shows (the policy fields, a refusal from step 3, outsider
PRs closed without merge, a guide that forbids outside or AI-assisted PRs), or
the answer is unclear, stop and report what you found, unless the user has
said to go ahead anyway. Do not continue with a caveat. A CLA or DCO is not a
block; list it as a gate in the report.

## Phase 2: Learn the bar

1. (Done in phase 1.) Read the repo's own guides from the default branch: AGENTS.md (or
   CLAUDE.md), CONTRIBUTING, any AI-contribution policy, the PR template, and
   any review checklist or style guide they link. They often live under
   `.github/` or `docs/`, so list them first:
   `git ls-tree -r --name-only {ref} | grep -iE 'contribut|agents|claude\.md|ai_|policy|review|pull_request_template'`.
2. Read 2 or 3 of the user's merged PRs here
   (`gh pr list -R $R --author {user} --state merged --limit 5`, then
   `gh pr view N -R $R --json title,body,files,reviews`). If they have none,
   read 2 or 3 recent merged PRs from outsiders instead. Note what evidence
   got them accepted.
3. Write the **acceptance bar** once, as a short list: the test that must
   fail before and pass after, the lint and format commands, the scoped test
   command, any conformance or benchmark gate, and any doc or changelog rule.
   Every candidate is measured against it.
4. Collect the user's own work in flight, to exclude later:
   - `gh pr list -R $R --author {user} --state open --json number,title,closingIssuesReferences,body`;
   - branch names on their fork and in the local clone that carry an issue
     number (`fix/1234-...`). A fork often mirrors every upstream branch, so
     do not treat each fork branch as the user's work; match numbers only.

## Phase 3: Filter open issues

1. Pull every open issue with its comments:
   `gh issue list -R $R --state open --limit 500 --json number,title,labels,assignees,author,createdAt,updatedAt,comments,closedByPullRequestsReferences,body`.
   Save it to the scratchpad and work from the file with `python3` (`jq`
   itself may not be installed). If there are
   more than about 150, narrow first by the user's focus, helpful labels
   ("good first issue", "help wanted", "bug") and activity in the last 90
   days, and say how many you set aside unread.
2. Open PRs that reference an issue:
   `gh pr list -R $R --state open --limit 1000 --json number,title,body,author,closingIssuesReferences`;
   an issue counts as referenced if it appears in `closingIssuesReferences`
   or as `#N` (on a word boundary, so `#12` does not match `#123`) in a PR
   title or body. A bare mention in a body can be a
   passing link, so glance at that PR's title and files before treating it
   as overlap. Also check each issue's `closedByPullRequestsReferences` for
   open PRs. This bulk pass misses `owner/repo#N` and URL references, so
   step 4 rechecks each survivor's timeline.
3. **Exclude**, and record the reason for each:
   - an assignee is set;
   - **claimed in a comment within the last 14 days** ("I'll take this",
     "working on it", "can I pick this up?" with a maintainer yes), unless the
     claimer later dropped it; read the comments, the assignee field is often
     empty. Go by the latest comment from the claimer: people withdraw and
     re-claim. An older claim with no follow-up stays in, with a risk note.
     The bulk pull returns only the first 100 comments; if an issue shows 100,
     fetch the rest before judging
     (`gh api repos/$R/issues/N/comments --paginate --jq '.[] | [.user.login, .author_association, .created_at, .body] | @tsv'`);
   - a maintainer or a bot is actively landing fixes on it (recent comments
     linking commits or partial PRs);
   - an open PR references it;
   - the user already has a PR or a branch for it;
   - epics, roadmap or tracking issues, and owner-only work (hosting, data,
     infrastructure, releases, design decisions only maintainers can make);
   - labels that block outside work (wontfix, needs design, blocked, question,
     duplicate), or a maintainer comment saying not to work on it;
   - the user's skips, the focus's exclusions, and the previous run's rejects
     with no update since.
4. Keep the survivors. If more than about 12 remain, take the 12 that best
   match the focus and the evidence the repo accepts; note the rest as
   "not examined". For each one kept, check the timeline for open PRs that
   mention it in any form, and exclude on a hit:
   `gh api repos/$R/issues/N/timeline --paginate --jq '.[] | select(.event=="cross-referenced") | .source.issue | select(.pull_request != null and .state=="open") | [.number, .user.login, .title] | @tsv'`.

## Phase 4: Verify against the default branch

For each survivor:

1. **Find the code path** the issue describes and read it at
   `{remote}/{default}`. Cite `file:line`.
2. **Check for a fix already landed**, scoping history to the files from
   step 1 (on a blobless clone an unscoped `-S` downloads every changed file):
   `git log {remote}/{default} --oneline --since='{issue createdAt}' -- {file}`,
   `git log {remote}/{default} --oneline -S '{symbol}' --since='{issue createdAt}' -- {file}`,
   and `git log {remote}/{default} --oneline --grep='#{N}'`. If the issue
   names a version, search from that tag instead (`{tag}..{remote}/{default}`),
   since reporters often file against a release main has already fixed. A
   keyword search of merged PRs helps too
   (`gh pr list -R $R --state merged --search '{keyword}' --limit 10`).
   Read the latest comments too: a "checked against main" note from a
   maintainer or contributor often says what already landed, even on an issue
   still open. Fixed in whole moves it to the rejected list with the commit.
   Fixed in part stays in only if what remains is real outside work; if the
   leftover is a choice the maintainers already made (help text, docs or a
   comment saying so), reject it and cite that.
3. **Reproduce only where cheap.** In the quick tier that means no build and
   under about 5 minutes, for example a published release binary or package
   whose checksum you verify against the release's published sums. Running
   one runs third-party code, so say what you are about to run first.
   Install packages only into a throwaway environment in the scratchpad (a
   venv, `npm --prefix {scratch}`, `cargo install --root {scratch}`), never
   globally or into the user's clone. Each run:
   - uses a free port, a fresh data directory in the scratchpad, and a
     timeout, and runs in the background;
   - never stops, restarts, or reuses a port of a service the user runs
     (check `ss -ltnp` or the platform equivalent first);
   - records the exact command and its output.

   Anything costlier is noted as "repro needs a build" for the deep tier.
4. **Assign a status**: *reproduced* (with the command, the release tag and
   its date, plus the main code read at file:line, since a release can trail
   main), *confirmed by reading* (with file:line), or *unverified* (with why).

## Phase 5: Report, then stop

Write the report to `{notes}/scout-{YYYY-MM-DD}.md` and return it in chat.

**Header**: repo, default branch and its commit, contributor, depth, focus,
the PR-access verdict with its evidence, and the acceptance bar.

**Shortlist**, 5 to 8 candidates, best first. Never pad it: fewer is fine
if fewer are worth it. If fewer than 3 survive, say the pool is thin and name
ways to widen it (a different focus, older claims with no PR, leftover parts
of partly fixed issues). For each:

- the issue link and title;
- two plain sentences: what is wrong for a user, and the likely fix;
- status: reproduced (command), confirmed by reading (file:line), or
  unverified;
- size (small, medium or large), the areas it touches, and which repo gates
  apply;
- the test that would prove the fix;
- risks: design questions, overlapping work, disputed scope, stale claims.

**After the list**:

1. A table: `# | Issue | Value | Size | Confidence | Matches focus`.
2. One top pick, with the reason.
3. **Checked and rejected**, one line each: issue, reason (claimed by whom
   and when, open PR #, fixed in commit `sha`, epic, owner-only, user's own
   PR #). This is what the next run skips.
4. Counts: open issues pulled, set aside unread, excluded by each rule,
   examined, shortlisted.

Then offer the deep tier for the top 1 or 2 candidates and stop. Do not start
it without a yes. Remove any detached worktree you made.

## Deep tier (only on the user's yes)

For the named candidates only:

1. **Check disk first**: `df -h` on the target filesystem. Below 30 GB free,
   or below a threshold the user named, stop and ask.
2. Estimate the build's time and size from the repo's docs or CI config and
   say it before starting.
3. Build from a fresh detached worktree of `{remote}/{default}` in the
   scratchpad, never the user's working tree. Build only what the candidate
   needs (the one crate, package or target), into a private target directory
   in the scratchpad. Run it in the background with a timeout.
4. Reproduce under the same rules as phase 4.
5. Delete the private target directory and remove the worktree
   (`git worktree remove`, then `git worktree prune`) when done, and report
   the disk reclaimed.
6. Update the report file with the new status and command.

## Example

`/repo-issue-scout xerj-org/xerj quick indexing and performance bugs` gates on PR
access, learns the repo's test and lint bar from the user's merged PRs, drops
issues claimed in comments or already fixed on `main`, and returns a ranked
list where indexing and performance issues rank first.
