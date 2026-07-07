---
name: flowchart
description: Generates a clean, readable flowchart of a codebase, feature, component, process, or entire project and renders it inline in the chat window. Accepts an optional argument describing the scope (e.g. "the auth flow", "the entire repo architecture", "how requests move through the API layer") plus any other specs like orientation or detail level. Use whenever the user asks for a flowchart, flow diagram, architecture diagram, process diagram, or wants to visualize how a feature/component/system/process works - e.g. "diagram this", "flowchart the X flow", "show me how X works visually", "draw the architecture", or "/flowchart". Delegates codebase exploration to a subagent and renders via the visualize tool to keep token usage low.
model: sonnet
argument-hint: [optional scope, e.g. "the auth flow" or "entire repo"]
---

# flowchart

Produce one clean flowchart for the requested scope and render it inline in the
chat - not a written file, not a wall of prose. Token efficiency is the point:
one exploration dispatch, one render call.

## Instructions

1. Parse the scope from $ARGUMENTS. If it's empty and the target isn't already
   obvious from the conversation, ask one clarifying question (AskUserQuestion):
   whole project/architecture, a specific feature/component, or a specific
   process/flow. Otherwise proceed without asking - don't stall on a scope that's
   already clear.

2. Decide whether this needs codebase exploration:
   - Code/architecture/feature scope: dispatch exactly one Explore agent (use
     general-purpose instead if the repo is large or unfamiliar). Ask it to
     return a compact structured outline - entry points, ordered steps, decision
     branches, terminal states, with file:line refs - not file contents. Tell it
     to abstract minor steps and cap at roughly 20-25 meaningful nodes. For a
     whole-project scope, ask for major modules/services/layers and how they
     connect, not a walk of every file.
   - Non-code process scope (e.g. "the deploy approval process"): skip
     exploration entirely - gather the steps from the user's description or the
     conversation directly.
   - Never dispatch more than one exploration agent for a single flowchart
     request; if the returned outline is thin, ask the user rather than looping
     back for another pass.

3. Turn the outline into a flowchart, applying these readability rules:
   - Cap at ~20-25 nodes. Group or omit minor steps rather than cramming
     everything in - a flowchart that needs a magnifying glass has failed.
   - One consistent flow direction (top-to-bottom for processes with a clear
     start/end, left-to-right for pipelines). Never let edges crisscross.
   - Consistent shape semantics: rounded = start/end, rectangle = process/action,
     diamond = decision, cylinder = data/store. Label decision edges (yes/no,
     success/failure) instead of leaving them bare.
   - Restrained, consistent color coding by category (e.g. one color per
     module/service) - not one color per node.

4. Render it inline as the deliverable:
   - Call `mcp__visualize__read_me` once with `modules: ["diagram"]` (skip if
     already loaded earlier this session) to pick up current styling rules.
   - Call `mcp__visualize__show_widget` with SVG flowchart markup that follows
     the returned style guide (CSS variables, sizing, spacing).
   - Only fall back to the `Artifact` tool (load the `artifact-design` skill
     first) with an SVG/HTML page if the visualize tool is unavailable or fails -
     this is a fallback, not a default.

5. After rendering, name the scope covered in one line and offer to adjust
   (more detail, different area, different orientation, add/remove nodes). Don't
   re-narrate the diagram in prose - the picture is the deliverable.

## Notes

- If scope is "entire project" on a large repo, tell the exploration agent to
  lean on directory structure and module boundaries (top-level dirs, manifest
  files like package.json/pyproject.toml) rather than reading every file -
  breadth over depth.
- Don't re-read files the exploration agent already summarized, and don't
  spawn a second agent for polish - iterate on the diagram markup directly from
  the outline you already have.
