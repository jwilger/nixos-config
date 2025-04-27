{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.consoleLogLevel = 0;
  # Kernel parameters: reduce verbosity and enable user xattr for overlayfs
  boot.kernelParams = [
    "quiet"
    "splash"
    "udev.log_level=3"
    "userxattr"
  ];
  boot.initrd.verbose = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.plymouth = {
    enable = true;
  };
  # Increase timeout to allow boot entry selection
  boot.loader.timeout = 5;
}
