---
name: sync-profile-readme
description: Regenerate the project table in a GitHub profile README from your pinned repositories, so repo descriptions stay the single source of truth and the profile stops needing hand-maintenance. Use whenever the user wants to sync, refresh, or update their profile README, says "update my profile README", "my pinned repos changed", "regenerate the projects table", or "my profile table is stale", or has just pinned, unpinned, published, or re-described a repo. Reads pins through the GitHub GraphQL API (the REST API does not expose pinned items), rewrites only the region between the PROJECTS:START and PROJECTS:END markers, never rewrites a hand-written row, never deletes a row, and always shows a diff for confirmation before writing.
model: sonnet
argument-hint: [optional path to the profile repo or its README]
---

# sync-profile-readme

Keep the project table in a GitHub profile README in step with the account's
pinned repositories. One job: rewrite the rows inside a marked region. It does
not manage pins, write repo descriptions, or edit anything else in the README.

Path the user gave, if any: $ARGUMENTS

## The row model

Every row in the managed table is one of three kinds, and the difference is a
single HTML comment that GitHub never renders:

| Kind | Marked with | On every run |
| :--- | :---------- | :----------- |
| **Generated** | `<!-- synced -->` | Rewritten from the repo's GitHub description |
| **Hand-written** | nothing | Left exactly as written |
| **Unpinned** | either | Kept in place and reported — never deleted |

The marker goes on the rows the tool *wrote*, not on the ones the human wrote,
so the safe default is "don't touch it": forgetting a marker can never cost
someone their prose, and the annotation sits on the row it governs rather than
in a companion file that drifts out of sync. To take ownership of a generated
row, rewrite its text and delete the marker; to hand it back, delete the row and
re-run.

## Instructions

1. **Run the dry run.** It writes nothing.

   ```bash
   "${CLAUDE_SKILL_DIR}/scripts/sync-profile-readme.sh"
   ```

   Add `--readme {path}` when the user named a repo or README, or when the
   session is not inside the profile repo. Add `--user {login}` only to target
   an account other than the authenticated one.

2. **Read the plan back to the user**, then show the diff verbatim. Call out by
   name, in plain language:
   - rows being **added** because a repo was newly pinned,
   - rows being **refreshed** because a description changed upstream,
   - any repo **in the table but no longer pinned** — say it is being kept and
     that removing it is their call, not the tool's,
   - every `warn` line (archived repo, missing description, duplicate row).

3. **Stop and get confirmation.** Never apply without it. If the run reports
   `RESULT: no-changes`, say so and stop — there is nothing to confirm.

4. **Apply**, once confirmed:

   ```bash
   "${CLAUDE_SKILL_DIR}/scripts/sync-profile-readme.sh" --write
   ```

   Repeat any `--readme` / `--user` flags from step 1.

5. **Report** what changed and leave the commit to the user unless they ask for
   one. A second run must print `RESULT: no-changes` — if it does not, something
   is wrong; say so rather than running it again.

## When it stops

Each failure names its own fix; relay it rather than working around it.

| Message | What the user does |
| :------ | :----------------- |
| `gh` not installed / not authenticated | Install the GitHub CLI, run `gh auth login` |
| needs bash 4 or newer | Stock macOS ships bash 3.2 — `brew install bash` and run it with that |
| not in the profile repo | `cd` into the `{login}/{login}` clone, or pass `--readme` |
| no managed region | Add the two markers around the table (the error prints them) |
| no pinned repositories | Pin repos on the GitHub profile page, then re-run |
| region contains prose | Move the prose outside the markers — this manages a table |

Do not add the markers, create the README, or restructure someone's file
uninvited. Show them where the markers go and let them place them.

## Notes

- Pinned repositories are only available through the **GraphQL** API. The REST
  API has no pinned-items endpoint, so there is no simpler call to fall back to.
  GitHub caps pins at 6.
- Everything outside the markers is copied through byte for byte. The table's
  header and separator rows live *inside* the region and are preserved verbatim,
  so a customized column heading survives — do not move them above the start
  marker, which would make the region unparseable.
- A repo's GitHub description is the source of truth for generated rows. If a
  row's wording is wrong, fix the repo's About field and re-run; hand-edit the
  row only when it deserves prose the description should not carry.
- Rows are matched by the repo URL — owner and name, not the link text — so a
  row that labels `AudioFY-Data` as "AudioFY" is still recognized as that repo's
  row, and a same-named repo under another owner is never mistaken for it. A
  custom label survives only on a hand-written row; a generated row's label is
  always the repo name.
- Row order is never shuffled. Existing rows stay put; a newly pinned repo is
  appended after the last pinned row.
