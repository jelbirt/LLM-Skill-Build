---
name: scaffold-audit
description: Run the periodic audit of Claude Code scaffolding - inventory every skill, command, agent, hook, permission list, and model pin across ~/.claude, triage each against the decay patterns that make old-model-era components harmful on newer models, gather A/B bake-off evidence for the contested ones, then prune with verified reference cleanup and git-versioned rollback. Use when the user says "scaffold audit", "prune my config", "audit my skills/setup", "Cherny prune", or "delete your CLAUDE.md and see what happens", when a new Claude model generation ships, or roughly every 6 months since the last audit.
argument-hint: [optional focus, e.g. "skills only" or "since last audit"]
---

# scaffold-audit

Periodically re-earn every piece of Claude Code scaffolding against the current
model generation, and delete what no longer pays its way.

**Why this exists:** scaffolding that compensates for an old model's weakness
decays into dead weight or active harm as models improve; intent, policy, and
environment facts stay valuable. Boris Cherny (creator of Claude Code)
[advises](https://x.com/rohanpaul_ai/status/2082695402953031825) deleting your
CLAUDE.md, skills, and hooks every ~6 months to see what the model now does on
its own, and Anthropic itself
[reportedly cut](https://finance.biggo.com/news/7df48019614f68c0) the large
majority of Claude Code's system prompt at the Opus 5 transition. This skill
makes that ritual repeatable and evidence-based instead of
delete-everything-and-pray.

## Step 1 - Orient, then inventory

Read whatever record the previous audit left (audit memory or notes,
config-repo tags, install-recipe history) and establish what was already
retired and what was deliberately kept, so the audit starts from decisions,
not from scratch.

Delegate the inventory to a subagent (it is bulky, mechanical reading).
Contract: counts and per-component rows (name, kind, size, model pin, one-line
purpose) for `~/.claude/{skills,commands,agents,workflows}`, hooks and
permission lists in `settings*.json`, plugins, and the user CLAUDE.md - plus
overlap clusters, model-era prose ("use a Sonnet subagent", tier-specific
instructions), duplicated payloads, and drift between installed copies and
their sources (repo skills, pinned install recipes).

## Step 2 - Triage every component into one of four buckets

- **Durable (keep, no test needed):** intent, policy, and environment facts -
  commit rules, review boundaries, repo conventions, checklists of *concerns*
  the model should not silently skip. These age well.
- **Suspect (bake-off):** methodology bodies that teach the model *how to
  think* - step-by-step debugging/TDD/review/planning process, orchestration
  logic assuming the model can't self-direct, verification nagging. On current
  models these are the components most likely to be dead weight.
- **Redundant (dedupe by decision):** components whose job another component
  already owns - near-duplicate agents, skill/command twins, overlapping
  clusters. No experiment needed; pick the canonical one with the user.
- **Hygiene (just fix):** stale permission grants, leftovers of finished
  projects, staging debris, dangling references, drifted copies, model pins
  that contradict the current pin policy.

## Step 3 - Bake off the suspects

For each contested skill, run a matched A/B pair of subagents on a fixture
with **ground truth the agents cannot see**: a planted bug with a known root
cause, hidden acceptance tests, a diff with planted issues, a rubric of
gotchas. Same prompt, same model; the only difference is that one arm must
read and follow the skill. Grade outcomes against the key - never vibes - and
verify claims yourself (run the hidden tests, probe the result, diff the two
arms). Record tokens and wall time per arm.

Decision rule: **outcome tie → cut** (the skill is charging tokens and latency
for nothing); the bar for keeping is a *measured* outcome the bare arm missed,
as when a checklist skill covers concerns (rate limiting, headers, quotas) the
bare model skipped. One run per arm detects "changes nothing"; replicate only
when the arms genuinely diverge and the delta would change the verdict.

## Step 4 - Prune with verified cleanup

Every removal is a move-to-backup or a git-tracked deletion - never an
unrecoverable delete. Then:

1. Sweep for references to every removed component (commands, other skills,
   agents, shared reference files) and rewrite them so nothing dangles -
   inline the one sentence of guidance that would otherwise be lost.
2. If a component came from a pinned install recipe, edit the recipe too, and
   prove convergence: a test-install into a scratch dir must reproduce the
   live post-prune state byte-for-byte, with a guard that fails loudly on
   upstream drift.
3. Grep the whole config tree for the removed names afterward; "clean" is a
   verified state, not an assumption.

## Step 5 - Version, record, schedule

Commit the results: the config repo (`~/.claude`) and any source repos each
get commits and, at milestones, tags - the previous state must stay one
`git checkout` away. Update the audit memory/notes with what was cut, what
was kept *and the evidence for each*, so the next audit starts from decisions.
Note the date; the next audit is due at the next model generation or ~6 months,
whichever comes first.

## Gates

- Cuts, merges, and commits are proposed to the user and wait for approval -
  batch the questions (AskUserQuestion) rather than dribbling them.
- Bake-offs cost real tokens (~60-160k per pair); state the estimate before
  launching more than a couple of pairs.
- This skill prunes scaffolding; it never touches project code, and it never
  deletes the only copy of anything.
