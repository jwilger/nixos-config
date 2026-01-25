{ lib, username, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  # kvm/qemu doesn't use UEFI firmware mode by default.
  # so we force-override the setting here
  # and configure GRUB instead.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = false;

  # allow local remote access to make it easier to toy around with the system
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = lib.mkForce true;
    };
  };

  users.users."${username}".initialPassword = "test";

  virtualisation.vmVariant = {
    virtualisation.graphics = false;
    services.timesyncd.enable = lib.mkForce true;
  };

  home-manager.users.${username}.imports = [ ./../../modules/home ];
}
