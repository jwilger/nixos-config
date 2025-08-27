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
      
      # Function to find the best available SSH agent
      find_ssh_agent() {
        # 1. Check if we're in an SSH session with forwarded agent
        if [ -n "$SSH_CONNECTION" ] && [ -n "$SSH_AUTH_SOCK" ]; then
          if test_ssh_agent "$SSH_AUTH_SOCK"; then
            echo "$SSH_AUTH_SOCK"
            return
          fi
        fi
        
        # 2. Check for saved forwarded agent from SSH rc
        if [ -f ~/.ssh/last_forwarded_sock ]; then
          local saved_sock=$(cat ~/.ssh/last_forwarded_sock)
          if test_ssh_agent "$saved_sock"; then
            echo "$saved_sock"
            return
          fi
        fi
        
        # 3. Check for agent-forwarded.sock symlink (created by SSH rc)
        if test_ssh_agent ~/.ssh/agent-forwarded.sock 2>/dev/null; then
          echo ~/.ssh/agent-forwarded.sock
          return
        fi
        
        # 4. Check for forwarded agents in standard locations
        for sock in /tmp/ssh-*/agent.* /run/user/"$(id -u)"/ssh-agent.* ; do
          if test_ssh_agent "$sock" 2>/dev/null; then
            echo "$sock"
            return
          fi
        done
        
        # 5. Fall back to local 1Password agent
        echo "$HOME/.1password/agent.sock"
      }
      
      # Set SSH_AUTH_SOCK to the best available agent
      export SSH_AUTH_SOCK=$(find_ssh_agent)
      
      # Create a stable symlink for the current agent (helps with multiplexer sessions)
      if [ -n "$SSH_AUTH_SOCK" ] && [ -S "$SSH_AUTH_SOCK" ]; then
        mkdir -p ~/.ssh
        ln -sf "$SSH_AUTH_SOCK" ~/.ssh/current_agent.sock
      fi
      
      # Helper function to refresh SSH agent (can be called manually if needed)
      refresh-ssh-agent() {
        export SSH_AUTH_SOCK=$(find_ssh_agent)
        echo "SSH_AUTH_SOCK updated to: $SSH_AUTH_SOCK"
        if [ -S "$SSH_AUTH_SOCK" ]; then
          ssh-add -l | head -3
        else
          echo "Warning: Socket not found or invalid"
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
