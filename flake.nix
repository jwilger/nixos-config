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
              default-nixos-builds =
                let
                  builds = {
                    gregor = self.nixosConfigurations.gregor.config.system.build.toplevel;
                  };
                in
                assert builtins.attrNames builds == [ "gregor" ];
                pkgs.emptyDirectory;
              no-kitten-ssh-alias-on-nixos =
                let
                  nixosHosts = [ "gregor" ];
                  hostsWithSshAlias = builtins.filter (
                    host:
                    self.nixosConfigurations.${host}.config.home-manager.users.jwilger.programs.zsh.shellAliases ? ssh
                  ) nixosHosts;
                in
                assert hostsWithSshAlias == [ ];
                pkgs.emptyDirectory;
              niri-screencast-portal =
                let
                  portalConfig = self.nixosConfigurations.gregor.config.xdg.portal.config.niri;
                in
                assert portalConfig.default == "gnome;gtk";
                assert portalConfig."org.freedesktop.impl.portal.Access" == "gtk";
                assert portalConfig."org.freedesktop.impl.portal.Notification" == "gtk";
                assert portalConfig."org.freedesktop.impl.portal.ScreenCast" == "gnome";
                assert portalConfig."org.freedesktop.impl.portal.Screenshot" == "gnome";
                assert portalConfig."org.freedesktop.impl.portal.Secret" == "gnome-keyring";
                pkgs.emptyDirectory;
              gregor-hindsight-sops =
                let
                  secret = self.nixosConfigurations.gregor.config.sops.secrets."hindsight/pg-password";
                  niriEnabled = self.nixosConfigurations.gregor.config.programs.niri.enable;
                in
                assert niriEnabled;
                assert secret.owner == "postgres";
                pkgs.emptyDirectory;
              gregor-tuple-screencast-modifier-compat =
                let
                  niriSettings =
                    self.nixosConfigurations.gregor.config.home-manager.users.jwilger.programs.niri.settings;
                in
                assert niriSettings.debug."force-pipewire-invalid-modifier";
                pkgs.emptyDirectory;
              gregor-noctalia-wallpaper =
                let
                  activation =
                    self.nixosConfigurations.gregor.config.home-manager.users.jwilger.home.activation.noctaliaWallpaperSeed.data;
                  liveActivation =
                    self.nixosConfigurations.gregor.config.home-manager.users.jwilger.home.activation.noctaliaWallpaperLive.data;
                  wallpaperPath = "${self.nixosConfigurations.gregor.config.home-manager.users.jwilger.home.homeDirectory}/.local/share/wallpapers/wallpaper.png";
                  niriSettings =
                    self.nixosConfigurations.gregor.config.home-manager.users.jwilger.programs.niri.settings;
                  hasWallpaperStartup = builtins.any (
                    entry: builtins.match ".*/noctalia-wallpaper" (builtins.head entry.command) != null
                  ) niriSettings.spawn-at-startup;
                in
                assert pkgs.lib.hasInfix ''"defaultWallpaper": "${wallpaperPath}"'' activation;
                assert pkgs.lib.hasInfix ''"dark": "${wallpaperPath}"'' activation;
                assert pkgs.lib.hasInfix ''"light": "${wallpaperPath}"'' activation;
                assert hasWallpaperStartup;
                assert pkgs.lib.hasInfix "systemctl --user start noctalia-wallpaper.service" liveActivation;
                pkgs.emptyDirectory;
            })
          );
    };
}
