---
name: diff-review
description: "Review a git diff against a TASK.md specification and produce a
  structured REVIEW.md. Supports both first-pass review and follow-up review modes.
  Use when acting as the review agent after an executing agent has completed work.
  Triggers: /aq-review command (first-pass), /aq-feedback command (follow-up),
  or explicit request to review changes."
---

# Diff Review Skill

## Inputs

- Task context (priority: `HANDOFF.md`, then project-local `TASK.md`, then
  explicit user context)
- The git diff (provided via `handoff` skill, `agent-handoff` script, or
  `git diff` directly; committed and/or uncommitted)

## Instructions

1. Determine review mode:
   - **First-pass review**: Triggered by `/aq-review` command or when `REVIEW.md` does not exist
   - **Follow-up review**: Triggered by `/aq-feedback` command or when `REVIEW.md` exists and user requests follow-up
2. Resolve task context in this order:
   a. Read `HANDOFF.md` if present.
   b. Else read `TASK.md` if present.
   c. Else infer context from user request, changed files, and current-branch
      history using:
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
3. Perform staleness check when reading `HANDOFF.md`:
   a. Extract "Prepared at" SHA from metadata.
   b. Compare with current HEAD: `git rev-parse HEAD`.
   c. If different, BLOCK review and instruct: "Handoff is stale (prepared at <sha>, HEAD is now <sha>). Run `/aq-handoff` to regenerate before reviewing."
   d. Do not proceed with review until handoff is fresh.
4. Identify acceptance criteria/constraints from the resolved context.
5. Review the diff file-by-file:
   a. Does each change serve the stated objective?
   b. Are there changes to files not listed in the task spec? Flag them.
   c. Do the changes violate any constraints?
   d. Do the changes follow the project's conventions?
6. Run or verify that verification commands were executed and passed.
7. Generate review output:
   - **First-pass**: Write project-local `REVIEW.md` following `~/.config/agent-config/templates/REVIEW.md`.
   - **Follow-up**: Append follow-up section to existing `REVIEW.md`.
8. Verdict:
   - **PASS**: All acceptance criteria met, no issues.
   - **PASS WITH COMMENTS**: Criteria met, minor improvements suggested.
   - **FAIL**: Acceptance criteria not met, or constraint violations found.

## Follow-Up Review Mode

When triggered by `/aq-feedback` or when `REVIEW.md` exists:

1. Require existing `REVIEW.md` (fail if missing, prompt user to run `/aq-review` first).
2. Read prior issues and comments from `REVIEW.md`.
3. Check current git state or regenerated `HANDOFF.md`.
4. For each prior issue, determine:
   - Resolved: Issue fully addressed
   - Partially addressed: Some progress but incomplete
   - Not addressed: No change related to this issue
5. Identify any new issues discovered in this review round.
6. Append follow-up section to existing `REVIEW.md`:

```markdown
---

## Follow-Up Review

### Metadata
- Reviewed at: `<current HEAD SHA>`
- Handoff ref: `<handoff SHA if from HANDOFF.md>`
- Follow-up round: `<number>`

### Prior Issues Status

- [x] Issue 1: Resolved
- [ ] Issue 2: Not addressed
- [~] Issue 3: Partially addressed

### New Issues

<Any new issues found>

### Verdict
**PASS** | **PASS WITH COMMENTS** | **FAIL**

### Next Steps
<What should happen next>
```

## Quality Checks

- Every acceptance criterion has an explicit pass/fail assessment.
- If context was inferred (no `TASK.md`/`HANDOFF.md`), state assumptions clearly.
- Issues include a suggested fix, not just a description.
- Verification results include actual command output.
- Review is blocked when HANDOFF.md is stale, requiring regeneration.
- Follow-up reviews explicitly track resolution of prior issues.
- `REVIEW.md` is written by default (not just printed).
