{ pkgs, ... }:
{
  home.packages = (
    with pkgs;
    [
      discord # chat for games
      kooha # simple screen recorder (Wayland/Portal)
      nixfmt-rfc-style
      pavucontrol # pulseaudio volume control (GUI)
    ]
  );
}
