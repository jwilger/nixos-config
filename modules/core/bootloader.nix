{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.consoleLogLevel = 0;
  boot.kernelParams = ["quiet" "udev.log_level=3"];
  boot.initrd.verbose = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.plymouth = {
    enable = true;
  };
  boot.loader.timeout = 1;
}
