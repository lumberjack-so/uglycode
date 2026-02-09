#!/bin/bash
# Split raw sprint output into individual files
# Usage: .factory/split-sprints.sh <raw-output-file>
#
# Use this if claude CLI isn't available:
# 1. Paste the prompt from .factory/last-sprint-prompt.md into claude.ai
# 2. Save Claude's response to a file
# 3. Run this script on that file

set -e

INPUT_FILE=${1:?"Usage: .factory/split-sprints.sh <raw-output-file>"}
SPRINTS_DIR=".factory/sprints"
mkdir -p "$SPRINTS_DIR"

echo "Splitting ${INPUT_FILE} into sprint files..."

awk -v dir="$SPRINTS_DIR" '
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
' "$INPUT_FILE"

TOTAL=$(ls -1 ${SPRINTS_DIR}/sprint-*.md 2>/dev/null | wc -l | tr -d ' ')
echo "Generated ${TOTAL} sprint files in ${SPRINTS_DIR}/"

for f in ${SPRINTS_DIR}/sprint-*.md; do
    if [ -f "$f" ]; then
        TASKS=$(grep -c "^\- \[ \]" "$f" 2>/dev/null || echo "0")
        echo "   $(basename $f): ${TASKS} tasks"
    fi
done

echo ""
echo "Run the factory:"
echo "   .factory/run.sh <your-prd-file>"
