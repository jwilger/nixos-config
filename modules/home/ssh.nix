{ pkgs, ... }:
let
  onePasswordAgentSock =
    if pkgs.stdenv.isDarwin then
      "~/Library/Group\\ Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
      "~/.1password/agent.sock";
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraConfig = ''
      Match exec "$HOME/.local/bin/ssh-agent-bridge auto >/dev/null 2>&1"
        IdentityAgent ~/.ssh/ssh_auth_sock

      Host *
        ForwardAgent yes
        IdentityAgent ${onePasswordAgentSock}

      Host github.com
        User git

      Host 127.0.0.1
        Port 60022
        User jwilger
        ForwardAgent yes
        IdentityAgent /Users/jwilger/.ssh/agent-local.sock
        PreferredAuthentications publickey
        StrictHostKeyChecking accept-new
    '';

    settings."*" = { };
  };
}
