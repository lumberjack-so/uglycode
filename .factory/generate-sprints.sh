#!/bin/bash
# Generate Sprint Breakdown from PRD
# Usage: .factory/generate-sprints.sh <prd-file>
#
# Takes a PRD and generates:
#   .factory/sprints/sprint-0.md through sprint-N.md (task lists)
#   .factory/sprints/claude-sprint-0.md through claude-sprint-N.md (CLAUDE.md additions)
#
# Requires: claude CLI in PATH

set -e

PRD_FILE=${1:?"Usage: .factory/generate-sprints.sh <prd-file>"}

if [ ! -f "$PRD_FILE" ]; then
    echo "Error: PRD file not found: ${PRD_FILE}"
    exit 1
fi

SPRINTS_DIR=".factory/sprints"
mkdir -p "$SPRINTS_DIR"

echo "========================================================"
echo "  Generating sprint breakdown from PRD"
echo "========================================================"
echo ""

# Read project context
CLAUDE_MD=$(cat CLAUDE.md 2>/dev/null || echo "No CLAUDE.md found")
EXISTING_CODE=$(tree -L 2 -I 'node_modules|__pycache__|.git|.claude|.venv' --charset ascii 2>/dev/null || echo "Empty project")

PROMPT="You are a sprint planner for an autonomous software factory. An AI coding agent (Claude Code) will execute these sprints without human intervention. The agent reads tasks from a todo.md file and works through them top to bottom.

## PRD
$(cat "$PRD_FILE")

