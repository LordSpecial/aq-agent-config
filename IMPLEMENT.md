# Implementation Plan: Agentic Workflow Improvements (Nix-Global)

> **Purpose:** Step-by-step instructions for an AI coding agent to implement the changes
> described in the Agentic Coding Workflow Review report.
>
> **Date:** 06/02/2026
>
> **Key design decision:** All agent configuration is managed globally via Nix, not
> per-project. Projects only contain their own `AGENTS.md` / `CLAUDE.md` with
> project-specific overrides.

---

## Background: How CC and Codex Discover Instructions

### Claude Code

| Type | Path | Notes |
|------|------|-------|
| Global instructions | `~/.claude/CLAUDE.md` | Always loaded |
| Global settings | `~/.claude/settings.json` | Permissions, hooks, overrides |
| Global state | `~/.claude.json` | Themes, OAuth |
| Global skills | `~/.claude/skills/*/SKILL.md` | Auto-discovered at startup |
| Project instructions | `CLAUDE.md` | In repo root (or any parent dir) |
| Project local | `CLAUDE.local.md` | Gitignored, per-developer overrides |
| Project settings | `.claude/settings.json` | Checked into git |
| Project skills | `.claude/skills/*/SKILL.md` | Auto-discovered, incl. monorepo nesting |

Discovery: CC checks current directory, traverses up to root or home. In monorepos,
both `root/CLAUDE.md` and `root/package/CLAUDE.md` are loaded. Skills require `"Skill"`
in `allowedTools` / `allowed_tools` configuration to activate.

Skills use progressive disclosure: only `name` and `description` from frontmatter are
loaded at startup. The full SKILL.md body is read into context only when CC deems the
skill relevant to the current task.

### Codex (OpenAI)

| Type | Path | Notes |
|------|------|-------|
| Global instructions | `~/.codex/AGENTS.md` | Always loaded |
| Global override | `~/.codex/AGENTS.override.md` | Takes precedence over AGENTS.md |
| Global settings | `~/.codex/config.toml` | `approval_policy`, `model_instructions_file`, etc. |
| Global skills | `~/.codex/skills/*/SKILL.md` | Requires `features.skills = true` in config.toml |
| Project instructions | `AGENTS.md` | Walks up from cwd to project root |
| Project override | `AGENTS.override.md` | Takes precedence over AGENTS.md |
| Project settings | `.codex/config.toml` | Only loaded if project is "trusted" |
| Project skills | `./skills/*/SKILL.md` | Or `.codex/skills/` — project-scoped |

Discovery: Codex walks up from the working directory to the project root, then checks
the global home directory. Files are merged root-down, concatenated with blank lines.
Combined size limit is 32 KiB by default — plan for this.

Both tools support the same Agent Skills standard: a directory containing a mandatory
`SKILL.md` with YAML frontmatter (`name`, `description`), plus optional `scripts/`,
`references/`, and `assets/` subdirectories.

### Implication for Nix

Nix needs to place files at:

