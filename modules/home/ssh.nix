{ ... }:
let
  onePassPath = "~/.1password/agent.sock";
in
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
      };
    };

    extraConfig = ''
      # Use the stable socket path if SSH_AUTH_SOCK is not set
      # IdentityAgent has lower priority than SSH_AUTH_SOCK when both are set
      Host *
          IdentityAgent ${onePassPath}
    '';
  };
}
