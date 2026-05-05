---
name: collab
description: Connect multiple Claude Code sessions to sync context, plan work, and split tasks across git branches. Subcommands - join, plan, update, sync, status.
---

# Collab — Multi-Session Coordination

Coordinate two or more Claude Code sessions working in the same repo. Sessions sync context, agree on a work split, then execute on separate git branches.

## Subcommands

Parse the first argument to determine the subcommand:

- `/collab join <name>` — Register this session, write context dump, read others
- `/collab plan` — Propose or review a work split
- `/collab update <message>` — Post a progress update
- `/collab sync` — Re-read everything: sessions, plan, messages
- `/collab status` — Quick view of plan, ownership, recent messages

If no argument is given, explain the available subcommands briefly.

---

## Directory Protocol

All state lives in `.collab/` at the repo root. Structure:

```
.collab/
  sessions/
    <name>.md       # Each session's context dump
  plan.md           # The agreed work split
  messages/
    NNN-<name>.md   # Timestamped progress messages
```

On first interaction with `.collab/`, check if `.collab/` is in `.gitignore`. If not, add it.

---

## Subcommand: `join`

**Usage:** `/collab join dashboard`

1. Create `.collab/sessions/` and `.collab/messages/` directories if they don't exist.
2. Ensure `.collab/` is gitignored.
3. Write this session's context dump to `.collab/sessions/<name>.md` using the template below.
4. Read all other files in `.collab/sessions/` and `.collab/messages/` and `plan.md` if it exists.
5. Summarize what you learned from other sessions — what they're working on, key decisions, current state.
6. If a `plan.md` exists and has a task assigned to this session's name, check out the assigned branch. If the branch doesn't exist, create it from the plan's specified base.
7. If no plan exists yet, suggest the user run `/collab plan` to propose a work split.

### Context Dump Template

Write to `.collab/sessions/<name>.md`:

```markdown
---
session: <name>
joined: <ISO timestamp>
updated: <ISO timestamp>
---

## What I'm working on
<Brief description of this session's focus and goals>

## Files touched
<List of files this session has created or modified>

## Key decisions
<Architecture choices, library picks, patterns established — anything another session needs to know>

## Current state
<What's done, what's in progress, what's blocked>

## Open questions
<Unresolved decisions that might affect other sessions>
```

Fill this out based on your actual conversation context. Be specific — the other session needs enough detail to avoid conflicts and make good decisions.

---

## Subcommand: `plan`

**Usage:** `/collab plan` or `/collab plan "B builds the WebSocket client, A builds the dashboard"`

The user can optionally provide guidance after the subcommand — high-level direction on how work should be split, what each session should own, priorities, constraints, or any other detail. **This guidance takes priority over the agent's own judgment** when drafting the plan.

**Who proposes:** The session that most recently joined (i.e., the one the user just briefed with fresh intent) should be the one to propose the plan. It has the clearest picture of what needs to happen. The other session reviews and accepts or amends. If both sessions have been around a while and neither is "newer," the session running `/collab plan` proposes.

### If no plan exists (proposing):

1. Read all session context dumps in `.collab/sessions/`.
2. Using **the user's guidance (if provided)**, your conversation context, AND the other sessions' context dumps, draft a work split as `.collab/plan.md` using the template below. The user's explicit guidance is the primary input — fill in the details (specific files, branch names, shared boundaries) around it.
3. Present the plan to the user for approval before writing.
4. On approval, write `plan.md` and create **all** git branches from the specified base. The proposing session is responsible for creating every branch in the plan.
5. Set up **git worktrees** so each session works in its own directory without interfering with the other. See the "Git Worktrees" section below for details.
6. `cd` into this session's worktree directory.
7. Write a message to `.collab/messages/` announcing the plan.

### If a plan exists (reviewing):

1. Read `plan.md` and present it.
2. Ask the user: accept as-is, or suggest amendments?
3. If accepted, `cd` into this session's worktree (it should already exist — the proposer created it).
4. Write a message to `.collab/messages/` confirming acceptance.
5. If amendments needed, update `plan.md`, create any new worktrees if the amendment changes branch names, and write a message noting the changes.

### Plan Template

