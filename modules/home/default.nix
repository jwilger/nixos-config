{ ... }:
{
  imports = [
    (import ./abduco.nix) # lightweight terminal session manager
    (import ./aws.nix)
  ]
  ++ [ (import ./ai-bot) ] # zero-seat bot automation profile
  ++ [ (import ./bat.nix) ] # better cat command
  ++ [ (import ./btop.nix) ] # resouces monitor
  ++ [ (import ./environment.nix) ] # global environment variables
  ++ [ (import ./git.nix) ] # version control
  ++ [ (import ./lazygit.nix) ] # git terminal UI
  ++ [ (import ./theme.nix) ] # general theme settings
  ++ [ (import ./helix) ] # helix editor
  ++ [ (import ./herdr.nix) ] # agent-aware terminal multiplexer
  ++ [ (import ./packages.nix) ] # other packages
  ++ [ (import ./ssh.nix) ] # SSH configuration
  ++ [ (import ./starship.nix) ] # shell prompt
  ++ [ (import ./tmux.nix) ] # terminal multiplexer (tmux)
  ++ [ (import ./wezterm.nix) ] # terminal emulator
  ++ [ (import ./yazi) ] # terminal-based file explorer
  ++ [ (import ./zellij) ] # terminal multiplexer
  ++ [ (import ./voice-dictation.nix) ] # voice-to-text dictation
  ++ [ (import ./zsh.nix) ]; # shell
}
