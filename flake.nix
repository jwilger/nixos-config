{
  description = "NixOX System Configuration";

  inputs = {
    hyprland.url = "github:hyprwm/Hyprland";
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
    stylix.url = "github:danth/stylix";
  };

  outputs = {
    nixpkgs,
    stylix,
    ...
  } @ inputs: {
    nixosConfigurations = {
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
          ./configuration.nix
        ];
      };
    };
  };
}
