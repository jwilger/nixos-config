{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    zellij
  ];

  xdg.configFile."zellij/config.kdl".source = ./config.kdl;

  # Provide a single, borderless pane while keeping Zellij's built-in status bar.
  xdg.configFile."zellij/layouts/single-borderless.kdl".source =
    pkgs.writeText "zellij-layout-single-borderless.kdl" ''
      layout {
        default_tab_template {
          pane borderless=true
        }
      }
    '';

  # Zellij-specific shell aliases
  programs.zsh.shellAliases = {
    # Attach or create session named after current directory
    zz = ''
      ${pkgs.zellij}/bin/zellij --layout=.zellij.kdl attach -c "`basename \"$PWD\"`"
    '';

    # Attach to first available session
    za = ''
      ${pkgs.zellij}/bin/zellij attach --index 0
    '';
  };
}
