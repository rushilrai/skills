---
name: passbaton
description: Generate a handoff message for a fresh Claude Code session to pick up where we left off
disable-model-invocation: true
---

# Passbaton — Session Handoff

The user is running low on context and wants to continue this work in a fresh Claude Code session. Your job is to produce a single self-contained starter message they can paste into the new session so the next Claude can pick up without needing to be re-briefed.

## What to produce

Output a markdown block (inside a single fenced code block, so it's one-click copyable) containing the handoff. No preamble, no explanation, no "here you go" — just the code block. After the code block you may add one short line confirming it's ready to copy, nothing more.

## Structure of the handoff

Write it as if *you* (the next Claude) are being addressed. Use second person ("You were helping me..."). Keep it balanced — enough context to be useful, not a wall of text. Aim for something the next session can skim in under 30 seconds.

Use this structure, with these exact headers:

```
# Continuing from previous session

## Task
One or two sentences: what we're building / trying to accomplish overall.

## Where we are
Current state of the work. What's done, what's in progress right now, and the very next concrete step. Include file paths, function names, command names — anything the next session needs to orient quickly. If there's a repo or working directory, say so.

## Key decisions made
Bulleted list of meaningful decisions that shape the current approach, each with a brief "because..." so the next session doesn't relitigate them. Skip trivial choices; include ones that would be non-obvious or reversible.

## Gotchas
Bulleted list of things that didn't work, dead ends, surprising behaviour, or traps to avoid. If there are none worth mentioning, write "None so far." — don't pad.

## Pick up by
One or two sentences on the exact next action. Be specific: "run X", "open file Y and continue from line Z", "ask me about W before proceeding."
```

## Rules

- **Draw only from this session's actual history.** Don't invent context, don't generalize, don't add best-practice advice that wasn't discussed.
- **Be concrete.** Filenames, function names, exact commands. Vague handoffs ("we were working on the backend") defeat the purpose.
- **Be honest about uncertainty.** If a decision was tentative or a piece of state is unclear, say so — don't paper over it.
- **Skip sections that genuinely have no content** by writing a short honest line ("No major decisions yet — still in exploration.") rather than fabricating.
- **Don't include secrets, tokens, or keys** even if they appeared in the session. Reference them by name only (e.g. "the HDFC API key in .env").
- **No signoff, no meta-commentary inside the block.** The handoff should read as briefing material, not a letter.

## After generating

After the fenced code block, add exactly one line:
`Ready to paste into the new session.`

Nothing else.