| Content | CC destination | Codex destination |
|---------|---------------|-------------------|
| Global instructions | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` |
| Global skills | `~/.claude/skills/` | `~/.codex/skills/` |
| Global settings | `~/.claude/settings.json` | `~/.codex/config.toml` |
| CC slash commands | `~/.claude/commands/` | N/A |
| Shared assets | `~/.config/agent-config/` | `~/.config/agent-config/` |

The canonical source is one `AGENTS.md` in the repo. Nix builds tool-specific wrappers
from it (appending CC- or Codex-specific sections). Skills are identical for both tools
since they share the same standard — Nix symlinks them into both discovery paths.

---

## Phase 1: Create the `aq-agent-config` Repository

### 1.1 Repository Structure

```
aq-agent-config/
├── AGENTS.md                        # Canonical global agent instructions
├── CHANGELOG.md
├── README.md
├── SUGGESTIONS.md                   # Agent feedback loop
│
├── home/                            # Files Nix will place in $HOME
│   ├── claude/
│   │   ├── CLAUDE.md                # CC-specific additions (appended after AGENTS.md)
│   │   ├── settings.json            # CC global settings (allowedTools incl. "Skill")
│   │   └── commands/                # CC custom slash commands
│   │       ├── plan.md              # /plan — generate a TASK.md
│   │       ├── review.md            # /review — review a diff against a TASK.md
│   │       ├── bump-defs.md         # /bump-defs — aq-standard-definitions bump
│   │       └── cubemx-verify.md     # /cubemx-verify — post-regen check
│   └── codex/
│       ├── AGENTS.md                # Codex-specific additions (appended after AGENTS.md)
│       └── config.toml              # Codex global settings (features.skills = true)
│
├── skills/                          # Shared skills (symlinked into both tool paths)
│   ├── task-spec/
│   │   └── SKILL.md
│   ├── diff-review/
│   │   └── SKILL.md
│   ├── commit-msg/
│   │   └── SKILL.md
│   ├── submodule-bump/
│   │   └── SKILL.md
│   └── cubemx-verify/
│       └── SKILL.md
│
├── templates/
│   ├── project-agents.md            # Project-level AGENTS.md template
│   ├── project-claude.md            # Project-level CLAUDE.md template
│   ├── TASK.md
│   └── REVIEW.md
│
├── scripts/
│   ├── handoff.sh                   # CC → Codex → CC review wrapper
│   └── sync-projects.sh             # Validate all projects have correct config
│
└── nix/
    └── module.nix                   # Nix home-manager module
```

### 1.2 Key Design Principles

**Single source of truth.** `AGENTS.md` at the repo root is the canonical global
instructions file. Tool-specific files in `home/claude/` and `home/codex/` contain
only additions specific to that tool — they are appended by Nix during the build.

**Shared skill standard.** The `skills/` directory contains skills compatible with both
CC and Codex. Nix symlinks them into `~/.claude/skills/` and `~/.codex/skills/`
simultaneously. No duplication.

**Size awareness.** Codex has a 32 KiB combined instruction limit. Keep `AGENTS.md` +
Codex-specific additions well under this. CC does not have the same limit, but concise
instructions are better for context efficiency regardless.

---

## Phase 2: Global Instructions Files

### 2.1 Update `AGENTS.md`

Copy the existing global `AGENTS.md` into the repo root. Apply these changes:

#### Fix 1: Complete the truncated sentence

Find:

```
When given feed
```

Replace with:

```
When given feedback on a previous response, incorporate it and offer to update the
closest project-level instructions file if the feedback reflects a recurring preference
or correction.
```

#### Fix 2: Add Context Loading to the project-level template

Inside the `## Project-Level AGENTS.md Template`, after `## 1) Context`, add:

```markdown
## 1.5) Context Loading (Files to read on init)
List every file the agent must read before starting work. Be explicit.
- `AGENTS.md` / `CLAUDE.md` (this project's instructions)
- `README.md`
- `<path to .ioc file>` (CubeMX source of truth)
- `<path to protocol definitions / DBC / schema files>`
- `<path to Makefile or primary build entry point>`
- `<path to CI config>`
- `<any other critical context files>`
```

#### Fix 3: Add Skills section

After `## Builds, Tests, and Timeouts`, add:

```markdown
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

In Claude Code, skills also surface as slash commands (e.g., `/plan`, `/review`,
`/bump-defs`, `/cubemx-verify`).
```

#### Fix 4: Add Handoff Workflow section

After the new Skills section, add:

```markdown
## Agent Handoff

When a task involves multiple agents (e.g., CC for planning, Codex for execution):

1. The planning agent writes a `TASK.md` following the template in
   `~/.config/agent-config/templates/TASK.md`.
2. The executing agent reads `TASK.md` as its primary work order.
3. After execution, a review agent evaluates the diff against the original `TASK.md`
   and writes a `REVIEW.md`.
4. `TASK.md` and `REVIEW.md` are temporary artefacts; do not commit them to the
   project repository.
```

### 2.2 `home/claude/CLAUDE.md`

