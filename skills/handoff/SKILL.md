---
name: handoff
description: "Prepare review handoff context directly from git and TASK.md without
  helper scripts. Use when an executing agent needs to package work for review,
  including before committing."
---

# Handoff Skill

## Inputs

- Task file path (default: `TASK.md`, optional)
- Base ref/branch for committed-range comparison (optional)
- Working ref/branch (default: `HEAD`)
- Include uncommitted changes (default: yes)

## Instructions

1. Default to pre-commit handoff scope:
   - If there are staged/unstaged changes or untracked files, use
     "pre-commit scope".
   - Only use committed-range scope when explicitly requested, or when working
     tree is clean.
2. Resolve refs:
   - Working ref defaults to `HEAD`.
   - If committed-range scope is needed and base ref is not provided, resolve in
     this order: `origin/HEAD` target branch, `develop`, `origin/develop`,
     `main`, `origin/main`, `master`, `origin/master`.
   - For committed-range scope, use merge-base:
     `MERGE_BASE=$(git merge-base <base> <working>)`.
3. Build task context:
   - If the task file exists, include it verbatim under `## Original Task`.
   - If the task file is missing, do not block. Include `## Task Context
     (Inferred)` using the user's request and the observed changed files.
4. Gather review context directly with git:
   - Always show current-branch history only (avoid inherited branch noise):
     `git log --oneline --first-parent --no-merges -n 20 <working>`
   - Pre-commit scope diff/stat (default): `git diff --stat HEAD` and
     `git diff HEAD` (changes since last commit).
   - Committed-range scope diff/stat: `git diff --stat <MERGE_BASE>..<working>`
     and `git diff <MERGE_BASE>..<working>`.
   - Untracked files: list with `git ls-files --others --exclude-standard`.
5. Produce a handoff bundle in this structure:

````markdown
# Handoff: Review Request

## Scope
- Mode: <pre-commit|committed-range>
- Working: <working ref>
- Base: <resolved base or N/A>
- Merge-base: <sha or N/A>

## Original Task
<TASK.md contents>

## Task Context (Inferred)
<only when TASK.md is missing>

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

## Untracked Files
```text
<untracked file list or "None">
```
````

6. By default, print the bundle in the response.
7. If the user asks to save it, write project-local `HANDOFF.md`.
8. Keep `TASK.md`, `REVIEW.md`, and `HANDOFF.md` out of committed changes.

## Quality Checks

- Task content is included verbatim when a task file exists.
- Missing `TASK.md` never blocks handoff generation.
- Scope and refs are explicit and reproducible.
- Pre-commit scope shows changes since `HEAD` by default.
- Generated handoff is complete and ready to paste into review context.
