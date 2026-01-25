{
  description = "jwilger's nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    # Pinned nixpkgs with polkit 126 (127 breaks pam_u2f/YubiKey)
    # See: https://github.com/polkit-org/polkit/issues/622
    nixpkgs-polkit126.url = "github:NixOS/nixpkgs/1412caf7bf9e660f2f962917c14b1ea1c3bc695e";

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
            (import ./overlays.nix)
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
            (import ./overlays.nix)
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
            catppuccin.nixosModules.catppuccin
            (import ./overlays.nix)
            (import ./hosts/darwin)
          ];
          specialArgs = {
            host = "darwin";
            username = "jwilger";
            inherit self inputs;
          };
        };
      };
    };
}
