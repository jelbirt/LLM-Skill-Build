---
name: audit
description: Run a comprehensive project audit organized by severity. Accepts an optional focus area (e.g., "data integration", "UX/UI", "performance", "security").
allowed-tools: Read, Grep, Glob, Bash, Agent
argument-hint: [optional focus — e.g., "data integration" or "accessibility"]
---

# Skill: audit

Run a comprehensive audit of the current project. Return findings as a severity-organized table with actionable remediation.

If `$ARGUMENTS` is provided, treat it as the **focus area** for the audit. The audit should emphasize that dimension but still surface critical issues in other areas. If no argument is provided, run a general audit across all dimensions.

---

## Step 0 — Parse focus

Interpret the focus argument using the routing table below. Adapt to any reasonable focus the user specifies, even if not listed.

| Focus keyword(s) | Emphasize | Route deep dives to |
|---|---|---|
| `data integration`, `data`, `pipelines`, `etl` | Schema correctness, transformation logic, data contract validation, idempotency, migration safety, error handling in pipelines, timezone / null handling | Audit inline (no specialist) |
| `ux/ui`, `ui`, `ux`, `frontend` | Component structure, loading/error states, form UX, responsive behavior, consistency, keyboard nav | `accessibility-reviewer`, `performance-reviewer` |
| `accessibility`, `a11y` | WCAG 2.2 AA, semantic HTML, ARIA, keyboard, focus management, contrast | `accessibility-reviewer` |
| `performance`, `perf` | Render perf, bundle size, N+1 queries, caching, memoization, async patterns | `performance-reviewer` |
| `security`, `sec` | AuthN/Z, input validation, secrets, injection surfaces, OWASP Top 10 | `security-reviewer` |
| `code quality`, `refactor`, `cleanup` | Duplication, cohesion, naming, dead code, type hygiene | `refactor-engineer` |
| `dependencies`, `deps` | Vulnerabilities, freshness, unused packages | Run `/deps-audit` inline |
| `tests`, `testing`, `coverage` | Test suite relevance, coverage gaps, test quality | `/prune-test-suite` skill suggestion |
| `api`, `endpoints`, `backend` | Endpoint contracts, error shapes, validation, auth at boundaries, rate limiting | `security-reviewer` + inline review |
| (none) | All core dimensions equally | `project-auditor` handles |

Print a one-line banner before proceeding:

```
🔍 Audit — Project: <name> | Focus: <focus or "general">
```

---

## Step 1 — Quick project context

Before delegating, gather minimal grounding (keep this under ~1 minute of work):

- Read `README.md` if present
- Read `CLAUDE.md` (root and any nested) if present
- Read `package.json` (or `pyproject.toml`, `go.mod`, `Cargo.toml`, etc.)
- Glob the top-level structure to identify where code lives (`src/`, `app/`, `api/`, `lib/`, etc.)
- Note framework(s), language(s), and rough scale

Print a one-paragraph project summary so the user (and subagent) can confirm you understood what's being audited.

---

## Step 2 — Dispatch to project-auditor

Invoke the `project-auditor` subagent with a brief that includes:

1. **Project summary** from Step 1
2. **Focus area** (if specified) — instruct it to weight findings toward that dimension but NOT exclude critical findings elsewhere
3. **Specialist routing** — tell it which specialist agent(s) to invoke for deep dives based on the focus table above
4. **Output contract** (below) — override the agent's default report format

Also instruct the subagent:
- Ground every finding in specific file:line evidence
- Skip generic best-practice advice that doesn't tie to code you can cite
- If a dimension is clean, say so in one line rather than manufacturing findings
- Confidence threshold ≥ 70 (do not report speculative issues)

---

## Step 3 — Format output

Return the findings in this exact shape:

```markdown
# Audit — <project name>
**Focus:** <focus or "general">
**Stack:** <language/framework summary>
**Overall health:** <one-sentence assessment>

## Findings

| Severity | Area | Issue | File | Fix | Effort |
|----------|------|-------|------|-----|--------|
| P0 Critical | Security | SQL injection via raw concat | `api/users.ts:42` | Parameterize query | S |
| P1 High | Performance | N+1 on user list | `api/users.ts:88` | Batch with `IN()` | S |
| P2 Medium | Code Quality | Duplicated validation logic | `utils/validate.ts:12,44,89` | Extract shared validator | M |
| P3 Low | Docs | README setup steps stale | `README.md:15` | Update install instructions | S |

## Top 3 Actions
1. <Highest-ROI fix — why it matters>
2. <...>
3. <...>

## Pipeline Candidates
<Findings too large or design-heavy for /audit-fix's parallel quick-fix flow.
Reference table rows by number, give a one-line why, and the pipeline entry point.
If none: "None — all findings are /audit-fix-sized.">
- #5 — auth checks duplicated across 4 modules; needs a designed boundary, not a patch → `/plan` then `/build auto` (use `/spec` first if requirements need pinning down)

## Not Covered
- <Area deliberately skipped and why — e.g., "E2E test coverage — no tests directory present">

## Suggested Follow-ups
- Run `@performance-reviewer` on `api/users.ts` for deeper perf analysis
- Run `/deps-audit` to complete the dependency review
- <other specialist handoffs>
```

### Severity scale

- **P0 Critical** — Active security risk, data loss, production breakage. Fix immediately.
- **P1 High** — Meaningful risk or friction. Next sprint.
- **P2 Medium** — Plan-for improvements. This quarter.
- **P3 Low** — Nice-to-haves, minor cleanup. Backlog.

### Effort scale

- **S** — Under 1 hour
- **M** — A few hours to a day
- **L** — Multi-day / requires planning

---

## Rules

- Focus area **weights** findings but does NOT exclude critical issues in other areas (a P0 security bug surfaces even during a performance-focused audit)
- Flag a finding as a **Pipeline Candidate** when any of these hold: Effort is **L**, the fix crosses module/architecture boundaries, or it requires design or product decisions. These belong in the spec-driven dev pipeline (`/spec` → `/plan` → `/build auto`), not `/audit-fix` — say so in the Pipeline Candidates section rather than sizing them down to fit the table's Fix column
- Every row in the findings table must cite a file path (and line number when applicable)
- Never pad the table with generic advice that isn't grounded in observed code
- If a specialist agent was invoked, fold its findings into the single table — don't return two separate reports
- If the project is small enough to audit inline without project-auditor (e.g., < 10 source files), skip Step 2 and audit directly — but still use the output format from Step 3
- Respect the project's context: a weekend side project doesn't need enterprise-grade CI/CD findings