CC-specific additions. Nix will concatenate `AGENTS.md` + this file into
`~/.claude/CLAUDE.md`.

```markdown
## Claude Code Specific

### Custom Commands

The following slash commands are available globally:

- `/plan` — Generate a structured TASK.md for agent handoff
- `/review` — Review a git diff against a TASK.md specification
- `/bump-defs` — Bump aq-standard-definitions and regenerate
- `/cubemx-verify` — Verify CubeMX regeneration output

### Templates

Handoff templates are at `~/.config/agent-config/templates/`.
```

### 2.3 `home/claude/settings.json`

Ensure skills are enabled and any default permissions are set:

```json
{
  "permissions": {
    "allowedTools": ["Skill"]
  }
}
```

Adapt this to your existing CC settings — the critical part is that `"Skill"` is in
`allowedTools` so that skills in `~/.claude/skills/` are activated.

### 2.4 `home/codex/AGENTS.md`

Codex-specific additions. Nix will concatenate `AGENTS.md` + this file into
`~/.codex/AGENTS.md`.

```markdown
## Codex Specific

### Skills

Global skills are auto-discovered from `~/.codex/skills/`. When a task matches a
skill trigger, the full SKILL.md will be loaded.

Available skills: task-spec, diff-review, commit-msg, submodule-bump, cubemx-verify.

### Templates

Handoff templates are at `~/.config/agent-config/templates/`.
```

### 2.5 `home/codex/config.toml`

Enable skills and set any defaults:

```toml
[features]
skills = true
```

Merge with your existing Codex config as needed.

---

## Phase 3: CC Custom Commands (Slash Commands)

CC slash commands are markdown files in `~/.claude/commands/`. They appear in the
command palette and can be invoked with `/command-name`.

These provide a convenience layer on top of skills — the slash command tells CC which
skill to read and provides the invocation context. Both CC and Codex can use the
underlying skills directly; the slash commands are CC-only sugar.

### 3.1 `home/claude/commands/plan.md`

```markdown
# Generate Task Specification

Read the skill at `~/.claude/skills/task-spec/SKILL.md` and follow its instructions.

Read the TASK.md template at `~/.config/agent-config/templates/TASK.md`.

Generate a TASK.md for the following request:

$ARGUMENTS
```

### 3.2 `home/claude/commands/review.md`

```markdown
# Review Changes Against Task Specification

Read the skill at `~/.claude/skills/diff-review/SKILL.md` and follow its instructions.

Read the REVIEW.md template at `~/.config/agent-config/templates/REVIEW.md`.

Review the current branch's diff against the TASK.md in the working directory. If no
TASK.md exists, ask the user for the task context.

$ARGUMENTS
```

### 3.3 `home/claude/commands/bump-defs.md`

```markdown
# Bump aq-standard-definitions

Read the skill at `~/.claude/skills/submodule-bump/SKILL.md` and follow its
instructions.

Bump the `aq-standard-definitions` submodule in this project to the latest revision
on main, regenerate, verify the build, and commit.

$ARGUMENTS
```

### 3.4 `home/claude/commands/cubemx-verify.md`

```markdown
# Verify CubeMX Regeneration

Read the skill at `~/.claude/skills/cubemx-verify/SKILL.md` and follow its
instructions.

Verify the CubeMX regeneration output in this project. Check for USER CODE block
integrity and unexpected file changes.

$ARGUMENTS
```

---

## Phase 4: Skill Definitions

All skills live in `skills/` at the repo root. Nix symlinks them into both
`~/.claude/skills/` and `~/.codex/skills/` so they are auto-discovered by both tools.

### 4.1 `skills/task-spec/SKILL.md`

