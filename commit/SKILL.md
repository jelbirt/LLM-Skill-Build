---
name: commit
description: Create a git commit for the pending changes, auto-generating a message in the repo's commit style and evaluating the actual diff (not just file names) to decide whether it should land as one commit or be split across several. Use whenever the user says "commit this", "commit these changes", "commit it", "make a commit", or otherwise asks to commit — even without typing /commit explicitly. Applies the "would I revert these together?" test to catch unrelated concerns (mixed features, refactor + feature, unrelated code areas) and always proposes the commit plan for approval before staging or committing anything.
allowed-tools: Bash(git add:*), Bash(git status), Bash(git diff:*), Bash(git log:*), Bash(git commit:*)
---

## Context

- Status: !`git status --short`
- Branch: !`git branch --show-current`
- Staged diff: !`git diff --cached --stat`
- Unstaged diff: !`git diff --stat`
- Recent commits: !`git log --oneline -10`

## Task

Commit the current changes, splitting into multiple commits when they span unrelated concerns.

---

### Step 1 — Analyze scope

Review the status, diffs, and recent commit messages above. For any file where the `--stat` shows a non-trivial change, read the **full diff** (`git diff <file>` or `git diff --cached <file>`) so you understand *what* changed, not just *which* files.

Decide whether the changes should be **one commit** or **split into multiple**, using these signals:

**Split when:**
- Changes span **unrelated features or bug fixes** (e.g., a typo fix + a new API endpoint)
- Mixed **refactor + feature** — separate the refactor so it's reviewable and revertable on its own
- Changes touch **unrelated areas of the codebase** with no logical link (e.g., frontend styling + backend migration)
- The diff fails the **"would I revert these together?"** test

**Keep as one commit when:**
- All changes serve a single goal (feature + its tests + its docs)
- Refactor is small and directly supports the feature in the same diff
- Fixes are cohesive (e.g., one bug's root-cause fix + a regression test)

Small cohesive change = one commit. **Don't split for the sake of splitting.**

---

### Step 2 — Propose the plan

Output a short plan **before** making any commits. Wait for user approval.

**Single-commit case:**
```
Plan: 1 commit
  Files: a.ts, b.ts
  Message: "{draft 1-2 sentence summary}"
```

**Multi-commit case:**
```
Plan: 2 commits (reason: {one-line justification})

  1. Files: a.ts, b.ts
     Message: "{draft summary}"

  2. Files: c.ts, d.ts
     Message: "{draft summary}"
```

If the user requests changes (different groupings, different order, merge two groups, different message), revise and re-propose. Do NOT stage or commit until the plan is explicitly approved.

---

### Step 3 — Execute

For each commit in the approved plan, in the order given:

1. Stage the group's files individually by name — do NOT use `git add -A` or `git add .`
2. Do NOT stage files that likely contain secrets (`.env`, `credentials.json`, `*.key`, `*.pem`, etc.) — warn the user if you see any in the diff
3. Create the commit with a message that:
   - Follows the style and conventions of the recent commits shown above
   - Focuses on the "why" rather than the "what"
   - Is 1–2 sentences max
   - **Does NOT include a `Co-Authored-By:` trailer or any Claude/Anthropic attribution**
4. Use HEREDOC format:
   ```
   git commit -m "$(cat <<'EOF'
   Your commit message here.
   EOF
   )"
   ```

---

### Step 4 — Confirm

After all commits are created, run:
- `git status` — verify a clean working tree (or note any deliberately unstaged files)
- `git log --oneline -N` (N = number of commits created) — confirm commits landed in the right order with the right messages

Report a one-line summary to the user: which commits were created and whether anything was intentionally left unstaged.
