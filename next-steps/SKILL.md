---
name: next-steps
description: Figure out the logical next steps for the current project by delegating a token-efficient review to a subagent that reads the repo state, git history, and the most recent plan/roadmap docs, then returns a prioritized short list. Use whenever the user asks "what's next", "what should I work on", "next steps", "where did we leave off", "what's left", "help me plan the next session", or seems unsure how to move the project forward — even if they don't say "next-steps" explicitly.
model: sonnet
argument-hint: [optional focus area, e.g. "testing" or "v2 features"]
---

# Next steps

Determine the most productive next steps for this project and report them as a
short prioritized list — without burning main-session context on the review.

## Instructions

1. Distill the current conversation into at most 5 bullets: the project's goal,
   decisions made this session, work completed, and known blockers. If the
   session is fresh with no meaningful history, write "no session context" and
   let the repo speak for itself. Do not paste raw transcript or file contents.

2. Launch ONE `general-purpose` agent with `model: sonnet`, filling in this
   prompt (replace braces; include the focus line only if the user gave `$ARGUMENTS`):

   ```text
   You are reviewing a project to recommend next steps. Work only inside {cwd}.
   Be economical: prefer git commands, file listings, and targeted reads of
   recent files over reading the whole repo.

   Session context from the requesting session:
   {conversation bullets}

   Focus area requested by the user: {arguments}

   Steps:
   1. Run `git status` and `git log --oneline -15` (and `git diff --stat` if
      dirty) to see the current state and trajectory.
   2. Find planning docs: README, TODO*, ROADMAP*, PLAN*, IDEAS*, CHANGELOG,
      and anything similar in docs/. Sort by last modified; read the most
      recent 2-3 closely, skim the rest. Treat newer docs as overriding older ones.
   3. Compare the plans against what actually exists in the repo to spot the
      gap: stated goals not yet built, half-finished work (dirty files, TODOs
      in code, stub files), and anything the session context says is blocked.
   4. Decide the 3-6 next steps that most move the project toward its goals.
      Order by priority: unblock > finish in-progress > highest-value new work.

   Return ONLY this, as raw markdown (it is data, not a chat message):
   ## State
   {2-3 sentences: where the project stands}
   ## Next steps
   {numbered list; each item: one-line action, why now, entry-point file(s),
   rough size (S/M/L)}
   ## Watch out
   {0-3 bullets: risks, contradictions between docs, or stale plans — omit
   the section if none}
   ```

3. Relay the agent's report to the user essentially as-is — do not re-verify
   by re-reading the repo yourself. Add at most one sentence connecting it to
   the current session, and offer to start on item 1.

## Notes

- If the subagent finds no planning docs, its recommendations come from git
  history and code state alone — say so in the relay so the user knows the basis.
- If the user's focus argument conflicts with what the roadmap prioritizes,
  present both rather than silently following one.
