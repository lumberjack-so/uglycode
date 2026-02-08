#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then exit 0; fi

# Skip test runs for non-code files
if [[ "$FILE_PATH" =~ \.(md|json|css|yml|yaml)$ ]]; then exit 0; fi

# TypeScript — run matching test file
if [[ "$FILE_PATH" =~ \.(ts|tsx)$ ]]; then
  TEST_FILE="${FILE_PATH%.ts}.test.ts"
  TEST_FILE2="${FILE_PATH%.tsx}.test.tsx"
  if [[ -f "$TEST_FILE" ]]; then
    npm test -- --run "$TEST_FILE" 2>&1 | tail -20
  elif [[ -f "$TEST_FILE2" ]]; then
    npm test -- --run "$TEST_FILE2" 2>&1 | tail -20
  fi
fi

# Python — run matching test file
if [[ "$FILE_PATH" =~ \.py$ ]]; then
  TEST_FILE="tests/test_$(basename "$FILE_PATH")"
  if [[ -f "$TEST_FILE" ]]; then
    pytest "$TEST_FILE" -x -q 2>&1 | tail -20
  fi
fi

exit 0
