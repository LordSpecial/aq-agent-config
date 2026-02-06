# Changelog

All notable changes to agent configuration are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [06/02/2026] - Initial Release and Alignment Update

### Added
- Global `AGENTS.md` baseline (including feedback, skills, and handoff guidance)
- Claude slash commands: `/aq-init`, `/plan`, `/review`, `/bump-defs`, `/cubemx-verify`
- Codex config with skills enabled
- Shared skills: `init`, `task-spec`, `diff-review`, `commit-msg`,
  `submodule-bump`, `cubemx-verify`
- Templates: `TASK.md`, `REVIEW.md`, `project-agents.md`, `project-claude.md`
- Scripts: `handoff.sh`, `sync-projects.sh`, `validate.sh`
- Nix Home Manager module and flake export (`flake.nix`)
- Repository housekeeping: `.gitignore`, `LICENSE`, CI validation workflow
- `SUGGESTIONS.md` feedback loop

### Changed
- `nix/module.nix` is now a consumable module via `programs.aqAgentConfig.*` options
- Shared asset deployment is scoped to `templates/` and `scripts/` only
- Canonical project template source is `templates/project-agents.md` (to avoid drift)
