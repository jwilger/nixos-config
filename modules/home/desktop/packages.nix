{ pkgs, ... }:
{
  home.packages = (
    with pkgs;
    [
      _1password-gui
      pavucontrol # pulseaudio volume controle (GUI)
      nixfmt-rfc-style
    ]
  );
}
