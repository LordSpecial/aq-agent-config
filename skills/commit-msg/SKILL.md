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
