---
name: implement
description: "Implement a spec (GitHub issue or file) end to end: clarify what's unclear, plan phases as a dependency graph and run independent ones in parallel worktrees, gate on typecheck + tests, review on every axis (standards, spec, cohesion, and design when a screen changed) at milestones and at the end, ship one PR with phases as commits."
disable-model-invocation: true
argument-hint: "<issue number | spec path> [extra guidance]"
---

Implement the work described by the spec the user points at. You are the **orchestrator and strict checker**: subagents write the code, you plan, gate, merge and verify. Do not write feature code yourself except for trivial glue that would cost more to delegate than to type.

## 1. Load the spec

- An issue number → `gh issue view <n> --comments`. A path → read it. Neither → ask.
- Read the repo's `AGENTS.md` (root + the nested one for every workspace the spec touches) and `CONTRIBUTING.md` if present. These are the standards the review will hold the work to.
- Read the docs the spec or the touched modules point at. Don't re-derive what they already say.

## 2. Clarify what's unclear

If anything in the spec is ambiguous, contradicts the code, or leaves a design choice open, call the Skill tool with "grilling" **before** planning. Keep it to the genuinely open questions — the spec has already been discussed once. If nothing is unclear, say so in one line and move on.

## 3. Plan phases as a graph

Break the work into **phases**: each phase is one coherent, reviewable step that leaves the tree green (typecheck + tests pass). For each phase record: what it delivers, which files and modules it touches, the tests that prove it, its seams (existing seams preferred; the fewer the better), and **which phases it depends on**.

Then arrange the phases into **waves**. A wave is the set of phases whose dependencies are all in earlier waves; phases in the same wave run in parallel, each in its own worktree. Think from parallelism first and fall back to serial only where the graph forces it:

- Two phases that touch the same files, or where one reads a shape the other defines (a schema, a type, an API), are serial.
- Anything every phase needs (a schema change, a shared type, a dependency bump that rewrites the lockfile) is a short wave of its own, first.
- Data before schema removal; code that stops writing a field before the function that clears it before the validator that drops it.
- A wave of N phases costs N builders at once. Say how many run in parallel.

Mark each wave as a **milestone** when it leaves the branch in a state a reviewer could judge on its own: a complete backend slice, a complete screen, a migration with its tests. Not every wave is a milestone.

Show the plan to the user as waves, with the milestones marked and the parallel count stated. Do not start until they confirm.

## 4. Branch and PR

- Create a branch off the default branch (`<type>/<slug>`), unless the user says to use the current one. This is the integration branch.
- One PR per spec. Phases land as **separate commits** on that PR, in dependency order. Open the PR as draft after the first wave lands so progress is visible.
- Commit messages follow `CONTRIBUTING.md`; if the repo has none, one-line imperative subject + a body explaining *why*.

## 5. Build each wave with subagents

Each phase in a wave gets its own builder subagent in its **own worktree** branched from the integration branch as it stands at the start of the wave. A wave of one phase runs the same way, in one worktree. Never let two builders share a working tree.

The subagent prompt must carry: the spec (or link), the phase's slice of the plan, which files the other phases in the wave are touching so it stays out of them, the relevant `AGENTS.md` and `CONTRIBUTING.md` rules, the seams and the tests expected, and the instruction to write the test before the code where a test-first loop fits. Builders run on the strongest model available for implementation (Opus-class); the phase's correctness is worth more than the tokens. Reviewers run on the strongest read-only model (Fable-class) and never edit.

When a builder reports back, **you check** — read the diff, don't trust the summary:

- Run the workspace's typecheck and the affected test files in that worktree.
- Confirm the phase did what the plan said — no more, no less. Scope creep goes back to the builder to remove.
- Confirm nothing destructive happened outside the phase's scope.

If it fails, send the builder back with the specific failure. Loop until green.

**Merging a wave back** is your job, not the builders': merge each phase into the integration branch in dependency order, rebasing onto what has already landed, and run the full gates (typecheck, lint if configured, whole test suite) after each merge. A conflict between two phases of one wave means the plan missed a dependency; resolve it, note it, and treat the pair as serial next time. The next wave branches from the merged result.

## 6. Review at milestones and at the end

Review runs at every **milestone** the plan marked and always once more **at the end**. Each review is a **subagent** that calls the Skill tool with "code-review" against the merge-base of the integration branch (or, at a milestone, against the previous milestone's commit), passing the spec source and the list of screens the work has touched, if any. The review runs Standards, Spec and Cohesion on every change and Design when a screen changed; for Design, launch the app the way the repo's `AGENTS.md` describes (simulator, dev server or preview) before the review starts, so the reviewer sees it running. Read every axis's findings.

- Fix everything real (via a subagent for anything non-trivial), re-run the gates, and commit the fixes as their own commit before the next wave starts. A finding at a milestone that changes the plan for later waves changes the plan; say so.
- The final review covers the whole diff, so cohesion problems between phases that each passed alone surface there.
- Findings you disagree with: say why in the PR description, don't silently drop them.

## 7. Ship

Mark the PR ready. The PR description carries: the spec link, the phase list by wave (one line each), how it was verified (the exact commands and their result), and any review findings deliberately not actioned. Report the same to the user, plainly — if a gate is red or a phase was skipped, say so.
