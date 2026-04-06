{
  description = "jwilger's nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };
    catppuccin-starship = {
      url = "github:catppuccin/starship";
      flake = false;
    };
    catppuccin = {
      url = "github:catppuccin/nix";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      catppuccin,
      niri,
      noctalia,
      nix-darwin,
      nixpkgs,
      self,
      ...
    }@inputs:
    {
      nixosConfigurations = {
        gregor = nixpkgs.lib.nixosSystem {
          modules = [
            catppuccin.nixosModules.catppuccin
            niri.nixosModules.niri
            (import ./hosts/gregor)
          ];
          specialArgs = {
            host = "gregor";
            username = "jwilger";
            inherit self inputs;
          };
        };
        vm = nixpkgs.lib.nixosSystem {
          modules = [
            catppuccin.nixosModules.catppuccin
            (import ./hosts/vm)
          ];
          specialArgs = {
            host = "vm";
            username = "jwilger";
            inherit self inputs;
          };
        };
      };

      darwinConfigurations = {
        darwin = nix-darwin.lib.darwinSystem {
          modules = [
            (import ./hosts/darwin)
          ];
          specialArgs = {
            host = "darwin";
            username = "jwilger";
            inherit self inputs;
          };
        };
        sansa = nix-darwin.lib.darwinSystem {
          modules = [
            (import ./hosts/sansa)
          ];
          specialArgs = {
            host = "sansa";
            username = "jwilger";
            inherit self inputs;
          };
        };
        bender = nix-darwin.lib.darwinSystem {
          modules = [
            (import ./hosts/bender)
          ];
          specialArgs = {
            host = "bender";
            username = "jwilger";
            inherit self inputs;
          };
        };
      };

      checks = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ] (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        (nixpkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          nixos-gregor = self.nixosConfigurations.gregor.config.system.build.toplevel;
          nixos-vm = self.nixosConfigurations.vm.config.system.build.toplevel;
        })
        // (nixpkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
          darwin-darwin = self.darwinConfigurations.darwin.system;
          darwin-sansa = self.darwinConfigurations.sansa.system;
          darwin-bender = self.darwinConfigurations.bender.system;
        })
      );
    };
}
