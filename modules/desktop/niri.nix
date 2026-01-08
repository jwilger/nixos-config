{ pkgs, config, lib, ... }:
{
  # Enable niri compositor
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  # Use greetd with tuigreet for console-based login (better YubiKey support)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --cmd niri-session --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
        user = "greeter";
      };
    };
  };

  # Disable COSMIC greeter since we're using greetd
  services.displayManager.cosmic-greeter.enable = lib.mkForce false;

  # XDG portal configuration for niri (merges with existing portal config)
  xdg.portal = {
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-wlr
    ];
    config = {
      niri = {
        default = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.Screencast" = [ "wlr" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
      };
    };
  };

  # Environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Required services for noctalia-shell
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Polkit for privilege escalation
  security.polkit.enable = true;

  # Use lxqt polkit agent for themed password dialogs (picks up Qt/Catppuccin theme)
  systemd.user.services.polkit-lxqt-agent = {
    description = "LXQt Polkit Agent";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Packages needed for niri desktop
  environment.systemPackages = with pkgs; [
    xwayland-satellite # XWayland support for niri
    wl-clipboard
    swaylock # Screen locker
    swayidle # Idle management
    fuzzel # Application launcher (backup)
    nautilus # File manager
    grim # Screenshot utility
    slurp # Screen area selection
    brightnessctl # Brightness control
    playerctl # Media control
    pamixer # Audio control
    lxqt.lxqt-policykit # Themed polkit agent
  ];

  # PAM configuration for swaylock
  security.pam.services.swaylock = { };
}
