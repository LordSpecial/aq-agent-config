# Agent Config Refactoring Plan

Last updated: 06/02/2026

## Overview

This document outlines a refactoring of the agent configuration to improve clarity, consistency, and workflow support for the execute → review → execute cycle between Codex (execution) and Claude Code (review).

## Design Principles

1. **Consistent naming**: All custom commands use `aq-` prefix to differentiate from potential future Claude Code built-in commands
2. **Persistent artefacts**: Commands default to writing `.md` files for handoff, review, and task tracking
3. **Staleness detection**: Handoff documents include reference commits to detect outdated review context
4. **Graceful fallback**: Review commands work with or without formal TASK.md/HANDOFF.md
5. **Pre-commit focus**: Default workflow captures unstaged/staged changes before commit

## Core Workflow

### Execute → Review → Execute Cycle

```
┌─────────────────────────────────────────────────────────────────┐
│ Terminal A (Claude Code - Planning/Review)                      │
├─────────────────────────────────────────────────────────────────┤
│ $ /aq-init          # Setup project                             │
│ $ /aq-plan <desc>   # Write TASK.md                             │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ↓ (TASK.md exists)
┌─────────────────────────────────────────────────────────────────┐
│ Terminal B (Codex - Execution)                                  │
├─────────────────────────────────────────────────────────────────┤
│ $ "Execute TASK.md"          # Implement changes                │
│ $ "Prepare handoff"          # Write HANDOFF.md                 │
│   (or invoke handoff skill)                                     │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ↓ (HANDOFF.md + staged/unstaged changes)
┌─────────────────────────────────────────────────────────────────┐
│ Terminal A (Claude Code - Review)                               │
├─────────────────────────────────────────────────────────────────┤
│ $ /aq-review         # Read HANDOFF.md, write REVIEW.md         │
│                      # Verdict: PASS / PASS WITH COMMENTS       │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ↓ (REVIEW.md exists)
┌─────────────────────────────────────────────────────────────────┐
│ Terminal B (Codex - Apply Feedback)                             │
├─────────────────────────────────────────────────────────────────┤
│ $ "Apply reviewer feedback"  # Read REVIEW.md, fix issues       │
│ $ "Update handoff"           # Regenerate HANDOFF.md            │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ↓ (Updated HANDOFF.md)
┌─────────────────────────────────────────────────────────────────┐
│ Terminal A (Claude Code - Follow-up Review)                     │
├─────────────────────────────────────────────────────────────────┤
│ $ /aq-feedback       # Check fixes, update REVIEW.md            │
│                      # Verdict: PASS                            │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ↓ (Approved)
┌─────────────────────────────────────────────────────────────────┐
│ Terminal B (Codex - Commit)                                     │
├─────────────────────────────────────────────────────────────────┤
│ $ "Commit changes"   # Use commit-msg skill, create commit      │
└─────────────────────────────────────────────────────────────────┘
```

### Key Workflow Features

1. **Pre-commit handoff (default)**:
   - Codex prepares `HANDOFF.md` from staged/unstaged changes
   - Includes `HEAD` commit SHA as staleness reference
   - Claude reviews before commit happens

2. **Staleness detection**:
   - `HANDOFF.md` records current `HEAD` SHA
   - Reviewer sees: "Handoff prepared at: abc1234"
   - If `HEAD` changed since handoff, reviewer knows context is stale

3. **Graceful fallback**:
   - If `TASK.md` missing: review infers context from changes
   - If `HANDOFF.md` missing: review reads git state directly
   - If `REVIEW.md` missing: feedback command prompts user

## Refactored Commands

### Before (9 commands, inconsistent naming)

