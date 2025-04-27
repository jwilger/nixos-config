{...}: {
  imports =
    [
      (import ./../default.nix)
      (import ./firefox.nix)
      (import ./hyprland)
      (import ./insync)
      (import ./swaync)
      (import ./waybar)
      (import ./fuzzel.nix)
      (import ./kitty.nix)
      (import ./packages.nix)
      (import ./theme.nix)
    ];
}
