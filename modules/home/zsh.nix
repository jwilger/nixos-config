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
        "eza"
      ];
    };

    # SSH Agent Socket Management for Zellij
    # Ensures SSH agent forwarding works correctly with zellij sessions
    initExtra = ''
      # If we're starting a local session (not via SSH), point symlink to local 1Password socket
      # This ensures the symlink always exists and points to the correct agent
      if [[ -z "$SSH_CONNECTION" ]] && [[ -S "$HOME/.1password/agent.sock" ]]; then
          ln -sf "$HOME/.1password/agent.sock" "$HOME/.ssh/ssh_auth_sock"
      fi

      # Always use the stable symlink path when inside a zellij session
      # This allows seamless switching between local and SSH-forwarded agents
      if [[ -n "$ZELLIJ" ]] && [[ -S "$HOME/.ssh/ssh_auth_sock" ]]; then
          export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
      fi
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

      # AI Stuff - Launch zellij with borderless nvim + claude layout
      cc = "zellij --layout borderless-left attach -c \"$(basename \"$PWD\")-claude\"";
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
