{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        ForwardAgent = true;
      };

      "github.com" = {
        User = "git";
      };

      "ubuntu-2510-dev" = {
        HostName = "127.0.0.1";
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
