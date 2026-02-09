#!/bin/bash
# Stop hook — checks if the agent completed its current task or drifted
# Enhanced: reads state.md for context, warns on remaining tasks

if [ ! -f ".llm/state.md" ]; then
    exit 0
fi

CURRENT_TASK=$(grep "## Current Task" -A 2 .llm/state.md 2>/dev/null | tail -1)

if [ -z "$CURRENT_TASK" ] || [ "$CURRENT_TASK" = "(none yet)" ] || [ "$CURRENT_TASK" = "(none — starting next sprint)" ]; then
    exit 0
fi

# Check if todo.md has unchecked tasks
REMAINING=$(grep -c "^\- \[ \]" .llm/todo.md 2>/dev/null || echo "0")

if [ "$REMAINING" -gt 0 ]; then
    # Check if we're at a HARD STOP (non-blocking warning)
    echo "WARNING: ${REMAINING} unchecked tasks remain in .llm/todo.md"
    echo "Current task was: ${CURRENT_TASK}"
    echo "If you are at a HARD STOP, this is expected. Otherwise, continue working."
fi

exit 0
