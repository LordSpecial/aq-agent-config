#!/usr/bin/env bash
# install.sh - Deploy agent configuration without Nix
# Usage: bash scripts/install.sh
# Run from the repository root.

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

echo "Installing from $REPO ..."

# -- Claude Code -----------------------------------------------------------

mkdir -p ~/.claude/commands ~/.claude/skills

# Global instructions (base + CC additions)
{
  echo "<!-- Managed by aq-agent-config install.sh. Re-run to update. -->"
  cat "$REPO/AGENTS.md"
  echo
  cat "$REPO/home/claude/CLAUDE.md"
} > ~/.claude/CLAUDE.md

cp "$REPO/home/claude/settings.json" ~/.claude/settings.json

# Commands
cp "$REPO"/home/claude/commands/*.md ~/.claude/commands/

# Skills
for skill_dir in "$REPO"/skills/*/; do
  name=$(basename "$skill_dir")
  mkdir -p ~/.claude/skills/"$name"
  cp -r "$skill_dir"/* ~/.claude/skills/"$name"/
done

# -- Codex -----------------------------------------------------------------

mkdir -p ~/.codex/skills

# Global instructions (base + Codex additions)
{
  echo "<!-- Managed by aq-agent-config install.sh. Re-run to update. -->"
  cat "$REPO/AGENTS.md"
  echo
  cat "$REPO/home/codex/AGENTS.md"
} > ~/.codex/AGENTS.md

cp "$REPO/home/codex/config.toml" ~/.codex/config.toml

# Skills
for skill_dir in "$REPO"/skills/*/; do
  name=$(basename "$skill_dir")
  mkdir -p ~/.codex/skills/"$name"
  cp -r "$skill_dir"/* ~/.codex/skills/"$name"/
done

# -- Shared assets ---------------------------------------------------------

mkdir -p ~/.config/agent-config

rm -rf ~/.config/agent-config/templates ~/.config/agent-config/scripts
cp -r "$REPO/templates" ~/.config/agent-config/templates
cp -r "$REPO/scripts" ~/.config/agent-config/scripts
cp "$REPO/HELP.md" ~/.config/agent-config/HELP.md

# -- Helper scripts on PATH -----------------------------------------------

mkdir -p ~/.local/bin
cp "$REPO/scripts/handoff.sh" ~/.local/bin/agent-handoff
cp "$REPO/scripts/sync-projects.sh" ~/.local/bin/agent-sync-projects
chmod +x ~/.local/bin/agent-handoff ~/.local/bin/agent-sync-projects

echo "Done."
echo ""
echo "Verify ~/.local/bin is on your PATH. If not, add to your shell profile:"
echo '  export PATH="$HOME/.local/bin:$PATH"'
