{ pkgs, ... }:
{
  home.packages = (
    with pkgs;
    [
      cosmic-ext-applet-caffeine # caffeine applet for COSMIC desktop
      discord # chat for games
      kooha # simple screen recorder (Wayland/Portal)
      nixfmt-rfc-style
      pavucontrol # pulseaudio volume controle (GUI)
    ]
  );
}
