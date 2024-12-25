{
  description = "NixOX System Configuration";

  inputs = {
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
  }: {
    nixosConfigurations = {
      gregor = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
	  {
	    nix.settings = {
	      substituters = [ "https://cosmic.cachix.org/" ];
	      trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
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
