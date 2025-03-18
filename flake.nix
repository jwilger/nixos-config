{
  description = "NixOX System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    stylix,
    home-manager,
    ...
    }: {
      nixosConfigurations = {
        gregor = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            {
              nixpkgs.config.allowUnfree = true;
            }
            stylix.nixosModules.stylix
            ./configuration.nix
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";

              home-manager.users.jwilger = import ./home.nix;
            }
            ({lib, ...}: {
              nix.registry.nixpkgs.flake = nixpkgs;
            })
          ];
        };
      };
    };
}