| Command | Issues |
|---------|--------|
| `/aq-help` | ✓ Good |
| `/aq-init` | ✓ Good |
| `/plan` | ✗ Missing `aq-` prefix |
| `/handoff` | ✗ Missing `aq-` prefix, unclear output behaviour |
| `/review` | ✗ Missing `aq-` prefix |
| `/aq-review` | ✗ Redundant with `/review` |
| `/feedback` | ✗ Missing `aq-` prefix, ambiguous name |
| `/bump-defs` | ✗ Missing `aq-` prefix |
| `/cubemx-verify` | ✗ Missing `aq-` prefix |

### After (8 commands, consistent naming)

| Command | Purpose | Primary Output |
|---------|---------|----------------|
| `/aq-help` | Print command reference | Terminal |
| `/aq-init` | Initialise project setup | `AGENTS.md`, `CLAUDE.md`, `.gitignore` |
| `/aq-plan` | Generate task specification | `TASK.md` |
| `/aq-handoff` | Prepare review request | `HANDOFF.md` |
| `/aq-review` | First-pass review | `REVIEW.md` |
| `/aq-feedback` | Follow-up review | `REVIEW.md` (updated) |
| `/aq-bump-defs` | Bump definitions submodule | Git commit |
| `/aq-cubemx-verify` | Verify CubeMX regeneration | Terminal report |

### Removed Commands

- **`/aq-review`** - Merged into `/aq-review` (fallback behaviour is default)

## Command Details

### `/aq-handoff` - Prepare Review Request

**Purpose**: Generate a comprehensive handoff document for review.

**Default behaviour**:

- Scope: pre-commit (staged + unstaged changes)
- Output: `HANDOFF.md` in project root
- Reference: includes current `HEAD` SHA

**HANDOFF.md structure**:

```markdown
# Handoff: Review Request

## Metadata
- Prepared at: `<HEAD SHA>`
- Prepared on: `<timestamp>`
- Branch: `<current branch>`
- Base: `<resolved base branch or N/A>`

## Task Context
<Contents of TASK.md if present, otherwise inferred context>

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

## Next Steps

- Review changes against task context
- Run `/aq-review` to generate REVIEW.md
- Apply feedback and regenerate this handoff if needed

```

**Staleness detection**:
- Reviewer checks "Prepared at" SHA against current `HEAD`
- If different, handoff is stale and should be regenerated

**Committed-range mode** (optional):
When explicitly requested (e.g., "/aq-handoff from main to HEAD"):
- Use merge-base for diff range
- Show committed history only
- Still include metadata for staleness tracking

### `/aq-review` - First-Pass Review

**Purpose**: Review changes and produce structured feedback.

**Inputs** (priority order):
1. `HANDOFF.md` (preferred - contains full context with metadata)
2. `TASK.md` + git state (read directly)
3. Inferred context from git state

**Output**: `REVIEW.md` in project root

**Staleness check**:
- If reading `HANDOFF.md`, compare "Prepared at" SHA with current `HEAD`
- Block review if mismatch detected, require regeneration

**REVIEW.md structure**:
```markdown
# Review: <task title>

## Metadata
- Reviewed at: `<current HEAD SHA>`
- Handoff ref: `<handoff SHA if from HANDOFF.md>`
- Reviewer: Claude Code

## Context
<Task objective and acceptance criteria>

## Verdict
**PASS** | **PASS WITH COMMENTS** | **FAIL**

## Acceptance Criteria

- [x] Criterion 1: Met
- [x] Criterion 2: Met
- [ ] Criterion 3: Not met

## Issues

### Issue 1: <description>
**Severity**: Critical | Major | Minor
**Location**: `file.c:42`
**Fix**: <suggested resolution>

## Comments

### Comment 1: <observation>
**Location**: `file.c:100`
**Suggestion**: <optional improvement>

## Verification

```bash
# Commands run and results
make build  # PASS
make test   # PASS
```

## Next Steps

- If FAIL or PASS WITH COMMENTS: address issues and run `/aq-feedback`
- If PASS: proceed to commit

```

### `/aq-feedback` - Follow-Up Review

**Purpose**: Re-review changes after feedback has been applied.

