{ ... }:

# Gaming Module - Re-export
#
# This module re-exports the Steam gaming configuration.
# Keeps the gaming subdirectory organized while allowing
# future expansion (e.g., lutris.nix, heroic.nix).

{
  imports = [
    ./steam.nix
  ];
}
