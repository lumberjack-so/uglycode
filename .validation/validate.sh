#!/bin/bash
# Validation Harness
# Usage: .validation/validate.sh [sprint-number]
#
# Collects codebase state and generates a judge prompt.
# The judge prompt is evaluated by a SEPARATE Claude session (not the coding agent).

set -e

SPRINT=${1:-"smoke"}
SCENARIO_FILE=".scenarios/sprint-${SPRINT}-scenarios.md"
REGRESSION_FILE=".scenarios/regression.md"
SMOKE_FILE=".scenarios/smoke.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "=== Collecting codebase state for Sprint ${SPRINT} validation ==="

# Collect evidence
TREE=$(tree -L 3 -I 'node_modules|__pycache__|.git|.claude|.venv' --charset ascii 2>/dev/null || echo "tree command not available")
GIT_LOG=$(git log --oneline -20 2>/dev/null || echo "no git history")
GIT_DIFF_STAT=$(git diff --stat HEAD~10 2>/dev/null || echo "no diff available")

# Try running tests and capture output
TEST_OUTPUT="No test runner detected"
if [ -f "api/pyproject.toml" ] || [ -d "api/tests" ] || [ -d "tests" ]; then
    TEST_OUTPUT=$(cd api 2>/dev/null && python -m pytest -x -q 2>&1 || python -m pytest -x -q 2>&1 || echo "pytest failed to run")
fi
if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
    JS_TESTS=$(npm test 2>&1 || echo "npm test failed")
    TEST_OUTPUT="${TEST_OUTPUT}\n\n--- JS/TS Tests ---\n${JS_TESTS}"
fi

# Try health check
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "API not running")

# Read agent state
AGENT_STATE=$(cat .llm/state.md 2>/dev/null || echo "No state file")
AGENT_BLOCKERS=$(cat .llm/blockers.md 2>/dev/null || echo "No blockers file")

# Build the judge prompt
cat > .validation/current-judge-prompt.md << JUDGE_EOF
You are a QA judge for an autonomous software factory. Evaluate whether the codebase satisfies the scenarios below based ONLY on the evidence provided. Do not guess — if evidence is insufficient, mark as UNKNOWN.

## Evidence

### Directory Structure
\`\`\`
${TREE}
\`\`\`

### Recent Commits
\`\`\`
${GIT_LOG}
\`\`\`

### Changed Files (last 10 commits)
\`\`\`
${GIT_DIFF_STAT}
\`\`\`

### Test Results
\`\`\`
${TEST_OUTPUT}
\`\`\`

### Health Check Response Code
${HEALTH_CHECK}

### Agent State
${AGENT_STATE}

### Agent Blockers
${AGENT_BLOCKERS}

---

## Scenarios to Evaluate

### Smoke Tests
$(cat ${SMOKE_FILE} 2>/dev/null || echo "No smoke scenarios file")

### Regression Tests
$(cat ${REGRESSION_FILE} 2>/dev/null || echo "No regression scenarios file")

### Sprint ${SPRINT} Scenarios
$(cat ${SCENARIO_FILE} 2>/dev/null || echo "No sprint-specific scenario file for sprint ${SPRINT}")

---

## Output Format

Respond with ONLY valid JSON, no markdown fences, no preamble:

{"scenarios": [{"id": "S-SMOKE-01", "status": "PASS|FAIL|UNKNOWN", "reason": "brief explanation"}], "satisfaction": 7, "total_pass": 5, "total_fail": 1, "total_unknown": 2, "blockers": ["list of blocking issues"], "recommendations": ["list of suggested fixes"]}
JUDGE_EOF

echo ""
echo "Judge prompt written to: .validation/current-judge-prompt.md"
echo ""
echo "Evaluate with a separate Claude session:"
echo "  cat .validation/current-judge-prompt.md | claude --print"
echo ""
echo "Or paste the contents into claude.ai manually."
