{ pkgs, ... }:
{
  # macOS-specific packages
  # Most GUI apps are installed via Homebrew casks
  # This file is for nix packages that need to be available on macOS

  home.packages = with pkgs; [
    # macOS-specific CLI tools can go here if needed
  ];
}
