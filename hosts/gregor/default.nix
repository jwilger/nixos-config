{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "gregor"; # Define hostname
    networkmanager.enable = true;
    nftables.enable = true;
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 80 443 ];
  };

  # Bootloader configuration specific to this host
  boot = {
    plymouth = {
      enable = true;
      theme = lib.mkForce "rings";
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "rings" ];
        })
      ];
    };
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelParams = [ "quiet" "splash" "boot.shell_on_fail" "loglevel=3" "rd.systemd.show_status=false" "rd.udev.log_level=3" "udev.log_priority=3" ];
    loader.timeout = 0;
  };

  # Enable ZSH for the user
  programs.zsh.enable = true;

  # Host-specific users
  users.users = {
    jwilger = {
      isNormalUser = true;
      description = "John Wilger";
      extraGroups = ["networkmanager" "wheel" "docker"];
      shell = pkgs.zsh;
      home = "/home/jwilger";
      group = "jwilger";
      createHome = true;
      linger = true;
    };
  };

  users.groups.jwilger = {};

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    usbutils    # Specific to this machine
    udiskie     # Specific to this machine
    udisks      # Specific to this machine
  ];
}