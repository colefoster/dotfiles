---
name: step-back
description: Pause hands-on work and reassess an area from a higher level — what the ideal architecture looks like for the goals, and where ad-hoc development has accrued friction. Use when the user wants to step back, zoom out, take stock, rethink the architecture, or pause after a stretch of ad-hoc work or a refactor that didn't go cleanly.
argument-hint: "[area or path — optional]"
---

# Step Back

$ARGUMENTS

Stop building. Zoom out. Look at the area as a whole and ask whether the shape of it still serves the goals — or whether it has drifted into something held together by ad-hoc fixes.

The user wants a thinking partner here, not a doer. **Do not propose code changes, do not open issues, do not start refactoring.** The output of this skill is shared understanding and a recommendation about direction.

## Process

### 1. Scope the area

If the user named an area or path in $ARGUMENTS, use that. Otherwise ask one question: *"Which area are we stepping back on?"* — and wait. Don't guess.

### 2. Read the recent history of the area

Before exploring code, read the git log for the area (last 30–60 commits, or last ~2 months — whichever is shorter). You are looking for **fingerprints of ad-hoc development**:

- **Two modules drifting toward the same job** — e.g. `deprecate X — Y replaces it`, parallel tools that overlap, one tool quietly killed
- **Per-thing accretion with no shared model** — detectors / readers / handlers / endpoints added one-at-a-time, each its own special case, no overarching schema
- **Reshape commits in adjacent pairs** — `split X into Y + Z` followed shortly by another split/move/rename in the same area. One split is housekeeping; two in a row means the shape is wrong.
- `fix:` / `revert:` commits that undo or patch over a recent change
- Repeated touches to the same file across many small commits
- Commits whose message admits a problem (`avoid`, `workaround`, `stop`, `was broken`, `actually`, `hack`)
- Long gaps followed by a flurry — areas that got revisited under pressure

Note these signals. They are evidence, not conclusions.

### 3. Explore the current state

Use the Agent tool with `subagent_type=Explore` to map the area as it stands today:
- What are the modules, and what does each own?
- Where are the seams? Are they load-bearing or accidental?
- What does the data flow look like end-to-end?
- Where does understanding require bouncing between many files?

You are building a mental model, not an inventory. Skip exhaustive listings.

### 4. Ask the user about goals — briefly

Before forming an opinion, confirm what the area is *for*. One short message, ideally 1–3 questions max:
- What is this area supposed to do well?
- What does it not need to do?
- Any constraints you haven't told me (perf, deploy target, who else touches it)?

If the goals are obvious from the code and recent conversation, skip this step and state your read of the goals up front in step 5 so the user can correct it.

### 5. Present the step-back

Output a single response with these sections, in this order. Keep it skimmable — bullets over prose, bold the load-bearing words.

**Goals (as I understand them)** — 2–4 bullets. The user will correct you if wrong.

**What the area looks like today** — a short, honest description of the current shape. Not a file tree; the *concept* shape.

**Pain points & smells** — bullets. Each one cites evidence (a commit, a file, a coupling). Distinguish:
- *Friction you observed* (hard to navigate, shallow modules, leaky seams)
- *Friction the git history admits* (the revert, the duplicate-after-refactor, the split that didn't stick)
- *Friction the user has mentioned* in this or recent conversations

**What the ideal shape might look like** — 1–3 sketches at the architecture level. Not code. Module boundaries, ownership, data flow. Be opinionated; name a favorite and say why. If you genuinely don't know enough yet, say so and name what you'd need to learn.

**Trade-offs and open questions** — what each direction costs, what you're unsure about, what depends on the user's answer.

**Recommended next step** — default to *"write this up as a PRD"* via `/mp-write-a-prd` or `/auto-prd`. A PRD that names the pain points explicitly is how a step-back actually closes the loop — it forces the ideal shape into a durable artifact instead of evaporating after the conversation. Other valid recommendations:
- A small spike to de-risk an unknown before committing to a direction
- *"Keep going as-is"* — if the friction isn't worth a reshape yet. Always on the table; don't manufacture a refactor.
- Stress-test first via `/mp-grill-me` or `/two-claudes` if the ideal shape is still uncertain

### 6. Stop

Do not jump into implementation, even if the path now seems obvious. Wait for the user to choose a direction.
