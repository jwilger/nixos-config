{
  description = "jwilger's nixos configuration";

  inputs = {
    auto-review.url = "git+https://github.com/jwilger/auto_review.git?ref=main";

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
      # Use upstream's Cachix-backed branch and keep its own nixpkgs input.
      # Following this flake's nixpkgs changes the derivation hash and misses
      # the upstream binary cache.
      url = "github:noctalia-dev/noctalia/cachix";
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
            auto-review.nixosModules.default
            catppuccin.nixosModules.catppuccin
            niri.nixosModules.niri
            sops-nix.nixosModules.sops
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
              chrome-profile-launching =
                let
                  hm = self.nixosConfigurations.gregor.config.home-manager.users.jwilger;
                  hasPackage =
                    expected:
                    builtins.any (
                      package:
                      let
                        name = package.pname or (pkgs.lib.getName package);
                      in
                      name == expected
                    ) hm.home.packages;
                  mimeDefaults = hm.xdg.mimeApps.defaultApplications;
                in
                assert hasPackage "nignite";
                assert hasPackage "chrome-personal";
                assert hasPackage "chrome-work";
                assert hasPackage "chrome-pick";
                assert hm.xdg.desktopEntries."chrome-personal".name == "Chrome Personal";
                assert hm.xdg.desktopEntries."chrome-personal".noDisplay == false;
                assert hm.xdg.desktopEntries."chrome-work".name == "Chrome Work";
                assert hm.xdg.desktopEntries."chrome-work".noDisplay == false;
                assert hm.xdg.desktopEntries."google-chrome".noDisplay == true;
                assert mimeDefaults."text/html" == [ "nignite.desktop" ];
                assert mimeDefaults."x-scheme-handler/http" == [ "nignite.desktop" ];
                assert mimeDefaults."x-scheme-handler/https" == [ "nignite.desktop" ];
                assert hm.programs.kitty.settings.open_url_with == "nignite";
                pkgs.runCommand "chrome-profile-launching" { } ''
                  grep -F 'exec chrome-personal --new-window "$@"' ${hm.home.path}/bin/chrome-pick
                  grep -F 'exec chrome-work --new-window "$@"' ${hm.home.path}/bin/chrome-pick
                  grep -F 'niri msg action focus-window --id "$chrome_window_id"' ${hm.home.path}/bin/nignite
                  grep -F 'exec chrome-pick "$@"' ${hm.home.path}/bin/nignite
                  touch $out
                '';
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
