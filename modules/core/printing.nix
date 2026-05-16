{ lib, pkgs, ... }:
let
  # Brother HL-3070CW PostScript PPD file from OpenPrinting
  hl3070cwPPD = pkgs.runCommand "brother-hl3070cw-ppd" { } ''
    mkdir -p $out/share/cups/model
    cp ${./ppd/Brother-HL-3070CW-Postscript.ppd} $out/share/cups/model/Brother-HL-3070CW-Postscript.ppd
  '';
  supportsBrotherBinaryDrivers = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
{
  # Enable CUPS printing system
  services.printing = {
    enable = true;

    # Brother printer drivers
    # HL-3070CW is a PostScript color laser printer
    # Using both the generic drivers and the specific PPD file
    drivers = [
      hl3070cwPPD # Specific PPD for HL-3070CW PostScript
    ] ++ lib.optionals supportsBrotherBinaryDrivers [
      pkgs.brgenml1lpr # Brother LPR driver (for other Brother models)
      pkgs.brgenml1cupswrapper # Brother CUPS wrapper driver
    ];
  };

  # Enable network printer discovery via Avahi/mDNS
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Enable mDNS NSS support for printer discovery
    openFirewall = true;
  };
}
