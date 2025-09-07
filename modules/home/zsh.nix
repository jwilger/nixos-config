{
  host,
  ...
}:
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
      ];
    };

    initContent = ''
      DISABLE_MAGIC_FUNCTIONS=true

      # SSH Agent Detection for proper forwarding support
      # This handles both local 1Password agent and forwarded agents from laptop

      # Function to test if an SSH agent socket is valid
      test_ssh_agent() {
        if [ -S "$1" ]; then
          SSH_AUTH_SOCK="$1" ssh-add -l >/dev/null 2>&1
          return $?
        fi
        return 1
      }

      # Function to find the best available SSH agent (returns real socket, not symlinks)
      find_ssh_agent() {
        # 1. Check if we're in an SSH session with forwarded agent
        # Skip our stable symlink to avoid circular references
        if [ -n "$SSH_CONNECTION" ] && [ -n "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/ssh_auth_sock" ]; then
          if test_ssh_agent "$SSH_AUTH_SOCK"; then
            echo "$SSH_AUTH_SOCK"
            return
          fi
        fi
        
        # 2. Check for saved forwarded agent from SSH rc
        if [ -f ~/.ssh/last_forwarded_sock ]; then
          local saved_sock=$(cat ~/.ssh/last_forwarded_sock)
          # Make sure it's not our symlink
          if [ "$saved_sock" != "$HOME/.ssh/ssh_auth_sock" ] && test_ssh_agent "$saved_sock"; then
            echo "$saved_sock"
            return
          fi
        fi
        
        # 3. Check for forwarded agents in standard locations
        # Use find to avoid glob expansion errors
        for sock in $(find /tmp -maxdepth 2 -type s -path '*/ssh-*' -name 'agent.*' 2>/dev/null) \
                    $(find /run/user/"$(id -u)" -maxdepth 2 -type s -name 'ssh-agent.*' 2>/dev/null); do
          if test_ssh_agent "$sock" 2>/dev/null; then
            echo "$sock"
            return
          fi
        done
        
        # 4. Fall back to local 1Password agent
        echo "$HOME/.1password/agent.sock"
      }

      # Find the best available agent and create a stable symlink
      _real_socket=$(find_ssh_agent)
      if [ -n "$_real_socket" ] && [ -S "$_real_socket" ]; then
        mkdir -p ~/.ssh
        ln -sf "$_real_socket" ~/.ssh/ssh_auth_sock
        # ALWAYS use the symlink as SSH_AUTH_SOCK, not the real socket
        export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
      fi

      # Helper function to refresh SSH agent (updates the symlink target only)
      refresh-ssh-agent() {
        local _real_socket=$(find_ssh_agent)
        if [ -n "$_real_socket" ] && [ -S "$_real_socket" ]; then
          ln -sf "$_real_socket" ~/.ssh/ssh_auth_sock
          echo "SSH agent symlink updated to point to: $_real_socket"
          ssh-add -l | head -3
        else
          echo "Warning: No valid socket found"
        fi
      }
    '';

    shellAliases = {
      # Utils
      cat = "bat";
      icat = "kitten icat";
      dsize = "du -hs";
      findw = "grep -rl";
      pdf = "tdf";
      open = "xdg-open";

      l = "eza --icons  -a --group-directories-first -1"; # EZA_ICON_SPACING=2
      ll = "eza --icons  -a --group-directories-first -1 --no-user --long";
      tree = "eza --icons --tree --group-directories-first";

      # Nixos
      ns = "nix-shell --run zsh";
      nix-shell = "nix-shell --run zsh";
      nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#${host}";
      nix-switchu = "sudo nixos-rebuild switch --upgrade --flake /etc/nixos#${host}";
      nix-flake-update = "sudo nix flake update /etc/nixos#";
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
