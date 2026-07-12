---
name: deps-audit
description: Produce a unified, prioritized report on project dependencies across three dimensions - security vulnerabilities, version freshness, and unused or missing packages - by orchestrating npm/yarn/pnpm audit, outdated, and depcheck into one triaged action list. Use when the user wants a dependency audit, asks if packages are outdated, wants to check for vulnerabilities, wants to find unused dependencies, or wants a dependency health report - this goes beyond automated security-only alerts like GitHub Dependabot by also covering freshness and utilization.
model: sonnet
allowed-tools: Read, Grep, Glob, Bash
---

# Skill: deps-audit

Audit the project's dependencies across three dimensions: security, freshness, and utilization. Produce a prioritized action list.

## Step 0 — Detect package manager

Check for:
- `package-lock.json` → npm
- `yarn.lock` → yarn
- `pnpm-lock.yaml` → pnpm
- `bun.lockb` → bun

Use the matching tool for all commands below. If multiple lockfiles exist, flag it and ask which to use.

## Step 1 — Security

Run the audit command for the detected package manager:
- npm: `npm audit --json`
- yarn: `yarn audit --json`
- pnpm: `pnpm audit --json`
- bun: `bun audit` (or fallback to `npm audit` against the lockfile)

Parse results into:
- **Critical / High**: immediate fix candidates
- **Moderate**: next-sprint candidates
- **Low**: backlog

For each vulnerability, report:
- Package and version
- Severity and CVE / advisory ID
- Whether a fix is available (and what version to upgrade to)
- Whether it's a direct dependency or transitive

## Step 2 — Freshness

Run the outdated command:
- npm: `npm outdated --json`
- yarn: `yarn outdated --json`
- pnpm: `pnpm outdated --format json`

Classify each outdated package:
- **Major behind**: breaking changes — plan and test carefully
- **Minor behind**: new features, usually safe
- **Patch behind**: bug fixes, update liberally

Flag dependencies where:
- Multiple majors behind (likely upgrade-blocked by something)
- Peer-dependency conflicts would prevent a clean update
- Framework-critical packages (React, Next, TypeScript) are out of date

## Step 3 — Utilization

Detect unused / unreferenced dependencies:
- Try `npx depcheck --json` (works with any package manager)
- Fall back to grep-based detection: for each `dependencies` entry in `package.json`, grep the source tree for `require('pkg')` or `from 'pkg'`
- Exclude dev-only packages that wouldn't appear in source (eslint configs, type defs for runtime-only packages, build-time plugins listed elsewhere)

Report:
- Unused dependencies (candidates for removal)
- Potentially unused (used only in config files / scripts — verify before removing)
- Missing dependencies (imported but not declared — bugs waiting to happen)

## Step 4 — Report

```markdown
# Dependency Audit — [date]

## Security (X critical, Y high, Z moderate, W low)
| Package | Severity | Fix available | Action |
|---------|----------|---------------|--------|
| ... | ... | ... | ... |

## Freshness (A major, B minor, C patch behind)
| Package | Current → Latest | Type | Notes |
|---------|------------------|------|-------|
| ... | ... | ... | ... |

## Utilization
**Unused (remove candidates):**
- `pkg-name` — not referenced in source

**Missing (add candidates):**
- `pkg-name` — imported but not in package.json

## Prioritized Actions
### P0 — Do now
1. ...

### P1 — Next sprint
1. ...

### P2 — Backlog
1. ...

## Suggested Commands
```bash
# Example upgrade commands for the P0 / P1 items
npm install pkg@^5.0.0
npm uninstall unused-pkg
```
```

## Rules

- Do NOT run `npm install` or any command that modifies `package.json` / lockfiles — only report and suggest commands
- If `depcheck` is not available and the user wants it run, suggest the install command but don't install unilaterally
- Never mark a package as unused without checking import references — grep the source tree
- Respect monorepo structure: if the project has workspaces, audit each workspace separately or ask which to audit
