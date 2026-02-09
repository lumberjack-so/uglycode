#!/bin/bash
# PreToolUse hook — guards .env, lockfiles, migrations, production configs, factory dirs
# Enhanced: uses jq for JSON parsing, returns hookSpecificOutput format

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

PROTECTED_PATTERNS=(
    "\.env"
    "package-lock\.json"
    "yarn\.lock"
    "pnpm-lock\.yaml"
    "poetry\.lock"
    "migrations/"
    "docker-compose\.prod"
    "\.scenarios/"
    "\.validation/"
    "\.factory/"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if echo "$FILE_PATH" | grep -qE "$pattern"; then
        echo "{\"hookSpecificOutput\": {\"permissionDecision\": \"deny\", \"reason\": \"Blocked: ${FILE_PATH} is a protected file. Do not modify directly.\"}}"
        exit 0
    fi
done

exit 0
