# Printing configuration
{ pkgs, ... }:

{
  services = {
    system-config-printer.enable = true;
    printing = {
      enable = true;
      drivers = [pkgs.brlaser];
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  programs.system-config-printer = {
    enable = true;
  };
}