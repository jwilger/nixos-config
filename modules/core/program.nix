{ pkgs, ... }: 
let
  ssh-agent-manager = pkgs.writeShellScriptBin "ssh-agent-manager" ''
    #!/usr/bin/env bash
    # SSH Agent Manager for stable SSH_AUTH_SOCK handling
    # This script ensures a stable SSH agent socket path for zellij sessions

    STABLE_SOCK="/tmp/ssh-agent-stable.sock"
    STABLE_SOCK_DIR="/tmp"

    # Function to set up stable SSH agent socket
    setup_stable_agent() {
        # Create directory if it doesn't exist
        mkdir -p "$STABLE_SOCK_DIR"
        
        # Skip if SSH_AUTH_SOCK is already the stable socket
        if [[ "$SSH_AUTH_SOCK" == "$STABLE_SOCK" ]]; then
            # Check if the stable socket is valid
            if [[ -S "$STABLE_SOCK" ]] && [[ "$(readlink -f "$STABLE_SOCK" 2>/dev/null)" != "$STABLE_SOCK" ]]; then
                echo "# SSH agent already stabilized"
                return 0
            else
                # Remove broken stable socket
                rm -f "$STABLE_SOCK"
                echo "# Removed broken stable socket" >&2
                # Don't set SSH_AUTH_SOCK if we don't have a valid alternative
                unset SSH_AUTH_SOCK
                return 1
            fi
        fi
        
        # If we have an SSH_AUTH_SOCK (either forwarded or local)
        if [[ -n "$SSH_AUTH_SOCK" && -S "$SSH_AUTH_SOCK" ]]; then
            # Remove old stable socket if it exists
            [[ -e "$STABLE_SOCK" ]] && rm -f "$STABLE_SOCK"
            
            # Create symlink to current SSH_AUTH_SOCK
            ln -sf "$SSH_AUTH_SOCK" "$STABLE_SOCK"
            
            # Output the export command for eval
            echo "export SSH_AUTH_SOCK=\"$STABLE_SOCK\""
            
            echo "SSH agent socket stabilized: $STABLE_SOCK -> $(readlink $STABLE_SOCK)" >&2
        else
            echo "No SSH agent socket found" >&2
        fi
    }

    # Function to check if we're in an SSH session
    is_ssh_session() {
        [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]]
    }

    # Main execution
    case "''${1:-setup}" in
        "setup")
            setup_stable_agent
            ;;
        "is-ssh")
            if is_ssh_session; then
                echo "ssh"
                exit 0
            else
                echo "local"
                exit 1
            fi
            ;;
        "status")
            echo "SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
            echo "Socket exists: $(test -S "$SSH_AUTH_SOCK" && echo "yes" || echo "no")"
            echo "Session type: $(is_ssh_session && echo "SSH" || echo "local")"
            ;;
        *)
            echo "Usage: $0 [setup|is-ssh|status]"
            exit 1
            ;;
    esac
  '';

  git-ssh-sign = pkgs.writeShellScriptBin "git-ssh-sign" ''
    #!/usr/bin/env bash
    # Git SSH signing wrapper that detects local vs SSH sessions
    # Uses op-ssh-sign for local sessions, ssh-keygen for SSH sessions

    # Check if we're in an SSH session
    if ${ssh-agent-manager}/bin/ssh-agent-manager is-ssh >/dev/null 2>&1; then
        # SSH session - use ssh-keygen with forwarded agent
        # Create a temporary public key file for the signing key
        SIGNING_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwXlUIgMZDNewfvIyX5Gd1B1dIuLT7lH6N+2+FrSaSU"
        TEMP_KEY=$(mktemp)
        echo "$SIGNING_KEY" > "$TEMP_KEY"
        
        # Use ssh-keygen to sign with the temporary key file
        ${pkgs.openssh}/bin/ssh-keygen -Y sign -n git -f "$TEMP_KEY" "$@"
        result=$?
        
        # Clean up temporary file
        rm -f "$TEMP_KEY"
        exit $result
    else
        # Local session - use 1Password SSH signing
        exec ${pkgs._1password-gui}/bin/op-ssh-sign "$@"
    fi
  '';
in
{
  programs.dconf.enable = true;
  programs.zsh.enable = true;
  programs.nix-ld.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  environment.systemPackages = with pkgs; [
    ssh-agent-manager
    git-ssh-sign
  ];
}