```markdown
---
created: <ISO timestamp>
proposed_by: <session name>
status: proposed | accepted
base: <branch name or commit SHA the work branches from>
---

## Goal
<One-paragraph description of what the collaboration is trying to achieve>

## Work split

### <session-name-1>
- **Branch:** `<branch-name>`
- **Worktree:** `.collab/worktrees/<session-name-1>`
- **Owns:** <files, directories, or areas of responsibility>
- **Tasks:**
  - [ ] Task 1
  - [ ] Task 2

### <session-name-2>
- **Branch:** `<branch-name>`
- **Worktree:** `.collab/worktrees/<session-name-2>`
- **Owns:** <files, directories, or areas of responsibility>
- **Tasks:**
  - [ ] Task 1
  - [ ] Task 2

## Shared boundaries
<APIs, types, contracts, or interfaces that both sessions depend on. Be explicit about the shape so both sides can code against it independently.>

## Integration notes
<How the branches come together — what to merge first, any ordering dependencies>
```

---

## Subcommand: `update`

**Usage:** `/collab update "finished the auth routes, schema unchanged"`

Or without a quoted message — the skill will summarize recent progress automatically.

1. Determine the next message number by counting files in `.collab/messages/`.
2. Write to `.collab/messages/NNN-<name>.md`:

```markdown
---
from: <session name>
time: <ISO timestamp>
---

<message content>
```

3. Also update this session's context dump in `.collab/sessions/<name>.md` with refreshed state.

If no message argument is provided, generate one by summarizing what's changed since the last update — files modified, tasks completed, decisions made.

---

## Subcommand: `sync`

**Usage:** `/collab sync`

1. Re-read all files in `.collab/` — sessions, plan, messages.
2. Update this session's own context dump with current state.
3. Report to the user:
   - Any new messages since last sync
   - Changes to other sessions' context dumps
   - Current plan status and task completion
4. If the plan has been amended by another session, highlight the changes.

---

## Subcommand: `status`

**Usage:** `/collab status`

Quick read-only view. Do not update any files.

1. Read `plan.md` and all session files.
2. Read recent messages (last 5).
3. Present a compact summary:
   - Who's working on what
   - Task checklist status
   - Branch names
   - Recent messages (one line each)

---

## Session Identity

This session's name is set on `/collab join <name>` and persists for the conversation. If the user runs a subcommand other than `join` without having joined, check `.collab/sessions/` — if only one session file does NOT match any currently active session, infer identity. Otherwise, ask.

To detect which session file is "ours": look for context that matches what this conversation has been doing — files discussed, topics covered. If ambiguous, ask the user.

---

## Git Worktrees

Since all sessions share the same repo directory, a regular `git checkout` in one session would change the working tree for all sessions. **Use git worktrees** so each session has its own isolated directory.

### How it works

Worktrees live in `.collab/worktrees/` (also gitignored). Each session gets a worktree named after its role:

```
.collab/
  worktrees/
    dashboard/    # Session A works here — on branch feat/dashboard
    client/       # Session B works here — on branch feat/client
```

### Creating worktrees (proposer does this)

When the plan is approved, the proposer creates all worktrees:

```bash
# Create branches from base
git branch feat/dashboard <base>
git branch feat/client <base>

# Create worktrees
git worktree add .collab/worktrees/dashboard feat/dashboard
git worktree add .collab/worktrees/client feat/client
```

### Working in a worktree

After worktree creation, the session must `cd` into its worktree:

```bash
cd .collab/worktrees/<session-name>
```

From there, all file reads, edits, and git operations happen against that worktree's branch. The main repo directory stays on whatever branch it was on — untouched.

### Important notes

- The `.collab/` directory itself is in the main repo root, **not** inside any worktree. All sessions read/write `.collab/` files using the **absolute path** to the main repo's `.collab/` directory. Before joining or syncing, resolve the main repo root (e.g., via `git worktree list` — the first entry is the main worktree).
- When reading/writing `.collab/sessions/`, `.collab/messages/`, or `.collab/plan.md`, always use the main repo root path, not the worktree-relative path.
- `git worktree list` shows all active worktrees if you need to inspect state.

---

## Rules

- **Never modify another session's context dump.** Only write to your own.
- **Messages are append-only.** Never edit or delete existing messages.
- **Plan amendments must be announced.** If you change `plan.md`, always write a message explaining what changed.
- **Stay on your branch.** After plan acceptance, do not check out or modify another session's branch.
- **Be specific in context dumps.** Vague summaries ("working on the frontend") are useless. Include file paths, function names, schema shapes.
- **Shared boundaries are critical.** The plan's "Shared boundaries" section is the contract. If you need to change it, post an update message first so the other session knows.
