# skills

Rushil's agent skills — the small set of workflows I actually run in Claude Code (and any Agent-Skills-compatible harness).

Most of these started life in [mattpocock/skills](https://github.com/mattpocock/skills) (MIT, © Matt Pocock — see `LICENSE-mattpocock-skills`) and were copied here so they can be tweaked to how I work. Other sources may be added over time; each skill's origin is recorded below.

## Layout

```
skills/<name>/SKILL.md      the skill (+ any support files, + agents/openai.yaml for Codex)
scripts/link-skills.sh      symlinks every skill into ~/.claude/skills and ~/.agents/skills
```

## Install

```bash
git clone https://github.com/rushilrai/skills ~/Documents/GitHub/rr/skills
~/Documents/GitHub/rr/skills/scripts/link-skills.sh
```

Symlinks, so `git pull` updates them in place. Re-run the script after adding or renaming a skill.

## Skills

| Skill | Invoke | Source | What changed here |
|---|---|---|---|
| `grill-me` | `/grill-me` | mattpocock | unchanged — wrapper that calls `grilling` |
| `grilling` | model-invoked | mattpocock | unchanged |
| `research` | model-invoked | mattpocock | unchanged |
| `to-spec` | `/to-spec` | mattpocock | publishes to **GitHub Issues** with a `spec` label (no setup skill, no triage labels); reads `AGENTS.md`/reference docs for vocabulary instead of CONTEXT.md/ADRs |
| `implement` | `/implement <issue \| path>` | mattpocock (rewritten) | orchestrator: load spec → grill what's unclear → phase plan (user confirms) → subagents build each phase sequentially on the branch → orchestrator checks diff + runs typecheck/tests → `code-review` via subagent → one PR per spec, phases as commits |
| `code-review` | model-invoked | mattpocock | spec source is a GitHub issue / path; standards sources are root **and nested** `AGENTS.md` + `CONTRIBUTING.md` (no tracker doc dependency) |
| `wayfinder` | `/wayfinder` | mattpocock | tracker hardwired to GitHub Issues (`wayfinder:map` / `wayfinder:<type>` labels, `Blocked by:` body convention); grilling tickets don't require `domain-modeling` |
| `domain-modeling` | model-invoked | mattpocock | glossary (`CONTEXT.md`) only — ADR half removed; decisions live in project docs |
| `teach` | `/teach <topic>` | mattpocock | unchanged — run it in a dedicated learning directory, not a project repo |
| `passbaton` | `/passbaton` | original | writes a copy-paste handoff message so a fresh session can pick up where this one left off |

## Conventions these skills assume

- Work is tracked in **GitHub Issues** on the repo (`gh` CLI). Specs are issues labelled `spec`.
- Repo conventions live in `AGENTS.md` (root + one per workspace) and `CONTRIBUTING.md`; skills read those, not a separate standards doc.
- Subagents do the building; the orchestrating session checks. Prefer the strongest available model for subagents.
