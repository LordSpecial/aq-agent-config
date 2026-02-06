# Prepare Review Handoff

Read the skill at `~/.claude/skills/handoff/SKILL.md` and follow its instructions.

Prepare review handoff context from current git state (including uncommitted
changes) without using helper scripts unless explicitly requested.
Default to changes since `HEAD` (pre-commit scope) and current-branch commit
history (`--first-parent`).
Prefer project-local `TASK.md`; if it is missing, infer task context and proceed
without blocking.

$ARGUMENTS
