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
            catppuccin.nixosModules.catppuccin
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
              chromium-profile-routing =
                let
                  hm = self.nixosConfigurations.sansa-vm.config.home-manager.users.jwilger;
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
                  hasChromiumPictureInPictureRule = builtins.any (
                    rule:
                    builtins.any (match: match."app-id" == "^chromium$" && match.title == "^Picture-in-Picture$") (
                      rule.matches or [ ]
                    )
                  ) hm.programs.niri.settings.window-rules;
                in
                assert hasPackage "chromium";
                assert !(hasPackage "firefox");
                assert hasPackage "chrome-personal";
                assert hasPackage "chrome-work";
                assert hasPackage "chrome-pick";
                assert hasPackage "nignite";
                assert hm.xdg.desktopEntries."chrome-personal".name == "Chromium Personal";
                assert hm.xdg.desktopEntries."chrome-work".name == "Chromium Work";
                assert mimeDefaults."text/html" == [ "nignite.desktop" ];
                assert mimeDefaults."x-scheme-handler/http" == [ "nignite.desktop" ];
                assert mimeDefaults."x-scheme-handler/https" == [ "nignite.desktop" ];
                assert hasChromiumPictureInPictureRule;
                pkgs.runCommand "chromium-profile-routing" { } ''
                  grep -F -- '--profile-directory=Default' ${hm.home.path}/bin/chrome-personal
                  grep -F -- '--profile-directory="Profile 4"' ${hm.home.path}/bin/chrome-work
                  grep -F 'exec chrome-personal --new-window "$@"' ${hm.home.path}/bin/chrome-pick
                  grep -F 'exec chrome-work --new-window "$@"' ${hm.home.path}/bin/chrome-pick
                  grep -F 'niri msg action focus-window --id "$chrome_window_id"' ${hm.home.path}/bin/nignite
                  grep -F 'exec chrome-pick "$@"' ${hm.home.path}/bin/nignite
                  touch $out
                '';
              slack-client-by-architecture =
                let
                  gregorHm = self.nixosConfigurations.gregor.config.home-manager.users.jwilger;
                  sansaVmHm = self.nixosConfigurations.sansa-vm.config.home-manager.users.jwilger;
                  sansaVmPkgs = self.nixosConfigurations.sansa-vm.pkgs;
                  hasPackage =
                    hm: expected:
                    builtins.any (
                      package:
                      let
                        name = package.pname or (pkgs.lib.getName package);
                      in
                      name == expected
                    ) hm.home.packages;
                in
                assert !(hasPackage gregorHm "slack");
                assert !(hasPackage gregorHm "slacky");
                assert hasPackage sansaVmHm "slacky";
                assert !(hasPackage sansaVmHm "slack");
                assert
                  sansaVmHm.xdg.desktopEntries.slacky.exec
                  == "env NIXOS_OZONE_WL=1 ${sansaVmPkgs.slacky}/bin/slacky %U";
                pkgs.runCommand "slack-client-by-architecture" { } ''
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
              darwin-chromium-browser =
                let
                  casks = self.darwinConfigurations.darwin.config.homebrew.casks;
                  hasCask = expected: builtins.any (cask: cask.name == expected) casks;
                  activationScript = self.darwinConfigurations.darwin.config.system.activationScripts.script.text;
                in
                assert hasCask "chromium";
                assert !(hasCask "firefox");
                assert pkgs.lib.hasInfix "defaultbrowser chromium" activationScript;
                assert pkgs.lib.hasInfix "--set-home" activationScript;
                pkgs.emptyDirectory;
            })
          );
    };
}
