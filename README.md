# aq-agent-config

Central configuration for AI coding agents (Claude Code and Codex) used across
Aquila projects.

## Purpose

This repository provides:

- Global baseline instructions (`AGENTS.md`).
- Tool-specific global additions (`home/claude/`, `home/codex/`).
- Shared cross-agent skills (`skills/`).
- Project and handoff templates (`templates/`).
- Utility scripts (`scripts/`).
- A consumable Home Manager module (`nix/module.nix`).
- A command and skill reference (`HELP.md`).

## Example Dialogue (Firmware, Two Terminals)

Use two terminals in the same project repository:

- Terminal A: Claude Code (planning/review)
- Terminal B: Codex (execution)

Terminal A (Claude), user: `/aq-init`

Claude (setup): "Project initialised. Updated `AGENTS.md`, created `CLAUDE.md`
if missing, and ensured `.gitignore` ignores `TASK.md` and `REVIEW.md`."

Terminal A (Claude), user:
`/plan Add a CAN fault message when battery voltage drops below threshold.`

Claude (planning): "Created `TASK.md` with acceptance criteria:
- Publish CAN fault frame when `battery_voltage_mv < undervoltage_threshold_mv`
- Clear fault when voltage recovers above hysteresis threshold
- Add tests for set/clear behaviour and no-flap behaviour"

Terminal B (Codex), user: "Execute `TASK.md`."

Codex (execution): "Implemented undervoltage detection path, added CAN fault
publish/clear logic, and added tests. Verification run:
- `make build` pass
- `make test` pass"

Terminal B (Codex), user: "Prepare handoff for review."

Codex: "Used `handoff` skill and wrote project-local `HANDOFF.md`."

Terminal A (Claude), user: `/review`

Claude (review): "Verdict: PASS WITH COMMENTS.
Feedback:
1. Add boundary test for exactly equal to threshold.
2. Add test for recovery hysteresis to avoid chatter near threshold."

Terminal B (Codex), user: "Apply reviewer feedback."

Codex: "Added boundary and hysteresis tests, re-ran `make test` (pass)."

Terminal A (Claude), user: `/feedback`

Claude (final feedback review): "Verdict: PASS. All `TASK.md` criteria and review
feedback addressed."

## Installation

### Quick Dependencies

The workflows in this repository assume these tools are available:

- Required: `bash`, `git`, `rg` (ripgrep)
- Optional but recommended: `tokei` (used by some skills for quick language sizing)

Quick install examples:

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y bash git ripgrep tokei

# macOS (Homebrew)
brew install git ripgrep tokei

# Nix
nix profile install nixpkgs#bash nixpkgs#git nixpkgs#ripgrep nixpkgs#tokei
```

### Option A: Nix (Home Manager)

#### 1) Add as a flake input

```nix
{
  inputs = {
    aq-agent-config.url = "github:your-org/aq-agent-config";
  };
}
```

#### 2) Import the module in Home Manager

```nix
{
  imports = [
    inputs.aq-agent-config.homeManagerModules.default
  ];

  programs.aqAgentConfig = {
    enable = true;
    source = inputs.aq-agent-config.outPath;
  };
}
```

#### 3) Apply

```bash
home-manager switch
# or
nixos-rebuild switch
```

### Option B: Manual (without Nix)

Clone the repository and run the install script:

```bash
git clone https://github.com/your-org/aq-agent-config.git
cd aq-agent-config
bash scripts/install.sh
```

Or perform the steps manually:

```bash
REPO="path/to/aq-agent-config"

# Claude Code: global instructions (concatenate base + CC additions)
mkdir -p ~/.claude
{ cat "$REPO/AGENTS.md"; echo; cat "$REPO/home/claude/CLAUDE.md"; } > ~/.claude/CLAUDE.md

# Claude Code: settings and commands
cp "$REPO/home/claude/settings.json" ~/.claude/settings.json
cp -r "$REPO/home/claude/commands" ~/.claude/commands

# Claude Code: skills
cp -r "$REPO/skills" ~/.claude/skills

# Codex: global instructions (concatenate base + Codex additions)
mkdir -p ~/.codex
{ cat "$REPO/AGENTS.md"; echo; cat "$REPO/home/codex/AGENTS.md"; } > ~/.codex/AGENTS.md

# Codex: settings and skills
cp "$REPO/home/codex/config.toml" ~/.codex/config.toml
cp -r "$REPO/skills" ~/.codex/skills

# Shared assets (templates, scripts, help)
mkdir -p ~/.config/agent-config
cp -r "$REPO/templates" ~/.config/agent-config/templates
cp -r "$REPO/scripts" ~/.config/agent-config/scripts
cp "$REPO/HELP.md" ~/.config/agent-config/HELP.md

