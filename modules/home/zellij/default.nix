{ pkgs, config, ... }:
let
  # Create a derivation for zjstatus plugin
  zjstatus = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "zjstatus";
    version = "0.21.1";

    src = pkgs.fetchurl {
      url = "https://github.com/dj95/zjstatus/releases/download/v${version}/zjstatus.wasm";
      sha256 = "sha256-3BmCogjCf2aHHmmBFFj7savbFeKGYv3bE2tXXWVkrho=";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out
      cp $src $out/zjstatus.wasm
    '';
  };
in
{
  home.packages = with pkgs; [
    zellij
  ];

  xdg.configFile."zellij/config.kdl".source = ./config.kdl;

  # Create the layout file using writeText to avoid duplication bug
  xdg.configFile."zellij/layouts/compact-with-datetime.kdl".source = pkgs.writeText "zellij-layout-compact-with-datetime.kdl" ''
    layout {
        default_tab_template {
            children
            pane size=1 borderless=true {
                plugin location="file://${zjstatus}/zjstatus.wasm" {
                    // Main status bar configuration
                    format_left   "{mode} #[fg=#B4BEFE,bg=#1E1E2E,bold]  {session} #[fg=#313244,bg=#1E1E2E]  {tabs}"
                    format_center ""
                    format_right  "{datetime}"

                    // Mode colors - Catppuccin Mocha theme with icons
                    mode_normal          "#[bg=#89B4FA,fg=#1E1E2E,bold]  "
                    mode_locked          "#[bg=#F9E2AF,fg=#1E1E2E,bold]  "
                    mode_resize          "#[bg=#F38BA8,fg=#1E1E2E,bold]  "
                    mode_pane            "#[bg=#A6E3A1,fg=#1E1E2E,bold]  "
                    mode_tab             "#[bg=#CBA6F7,fg=#1E1E2E,bold]  "
                    mode_scroll          "#[bg=#94E2D5,fg=#1E1E2E,bold]  "
                    mode_enter_search    "#[bg=#F5C2E7,fg=#1E1E2E,bold]  "
                    mode_search          "#[bg=#F5C2E7,fg=#1E1E2E,bold]  "
                    mode_rename_tab      "#[bg=#FAB387,fg=#1E1E2E,bold]  "
                    mode_rename_pane     "#[bg=#FAB387,fg=#1E1E2E,bold]  "
                    mode_session         "#[bg=#74C7EC,fg=#1E1E2E,bold]  "
                    mode_move            "#[bg=#F2CDCD,fg=#1E1E2E,bold]  "
                    mode_prompt          "#[bg=#CDD6F4,fg=#1E1E2E,bold]  "
                    mode_tmux            "#[bg=#F38BA8,fg=#1E1E2E,bold]  "

                    // Tab styles - Powerline-inspired with rounded edges
                    tab_normal              "#[fg=#313244,bg=#1E1E2E]#[fg=#6C7086,bg=#313244] {index} #[fg=#585B70]#[fg=#9399B2] {name} #[fg=#313244,bg=#1E1E2E]"
                    tab_active              "#[fg=#45475A,bg=#1E1E2E,bold]#[fg=#89B4FA,bg=#45475A] {index} #[fg=#CDD6F4]#[fg=#F5E8E4,bold] {name} #[fg=#45475A,bg=#1E1E2E,bold]"
                    tab_fullscreen_indicator       " "
                    tab_sync_indicator              " "
                    tab_floating_indicator          " "

                    // DateTime configuration
                    datetime          "#[fg=#313244,bg=#1E1E2E]#[fg=#9399B2,bg=#313244]  {format} #[fg=#313244,bg=#1E1E2E]"
                    datetime_format   "%a %d %b  %H:%M"
                    datetime_timezone "America/Los_Angeles"

                    // Other settings
                    hide_frame_for_single_pane "true"
                    border_enabled "false"
                }
            }
        }
    }
  '';

  # Create a wrapper script for zellij that handles SSH agent setup
  home.file.".local/bin/zj" = {
    text = ''
      #!/usr/bin/env bash

      # Intelligent zellij wrapper that handles SSH agent switching
      # Works correctly when switching between SSH and local desktop sessions

      # Function to test if a socket is valid
      test_socket() {
        [ -S "$1" ] && SSH_AUTH_SOCK="$1" ssh-add -l &>/dev/null 2>&1
        [ $? -le 1 ]
      }

      # Function to find and set up the best SSH agent
      setup_ssh_agent() {
        local found_socket=""
        local is_ssh_session=0
        
        # Detect if we're in an SSH session
        if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
          is_ssh_session=1
        fi
        
        # Strategy 1: If we have a working SSH_AUTH_SOCK, keep it
        if [ -n "$SSH_AUTH_SOCK" ] && test_socket "$SSH_AUTH_SOCK"; then
          found_socket="$SSH_AUTH_SOCK"
        
        # Strategy 2: Check the stable symlink
        elif test_socket "$HOME/.ssh/ssh_auth_sock"; then
          found_socket="$HOME/.ssh/ssh_auth_sock"
        
        # Strategy 3: For SSH sessions, look for forwarded sockets
        elif [ $is_ssh_session -eq 1 ]; then
          for socket in $(find /tmp -type s -path '*/ssh-*' -name 'agent.*' 2>/dev/null | sort -r); do
            if test_socket "$socket"; then
              found_socket="$socket"
              break
            fi
          done
        
        # Strategy 4: For local sessions, use 1Password agent
        elif [ $is_ssh_session -eq 0 ] && test_socket "$HOME/.1password/agent.sock"; then
          found_socket="$HOME/.1password/agent.sock"
        
        # Strategy 5: Try any available socket
        else
          # Try 1Password first regardless of session type
          if test_socket "$HOME/.1password/agent.sock"; then
            found_socket="$HOME/.1password/agent.sock"
          else
            # Look for any SSH agent socket
            for socket in $(find /tmp -type s -path '*/ssh-*' -name 'agent.*' -user "$USER" 2>/dev/null | sort -r); do
              if test_socket "$socket"; then
                found_socket="$socket"
                break
              fi
            done
          fi
        fi
        
        # Set the socket if we found one
        if [ -n "$found_socket" ]; then
          export SSH_AUTH_SOCK="$found_socket"
          # Update the stable symlink
          ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
          return 0
        else
          echo "Warning: No valid SSH agent socket found" >&2
          return 1
        fi
      }

      # Main execution

      # Always try to set up SSH agent before running zellij
      setup_ssh_agent

      # Check if we're attaching to an existing session
      if [[ "$*" == *"attach"* ]]; then
        # For attach operations, we need to be extra careful about agent setup
        # The agent may have changed since the session was created
        echo "Checking SSH agent status..." >&2
        
        if setup_ssh_agent; then
          echo "SSH agent configured: $SSH_AUTH_SOCK" >&2
        else
          echo "Warning: Could not configure SSH agent" >&2
          echo "You may need to run 'fix-ssh' inside the session" >&2
        fi
      fi

      # Run zellij with all provided arguments
      exec ${pkgs.zellij}/bin/zellij "$@"
    '';
    executable = true;
  };

  programs.zsh.shellAliases = {
    # Main zellij alias using our wrapper
    zz = ''
      zj --layout=.zellij.kdl attach -c "`basename \"$PWD\"`"
    '';

    # Attach to first session
    za = ''
      zj attach --index 0
    '';

    # Quick alias to fix SSH agent in current shell
    fix-ssh = ''
      eval "$(fix-ssh-agent)"
    '';

    # Test SSH agent status
    ssh-test = ''
      ssh-add -l && echo "✓ SSH agent is working" || echo "✗ SSH agent not working"
    '';
  };

  # Add sophisticated initialization to zsh for zellij sessions
  programs.zsh.initContent = ''
    # Function to ensure SSH agent is working in zellij
    _zellij_ssh_agent_check() {
      # Only run in zellij sessions
      [ -z "$ZELLIJ" ] && return 0
      
      # Test if current SSH_AUTH_SOCK works
      if ! ssh-add -l &>/dev/null 2>&1; then
        # Agent not working, try to fix it automatically
        
        # First, check if we have a stable symlink that works
        if [ -S "$HOME/.ssh/ssh_auth_sock" ]; then
          if SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock" ssh-add -l &>/dev/null 2>&1; then
            export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
            return 0
          fi
        fi
        
        # Check for 1Password agent (common for local sessions)
        if [ -S "$HOME/.1password/agent.sock" ]; then
          if SSH_AUTH_SOCK="$HOME/.1password/agent.sock" ssh-add -l &>/dev/null 2>&1; then
            export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
            ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
            return 0
          fi
        fi
        
        # Try to find any working socket
        for socket in $(find /tmp -type s -path '*/ssh-*' -name 'agent.*' -user "$USER" 2>/dev/null | sort -r); do
          if [ -S "$socket" ] && SSH_AUTH_SOCK="$socket" ssh-add -l &>/dev/null 2>&1; then
            export SSH_AUTH_SOCK="$socket"
            ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
            return 0
          fi
        done
      fi
    }

    # Run the check when shell starts
    _zellij_ssh_agent_check

    # Optional: Add a precmd hook to check periodically (commented out by default)
    # This would check before each prompt, but might be too aggressive
    # autoload -Uz add-zsh-hook
    # add-zsh-hook precmd _zellij_ssh_agent_check
  '';

  # Create a convenience script to diagnose SSH agent issues
  home.file.".local/bin/ssh-agent-debug" = {
    text = ''
      #!/usr/bin/env bash

      echo "=== SSH Agent Debug Information ==="
      echo ""
      echo "Environment Variables:"
      echo "  SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
      echo "  SSH_CONNECTION: $SSH_CONNECTION"
      echo "  SSH_TTY: $SSH_TTY"
      echo "  ZELLIJ: $ZELLIJ"
      echo ""

      echo "Socket Status:"
      if [ -n "$SSH_AUTH_SOCK" ]; then
        if [ -e "$SSH_AUTH_SOCK" ]; then
          if [ -S "$SSH_AUTH_SOCK" ]; then
            echo "  ✓ $SSH_AUTH_SOCK exists and is a socket"
            if ssh-add -l &>/dev/null 2>&1; then
              echo "  ✓ Socket is working"
              echo "  Keys loaded: $(ssh-add -l 2>/dev/null | wc -l)"
            else
              echo "  ✗ Socket exists but not responding"
            fi
          else
            echo "  ✗ $SSH_AUTH_SOCK exists but is not a socket"
          fi
        else
          echo "  ✗ $SSH_AUTH_SOCK does not exist"
        fi
      else
        echo "  ✗ SSH_AUTH_SOCK not set"
      fi
      echo ""

      echo "Checking alternative sockets:"

      # Check stable symlink
      if [ -e "$HOME/.ssh/ssh_auth_sock" ]; then
        echo -n "  ~/.ssh/ssh_auth_sock: "
        if [ -S "$HOME/.ssh/ssh_auth_sock" ] && SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock" ssh-add -l &>/dev/null 2>&1; then
          echo "✓ working"
        else
          echo "✗ not working"
        fi
      else
        echo "  ~/.ssh/ssh_auth_sock: not found"
      fi

      # Check 1Password
      if [ -e "$HOME/.1password/agent.sock" ]; then
        echo -n "  ~/.1password/agent.sock: "
        if [ -S "$HOME/.1password/agent.sock" ] && SSH_AUTH_SOCK="$HOME/.1password/agent.sock" ssh-add -l &>/dev/null 2>&1; then
          echo "✓ working"
        else
          echo "✗ not working"
        fi
      else
        echo "  ~/.1password/agent.sock: not found"
      fi

      echo ""
      echo "Available SSH agent sockets in /tmp:"
      find /tmp -type s -path '*/ssh-*' -name 'agent.*' 2>/dev/null | while read -r socket; do
        echo -n "  $socket: "
        if SSH_AUTH_SOCK="$socket" ssh-add -l &>/dev/null 2>&1; then
          echo "✓ working"
        else
          echo "✗ not working"
        fi
      done

      echo ""
      echo "To fix SSH agent issues, run: fix-ssh"
    '';
    executable = true;
  };
}
