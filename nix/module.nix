{ config, lib, pkgs, ... }:

let
  cfg = config.programs.aqAgentConfig;
  agentConfig = cfg.source;
in
{
  options.programs.aqAgentConfig = {
    enable = lib.mkEnableOption "Aquila agent configuration for Claude and Codex";

    source = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Source path for aq-agent-config repository content.
        For flake inputs, use `inputs.aq-agent-config.outPath`.
      '';
      example = lib.literalExpression "inputs.aq-agent-config.outPath";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.source != null;
        message = "Set programs.aqAgentConfig.source when enabling aqAgentConfig.";
      }
    ];

    # -- Claude Code ------------------------------------------------

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

    # -- Codex ------------------------------------------------------

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

    # -- Shared assets ---------------------------------------------
    home.file.".config/agent-config/templates" = {
      source = "${agentConfig}/templates";
      recursive = true;
    };

    home.file.".config/agent-config/scripts" = {
      source = "${agentConfig}/scripts";
      recursive = true;
    };

    home.file.".config/agent-config/HELP.md".source =
      "${agentConfig}/HELP.md";

    # Commands/skills are copied as regular files so both tools can index them.
    # Some discovery flows ignore symlinked SKILL.md/command files.
    home.activation.aqAgentConfigCopyDiscoverableFiles =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu

        mkdir -p "$HOME/.claude/commands" "$HOME/.claude/skills" "$HOME/.codex/skills"

        for cmd_file in "${agentConfig}/home/claude/commands/"*.md; do
          cmd_name="$(basename "$cmd_file")"
          rm -f "$HOME/.claude/commands/$cmd_name"
          cp "$cmd_file" "$HOME/.claude/commands/$cmd_name"
        done

        for skill_dir in "${agentConfig}/skills/"*/; do
          skill_name="$(basename "$skill_dir")"

          rm -rf "$HOME/.claude/skills/$skill_name"
          mkdir -p "$HOME/.claude/skills/$skill_name"
          cp -R "$skill_dir". "$HOME/.claude/skills/$skill_name/"

          rm -rf "$HOME/.codex/skills/$skill_name"
          mkdir -p "$HOME/.codex/skills/$skill_name"
          cp -R "$skill_dir". "$HOME/.codex/skills/$skill_name/"
        done
      '';

    # -- Scripts on PATH -------------------------------------------
    home.packages = [
      (pkgs.writeShellScriptBin "agent-handoff"
        (builtins.readFile "${agentConfig}/scripts/handoff.sh"))
      (pkgs.writeShellScriptBin "agent-sync-projects"
        (builtins.readFile "${agentConfig}/scripts/sync-projects.sh"))
    ];
  };
}
