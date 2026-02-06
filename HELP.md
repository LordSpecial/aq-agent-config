# Agent Command Help

Last updated: 06/02/2026

This guide lists the global commands and skills installed by this repository.

## Claude Code Commands

Use these as slash commands in Claude Code.

### Setup & Information

| Command | Purpose | Output |
|---------|---------|--------|
| `/aq-help` | Print command reference from this file | Terminal |
| `/aq-init` | Initialise or align project agent setup | `AGENTS.md`, `CLAUDE.md`, `.gitignore` |

### Planning & Execution Workflow

| Command | Purpose | Output |
|---------|---------|--------|
| `/aq-plan` | Generate task specification | `TASK.md` |
| `/aq-handoff` | Prepare review request from git state | `HANDOFF.md` |

### Review Workflow

| Command | Purpose | Output |
|---------|---------|--------|
| `/aq-review` | First-pass review against task context | `REVIEW.md` |
| `/aq-feedback` | Follow-up review after fixes | `REVIEW.md` (updated) |

### Utilities

| Command | Purpose | Output |
|---------|---------|--------|
| `/aq-bump-defs` | Bump `aq-standard-definitions` and regenerate | Git commit |
| `/aq-cubemx-verify` | Verify CubeMX regeneration integrity | Terminal report |

## Codex Skills

Codex uses skills (not slash commands). Invoke by asking Codex to use the skill
for the current task.

| Skill | Purpose | Typical use |
|-------|---------|-------------|
| `init` | Initialise or align project-level agent setup | First run in a project from Codex |
| `task-spec` | Build a structured `TASK.md` from a request | Planning without Claude `/aq-plan` |
| `handoff` | Build a review handoff bundle from git context | Default: pre-commit diff from `HEAD`, plus branch history |
| `diff-review` | Review a diff against `TASK.md` and produce `REVIEW.md` | Review-agent workflow in Codex |
| `aq-apply-feedback` | Apply `REVIEW.md` findings and refresh review context | Execution follow-up after review comments |
| `commit-msg` | Draft commit messages from staged changes and repo style | Before creating a commit |
| `submodule-bump` | Bump submodule references safely | Dependency update tasks |
| `cubemx-verify` | Validate CubeMX regeneration and repo state | STM32/CubeMX validation tasks |
| `aq-help` | Print the Codex skill help section from this file | Quick skill reference in Codex |

## Preparing Handoff for Review

### Primary Method (Preferred)

Use the `handoff` skill in Codex or `/aq-handoff` in Claude Code to generate
`HANDOFF.md` directly from git state.

**Default behaviour:**
- Captures staged + unstaged changes (pre-commit scope)
- Includes current HEAD SHA for staleness detection
- Writes project-local `HANDOFF.md`

**Example usage:**
```
Terminal B (Codex): "Prepare handoff for review"
Terminal A (Claude): /aq-handoff
```

### Script Fallback (Legacy)

```bash
agent-handoff TASK.md main HEAD > HANDOFF.md
```

Note: The script method is provided for backwards compatibility. The skill/command
method is preferred as it includes metadata for staleness detection.
