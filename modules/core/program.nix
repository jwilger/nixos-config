{ pkgs, ... }:
{
  programs.dconf.enable = true;
  programs.zsh.enable = true;
  programs.nix-ld.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "git-ssh-sign" ''
      #!/usr/bin/env bash
      # Git SSH signing wrapper that works with WezTerm's native SSH agent forwarding
      # WezTerm automatically handles forwarding the correct agent (local or remote)

      # Check if SSH agent is available
      if [[ -z "$SSH_AUTH_SOCK" || ! -S "$SSH_AUTH_SOCK" ]]; then
          echo "Error: SSH agent not available (SSH_AUTH_SOCK not set or socket doesn't exist)" >&2
          exit 1
      fi

      # For 1Password agent (both local and forwarded), prefer op-ssh-sign if available
      resolved_sock=$(readlink -f "$SSH_AUTH_SOCK" 2>/dev/null || echo "$SSH_AUTH_SOCK")
      if [[ "$resolved_sock" == "$HOME/.1password/agent.sock" ]] && command -v op-ssh-sign >/dev/null 2>&1; then
          # Use 1Password's native SSH signing
          exec ${pkgs._1password-gui}/bin/op-ssh-sign "$@"
      else
          # Use standard ssh-keygen signing (works with any SSH agent)
          SIGNING_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwXlUIgMZDNewfvIyX5Gd1B1dIuLT7lH6N+2+FrSaSU"
          TEMP_KEY=$(mktemp)
          echo "$SIGNING_KEY" > "$TEMP_KEY"
          
          ${pkgs.openssh}/bin/ssh-keygen -Y sign -n git -f "$TEMP_KEY" "$@"
          result=$?
          
          rm -f "$TEMP_KEY"
          exit $result
      fi
    '')
  ];
}
