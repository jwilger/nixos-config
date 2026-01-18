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
      local session_name="$(basename "$PWD")"
      print -n "\033]0;$session_name - Zellij\007"
      ${pkgs.zellij}/bin/zellij attach -c "$session_name"
    '';
  };
}