```markdown
---
name: task-spec
description: "Generate a structured task specification (TASK.md) for agent handoff.
  Use when acting as the planning agent and need to produce a work order for an
  executing agent. Triggers: /plan command, explicit request to plan a task, or when
  preparing work for another agent."
---

# Task Specification Skill

## Instructions

1. Read the user's request. Clarify ambiguities before proceeding.
2. Identify the target repository and read its project instructions (`AGENTS.md`,
   `CLAUDE.md`, `README.md`) and build entry points.
3. Determine the minimal set of files that need to change.
4. Write a `TASK.md` following `~/.config/agent-config/templates/TASK.md`.
5. For each acceptance criterion, ensure there is a corresponding verification command.
6. List all context files the executing agent will need to read.
7. Define a rollback strategy (usually `git checkout` of affected files).
8. Present the `TASK.md` to the user for review before handoff.

## Quality Checks

- Every file listed under "Files" has a clear action (Read/Modify/Create).
- Acceptance criteria are testable, not subjective.
- Verification commands are copy-pasteable with no placeholders.
- Constraints explicitly state what must not change.
```

### 4.2 `skills/diff-review/SKILL.md`

```markdown
---
name: diff-review
description: "Review a git diff against a TASK.md specification and produce a
  structured REVIEW.md. Use when acting as the review agent after an executing agent
  has completed work. Triggers: /review command, explicit request to review changes,
  or when evaluating another agent's output."
---

# Diff Review Skill

## Inputs

- The original `TASK.md`
- The git diff (provided via `agent-handoff` script or `git diff` directly)

## Instructions

1. Read the `TASK.md` acceptance criteria and constraints.
2. Review the diff file-by-file:
   a. Does each change serve the stated objective?
   b. Are there changes to files not listed in the task spec? Flag them.
   c. Do the changes violate any constraints?
   d. Do the changes follow the project's conventions?
3. Run or verify that verification commands were executed and passed.
4. Write a `REVIEW.md` following `~/.config/agent-config/templates/REVIEW.md`.
5. Verdict:
   - **PASS**: All acceptance criteria met, no issues.
   - **PASS WITH COMMENTS**: Criteria met, minor improvements suggested.
   - **FAIL**: Acceptance criteria not met, or constraint violations found.

## Quality Checks

- Every acceptance criterion has an explicit pass/fail assessment.
- Issues include a suggested fix, not just a description.
- Verification results include actual command output.
```

### 4.3 `skills/commit-msg/SKILL.md`

```markdown
---
name: commit-msg
description: "Generate a well-formed commit message following project conventions.
  Use when committing changes. Triggers: explicit request to write a commit message,
  or as the final step after implementing changes."
---

# Commit Message Skill

## Instructions

1. Check the project's existing commit history (`git log --oneline -20`) for
   convention (Conventional Commits, imperative mood, prefixes, etc.).
2. Write the commit message following the observed convention.
3. Rules from global instructions:
   - Imperative mood.
   - Atomic and scoped.
   - Explain *why* as well as *what*.
   - A oneline is fine for simple/obvious changes.
   - Reference issue/ticket numbers when applicable.
4. For Conventional Commits, common prefixes: `feat:`, `fix:`, `refactor:`,
   `docs:`, `chore:`, `deps:`, `test:`, `ci:`.
```

### 4.4 `skills/submodule-bump/SKILL.md`

```markdown
---
name: submodule-bump
description: "Bump aq-standard-definitions submodule and regenerate code. Use when
  protocol definitions or schemas have changed upstream. Triggers: /bump-defs command,
  or when a task requires updated definitions."
---

# Submodule Bump Skill (aq-standard-definitions)

## Instructions

1. Confirm the project uses `aq-standard-definitions` as a submodule.
2. Fetch and checkout the target revision:
   ```bash
   cd <submodule-path>
   git fetch origin
   git checkout <target-ref>  # usually origin/main or a specific tag
   cd ..
   ```
3. Run the project's regeneration targets:
   ```bash
   make deps
   make generate
   ```
4. Verify the build:
   ```bash
   make build
   ```
5. Review the diff — generated files should only show changes consistent with
   the schema update. Flag anything unexpected.
6. Commit:
   ```
   deps: bump aq-standard-definitions to <short-sha>

   <one-line summary of what changed in the definitions>
   ```

## Never

- Hand-edit generated files.
- Bump without rebuilding and verifying.
```

