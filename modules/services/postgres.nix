{ lib, ... }:
{
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "forgejo"
      "teamcity"
    ];
    ensureUsers = [
      {
        name = "forgejo";
        ensureDBOwnership = true;
      }
      {
        name = "teamcity";
        ensureDBOwnership = true;
      }
    ];
    # Forgejo uses peer auth via the Unix socket. TeamCity's JDBC driver
    # can't speak Unix sockets, so it connects over TCP. Trust loopback
    # for the teamcity user/db pair only — no password to manage on a
    # single-user box.
    authentication = lib.mkBefore ''
      host  teamcity  teamcity  127.0.0.1/32  trust
      host  teamcity  teamcity  ::1/128       trust
    '';
  };
}
