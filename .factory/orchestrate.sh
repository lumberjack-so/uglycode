#!/bin/bash
# Factory Orchestrator
# Usage: .factory/orchestrate.sh <sprint-number> [max-stages] [--manual]
#
# Runs the full factory cycle:
# 1. Prepare context handoff
# 2. Launch coding agent (auto) or print command to paste (manual)
# 3. Wait for stage completion
# 4. Run validation
# 5. Score and decide: continue, retry, or stop
#
# Pass --manual to use the interactive mode (print command, wait for input).
# Default is auto mode: invoke claude CLI directly.

set -e

SPRINT=${1:?"Usage: .factory/orchestrate.sh <sprint-number> [max-stages] [--manual]"}
MAX_STAGES=${2:-3}
STAGE=1
LOG_FILE=".validation/satisfaction-log.jsonl"

MANUAL=false
for arg in "$@"; do
    if [ "$arg" = "--manual" ]; then MANUAL=true; fi
done

echo "========================================================"
echo "  FACTORY: Sprint ${SPRINT}, Max Stages: ${MAX_STAGES}"
if [ "$MANUAL" = "true" ]; then
    echo "  Mode: MANUAL (interactive)"
else
    echo "  Mode: AUTO (claude CLI)"
fi
echo "========================================================"
echo ""

# Pre-flight: check required files exist
if [ ! -f ".llm/todo.md" ]; then
    echo "Error: .llm/todo.md not found. Load sprint tasks first."
    exit 1
fi

if [ ! -f "CLAUDE.md" ]; then
    echo "Error: CLAUDE.md not found. Are you in the project root?"
    exit 1
fi

# In auto mode, verify claude CLI is available
if [ "$MANUAL" = "false" ]; then
    if ! command -v claude &>/dev/null; then
        echo "Error: claude CLI not found. Install it or use --manual mode."
        exit 1
    fi
fi

REMAINING=$(grep -c "^\- \[ \]" .llm/todo.md 2>/dev/null || echo "0")
echo "Tasks remaining: ${REMAINING}"
echo ""

TASK_PROMPT='Read .llm/stage-context.md first, then .llm/todo.md. Work through each unchecked task top to bottom. For each task: read existing code and tests first, check .llm/exemplars/ for patterns, write failing test, implement minimally to pass, run full test suite, commit with conventional message, mark task complete in todo.md, update .llm/state.md. At HARD STOP tasks, stop and report. Do not skip tasks. Do not refactor beyond what the task requires. Output <promise>DONE</promise> when all tasks are complete.'

while [ $STAGE -le $MAX_STAGES ]; do
    echo "-----------------------------------"
    echo "  Stage ${STAGE}/${MAX_STAGES}"
    echo "-----------------------------------"
    echo ""

    # 1. Write context handoff
    cat > .llm/stage-context.md << EOF
# Stage ${STAGE} of Sprint ${SPRINT}

## Previous State
$(cat .llm/state.md 2>/dev/null || echo "No previous state")

## Known Blockers
$(cat .llm/blockers.md 2>/dev/null || echo "No blockers")

## Decisions So Far
$(tail -20 .llm/decisions.md 2>/dev/null || echo "No decisions yet")

