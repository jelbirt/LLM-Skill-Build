---
name: repo-adopt
description: Scaffold any repo for a parallel-workstream worktree workflow - tailored scripts/new-worktree.sh and rm-worktree.sh wired to that repo's own gitignored local state (secrets to copy, caches to share, envs to recreate), a checks.sh that defines the green bar once, a CI workflow that runs it, an optional commit-guard hook enforcing that bar and the default-branch rule on agent commits, and a repo-local worktree-cleanup skill; optionally a decisions-first PR template and a starter CLAUDE.md plus tasks/todo.md. Handles multi-project repos with several sub-project manifests, not only one stack at the root. Use whenever the user wants to adopt, onboard, or set up a repo or a brand-new project for git worktrees or parallel agent sessions, says "repo-adopt", "adopt this repo", "wire this repo for worktrees", or "set this project up for parallel sessions". Supports a dry-run that reports what it would create without writing anything.
argument-hint: [repo path] [--dry-run]
---

# repo-adopt

Point at a repo and scaffold the per-repo pieces of a parallel-workstream
workflow: branch-per-workstream worktrees (creation AND teardown), CI at the
merge point, and — when asked — a decisions-first PR template and a starter
CLAUDE.md plus tasks/todo.md. Detect, propose, confirm, then write. Never
guess silently, and never overwrite an existing file without showing a diff
first.

## 1. Inspect the target repo

The repo path may be passed as `$ARGUMENTS` (default: current directory).
With `--dry-run`, do all detection and produce the full proposed file
contents, but write nothing.

Detect, and record what you find:

1. **Sanity** — it is a git repo; note the default branch and the remote,
   if any.
2. **Gitignored local state** a bare `git worktree add` would miss — read
   `.gitignore` and check what actually exists: secrets files such as `.env`
   (copy per worktree), large data or cache directories (symlink and share),
   virtualenvs and `node_modules` (recreate, never copy). For anything
   ambiguous, **ask which way to wire it** — shared-vs-copied is a per-repo
   judgment, and a shared cache can carry operational meaning.
3. **Shared mutable state** — append-only ledgers, registries, databases:
   anything two concurrent workstreams would corrupt by writing at once. If
   found, plan a "who holds the pen" warning in the worktree script's output
   and suggest a pen-registry line in the repo's todo or state doc.
   **Check both directions across repos, not just across worktrees.** A cache
   this repo owns may have *inbound* consumers — sibling repos whose own
   gitignored directories are symlinks pointing into this checkout, or whose
   scheduled jobs invoke this repo's CLI to write it. Conversely this repo's
   shared directories may themselves be symlinks pointing *outward*. Resolve
   the symlinks rather than trusting directory names, and scan sibling repos
   for links landing here. A pen rule that says "one worktree at a time" is
   actively wrong when the real co-holder is another repo, and a fresh
   session adopting this repo cold has no way to know that. When you find
   cross-repo coupling, name the other repo and what it does — reads, writes,
   or runs a scheduled job — and ask which repo's state doc owns the pen
   registry so it is recorded once rather than duplicated into drift.
4. **Test/lint stack** — lockfiles and config (`pyproject.toml` plus
   `uv.lock`, `package.json`, `Cargo.toml`, ...) and the actual test and
   lint commands. Prefer what CLAUDE.md or the README document over
   inference. Manifests worth looking for include `pyproject.toml`,
   `uv.lock`, `requirements.txt`, `setup.py`, `package.json`, `Cargo.toml`,
   `go.mod` — a plain `requirements.txt` with no lockfile is still a stack.
   **Do not assume one stack at the root.** Plenty of repos hold several
   sub-projects, each with its own manifest and tests and no manifest at
   the top at all. Search a couple of levels down for manifests before
   concluding anything, and skip vendored or reference trees. When you find
   more than one, enumerate them — path, stack, test command, lint command,
   whether it has tests at all — and **ask** whether they share one bar or
   each keep their own; that answers whether CI is one job or a matrix.
   A sub-project silently left out of CI is worse than an obviously absent
   one, because the badge goes green either way. Where a sub-project has no
   tests, say so plainly rather than wiring a bar that checks nothing.
   Also note the toolchain version the repo pins (`.nvmrc`,
   `requires-python`, `rust-toolchain.toml`) — the generated pieces need it.
