#!/bin/bash
# PostToolUse hook — runs formatters on edited files
# Enhanced: uses jq for JSON parsing

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

case "$FILE_PATH" in
    *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.md)
        npx prettier --write "$FILE_PATH" 2>/dev/null || true
        ;;
    *.py)
        python -m black "$FILE_PATH" 2>/dev/null || true
        python -m isort "$FILE_PATH" 2>/dev/null || true
        ;;
esac
