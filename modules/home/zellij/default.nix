{ pkgs, ... }:
{
  home.packages = with pkgs; [
    zellij
  ];

  xdg.configFile."zellij/config.kdl".source = ./config.kdl;

  programs.zsh.shellAliases = {
    zz = ''
          zellij --layout=.zellij.kdl attach -c "`basename \"$PWD\"`"
    '';

    za = ''
          zellij attach --index 0
    '';
  };
}
