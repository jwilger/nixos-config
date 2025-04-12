{inputs, username, host, ...}: {
  imports =
    [
      (import ./default.nix)
      (import ./firefox.nix)
      (import ./unity.nix)
    ];
}
