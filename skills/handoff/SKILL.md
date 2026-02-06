---
name: handoff
description: "Prepare review handoff context directly from git and TASK.md without
  helper scripts. Use when an executing agent needs to package work for review."
---

# Handoff Skill

## Inputs

- Task file path (default: `TASK.md`)
- Base ref/branch for comparison (default: `main`)
- Working ref/branch (default: `HEAD`)

## Instructions

1. Confirm the task file exists in the current repository.
2. Gather review context directly with git commands:
   - `git log --oneline <base>..<working>`
   - `git diff --stat <base>..<working>`
   - `git diff <base>..<working>`
3. Produce a handoff bundle in this exact structure:

````markdown
# Handoff: Review Request

## Original Task
<TASK.md contents>

## Commits
```text
<git log output>
```

## Diff Summary
```text
<git diff --stat output>
```

## Full Diff
```diff
<git diff output>
```
````

4. By default, print the bundle in the response.
5. If the user asks to save it, write project-local `HANDOFF.md`.
6. Keep `TASK.md`, `REVIEW.md`, and `HANDOFF.md` out of committed changes.

## Quality Checks

- Task content is included verbatim in the handoff bundle.
- Base and working refs are clearly reflected in the diff/log commands used.
- Generated handoff is complete and ready to paste into review context.