# Helper scripts on PATH (pick a directory already on your PATH)
cp "$REPO/scripts/handoff.sh" ~/.local/bin/agent-handoff
cp "$REPO/scripts/sync-projects.sh" ~/.local/bin/agent-sync-projects
chmod +x ~/.local/bin/agent-handoff ~/.local/bin/agent-sync-projects
```

To update after pulling new changes, re-run the install script or repeat
these steps. Unlike the Nix path, manual installs are not automatically kept
in sync with the repository.

## What Gets Installed

| Content | Claude Code path | Codex path |
|---------|------------------|------------|
| Global instructions | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` |
| Global settings | `~/.claude/settings.json` | `~/.codex/config.toml` |
| Commands | `~/.claude/commands/` | N/A |
| Skills | `~/.claude/skills/` | `~/.codex/skills/` |
| Shared templates | `~/.config/agent-config/templates/` | `~/.config/agent-config/templates/` |
| Shared scripts | `~/.config/agent-config/scripts/` | `~/.config/agent-config/scripts/` |
| Shared help | `~/.config/agent-config/HELP.md` | `~/.config/agent-config/HELP.md` |

Global instruction files are generated by concatenating:

1. repository `AGENTS.md`
2. tool-specific additions (`home/claude/CLAUDE.md` or `home/codex/AGENTS.md`)

## Workflow

### 1) Initialise a project

- In Claude: run `/aq-init` from project root.
- In Codex: invoke the `init` skill.

This initialises or aligns:

- project `AGENTS.md`
- project `CLAUDE.md` where appropriate
- `.gitignore` entries for `TASK.md` and `REVIEW.md`

### 2) Plan -> Execute -> Review

1. Create project-local `TASK.md` (for example via `/plan`).
2. Implement against `TASK.md`.
3. Prepare review context:
   Preferred: use `handoff` skill in Codex (or `/handoff` in Claude) to generate
   handoff content from current git state. Default scope is pre-commit changes
   since `HEAD`, plus current-branch commit history.
   If `TASK.md` is missing, handoff should infer task context and continue.
   Script fallback (requires an existing `TASK.md`):
   ```bash
   agent-handoff TASK.md main HEAD
   ```
4. Review against `TASK.md` and write project-local `REVIEW.md`.
   Use `/review` or `/aq-review` in Claude. For follow-up checks after comments,
   use `/feedback`.

`TASK.md`, `REVIEW.md`, and optional `HANDOFF.md` are project-level temporary
artefacts and should not be committed.

### 3) Verify fleet state

```bash
agent-sync-projects /path/to/projects
```

## Claude Commands

- `/aq-help` - Print the Claude command help section
- `/aq-init` - Initialise or align project agent setup
- `/plan` - Generate a structured task specification (`TASK.md`)
- `/handoff` - Prepare handoff context from git state (pre-commit friendly)
- `/review` - First-pass review of a diff against `TASK.md`
- `/aq-review` - Review alias with task-context fallback
- `/feedback` - Follow-up review against existing `REVIEW.md` feedback
- `/bump-defs` - Bump `aq-standard-definitions` and regenerate
- `/cubemx-verify` - Check CubeMX regeneration integrity

## Command Help

For a full command and skill reference for Claude Code and Codex, see
`HELP.md`.

## Shared Skills

- `aq-help`
- `init`
- `task-spec`
- `handoff`
- `diff-review`
- `commit-msg`
- `submodule-bump`
- `cubemx-verify`

## Repository Layout

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Canonical global instructions |
| `home/` | Tool-specific settings and command additions |
| `skills/` | Shared skills loaded by Claude and Codex |
| `templates/` | Canonical templates for project/task/review artefacts |
| `scripts/` | Handoff and project-sync helpers |
| `nix/module.nix` | Home Manager module |
| `flake.nix` | Flake output exporting the Home Manager module |
| `IMPLEMENT.md` | Historical implementation plan and design notes |
| `CHANGELOG.md` | Configuration change history |
| `SUGGESTIONS.md` | Agent feedback backlog |

## Validation

Local validation:

```bash
bash scripts/validate.sh
```

CI runs `.github/workflows/validate.yml` on push and pull requests.

## Updating

### Nix

1. Update this repository.
2. Update flake lock in consuming systems:
   ```bash
   nix flake update aq-agent-config
   ```
3. Rebuild (`home-manager switch` or `nixos-rebuild switch`).

### Manual

1. Pull latest changes:
   ```bash
   cd path/to/aq-agent-config && git pull
   ```
2. Re-run `bash scripts/install.sh` (or repeat the manual steps).

After either method, re-run project initialisation (`/aq-init` in Claude or
`init` skill in Codex) where needed.

## Troubleshooting

- Codex skills not loading:
  confirm `~/.codex/config.toml` has:
  ```toml
  [features]
  skills = true
  ```
- Codex custom skills missing from `$` list:
  re-run `home-manager switch` (or `bash scripts/install.sh`) and restart Codex.
- Claude skills not loading:
  confirm `~/.claude/settings.json` includes `"Skill"` in `allowedTools`.
- Claude commands missing:
  re-run `home-manager switch` (or `bash scripts/install.sh`) and restart Claude.

## Contributing

1. Create a branch.
2. Make focused changes.
3. Update `CHANGELOG.md` for notable behaviour changes.
4. Run `bash scripts/validate.sh`.
5. Open a PR.
