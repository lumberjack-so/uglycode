#!/bin/bash
# PostToolUse hook — runs the matching test file after a code edit
# Enhanced: uses jq for JSON parsing, skips non-code files

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Skip non-code files
case "$FILE_PATH" in
    *.md|*.json|*.css|*.yml|*.yaml|*.toml|*.cfg|*.ini|*.txt)
        exit 0
        ;;
esac

# Skip if the edited file is itself a test
if echo "$FILE_PATH" | grep -qE '(test_|_test\.|\.test\.|\.spec\.|__tests__)'; then
    exit 0
fi

# Python: look for matching test file
if echo "$FILE_PATH" | grep -qE '\.py$'; then
    BASENAME=$(basename "$FILE_PATH" .py)
    TEST_FILE=$(find . -name "test_${BASENAME}.py" -o -name "${BASENAME}_test.py" 2>/dev/null | head -1)
    if [ -n "$TEST_FILE" ]; then
        python -m pytest "$TEST_FILE" -x -q 2>/dev/null || true
    fi
fi

# TypeScript/JavaScript: look for matching test file
if echo "$FILE_PATH" | grep -qE '\.(ts|tsx|js|jsx)$'; then
    BASENAME=$(basename "$FILE_PATH" | sed 's/\.\(ts\|tsx\|js\|jsx\)$//')
    TEST_FILE=$(find . -name "${BASENAME}.test.*" -o -name "${BASENAME}.spec.*" 2>/dev/null | head -1)
    if [ -n "$TEST_FILE" ]; then
        npm test -- --run "$TEST_FILE" 2>/dev/null || npx jest "$TEST_FILE" --no-coverage 2>/dev/null || true
    fi
fi
