{
  description = "NixOS System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # macOS support
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, stylix, home-manager, darwin, ... } @ inputs: {
    # Set global nixpkgs configuration for the flake
    nixpkgs.config = {
      allowUnfree = true;
    };
    
    # Define reusable configurations for all NixOS systems in the flake
    nixosModules.default = {
      nixpkgs.config.allowUnfree = true;
    };
    
    nixosConfigurations = {
      # Current host configuration
      gregor = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-linux";
        modules = [
          {
            nix.settings = {
              substituters = [ "https://hyprland.cachix.org/" ];
              trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
            };
          }
          stylix.nixosModules.stylix
          ./hosts/gregor
          ./common
          ./modules/1password.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.users.jwilger = import ./users/jwilger;
          }
        ];
      };
    };
    
    # Darwin (macOS) configurations
    darwinConfigurations = {
      sansa = darwin.lib.darwinSystem {
        system = "aarch64-darwin"; # For Apple Silicon Macs (M1/M2/M3)
        # If using an Intel Mac, change to "x86_64-darwin"
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/sansa
          ./common/darwin.nix
          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.users.jwilger = import ./users/jwilger/darwin.nix; # Use darwin-specific config
          }
        ];
      };
    };
  };
}
