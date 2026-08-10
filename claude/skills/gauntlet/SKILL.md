---
name: gauntlet
description: Iterate an artifact against a concrete reference bar using a blind fresh-context critic each round. A lightweight distillation of the "gauntlet loop" — no agent fleet. Use when the user wants to push something (code, a UI, a page, a piece of writing) up to the quality of a real reference and says things like "make this match X", "get it as good as Y", "critique and improve until it's there", or "run a gauntlet on this".
argument-hint: "[what to improve] — optional"
---

# Gauntlet

Push one artifact up to the quality of a **concrete reference bar**, using a **blind critic in a fresh context** each round. This is the lightweight version of the gauntlet-loop pattern: you keep the three ideas that matter and drop the agent fleet.

**The three load-bearing ideas:**
1. **A real, inspectable bar** — a specific reference the work is measured against, not "make it good."
2. **Blind critique separated from creation** — the critic runs in a fresh context and never sees how the work was made. You (the builder) do not grade your own work.
3. **One biggest gap per round, bounded loop** — focused fixes, a hard round cap, stop when gains go marginal.

You are the builder. A throwaway subagent is the critic. That's the whole mechanism — one cheap subagent per round, not a swarm.

## When NOT to use this

- **No objective bar exists** and the goal is genuinely subjective taste → use `/three-designs` instead.
- **The design itself is in question**, not the execution quality → use `/step-back` or `/two-claudes`.
- **A mistake is costly or irreversible**, or you can't actually observe the true result of a change → don't loop autonomously; do it by hand.

## Process

### 1. Nail down the bar (do not skip)

The skill does not start without a concrete, inspectable bar. The bar is the reference the critic compares against. Good bars are things you can *point at*:

- A **screenshot / live URL / design** the output should visually match
- A **reference implementation, file, or repo** to match in structure or quality
- A **test suite, perf target, or measurable spec** ("p95 < 100ms", "passes these cases")
- **Reference prose** for writing ("as tight as this paragraph")

If the user gave a bar in `$ARGUMENTS` or the conversation, restate it in one line and proceed. If there's **no bar**, ask for one — offer to help construct it (e.g. "point me at the page you want this to feel like"). A vague bar like "perfect" is not a bar; it produces motion with no stop condition. Push back until the bar is inspectable.

Also state the **round cap** (default **3**) and confirm the artifact under test.

### 2. Build / take a first pass

Get the artifact to a first honest attempt against the bar. If it already exists, this is just the current state. Keep a **compact note of what the artifact is and where it lives** — you'll hand this to the critic, not your reasoning.

### 3. Blind critique — one fresh subagent

Spawn **one** `general-purpose` subagent as the critic. Its context is deliberately clean:

**Give the critic:**
- The **bar** (the reference — paste it, link it, or point it at the file/URL/screenshot)
- The **artifact** as it stands (the file, the rendered output, the running thing — however it can inspect it directly)
- Nothing about how you built it, what you already tried, or prior critiques

**Ask the critic for exactly:**
1. A **blind A/B verdict** — does the artifact meet the bar? (`below` / `at` / `above`)
2. The **single biggest gap** between artifact and bar — the one thing that, fixed, closes the most distance. Not a laundry list. One gap, concrete, with *where* and *why it misses*.
3. A **one-line marginal check** — is the remaining gap worth another round, or is this close enough that further work is diminishing returns?

Keep the critic cheap: cap its report tightly. It judges; it does not fix.

> Why a subagent and not just re-reading it yourself: the point is a context that never saw your reasoning. Grading your own work is the exact bias this pattern removes. Do not shortcut this step by self-critiquing inline.

### 4. Fix the one gap

Address the single biggest gap the critic named. Don't opportunistically rewrite everything — fix the thing, keep the rest stable. If fixing it reveals a second obvious issue, note it but stay focused.

### 5. Loop or stop

Go back to step 3 with a **fresh** critic (new context every round — never reuse the prior critic; it would carry bias). Stop when **any** of these is true:

- Critic returns **`at`/`above`** — the artifact meets the bar.
- The **marginal check says stop** — remaining gap isn't worth another round.
- **Round cap hit** (default 3).
- **Same gap twice, unfixed** — you're spinning, not improving. Stop and surface it to the user; the bar may be unreachable with this approach, or the gap needs a design change (→ `/step-back`).

### 6. Report

Short summary:
- **The bar** you measured against
- **What each round changed** — one line per round, the gap that round closed
- **Final verdict** from the last critic (`below`/`at`/`above`) and why you stopped
- If you stopped short of the bar, **what's still missing** and the honest reason

## Anti-patterns

- **No real bar.** "Make it better" with nothing to point at. The bar is the skill; without it, use a different one.
- **Self-critiquing inline.** Re-reading your own work in the same context is not a blind critic. Spawn the subagent.
- **Laundry-list critiques.** Ten small notes scatter effort. Force the *one* biggest gap per round.
- **A fleet.** One critic subagent per round. If you're spawning builders and smoothers and parallel critics, you've rebuilt the heavy version — that's the thing this skill exists to avoid.
- **Unbounded looping.** No round cap, or chasing "perfect." Cap it, honor the marginal check, and stop on repeats.
- **Fixing everything each round.** Broad rewrites destabilize what already worked. One gap at a time.