5. **Existing artifacts** — `scripts/new-worktree.sh`,
   `scripts/rm-worktree.sh`, `.claude/skills/`, CI workflows, PR template,
   `CLAUDE.md`, `tasks/todo.md`. Never clobber; propose a diff against what
   exists instead.
6. **Whether they want a commit guard**: ask, never assume. It is the one
   generated piece that costs something on every commit: it runs the full bar
   before each one, which can be a minute or more. In a repo whose CI already
   blocks a red PR, its unique contribution is surfacing mechanical failures at
   commit time instead of at CI time, which is feedback latency rather than a
   correctness gate. Offer it, name that trade honestly, and take no for an
   answer. Ask about its two halves separately: running the bar (slow) and
   blocking commits on the default branch (instant, just a branch-name check).
   They are independent and are often wanted one without the other.

## 2. Scaffold

Generate, confirming the choices flagged in step 1:

Everything below is new text, so the owner's global formatting rules apply
to all of it. When adapting a file from another repo, normalize it rather
than preserving its punctuation verbatim: a source written before a rule
existed will otherwise carry violations into every repo this skill touches.

- **`scripts/new-worktree.sh`** — usage `scripts/new-worktree.sh {branch}
  [dir]`; creates the worktree from the default branch, reusing the branch
  if it already exists; then wires this repo's specific state — symlink the
  shared directories, copy the secrets files, leave envs to be recreated. A
  header comment documents WHAT is wired and WHY, plus the shared-state pen
  rule when step 1.3 found any — naming every co-holder it found, including
  other repos and scheduled jobs, since a pen rule scoped to worktrees reads
  as safe while the real conflict sits outside them. When the wiring assigns
  a NUMBERED per-worktree resource — a proxy port, a schema suffix, a
  display number — **claim it, don't hash it**: read what the sibling
  worktrees have already taken (their `.env.worktree` or equivalent) and
  check for live listeners before picking. Two branch names can hash to the
  same number, and that collision surfaces as a mid-session bind failure
  long after creation, not as an error at the moment someone could fix it.
  Wrap the wiring in an EXIT trap that removes the worktree again if a
  later step fails — a half-wired worktree (created but never fully wired)
  otherwise survives as a trap for the next session that finds it.
  Use `set -euo pipefail`,
  set the executable
  bit, and end by echoing the new path and `scripts/checks.sh` as the
  next step.
- **`scripts/rm-worktree.sh`** — the teardown mirror; usage
  `scripts/rm-worktree.sh {branch} [--force] [--delete-remote]`. Gate before
  removing anything: the branch is merged into the default branch, the tree
  is clean, the target is not the main checkout, and it is not the caller's
  working directory. Then, in this order: `git worktree remove {dir}`,
  `git branch -D {branch}`, `git worktree prune` — the branch delete must
  come after the worktree removal, since git refuses to delete a branch
  that is still checked out somewhere. That ordering makes the removal
  irreversible by the time the delete runs, so **nothing after it may
  veto: `-D`, with the script's own merged gate as the sole authority**.
  `git branch -d` asks a DIFFERENT question — reachable from HEAD or
  upstream, not "merged into the default branch" — and when the two
  disagree it refuses after the worktree is already gone, leaving a
  half-torn-down repo (branch orphaned, prune never run) and an error that
  steers users toward `--force`, the one flag that skips the merged gate.
  The gates themselves have edges, each of which cost a real bug to learn:
  - **Merged** compares FULLY-QUALIFIED refs — `refs/heads/{branch}` is
    an ancestor of `refs/heads/{default}` OR of
    `refs/remotes/origin/{default}`; either counts as merged (fetch
    first, tolerating offline). A bare name lets a same-named tag win the
    lookup, and checking only local makes every PR-merged branch read as
    unmerged, which trains the `--force` habit.
  - **Clean** captures `git -C {dir} status --porcelain` output and exit
    code SEPARATELY and refuses on either. `[ -n "$(...)" ]` discards the
    exit code, so a status that FAILS reads as clean.
  - A registered worktree whose directory is MISSING is refused outright,
    pointing at `git worktree repair` — otherwise the first signal is the
    clean gate refusing with an unrelated-looking `cannot change to`
    error, long after the real cause (a moved directory) was fixable.
  - The "you are standing inside it" gate needs BOTH spellings of the cwd
    against BOTH spellings of the worktree path, and both snapshots must be
    taken on the script's FIRST line, before any `cd`. Read after a `cd` to
    the repo root, `$PWD` IS the repo root, so the check compares it against
    itself and never fires. Physical alone (`pwd -P`) is not enough either:
    a shared directory symlinked INTO a worktree resolves back OUT of it, so
    the physical cwd lands outside the worktree. Teardown does not delete
    that directory (it removes the symlink, never following it to the
    target), but `$PWD` is left naming a path inside a worktree that no
    longer exists, which is what the gate promises will not happen.
    Logical alone fails the
    mirror case, an ancestor symlink on the worktree path. Snapshot both
    forms up front, resolve the worktree path as well, and compare each
    snapshot against both. Verify by running the SCRIPT from inside a
    symlinked directory, never by testing the comparison in isolation: the
    pattern can be correct while the script that runs it is not, and that
    failure looks exactly like a pass.

  `--force` covers squash-merged branches, which the merged-check cannot
  see (it bypasses the merged gate only, never the clean-tree gate);
  `--delete-remote` optionally deletes the remote branch as well.
