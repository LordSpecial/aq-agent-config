---
name: diff-review
description: "Review a git diff against a TASK.md specification and produce a
  structured REVIEW.md. Use when acting as the review agent after an executing agent
  has completed work. Triggers: /review command, explicit request to review changes,
  or when evaluating another agent's output."
---

# Diff Review Skill

## Inputs

- The original project-local `TASK.md`
- The git diff (provided via `handoff` skill, `agent-handoff` script, or
  `git diff` directly)

## Instructions

1. Read the `TASK.md` acceptance criteria and constraints.
2. Review the diff file-by-file:
   a. Does each change serve the stated objective?
   b. Are there changes to files not listed in the task spec? Flag them.
   c. Do the changes violate any constraints?
   d. Do the changes follow the project's conventions?
3. Run or verify that verification commands were executed and passed.
4. Write a project-local `REVIEW.md` following
   `~/.config/agent-config/templates/REVIEW.md`.
5. Verdict:
   - **PASS**: All acceptance criteria met, no issues.
   - **PASS WITH COMMENTS**: Criteria met, minor improvements suggested.
   - **FAIL**: Acceptance criteria not met, or constraint violations found.

## Quality Checks

- Every acceptance criterion has an explicit pass/fail assessment.
- Issues include a suggested fix, not just a description.
- Verification results include actual command output.
