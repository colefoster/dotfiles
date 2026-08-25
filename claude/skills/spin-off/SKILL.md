---
name: spin-off
description: Start a second, user-driven Claude session beside this one — a tmux split (or window, or session) seeded with a self-contained briefing on whatever work is being handed over. Use when the user wants to spin off, fork, branch, or peel off a task into another session, open a second Claude on something, or run a side quest in parallel without an agent-managed subagent.
argument-hint: "[what the new session should work on] [--raw pass it through verbatim] [-w window | -s session] [-v stacked] [-f focus it] [-d DIR]"
---

# Spin off a parallel session

$ARGUMENTS

Hand a slice of work to a **peer Claude session** the user drives themselves. This is not a subagent: nothing reports back, nothing merges, and this session keeps its own thread. Use it when work splits cleanly in two and the user wants both halves live.

Do not use this for work you can do yourself, and do not use it as a substitute for the Agent tool when the user wants a result returned here.

## Phase 1 — Scope the handoff

Read `$ARGUMENTS` for what the new session takes on. If it names something specific, that is the scope. If it is vague or empty, pick the most separable strand of the current work and say which one you chose in the summary.

Decide the working directory. It defaults to this one; use `-d DIR` when the work lives in another repo.

## Phase 2 — Write the briefing

**Skip this phase when `$ARGUMENTS` contains `--raw`.** The text that remains after the flags is then the prompt itself, verbatim: write it to the file unchanged, add nothing, and note "raw" in the summary. Use `--raw` as written even when the text reads as terse or incomplete — passing it through untouched is the point of the flag.


Write the prompt as if **the user is speaking to a fresh Claude**, first person ("I want you to..."), not as a report about this session. The new session loads `CLAUDE.md` and `MEMORY.md` on its own, so do not restate anything in those.

Include only what is load-bearing:

- **The task** — one or two sentences on the goal and why it matters.
- **Where things stand** — the project, the branch, what already exists, what is half-done.
- **Boundaries** — what this session is still working on, so the two do not edit the same files. Name the files or areas that are off limits.
- **First step** — the concrete thing to do first.
- **Pointers** — paths, `file:line` references, commands to run, issue numbers.

Keep it under about 200 words.

## Phase 3 — Launch it

1. Write the prompt as plain text — no fences, no surrounding prose — to a file under `${TMPDIR:-/tmp}`.
2. Run `~/dotfiles/zsh/common/cc-spawn [flags] <that file>`.

Flags, mapped from `$ARGUMENTS`:

| Flag | Effect |
|---|---|
| _(none)_ | A pane beside this one. Side by side when the window is at least 160 columns, stacked when it is tall enough, otherwise a window. |
| `-v` | Force the stacked split. |
| `-w` | A tmux window in this session instead of a pane. |
| `-s` | A detached tmux session of its own, reachable with `ccl`. |
| `-f` | Move the terminal to the new session. Off by default, so this session keeps the keyboard. |
| `-d DIR` | Working directory for the new session. |
| `-t TITLE` | Pane or window title. |
| `-T` | Leave the workspace-trust dialog to the new session. Off by default: `cc-spawn` pre-accepts trust for the target directory, so a seeded session does not stall on that prompt. |
| `--raw` | Skip Phase 2 and seed the new session with the argument text verbatim. `cc-spawn` does not take this flag — strip it before building the command. |

`cc-spawn` prints the target and the path it parked the seed prompt at. It picks the Claude account from the target directory, the same way the `claude` wrapper does.

If `cc-spawn` exits non-zero — it refuses outside a tmux-wrapped session — fall back to printing the prompt in a fenced `text` block and piping the raw text to `pbcopy`, then say so in one line.

## Output

Three bullets, no more:

- What the new session took on.
- Where it landed — the pane, window, or session name, and how to reach it (`ctrl+b o` for a pane, `ctrl+b <n>` for a window, `ccl <name>` for a session).
- What this session is still holding, if anything.
