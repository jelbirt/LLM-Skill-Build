---
name: sidebar
description: Answer a tangential side question without bloating the main session - delegate it to a subagent that researches it in its own context (the repo first, reaching out to the web only when the answer isn't in the project) and returns only a tight, cited answer. Use whenever the user asks a side/aside question mid-session, says "sidebar", "side question", "quick aside", "while we're here", "remind me how X works", or wants to look something up about the project's architecture, design, or existing/planned code or infra without spending main-chat context. Prefer this over answering inline so the heavy file-reading stays in the subagent and only the distilled answer returns.
argument-hint: [your-side-question]
---

# sidebar

Answer a side question by delegating it to a subagent, so the research happens in
the subagent's context and only a concise answer returns to the main chat. The
point is efficiency: spend main-session context on the question and the answer,
never on the file-reading in between.

The side question: $ARGUMENTS

## 1. Pick the subagent

Choose by what the question needs, then dispatch with the Task tool:

- **`Explore`** (default) — understanding *existing* code or infra: "how/where does X work", "what does this module do", "where is Y configured". Read-only, search-optimized, reads excerpts not whole files.
- **`Plan`** — design or architecture questions about *planned* or *changing* work: "how would I structure X", "what's the right approach for Y", trade-offs.
- **`general-purpose`** — cross-cutting or multi-step questions that need both searching and reasoning across several areas.

When in doubt, use `Explore`. Spawn **one** subagent — do not fan out for a quick aside.

**Research the repo first; go external only as a fallback.** Tell the subagent to answer from the codebase and project files whenever it can. It may use the web (it has `WebSearch`/`WebFetch`) *only* when the answer genuinely isn't in the project — e.g. external library behavior, a spec, or current best practice — and must then label the externally-sourced claim and cite its URL. For heavyweight, multi-source, fact-checked web research, use `/deep-research` instead.

## 2. Build a lightweight context envelope

Give the subagent just enough to answer well, no more. Keep it to a few lines —
do NOT paste the conversation or dump files. Include:

- **The question**, verbatim or lightly sharpened.
- **One line of orientation** *only if it changes the answer* — e.g. the project/working dir, or what the main session is currently focused on (e.g. "we're mid-refactor of the auth layer; this is an aside").
- **The return contract** (below).

If the question is self-contained, skip the orientation line entirely — the
subagent already has the repo and working dir.

## 3. Instruct the subagent to return tightly

Tell the subagent explicitly to:

- Answer the question directly and concisely — a few sentences or a short list, not a report.
- Cite specifics as `path/to/file.ext:line` so the user can click through.
- Surface only what's needed to answer; omit exploration narrative, file dumps, and dead ends.
- State plainly if the answer isn't found, rather than padding.

## 4. Relay the result

Return the subagent's answer to the user, lightly framed if useful (e.g. "Sidebar
answer:"). Keep your own additions minimal — the value is the distilled answer,
not commentary on it. If the answer is incomplete, offer a focused follow-up
`sidebar` rather than re-investigating inline.
