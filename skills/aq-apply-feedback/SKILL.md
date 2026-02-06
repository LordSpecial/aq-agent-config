---
name: aq-apply-feedback
description: "Apply review feedback from REVIEW.md to an in-progress change set and
  prepare an updated handoff. Use when the executing agent needs to address review
  issues before follow-up review. Triggers: explicit requests such as 'apply reviewer
  feedback', 'address REVIEW.md comments', or 'fix review issues'."
---

# Apply Feedback Skill

## Inputs

- Existing `REVIEW.md` (required)
- `TASK.md` (optional but preferred)
- Current git state and changed files
- Existing `HANDOFF.md` (optional, for context only)

## Instructions

1. Read `REVIEW.md` and extract:
   - Current verdict
   - Issues (severity, location, required fix)
   - Comments that imply concrete follow-up work
2. Resolve execution context:
   - If `TASK.md` exists, use it to keep scope bounded.
   - If `TASK.md` is missing, infer scope from `REVIEW.md`, changed files, and
     current-branch history using:
     ```bash
     # Commit subjects + full message bodies
     git log --first-parent --no-merges -n 20 --pretty=format:'%h %s%n%b%n---'

     # Branch-level touched-file frequency summary
     git log --first-parent --no-merges -n 20 --name-only --pretty=format: \
       | rg -v '^$' \
       | sort \
       | uniq -c \
       | sort -nr
     ```
3. Build a fix checklist:
   - Mark each prior issue as target work.
   - Separate must-fix items (for FAIL) from discretionary improvements
     (for PASS WITH COMMENTS).
4. Implement the smallest change set that addresses each must-fix item.
5. Re-run the relevant verification commands from `TASK.md` or `REVIEW.md`.
6. Confirm issue coverage explicitly:
   - Resolved: fully fixed and verified.
   - Partially addressed: progress made but incomplete.
   - Not addressed: no valid change.
7. Regenerate project-local `HANDOFF.md` for follow-up review using current git
   state and include verification results.
8. Return a concise summary with:
   - Files changed
   - Verification results
   - Issue-by-issue status mapping

## Quality Checks

- Do not ignore Critical or Major issues when verdict is FAIL.
- Keep changes scoped to review findings and task requirements.
- Verification results are concrete command outcomes, not assumptions.
- `HANDOFF.md` is refreshed after fixes so follow-up review context is current.