## Current Project State
\`\`\`
${EXISTING_CODE}
\`\`\`

## Current CLAUDE.md
${CLAUDE_MD}

## Instructions

Break this PRD into sprints. Output ALL sprints in a single response.

### Sprint Planning Rules

1. **Sprint 0 is always scaffold** — project structure, Docker/infra, stub API, stub frontend, CI pipeline. No business logic.
2. **Each sprint is a vertical slice** — it produces something testable end-to-end. Not \"backend sprint\" then \"frontend sprint.\"
3. **5-15 tasks per sprint.** Each task takes the agent 2-5 minutes.
4. **HARD STOP every 4-6 tasks.** The agent pauses for validation.
5. **Each task has:** a clear artifact (file path), a specific constraint (what NOT to do), and a success check.
6. **Total sprints: 5-12** depending on PRD complexity. Lean toward fewer, larger sprints over many tiny ones.
7. **Dependencies flow forward** — Sprint N never depends on Sprint N+2.
8. **Last sprint is always hardening** — error handling, edge cases, monitoring, production config.

### Task Format (STRICT — the agent parses this)

\`\`\`
- [ ] N. [Description] — Artifact: \`path/to/file\`. Constraint: [what not to do]. Verify: [how to check].
- [ ] N. **HARD STOP** — Run full test suite. Check: [specific thing to verify]. Report status.
\`\`\`

### Output Format

Output each sprint as a separate block, using this EXACT delimiter between sprints:

===SPRINT_BREAK===

Each sprint block must contain TWO sections separated by:

===CLAUDE_ADDITIONS===

Section 1 (before the marker): The todo.md content for that sprint.
Section 2 (after the marker): CLAUDE.md additions specific to that sprint (new commands, constraints, architecture notes the agent needs). Keep under 30 lines. Include a header: \`## Sprint-Specific Context\`

### Example Sprint Block

# Sprint 0: Project Scaffold

## Context
Set up project structure, Docker infrastructure, stub API, and CI pipeline.

## Tasks

- [ ] 1. Create project directory structure — Artifact: \`api/\`, \`src/\`, \`tests/\`, \`infra/\`. Constraint: directories only, no code files yet. Verify: \`tree -L 2\` shows expected structure.
- [ ] 2. Initialize Python backend — Artifact: \`api/pyproject.toml\`, \`api/app/main.py\`. Constraint: FastAPI only, no Django. Verify: \`cd api && uvicorn app.main:app\` starts without errors.
- [ ] 3. Create health endpoint — Artifact: \`api/app/routes/health.py\`. Constraint: return {\"status\": \"ok\"} only. Verify: \`curl localhost:8000/health\` returns 200.
- [ ] 4. **HARD STOP** — Run: \`cd api && pytest -x -q\`. Check: health endpoint test passes. Report number of tests.
- [ ] 5. Initialize Next.js frontend — Artifact: \`src/\`. Constraint: App Router, TypeScript, Tailwind. Verify: \`npm run dev\` starts without errors.
- [ ] 6. Create Docker Compose — Artifact: \`infra/docker-compose.yml\`. Constraint: dev config only, no production. Verify: \`docker compose -f infra/docker-compose.yml up -d\` starts all services.
- [ ] 7. **HARD STOP** — Run: \`docker compose ps\`. Check: all services healthy. Run full test suite. Report status.

## Success Criteria
- [ ] All tests pass
- [ ] docker compose up -d starts all services
- [ ] API health endpoint responds
- [ ] Frontend dev server starts

===CLAUDE_ADDITIONS===

## Sprint-Specific Context

### Sprint 0: Scaffold
- Backend framework: FastAPI with uvicorn
- Frontend framework: Next.js 14 with App Router
- Infrastructure: Docker Compose for local dev
- Do NOT add any business logic in this sprint
- Do NOT install optional dependencies — only what's needed for stubs

NOW GENERATE THE COMPLETE SPRINT BREAKDOWN. Every sprint. Do not stop early or summarize remaining sprints — output the full task list for each one."

echo "Calling Claude to generate sprint breakdown..."
echo "   (This may take 30-60 seconds for complex PRDs)"
echo ""

RESULT=$(echo "${PROMPT}" | claude --print 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$RESULT" ]; then
    echo "Warning: Claude CLI not available or failed."
    echo ""
    echo "The prompt has been saved to: .factory/last-sprint-prompt.md"
    echo "${PROMPT}" > .factory/last-sprint-prompt.md
    echo ""
    echo "Options:"
    echo "  1. Install claude CLI: npm install -g @anthropic-ai/claude-cli"
    echo "  2. Paste the prompt into claude.ai manually"
    echo "  3. Save output to .factory/sprints/raw-output.md and run:"
    echo "     .factory/split-sprints.sh .factory/sprints/raw-output.md"
    exit 1
fi

# Save raw output for debugging
echo "$RESULT" > "${SPRINTS_DIR}/raw-output.md"

# Split into individual sprint files
echo "Splitting into individual sprint files..."

SPRINT_NUM=0
# Use awk to split on the delimiter
echo "$RESULT" | awk -v dir="$SPRINTS_DIR" '
BEGIN { sprint=0; section="todo"; outfile=dir "/sprint-0.md" }
/^===SPRINT_BREAK===/ {
    sprint++
    section="todo"
    outfile=dir "/sprint-" sprint ".md"
    next
}
/^===CLAUDE_ADDITIONS===/ {
    close(outfile)
    section="claude"
    outfile=dir "/claude-sprint-" sprint ".md"
    next
}
{
    print >> outfile
}
END {
    close(outfile)
}
'

# Count what was generated
TOTAL=$(ls -1 ${SPRINTS_DIR}/sprint-*.md 2>/dev/null | wc -l | tr -d ' ')
CLAUDE_FILES=$(ls -1 ${SPRINTS_DIR}/claude-sprint-*.md 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "Generated ${TOTAL} sprint files:"
for f in ${SPRINTS_DIR}/sprint-*.md; do
    if [ -f "$f" ]; then
        TASKS=$(grep -c "^\- \[ \]" "$f" 2>/dev/null || echo "0")
        HARD_STOPS=$(grep -c "HARD STOP" "$f" 2>/dev/null || echo "0")
        echo "   $(basename $f): ${TASKS} tasks, ${HARD_STOPS} checkpoints"
    fi
done

echo ""
echo "Generated ${CLAUDE_FILES} CLAUDE.md addition files"
echo ""
echo "Review the sprint breakdown:"
echo "   ls -la ${SPRINTS_DIR}/"
echo "   cat ${SPRINTS_DIR}/sprint-0.md"
echo ""
echo "To run the full factory:"
echo "   .factory/run.sh ${PRD_FILE}"
