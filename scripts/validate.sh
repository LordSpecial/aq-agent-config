#!/usr/bin/env bash
# validate.sh - Basic repository validation checks

set -euo pipefail

required_files=(
  "AGENTS.md"
  "README.md"
  "HELP.md"
  "CHANGELOG.md"
  "nix/module.nix"
  "templates/TASK.md"
  "templates/REVIEW.md"
  "templates/HANDOFF.md"
)

for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "Missing required file: $file" >&2
    exit 1
  fi
done

# All skills must have frontmatter name+description.
for skill in skills/*/SKILL.md; do
  rg -q '^name:' "$skill" || { echo "Missing name in $skill" >&2; exit 1; }
  rg -q '^description:' "$skill" || { echo "Missing description in $skill" >&2; exit 1; }
done

# Shell script syntax.
bash -n scripts/handoff.sh
bash -n scripts/sync-projects.sh
bash -n scripts/install.sh

# All command files must have aq- prefix.
for cmd in home/claude/commands/*.md; do
  basename=$(basename "$cmd")
  if [[ ! "$basename" =~ ^aq- ]]; then
    echo "Command file missing aq- prefix: $basename" >&2
    exit 1
  fi
done

# No old command names in active guidance (allow in REFACTOR.md, CHANGELOG.md as historical).
# Look for old slash commands without aq- prefix:
# - Backticked: `/plan`, `/review`, etc.
# - Parenthesized: (/plan)
# - After "run", "use", "invoke": run /plan, use /review
# Exclude command files (they reference skill paths which don't have aq- prefix)
old_commands=(
  "\`/plan\`|\(/plan\)|\b(run|use|invoke)\s+/plan\b"
  "\`/review\`|\(/review\)|\b(run|use|invoke)\s+/review\b"
  "\`/feedback\`|\(/feedback\)|\b(run|use|invoke)\s+/feedback\b"
  "\`/handoff\`|\(/handoff\)|\b(run|use|invoke)\s+/handoff\b"
  "\`/bump-defs\`|\(/bump-defs\)|\b(run|use|invoke)\s+/bump-defs\b"
  "\`/cubemx-verify\`|\(/cubemx-verify\)|\b(run|use|invoke)\s+/cubemx-verify\b"
)
check_files=("AGENTS.md" "README.md" "HELP.md" "home/claude/CLAUDE.md" "home/codex/AGENTS.md" "skills/*/SKILL.md")

for pattern in "${old_commands[@]}"; do
  for file_pattern in "${check_files[@]}"; do
    # Expand glob
    for file in $file_pattern; do
      if [ -f "$file" ] && rg -q "$pattern" "$file"; then
        echo "Found old command reference matching $pattern in $file" >&2
        rg "$pattern" "$file" >&2
        exit 1
      fi
    done
  done
done

echo "Validation passed."
