{
  inputs,
  pkgs,
  ...
}:
let
  # Import polkit 126 from pinned nixpkgs (127 breaks pam_u2f/YubiKey)
  # See: https://github.com/polkit-org/polkit/issues/622
  pkgs-polkit126 = import inputs.nixpkgs-polkit126 {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      polkit = pkgs-polkit126.polkit;
    })
  ];
}
