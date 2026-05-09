---
name: btca
description: Invoke this skill when the user says "use btca".
---

# BTCA

BTCA, aka "The Better Context App", is a simple app defined as a skill file. The purpose of this app is to search git repos cloned onto this machine.

## The BTCA Search Workflow

### Guidelines

- If the user includes a direct link to a GitHub repo, always load and reference that.
- If the user doesn't include any specific links/repos they want you to use, do your best to guess based on the context provided.
- Always include very clear and complete code snippets. Do not leave out things that are important context, like imports.
- When answering, use lots of bulleted/numbered lists to keep things readable and clear.

### Workflow

1. Use `~/.btca/agent/sandbox` as the destination for cloning and searching repos.
   - If the directory does not exist, first run `mkdir -p ~/.btca/agent/sandbox`
2. If the repo(s) are already in the working directory `~/.btca/agent/sandbox`, update them. Otherwise clone them. Clone the main/master branch by default, unless the user asks for something else.
3. Search the repo for the information you need. Make sure the follow the guidelines.

### End Goal

A clear, concise answer to the user's question with relevant code examples.

## Startup Cases

This skill can be invoked in several different ways, and your behavior should reflect that:

### User invoked without extra context/question

This is the "app startup" state, almost as if a terminal app was booted up.

Your job is to search the working directory `~/.btca/agent/sandbox` at the top level, just to get a list of all repos currently available in the sandbox.

Then you should simply output the following markdown (filling in the existing repos):

```md
---
# BTCA

_use your coding agent to search any git repo locally_

Available sandbox repos:

- repo 1
- ...

Give me a question and the link to a git repo to get started!

_I can also clean up the sandbox or pre-install repos for future reference._

---

```

### You invoked because of the user's prompt

In this case, your job is to answer/execute the user's prompt faithfully, while using the BTCA search workflow when needed to better execute your task.

### User invoked while also giving a prompt/question

This case is simple: answer the user's prompt with the btca search workflow.
