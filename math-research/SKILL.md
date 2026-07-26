---
name: math-research
description: Review a mathematical or algorithmic choice against the literature - delegate it to a research-only subagent that reads the actual implementation, identifies which branch of applied math the question sits in, and returns a cited findings brief with complexity bounds, numerical-stability analysis, and tradeoffs. Use whenever the user asks whether an algorithm is the right one, wants the state of the art for a numerical method, questions convergence, conditioning, or stability, asks for a paper or textbook citation to justify an approach, wants alternatives to a solver, estimator, decomposition, or embedding compared, or says "math research", "is this the right method", or "what does the literature say". The dividing line against a quick sidebar lookup is citation - use this whenever the answer must trace to a primary source rather than to recall, however plausible the recall sounds.
argument-hint: [the method question, optionally naming the file or module]
---

# math-research

Answer a methodology question about a mathematical or algorithmic choice with a
cited, tradeoff-explicit findings brief. Research-only - this skill never edits
code, and the subagent is instructed not to. Know the limit of that guarantee:
it is enforced by instruction, not mechanically, whenever the subagent has
write tools. Step 2 covers what to do when that is not good enough.

The question: $ARGUMENTS

## 1. Locate the specialization - do not assume it

The branch of applied math is a finding, not an input. Before dispatching,
spend a few cheap reads establishing:

- **The numeric stack.** Grep the manifest and imports for what the project
  actually computes with - `numpy`/`scipy`/`scikit-learn`/`statsmodels`,
  `nalgebra`/`faer`/`ndarray`, Eigen/BLAS/LAPACK, `torch`/`jax`, R packages.
  The stack constrains which recommendations are implementable.
- **The call site.** The specific function, module, or pipeline stage the
  question is about. If the user named one, start there; otherwise find it.
- **The problem class.** Name it explicitly - optimization, dimensionality
  reduction, linear-system solving, eigenproblems, graph algorithms,
  probabilistic inference, time-series estimation, quadrature, signal
  processing. State the specialization in your dispatch so the subagent
  researches as a specialist in *that*, not as a generalist.
- **The problem scale.** Rough data size (n, dimensionality, sparsity) and any
  latency or throughput constraint, taken from config, tests, fixtures, or
  sample data. Step 4 asks whether an alternative is *practically* better at
  the sizes this project actually sees - without a number here, that judgment
  is a guess. If no scale is discoverable, say so explicitly rather than
  assuming one.

If the question is purely theoretical with no implementation to inspect, say
so and skip to step 2 - but do not invent a call site that is not there.

## 2. Dispatch one research subagent

Use the Task tool with **`general-purpose`**, and spawn **one** - do not fan
out. It is the type built for open-ended research across code and the web,
which is this skill's whole job.

Do not substitute a read-only agent type to get a write guarantee. `Plan` is
scoped to designing implementation plans and closes with a critical-files
list; `Explore` is scoped to locating code, not analyzing it. Both would be
working against their own instructions here, and the findings contract in step
4 is what loses. Where a mechanical guarantee is genuinely required, define an
agent whose `tools:` frontmatter grants read and web access only - a real
restriction from a purpose-built persona, rather than a borrowed one.

State in the dispatch:

- The question, the specialization and problem scale from step 1, and the
  concrete call site.
- The numeric stack, so implementation notes are written in the host language
  rather than an unusable one.
- **The read-only mandate.** It reads code and searches the literature. It
  never edits, creates, or reformats a file. A researcher that can write is a
  researcher that starts implementing.
- **Read the implementation before recommending anything.** Never reason from
  file or function names alone - what the code does and what it is called
  routinely diverge, and a recommendation aimed at the wrong current behavior
  is worse than none.

## 3. Hold the subagent to source discipline

This is what separates methodology review from confident recall. Require that
every recommendation trace to one of:

1. **Peer-reviewed literature** - a journal or established conference, or an
   arXiv preprint carrying real citation weight (roughly 50+ citations, or
   independently corroborated by a source in one of the tiers below). "It
   sounds authoritative" is not a tier.
2. **Established numerical libraries** - LAPACK, scipy, scikit-learn, MATLAB
   algorithm documentation, and the equivalents for the host stack.
3. **Official library documentation** for the stack in use.
4. **Textbooks**, cited by author and title.

Blogs, tutorials, and forum answers may be read to *discover leads* and must
never appear as the justification for a change - trace back to a primary
source first, or drop the claim. An uncited recommendation is a finding that
did not survive.

## 4. Fix the return contract

Require findings in this shape, one block per topic:

- **Current approach** - what the code does now, cited as `path/file.ext:line`.
- **Proposed alternative** - the method recommended, or an explicit "keep the
  current approach" with the reason.
- **Citation** - authors, title, venue, year, or a documentation URL.
- **Tradeoffs** - benefits, drawbacks, scaling behavior as the problem size
  grows (with concrete time and space bounds), and numerical stability or
  conditioning concerns.
- **Implementation notes** - which library or from-scratch approach in the
  host stack, the integration points, and a rough complexity estimate. Verify
  any recommended library actually exists and is still maintained.
- **Compatibility** - what this changes for downstream consumers of the
  output.

Require one explicit judgment per finding: is the alternative *practically*
better here, or only theoretically superior? Say which. Most methods that win
on paper lose on problem sizes this project actually sees.

## 5. Relay

Return the brief with citations intact - they are the deliverable, not
decoration. Keep your own commentary minimal.

State plainly when the literature does not settle the question, when the
current approach is already the right one, or when a recommendation rests on
an assumption about problem size or data distribution that nobody has
verified. A brief that recommends a change in every case is not a review.
