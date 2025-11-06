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

    # SSH Agent Socket Management
    # Handles both local 1Password agent and SSH agent forwarding
    initContent = ''
      if [[ -n "$SSH_CONNECTION" ]]; then
          # SSH session: Create/update symlink to forwarded agent socket
          # This allows agent forwarding to persist across Zellij panes

          # Remove invalid/circular symlink if it exists
          if [[ -L "$HOME/.ssh/ssh_auth_sock" ]] && [[ ! -S "$HOME/.ssh/ssh_auth_sock" ]]; then
              rm -f "$HOME/.ssh/ssh_auth_sock"
          fi

          # Only update symlink if SSH_AUTH_SOCK points to something OTHER than our symlink
          # This prevents circular symlink issues
          if [[ -n "$SSH_AUTH_SOCK" ]] && [[ "$SSH_AUTH_SOCK" != "$HOME/.ssh/ssh_auth_sock" ]] && [[ -S "$SSH_AUTH_SOCK" ]]; then
              ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/ssh_auth_sock"
              export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
          elif [[ -S "$HOME/.ssh/ssh_auth_sock" ]]; then
              # Fallback: use existing symlink (for new Zellij panes)
              export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
          fi
      else
          # Local session: use 1Password agent
          if [[ -S "$HOME/.1password/agent.sock" ]]; then
              ln -sf "$HOME/.1password/agent.sock" "$HOME/.ssh/ssh_auth_sock"
              export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
          fi
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