**Inputs** (required):
1. Existing `REVIEW.md` (must exist, else prompt user to run `/aq-review` first)
2. `HANDOFF.md` (regenerated) or git state

**Output**: `REVIEW.md` (updated with follow-up section)

**Behaviour**:
- Append follow-up section to existing `REVIEW.md`
- Focus on whether prior issues/comments were addressed
- New verdict: PASS | PASS WITH COMMENTS | FAIL

**Updated REVIEW.md structure**:
```markdown
# Review: <task title>

## Metadata
...

## Verdict
**PASS WITH COMMENTS** (initial review)

...

---

## Follow-Up Review

### Metadata
- Reviewed at: `<current HEAD SHA>`
- Handoff ref: `<updated handoff SHA>`

### Prior Issues Status

- [x] Issue 1: Resolved
- [x] Issue 2: Resolved
- [ ] Issue 3: Partially addressed

### New Issues

<Any new issues found>

### Verdict
**PASS**

### Next Steps
- Proceed to commit
```

## Implementation Changes

### Files to Modify

#### Command files (rename/update)

```
home/claude/commands/plan.md          → home/claude/commands/aq-plan.md
home/claude/commands/handoff.md       → home/claude/commands/aq-handoff.md
home/claude/commands/review.md        → home/claude/commands/aq-review.md
home/claude/commands/aq-review.md     → DELETE (redundant)
home/claude/commands/feedback.md      → home/claude/commands/aq-feedback.md
home/claude/commands/bump-defs.md     → home/claude/commands/aq-bump-defs.md
home/claude/commands/cubemx-verify.md → home/claude/commands/aq-cubemx-verify.md
```

#### Skill files (update instructions)

```
skills/handoff/SKILL.md     # Update to default to writing HANDOFF.md
skills/diff-review/SKILL.md # Update to default to writing REVIEW.md
```

#### Documentation

```
HELP.md                     # Update command list and grouping
README.md                   # Update example workflow
home/claude/CLAUDE.md       # Update command list
```

#### Templates (enhance)

```
templates/HANDOFF.md        # NEW - template for handoff structure
templates/REVIEW.md         # UPDATE - add follow-up section format
```

### Skill Updates

#### `skills/handoff/SKILL.md`

**Key changes**:

1. Default to writing `HANDOFF.md` (not just printing)
2. Always include `HEAD` SHA in metadata
3. Default scope: pre-commit (staged + unstaged)
4. Include staleness detection metadata

**New instruction sections**:

```markdown
## Default Output Behaviour

1. Generate handoff content following the structure in
   `~/.config/agent-config/templates/HANDOFF.md`.
2. Write to project-local `HANDOFF.md` by default.
3. Only print to terminal if user explicitly requests it.

## Metadata Requirements

Always include in the handoff:
- Current HEAD SHA (for staleness detection)
- Timestamp (ISO 8601 format)
- Current branch name
- Resolved base branch (if committed-range scope)
```

#### `skills/diff-review/SKILL.md`

**Key changes**:

1. Default to writing `REVIEW.md` (not just printing)
2. Check handoff staleness when reading `HANDOFF.md`
3. Support follow-up review mode (append to existing `REVIEW.md`)

**New instruction sections**:

```markdown
## Default Output Behaviour

1. Generate review content following the structure in
   `~/.config/agent-config/templates/REVIEW.md`.
2. Write to project-local `REVIEW.md` by default.
3. Only print to terminal if user explicitly requests it.

## Staleness Detection

When reading `HANDOFF.md`:
1. Extract "Prepared at" SHA
2. Compare with current HEAD: `git rev-parse HEAD`
3. If different, warn: "Handoff is stale (prepared at <sha>, HEAD is now <sha>).
   Regenerate handoff before reviewing."

## Follow-Up Review Mode

Triggered by `/aq-feedback` command:
1. Require existing `REVIEW.md` (fail if missing)
2. Read prior issues and comments
3. Check if each issue was addressed
4. Append follow-up section to existing `REVIEW.md`
```

