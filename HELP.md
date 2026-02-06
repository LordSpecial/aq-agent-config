# Agent Command Help

Last updated: 06/02/2026

This guide lists the global commands and skills installed by this repository.

## Claude Code Commands

Use these as slash commands in Claude Code.

| Command | Purpose | Typical use |
|---------|---------|-------------|
| `/aq-help` | Print the Claude help section from this file | Quick command reference in Claude |
| `/aq-init` | Initialise or align project agent setup | First run in a new or existing project |
| `/plan` | Generate project-local `TASK.md` | Define objective, files, checks, and constraints before execution |
| `/handoff` | Prepare a review handoff bundle from git state | Default: changes since `HEAD` before commit/review |
| `/review` | Run a full review against `TASK.md` and write `REVIEW.md` | First review pass after implementation |
| `/aq-review` | Alias for review with task-context fallback | Review even when `TASK.md` is missing |
| `/feedback` | Re-review changes against prior feedback in `REVIEW.md` | Follow-up review after `PASS WITH COMMENTS` |
| `/bump-defs` | Bump `aq-standard-definitions` and regenerate outputs | Definition updates in `aq-*` repositories |
| `/cubemx-verify` | Verify CubeMX regeneration integrity | STM32/CubeMX projects after regeneration |

## Codex Skills

Codex uses skills (not slash commands). Invoke by asking Codex to use the skill
for the current task.

| Skill | Purpose | Typical use |
|-------|---------|-------------|
| `init` | Initialise or align project-level agent setup | First run in a project from Codex |
| `task-spec` | Build a structured `TASK.md` from a request | Planning without Claude `/plan` |
| `handoff` | Build a review handoff bundle from git context | Default: pre-commit diff from `HEAD`, plus branch history |
| `diff-review` | Review a diff against `TASK.md` and produce `REVIEW.md` | Review-agent workflow in Codex |
| `commit-msg` | Draft commit messages from staged changes and repo style | Before creating a commit |
| `submodule-bump` | Bump submodule references safely | Dependency update tasks |
| `cubemx-verify` | Validate CubeMX regeneration and repo state | STM32/CubeMX validation tasks |
| `aq-help` | Print the Codex skill help section from this file | Quick skill reference in Codex |

## Preparing Handoff for Review

Preferred: use the `handoff` skill in Codex (or `/handoff` in Claude) to produce
review context directly from git state (including uncommitted changes).

Script fallback:

```bash
agent-handoff TASK.md main HEAD
```

Optional: save output for review context:

```bash
agent-handoff TASK.md main HEAD > HANDOFF.md
```
