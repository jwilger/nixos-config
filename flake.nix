{
  description = "jwilger's nixos configuration";

  inputs = {
    auto-review.url = "git+https://git.johnwilger.com/Slipstream/auto_review?ref=main";

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

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zjstatus = {
      url = "github:dj95/zjstatus/053898e1e245c0df9aaaa783710e88e2926fbbb2";
    };

    noctalia = {
      # Pinned to pre-v5 release; v5 renamed programs.noctalia-shell → programs.noctalia
      # and replaced the JSON settings schema with TOML. Migrate modules/home/desktop/niri/
      # before bumping this pin.
      url = "github:noctalia-dev/noctalia-shell/da95089dfe5148ee7fb33b3faa314e86de1e6f25";
    };
  };

  outputs =
    {
      auto-review,
      catppuccin,
      niri,
      noctalia,
      nix-darwin,
      nixpkgs,
      self,
      sops-nix,
      ...
    }@inputs:
    {
      nixosConfigurations = {
        gregor = nixpkgs.lib.nixosSystem {
          modules = [
            auto-review.nixosModules.default
            catppuccin.nixosModules.catppuccin
            niri.nixosModules.niri
            sops-nix.nixosModules.sops
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
        sansa-vm = nixpkgs.lib.nixosSystem {
          modules = [
            catppuccin.nixosModules.catppuccin
            niri.nixosModules.niri
            (import ./hosts/sansa-vm)
          ];
          specialArgs = {
            host = "sansa-vm";
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

      checks =
        nixpkgs.lib.genAttrs
          [
            "aarch64-darwin"
            "aarch64-linux"
            "x86_64-linux"
          ]
          (
            system:
            let
              pkgs = import nixpkgs { inherit system; };
            in
            (nixpkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
              nixos-gregor = self.nixosConfigurations.gregor.config.system.build.toplevel;
              nixos-sansa-vm = self.nixosConfigurations.sansa-vm.config.system.build.toplevel;
              nixos-vm = self.nixosConfigurations.vm.config.system.build.toplevel;
              no-kitten-ssh-alias-on-nixos =
                let
                  nixosHosts = builtins.attrNames self.nixosConfigurations;
                  hostsWithSshAlias = builtins.filter (
                    host:
                    self.nixosConfigurations.${host}.config.home-manager.users.jwilger.programs.zsh.shellAliases ? ssh
                  ) nixosHosts;
                in
                assert hostsWithSshAlias == [ ];
                pkgs.emptyDirectory;
            })
            // (nixpkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
              darwin-darwin = self.darwinConfigurations.darwin.system;
              darwin-sansa = self.darwinConfigurations.sansa.system;
              darwin-bender = self.darwinConfigurations.bender.system;
              no-kitten-ssh-alias-on-darwin =
                let
                  darwinHosts = builtins.attrNames self.darwinConfigurations;
                  hostsWithSshAlias = builtins.filter (
                    host:
                    self.darwinConfigurations.${host}.config.home-manager.users.jwilger.programs.zsh.shellAliases ? ssh
                  ) darwinHosts;
                in
                assert hostsWithSshAlias == [ ];
                pkgs.emptyDirectory;
            })
          );
    };
}