### Template Files

#### `templates/HANDOFF.md` (NEW)

```markdown
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

```

#### `templates/REVIEW.md` (UPDATE)

Add follow-up section template:

```markdown
---

## Follow-Up Review

### Metadata
- Reviewed at: `<current HEAD SHA>`
- Handoff ref: `<handoff SHA if available>`
- Follow-up round: `<number>`

### Prior Issues Status

- [ ] Issue 1: Status (Resolved / Partially addressed / Not addressed)
- [ ] Issue 2: Status
- [ ] Issue 3: Status

### New Issues

<Any new issues discovered in this review round>

### New Comments

<Any new observations or suggestions>

### Verdict
**PASS** | **PASS WITH COMMENTS** | **FAIL**

### Next Steps
<What should happen next>
```

## Migration Path

### Phase 1: Command Renaming

1. Rename command files to add `aq-` prefix
2. Update `home/claude/CLAUDE.md` with new command names
3. Update `HELP.md` with new command list

### Phase 2: Skill Enhancements

1. Update `handoff` skill to default to writing `HANDOFF.md`
2. Add staleness detection metadata
3. Update `diff-review` skill to default to writing `REVIEW.md`
4. Add staleness checking logic
5. Add follow-up review mode

### Phase 3: Documentation

1. Update `README.md` with new workflow example
2. Update `HELP.md` with command grouping
3. Create `templates/HANDOFF.md`
4. Enhance `templates/REVIEW.md`

### Phase 4: Validation

1. Test full workflow: init → plan → execute → handoff → review → feedback
2. Test staleness detection
3. Test fallback scenarios (missing TASK.md, missing HANDOFF.md)
4. Update CI validation if needed

## Benefits

### Consistency

- All custom commands have `aq-` prefix
- Clear namespace separation from potential built-in commands

### Traceability

- All handoffs and reviews written to `.md` files
- Clear audit trail of review rounds
- Staleness detection prevents reviewing outdated state

### Workflow Support

- Pre-commit handoff is default (prevents committing unreviewed work)
- Follow-up review explicitly tracks issue resolution
- Graceful fallback when formal docs missing

### Developer Experience

- Clear command names indicate purpose
- Persistent artefacts can be referenced later
- Two-terminal workflow is explicit and documented

## Open Questions

1. **Handoff file lifecycle**: Should `HANDOFF.md` be regenerated on each handoff, or versioned (e.g., `HANDOFF-001.md`, `HANDOFF-002.md`)?
   - **Recommendation**: Regenerate (overwrite). Use git history to track changes.

2. **Review file lifecycle**: Should follow-up reviews append or create new files?
   - **Recommendation**: Append (single `REVIEW.md` with multiple sections). Preserves conversation history.

3. **Committed-range handoff**: When should this be used vs pre-commit?
   - **Recommendation**: Pre-commit is default. Committed-range only for post-merge review or historical analysis.

4. **Staleness tolerance**: Should stale handoff block review or just warn?
   - **Decision**: Block review. Prevents reviewing outdated state and ensures handoff accuracy.

5. **Codex command equivalence**: Should Codex skills use same naming?
   - **Recommendation**: Skills don't have the namespace collision concern. Keep skill names clean (`handoff`, `diff-review`), let command wrappers add `aq-` prefix.

## Success Criteria

Refactoring is successful when:

1. ✓ All custom commands have `aq-` prefix
2. ✓ `/aq-handoff` writes `HANDOFF.md` by default
3. ✓ `/aq-review` writes `REVIEW.md` by default
4. ✓ Staleness detection prevents reviewing stale context
5. ✓ Follow-up review explicitly tracks issue resolution
6. ⏳ Full workflow tested end-to-end in two-terminal setup (requires post-deployment testing)
7. ✓ Documentation updated (README, HELP, CLAUDE.md)
8. ✓ No regression in existing functionality
