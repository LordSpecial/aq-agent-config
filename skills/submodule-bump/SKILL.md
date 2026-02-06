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
5. Review the diff - generated files should only show changes consistent with
   the schema update. Flag anything unexpected.
6. Commit:
   ```
   deps: bump aq-standard-definitions to <short-sha>

   <one-line summary of what changed in the definitions>
   ```

## Never

- Hand-edit generated files.
- Bump without rebuilding and verifying.
