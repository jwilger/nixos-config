{ pkgs, ... }:
{
  home.file.".local/bin/ssh-agent-bridge" = {
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}

      set -u

      stable_agent_sock="$HOME/.ssh/ssh_auth_sock"
      linux_op_agent_sock="$HOME/.1password/agent.sock"
      macos_op_agent_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
      switcher_agent_sock="$runtime_dir/ssh-agent-switcher.sock"

      mode="''${1:-auto}"
      if [ "$mode" = "auto" ]; then
        if [ -n "''${SSH_CONNECTION:-}" ]; then
          mode="remote"
        else
          mode="local"
        fi
      fi

      agent_is_healthy() {
        candidate="$1"

        if [ ! -S "$candidate" ]; then
          return 1
        fi

        SSH_AUTH_SOCK="$candidate" ${pkgs.openssh}/bin/ssh-add -l >/dev/null 2>&1
      }

      first_healthy_agent() {
        for candidate in "$@"; do
          if agent_is_healthy "$candidate"; then
            printf '%s\n' "$candidate"
            return 0
          fi
        done

        return 1
      }

      op_agent_sock=""
      if agent_is_healthy "$linux_op_agent_sock"; then
        op_agent_sock="$linux_op_agent_sock"
      elif agent_is_healthy "$macos_op_agent_sock"; then
        op_agent_sock="$macos_op_agent_sock"
      fi

      selected_agent_sock=""
      case "$mode" in
        remote)
          selected_agent_sock="$(first_healthy_agent "$switcher_agent_sock" "$op_agent_sock" 2>/dev/null || true)"
          ;;
        local)
          selected_agent_sock="$(first_healthy_agent "$op_agent_sock" "$switcher_agent_sock" 2>/dev/null || true)"
          ;;
        *)
          printf 'usage: ssh-agent-bridge [auto|local|remote]\n' >&2
          exit 64
          ;;
      esac

      if [ -z "$selected_agent_sock" ]; then
        exit 1
      fi

      ${pkgs.coreutils}/bin/mkdir -p "$HOME/.ssh"
      ${pkgs.coreutils}/bin/ln -sfn "$selected_agent_sock" "$stable_agent_sock"
    '';
  };
}
