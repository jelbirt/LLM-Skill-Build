# Skill ideas backlog

**Capture rule:** every time you paste the same instruction into Claude Code **3+ times**, log it here as a candidate. Cheap to add, cheap to ignore.

Each entry: a one-line "what + when", a note on why it's worth it, and a status.
Status: `seed` (unvetted brainstorm) · `next` (chosen to build) · `building` · `shipped` · `dropped`.

---

## Candidates

> These are **seeds** — unvetted starting points to react to in a dedicated brainstorm.
> Don't build straight from here; promote to `next` first.

| Skill | What + when | Why | Status |
| :---- | :---------- | :-- | :----- |
| `new-skill` | Interview + scaffold a new skill folder from the template, pre-fill frontmatter, run the linter. Use when starting a new skill. | Highest-leverage infra; dogfoods the repo; strong portfolio piece. | **building** (created + linted; dogfood before publish) |
| `git-undo` | Diagnose a git mistake and return safe, state-aware recovery steps with destructive ops flagged. Use when undoing/reverting/recovering in git. | High real-world value; reliably triggers; portable to chat; relatable demo. | **building** (created + linted; dogfood before publish) |
| `sidebar` | Delegate a tangential side question to a subagent so the research happens in its context and only a tight, cited answer returns. Use for mid-session asides about architecture/design/existing code. | Saves main-chat context on tangents; dogfoods the subagent-delegation pattern; broad trigger surface. | **building** (created + linted; dogfood before publish) |
| `hone-skill` | Improve an existing skill: locate its SKILL.md, analyze it, apply targeted edits for a requested improvement, then re-lint and validate. Use to refine/tweak/sharpen a skill. | Counterpart to `new-skill`; closes the create→refine loop; dogfoods the repo's own conventions. | **building** (created + linted; dogfood before publish) |
| `next-steps` | Delegate a token-efficient review (repo state, git history, freshest plan/roadmap docs, session summary) to a Sonnet subagent and return a prioritized next-steps list. Use when asking "what's next" / "where did we leave off". | Solves real session-restart friction; dogfoods the subagent-delegation pattern; cheap to run. | **building** (created + linted; dogfood before publish) |
| `flowchart` | Generate a clean, readable flowchart for a codebase, feature/component, process, or whole project and render it inline in chat via the visualize tool, delegating exploration to a subagent. Use for "diagram this" / "flowchart the X flow" / architecture diagram requests. | Visual deliverable distinct from the rest of the repo's text-only skills; dogfoods subagent-delegation + visualize-tool rendering pattern. | **building** (created + linted; dogfood before publish) |
| `audit` | Severity-organized project audit with optional focus area; flags Effort-L/architectural findings as dev-pipeline candidates. Use for "audit this project", health checks, hardening passes. | Graduated extended skill: customized with pipeline-promotion logic to hand off big findings to /spec → /plan → /build auto. | **building** (customized + linted; dogfood the promotion flow) |
| `audit-fix` | Parallel remediation of /audit findings with disjoint file scopes; Prove-It repro tests required for bug fixes; pipeline candidates deferred. Use right after /audit. | Graduated extended skill: Prove-It discipline borrowed from the imported TDD pipeline; tool-agnostic migration safety gate. | **building** (customized + linted; dogfood the Prove-It flow) |
| `prompt-engineer` | Standalone prompt design/diagnosis framework - structure, technique selection, and a weak-prompt checklist. Use for writing or refining any prompt, system prompt, or tool description. | Graduated personal skill; rewritten via `hone-skill` from a thin agent-delegate wrapper (redundant + non-portable) into self-contained domain expertise. | **building** (rewritten + graduated + linted; dogfood before publish) |
| `release-notes` | Generate release notes from git history since the last tag, grouped by conventional-commit type (features, fixes, breaking changes). Use for changelogs / "what shipped" summaries. | Graduated personal skill (predates project); differentiated from GitHub's PR-label release notes button; picked up the model: sonnet pin. | **building** (graduated + linted; dogfood before publish) |
| `deps-audit` | Unified, prioritized dependency report across security, freshness, and unused/missing packages by orchestrating npm/yarn/pnpm audit, outdated, and depcheck. | Graduated personal skill; goes beyond Dependabot's security-only alerts; hardened description + model: sonnet pin via hone-skill. | **building** (graduated + linted; dogfood before publish) |
| `bash-script-review` | Review a shell script for pitfalls (unquoted vars, missing `set -euo pipefail`, word-splitting, bashisms, unsafe rm/glob); suggest fixes; recommend shellcheck. | Substantive → triggers well; genuine expertise; fits a bash-heavy role; portable. | seed |
| `explain-shell` | Break down a gnarly shell one-liner into what each part does + risks. Use when handed an unfamiliar command/pipeline. | Genuinely useful day-to-day; tiny body; broad trigger surface. | seed |
| `pr-summary` | Summarize a PR from its diff + comments (uses `!`gh pr diff``). Use when reviewing or describing a PR. | Classic, demoable; good dynamic-context-injection example. | seed |
| `dockerfile-review` | Review a Dockerfile for size/security/caching issues. Use when editing or adding a Dockerfile. | Narrow, opinionated, easy to dogfood. | seed |
| `regex-explain` | Explain a regex in plain English + edge cases. Use when reading/writing a regex. | Tiny, high-reuse, very shareable. | seed |

## Notes

- Keep each shipped skill to **one clear job**. If an idea bundles two jobs, split it into two rows.
- Prefer ideas you'll actually dogfood — real use is the test harness.
