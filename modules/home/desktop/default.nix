{ ... }:
{
  imports = [
    (import ./../default.nix)
    (import ./cosmic.nix)
    (import ./firefox.nix)
    (import ./insync)
    (import ./kitty.nix)
    (import ./spotify.nix)
    (import ./zoom.nix)
    (import ./packages.nix)
  ];
}
