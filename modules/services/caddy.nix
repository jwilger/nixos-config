{ ... }:
{
  services.caddy = {
    enable = true;
    virtualHosts."git.johnwilger.com".extraConfig = ''
      reverse_proxy 127.0.0.1:3300
    '';
    virtualHosts."dev.auto-review.johnwilger.com".extraConfig = ''
      reverse_proxy 127.0.0.1:8090
    '';
    virtualHosts."auto-review.johnwilger.com".extraConfig = ''
      reverse_proxy 127.0.0.1:8080
    '';
  };
}
