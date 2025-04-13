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
      allowedTCPPorts = [22 80 443];
    };
  };

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
  ];
}
