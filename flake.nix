{
  description = "NixOX System Configuration";

  inputs = {
    nixpkgs = {
      url = "github:NixOs/nixpkgs/nixos-unstable";
    };
  };

  outputs = {self, nixpkgs}: {
    nixosConfigurations = {
      gregor = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
	modules = [
	  ./configuration.nix
	];
      };
    };
  };
}
