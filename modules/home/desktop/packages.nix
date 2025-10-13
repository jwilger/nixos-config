{ pkgs, ... }:
{
  home.packages = (
    with pkgs;
    [
      _1password-gui
      nixfmt-rfc-style
      pavucontrol # pulseaudio volume controle (GUI)
      slack
    ]
  );
}
