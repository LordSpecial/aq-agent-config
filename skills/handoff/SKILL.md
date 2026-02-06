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
5. Gather metadata for staleness detection:
   - Current HEAD SHA: `git rev-parse HEAD`
   - Current timestamp (ISO 8601): `date -u +"%Y-%m-%dT%H:%M:%SZ"`
   - Current branch: `git branch --show-current`
6. Produce a handoff bundle following the structure in
   `~/.config/agent-config/templates/HANDOFF.md`:

````markdown
# Handoff: Review Request

## Metadata
- Prepared at: `<HEAD SHA>`
- Prepared on: `<timestamp>`
- Branch: `<current branch>`
- Base: `<resolved base or N/A>`
- Merge-base: `<merge-base SHA or N/A>`

## Task Context
<TASK.md contents if present, otherwise inferred context>

## Commits (Current Branch)
```text
<git log output>
```

## Changes Since HEAD

### Summary
```text
<git diff --stat HEAD>
```

### Full Diff
```diff
<git diff HEAD>
```

## Untracked Files
```text
<untracked file list or "None">
```

## Verification
<!-- If verification commands were run, include results here -->

## Next Steps
1. Review changes against task context
2. Run `/aq-review` to generate `REVIEW.md`
3. Apply feedback and regenerate this handoff if needed
````

7. Default to writing project-local `HANDOFF.md`.
8. Only print to terminal if user explicitly requests it.
9. Keep `TASK.md`, `REVIEW.md`, and `HANDOFF.md` out of committed changes.

## Quality Checks

- Task content is included verbatim when a task file exists.
- Missing `TASK.md` never blocks handoff generation.
- Metadata includes HEAD SHA for staleness detection.
- Timestamp and branch information are included.
- Scope and refs are explicit and reproducible.
- Pre-commit scope shows changes since `HEAD` by default.
- `HANDOFF.md` is written by default (not just printed).
