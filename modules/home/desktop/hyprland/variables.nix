{ ... }:
{
  home.sessionVariables = {
    # Prefer Wayland backends for various toolkits
    XDG_SESSION_TYPE = "wayland";
    GDK_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";

    # Qt scaling and platform
    QT_QPA_PLATFORM = "wayland";
    QT_AUTO_SCREEN_SCALE_FACTOR = "0"; # disable auto-scaling
    QT_SCALE_FACTOR = "2"; # force 2x scale on Qt apps

    # Electron/Chromium (VSCode, 1Password, etc.) Wayland support
    ELECTRON_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1"; # (NixOS-specific hint for electron apps)

    # Cursor theme and size (for HiDPI, size 24 gets doubled to 48px)
    XCURSOR_THEME = "Catppuccin-Mocha-Lavender-Cursors";
    XCURSOR_SIZE = "48";
  };
}