### 4.5 `skills/cubemx-verify/SKILL.md`

```markdown
---
name: cubemx-verify
description: "Verify CubeMX regeneration output for integrity. Use after the user
  has regenerated from a .ioc file. Triggers: /cubemx-verify command, or after any
  CubeMX regeneration."
---

# CubeMX Post-Regeneration Verification Skill

## Instructions

1. Run `git diff` on the CubeMX generated directory (typically `Core/` or the path
   in the project instructions).
2. For each changed file, verify:
   a. Changes are within CubeMX-managed sections (outside USER CODE blocks).
   b. No USER CODE blocks have been deleted or corrupted.
   c. No unexpected files added or removed.
3. Check the build:
   ```bash
   make build
   ```
4. If `hal.c` exists (see global instructions CubeMX Rules), verify generated
   `main.c` references are correctly redirected.
5. Report findings. If any USER CODE blocks were affected, flag immediately.

## Never

- Modify CubeMX generated files.
- Approve a regen that deletes USER CODE content without explicit user confirmation.
```

---

## Phase 5: Templates and Scripts

### 5.1 `templates/TASK.md`

```markdown
# Task Specification

## Objective
<!-- One sentence: what needs to change and why -->

## Branch
<!-- Branch name, e.g. feat/update-canfd-handler -->

## Files
| Action | Path | Notes |
|--------|------|-------|
| Read   |      |       |
| Modify |      |       |
| Create |      |       |

## Acceptance Criteria
- [ ] ...

## Verification Commands
```bash
# Build
<command>

# Test
<command>

# Lint
<command>
```

## Constraints
-

## Rollback
```bash
git checkout main -- <files>
```

## Context Files
<!-- Files the executing agent must read before starting -->
-
```

### 5.2 `templates/REVIEW.md`

```markdown
# Review

## Task Reference
<!-- Original TASK.md objective -->

## Verdict
<!-- PASS / FAIL / PASS WITH COMMENTS -->

## Summary
<!-- 2–3 sentences -->

## Files Changed
| File | Change Type | Assessment |
|------|-------------|------------|
|      |             | OK / Issue |

## Issues Found
| Severity | File | Description | Suggested Fix |
|----------|------|-------------|---------------|
|          |      |             |               |

## Verification Results
```bash
# Build output

# Test output
```

## Follow-Ups
-
```

### 5.3 `templates/project-agents.md`

Copy the project-level template from the updated global `AGENTS.md` (including the
Context Loading section). This is the canonical starting point for new projects.

Both CC and Codex will discover this file. CC additionally looks for `CLAUDE.md`, so
projects may optionally have both — `AGENTS.md` for shared instructions (read by both
tools) and `CLAUDE.md` for CC-specific overrides.

### 5.4 `templates/project-claude.md`

Template for project-level `CLAUDE.md`:

```markdown
# <Project Name> — Claude Code Instructions

> Project-specific CC instructions. Global instructions are loaded from
> `~/.claude/CLAUDE.md` automatically. Shared project instructions are in `AGENTS.md`.

## Context Loading

Read these files before starting any work:
- `AGENTS.md` (shared project instructions)
- `README.md`
- <add project-specific files>

## Project Skills

Project-level skills can be added to `.claude/skills/` and will be auto-discovered.
```

### 5.5 `scripts/handoff.sh`

```bash
#!/usr/bin/env bash
# handoff.sh — Capture execution results for review agent
# Usage: handoff.sh <task-file> <base-branch> [working-branch]

set -euo pipefail

TASK_FILE="${1:?Usage: handoff.sh <task-file> <base-branch> [working-branch]}"
BASE_BRANCH="${2:?Usage: handoff.sh <task-file> <base-branch> [working-branch]}"
WORKING_BRANCH="${3:-HEAD}"

if [ ! -f "$TASK_FILE" ]; then
    echo "Error: Task file '$TASK_FILE' not found." >&2
    exit 1
fi

DIFF=$(git diff "$BASE_BRANCH".."$WORKING_BRANCH")
STAT=$(git diff --stat "$BASE_BRANCH".."$WORKING_BRANCH")
LOG=$(git log --oneline "$BASE_BRANCH".."$WORKING_BRANCH")

cat <<EOF
# Handoff: Review Request

## Original Task
$(cat "$TASK_FILE")

## Commits
\`\`\`
${LOG}
\`\`\`

## Diff Summary
\`\`\`
${STAT}
\`\`\`

## Full Diff
\`\`\`diff
${DIFF}
\`\`\`
EOF
```

