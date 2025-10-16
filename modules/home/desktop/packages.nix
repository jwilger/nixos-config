{ pkgs, ... }:
{
  home.packages = (
    with pkgs;
    [
      nixfmt-rfc-style
      pavucontrol # pulseaudio volume controle (GUI)
    ]
  );
}
