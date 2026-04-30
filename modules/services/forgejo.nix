{ config, lib, ... }:
{
  # Expose the forgejo CLI system-wide so admin commands like
  # `sudo -u forgejo forgejo admin user create …` work without
  # hardcoded /nix/store paths.
  environment.systemPackages = [ config.services.forgejo.package ];

  services.forgejo = {
    enable = true;
    stateDir = "/home/forgejo";
    database = {
      type = "postgres";
      socket = "/run/postgresql";
      user = "forgejo";
      name = "forgejo";
    };
    settings = {
      server = {
        DOMAIN = "git.johnwilger.com";
        ROOT_URL = "https://git.johnwilger.com/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3300;
        SSH_PORT = 2222;
        START_SSH_SERVER = true;
        SSH_LISTEN_HOST = "0.0.0.0";
      };
      service.DISABLE_REGISTRATION = true;
      security.INSTALL_LOCK = true;
    };
  };

  # The upstream forgejo module sets ProtectHome=true, which hides /home
  # from the unit's mount namespace. We put stateDir on /home so it
  # rides along on btrbk's nightly /home → /archive snapshots, so we
  # need /home visible to the unit.
  systemd.services.forgejo.serviceConfig.ProtectHome = lib.mkForce false;
}