## Instructions
Continue from where the last stage left off.
Read .llm/todo.md for remaining unchecked tasks.
Update .llm/state.md after each completed task.
Log architectural decisions in .llm/decisions.md.
Log blockers in .llm/blockers.md.
EOF

    echo "Context handoff written to .llm/stage-context.md"
    echo ""

    # 2. Launch coding agent
    if [ "$MANUAL" = "true" ]; then
        echo "Paste one of these into Claude Code (depending on which plugin you installed):"
        echo ""
        echo "  OFFICIAL PLUGIN:"
        echo "  /ralph-wiggum:ralph-loop --max-iterations 15 --completion-promise \"DONE\" \"${TASK_PROMPT}\""
        echo ""
        echo "  DIAL481/RALPH FORK:"
        echo "  /ralph:ralph-loop \"${TASK_PROMPT}\" --max-iterations 15 --completion-promise \"DONE\""
        echo ""
        echo "Press ENTER when this stage is complete (or 'q' to quit)..."
        read -r INPUT

        if [ "$INPUT" = "q" ]; then
            echo "Factory stopped by user."
            exit 0
        fi
    else
        STAGE_LOG=".validation/stage-${SPRINT}-${STAGE}.log"
        echo "Launching coding agent via ralph-loop (auto mode)..."
        echo "Log: ${STAGE_LOG}"
        echo ""
        claude -p --dangerously-skip-permissions \
            "/ralph-wiggum:ralph-loop --max-iterations 15 --completion-promise \"DONE\" \"${TASK_PROMPT}\"" \
            2>&1 | tee "${STAGE_LOG}"
        echo ""
        echo "Coding agent finished."
    fi

    # 3. Check remaining tasks
    REMAINING=$(grep -c "^\- \[ \]" .llm/todo.md 2>/dev/null || echo "0")
    COMPLETED=$(grep -c "^\- \[x\]" .llm/todo.md 2>/dev/null || echo "0")
    echo "Tasks: ${COMPLETED} complete, ${REMAINING} remaining"
    echo ""

    # 4. Run validation
    echo "Running validation..."
    bash .validation/validate.sh "${SPRINT}" 2>/dev/null || echo "Validation script had warnings (continuing)"
    echo ""

    # 5. Judge scoring
    if [ "$MANUAL" = "true" ]; then
        echo "Judge prompt ready at: .validation/current-judge-prompt.md"
        echo "   Run: cat .validation/current-judge-prompt.md | claude --print"
        echo ""
        echo "What was the satisfaction score? (0-10, 'skip' to continue, 'q' to quit)"
        read -r SCORE

        if [ "$SCORE" = "q" ]; then
            echo "Factory stopped by user."
            exit 0
        fi
    else
        JUDGE_LOG=".validation/judge-${SPRINT}-${STAGE}.json"
        echo "Running auto-judge..."
        JUDGE_RESULT=$(cat .validation/current-judge-prompt.md | claude -p 2>/dev/null) || true
        echo "$JUDGE_RESULT" > "${JUDGE_LOG}"
        SCORE=$(echo "$JUDGE_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['satisfaction'])" 2>/dev/null) || true
        if [ -z "$SCORE" ]; then
            echo "Warning: Could not parse judge score from ${JUDGE_LOG}. Defaulting to skip."
            SCORE="skip"
        fi
        echo "Auto-judge score: ${SCORE}/10"
        echo "Judge output: ${JUDGE_LOG}"
    fi

    if [ "$SCORE" != "skip" ]; then
        # 6. Log result
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "{\"timestamp\":\"${TIMESTAMP}\",\"sprint\":${SPRINT},\"stage\":${STAGE},\"satisfaction\":${SCORE},\"tasks_remaining\":${REMAINING}}" >> "${LOG_FILE}"

        # 7. Decide
        if [ "$SCORE" -ge 8 ]; then
            echo ""
            echo "Satisfaction ${SCORE}/10 — Stage ${STAGE} PASSED"
        elif [ "$SCORE" -ge 5 ]; then
            echo ""
            echo "Satisfaction ${SCORE}/10 — Continuing with caution"
        else
            echo ""
            echo "Satisfaction ${SCORE}/10 — STOPPING for review"
            echo ""
            echo "Review the judge output, then either:"
            echo "  - Fix CLAUDE.md or .llm/todo.md and rerun this stage"
            echo "  - Run: .factory/orchestrate.sh ${SPRINT} $((MAX_STAGES - STAGE + 1))"
            exit 1
        fi
    fi

    # If no tasks remaining, we're done
    if [ "$REMAINING" -eq 0 ]; then
        echo ""
        echo "All tasks complete!"
        break
    fi

    STAGE=$((STAGE + 1))
done

echo ""
echo "========================================================"
echo "  Sprint ${SPRINT} Factory Run Complete"
echo "========================================================"
echo ""
echo "Next steps:"
echo "  .factory/next-sprint.sh ${SPRINT} $((SPRINT + 1))"
