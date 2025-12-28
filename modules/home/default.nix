{ ... }:
{
  imports = [
    (import ./aws.nix)
  ]
  ++ [ (import ./bat.nix) ] # better cat command
  ++ [ (import ./btop.nix) ] # resouces monitor
  ++ [ (import ./environment.nix) ] # global environment variables
  ++ [ (import ./git.nix) ] # version control
  ++ [ (import ./lazygit.nix) ] # git terminal UI
  ++ [ (import ./theme.nix) ] # general theme settings
  ++ [ (import ./helix) ] # helix editor
  ++ [ (import ./packages.nix) ] # other packages
  ++ [ (import ./ssh.nix) ] # SSH configuration
  ++ [ (import ./starship.nix) ] # shell prompt
  ++ [ (import ./yazi) ] # terminal-based file explorer
  ++ [ (import ./zellij) ] # terminal multiplexer
  ++ [ (import ./zsh.nix) ]; # shell
}
