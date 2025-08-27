{ pkgs, ... }:
{
  home.packages = (
    with pkgs;
    [
      _1password-gui
      evince # gnome pdf viewer
      imv # image viewer
      mpv # video player
      nautilus # file manager
      nomachine-client # remote screen on other computers
      pavucontrol # pulseaudio volume controle (GUI)
      playerctl # controller for media players
      qalculate-gtk # calculator
      nixfmt-rfc-style
      vscode-fhs
    ]
  );
}
