# Agent Instructions (Global)

Last updated: 06/02/2026

This file defines baseline guidance for AI coding assistants working in this workspace. It is intentionally broad; projects may add stricter, more specific rules in their own `AGENTS.md`.

This file is global, so it should be kept generic. It is also a living document and
should be updated over time as you gain a more detailed understanding of your
workflow.

## Instruction Precedence

1. System/tool instructions (e.g., the runtime harness you are operating under)
2. The closest project/directory `AGENTS.md` to the files you will change
3. This file

If instructions conflict, ask for clarification and proceed conservatively.

If the user/prompt directly conflicts with any of these, clarify and offer to add an
exception/clarification to the closest `AGENTS.md`.

When given feedback on a previous response, incorporate it and offer to update the
closest project-level instructions file if the feedback reflects a recurring preference
or correction.

## Working Method (Default)

- **Discover**: identify the project root and read `AGENTS.md`, `README.md`, and the primary build/test entry points (e.g., `Makefile`, `CMakeLists.txt`, `go.mod`, `pyproject.toml`, CI config).
- **Clarify**: confirm requirements, constraints, and acceptance criteria before making broad changes.
- **Implement**: prefer the smallest change that fixes the root cause; avoid drive-by refactors.
- **Validate**: run the most relevant formatter/linter/tests/build steps; record the exact commands and results.
- **Communicate**: summarise what changed, why, and any risks or follow-ups.

## Language and Communication

- **British English only** for all prose: docs, comments, commit messages, PR text, user-facing strings.
- Date format: **DD/MM/YYYY** (e.g., 03/02/2026). Use 24-hour time where relevant (e.g., 15:37).
- Keep communication professional and concise; avoid slang and emojis.
- Use SI units unless a project explicitly uses alternatives.

## Safety, Security, and Compliance

- Never add or commit secrets (API keys, tokens, credentials). Use environment variables or approved secret stores.
- Do not run privileged or destructive operations without explicit confirmation (e.g., `sudo`, flashing, `rm -rf`, force pushes, `git reset --hard`).
- Treat hardware interaction as safety-critical: confirm target device, configuration, and rollback steps before flashing or applying power.
- Validate all external inputs (files, network payloads, CAN frames, serial, config) and avoid logging sensitive data.

## Repository Hygiene

- Follow existing code style and project conventions; do not introduce new tooling/dependencies unless necessary and justified.
- Keep generated artefacts out of git; follow `.gitignore` and existing patterns (`build/`, `bin/`, `.venv/`, etc.).
- Generated code: do not hand-edit. Modify the source (schemas/YAML/templates), regenerate using the project’s documented process, and commit regenerated outputs only if the repo expects them.
- Git submodules: treat as pinned dependencies. Avoid editing submodule contents unless asked; prefer updating via a submodule revision bump.
  - The exception to this is `aq-standard-definitions`. This repository is used
    frequently as a submodule and can be updated whenever necessary (following
    generated code guidelines).

## Version Control

- Commit messages: imperative mood and consistent with the project’s existing convention (e.g., Conventional Commits if already used).
- Keep commits atomic and scoped; explain *why* as well as *what*.
- Keep commits concise. A one-line is fine for simple/obvious changes.
- Reference issue/ticket numbers when applicable.

## Builds, Tests, and Timeouts

- Prefer the project’s own entry points (`make`, `just`, `task`, `scripts/…`) over ad-hoc commands.
  - Always check for a `Makefile`, if it exists use it. If you are, or will be, frequently using a command, offer to add it to `Makefile`
- Never cancel a build/test simply because it is slow. If a command may take time, state an expected duration and set a generous timeout (2–5× normal).
- If tests do not exist, perform a reasonable manual verification and document what you ran/observed.
- `aq-*` are all Aquila projects. These will frequently use git submodules and
  Python-based code generation (notably `aq-standard-definitions`). Prefer the
  repo-provided targets (commonly `make deps` / `make generate`) rather than running
  scripts manually.

## Skills

Skills are reusable instruction sets stored globally. Each skill is a directory
containing a `SKILL.md` with YAML frontmatter (`name`, `description`) and optional
`scripts/`, `references/`, and `assets/` subdirectories.

Global skills are automatically discovered by both CC (`~/.claude/skills/`) and
Codex (`~/.codex/skills/`). Project-level skills can be added to `.claude/skills/`
or the project's skills directory.

- Skills are read-only references; do not modify them during task execution.
- When multiple skills are relevant, read all of them before starting work.
- If a skill conflicts with project-level instructions, the project file wins.
- Propose new skills or improvements via `SUGGESTIONS.md` in `aq-agent-config`.

In Claude Code, skills also surface as slash commands (e.g., `/plan`, `/handoff`,
`/review`, `/bump-defs`, `/cubemx-verify`).

## Agent Handoff

When a task involves multiple agents (e.g., CC for planning, Codex for execution),
handoff artefacts must stay project-level:

1. The planning agent writes a project-local `TASK.md` (typically in the project
   root), following the template at `~/.config/agent-config/templates/TASK.md`.
2. The executing agent reads that project-local `TASK.md` as its primary work order.
3. After execution, a review agent evaluates the diff against the same `TASK.md` and
   writes a project-local `REVIEW.md`.
4. `TASK.md` and `REVIEW.md` are temporary artefacts; do not commit them to the
   project repository.

## Technology-Specific Guidance (High Level)

### Embedded C/C++ / Firmware

- Follow the project’s chosen standard (often C++23). Use RAII, and keep allocation and blocking operations out of hot paths/ISRs unless the project explicitly permits it.
- Look for clang dotfiles (`.clang-tidy`, `.clang-format`, `.clangd`) and follow their guidelines.
- Be careful with interrupt context, DMA/volatile semantics, timing, and numerical stability.
- Prefer conservative safety limits; document and justify any changes to limits, calibration, or protection behaviour.
- STM32 projects should always use CubeMX generation.

### Go

- If a Makefile doesn't exist, format with `gofmt`/`go fmt`. Validate with `go test ./...` and `go vet ./...` (or project Makefile targets).
- Use `context.Context` for cancellation and timeouts. Avoid global mutable state unless unavoidable and well-encapsulated.

### Python

- Use virtual environments where appropriate (`python3 -m venv venv`).
- Prefer type hints for non-trivial logic and run the project’s formatter/linter/test suite if configured.

### Services / System Integration

- Keep services least-privilege. Document install/enable steps (e.g., systemd), required env vars, and logging/metrics configuration.
- Avoid hard-coded absolute paths; use config files and standard locations.

## Project-Level `AGENTS.md` Template

The canonical project template is:

- `templates/project-agents.md` inside this repository.
- Installed path: `~/.config/agent-config/templates/project-agents.md`.

When initialising a project, keep project-specific details in the project's own
`AGENTS.md` and avoid duplicating global policy text unless it is needed for local
clarity.
