{ ... }: 
{
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
    };
  };
  # Enable systemd-resolved for DNS resolution
  services.resolved.enable = true;
}