- **`scripts/checks.sh`** — the single definition of the green bar: the
  repo's real lint / format / typecheck / test commands from step 1.4, in
  one executable script. CI runs it and so does the commit hook below, so
  the local bar and the CI bar cannot drift — there is one list, and this
  is it. `set -euo pipefail`, `cd` to the repo root first. For a
  multi-project repo, take an optional sub-project path argument: with no
  argument run every sub-project's bar in turn, so one command still
  answers "is this repo green"; with one, run only that sub-project's, so
  a CI matrix job and a hook checking a single tree can both scope down.
  When the repo pins a toolchain version, check it first and bootstrap if
  you can: a non-interactive hook shell gets the machine default rather
  than the pinned version, and under the wrong one a suite can fail as a
  pile of unrelated-looking crashes instead of one actionable line. Fail
  with that line if the bootstrap is unavailable. Tell the header that
  changing this script means updating the CLAUDE.md Commands section in
  the same commit.
  The shell-syntax check must glob `.claude/hooks/` as well as `scripts/`.
  The commit guard below is a generated script, and it is the one file
  where going unchecked is worst: a syntax error makes it exit non-zero,
  and any code other than 2 lets the commit through, so the guard becomes
  the silent no-op its own header warns about. Guard the loop with
  `[ -f "$f" ] || continue` so an unmatched glob is skipped, not parsed.
- **CI workflow** (`.github/workflows/ci.yml`) — on pull_request and on push
  to the default branch; locked install (`uv sync --frozen`, `npm ci`, ...)
  reading the pinned toolchain version; then `scripts/checks.sh` and
  **nothing else** — not a re-listing of the commands, and no CI-only
  extras. A check that exists only in CI breaks the local-green-means-CI-
  green promise, so anything worth checking — including `bash -n` over the
  generated scripts — goes in `checks.sh` itself. And `bash -n` takes ONE
  file per invocation: `bash -n a.sh b.sh` parses only `a.sh` and hands the
  rest to it as positional parameters, so the scripts most in need of a
  syntax check are the ones that never get it. Loop, one file at a time.
  For a multi-project repo whose sub-projects do NOT share a bar, use a
  matrix — one job per sub-project, each passing its path to
  `scripts/checks.sh` — so a failure names which one instead of stopping
  at the first. Skip or adapt when the repo has no remote or already has
  CI.
