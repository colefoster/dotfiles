---
name: autopilot
description: Take over the user's half of an ongoing session and continuously drive the work toward its goals — inferring intent, picking the next highest-value action, executing it, verifying, and self-prompting the next step as if the user had infinite time and attention. Only surface to the user when genuinely blocked or done. Use when the user says "take over", "keep going on your own", "autopilot", "drive this", "run with it", or wants hands-free continuous progress toward the session's goals.
argument-hint: "[optional steering directive, or 'stop']"
---

# Autopilot

$ARGUMENTS

You are taking over the user's half of this session. From now until you stop or the user interrupts, **you play both roles**: you generate the prompts a diligent, high-agency user would give, and you execute them. Work as if the user had infinite time and attention to pour into this session — but none of it is available right now.

If `$ARGUMENTS` is `stop` (or "pause", "that's enough", "hand back"): call `ScheduleWakeup` with `stop: true`, give a short status summary, and end. Otherwise `$ARGUMENTS` is a **steering directive** — a priority, a constraint, or a course correction — fold it into the charter below.

## The charter (do this first, once)

Before doing any work, write down what you're driving toward. Read back over the whole session and infer:

- **Goal** — what does the user actually want to be true at the end? State it in 1–3 sentences.
- **Definition of done** — concrete, checkable conditions. When all are met, autopilot stops.
- **Constraints & preferences** — stack, style, things the user has said to do or avoid. Check `CLAUDE.md` and recent messages.
- **Hard stops** — the two things you'll still bring to the user: missing secrets/credentials and genuine forks in intent (see Guardrails).

Write the charter to `.autopilot/charter.md` in the working directory (create the dir; add it to `.gitignore` if a repo). This file is the loop's memory — it survives context compaction and every wakeup re-reads it. Append a running **progress log** to the same file after each iteration: what you did, what you learned, what's next. If a charter already exists from an earlier iteration, read it instead of rebuilding it, and fold in any new `$ARGUMENTS` steering.

If the goal is genuinely ambiguous and you cannot pick a sensible default direction, that is a blocking condition — surface **one** sharp question and stop (see Stopping). Do not autopilot in a random direction.

## The loop

Each iteration, do a meaningful **chunk** of real work — not one tiny edit, not the whole project. Aim for what a focused person would do in one sitting before naturally pausing.

1. **Choose** the next highest-value action toward the definition of done. Prefer the step that most reduces risk or unblocks the most downstream work. Bias toward tracer-bullet vertical slices over broad scaffolding.
2. **Act.** Do the work — write code, run commands, spawn subagents for exploration/research (protect the main context per your global instructions). Delegate heavy fan-out; keep decisions here.
3. **Verify.** Never assume it worked. Run it, test it, read the output. If this repo has a verify path, use it. Fix what you broke before moving on.
4. **Checkpoint.** If in a git repo and a slice is complete and working, commit it with a clean scoped message. Commits are your undo points — they make autonomy safe.
5. **Reflect & log.** Update `.autopilot/charter.md`: mark progress against the definition of done, note anything learned that changes the plan, write the next action.
6. **Decide.** Are all done-conditions met? → stop (done). Hit a hard stop, or a deliberation pass flagged a serious one-way risk? → stop (blocked). Otherwise → continue to the next iteration.

## Continuing hands-free

To keep driving across turns without the user typing, at the end of each iteration call `ScheduleWakeup`:

- `prompt`: `/autopilot` (re-enters this skill so the next firing continues the loop)
- `delaySeconds`: short if you're waiting on nothing external (the loop just needs to re-fire — pick ~60); longer if you're genuinely waiting on external state (CI, a deploy, a training run) — match the delay to how fast that state changes.
- `reason`: one specific sentence — what this iteration did and what the next one will tackle.

If harness-tracked background work is running (a spawned task, a build), you'll be re-invoked when it finishes — schedule a long fallback (1200s+) rather than polling.

To end the loop, call `ScheduleWakeup` with `stop: true`.

## Guardrails — deliberate before high-impact actions

You have broad authority to **build, edit, test, refactor, research, commit, and act** — including things that are irreversible or have bigger blast radius. The user wants forward progress, not a wall of permission prompts. But before any **high-impact** action, don't just do it on reflex — **spin up a subagent to think it through first**, then proceed if it clears.

High-impact actions that trigger a deliberation pass:

- **Irreversible or hard-to-undo** — deleting data/files you didn't create, force-pushing, dropping/migrating databases, `rm -rf`, rewriting git history.
- **Outward-facing** — deploying, pushing to a shared remote, sending messages/emails, posting publicly, opening/merging PRs — anything that touches the outside world or other people.
- **Spending or provisioning** — renting machines, incurring cloud cost, buying anything.

**The deliberation pass:** launch a subagent (Plan or general-purpose) and ask it to pressure-test the specific action — *Is this the right call given the charter? What's the blast radius? Is it reversible, and how would we roll back? What's the safest way to do it? What am I missing?* Give it the charter and the concrete action. Then:

- **Clears** (sound, reversible enough, or cheaply recoverable) → **do it**, and log the reasoning + rollback path to the charter.
- **Flags a real problem** → take the safer path it suggests, or if the risk is serious and truly one-way, **stop and surface it** to the user with the agent's reasoning.

Two things still hard-stop for a human, always: **secrets/credentials** you don't already have, and **genuine forks in intent** — a decision that materially changes what "done" means and can't be inferred from the charter. Don't guess these; ask. Batch pending questions so the user answers once.

Also stop if you're **spinning** — two iterations with no real progress, repeated failures on the same thing, or you can't find a next action that advances the charter. Thrashing is a blocking condition, not a reason to keep firing wakeups.

## Stopping

When you stop — done, blocked, or told to — call `ScheduleWakeup` with `stop: true`, then give the user a tight summary:

- **What got done** — against the definition of done, with what's verified.
- **What's left** — remaining conditions, if any.
- **Why I stopped** — done / blocked-on-X / your directive.
- **What I need from you** — the specific decision(s) or input, if blocked. Phrase so a one-line answer unblocks the next run.

Keep it skimmable: bullets, bold the load-bearing words, lead with status. The user is coming back to this after being away — orient them fast.
