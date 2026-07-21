---
name: ticket-puncher
description: Drafts tasks as concise Jira tickets with motivation, acceptance criteria, and developer notes, then saves them as Markdown. Use when the user asks to create, write, refine, or formalize a ticket, issue, task, story, bug, spike, or chore.
---

# Ticket Puncher

Turn any requested task into a clear, implementation-ready Jira ticket and save it as a Markdown file in the current working directory.

## Workflow

1. Extract the task's purpose, desired outcome, constraints, and relevant technical context.
2. Identify missing information that would make the ticket ambiguous or prevent objective acceptance criteria.
3. If essential information is missing, ask focused clarifying questions in one batch. Do not write the file until the user answers.
4. Draft the ticket using exactly the three headings below, in the same order and with no additional headings or preamble.
5. Choose a concise, descriptive kebab-case filename ending in `.md`. If the target already exists, ask before overwriting it.
6. Write the file to the current working directory and report its path.

## Content rules

- **Motivation:** Write 1–3 concise sentences explaining why the task matters and what outcome it should produce. Do not prescribe implementation details.
- **Acceptance Criteria:** Use a short Markdown bullet list of observable, testable facts that must be true when the task is complete. Cover the requested behavior, important constraints, and relevant failure or edge cases without inventing requirements.
- **Dev Notes:** Use a Markdown bullet list containing only useful implementation context, constraints, dependencies, affected areas, or known decisions. Do not repeat the acceptance criteria. If no notes are needed, write `- None.`
- Preserve facts supplied by the user. Do not silently fill important gaps with assumptions.
- Keep the ticket scoped to the task given, regardless of whether it is a feature, bug, story, spike, chore, or other task type.

## Required output structure

```md
## Motivation

[1–3 sentences]

## Acceptance Criteria

- [Observable, testable outcome]

## Dev Notes

- [Implementation context or `None.`]
```
