{ ... }:
{
  programs.ssh = {
    enable = true;
    
    # Enable agent forwarding for connections from this machine
    forwardAgent = true;
    
    # Match blocks for specific hosts
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = null; # Use agent instead of specific key file
      };
    };
    
    # Extra configuration
    extraConfig = ''
      # Dynamic SSH agent selection
      # The IdentityAgent will be overridden by SSH_AUTH_SOCK if set
      Host *
          IdentityAgent ~/.ssh/current_agent.sock
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
        # Create a predictable symlink to the forwarded agent socket
        # This helps when reconnecting to existing multiplexer sessions
        ln -sf "$SSH_AUTH_SOCK" ~/.ssh/agent-forwarded.sock
        
        # Also update the stable current agent symlink
        ln -sf "$SSH_AUTH_SOCK" ~/.ssh/current_agent.sock
        
        # Store the forwarded socket path for later reference
        echo "$SSH_AUTH_SOCK" > ~/.ssh/last_forwarded_sock
      fi
      
      # Fix permissions on the .ssh directory
      if [ -d ~/.ssh ]; then
        chmod 700 ~/.ssh
        chmod 600 ~/.ssh/rc 2>/dev/null || true
      fi
    '';
    executable = true;
  };
}