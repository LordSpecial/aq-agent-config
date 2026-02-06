#!/usr/bin/env bash
# sync-projects.sh - Verify all aq-* projects have correct agent config
# Usage: sync-projects.sh <projects-root-dir>

set -euo pipefail

PROJECTS_ROOT="${1:?Usage: sync-projects.sh <projects-root-dir>}"
ERRORS=0

for project_dir in "$PROJECTS_ROOT"/aq-*; do
    [ -d "$project_dir/.git" ] || continue
    name=$(basename "$project_dir")

    if [ ! -f "$project_dir/AGENTS.md" ]; then
        echo "MISSING: $name/AGENTS.md"
        ERRORS=$((ERRORS + 1))
    else
        echo "OK:      $name/AGENTS.md"
    fi
done

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "$ERRORS project(s) missing AGENTS.md. Use templates/project-agents.md."
    exit 1
else
    echo ""
    echo "All projects OK."
fi
