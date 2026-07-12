---
name: prune-test-suite
description: Review the test suite for relevance against current source code, pruning stale tests and adding missing coverage
allowed-tools: Read, Edit, Write, Grep, Glob, Bash
---

# Skill: prune-test-suite

Review and prune the test suite for this project. For each test file, verify its logic against
the current production source, then apply all necessary changes.

---

## Step 0 — Discover scope

1. Find all test files in this project:
   ```
   glob **/*.test.{ts,tsx,js,jsx} **/*.spec.{ts,tsx,js,jsx} **/__tests__/**/*.{ts,tsx,js,jsx}
   ```
   Exclude `node_modules`, `dist`, `.next`, and build output directories.

2. For each test file, determine which source file(s) it mirrors by examining:
   - Import paths within the test (e.g., `import { foo } from '../utils'`)
   - Inline simulation functions that replicate logic from a source file (match function names,
     regex patterns, or constants against the codebase via grep)
   - File naming conventions (e.g., `foo.test.ts` tests `foo.ts`)

3. Build a scope table mapping each test file to its source file(s). Print the table before
   proceeding.

Do not modify any source file. Do not touch node_modules, dist directories, or generated files.

---

## Step 1 — Read both files

For each row in the scope table:
- Read the test file in full.
- Read every source file listed for that test.

Complete Steps 1-4 for each test file before moving to the next.

---

## Step 2 — Audit

Check each of the following for every test or `describe` block:

1. **Logic match** — Does the test's logic (imported or inlined) exactly match the corresponding
   production code? Flag any line in the test that copies a constant, regex, branch condition,
   function body, or message string that differs from the current source.

2. **Stale behaviour** — Does the test assert something the source no longer does? (e.g., a branch
   that was removed, a string that changed, a parameter that was renamed, a function signature
   that was updated.)

3. **Dead test** — Does the test import or reference a symbol, function, or type that no longer
   exists in the source? Does it test a code path that was deleted?

4. **Missing coverage** — Does the source contain pure, deterministic logic that has no
   corresponding test? Count logic as "pure" only if it can be exercised without mocking
   external services, databases, network calls, or framework internals. Examples:
   - Regex patterns and validation functions
   - Date/string/number formatting or parsing
   - State machine transitions and boundary arithmetic
   - Pure transform/filter/map logic
   - Error message construction

   If logic requires a database client, HTTP call, framework hook, or rendering context to
   execute, it does not qualify — skip it.

---

## Step 3 — Produce a change list

Write a numbered list of concrete changes. Each item must specify:
- The action: **DELETE** test / **UPDATE** test / **ADD** test
- The file, `describe` block, and `it(...)` name affected
- One sentence explaining why

Do not apply changes yet. Print the list, then stop and ask the user to confirm
before proceeding. This list can include test deletions, which are only
recoverable through git history, not through this skill - do not apply any
change until the user approves the list, or has explicitly pre-approved
auto-apply for this session.

---

## Step 4 — Apply changes

Only after the user has confirmed the change list (or pre-approved auto-apply):

- **DELETE**: Remove the individual `it(...)` / `test(...)` block. If an entire `describe` block
  becomes empty, remove it too.
- **UPDATE**: Edit only the specific lines that are wrong. Do not rewrite surrounding tests.
- **ADD**: Add new test blocks inside an appropriate `describe`, or create a new `describe` if
  none fits. Follow the style and conventions of the existing test file (import patterns, assertion
  style, naming conventions). Do not introduce new testing libraries or dependencies.

---

## Constraints

- Do not add test infrastructure (new configs, new packages, new scripts) unless the project has
  no test runner at all — in that case, ask before proceeding.
- Preserve every test that is still correct. Do not rewrite passing tests for style.
- Match the exact regex literal, exact error message string, and exact arithmetic from the source.
  Copy character-for-character; do not paraphrase.
- If a test file uses inline simulation functions (re-implementing source logic inside the test
  rather than importing it), verify those inline functions match the source exactly.
- If a source function depends on `Date.now()` or `new Date()`, use a fixed reference date in
  the test and document the assumption in a comment.
- Edit the minimum number of lines necessary. If a diff would exceed 20 lines for a single test
  update, explain why before proceeding.

---

## Output

After applying all changes for all test files, print a summary table:

| Test file | Tests deleted | Tests updated | Tests added | Notes |
|---|---|---|---|---|
| ... | ... | ... | ... | ... |

Then run the project's test suite using whatever test command is configured (check `package.json`
scripts for `test`, `test:unit`, etc.). Report whether all tests pass. If any fail, read the
failure output, fix the cause, and re-run until the suite is green.
