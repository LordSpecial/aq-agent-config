{
  description = "Aquila agent configuration for Claude Code and Codex";

  outputs = { self }: {
    homeManagerModules.default = import ./nix/module.nix;
  };
}
