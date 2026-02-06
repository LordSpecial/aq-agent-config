# Handoff: Review Request

## Metadata
- Prepared at: `<HEAD SHA>`
- Prepared on: `<ISO 8601 timestamp>`
- Branch: `<current branch>`
- Base: `<base branch or N/A>`
- Merge-base: `<merge-base SHA or N/A>`

## Task Context
<!-- If TASK.md exists, include verbatim -->
<!-- Otherwise, infer from user request and changed files -->

## Commits (Current Branch)
```text
<git log --oneline --first-parent --no-merges -n 20>
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
<git ls-files --others --exclude-standard>
```

## Verification
<!-- If verification commands were run, include results here -->

## Next Steps
1. Review changes against task context
2. Run `/aq-review` to generate `REVIEW.md`
3. Apply feedback and regenerate this handoff if needed
