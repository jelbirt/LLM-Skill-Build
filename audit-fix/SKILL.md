---
name: audit-fix
description: Implement fixes for findings from the preceding /audit report, parallelizing via subagents grouped by non-overlapping file scope. Accepts optional severity/category filter.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write, Agent
argument-hint: [optional severity/category filter — e.g., "critical,high", "P0", "security", "P1 performance"]
---

# Skill: audit-fix

Implement fixes for issues surfaced by a prior `/audit` run. Parcel work to subagents grouped by **non-overlapping file scope** (never one-agent-per-finding — that causes edit conflicts), verify each group's work, then return a consolidated status report.

---

## Step 0 — Locate the findings table

Read the **most recent `/audit` findings table in this conversation's context** (the markdown table with `Severity | Area | Issue | File | Fix | Effort` columns).

If no audit table is present in context, stop and say:
> No `/audit` findings table found in this conversation. Run `/audit` first, or paste the table.

Do **not** re-run `/audit` yourself.

---

## Step 1 — Parse the filter argument

If `$ARGUMENTS` is provided, use it to filter the findings table.

Accept flexible forms (case-insensitive, comma- or space-separated):
- **Severity tokens:** `P0`, `P1`, `P2`, `P3`, `critical`, `high`, `medium`, `low`
- **Area tokens:** `security`, `performance`, `ux/ui`, `accessibility`, `data`, `code quality`, `docs`, etc. — match the Area column
- **Combined:** e.g., `"P0 P1 security"` — AND across token types (severity ∈ {P0,P1} AND area matches security); OR within a type
- **Aliases:** `critical` → P0, `high` → P1, `medium` → P2, `low` → P3

If `$ARGUMENTS` is empty, default to **P0 Critical + P1 High**.

**Pipeline Candidates are excluded from dispatch by default.** A finding is a Pipeline Candidate if the audit report flagged it as one, or if it matches the criteria (Effort L, architectural/cross-module fix, or design decisions needed). Do not quick-fix these — list them in the banner as deferred and route them to the dev pipeline (`/plan` → `/build auto`, with `/spec` first if requirements need pinning down). Include one in dispatch only if the user explicitly asks for it (e.g., names the finding or says "including pipeline candidates").

Print a one-line banner:
```
🛠️  Audit-fix — targeting: <resolved filter> | <N> findings selected | <M> deferred to pipeline
```

If 0 findings match, stop and say so — do not silently broaden the filter.

---

## Step 2 — Group by non-overlapping file scope

**Critical rule:** each subagent owns a disjoint set of files end-to-end. Never dispatch two subagents that could touch the same file.

1. For each selected finding, collect its file path(s) from the `File` column (a finding may cite multiple files).
2. Merge findings whose file sets overlap into the same group (transitive closure — if A shares a file with B, and B shares with C, A/B/C form one group).
3. Each resulting group = one subagent's workload.

If a finding's fix will likely touch files beyond those cited (e.g., "extract shared validator" implies new helper files), widen that group's scope conservatively and note the expansion in the dispatch brief.

Print the planned grouping before dispatching:
```
Plan:
  Group 1 (api/users.ts, api/auth.ts): findings #1, #3 → general-purpose
  Group 2 (utils/validate.ts): finding #2 → general-purpose
  Group 3 (README.md): finding #4 → general-purpose
```

---

## Step 3 — Dispatch subagents in parallel

For each group, spawn an `Agent`. Use `general-purpose` by default; route to a specialist only when the fix itself needs specialist judgment (e.g., `security-reviewer` for non-trivial auth fixes).

Launch all group agents in a **single message with multiple `Agent` tool calls** so they run concurrently.

Each dispatch brief must include:

1. **The specific findings assigned** — full row content, not just IDs
2. **File scope** — exact list of files this agent owns; explicitly state *"other agents own other files concurrently; do not touch anything outside your scope"*
3. **Project context** — stack, relevant conventions from `CLAUDE.md`, how to run the test suite
4. **No-fabrication rule** — *"If you need information not present in the codebase (API keys, external service behavior, product decisions, ambiguous requirements), STOP and return a flagged question. Do not invent values, mock external systems, or guess."*
5. **Prove-It rule (bug-class findings)** — for any finding describing observable wrong behavior (incorrect logic, security vulnerability, data corruption, broken flow): *first* write a test that reproduces the issue, run it, and confirm it **FAILS**; then implement the fix; then confirm that test passes along with the rest of the scoped suite. A fix whose repro test never failed proves nothing. Exemptions — findings with no observable runtime behavior (docs, dead code, naming/style, comments) and projects with no test infrastructure — must be stated per finding, not silently assumed.
6. **Return contract** — each agent reports: files changed, what was fixed per finding, the repro test path per bug-class finding (or its stated exemption), flagged questions (if any), whether tests/type-check in their scope still pass.

---

## Step 4 — Apply database migrations (if applicable)

**Run this step only if** one or more subagents in Step 3 produced or modified database migration files (e.g., `prisma/migrations/`, `supabase/migrations/`, `alembic/versions/`, `drizzle/`, or raw `migrations/*.sql`). Otherwise, skip directly to Step 5.

