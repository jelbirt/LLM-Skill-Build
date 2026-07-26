---
name: kickoff
description: Generate a complete, copy-ready kickoff prompt for a new Claude Code session from a short workstream description - orient-first checks, inherited state, ordered work items, hard stops, and definition of done, returned in one fenced code block. Use whenever the user wants to spin up, kick off, or brief a new session or workstream, says "kickoff", "write a kickoff prompt", "prep a session for X", or "hand this plan to a fresh session", even if they don't say "kickoff" explicitly.
argument-hint: [short workstream description]
---

# kickoff

Turn a short workstream description into a complete kickoff prompt a fresh
Claude Code session can execute without any other context. The prompt is the
deliverable - return it inline in one fenced code block, copy-ready. Do not
write it to a file unless explicitly asked.

## 1. Gather context (before writing anything)

The workstream description may be passed as `$ARGUMENTS`. If absent, ask for it.

Ground the prompt in the TARGET repo's reality - never hardcode assumptions
from any one project:

1. Read the target repo's `CLAUDE.md` (and anything it declares authoritative,
   e.g. a SPEC or todo file). The generated prompt must tell the successor to
   honor those conventions, and must not contradict them.
2. Run `git log --oneline -5`, `git status`, `git branch --show-current` in the
   target repo. Record the expected HEAD commit and branch so the successor can
   verify it landed in the right place.
3. Identify inherited state: what is done, in flight, blocked, or decided.
   Pull from the conversation, todo/state docs, and recent commits. Trust
   commits over docs where they disagree.
4. Ask the owner (or determine from repo docs): **does this project have
   shared mutable state, and which workstream currently holds the pen?**
   Examples: an append-only ledger, a registry, a shared database or cache,
   a deploy environment. If yes, the prompt must name the current pen-holder
   and forbid the new session from writing that state without it.
5. If anything essential is missing (branch strategy, review policy, scope
   boundaries), ask one round of questions rather than guessing.

## 2. Compose the kickoff prompt

Required sections, in order:

1. **Mission** - what this session exists to do, in a paragraph. Name the
   step/phase it completes. State explicitly what kind of workstream it is
   (research, tooling, docs...) and what it must NOT touch.
2. **Environment** - cwd, branch, remote, sibling worktrees or checkouts to
   leave alone, how changes land (PR? direct commit? review policy), and a
   note that the repo `CLAUDE.md` auto-loads and is binding.
3. **Orient first** - concrete verification steps to run before any writing:
   expected `git log` HEAD and branch, clean-tree check, which docs to read
   in full vs skim, and the rule "trust commits over docs where they
   disagree."
4. **Inherited-state summary** - what is already done, decided, in flight,
   or blocked; include the pen-holder line from step 1.4 when the project
   has shared mutable state.
5. **Ordered work items** - numbered or tabled, each with a deliverable and
   enough spec to execute without guessing. Mark prepare-only items clearly.
6. **Hard stops** - owner gates marked ⛳, commit/PR policy (including any
   no-attribution-trailer rule), scope guards, and what to do when a task
   seems to require crossing one (stop and ask).
7. **Definition of done** - verifiable outcomes: what must be demonstrated,
   green, open, or reported when the session ends, including the closing
   report the owner expects. Make it **machine-checkable wherever possible**:
   an "Acceptance checks" list of concrete commands with their expected
   result (e.g. `uv run pytest -q` exits 0; `grep -rn "X" src/` returns
   empty; `gh pr checks N` all pass; `test -x ~/bin/tool`), so the session
   can verify completion itself and the owner can re-verify in seconds.
   Reserve prose-only criteria for genuinely unautomatable outcomes
   (owner judgment, review quality), and keep those few and explicit.

Do NOT append standing disclaimers or footers to the prompt, PR text, or
chat messages — the owner does not want them there. Repo conventions about
disclaimers apply to the project's own research/output artifacts, not to
session prompts or PR bodies.

## 3. Deliver it

- Output the entire generated prompt in a **single fenced code block** so the
  owner can copy it in one motion. Use a four-backtick outer fence when the
  prompt itself contains triple-backtick fences.
- After the block, add at most 2-3 sentences: anything you had to assume, and
  any open question the owner should settle before pasting it.
