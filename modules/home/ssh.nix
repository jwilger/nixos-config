{ ... }:
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

      "ubuntu-2510-dev" = {
        host = "127.0.0.1";
        port = 60022;
        user = "jwilger";
        forwardAgent = true;
        identityAgent = "/Users/jwilger/.ssh/ssh_auth_sock";
        extraOptions = {
          PreferredAuthentications = "publickey";
          StrictHostKeyChecking = "accept-new";
        };
      };
    };
  };

  # Update the forwarded agent socket on SSH login without clobbering the
  # stable local 1Password socket used by local shells.
  home.file.".ssh/rc" = {
    executable = true;
    text = ''
      #!/bin/sh

      if [ -n "$SSH_AUTH_SOCK" ] && [ -S "$SSH_AUTH_SOCK" ]; then
          ln -sfn "$SSH_AUTH_SOCK" "$HOME/.ssh/agent-forwarded.sock"
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
