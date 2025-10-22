{ pkgs, ... }:
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
        user = "git";
      };
    };
  };

  # Create ~/.ssh/rc to maintain stable SSH agent socket symlink
  # This script runs on every SSH connection and updates the symlink
  # to point to the current forwarded agent socket
  home.file.".ssh/rc" = {
    executable = true;
    text = ''
      #!/bin/sh

      # Update symlink to current SSH agent socket if one is forwarded
      if [ -n "$SSH_AUTH_SOCK" ]; then
          ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/ssh_auth_sock"
      fi

      # Handle xauth for X11 forwarding (required when ~/.ssh/rc exists)
      # Without this, X11 forwarding breaks because sshd expects rc to handle it
      if read proto cookie && [ -n "$DISPLAY" ]; then
          if [ `echo "$DISPLAY" | cut -c1-10` = 'localhost:' ]; then
              # X11UseLocalhost=yes
              echo add unix:`echo "$DISPLAY" |
                  cut -c11-` "$proto" "$cookie"
          else
              # X11UseLocalhost=no
              echo add "$DISPLAY" "$proto" "$cookie"
          fi | xauth -q -
      fi
    '';
  };
}
