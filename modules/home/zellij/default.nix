{ pkgs, ... }:
{
  home.packages = with pkgs; [
    zellij
  ];

  xdg.configFile."zellij/config.kdl".source = ./config.kdl;
  xdg.configFile."zellij/layouts/default.kdl".source = ./layout.kdl;
  # Zellij-specific shell aliases
  programs.zsh.shellAliases = {
    # Attach or create session named after current directory
    zz = ''
      ${pkgs.zellij}/bin/zellij attach -c "`basename \"$PWD\"`"
    '';

    # Attach to first available session
    za = ''
      ${pkgs.zellij}/bin/zellij attach --index 0
    '';
  };
}
