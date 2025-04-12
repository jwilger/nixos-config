{inputs, username, host, ...}: {
  imports =
       [(import ./bat.nix)]                       # better cat command
    ++ [(import ./btop.nix)]                      # resouces monitor 
    ++ [(import ./cava.nix)]                      # audio visualizer
    ++ [(import ./fuzzel.nix)]                    # launcher
    ++ [(import ./git.nix)]                       # version control
    ++ [(import ./gtk.nix)]                       # gtk theme
    ++ [(import ./hyprland)]                      # window manager
    ++ [(import ./kitty.nix)]                     # terminal
    ++ [(import ./swaync/swaync.nix)]             # notification deamon
    ++ [(import ./nvim.nix)]                      # neovim editor
    ++ [(import ./packages.nix)]                  # other packages
    ++ [(import ./scripts/scripts.nix)]           # personal scripts
    ++ [(import ./starship.nix)]                  # shell prompt
    ++ [(import ./waybar)]                        # status bar
    ++ [(import ./zsh.nix)];                      # shell
}
