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
  };

  outputs = { nixpkgs, stylix, home-manager, ... } @ inputs: {
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
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.users.jwilger = import ./users/jwilger;
          }
        ];
      };
      
      # Template for adding a new host in the future:
      #
      # new-host = nixpkgs.lib.nixosSystem {
      #   specialArgs = { inherit inputs; };
      #   system = "x86_64-linux";  # Change as needed for the architecture
      #   modules = [
      #     ./hosts/new-host
      #     ./common
      #     # You can conditionally include modules based on the host type
      #     # ./modules/server    # For server configurations
      #     # ./modules/desktop   # For desktop configurations
      #     home-manager.nixosModules.home-manager {
      #       home-manager.useGlobalPkgs = false;
      #       home-manager.useUserPackages = true;
      #       # Configure which users exist on this host
      #       home-manager.users.jwilger = import ./users/jwilger/server.nix;  # Example of a server-specific config
      #       # home-manager.users.other-user = import ./users/other-user;
      #     }
      #   ];
      # };
    };
  };
}