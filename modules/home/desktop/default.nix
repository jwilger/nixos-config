{ ... }:
{
  imports = [
    (import ./../default.nix)
    (import ./cosmic.nix)
    (import ./firefox.nix)
    (import ./insync)
    (import ./kitty.nix)
    (import ./onepassword.nix)
    (import ./spotify.nix)
    (import ./slack.nix)
    (import ./vlc.nix)
    (import ./zoom.nix)
    (import ./packages.nix)
    (import ./obs-studio.nix)
  ];
}