- **Commit guard** (`.claude/hooks/pre-commit-guard.sh` plus the
  `PreToolUse` wiring in `.claude/settings.json`, **only when asked for in
  step 1.6**) — enforces at the tool
  call what CLAUDE.md only states. Before any agent-made `git commit` into
  this repo it runs `scripts/checks.sh` and blocks on failure; in a repo
  that declared PR-based flow (step 1.1) it also blocks commits on the
  default branch. Follow the `PreToolUse` contract exactly — **exit 0
  allows, exit 2 blocks and feeds stderr back as the reason**; any other
  code lets the commit through, so a guard with the wrong exit is a no-op
  that looks installed. Generate it with these properties, each of which
  cost a real bug to learn:
  - **Check the tree being committed**, not the hook's own checkout. They
    differ per worktree, and running the wrong one passes a green tree
    while the dirty one lands. Prefer each worktree's own `checks.sh` so a
    branch that changes the bar is judged by its own version.
  - **Anchor on the payload's `cwd`, never `getcwd()`.** The hook process
    does not start where the session's shell is standing — the payload's
    `cwd` field is where a bare `git commit` actually lands, so `getcwd()`
    judges the wrong tree. Fall back to the repo root, not to the process
    cwd. And when the guard shells into an embedded parser, pass that
    anchor via the ENVIRONMENT, never argv: under `node -e` (and
    similarly `python -c`) the argv indexing SHIFTS relative to a normal
    script invocation — `process.argv[2]` is silently undefined under
    `-e` — so an argv-based anchor degrades right back to the process
    cwd. The environment does not shift.
  - **Normalize the target with `git rev-parse --show-toplevel`** before
    looking up its `checks.sh`. git commits happily from a subdirectory,
    and without this `cd src && git commit` looks for
    `src/scripts/checks.sh`, finds nothing, and fails open — a pass with
    no test ever run.
  - **Escapes count only in command-prefix position** — a `VAR=value`
    assignment at the start of a segment or directly before the `git`
    token, never a substring match over the whole command. A substring
    match lets a commit MESSAGE that merely mentions the escape activate
    it, and since CLAUDE.md documents the escapes by name, messages
    about the guard are guaranteed to mention them.
  - **Gate every commit-writing subcommand** — `commit`, `merge`, `pull`,
    `cherry-pick`, `revert`, `am`, `rebase` — matched as
    whitespace-delimited tokens, never `\b`: hyphens are word boundaries,
    so `\bam\b` matches inside a path like `/home/i-am-here/`. A verb
    that cannot be resolved gets the STRICTEST treatment (`commit`), not
    a skip.
  - **Parse the command shell-aware.** Split on operators, skip `env` and
    `VAR=` prefixes and git global flags, follow `cd` so the target
    worktree is the one that receives the commit, and recurse into
    `sh -c` / `bash -c` / `eval` payloads. A naive regex misses all of
    these, and every miss is a silent bypass.
  - **Scope to this repo, by git common dir** — not by comparing toplevel
    paths, which differ for every worktree of the same repo. Commits aimed
    at a sibling repo from a session running here are ignored, not gated.
  - **Fail open at the payload level only** — unreadable JSON, missing
    interpreter, git errors. This is a guardrail for cooperating sessions,
    not a security boundary, and it must never wedge unrelated work; say
    so in the header rather than implying a guarantee it cannot make. But
    a single *segment* that will not tokenize is a different case: fall
    back to a conservative substring match and treat it as a commit rather
    than skipping it. A multi-line commit message tokenizes badly and is
    the common case, so skipping there would bypass the guard exactly when
    it matters.
  - **Give each rule a named escape** typed into the commit command itself
    (`SKIP_CHECKS=1`, `ALLOW_MASTER_COMMIT=1` or the local equivalent), so
    every override is deliberate and visible in the transcript. Document
    them in CLAUDE.md. A gate with no legitimate override gets bypassed
    illegitimately.
  - **Wire `settings.json` defensively.** Quote the command path —
    `"$CLAUDE_PROJECT_DIR/.claude/hooks/pre-commit-guard.sh"` — and set an
    explicit, generous `"timeout"` (e.g. `180`): a real bar can
    legitimately run for minutes, and the 60s default kills the hook
    mid-run, discarding the exit-2 verdict so the commit PROCEEDS. Both
    an unquoted path with a space and a timed-out hook are silent no-ops
    that look installed.
  Skip the branch rule in repos that are deliberately direct-to-main.
- **Repo skill `worktree-cleanup`**
  (`.claude/skills/worktree-cleanup/SKILL.md`) — a thin wrapper over
  `rm-worktree.sh`: with a branch argument tear down that worktree; with no
  argument, sweep — find every merged-and-clean worktree, list them, confirm
  once, then tear down each. If the `worktree-cleanup` skill is already
  installed, copy it and adjust its notes to name this repo's wired state.
