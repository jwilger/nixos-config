{ ... }:
{
  imports = [
    (import ./../default.nix)
    (import ./firefox.nix)
    (import ./hyprland)
    (import ./insync)
    (import ./swaync)
    (import ./waybar)
    (import ./fuzzel.nix)
    (import ./kitty.nix)
    # (import ./wezterm.nix)  # Disabled - using kitty instead
    (import ./spotify.nix)
    (import ./zoom.nix)
    (import ./packages.nix)
    (import ./theme.nix)
  ];
}
