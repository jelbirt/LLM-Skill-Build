# <project> ledger

- Repo: `<path>` (<GitHub owner/name>)
- Plan docs: `<path or none>`
- Manager session: not started
- Ask session: not started
- Last checked against git and GitHub: <date>

## Open asks

The user's requests, word for word, in the order they made them. An ask closes only with a pointer
to where it was answered (a message date, a PR, a commit). Closed asks move to the bottom
of this table and are deleted once a week.

| # | Date | The user's words | Status | Answered where |
|---|---|---|---|---|

## Waiting on the user

Numbered one-line questions. Each says what is blocked until they answer.

1.

## Workstreams

| Name | Session | Branch | PR | Status | Next step |
|---|---|---|---|---|---|

## Decisions

Dated, in the user's words where possible. Plan-level decisions that live in the plan docs are
linked, not copied.

- <date>: <decision> (<where it was made>)

## Names

Every term a session coins gets one plain line here before it is used with the user. If a term
has no entry, describe the thing instead of naming it.

| Term | Plain meaning |
|---|---|

## Later

Things the user set aside, with when to pick each up. Items already in the plan docs are linked.

## PR log

Every PR, including bot PRs. Type is one of: actions-bump, dep-patch, dep-minor, dep-major,
docs-only, tests-only, config, code. Outcome is one of: merged as-is, merged after changes,
closed. "After changes" means the merged head differs from the head SHA in the Note, which
the Manager records when it sends the packet.

| PR | Opened | Type | Author | Outcome | Review rounds | Note |
|---|---|---|---|---|---|---|

## Review rounds

Open PRs only; a PR's rows are deleted when it merges or closes (git history keeps them).
One row per finding, so the integration reviewer can spot a problem coming back.

| PR | Round | Head | Tier | Finding (file:line, one line) | Fixed in |
|---|---|---|---|---|---|
