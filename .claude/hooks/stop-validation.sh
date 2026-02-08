#!/bin/bash
INPUT=$(cat)

# Check if we're in a ralph loop — if so, let the plugin handle stopping
RALPH_STATE="$CLAUDE_PROJECT_DIR/.claude/ralph-loop.local.md"
if [[ -f "$RALPH_STATE" ]]; then
  exit 0
fi

# Run the test suite before allowing stop
TS_RESULT=0
PY_RESULT=0

if [[ -f "package.json" ]]; then
  npm test -- --run --silent 2>&1
  TS_RESULT=$?
fi

if [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]] || [[ -d "tests" ]]; then
  if command -v pytest &>/dev/null; then
    pytest -x -q 2>&1
    PY_RESULT=$?
  fi
fi

if [[ $TS_RESULT -ne 0 ]] || [[ $PY_RESULT -ne 0 ]]; then
  echo '{"decision":"block","reason":"Tests are failing. Fix all failing tests before completing this task. Run the full test suite and address each failure."}'
  exit 0
fi

exit 0
