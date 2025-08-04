{ host, config, pkgs, ... }:
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
      export "MICRO_TRUECOLOR=1"
    '';

    envExtra = ''
      # Check if we're in an SSH session with agent forwarding
      if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]]; then
        # In SSH session - do nothing, preserve the forwarded agent
        :
      else
        # Local session - use 1Password agent if no other agent is available
        if [[ -z "$SSH_AUTH_SOCK" || ! -S "$SSH_AUTH_SOCK" ]]; then
          export SSH_AUTH_SOCK="/${config.home.homeDirectory}/.1password/agent.sock"
        fi
      fi
      
      # Set up GUI askpass for sudo
      export SUDO_ASKPASS="${pkgs.zenity}/bin/zenity --password --title='Sudo Password'"
    '';

    shellAliases = {
      claude = "~/.claude/local/claude";

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
