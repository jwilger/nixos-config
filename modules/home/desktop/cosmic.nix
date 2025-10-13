{ config, ... }:
{
  # Create a direct symlink from ~/.config/cosmic to /etc/nixos/modules/home/desktop/cosmic
  # This allows editing Cosmic settings in place without rebuilding NixOS
  home.file.".config/cosmic".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/home/desktop/cosmic";
}
