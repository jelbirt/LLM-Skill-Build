---
name: handoff
description: Emit a successor-session briefing from the CURRENT session - exact state left behind, in-flight and promised-but-undone work, open owner gates, honest uncertainties, standing invariants, and orient-first instructions - in one fenced code block. Use whenever the user wants to wrap up, hand off, or continue in a fresh session, says "handoff", "write a handoff", "brief the next session", "I'm about to /clear", or asks what a successor needs to know, even if they don't say "handoff" explicitly.
---

# handoff

Write the briefing a successor session needs to continue THIS session's work
with zero shared memory. The audience is a fresh Claude Code session (or the
owner pasting into one). Be honest about what is unfinished and uncertain -
a flattering handoff is a defective one.

## Instructions

1. Take stock before writing. Re-check reality rather than trusting your own
   narrative of the session: run `git status`, `git log --oneline -5`, and
   `git branch --show-current`; list uncommitted files, un-pushed commits,
   open PRs, and anything created outside git (home-dir files, scratch
   artifacts) that the successor would not find on their own.

2. Compose the briefing with these sections, in order:
   - **State left behind** - branch, HEAD commit, clean/dirty tree, open
     PRs with status, artifacts created outside git (absolute paths).
   - **What was done** - completed work, tersely, with where it lives.
   - **In flight / promised but undone** - anything started, planned, or
     told to the owner as "will do" that is not finished. Never silently
     drop these; this section is the whole point of a handoff.
   - **Open owner gates** - decisions awaiting the owner, marked ⛳, with
     what each is blocking.
   - **Honest uncertainties** - things not verified, tests not run, guesses
     made, or areas where the successor should re-check rather than trust
     this briefing.
   - **Standing invariants** - the rules the successor must keep honoring
     (from the repo's CLAUDE.md/spec plus any session-specific constraints,
     e.g. who holds the pen on shared mutable state).
   - **Orient first** - the exact commands and reads the successor should do
     before writing anything: verify expected HEAD/branch, which docs to
     read, and "trust commits over docs where they disagree."

3. Output the entire briefing in a **single fenced code block**, copy-ready.
   Use a four-backtick outer fence if the briefing contains triple-backtick
   fences. Do not write it to a file unless explicitly asked.

4. After the block, note in 1-2 sentences anything that belongs in the
   owner's hands rather than the successor's (e.g. an approval only the
   owner can give).
