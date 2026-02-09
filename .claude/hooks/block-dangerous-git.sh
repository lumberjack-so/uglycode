#!/bin/bash
# PreToolUse hook — blocks force push, reset --hard, rm -rf, push to main/master
# Enhanced: uses jq for JSON parsing, returns hookSpecificOutput format

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
    exit 0
fi

# Block destructive git operations
if echo "$COMMAND" | grep -qE 'git push.*--force|git push.*-f |git reset --hard|git clean -fd'; then
    echo '{"hookSpecificOutput": {"permissionDecision": "deny", "reason": "Blocked: destructive git operation (force push, reset --hard, clean -fd). Use safe alternatives."}}'
    exit 0
fi

# Block push to main/master
if echo "$COMMAND" | grep -qE 'git push.*(origin|upstream)\s+(main|master)'; then
    echo '{"hookSpecificOutput": {"permissionDecision": "deny", "reason": "Blocked: direct push to main/master. Create a feature branch and PR instead."}}'
    exit 0
fi

# Block rm -rf on critical directories
if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+(/|~|\.|src|app|api|tests|infra|services)'; then
    echo '{"hookSpecificOutput": {"permissionDecision": "deny", "reason": "Blocked: rm -rf on critical directory. Remove specific files instead."}}'
    exit 0
fi

exit 0
