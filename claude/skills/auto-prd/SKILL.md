---
name: auto-prd
description: Agent autonomously drafts a complete PRD from a short feature description by exploring the codebase, then presents it for review. Use when user wants to quickly create a PRD, add a feature, describe new work, or mentions "auto-prd".
---

# Auto PRD

The user provides a short description of what they want. You do the heavy lifting — explore the codebase, make informed decisions, and draft a complete PRD. The user reviews and refines rather than answering a long interview.

## Process

### 1. Receive the feature description

The user has already provided a description (could be one sentence or a paragraph). Do NOT ask for more detail upfront. Work with what you have.

### 2. Do your homework

Before writing anything, explore autonomously:

- Read CLAUDE.md and any existing project documentation
- Explore the codebase structure, key modules, patterns, and conventions
- Read existing PRDs (check GitHub issues labeled "prd") for style and scope reference
- Understand the tech stack, testing patterns, and architecture
- Identify which parts of the codebase this feature would touch

This step should be thorough. The better your understanding, the fewer questions you need to ask.

### 3. Draft the complete PRD

Using everything you learned, draft a full PRD. Make your best judgment call on every decision. Use the template below.

For each decision where you are genuinely uncertain (not just being polite — actually uncertain between meaningfully different options), flag it inline with:

> **[DECISION NEEDED]** I assumed X because Y. Alternative would be Z. Which do you prefer?

Limit these to 3-5 at most. If you can make a reasonable call, make it. Do not ask about things you can infer from the codebase or prior PRDs.

### 4. Present the draft

Show the complete PRD to the user. Ask them to:
- Approve it as-is
- Flag sections to change
- Answer any [DECISION NEEDED] items

### 5. Iterate (if needed)

If the user pushes back on specific sections, revise only those sections. Do not re-present the entire PRD unless asked.

### 6. File and generate tasks

Once approved:
- Submit the PRD as a GitHub issue with the "prd" label via `gh issue create`
- Break it into vertical-slice tasks using the same approach as mp-prd-to-issues:
  - Each task is a thin end-to-end slice (schema → API → UI → tests)
  - Classify as HITL (needs human) or AFK (agent can handle)
  - Include acceptance criteria and TDD plan per task
  - Create as GitHub issues with dependency ordering
- Present the task list to the user for approval before creating issues

## PRD Template

```markdown
## Problem Statement

The problem from the user's perspective.

## Solution

The solution from the user's perspective.

## User Stories

A numbered list of user stories:

1. As a <actor>, I want <feature>, so that <benefit>

Be extensive — cover all aspects of the feature.

## Implementation Decisions

- Modules to build/modify (prefer deep modules with simple interfaces)
- Architectural decisions
- Schema changes
- API contracts / route structures
- Key interactions between components

Do NOT include specific file paths or code snippets.

## Testing Decisions

- What makes a good test for this feature
- Which modules to test
- Testing approach (mock boundaries, not internals)
- Prior art in the codebase

## Out of Scope

What this PRD intentionally does NOT cover.

## Further Notes

Any additional context.
```

## Key Principles

- **You propose, they approve.** The user's job is to review your work, not author it.
- **Minimize questions.** Every question you ask is a context switch for the user. Only ask when you genuinely cannot infer the answer.
- **Use the codebase as your source of truth.** Don't ask about architecture, conventions, or patterns you can read from the code.
- **Same quality as write-a-prd.** This is not a lesser PRD — it's a smarter process to produce the same artifact.
- **Flag uncertainty, don't hide it.** When you make a judgment call, say so. The user can override.
