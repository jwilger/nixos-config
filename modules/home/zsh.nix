{
  config,
  host,
  pkgs,
  ...
}:
let
  onePasswordAgentSock =
    if pkgs.stdenv.isDarwin then
      "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
      "$HOME/.1password/agent.sock";
in
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "fzf"
        "sudo"
        "1password"
        "aws"
        "colored-man-pages"
        "docker"
        "docker-compose"
        "gh"
        "git-auto-fetch"
        "git-commit"
        "npm"
        "postgres"
        "rust"
        "safe-paste"
        "eza"
      ];
    };

    initContent = ''
      if [[ -n "$SSH_CONNECTION" ]]; then
          export OP_BIOMETRIC_UNLOCK_ENABLED=false
      else
          export SSH_AUTH_SOCK="${onePasswordAgentSock}"
      fi

      # Zellij 0.43.1+ natively manages terminal title with session name.
      # Shell-based title setting is disabled as zellij intercepts OSC sequences.
      # See: https://github.com/zellij-org/zellij/pull/3898 for session-switch title fix.
    '';

    shellAliases = {
      # Utils
      cat = "bat";
      open = "xdg-open";

      # Nixos
      ns = "nix-shell --run zsh";
      nix-shell = "nix-shell --run zsh";
      nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#${host}";
      nix-switchu = "sudo nixos-rebuild switch --upgrade --flake /etc/nixos#${host}";
      nix-clean = "sudo nix-collect-garbage && sudo nix-collect-garbage -d && sudo rm /nix/var/nix/gcroots/auto/* && nix-collect-garbage && nix-collect-garbage -d";

      # Git
      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gst = "git status";
      gbr = "git branch";
      gpl = "git pull";
      gps = "git push";
      gci = "git commit";
      gco = "git checkout";
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
