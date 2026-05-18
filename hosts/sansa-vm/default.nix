{
  pkgs,
  lib,
  username,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    ./../../modules/desktop
  ];

  networking.hostName = "sansa-vm";

  # Apple Silicon VMs run the NixOS aarch64 installer natively.
  nixpkgs.hostPlatform = "aarch64-linux";

  # The generated x86 VM profile uses kvm-intel; this host is arm64.
  boot.kernelModules = lib.mkForce [ ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  boot.loader.efi = {
    canTouchEfiVariables = lib.mkForce false;
    efiSysMountPoint = "/boot";
  };

  # qemu/UTM-style VMs commonly expose the disk as /dev/vda.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.useOSProber = false;

  # Allow local remote access to make it easier to toy around with the system.
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = lib.mkForce true;
    };
  };

  users.users."${username}".initialPassword = "test";

  virtualisation.vmVariant = {
    virtualisation.graphics = true;
    services.timesyncd.enable = lib.mkForce true;
  };

  catppuccin.enable = lib.mkForce false;

  home-manager.users.${username}.imports = [ ./../../modules/home/desktop ];

  environment.systemPackages = with pkgs; [
    mesa-demos
    eglinfo
    vulkan-tools
    foot
    wezterm
  ];
}
