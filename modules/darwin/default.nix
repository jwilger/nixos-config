{
  pkgs,
  inputs,
  username,
  host,
  ...
}:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ./system.nix
    ./homebrew.nix
  ];

  # Home Manager configuration
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "before-hm";
    extraSpecialArgs = {
      inherit inputs username host;
    };
    sharedModules = [
      inputs.catppuccin.homeModules.catppuccin
    ];
  };

  # Nix settings
  nix = {
    enable = true;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      ssl-cert-file = "/etc/ssl/cert.pem";
      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
    optimise.automatic = true;
    gc = {
      automatic = true;
      interval = {
        Weekday = 7;
      };
      options = "--delete-older-than 7d";
    };
  };

  system.primaryUser = username;

  nixpkgs.config.allowUnfree = true;

  # direnv's upstream test suite hangs in the macOS Nix sandbox (zsh test
  # spawns an interactive shell that never exits). Skip it so we don't wedge
  # rebuilds when cache.nixos.org hasn't yet published the binary.
  nixpkgs.overlays = [
    (_: prev: {
      direnv = prev.direnv.overrideAttrs (_: { doCheck = false; });
    })
  ];
}
