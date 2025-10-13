{ config, ... }:
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
        identityFile = null; # Use agent instead of specific key file
      };
    };

    # Extra configuration
    extraConfig = ''
      # Use the stable socket path if SSH_AUTH_SOCK is not set
      # IdentityAgent has lower priority than SSH_AUTH_SOCK when both are set
      Host *
          IdentityAgent ${config.home.homeDirectory}/.ssh/ssh_auth_sock
    '';
  };

  # Create an SSH rc file that helps maintain agent forwarding
  # This runs when someone SSHs into this machine
  home.file.".ssh/rc" = {
    text = ''
      #!/bin/sh

      # SSH rc script to maintain agent forwarding
      # This script runs when someone SSHs into this machine

      if [ -n "$SSH_AUTH_SOCK" ]; then
        # Create a stable symlink to the current SSH agent socket
        # This is the primary socket that should always work
        ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
        
        # Store the current socket path for debugging
        echo "$SSH_AUTH_SOCK" > ~/.ssh/last_ssh_auth_sock
        
        # Store timestamp for debugging
        date > ~/.ssh/last_ssh_auth_update
      fi

      # Fix permissions on the .ssh directory
      if [ -d ~/.ssh ]; then
        chmod 700 ~/.ssh
        chmod 600 ~/.ssh/rc 2>/dev/null || true
      fi
    '';
    executable = true;
  };

  # Create a sophisticated helper script to fix SSH agent socket in existing sessions
  home.file.".local/bin/fix-ssh-agent" = {
    text = ''
      #!/usr/bin/env bash

      # This script intelligently finds and sets up SSH agent socket
      # It handles switching between SSH forwarded agents and local agents

      # Function to test if a socket is valid and working
      test_ssh_socket() {
        local socket="$1"
        if [ -S "$socket" ]; then
          SSH_AUTH_SOCK="$socket" ssh-add -l &>/dev/null
          local result=$?
          # Return codes: 0 = has keys, 1 = no keys but working, 2+ = not working
          if [ $result -le 1 ]; then
            return 0
          fi
        fi
        return 1
      }

      # Function to find a valid SSH socket
      find_valid_ssh_socket() {
        local socket
        
        # Priority 1: Check current SSH_AUTH_SOCK if it's still valid
        if [ -n "$SSH_AUTH_SOCK" ] && test_ssh_socket "$SSH_AUTH_SOCK"; then
          echo "$SSH_AUTH_SOCK"
          return 0
        fi
        
        # Priority 2: Check the stable symlink
        if test_ssh_socket "$HOME/.ssh/ssh_auth_sock"; then
          echo "$HOME/.ssh/ssh_auth_sock"
          return 0
        fi
        
        # Priority 3: Check if we're in an SSH session with a new socket
        if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
          # Look for SSH forwarded sockets in /tmp
          for socket in $(find /tmp -type s -path '*/ssh-*' -name 'agent.*' 2>/dev/null | sort -r); do
            if test_ssh_socket "$socket"; then
              echo "$socket"
              return 0
            fi
          done
        fi
        
        # Priority 4: Check for 1Password agent (local sessions)
        if test_ssh_socket "$HOME/.1password/agent.sock"; then
          echo "$HOME/.1password/agent.sock"
          return 0
        fi
        
        # Priority 5: Check for any other SSH agent sockets
        for socket in $(find /tmp -type s -path '*/ssh-*' -name 'agent.*' -user "$USER" 2>/dev/null | sort -r); do
          if test_ssh_socket "$socket"; then
            echo "$socket"
            return 0
          fi
        done
        
        # Priority 6: Check XDG runtime directory
        if [ -n "$XDG_RUNTIME_DIR" ]; then
          for socket in "$XDG_RUNTIME_DIR"/ssh-agent.* "$XDG_RUNTIME_DIR"/gnupg/S.gpg-agent.ssh; do
            if test_ssh_socket "$socket"; then
              echo "$socket"
              return 0
            fi
          done
        fi
        
        return 1
      }

      # Main script logic
      main() {
        local new_socket
        local old_socket="$SSH_AUTH_SOCK"
        
        # Find a valid socket
        new_socket=$(find_valid_ssh_socket)
        
        if [ -n "$new_socket" ]; then
          export SSH_AUTH_SOCK="$new_socket"
          
          # Update the stable symlink
          ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
          
          # Provide feedback
          if [ "$old_socket" != "$new_socket" ]; then
            echo "SSH_AUTH_SOCK updated from: $old_socket"
            echo "                        to: $new_socket"
          else
            echo "SSH_AUTH_SOCK unchanged: $SSH_AUTH_SOCK"
          fi
          
          # Test the connection
          if ssh-add -l &>/dev/null; then
            local key_count=$(ssh-add -l 2>/dev/null | wc -l)
            echo "✓ SSH agent working with $key_count key(s)"
          else
            echo "✓ SSH agent working (no keys loaded)"
          fi
          
          # Output export command for sourcing
          echo "export SSH_AUTH_SOCK='$SSH_AUTH_SOCK'"
        else
          echo "✗ No valid SSH agent socket found"
          echo ""
          echo "Troubleshooting:"
          echo "  • For SSH: ensure agent forwarding is enabled (ssh -A)"
          echo "  • For local: ensure 1Password SSH agent is running"
          echo "  • Check: systemctl --user status ssh-agent"
          return 1
        fi
      }

      main "$@"
    '';
    executable = true;
  };
}
