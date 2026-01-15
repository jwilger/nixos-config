{ pkgs, ... }:
{
  home.packages = (
    with pkgs;
    [
      discord # chat for games
      pavucontrol # pulseaudio volume control (GUI)
      gpu-screen-recorder
    ]
  );
}
