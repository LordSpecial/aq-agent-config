## Codex Specific

### Skills

Global skills are auto-discovered from `~/.codex/skills/`. When a task matches a
skill trigger, the full SKILL.md will be loaded.

Available skills: init, task-spec, diff-review, commit-msg, submodule-bump,
cubemx-verify.

### Templates

Handoff templates are at `~/.config/agent-config/templates/`.
Generated handoff artefacts (`TASK.md`, `REVIEW.md`) should remain project-local.
