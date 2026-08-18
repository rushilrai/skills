---
name: implement
description: "Implement a spec (GitHub issue or file) end to end: clarify what's unclear, plan phases, have subagents build each phase, gate on typecheck + tests, review via subagent, ship one PR with phases as commits."
disable-model-invocation: true
argument-hint: "<issue number | spec path> [extra guidance]"
---

Implement the work described by the spec the user points at. You are the **orchestrator and strict checker**: subagents write the code, you plan, gate, and verify. Do not write feature code yourself except for trivial glue that would cost more to delegate than to type.

## 1. Load the spec

- An issue number → `gh issue view <n> --comments`. A path → read it. Neither → ask.
- Read the repo's `AGENTS.md` (root + the nested one for every workspace the spec touches) and `CONTRIBUTING.md` if present. These are the standards the review will hold the work to.
- Read the docs the spec or the touched modules point at. Don't re-derive what they already say.

## 2. Clarify what's unclear

If anything in the spec is ambiguous, contradicts the code, or leaves a design choice open, call the Skill tool with "grilling" **before** planning. Keep it to the genuinely open questions — the spec has already been discussed once. If nothing is unclear, say so in one line and move on.

## 3. Plan phases

Break the work into **phases**: each phase is one coherent, reviewable step that leaves the tree green (typecheck + tests pass). Order by dependency. For each phase record: what it delivers, which files/modules it touches, the tests that prove it, and its seams (existing seams preferred; the fewer the better).

Show the plan to the user. Do not start until they confirm.

## 4. Branch and PR

- Create a branch off the default branch (`<type>/<slug>`), unless the user says to use the current one.
- One PR per spec. Phases land as **separate commits** on that PR, in plan order. Open the PR as draft after the first phase lands so progress is visible.
- Commit messages follow `CONTRIBUTING.md`; if the repo has none, one-line imperative subject + a body explaining *why*.

## 5. Build each phase with a subagent

Default: phases run **sequentially on the branch** — each subagent starts from the tree the previous one left. Use worktree isolation only when two phases are genuinely independent and the user has agreed to parallelise.

The subagent prompt must carry: the spec (or link), the phase's slice of the plan, the relevant `AGENTS.md` rules, the seams and the tests expected, and the instruction to use the "tdd" skill where a test-first loop fits. Prefer the strongest model available for subagents (Opus-class); the phase's correctness is worth more than the tokens.

When the subagent reports back, **you check** — read the diff, don't trust the summary:

- Run the workspace's typecheck and the affected test files; run the full test suite once at the end of the phase.
- Confirm the phase did what the plan said — no more, no less. Scope creep goes back to the subagent to remove.
- Confirm nothing destructive happened outside the phase's scope.

If it fails, send the subagent back with the specific failure. Loop until green. Then commit the phase.

## 6. Review before hand-off

After the last phase: run the full gates one more time (typecheck, lint if configured, whole test suite), then spawn a **subagent** that calls the Skill tool with "code-review" against the merge-base of the branch, passing the spec source. Read its Standards and Spec findings.

- Fix everything real (via a subagent for anything non-trivial), re-run the gates, and commit the fixes as their own commit.
- Findings you disagree with: say why in the PR description, don't silently drop them.

## 7. Ship

Mark the PR ready. The PR description carries: the spec link, the phase list (one line each), how it was verified (the exact commands and their result), and any review findings deliberately not actioned. Report the same to the user, plainly — if a gate is red or a phase was skipped, say so.
