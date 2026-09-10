{
  description = "jwilger's Gregor NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    catppuccin.url = "github:catppuccin/nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jwilger-home = {
      url = "github:jwilger/home/eb3ae4123b5180a3123e613ba08912befebed983";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      catppuccin,
      nixpkgs,
      self,
      sops-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations.gregor = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          catppuccin.nixosModules.catppuccin
          sops-nix.nixosModules.sops
          ./hosts/gregor
        ];
        specialArgs = {
          host = "gregor";
          username = "jwilger";
          inherit inputs self;
        };
      };

      checks.${system} = {
        gregor = self.nixosConfigurations.gregor.config.system.build.toplevel;
        gregor-home =
          assert
            self.nixosConfigurations.gregor.config.home-manager.users.jwilger.jwilger.hostProfile == "gregor";
          self.nixosConfigurations.gregor.config.home-manager.users.jwilger.home.activationPackage;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
