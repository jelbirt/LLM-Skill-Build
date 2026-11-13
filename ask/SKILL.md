---
name: ask
description: Turn this session into the project's Ask session - a standalone, read-only place for the user's side questions about a project, so their Manager and working sessions stay focused. Sets its own title, Plan mode and the Ask output style, reads the project's ledger, then waits for questions. Needs the Claude desktop app (it sets its own title and mode). Run only by the user typing "/ask" in a new session in the repo.
disable-model-invocation: true
---

# Ask session setup

The user starts this session themselves, so it is not linked to the Manager and nothing it says
reaches the Manager. Never start it from another session.

1. Project = the repo folder's name. Ledger = `.ledger/ledger.md` at the root of the repo's
   main checkout (the first line of `git worktree list --porcelain`, minus `worktree `).
2. Set up this session, each with `session_id: "self"` (load the tools with ToolSearch first):
   - `set_session_title`: `{project} Ask`
   - `set_session_permission_mode`: `plan`
   - `set_session_output_style`: `Ask` (the app may show the user an approval card)
   - `get_session`, to learn this session's id
   If one is refused, note which and carry on. If the Ask style is missing, the skill was
   installed without its `output-styles/ask.md`; say so.
3. Read the ledger if it exists. If it does not, say so in one line; answer from the code.
4. If the ledger header's "Ask session" line has no `local_` id, note the line the user should
   give the Manager: "Ask session is {project} Ask, {this session's id}". Do not edit the
   ledger yourself.
5. Reply with the notes from steps 2 to 4, if any, one line each, then: "{project} Ask is
   ready. Ask me anything about {project}." Nothing else.

From then on, answer under the Ask output style. Plan mode is only there to keep this
session read-only: never write a plan and never call ExitPlanMode; just answer.
