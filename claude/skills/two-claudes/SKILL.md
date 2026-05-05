---
name: two-claudes
description: Flesh out a plan or design by grilling it yourself (with codebase access) and sending each question to an independent expert agent for fresh perspective. Catches blind spots by combining codebase-grounded questioning with first-principles reasoning. Use when user wants to stress-test a design, get a second opinion, explore decisions, or mentions "two claudes".
---

# Two Claudes

There are two agents in this skill:

- **Interviewer** (the agent reading this — the main Claude Code session). Has full codebase access. Drives the session by probing the plan, finding gaps, and asking hard questions. Also synthesizes the expert's responses against codebase reality.
- **Expert** (a spawned CLI agent with no codebase access). Answers each question with opinions and recommendations from first principles. Its independence from the codebase is what makes it catch blind spots.

## Setup

1. If the plan or feature isn't already clear from context, ask the user what they want to flesh out.
2. Summarize the plan into a self-contained PLAN_SUMMARY (3-8 sentences covering what it is, why it matters, and any known constraints). Show it to the user: "**Fleshing out:** [summary]" — then immediately start the loop. Do not wait for confirmation unless the user interrupts.
3. Do all codebase exploration silently. The user should only see the question/expert/synthesis blocks, not the exploration steps.

## Loop

Run continuously without pausing for user input. The user can interrupt at any time to steer, override, or ask to dig deeper — but do not prompt them to.

### Step 1: Formulate the question

Silently explore the codebase to ground the interviewer's thinking — read files, grep for patterns, check existing implementations. Then identify the most critical unresolved question or gap in the plan. Write a focused question (1-3 sentences).

### Step 2: Send it to the expert

**First round:**

```bash
SESSION_ID=$(uuidgen)

EXPERT_SYSTEM_PROMPT='You are an independent technical expert. You will receive a plan summary followed by questions about it. For each question, give your honest expert opinion — recommend a concrete approach, flag risks the questioner might not be considering, and name alternatives worth evaluating. Be opinionated and direct.

Rules for this automated format:
- Give ONE clear recommendation, then briefly note alternatives or risks.
- Keep responses to 3-8 sentences.
- Do NOT use markdown formatting, bullet points, or headers. Write in plain conversational prose.
- Do NOT repeat or summarize prior conversation. Just answer the current question.
- When you believe all major decisions are resolved, start your message with ALL_DECIDED and give a brief confirmation.'

claude -p --output-format text --model opus --session-id "$SESSION_ID" \
  --system-prompt "$EXPERT_SYSTEM_PROMPT" --allowedTools "" <<'PROMPT'
Plan summary:

PLAN_SUMMARY_HERE

Question: QUESTION_HERE
PROMPT
```

Save `SESSION_ID` for subsequent rounds.

**Subsequent rounds:**

```bash
claude -p --output-format text --resume "$SESSION_ID" --allowedTools "" <<'PROMPT'
QUESTION_HERE
PROMPT
```

### Step 3: Synthesize and present

After reading the expert's response:

1. **Look for surprises** — what did the expert raise that the interviewer hadn't considered? This is where the value is.
2. **Check against codebase reality** — does the expert's suggestion conflict with existing patterns, constraints, or code? Quickly verify if needed.
3. **Present to the user** — this is the only output per round:

> **Q:** [the interviewer's question]
>
> **Expert:** [brief paraphrase of expert's response]
>
> **Synthesis:** [the interviewer's take — agree, adjust, or flag conflict with codebase reality. 2-4 sentences.]

Then immediately continue to the next round.

## Ending the session

Stop when:
- The expert responds with ALL_DECIDED
- The user says to stop
- All major branches of the design tree have been covered

Produce a final **Decision Log** — a numbered list of each question and the resolution reached. Offer to save it to a file if the user wants.

## Rules

- **Run autonomously.** Do not ask permission between rounds. The user will interrupt if they want to steer.
- **Keep exploration silent.** The user sees only the Q/Expert/Synthesis blocks, not file reads or grep output.
- The interviewer is the questioner, not the answerer. Its job is to find the hard questions, not to have all the answers.
- When the expert catches something the interviewer missed, say so openly. Don't minimize it.
- Keep per-round output short. The user should be able to skim each round in 10 seconds.
- Between rounds, explore the codebase if it would sharpen the next question. Don't speculate about code that can be read.
- The expert has no codebase access by design. That independence is what makes it catch blind spots.
