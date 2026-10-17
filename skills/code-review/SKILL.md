---
name: code-review
description: Review the changes since a fixed point (commit, branch, tag, or merge-base) along three axes — Standards (does the code follow this repo's documented coding standards?), Spec (does the code match what the originating issue/spec asked for?) and Cohesion (does the change sit where the codebase would expect it and reuse what is there?) — plus a Design axis for changes that touch a screen. Runs the reviews in parallel sub-agents and reports them side by side. Use when the user wants to review a branch, a PR, work-in-progress changes, or asks to "review since X".
---

Multi-axis review of the diff between `HEAD` and a fixed point the user supplies:

- **Standards** — does the code conform to this repo's documented coding standards?
- **Spec** — does the code faithfully implement the originating issue / spec?
- **Cohesion** — does the change fit how the codebase is already structured: right module and layer, reuses what exists, reads where a maintainer would look for it?
- **Design** — only when the diff touches a screen: does it look and behave like the rest of the product, seen running?

Each axis runs as a **parallel sub-agent** so they don't pollute each other's context, then this skill aggregates their findings. Review sub-agents run on the strongest read-only model available (Fable-class if the harness offers it); they must not edit files.

## Process

### 1. Pin the fixed point

Whatever the user said is the fixed point — a commit SHA, branch name, tag, `main`, `HEAD~5`, etc. If they didn't specify one, ask for it.

Capture the diff command once: `git diff <fixed-point>...HEAD` (three-dot, so the comparison is against the merge-base). Also note the list of commits via `git log <fixed-point>..HEAD --oneline`.

Before going further, confirm the fixed point resolves (`git rev-parse <fixed-point>`) and the diff is non-empty. A bad ref or empty diff should fail here — not inside two parallel sub-agents.

### 2. Identify the spec source

Look for the originating spec, in this order:

1. An issue number or path the user passed as an argument.
2. Issue references in the commit messages or PR body (`#123`, `Closes #45`) — fetch with `gh issue view <n> --comments`.
3. A spec file under `specs/` matching the branch name or feature.
4. If nothing is found, ask the user where the spec is. If they say there isn't one, the **Spec** sub-agent will skip and report "no spec available".

### 3. Identify the standards sources

Anything in the repo that documents how code should be written: `AGENTS.md` / `CLAUDE.md` at the root **and** the nested ones in every workspace the diff touches, `CONTRIBUTING.md`, and anything they point at (e.g. a card format doc). Nested `AGENTS.md` files are the primary standards source in a monorepo — always collect them.

On top of whatever the repo documents, the Standards axis always carries the **smell baseline** below — a fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when a repo documents nothing. Two rules bind it:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation — and, like any standard here, skip anything tooling already enforces.

Each smell reads *what it is* → *how to fix*; match it against the diff:

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

### 4. Decide whether the Design axis runs

The Design axis runs when the diff touches anything a user sees: screens, components, routes, styles, copy, motion, or the marketing site. Decide from the file list, not from the commit messages. If it runs, it needs the app running: ask the user how to launch it if the repo's `AGENTS.md` does not say (a simulator build, `bun run dev`, a preview), and note in the report if it could not be launched and the pass was done from code alone.

### 5. Spawn the sub-agents in parallel

**Standards sub-agent prompt** — include:

- The full diff command and commit list.
- The list of standards-source files you found in step 3, **plus the smell baseline from step 3** pasted in full — the sub-agent has no other access to it.
- The brief: "Report — per file/hunk where relevant — (a) every place the diff violates a documented standard: cite the standard (file + the rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls — documented-standard breaches can be hard, but baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words."

**Spec sub-agent prompt** — include:

- The diff command and commit list.
- The path or fetched contents of the spec.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words."

If the spec is missing, skip the Spec sub-agent and note this in the final report.

**Cohesion sub-agent prompt** — include:

- The diff command and commit list.
- The list of standards-source files from step 3 (the nested `AGENTS.md` files describe each workspace's layering; this axis reads them for structure, not style).
- The brief: "Read the diff against the surrounding codebase, not just itself. Report: (a) code placed in the wrong module, layer or workspace for what it does (cite where the equivalent existing code lives); (b) a parallel to something that already exists: a second helper, type, query, constant or component doing the same job as one already in the tree, name both; (c) a new abstraction, folder or pattern that the rest of the codebase does not use, when an existing pattern would have carried it; (d) a change that a maintainer would not find where they would first look. For each finding, say what the cohesive version would be. Judgement calls, not violations. Under 400 words."

**Design sub-agent prompt** (only when step 4 said so) — include:

- The diff command and commit list, and the list of screens, routes or pages the diff touches.
- How to run the app and reach each touched screen; the repo's `AGENTS.md` for the app, which should name the design conventions (spacing, type, colour, motion, empty and loading and error states).
- The brief: "Open each touched screen in the running app and compare it with the neighbouring screens of the same product. Report: (a) anything that does not match the product's existing look: spacing, type, colour, iconography, corner radius, motion; (b) missing states: empty, loading, error, long content, no network, where the neighbours have them; (c) copy that does not read like the rest of the product; (d) interactions that fight the platform's conventions. Attach a screenshot path for each finding where you can. Findings only; do not propose redesigns. Under 400 words."

### 6. Aggregate

Present the reports under `## Standards`, `## Spec`, `## Cohesion` and, when it ran, `## Design` headings, verbatim or lightly cleaned. Do **not** merge or rerank findings — the axes are deliberately separate (see _Why separate axes_).

End with a one-line summary: total findings per axis, and the worst issue _within each axis_ (if any). Don't pick a single winner across axes — that's the reranking the separation exists to prevent.

## Why separate axes

A change can pass one axis and fail another:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**
- Code that is correct and clean but lands in the wrong module beside a duplicate of something that already existed → **Standards and Spec pass, Cohesion fail.**
- Code that is correct, clean and well placed but whose screen looks nothing like the one next to it → **Design fail.**

Reporting them separately stops one axis from masking another.
