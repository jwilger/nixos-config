{ config, host, ... }:
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
      local_agent_sock="$HOME/.ssh/agent-local.sock"
      forwarded_agent_sock="$HOME/.ssh/agent-forwarded.sock"

      if [[ -L "$local_agent_sock" ]] && [[ ! -S "$local_agent_sock" ]]; then
          rm -f "$local_agent_sock"
      fi

      if [[ -L "$forwarded_agent_sock" ]] && [[ ! -S "$forwarded_agent_sock" ]]; then
          rm -f "$forwarded_agent_sock"
      fi

      if [[ -S "$HOME/.1password/agent.sock" ]]; then
          ln -sfn "$HOME/.1password/agent.sock" "$local_agent_sock"
      fi

      if [[ -n "$SSH_CONNECTION" ]]; then
          export OP_BIOMETRIC_UNLOCK_ENABLED=false

          if [[ -n "$SSH_AUTH_SOCK" ]] && [[ "$SSH_AUTH_SOCK" != "$forwarded_agent_sock" ]] && [[ -S "$SSH_AUTH_SOCK" ]]; then
              ln -sfn "$SSH_AUTH_SOCK" "$forwarded_agent_sock"
          fi

          if [[ -S "$forwarded_agent_sock" ]]; then
              export SSH_AUTH_SOCK="$forwarded_agent_sock"
          fi
      elif [[ -S "$local_agent_sock" ]]; then
          export SSH_AUTH_SOCK="$local_agent_sock"
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
