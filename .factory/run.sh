#!/bin/bash
# Software Factory — PRD In, Software Out
# Usage: .factory/run.sh <prd-file> [start-sprint] [--manual]
#
# This is the only command you run. Everything else is automated:
# 1. PRD → Sprint breakdown (todo.md files for each sprint)
# 2. PRD → Scenario holdout sets per sprint
# 3. CLAUDE.md updated with sprint-specific context
# 4. Factory loop: code → validate → score → continue/stop
# 5. Sprint transition: PR, summary, reset, next sprint
#
# Pass --manual to use interactive mode (paste commands, enter scores manually).
# Default is auto mode: coding agent and judge run via claude CLI.

set -e

PRD_FILE=${1:?"Usage: .factory/run.sh <prd-file> [start-sprint] [--manual]"}
START_SPRINT=${2:-0}

MANUAL_FLAG=""
for arg in "$@"; do
    if [ "$arg" = "--manual" ]; then MANUAL_FLAG="--manual"; fi
done

if [ ! -f "$PRD_FILE" ]; then
    echo "Error: PRD file not found: ${PRD_FILE}"
    exit 1
fi

echo "========================================================"
echo "  SOFTWARE FACTORY"
echo "  Input: ${PRD_FILE}"
if [ -n "$MANUAL_FLAG" ]; then
    echo "  Mode: MANUAL (interactive)"
else
    echo "  Mode: AUTO (claude CLI)"
fi
echo "========================================================"
echo ""

# Step 1: Generate sprint breakdown from PRD
SPRINTS_DIR=".factory/sprints"
if [ ! -d "$SPRINTS_DIR" ] || [ "$START_SPRINT" -eq 0 ]; then
    echo "Step 1: Breaking PRD into sprints..."
    bash .factory/generate-sprints.sh "$PRD_FILE"
    echo ""
fi

# Count total sprints
TOTAL_SPRINTS=$(ls -1 ${SPRINTS_DIR}/sprint-*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$TOTAL_SPRINTS" -eq 0 ]; then
    echo "Error: No sprint files generated. Check .factory/generate-sprints.sh output."
    exit 1
fi
echo "Total sprints: ${TOTAL_SPRINTS} (starting from sprint ${START_SPRINT})"
echo ""

# Step 2: Run each sprint
CURRENT_SPRINT=$START_SPRINT
while [ $CURRENT_SPRINT -lt $TOTAL_SPRINTS ]; do
    SPRINT_FILE="${SPRINTS_DIR}/sprint-${CURRENT_SPRINT}.md"

    if [ ! -f "$SPRINT_FILE" ]; then
        echo "Warning: Sprint file not found: ${SPRINT_FILE} — skipping"
        CURRENT_SPRINT=$((CURRENT_SPRINT + 1))
        continue
    fi

    echo "========================================================"
    echo "  Sprint ${CURRENT_SPRINT} / $((TOTAL_SPRINTS - 1))"
    echo "========================================================"
    echo ""

    # 2a. Load sprint tasks
    cp "$SPRINT_FILE" .llm/todo.md
    echo "Loaded: ${SPRINT_FILE} -> .llm/todo.md"

    # 2b. Update CLAUDE.md with sprint context
    CLAUDE_ADDITIONS="${SPRINTS_DIR}/claude-sprint-${CURRENT_SPRINT}.md"
    if [ -f "$CLAUDE_ADDITIONS" ]; then
        # Remove previous sprint additions, append new ones
        sed -i '' '/^## Sprint-Specific Context$/,$d' CLAUDE.md 2>/dev/null || sed -i '/^## Sprint-Specific Context$/,$d' CLAUDE.md 2>/dev/null || true
        echo "" >> CLAUDE.md
        cat "$CLAUDE_ADDITIONS" >> CLAUDE.md
        echo "Updated CLAUDE.md with Sprint ${CURRENT_SPRINT} context"
    fi

    # 2c. Generate scenarios
    echo "Generating scenarios for Sprint ${CURRENT_SPRINT}..."
    bash .factory/generate-scenarios.sh "$PRD_FILE" "$CURRENT_SPRINT"
    echo ""

    # 2d. Run the factory orchestrator
    echo "Launching factory for Sprint ${CURRENT_SPRINT}..."
    echo ""
    bash .factory/orchestrate.sh "$CURRENT_SPRINT" 3 $MANUAL_FLAG
    RESULT=$?

    if [ $RESULT -ne 0 ]; then
        echo ""
        echo "Sprint ${CURRENT_SPRINT} stopped. Fix issues then resume:"
        echo "   .factory/run.sh ${PRD_FILE} ${CURRENT_SPRINT} ${MANUAL_FLAG}"
        exit 1
    fi

    # 2e. Sprint transition
    NEXT_SPRINT=$((CURRENT_SPRINT + 1))
    if [ $NEXT_SPRINT -lt $TOTAL_SPRINTS ]; then
        echo ""
        echo "Transitioning to Sprint ${NEXT_SPRINT}..."
        bash .factory/next-sprint.sh "$CURRENT_SPRINT" "$NEXT_SPRINT"
    fi

    CURRENT_SPRINT=$NEXT_SPRINT
done

echo ""
echo "========================================================"
echo "  FACTORY COMPLETE"
echo "  All ${TOTAL_SPRINTS} sprints finished"
echo "========================================================"
echo ""
echo "Satisfaction history:"
cat .validation/satisfaction-log.jsonl 2>/dev/null || echo "No scores logged"
echo ""
echo "Final sprint transition:"
echo "  .factory/next-sprint.sh $((TOTAL_SPRINTS - 1)) final"
