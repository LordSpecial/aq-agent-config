---
name: cubemx-verify
description: "Verify CubeMX regeneration output for integrity. Use after the user
  has regenerated from a .ioc file. Triggers: /aq-cubemx-verify command, or after any
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
