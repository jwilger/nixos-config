{ pkgs, ... }: 
{
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
  ];
}
