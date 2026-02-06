---
name: init
description: "Initialise or align repository-level agent setup in one run. Creates or updates AGENTS.md from templates and, when available, bootstraps project-level CLAUDE.md and handoff ignore rules. Use when starting work in a new or uninitialised repository."
---

# Init Skill

## Workflow

1. Locate the repository root (`pwd`, `ls`, `git rev-parse --show-toplevel` if needed).
2. Read existing project files when present: `AGENTS.md`, `CLAUDE.md`, `.gitignore`.
3. Resolve templates in this order:
   - Preferred: `~/.config/agent-config/templates/project-agents.md`
   - Fallback: project-level template section in `~/AGENTS.md`
   - Optional CC template: `~/.config/agent-config/templates/project-claude.md`
4. Gather repository facts before writing:
   - Top-level directories and key files.
   - Languages and size (`tokei` if available).
   - Submodules (`git submodule status` or `.gitmodules`).
   - Build/test entry points (`Makefile`, `CMakeLists.txt`, `package.json`,
     `pyproject.toml`, CI config).
5. Build or update project `AGENTS.md`:
   - New project: generate a complete project `AGENTS.md` from the template.
   - Existing project: preserve accurate guidance, map content into template
     sections, and only remove obsolete material.
6. Apply setup automatically:
   - Write/update project `AGENTS.md`.
   - If `CLAUDE.md` does not exist and CC template is available, create it.
   - Ensure `.gitignore` contains `TASK.md`, `REVIEW.md`, and `HANDOFF.md`.
7. Validate:
   - Confirm files exist after writing.
   - List unresolved placeholders (`<...>`) explicitly.

## Output Rules

- Default to editing files directly unless user requests dry-run behaviour.
- Use British English and concise wording.
- Do not invent build/flash/test commands that cannot be confirmed from project files.
