{
  pkgs,
  config,
  lib,
  ...
}:
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

  # XDG portal configuration for niri
  # Note: niri is NOT wlroots-based (it uses Smithay), so xdg-desktop-portal-wlr won't work
  # niri-flake automatically configures portals via configPackages (installs niri-portals.conf)
  # We just need to ensure xdg-desktop-portal-gnome is available for screencasting
  xdg.portal = {
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
    ];
    # Explicitly select the GNOME backend for niri's Smithay ScreenCast API.
    # This prevents the portal frontend from falling back to an implementation
    # that does not provide ScreenCast when the niri config package is absent.
    config.niri = {
      default = [
        "gnome"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Access" = "gtk";
      "org.freedesktop.impl.portal.Notification" = "gtk";
      "org.freedesktop.impl.portal.ScreenCast" = "gnome";
      "org.freedesktop.impl.portal.Screenshot" = "gnome";
      "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
    };
  };

  # Environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    # Cursor settings for XWayland apps (Slack, Electron apps, etc.)
    XCURSOR_SIZE = "24";
    XCURSOR_THEME = "Vanilla-DMZ";
  };

  # Required services for Noctalia
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Polkit for privilege escalation
  security.polkit.enable = true;

  # Packages needed for niri desktop
  environment.systemPackages = with pkgs; [
    xwayland-satellite # XWayland support for niri
    wl-clipboard
    fuzzel # Application launcher (backup)
    nautilus # File manager
    grim # Screenshot utility
    slurp # Screen area selection
    brightnessctl # Brightness control
    playerctl # Media control
    pamixer # Audio control
  ];
}
