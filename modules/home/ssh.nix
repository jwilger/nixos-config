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

    settings = {
      "*" = {
        ForwardAgent = true;
        IdentityAgent = onePasswordAgentSock;
      };

      "github.com" = {
        User = "git";
        IdentityAgent = "none";
        IdentitiesOnly = true;
        IdentityFile = "~/.ssh/id_ed25519";
      };

      "ubuntu-2510-dev" = {
        header = "Host 127.0.0.1";
        Port = 60022;
        User = "jwilger";
        ForwardAgent = true;
        IdentityAgent = "/Users/jwilger/.ssh/agent-local.sock";
        PreferredAuthentications = "publickey";
        StrictHostKeyChecking = "accept-new";
      };
    };
  };
}
