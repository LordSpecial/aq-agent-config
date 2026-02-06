## Claude Code Specific

### Custom Commands

The following slash commands are available globally:

- `/aq-help` - Print the Claude command help section from shared `HELP.md`
- `/aq-init` - Initialise or align project agent setup
- `/aq-plan` - Generate a structured TASK.md for agent handoff
- `/aq-handoff` - Prepare HANDOFF.md from git state (pre-commit friendly)
- `/aq-review` - First-pass review, write REVIEW.md
- `/aq-feedback` - Follow-up review, append to REVIEW.md
- `/aq-bump-defs` - Bump aq-standard-definitions and regenerate
- `/aq-cubemx-verify` - Verify CubeMX regeneration output

### Templates

Handoff templates are at `~/.config/agent-config/templates/`.
Generated handoff artefacts (`TASK.md`, `REVIEW.md`) should remain project-local.
