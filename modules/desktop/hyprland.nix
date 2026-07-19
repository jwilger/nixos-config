{
  lib,
  pkgs,
  ...
}:
{
  programs.hyprland = {
    enable = true;
    withUWSM = false;
    xwayland.enable = true;
  };

  services.greetd.settings.default_session.command = lib.mkForce (
    "${pkgs.tuigreet}/bin/tuigreet --time --remember "
    + "--cmd start-hyprland "
    + "--sessions ${pkgs.hyprland}/share/wayland-sessions"
  );

  xdg.portal.config.hyprland = {
    default = [
      "hyprland"
      "gtk"
    ];
    "org.freedesktop.impl.portal.Access" = "gtk";
    "org.freedesktop.impl.portal.Notification" = "gtk";
    "org.freedesktop.impl.portal.ScreenCast" = "hyprland";
    "org.freedesktop.impl.portal.Screenshot" = "hyprland";
    "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
  };
}
