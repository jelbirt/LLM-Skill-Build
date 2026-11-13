# Review packet (one per PR, for the user)

The format for every report the user reviews. If `.ledger/packet-example.md`
exists, it is the user's model packet: copy its shape, length and tone, not its content.
Where it differs from the shape below, the shape below wins.

Write it to `.ledger/packets/pr-{n}.md`, with `pr-{n}-details.md` beside it. Never
overwrite one the user has been sent: a new head gets `pr-{n}-v2.md` and `pr-{n}-v2-details.md`,
and so on. In chat, send the user only the status line, the number of decisions, and the packet's
path as a link. After the user answers a decision, update that packet in place (it is not a new
version): rewrite the decision with *Done:* set to their answer, and set the status line.

Assume the user is technical but not a specialist in every part of the code. Write for that reader, not
as documentation. At most 1100 words outside the diagrams; the full record goes in details.

## Shape (these headings, in this order)

1. `# Title`: what the PR changes, in plain words. Not the commit subject.
2. Status line under the title, first sentence bold: `**Ready for your review.**` or
   `**Needs your decision.**`. Then how many decisions wait on the user, and that nothing is merged.
3. At-a-glance table (`| | |`), one row each, label bold: **Area** (the part of the system,
   with a plain gloss), **The change** (one or two sentences), **Why** (the ask or plan item it
   answers), **Size** (files, lines, tests), **Proof** (before and after numbers, each
   explained), **Risk** (low, medium or high, and why in a few words).
4. `## The problem`: a **Background.** paragraph that explains the area and defines every term
   the user may not know, then what happens today against what should happen, then a Mermaid
   flowchart of today's behavior. About 150 words.
5. `## Options`: when there was a real choice, a table of at most three (What it does, For,
   Against), the chosen one in bold. Otherwise "One way to do it:" and a sentence.
6. `## The change`: a Mermaid flowchart of the changed path with the new step marked
   (`style <node> stroke-width:3px`), two or three sentences, and a **Not checked** line for
   anything assumed rather than run.
7. `## Decisions for you`: numbered. Every choice the user might have made differently, and anything
   only they can do. Each: what it means in practice, then *Done:*, *Alternative:* and
   *Recommend:* lines. "None." when there are none.
8. `## Not covered`: a table: What, Why it matters, Own PR? (Yes, small / Yes / Later / No).
9. `## Review`: integration rounds run, counts by tier, loop status (none, stopped: loop at
   round n, or stopped: cap), and each real problem found and what happened to it. Three or
   four sentences.
10. `## Other open PRs`: whether any touches the same code or behavior, in one or two lines.
11. Footer after `---`: PR link and title, branch, head short SHA, a link to the details file.

## Writing rules

- Plain words. Define a term the first time it appears; use the ledger's Names.
- Name code by what it does ("the screen step"), not by its path. File:line pointers, full
  SHAs, logs and command output go in details, never in the packet.
- Explain every number where it appears: "6 of the 8 new tests fail without the fix".
- Diagrams: Mermaid `flowchart LR` or `TD`, at most 8 nodes, labels the user understands.
- A table beats a paragraph for any comparison or list. No em dashes.

## Details file

Everything needed to check a claim, no word limit: the ask or plan item, base and head SHAs,
the file-by-file change list, each check command with its output and exit code, the full
integration review findings by round, overlap evidence, and Verified against Assumed.
Quotes keep their words, but swap any em or en dash for a comma or a hyphen.