- **PR template** (`.github/pull_request_template.md`, only when asked) —
  decisions-first: decisions made, hypotheses, cost, and methodology at the
  top; mechanics (files, tests, how verified) below.
- **Starter `CLAUDE.md` plus `tasks/todo.md`** (only when asked, or offer
  it when the repo has neither — typical for a brand-new project). Encode
  the operating model, not boilerplate: the repo's test and lint commands
  (the must-be-green-before-commit bar, noting that `scripts/checks.sh`
  defines it once and that the commit guard enforces it, with each escape
  named), the parallel-workstream rules (one
  branch per workstream via `new-worktree.sh`, the default branch as review
  inbox, merge back via PRs, plus any pen or serialized state from step
  1.3), and the gated workflow (spec, plan, tasks, implement, with explicit
  owner-approval gates; PRs opened for review, never merged by the agent).
  `tasks/todo.md` starts as the current-state doc: active workstreams, next
  gates, and a pen-registry line when step 1.3 applies. Keep both to about a
  page — they are conventions, not documentation.

## 3. Verify and report

- **Dry-run:** print each proposed file in full, plus the questions you
  would have asked. Where the repo already has an equivalent, diff proposal
  against existing and say whether adoption would be a no-op.
- **Real run:** `bash -n` every generated script — ONE file per
  invocation, since `bash -n a.sh b.sh` parses only the first — then
  create a throwaway worktree with `new-worktree.sh` and confirm the
  wiring (symlinks resolve, secrets copied, shared dirs shared and
  per-worktree dirs not). Confirm the throwaway worktree reports a
  **clean** `git status`: a wired path that the repo's ignore rules do not
  actually match leaves every worktree permanently dirty and
  un-teardownable, and only a real round trip surfaces it. Run
  `scripts/checks.sh` to confirm the bar is real before committing
  anything.
- **Exercise the teardown WITHOUT `--force`** — never verify with it.
  `--force` skips the merged gate, so a forced teardown exercises none of
  the logic users actually depend on; verifying that way is exactly how a
  broken teardown shipped everywhere while every adoption "verified
  green". Arrange the throwaway branch so the merged gate and
  `git branch -d` would DISAGREE: merge the branch into the default
  branch, advance the default branch past it, and move HEAD somewhere
  else — the branch is now an ancestor of the default branch but NOT
  reachable from HEAD. A correct teardown completes fully (worktree gone,
  branch gone, prune run); a broken one aborts half-done after the
  irreversible step. Also confirm the refusals still refuse: a dirty
  tree, an unmerged branch without `--force`, and a run from inside the
  worktree.
- **Verify the commit guard, if one was generated,** by feeding it hand-built payloads rather
  than by trusting it — and test the BLOCK side against a deliberately
  FAILING `checks.sh`, not only the allow side: a matrix that only ever
  exercises the allow path cannot distinguish "bar ran and passed" from
  "bar never ran". TIME the gated commits for the same reason — a gated
  commit takes roughly as long as the bar itself, so a millisecond
  verdict means nothing ran. The matrix:
  - a non-commit command, and a commit aimed at a different repo → allow
  - a commit on a workstream branch with a green tree → allow, at
    bar-runtime speed
  - a commit on the default branch → block
  - each escape in command-prefix position → that rule waived, others
    intact
  - a commit whose MESSAGE contains each escape verbatim → still gated
  - a bare `git commit` whose payload `cwd` is inside the repo while the
    hook process starts OUTSIDE it → still gated (the `getcwd()` trap)
  - a commit from a SUBDIRECTORY of the worktree → still finds and runs
    the root's `checks.sh` (against a failing bar, so the block proves it
    ran)
  - the indirection forms (`git -C`, `cd &&`, `sh -c`, heredoc message)

  Blocking what should pass is as much a defect as passing what should
  block, and both are cheap to check now and expensive to discover
  mid-commit.
- Land the changes per the target repo's own commit and review policy (read
  its CLAUDE.md): propose commits, and never auto-merge.
