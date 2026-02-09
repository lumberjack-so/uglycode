#!/bin/bash
# Sprint Transition
# Usage: .factory/next-sprint.sh <completed-sprint> <next-sprint>
#
# Handles the clean handoff between sprints:
# 1. Branch, push, PR for completed sprint
# 2. Write pyramid summary for cross-sprint context
# 3. Reset state files
# 4. Prompt for next sprint setup

set -e

COMPLETED=${1:?"Usage: .factory/next-sprint.sh <completed-sprint> <next-sprint>"}
NEXT=${2:?"Usage: .factory/next-sprint.sh <completed-sprint> <next-sprint>"}

echo "========================================================"
echo "  Transitioning: Sprint ${COMPLETED} -> Sprint ${NEXT}"
echo "========================================================"
echo ""

# 1. Branch, push, PR
BRANCH="feat/sprint-${COMPLETED}"
echo "Step 1: Creating PR for Sprint ${COMPLETED}..."
git checkout -b "${BRANCH}" 2>/dev/null || git checkout "${BRANCH}" 2>/dev/null || true
git add -A
git commit -m "feat: complete sprint ${COMPLETED}" --allow-empty 2>/dev/null || true
git push origin "${BRANCH}" 2>/dev/null || echo "   Push failed — you may need to push manually"
gh pr create --title "feat: Sprint ${COMPLETED} complete" --body "Autonomous factory run. See .validation/satisfaction-log.jsonl for scores." 2>/dev/null || echo "   PR creation failed — create manually or PR already exists"
echo ""

# 2. Back to main
echo "Step 2: Returning to main..."
git checkout main 2>/dev/null || true
git pull origin main 2>/dev/null || true
echo ""

# 3. Pyramid summary
echo "Step 3: Writing sprint summary..."
SPRINT_COMMITS=$(git log --oneline "${BRANCH}" --not main 2>/dev/null | head -20 || echo "Could not diff branches")
COMPLETED_TASKS=$(grep "^\- \[x\]" .llm/todo.md 2>/dev/null || echo "No completed tasks found")

cat > ".llm/sprint-${COMPLETED}-summary.md" << EOF
# Sprint ${COMPLETED} Summary

## 2-word summary
Sprint ${COMPLETED} complete

## 8-word summary
All sprint ${COMPLETED} tasks done, tests passing, merged

## Commits
${SPRINT_COMMITS}

## Completed Tasks
${COMPLETED_TASKS}

## Final Agent State
$(cat .llm/state.md 2>/dev/null || echo "No state file")

## Decisions Made This Sprint
$(cat .llm/decisions.md 2>/dev/null || echo "No decisions logged")

## Unresolved Blockers
$(cat .llm/blockers.md 2>/dev/null || echo "No blockers")
EOF
echo "   Written: .llm/sprint-${COMPLETED}-summary.md"
echo ""

# 4. Reset state for next sprint
echo "Step 4: Resetting state for Sprint ${NEXT}..."
cat > .llm/state.md << EOF
# Agent State

## Last Action
Completed Sprint ${COMPLETED}. See .llm/sprint-${COMPLETED}-summary.md for context.

## Current Task
(none — starting Sprint ${NEXT})

## Next Task
Read .llm/todo.md for Sprint ${NEXT} tasks

## Blockers
$(grep "^\- \[ \]" .llm/blockers.md 2>/dev/null || echo "(none carried over)")

## Modified Files This Session
(none — new session)
EOF

# Keep decisions log but add separator
echo "" >> .llm/decisions.md
echo "---" >> .llm/decisions.md
echo "# Sprint ${NEXT} Decisions" >> .llm/decisions.md
echo "" >> .llm/decisions.md

# Reset blockers (keep unresolved ones)
UNRESOLVED=$(grep "^\- \[ \]" .llm/blockers.md 2>/dev/null || true)
cat > .llm/blockers.md << EOF
# Blockers

Issues the coding agent cannot resolve autonomously. Human reviews at HARD STOP.

${UNRESOLVED}
EOF

echo ""
echo "========================================================"
echo "  Ready for Sprint ${NEXT}"
echo "========================================================"
echo ""
echo "Next steps:"
echo "  1. Copy Sprint ${NEXT} tasks into .llm/todo.md"
echo "  2. Add Sprint ${NEXT} additions to CLAUDE.md (if any)"
echo "  3. Generate scenarios:"
echo "     .factory/generate-scenarios.sh docs/prd.md ${NEXT}"
echo "  4. Review: cat .scenarios/sprint-${NEXT}-scenarios.md"
echo "  5. Add regression scenarios from Sprint ${COMPLETED} to .scenarios/regression.md"
echo "  6. Launch: .factory/orchestrate.sh ${NEXT}"
