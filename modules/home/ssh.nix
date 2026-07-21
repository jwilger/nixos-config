{ pkgs, ... }:
let
  darwinOnePasswordAgentSock = "~/Library/Group\\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        ForwardAgent = true;
        IdentityAgent = if pkgs.stdenv.isLinux then "SSH_AUTH_SOCK" else darwinOnePasswordAgentSock;
      };
    };
  };
}
