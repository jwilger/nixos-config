{
  description = "NixOX System Configuration";

  inputs = {
    nixpkgs = {
      url = "github:NixOs/nixpkgs/nixos-unstable";
    };
    stylix = {
      url = "github:danth/stylix";
    };
  };

  outputs = { nixpkgs, stylix, ... }: {
    nixosConfigurations = {
      gregor = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          stylix.nixosModules.stylix
          ./configuration.nix
        ];
      };
    };
  };
}
