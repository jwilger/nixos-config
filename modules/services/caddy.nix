{ ... }:
{
  services.caddy = {
    enable = true;
    virtualHosts."git.johnwilger.com".extraConfig = ''
      reverse_proxy 127.0.0.1:3300
    '';
  };
}
