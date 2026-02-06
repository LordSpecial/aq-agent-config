# Review Changes Against Task Specification

Read the skill at `~/.claude/skills/diff-review/SKILL.md` and follow its instructions.

Read the REVIEW.md template at `~/.config/agent-config/templates/REVIEW.md`.

Review current changes against project task context.
Context priority: `HANDOFF.md` (preferred), then `TASK.md`, then inferred from
changes. Blocks if `HANDOFF.md` is stale.

$ARGUMENTS