### 5.6 `scripts/sync-projects.sh`

```bash
#!/usr/bin/env bash
# sync-projects.sh — Verify all aq-* projects have correct agent config
# Usage: sync-projects.sh <projects-root-dir>

set -euo pipefail

PROJECTS_ROOT="${1:?Usage: sync-projects.sh <projects-root-dir>}"
ERRORS=0

for project_dir in "$PROJECTS_ROOT"/aq-*; do
    [ -d "$project_dir/.git" ] || continue
    name=$(basename "$project_dir")

    if [ ! -f "$project_dir/AGENTS.md" ]; then
        echo "MISSING: $name/AGENTS.md"
        ERRORS=$((ERRORS + 1))
    else
        echo "OK:      $name/AGENTS.md"
    fi
done

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "$ERRORS project(s) missing AGENTS.md. Use templates/project-agents.md."
    exit 1
else
    echo ""
    echo "All projects OK."
fi
```

---

## Phase 6: Nix Integration

### 6.1 `nix/module.nix`

Home-manager module. Adapt to your existing Nix structure.

```nix
{ config, lib, pkgs, ... }:

let
  # Point at the aq-agent-config repo — flake input, local path, or fetchGit.
  agentConfig = ...; # e.g., inputs.aq-agent-config
in
{
  # ── Claude Code ──────────────────────────────────────────────

  # Global instructions: AGENTS.md + CC-specific additions
  home.file.".claude/CLAUDE.md".text = builtins.concatStringsSep "\n" [
    "<!-- Managed by Nix from aq-agent-config. Do not edit. -->"
    (builtins.readFile "${agentConfig}/AGENTS.md")
    ""
    (builtins.readFile "${agentConfig}/home/claude/CLAUDE.md")
  ];

  # Settings (ensure Skill is in allowedTools)
  home.file.".claude/settings.json".source =
    "${agentConfig}/home/claude/settings.json";

  # Slash commands
  home.file.".claude/commands" = {
    source = "${agentConfig}/home/claude/commands";
    recursive = true;
  };

  # Skills — symlinked into CC's discovery path
  home.file.".claude/skills" = {
    source = "${agentConfig}/skills";
    recursive = true;
  };

  # ── Codex ────────────────────────────────────────────────────

  # Global instructions: AGENTS.md + Codex-specific additions
  home.file.".codex/AGENTS.md".text = builtins.concatStringsSep "\n" [
    "<!-- Managed by Nix from aq-agent-config. Do not edit. -->"
    (builtins.readFile "${agentConfig}/AGENTS.md")
    ""
    (builtins.readFile "${agentConfig}/home/codex/AGENTS.md")
  ];

  # Settings (enable skills feature)
  home.file.".codex/config.toml".source =
    "${agentConfig}/home/codex/config.toml";

  # Skills — symlinked into Codex's discovery path
  home.file.".codex/skills" = {
    source = "${agentConfig}/skills";
    recursive = true;
  };

  # ── Shared assets (templates, full repo for reference) ──────
  home.file.".config/agent-config" = {
    source = "${agentConfig}";
    recursive = true;
  };

  # ── Scripts on PATH ─────────────────────────────────────────
  home.packages = [
    (pkgs.writeShellScriptBin "agent-handoff"
      (builtins.readFile "${agentConfig}/scripts/handoff.sh"))
    (pkgs.writeShellScriptBin "agent-sync-projects"
      (builtins.readFile "${agentConfig}/scripts/sync-projects.sh"))
  ];
}
```

