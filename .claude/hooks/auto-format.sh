#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then exit 0; fi

# TypeScript/JavaScript — Prettier
if [[ "$FILE_PATH" =~ \.(ts|tsx|js|jsx|json|css|md)$ ]]; then
  npx prettier --write "$FILE_PATH" 2>/dev/null || true
fi

# Python — Black + isort
if [[ "$FILE_PATH" =~ \.py$ ]]; then
  python -m black "$FILE_PATH" 2>/dev/null || true
  python -m isort "$FILE_PATH" 2>/dev/null || true
fi

exit 0
