#!/bin/bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block dangerous git operations
if echo "$CMD" | grep -qE 'git (push.*--force|push.*-f |reset.*--hard|clean.*-fd|push.*origin.*(main|master)$)'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: Dangerous git operation. Use feature branches and regular push."}}'
  exit 0
fi

# Block rm -rf on important directories
if echo "$CMD" | grep -qE 'rm -rf\s+(/|~|\.|src|app|api)'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"BLOCKED: Destructive delete on important directory."}}'
  exit 0
fi

exit 0
