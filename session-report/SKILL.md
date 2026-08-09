---
name: session-report
description: Write the status report this session sends back to the main session that delegated the work - the scope it was given, what it accomplished, exactly what changed on disk, how that was verified, what remains outstanding, and how the remainder connects to the tasks the receiving session is managing - in one fenced code block. Use whenever a delegated, side, or parallel session has to report up, or the user says "session report", "report back", "write up what you did", "status synopsis", "summarize this session for the main session", or "what do I paste back". Written for a reader that already has the project in context and merges into a session that keeps running, so use handoff instead when the next session starts empty.
argument-hint: [optional focus, or what the main session asked for]
---

# session-report

Write the report THIS session sends back up to the session that delegated the
work. The reader is a running Claude Code session that already has the project
in context — it does not need orienting, only updating.

Anything the user wants emphasized: $ARGUMENTS

## What this is not

The reader already knows the project. Do not restate its shape, re-derive its
architecture, explain decisions it made itself, or open with a preamble. No
orient-first block — that is `handoff`'s job, for a successor starting empty.
Every line should be something the reader could not already know.

## Instructions

1. **Re-check reality before writing.** Report the repo, not your memory of it.
   - Uncommitted work: `git status --short` and `git diff --stat HEAD`.
   - Committed work needs a base commit, so establish one: the merge-base with
     the default branch (`git merge-base HEAD origin/main`, substituting the
     repo's actual default branch) when this session worked on its own branch,
     otherwise the newest commit in `git log --oneline -20` that predates the
     session. Then `git log --oneline {base}..HEAD` and
     `git diff --stat {base}..HEAD`. If no base can be established, say that
     in the report rather than guessing at what this session committed.
   - `git branch --show-current`, un-pushed commits (`git status -sb`), and
     open PRs.
   - Anything created outside git — scratch files, generated artifacts,
     installed tooling — with absolute paths.

   A file you changed and forgot is the most damaging thing a report of this
   kind can omit.

2. **Compose the report** with these sections, in this order. Keep every one —
   an empty section is stated as empty, never dropped, because a missing
   section reads as "nothing to report" rather than "not checked."

   - **Scope** — what this session was asked to do, in one or two lines, plus
     anything in that ask it deliberately did not do and why. When
     `$ARGUMENTS` carries the delegating ask itself, that text is the source
     of truth here; otherwise reconstruct it and say it was reconstructed.
   - **Done** — what was accomplished, against that scope. If the scope had
     five items and three landed, say so here rather than letting the reader
     infer it from what is missing.
   - **Changed on disk** — an explicit list of paths, one per line, each with
     a few words on what changed. Paths, not prose; taken from git in step 1,
     not from recollection. Include what was committed vs. left dirty, the
     branch, and anything written outside the repo. Say "no files changed"
     outright when that is the case.
   - **Verified** — for each claim of working, the evidence: the command run
     and its actual result. Anything not verified is listed as not verified.
     Never let an unverified claim sit next to a verified one unmarked — a
     reader merging this into live context will act on both equally.
   - **Outstanding** — what remains, each item labelled with why it remains:
     blocked (on what), deferred (by whose call), out of scope, or tried and
     rejected (with why). That last label is not filler — an approach this
     session ruled out is the one thing that stops the main session spending
     its own context rediscovering it.
   - **Back to the main session** — the connective tissue, and the reason this
     is a report rather than a summary: which outstanding items belong on the
     reader's task list, what it should stop doing or no longer assume, what
     moved under it (shared files, branches, schemas, state it also touches),
     and any decision now waiting on it, marked ⛳.

3. **Output the whole report in a single fenced code block**, copy-ready, so
   it can be pasted into the main session in one motion. Use a four-backtick
   outer fence if the report itself contains triple-backtick fences. Do not
   write it to a file unless asked.

4. **After the block**, add at most one line, marked ⛳ — and only for
   something the owner must act on personally, not the receiving session.

## Notes

- Terse beats complete. This lands in a context window that is already full;
  every line spent on what the reader knows costs a line it needed.
- Report failures and dead ends as plainly as successes. A session that tried
  an approach and abandoned it saves the main session from retrying it, but
  only if the report says so.
- If this session was never given a scope — the user just started working —
  say that in **Scope** rather than inventing a mission after the fact.
- If there is no delegating session at all, say so and stop. Offer `handoff`
  when the next session starts empty, or a plain chat summary when the user
  just wants to know where things stand. Do not address a reader that does
  not exist.
- **Back to the main session** comes last on purpose, even though it is what
  the reader acts on first. Writing it after the other five forces it to be
  derived from them rather than from memory, which is what keeps it honest.
- Where the session's own narrative and git disagree, git wins. Say what the
  repo shows and flag the discrepancy.
