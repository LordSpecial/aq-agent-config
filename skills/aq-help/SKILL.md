---
name: aq-help
description: "Print the Codex help section from shared HELP.md. Use when the user
  asks for available Codex skills or requests aq-help output."
---

# AQ Help Skill

## Instructions

1. Read `~/.config/agent-config/HELP.md`.
2. If the file is missing, state that `aq-agent-config` is not fully installed and
   ask the user to install or re-run setup.
3. Output only the section titled `## Codex Skills`.
4. Do not add commentary before or after the section.
