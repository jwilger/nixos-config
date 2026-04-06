{ ... }:
{
  imports = [
    # ./iterm2.nix  # Not managing iTerm2 settings via Nix - too problematic
    ./wallpaper.nix
    ./packages.nix
  ];
}
