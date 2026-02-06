## Claude Code Specific

### Custom Commands

The following slash commands are available globally:

- `/aq-init` - Initialise or align project agent setup
- `/plan` — Generate a structured TASK.md for agent handoff
- `/review` — Review a git diff against a TASK.md specification
- `/bump-defs` — Bump aq-standard-definitions and regenerate
- `/cubemx-verify` — Verify CubeMX regeneration output

### Templates

Handoff templates are at `~/.config/agent-config/templates/`.
Generated handoff artefacts (`TASK.md`, `REVIEW.md`) should remain project-local.
