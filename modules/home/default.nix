{...}: {
  imports =
       [(import ./bat.nix)]                       # better cat command
    ++ [(import ./btop.nix)]                      # resouces monitor 
    ++ [(import ./cava.nix)]                      # audio visualizer
    ++ [(import ./fuzzel.nix)]                    # launcher
    ++ [(import ./git.nix)]                       # version control
    ++ [(import ./gtk.nix)]                       # gtk theme
    ++ [(import ./hyprland)]                      # window manager
    ++ [(import ./insync)]                        # google drive client
    ++ [(import ./kitty.nix)]                     # terminal
    ++ [(import ./swaync/swaync.nix)]             # notification deamon
    ++ [(import ./nvim)]                          # neovim editor
    ++ [(import ./packages.nix)]                  # other packages
    ++ [(import ./scripts/scripts.nix)]           # personal scripts
    ++ [(import ./starship.nix)]                  # shell prompt
    ++ [(import ./waybar)]                        # status bar
    ++ [(import ./yazi)]                          # terminal-based file explorer
    ++ [(import ./zellij)]                        # terminal multiplexer
    ++ [(import ./zsh.nix)];                      # shell
}
