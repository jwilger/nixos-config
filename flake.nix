{
  description = "NixOX System Configuration";

  inputs = {
    hyprland.url = "github:hyprwm/Hyprland";
    nixpkgs = {
      url = "github:NixOs/nixpkgs/nixos-unstable";
      follows = "nixos-cosmic/nixpkgs";
    };
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
    };
    stylix = {
      url = "github:danth/stylix";
    };
  };

  outputs = {
    nixpkgs,
    nixos-cosmic,
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
	      substituters = [ "https://cosmic.cachix.org/" "https://hyprland.cachix.org/" ];
	      trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
	    };
	  }
	  nixos-cosmic.nixosModules.default
          stylix.nixosModules.stylix
          ./configuration.nix
        ];
      };
    };
  };
}
