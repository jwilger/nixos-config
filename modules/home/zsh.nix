{ host, ... }:
{
  programs.zsh = {
    enable = true;
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
        "ssh"
        "eza"
      ];
    };

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

      # AI Stuff
      cc = "claude --append-system-prompt \"$(cat ~/.claude/system-prompt.md)\"";
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
