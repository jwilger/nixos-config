{ pkgs, ... }:
{
  # Enable CUPS printing system
  services.printing = {
    enable = true;

    # Brother printer drivers
    # HL-3070CW is a PostScript color laser printer, requires proprietary drivers
    drivers = [
      pkgs.brgenml1lpr        # Brother LPR driver
      pkgs.brgenml1cupswrapper # Brother CUPS wrapper driver
    ];
  };

  # Enable network printer discovery via Avahi/mDNS
  services.avahi = {
    enable = true;
    nssmdns4 = true;  # Enable mDNS NSS support for printer discovery
    openFirewall = true;
  };
}
