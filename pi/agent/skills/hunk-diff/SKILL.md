---
name: hunk-diff
description: Mandatory final step for code/file changes. If you edited, created, or deleted any project file, invoke this skill after validation and immediately before your final response. It opens a tmux hunk diff review window for the user. Skip only for read-only tasks or when no files changed.
---

# Hunk Diff Review

Use this skill only at the end of an implementation task, after all intended code edits, tests, and validation steps are complete, and immediately before the final response to the user.

## When to run

Run this skill when all of the following are true:

- You made code changes for the user's request.
- You believe the implementation task is complete.
- You are ready to give the final response to the user.
- The user should review the complete diff, not an intermediate edit.

Do **not** run this skill:

- After every single file edit or small code change.
- While you are still iterating, debugging, or testing.
- For read-only tasks where no code changes were made.
- More than once for the same completed task unless the user asks.

## Action

Call the bundled script from the current working directory:

```bash
/Users/zachary.saylor/.config/pi/agent/skills/hunk-diff/tmux-hunk-session.sh
```

The script opens a new tmux window named `hunk-diff` and runs:

```bash
hunk diff
```

If the script fails, report the error briefly in the final response and do not retry repeatedly.

## Final response

After running the script, send a concise final response summarizing what changed and mention that the hunk diff review window was opened for the user.
