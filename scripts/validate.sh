#!/usr/bin/env bash
# validate.sh - Basic repository validation checks

set -euo pipefail

required_files=(
  "AGENTS.md"
  "README.md"
  "CHANGELOG.md"
  "nix/module.nix"
  "templates/TASK.md"
  "templates/REVIEW.md"
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

echo "Validation passed."
