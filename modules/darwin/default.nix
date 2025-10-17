{ pkgs, inputs, username, ... }:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.catppuccin.darwinModules.catppuccin
    ./system.nix
    ./homebrew.nix
  ];

  # Catppuccin theme system-wide
  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "lavender";
  };

  # Home Manager configuration
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs username; };
  };

  # Nix settings
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
    gc = {
      automatic = true;
      interval = { Weekday = 7; };
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs.config.allowUnfree = true;
}
