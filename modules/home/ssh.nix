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
        identityAgent = "/Users/jwilger/.ssh/agent-local.sock";
        extraOptions = {
          PreferredAuthentications = "publickey";
          StrictHostKeyChecking = "accept-new";
        };
      };
    };
  };
}
