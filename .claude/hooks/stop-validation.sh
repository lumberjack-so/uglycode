#!/bin/bash
# Stop hook — blocks Claude from stopping if tests are failing
# Enhanced: checks for ralph loop state file, returns hookSpecificOutput

# If ralph-wiggum is managing the loop, let it handle stopping
if [ -f ".claude/ralph-loop.local.md" ]; then
    exit 0
fi

FAILURES=""

# Check for Python tests
if [ -d "api" ] || [ -d "tests" ]; then
    PYTEST_RESULT=$(python -m pytest -x -q 2>&1)
    if echo "$PYTEST_RESULT" | grep -qE 'failed|error'; then
        FAILURES="${FAILURES}Python tests failing:\n$(echo "$PYTEST_RESULT" | tail -5)\n\n"
    fi
fi

# Check for JS/TS tests
if [ -f "package.json" ]; then
    if grep -q '"test"' package.json 2>/dev/null; then
        NPM_RESULT=$(npm test 2>&1)
        if [ $? -ne 0 ]; then
            FAILURES="${FAILURES}JS/TS tests failing:\n$(echo "$NPM_RESULT" | tail -5)\n\n"
        fi
    fi
fi

if [ -n "$FAILURES" ]; then
    echo "{\"decision\": \"block\", \"reason\": \"Tests are failing. Fix them before stopping.\n${FAILURES}\"}"
    exit 1
fi

exit 0
