{ pkgs, ... }:
{
  home.packages = (
    with pkgs;
    [
      cosmic-ext-applet-caffeine # caffeine applet for COSMIC desktop
      nixfmt-rfc-style
      pavucontrol # pulseaudio volume controle (GUI)
    ]
  );
}
