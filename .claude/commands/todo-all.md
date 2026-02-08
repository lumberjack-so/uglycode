---
description: "Process all tasks in .llm/todo.md autonomously using subagents"
allowed-tools: ["Bash", "Read", "Write", "Edit", "MultiEdit", "Task", "TodoRead", "TodoWrite"]
---
# Autonomous Task Loop

Read .llm/todo.md and process each incomplete task (marked with `- [ ]`).

For each task:
1. Launch a @do-todo subagent with the task description
2. When the subagent completes, verify the task was done correctly
3. Run the project test suite
4. If tests pass, mark the task as complete in .llm/todo.md
5. Commit changes with a conventional commit message matching the task
6. Move to the next incomplete task

If you encounter a **HARD STOP** task, use AskUserQuestion to get confirmation before proceeding.

Stop when all tasks are checked off and the final test suite passes.
