# Changelog

All notable changes to agent configuration are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [06/02/2026] - Initial Release and Alignment Update

### Added
- Global `AGENTS.md` baseline (including feedback, skills, and handoff guidance)
- Claude slash commands: `/aq-help`, `/aq-init`, `/plan`, `/handoff`, `/review`,
  `/feedback`, `/bump-defs`, `/cubemx-verify`
- Codex config with skills enabled
- Shared skills: `aq-help`, `init`, `task-spec`, `handoff`, `diff-review`,
  `commit-msg`, `submodule-bump`, `cubemx-verify`
- Templates: `TASK.md`, `REVIEW.md`, `project-agents.md`, `project-claude.md`
- Scripts: `handoff.sh`, `sync-projects.sh`, `validate.sh`
- Nix Home Manager module and flake export (`flake.nix`)
- Repository housekeeping: `.gitignore`, `LICENSE`, CI validation workflow
- `SUGGESTIONS.md` feedback loop
- Shared command reference at `HELP.md`

### Changed
- `nix/module.nix` is now a consumable module via `programs.aqAgentConfig.*` options
- Shared asset deployment is scoped to `templates/`, `scripts/`, and `HELP.md`
- Canonical project template source is `templates/project-agents.md` (to avoid drift)
- Nix install now copies command/skill files into `~/.claude` and `~/.codex` so
  tool discovery does not depend on symlink indexing
