{ pkgs, ... }:
let
  onePassPath = "~/.1password/agent.sock";
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Match blocks for specific hosts
    matchBlocks = {
      "*" = {
        forwardAgent = true;
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
      };
    };

    # SSH_AUTH_SOCK is managed by shell initialization below:
    # - When agent forwarding is active, use the forwarded agent
    # - When not set (local login), shell init falls back to 1Password agent
  };

  # SSH agent selection logic - runs on every shell initialization
  programs.zsh.initContent = ''
    # Function to test if a socket is valid and responding
    _ssh_test_socket() {
      [ -S "$1" ] && SSH_AUTH_SOCK="$1" ssh-add -l &>/dev/null 2>&1
      [ $? -le 1 ]
    }

    # Function to find and configure the optimal SSH agent
    _ssh_setup_agent() {
      local found_socket=""
      local is_ssh_session=0

      # Detect if we're in an SSH session
      if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
        is_ssh_session=1
      fi

      # Strategy 1: If we have a working SSH_AUTH_SOCK, keep it
      if [ -n "$SSH_AUTH_SOCK" ] && _ssh_test_socket "$SSH_AUTH_SOCK"; then
        found_socket="$SSH_AUTH_SOCK"

      # Strategy 2: Check the stable symlink
      elif _ssh_test_socket "$HOME/.ssh/ssh_auth_sock"; then
        found_socket="$HOME/.ssh/ssh_auth_sock"

      # Strategy 3: For SSH sessions, look for forwarded sockets
      elif [ $is_ssh_session -eq 1 ]; then
        for socket in $(find /tmp -type s -path '*/ssh-*' -name 'agent.*' 2>/dev/null | sort -r); do
          if _ssh_test_socket "$socket"; then
            found_socket="$socket"
            break
          fi
        done

      # Strategy 4: For local sessions, use 1Password agent
      elif [ $is_ssh_session -eq 0 ] && _ssh_test_socket "$HOME/.1password/agent.sock"; then
        found_socket="$HOME/.1password/agent.sock"

      # Strategy 5: Try any available socket
      else
        # Try 1Password first regardless of session type
        if _ssh_test_socket "$HOME/.1password/agent.sock"; then
          found_socket="$HOME/.1password/agent.sock"
        else
          # Look for any SSH agent socket
          for socket in $(find /tmp -type s -path '*/ssh-*' -name 'agent.*' -user "$USER" 2>/dev/null | sort -r); do
            if _ssh_test_socket "$socket"; then
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
        return 1
      fi
    }

    # Run agent setup on shell initialization
    _ssh_setup_agent
  '';

  # SSH diagnostic and management aliases
  programs.zsh.shellAliases = {
    # Test SSH agent status
    ssh-test = ''
      ssh-add -l && echo "✓ SSH agent is working" || echo "✗ SSH agent not working"
    '';

    # Re-run SSH agent setup in current shell
    fix-ssh = ''
      _ssh_setup_agent && echo "✓ SSH agent reconfigured: $SSH_AUTH_SOCK" || echo "✗ Could not configure SSH agent"
    '';
  };

  # Create diagnostic script for SSH agent troubleshooting
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
      echo "To reconfigure SSH agent, run: fix-ssh"
    '';
    executable = true;
  };
}