### 6.2 Flake Input

```nix
{
  inputs = {
    # ... existing inputs ...
    aq-agent-config = {
      url = "github:your-org/aq-agent-config";
      flake = false;  # Just a source tree
    };
  };

  outputs = { self, nixpkgs, home-manager, aq-agent-config, ... }: {
    # Pass aq-agent-config through to the home-manager module
    # via specialArgs or extraSpecialArgs
  };
}
```

### 6.3 What Nix Produces

After `nixos-rebuild switch` or `home-manager switch`:

```
~/.claude/
├── CLAUDE.md              # AGENTS.md + CC additions (concatenated)
├── settings.json          # Permissions incl. Skill in allowedTools
├── commands/
│   ├── plan.md
│   ├── review.md
│   ├── bump-defs.md
│   └── cubemx-verify.md
└── skills/                # Symlinked from aq-agent-config/skills/
    ├── task-spec/SKILL.md
    ├── diff-review/SKILL.md
    ├── commit-msg/SKILL.md
    ├── submodule-bump/SKILL.md
    └── cubemx-verify/SKILL.md

~/.codex/
├── AGENTS.md              # AGENTS.md + Codex additions (concatenated)
├── config.toml            # features.skills = true
└── skills/                # Symlinked from aq-agent-config/skills/
    ├── task-spec/SKILL.md
    ├── diff-review/SKILL.md
    ├── commit-msg/SKILL.md
    ├── submodule-bump/SKILL.md
    └── cubemx-verify/SKILL.md

~/.config/agent-config/    # Full repo for templates, scripts, reference
├── templates/
├── scripts/
├── skills/
└── ...
```

### 6.4 Update Flow

1. Push changes to `aq-agent-config` on GitHub.
2. `nix flake update aq-agent-config` (or `nix flake lock --update-input aq-agent-config`).
3. Rebuild: `nixos-rebuild switch` or `home-manager switch`.
4. Both CC and Codex immediately see updated instructions and skills.

---

## Phase 7: Feedback Loop

### 7.1 `SUGGESTIONS.md`

```markdown
# Agent Suggestions

Agents should append entries here when they encounter ambiguity, make assumptions, or
identify potential improvements to agent configuration.

Format:

### <DATE> — <PROJECT> — <AGENT>
**Context:** <what was happening>
**Issue:** <what was ambiguous or suboptimal>
**Suggestion:** <proposed change to AGENTS.md, a skill, or a template>
```

### 7.2 `CHANGELOG.md`

```markdown
# Changelog

All notable changes to agent configuration are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [2026.02.06] — Initial Release

### Added
- Global AGENTS.md (migrated from standalone file, fixes applied)
- CC slash commands: /plan, /review, /bump-defs, /cubemx-verify
- CC settings.json with Skill in allowedTools
- Codex AGENTS.md and config.toml with skills enabled
- Shared skills: task-spec, diff-review, commit-msg, submodule-bump, cubemx-verify
- Templates: TASK.md, REVIEW.md, project-agents.md, project-claude.md
- Scripts: handoff.sh, sync-projects.sh
- Nix home-manager module for global deployment
- SUGGESTIONS.md feedback loop
```

### 7.3 `README.md`

```markdown
# aq-agent-config

Central configuration for AI coding agents (Claude Code, Codex) used across Aquila.

## How It Works

This repo is consumed as a Nix flake input. On rebuild, Nix places:

| Content | CC path | Codex path |
|---------|---------|------------|
| Global instructions | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` |
| Settings | `~/.claude/settings.json` | `~/.codex/config.toml` |
| Slash commands | `~/.claude/commands/` | N/A |
| Skills | `~/.claude/skills/` | `~/.codex/skills/` |
| Templates & scripts | `~/.config/agent-config/` | `~/.config/agent-config/` |

Skills are shared between both tools using the Agent Skills standard.

## Usage

### Agent handoff
```bash
agent-handoff TASK.md main feat/my-branch > HANDOFF.md
```