### Before running

Database migrations are hard to reverse. **Do not apply them without explicit user confirmation.**

1. List every migration file created or modified in Step 3, with full path and the finding(s) it addresses.
2. Show the migration content (summarize if >100 lines, but always show DDL/schema-change statements in full).
3. Identify the project's migration tooling from its config/scripts, and state the intended target:
   - **Local dev DB** — generally safe, reversible by resetting local state.
   - **Shared/remote DB** — requires explicit user confirmation every time, even if the user previously authorized local runs.
4. Ask the user to confirm before proceeding. Default to **local first** unless the user explicitly states otherwise.

### Running

Use the project's own migration command (from its package scripts, Makefile, or tool docs — e.g., `npx prisma migrate dev`, `alembic upgrade head`, `supabase migration up`). Never use a reset/wipe variant unless the user explicitly asks.

Capture and surface the full CLI output. On failure:
- **Stop** — do not proceed to Step 5 verification.
- Report the error verbatim along with the offending migration file and statement.
- Do not attempt to auto-repair the migration or retry with modifications. Flag for user decision.

### After running

- Confirm the CLI exited cleanly.
- If the local DB was updated, note that the Step 5 test run will hit the new schema — some test failures may be expected if tests reference old columns/tables and weren't updated by the same subagent.
- If a shared/remote DB was updated, flag it prominently in the Step 6 report (dedicated line under "What was done").

---

## Step 5 — Verification pass

After all subagents return, run a thorough verification round yourself:

- Run the **full test suite** (detect from `package.json`, `pyproject.toml`, `go.mod`, etc.). If there's no test suite, say so explicitly.
- Run type-check / lint if configured.
- For each finding, re-read the cited file at the cited line and confirm the fix is present and addresses the issue.
- For each bug-class finding, confirm the reported repro test exists at its path and genuinely asserts the fixed behavior (not a placeholder or a tautology). Surface any finding that leaned on a Prove-It exemption so the user can judge it.
- Look for cross-group regressions: broken imports, duplicate symbols, stale references to removed code, contract mismatches between files owned by different groups.
- For frontend/UI findings, **state that visual/interaction behavior cannot be verified without a browser** — do not claim success on UX behavior you haven't actually exercised.

If any subagent flagged a question, **do not resolve it yourself** — surface it verbatim to the user.

---

## Step 6 — Report

Return in the chat using this structure:

```markdown
# Audit-fix results — <filter applied>

## Summary
<2–4 sentences: what was attempted, what succeeded, what's blocked or pending input>

## What was done
- **Group 1 (files: ...)** — Findings #1, #3 — <one-line summary> — ✅ verified / ⚠️ partial / ❌ blocked
- **Group 2 (files: ...)** — ...

## Migrations applied (if applicable)
- **Target:** <local / remote / n/a>
- **Files:** <list of migration files, or "none">
- **Result:** <success / failure — with CLI output snippet on failure>

## Verification
- Tests: <pass / fail / not present> — <detail>
- Repro tests: <N added, paths / exemptions claimed per finding>
- Type-check: <...>
- Lint: <...>
- Manual code re-read: <confirmed / issues found>
- Unverifiable (requires human): <e.g., UI interaction checks, production data behavior>

## Flagged for your input
<Questions subagents raised; external decisions needed. Verbatim, grouped by finding.
If none: "None — no external input needed.">

## Outstanding / next steps
- Findings deferred (not in filter): #N, #M — run `/audit-fix <filter>` when ready
- Deferred to pipeline: #P — <one-line why> — start with `/plan` then `/build auto` (`/spec` first if requirements need pinning down)
- New issues surfaced during this pass: <list or "none">
- Follow-up tasks: <...>

## Updated findings table
<Re-emit the original table with a new "Status" column: ✅ Fixed / ⚠️ Partial / ⏸️ Deferred / ❌ Blocked>
```

---

## Rules

- **Never** dispatch one agent per finding blindly. Always group by file scope first.
- **Never** dispatch a Pipeline Candidate (Effort L / architectural / design decisions needed) to a quick-fix subagent unless the user explicitly asks — route it to the dev pipeline instead.
- **Never** accept a bug-class fix whose repro test was not observed failing first, unless the agent stated a valid Prove-It exemption.
- **Never** fabricate external values, API responses, business logic, or user-facing copy. Flag and ask.
- **Never** claim UI/interaction verification you haven't actually performed in a browser — state the limitation.
- **Never** commit, push, or merge. This skill ends at "report to user." Commits are the user's call.
- **Never** apply database migrations (any tooling, local or remote) without explicit user confirmation in the current turn. Local vs shared/remote requires separate confirmation — authorizing a local run does not authorize a remote push.
- If the user's filter selects zero findings, stop cleanly — don't fall back to a different filter.
- If the findings table in context predates the current session's most recent code changes, note it at the top of the report — the audit may be stale.
- Respect the original audit's confidence threshold: if a finding looks wrong when you re-read the code, flag it rather than silently skipping.
