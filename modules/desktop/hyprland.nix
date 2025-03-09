# Hyprland desktop environment
{ inputs, pkgs, lib, ... }:

let
  pkgs-unstable = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  hardware.graphics = {
    package = pkgs-unstable.mesa.drivers;
    package32 = pkgs-unstable.pkgsi686Linux.mesa.drivers;
    enable32Bit = true;
  };

  # Hyprland-related services and packages
  services = {
    gvfs.enable = true;
    udisks2.enable = true;
    devmon.enable = true;
    udev.enable = true;
    
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd 'uwsm start default'";
          user = "greeter";
        };
      };
    };
    
    gnome.gnome-keyring = {
      enable = true;
    };
  };

  # Interception tools for keyboard remapping
  services.interception-tools =
  let
    itools = pkgs.interception-tools;
    itools-caps = pkgs.interception-tools-plugins.caps2esc;
  in
  {
    enable = true;
    plugins = [ itools-caps ];
    udevmonConfig = pkgs.lib.mkDefault ''
      - JOB: "${itools}/bin/intercept -g $DEVNODE | ${itools-caps}/bin/caps2esc -m 0 | ${itools}/bin/uinput -d $DEVNODE"
        DEVICE:
          EVENTS:
            EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
    '';
  };

  # Hyprland and related programs
  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      xwayland = {
        enable = true;
      };
      withUWSM = true;
    };

    hyprlock.enable = true;
  };

  environment.systemPackages = with pkgs; [
    kitty
    grim
    slurp
    solaar
    firefoxpwa
    neovim
  ];

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    nativeMessagingHosts.packages = [pkgs.firefoxpwa];
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Hardware-specific configuration for Logitech devices
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };
}