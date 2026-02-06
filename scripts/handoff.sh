#!/usr/bin/env bash
# handoff.sh - Capture execution results for review agent
# Usage: handoff.sh <task-file> <base-branch> [working-branch]
# Note: run this from a project repository so TASK.md/REVIEW.md stay project-local.

set -euo pipefail

TASK_FILE="${1:?Usage: handoff.sh <task-file> <base-branch> [working-branch]}"
BASE_BRANCH="${2:?Usage: handoff.sh <task-file> <base-branch> [working-branch]}"
WORKING_BRANCH="${3:-HEAD}"

if [ ! -f "$TASK_FILE" ]; then
    echo "Error: Task file '$TASK_FILE' not found." >&2
    exit 1
fi

DIFF=$(git diff "$BASE_BRANCH".."$WORKING_BRANCH")
STAT=$(git diff --stat "$BASE_BRANCH".."$WORKING_BRANCH")
LOG=$(git log --oneline "$BASE_BRANCH".."$WORKING_BRANCH")

cat <<EOF2
# Handoff: Review Request

## Original Task
$(cat "$TASK_FILE")

## Commits
\`\`\`
${LOG}
\`\`\`

## Diff Summary
\`\`\`
${STAT}
\`\`\`

## Full Diff
\`\`\`diff
${DIFF}
\`\`\`
EOF2
