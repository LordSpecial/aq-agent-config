---
name: diff-review
description: "Review a git diff against a TASK.md specification and produce a
  structured REVIEW.md. Use when acting as the review agent after an executing agent
  has completed work. Triggers: /review or /aq-review command, explicit request to
  review changes, or when evaluating another agent's output."
---

# Diff Review Skill

## Inputs

- Task context (priority: project-local `TASK.md`, then `HANDOFF.md`, then
  explicit user context)
- The git diff (provided via `handoff` skill, `agent-handoff` script, or
  `git diff` directly; committed and/or uncommitted)

## Instructions

1. Resolve task context in this order:
   a. Read `TASK.md` if present.
   b. Else read task context from `HANDOFF.md` if present.
   c. Else infer context from user request and changed files.
2. Identify acceptance criteria/constraints from the resolved context.
3. Review the diff file-by-file:
   a. Does each change serve the stated objective?
   b. Are there changes to files not listed in the task spec? Flag them.
   c. Do the changes violate any constraints?
   d. Do the changes follow the project's conventions?
4. Run or verify that verification commands were executed and passed.
5. Write a project-local `REVIEW.md` following
   `~/.config/agent-config/templates/REVIEW.md`.
6. Verdict:
   - **PASS**: All acceptance criteria met, no issues.
   - **PASS WITH COMMENTS**: Criteria met, minor improvements suggested.
   - **FAIL**: Acceptance criteria not met, or constraint violations found.

## Quality Checks

- Every acceptance criterion has an explicit pass/fail assessment.
- If context was inferred (no `TASK.md`/`HANDOFF.md`), state assumptions clearly.
- Issues include a suggested fix, not just a description.
- Verification results include actual command output.
