{ ... }:
{
  imports = [
    (import ./../default.nix)
    (import ./niri)
    (import ./insync)
    (import ./nignite.nix)
    (import ./onepassword.nix)
    (import ./spotify.nix)
    (import ./slack.nix)
    (import ./vlc.nix)
    (import ./zoom.nix)
    (import ./packages.nix)
    (import ./obs-studio.nix)
  ];
}
