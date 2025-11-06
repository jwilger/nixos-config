{
  description = "jwilger's nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    beads = {
      url = "github:steveyegge/beads";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
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
  };

  outputs =
    {
      catppuccin,
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
            (import ./overlays.nix)
            (import ./hosts/gregor)
          ];
          specialArgs = {
            host = "gregor";
            system = "x86_64-linux";
            username = "jwilger";
            inherit self inputs;
          };
        };
        vm = nixpkgs.lib.nixosSystem {
          modules = [
            catppuccin.nixosModules.catppuccin
            (import ./overlays.nix)
            (import ./hosts/vm)
          ];
          specialArgs = {
            host = "vm";
            system = "x86_64-linux";
            username = "jwilger";
            inherit self inputs;
          };
        };
      };

      darwinConfigurations = {
        darwin = nix-darwin.lib.darwinSystem {
          modules = [
            catppuccin.nixosModules.catppuccin
            (import ./overlays.nix)
            (import ./hosts/darwin)
          ];
          specialArgs = {
            host = "darwin";
            system = "aarch64-darwin";
            username = "jwilger";
            inherit self inputs;
          };
        };
      };
    };
}
