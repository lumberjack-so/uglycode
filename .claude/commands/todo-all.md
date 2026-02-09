# Autonomous Task Loop

1. Read `.llm/stage-context.md` if it exists (context from previous stage)
2. Read `.llm/state.md` for current agent state
3. Read `.llm/todo.md` for the task list

For each unchecked task (top to bottom):
1. Read existing code and tests in affected directories
2. Check `.llm/exemplars/` for reusable patterns
3. Write a failing test for the expected behavior
4. Implement the minimum code to pass the test
5. Run the full test suite
6. If all pass: commit with conventional message, mark task `[x]` in todo.md
7. If failing: debug until passing, then commit
8. Update `.llm/state.md` with what you just did
9. If the task is a **HARD STOP**: stop execution and report status

After all tasks:
1. Update `.llm/state.md` with final status
2. Log any architectural decisions to `.llm/decisions.md`
3. Log any blockers to `.llm/blockers.md`

Rules:
- Do NOT skip tasks. If blocked, log to blockers.md and continue to next.
- Do NOT refactor outside current task scope.
- Do NOT add dependencies not specified in the task.
- Every task gets at least one test.
