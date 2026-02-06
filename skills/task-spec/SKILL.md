---
name: task-spec
description: "Generate a structured task specification (TASK.md) for agent handoff.
  Use when acting as the planning agent and need to produce a work order for an
  executing agent. Triggers: /aq-plan command, explicit request to plan a task, or when
  preparing work for another agent."
---

# Task Specification Skill

## Instructions

1. Read the user's request. Clarify ambiguities before proceeding.
2. Identify the target repository and read its project instructions (`AGENTS.md`,
   `CLAUDE.md`, `README.md`) and build entry points.
3. Determine the minimal set of files that need to change.
4. Write a project-local `TASK.md` following
   `~/.config/agent-config/templates/TASK.md`.
5. For each acceptance criterion, ensure there is a corresponding verification command.
6. List all context files the executing agent will need to read.
7. Define a rollback strategy (usually `git checkout` of affected files).
8. Present the `TASK.md` to the user for review before handoff.

## Quality Checks

- Every file listed under "Files" has a clear action (Read/Modify/Create).
- Acceptance criteria are testable, not subjective.
- Verification commands are copy-pasteable with no placeholders.
- Constraints explicitly state what must not change.
