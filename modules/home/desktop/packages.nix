{ pkgs, ... }:
{
  home.packages = (
    with pkgs;
    [
      cosmic-ext-applet-caffeine # caffeine applet for COSMIC desktop
      discord # chat for games
      nixfmt-rfc-style
      pavucontrol # pulseaudio volume controle (GUI)
    ]
  );
}
