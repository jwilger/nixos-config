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

    lanyard = {
      url = "github:jwilger/lanyard-ssh-agent/v0.1.2";
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
              gregor-hyprland-only =
                let
                  gregorConfig = self.nixosConfigurations.gregor.config;
                  sessionNames = map (
                    package: package.pname or package.name
                  ) gregorConfig.services.displayManager.sessionPackages;
                in
                assert gregorConfig.programs.hyprland.enable;
                assert sessionNames == [ "hyprland" ];
                pkgs.emptyDirectory;
              hyprland-default-session =
                let
                  gregorConfig = self.nixosConfigurations.gregor.config;
                in
                assert gregorConfig.services.greetd.enable;
                assert pkgs.lib.hasInfix "--cmd start-hyprland"
                  gregorConfig.services.greetd.settings.default_session.command;
                assert
                  !pkgs.lib.hasInfix "--remember-user-session" gregorConfig.services.greetd.settings.default_session.command;
                pkgs.emptyDirectory;
              hyprland-screencast-portal =
                let
                  portalConfig = self.nixosConfigurations.gregor.config.xdg.portal.config.hyprland;
                in
                assert portalConfig.default == "hyprland;gtk";
                assert portalConfig."org.freedesktop.impl.portal.Access" == "gtk";
                assert portalConfig."org.freedesktop.impl.portal.Notification" == "gtk";
                assert portalConfig."org.freedesktop.impl.portal.ScreenCast" == "hyprland";
                assert portalConfig."org.freedesktop.impl.portal.Screenshot" == "hyprland";
                assert portalConfig."org.freedesktop.impl.portal.Secret" == "gnome-keyring";
                pkgs.emptyDirectory;
              gregor-hyprland-scrolling-workflow =
                let
                  hyprlandConfig =
                    self.nixosConfigurations.gregor.config.home-manager.users.jwilger.wayland.windowManager.hyprland;
                  bindKeys = map (bind: builtins.elemAt bind._args 0) hyprlandConfig.settings.bind;
                  workspaceNames = map (
                    rule: (builtins.elemAt rule._args 0).workspace
                  ) hyprlandConfig.settings.workspace_rule;
                in
                assert hyprlandConfig.enable;
                assert hyprlandConfig.configType == "lua";
                assert hyprlandConfig.settings.config.general.layout == "scrolling";
                assert hyprlandConfig.settings.config.input.natural_scroll;
                assert hyprlandConfig.settings.config.scrolling.column_width == 0.5;
                assert hyprlandConfig.settings.config.scrolling.explicit_column_widths == "0.333, 0.5, 0.667";
                assert hyprlandConfig.settings.config.scrolling.focus_fit_method == 1;
                assert !hyprlandConfig.settings.config.scrolling.wrap_focus;
                assert !hyprlandConfig.settings.config.scrolling.wrap_swapcol;
                assert builtins.all (key: builtins.elem key bindKeys) [
                  "SUPER + RETURN"
                  "SUPER + SPACE"
                  "SUPER + H"
                  "SUPER + SHIFT + H"
                  "SUPER + 1"
                  "SUPER + SHIFT + 1"
                  "SUPER + PRINT"
                  "SUPER + V"
                  "SUPER + SHIFT + V"
                ];
                assert workspaceNames == map builtins.toString (pkgs.lib.range 1 9);
                pkgs.emptyDirectory;
              gregor-hyprland-noctalia-session =
                let
                  userServices =
                    self.nixosConfigurations.gregor.config.home-manager.users.jwilger.systemd.user.services;
                in
                assert userServices.noctalia-hyprland.Install.WantedBy == [ "hyprland-session.target" ];
                assert userServices.noctalia-wallpaper.Install.WantedBy == [ "hyprland-session.target" ];
                assert userServices.onepassword-hyprland.Install.WantedBy == [ "hyprland-session.target" ];
                assert builtins.elem "noctalia-hyprland.service" userServices.noctalia-wallpaper.Unit.After;
                pkgs.emptyDirectory;
              gregor-noctalia-notification-bindings =
                let
                  homeConfig = self.nixosConfigurations.gregor.config.home-manager.users.jwilger;
                  hyprlandBinds = homeConfig.wayland.windowManager.hyprland.settings.bind;
                  hyprlandCommand =
                    key:
                    ((builtins.elemAt
                      (builtins.head (builtins.filter (bind: builtins.elemAt bind._args 0 == key) hyprlandBinds))._args
                      1
                    ).expr
                    );
                in
                assert hyprlandCommand "SUPER + N" == ''hl.dsp.exec_cmd("noctalia msg notification-clear-active")'';
                assert
                  hyprlandCommand "SUPER + SHIFT + N" == ''hl.dsp.exec_cmd("noctalia msg notification-dnd-toggle")'';
                pkgs.emptyDirectory;
              gregor-noctalia-restores-focus-after-unlock =
                let
                  noctaliaConfig = builtins.fromTOML (builtins.readFile ./modules/home/desktop/noctalia/config.toml);
                  noctaliaState = builtins.fromTOML (builtins.readFile ./modules/home/desktop/noctalia/settings.toml);
                in
                assert noctaliaConfig.hooks.session_unlocked == "restore-window-focus";
                assert noctaliaState.hooks.session_unlocked == "restore-window-focus";
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
              gregor-lanyard-ssh-agent =
                let
                  homeConfig = self.nixosConfigurations.gregor.config.home-manager.users.jwilger;
                  service = homeConfig.systemd.user.services.lanyard-ssh-agent.Service;
                in
                assert homeConfig.programs.lanyard-ssh-agent.enable;
                assert homeConfig.programs.ssh.settings."*".data.IdentityAgent == "SSH_AUTH_SOCK";
                assert builtins.any (
                  command: pkgs.lib.hasInfix ''"serve" "--upstream" "/home/jwilger/.1password/agent.sock"'' command
                ) service.ExecStart;
                assert pkgs.lib.hasSuffix "export SSH_AUTH_SOCK=\"$XDG_RUNTIME_DIR/lanyard-ssh-agent/agent.sock\"\n"
                  homeConfig.programs.zsh.initContent;
                pkgs.emptyDirectory;
              gregor-hindsight-sops =
                let
                  secret = self.nixosConfigurations.gregor.config.sops.secrets."hindsight/pg-password";
                in
                assert secret.owner == "postgres";
                pkgs.emptyDirectory;
              gregor-noctalia-wallpaper =
                let
                  activation =
                    self.nixosConfigurations.gregor.config.home-manager.users.jwilger.home.activation.noctaliaWallpaperSeed.data;
                  liveActivation =
                    self.nixosConfigurations.gregor.config.home-manager.users.jwilger.home.activation.noctaliaWallpaperLive.data;
                  wallpaperPath = "${self.nixosConfigurations.gregor.config.home-manager.users.jwilger.home.homeDirectory}/.local/share/wallpapers/wallpaper.png";
                  userServices =
                    self.nixosConfigurations.gregor.config.home-manager.users.jwilger.systemd.user.services;
                in
                assert pkgs.lib.hasInfix ''"defaultWallpaper": "${wallpaperPath}"'' activation;
                assert pkgs.lib.hasInfix ''"dark": "${wallpaperPath}"'' activation;
                assert pkgs.lib.hasInfix ''"light": "${wallpaperPath}"'' activation;
                assert userServices.noctalia-wallpaper.Install.WantedBy == [ "hyprland-session.target" ];
                assert pkgs.lib.hasInfix "systemctl --user start noctalia-wallpaper.service" liveActivation;
                pkgs.emptyDirectory;
            })
          );
    };
}
