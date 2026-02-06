## Claude Code Specific

### Custom Commands

The following slash commands are available globally:

- `/aq-help` - Print the Claude command help section from shared `HELP.md`
- `/aq-init` - Initialise or align project agent setup
- `/plan` — Generate a structured TASK.md for agent handoff
- `/handoff` — Prepare a review handoff bundle from git state (pre-commit friendly)
- `/review` — First-pass review of a git diff against `TASK.md`
- `/aq-review` — Alias for review using `TASK.md` or inferred task context
- `/feedback` — Follow-up review of changes against existing `REVIEW.md` feedback
- `/bump-defs` — Bump aq-standard-definitions and regenerate
- `/cubemx-verify` — Verify CubeMX regeneration output

### Templates

Handoff templates are at `~/.config/agent-config/templates/`.
Generated handoff artefacts (`TASK.md`, `REVIEW.md`) should remain project-local.
