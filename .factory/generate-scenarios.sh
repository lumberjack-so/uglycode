#!/bin/bash
# Generate Scenario Files from a PRD
# Usage: .factory/generate-scenarios.sh <prd-file> <sprint-number>
#
# Reads your PRD + sprint todo.md, generates:
#   .scenarios/sprint-NN-scenarios.md
#   Appends new regression checks to .scenarios/regression.md
#
# Requires: claude CLI available in PATH

set -e

PRD_FILE=${1:?"Usage: .factory/generate-scenarios.sh <prd-file> <sprint-number>"}
SPRINT=${2:?"Usage: .factory/generate-scenarios.sh <prd-file> <sprint-number>"}

if [ ! -f "$PRD_FILE" ]; then
    echo "Error: PRD file not found: ${PRD_FILE}"
    exit 1
fi

SCENARIO_FILE=".scenarios/sprint-${SPRINT}-scenarios.md"
TODO_FILE=".llm/todo.md"
EXISTING_REGRESSION=".scenarios/regression.md"
EXISTING_SCENARIOS_DIR=".scenarios"

echo "========================================================"
echo "  Generating scenarios for Sprint ${SPRINT}"
echo "========================================================"
echo ""
echo "PRD: ${PRD_FILE}"
echo "Tasks: ${TODO_FILE}"
echo ""

# Collect context
PRD_CONTENT=$(cat "${PRD_FILE}")
TODO_CONTENT=$(cat "${TODO_FILE}" 2>/dev/null || echo "No todo.md found — generate scenarios from PRD only")
REGRESSION_CONTENT=$(cat "${EXISTING_REGRESSION}" 2>/dev/null || echo "No existing regression scenarios")

# Check for previous sprint summaries for context
PREV_SUMMARIES=""
for f in .llm/sprint-*-summary.md; do
    if [ -f "$f" ]; then
        # Use 8-word summary only (pyramid summary layer 2)
        EIGHT_WORD=$(grep "## 8-word" -A 1 "$f" 2>/dev/null | tail -1)
        SPRINT_NUM=$(echo "$f" | grep -oE '[0-9]+')
        PREV_SUMMARIES="${PREV_SUMMARIES}\n- Sprint ${SPRINT_NUM}: ${EIGHT_WORD}"
    fi
done

# Build the prompt
PROMPT="You are a QA scenario writer for an autonomous software factory.

Your job: write end-to-end user scenarios that a SEPARATE validation agent (not the coding agent) will use to judge whether the coding agent built the right thing.

The coding agent CANNOT see these scenarios. They are a holdout set — like validation data in ML training.

## PRD
${PRD_CONTENT}

## Sprint ${SPRINT} Task List
${TODO_CONTENT}

## Previous Sprint Context
${PREV_SUMMARIES:-No previous sprints}

## Existing Regression Scenarios (do NOT duplicate these)
${REGRESSION_CONTENT}

## Instructions

Generate TWO sections separated by the exact marker: ---REGRESSION---

### Section 1: Sprint ${SPRINT} Scenarios

Write 5-10 scenarios. Each MUST:
- Have a unique ID: S${SPRINT}-NN (e.g., S${SPRINT}-01, S${SPRINT}-02)
- Describe ONE observable behavior from the user/API perspective
- Include exact verification steps (curl commands, expected HTTP codes, expected response fields)
- Specify concrete expected values where possible
- Be evaluatable by an LLM judge looking at: test output, API responses, directory structure, git log
- NOT require visual inspection or subjective judgment

Format each scenario exactly like this:
## S${SPRINT}-NN: [Title]
- [Step 1 — what to do]
- [Step 2 — what to do]
- Expected: [concrete expected outcome]
- Fail if: [what indicates failure]

### Section 2: New Regression Scenarios (after ---REGRESSION--- marker)

Write 1-3 NEW regression scenarios for features Sprint ${SPRINT} adds that should be verified in ALL future sprints. Do NOT repeat anything already in the existing regression file. If nothing warrants regression testing, output only: NONE

Use format:
## R-NNN: [Title]
- [Verification steps]
- Expected: [behavior that must persist]"

# Try claude CLI first
echo "Generating scenarios via Claude CLI..."
RESULT=$(echo "${PROMPT}" | claude --print 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$RESULT" ]; then
    echo ""
    echo "Warning: Claude CLI not available or failed."
    echo ""
    echo "Option 1: Install claude CLI and retry"
    echo "Option 2: Copy the prompt and paste into claude.ai manually:"
    echo ""
    echo "The prompt has been saved to: .factory/last-scenario-prompt.md"
    echo "${PROMPT}" > .factory/last-scenario-prompt.md
    echo ""
    echo "After getting the output, save it to: ${SCENARIO_FILE}"
    echo "And append any regression scenarios to: ${EXISTING_REGRESSION}"
    exit 1
fi

# Split at the regression marker
SPRINT_SCENARIOS=$(echo "${RESULT}" | sed '/---REGRESSION---/,$d')
REGRESSION_ADDITIONS=$(echo "${RESULT}" | sed -n '/---REGRESSION---/,$p' | tail -n +2)

# Write sprint scenarios
echo "# Sprint ${SPRINT} Scenarios" > "${SCENARIO_FILE}"
echo "" >> "${SCENARIO_FILE}"
echo "Generated from: ${PRD_FILE}" >> "${SCENARIO_FILE}"
echo "Generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "${SCENARIO_FILE}"
echo "" >> "${SCENARIO_FILE}"
echo "${SPRINT_SCENARIOS}" >> "${SCENARIO_FILE}"
echo "Written: ${SCENARIO_FILE}"

# Append regression scenarios
if [ -n "${REGRESSION_ADDITIONS}" ] && ! echo "${REGRESSION_ADDITIONS}" | grep -qi "^NONE$"; then
    echo "" >> "${EXISTING_REGRESSION}"
    echo "# Added after Sprint ${SPRINT} ($(date +%Y-%m-%d))" >> "${EXISTING_REGRESSION}"
    echo "${REGRESSION_ADDITIONS}" >> "${EXISTING_REGRESSION}"
    echo "Appended to: ${EXISTING_REGRESSION}"
else
    echo "No new regression scenarios needed"
fi

echo ""
echo "Review the generated scenarios:"
echo "   cat ${SCENARIO_FILE}"
echo ""
echo "Then launch the factory:"
echo "   .factory/orchestrate.sh ${SPRINT}"
