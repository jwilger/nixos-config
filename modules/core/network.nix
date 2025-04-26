{ host, pkgs, ... }: 
{
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" =
    if host == "gregor"
      then 0
    else null;

  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
    };
  };
  # Enable systemd-resolved for DNS resolution
  services.resolved.enable = true;

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
  ];
}