### CC slash commands
```
/plan <description of work>
/review
/bump-defs
/cubemx-verify
```

### Adding a new project
1. Copy `templates/project-agents.md` to project root as `AGENTS.md`.
2. Fill in project-specific fields, especially Context Loading.
3. Optionally copy `templates/project-claude.md` to `CLAUDE.md` for CC overrides.

### Updating
```bash
nix flake update aq-agent-config
nixos-rebuild switch  # or home-manager switch
```

## Contributing

1. Branch, make changes, open PR.
2. Update CHANGELOG.md.
3. After merge, bump flake lock and rebuild.
```

---

## Phase 8: Integrate with First Project

### 8.1 Create project-level `AGENTS.md`

In your most active `aq-*` project, create an `AGENTS.md` from the template. Fill in
all project-specific fields. This file is read by both CC and Codex.

### 8.2 Optionally create `CLAUDE.md`

If the project needs CC-specific overrides or project-level skills in `.claude/skills/`,
create a `CLAUDE.md` from `templates/project-claude.md`.

### 8.3 Validate discovery

**Claude Code:**
1. `cd` into the project.
2. Start CC. Verify it loads both `~/.claude/CLAUDE.md` (global) and `AGENTS.md`
   (project).
3. Check that `/plan`, `/review`, `/bump-defs`, `/cubemx-verify` appear in the
   command palette.
4. Check that skills are listed (CC should show them at startup or when relevant).

**Codex:**
1. `cd` into the project.
2. Start Codex. Verify it loads both `~/.codex/AGENTS.md` (global) and `AGENTS.md`
   (project).
3. Verify skills are discoverable (check Codex output for skill loading messages).

### 8.4 Validate end-to-end handoff

1. In CC, run `/plan <a small, low-risk task>`.
2. Review the generated TASK.md.
3. Hand TASK.md to Codex for execution.
4. Run `agent-handoff TASK.md main` to capture the diff.
5. In CC, run `/review`.
6. Verify the REVIEW.md output is useful and actionable.
7. Iterate on templates and skills based on this first run.

---

## Verification Checklist

### Repository
- [ ] `aq-agent-config` repository created and pushed
- [ ] `AGENTS.md` updated (truncated sentence, context loading, skills, handoff)
- [ ] `home/claude/CLAUDE.md` written (CC-specific additions only)
- [ ] `home/claude/settings.json` has `Skill` in `allowedTools`
- [ ] `home/claude/commands/` contains plan.md, review.md, bump-defs.md, cubemx-verify.md
- [ ] `home/codex/AGENTS.md` written (Codex-specific additions only)
- [ ] `home/codex/config.toml` has `features.skills = true`
- [ ] All skill SKILL.md files have correct frontmatter (`name`, `description`)
- [ ] `templates/` contains TASK.md, REVIEW.md, project-agents.md, project-claude.md
- [ ] `scripts/handoff.sh` and `scripts/sync-projects.sh` are executable
- [ ] `SUGGESTIONS.md`, `CHANGELOG.md`, `README.md` exist

### Nix
- [ ] `nix/module.nix` integrates with existing home-manager config
- [ ] Flake input added for `aq-agent-config`
- [ ] `nix flake update && rebuild` places all files correctly

### CC Discovery
- [ ] `~/.claude/CLAUDE.md` contains AGENTS.md + CC additions
- [ ] `~/.claude/commands/` has all slash commands
- [ ] `~/.claude/skills/` contains all skill directories
- [ ] Slash commands appear in CC command palette
- [ ] Skills are loaded by CC when relevant

### Codex Discovery
- [ ] `~/.codex/AGENTS.md` contains AGENTS.md + Codex additions
- [ ] `~/.codex/config.toml` enables skills
- [ ] `~/.codex/skills/` contains all skill directories
- [ ] Skills are discoverable by Codex

### Integration
- [ ] Project-level `AGENTS.md` created for at least one project
- [ ] Both CC and Codex load global + project instructions simultaneously
- [ ] End-to-end handoff workflow validated on a real task
