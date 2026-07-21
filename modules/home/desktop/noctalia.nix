{
  config,
  host,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  noctaliaConfigDir = "/etc/nixos/modules/home/desktop/noctalia";
  noctaliaHostConfigDir = "${noctaliaConfigDir}/${host}";
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  wallpaperPath = "${config.home.homeDirectory}/.local/share/wallpapers/wallpaper.png";
  noctaliaWallpaper = pkgs.writeShellApplication {
    name = "noctalia-wallpaper";
    runtimeInputs = [
      noctaliaPkg
      pkgs.coreutils
    ];
    text = ''
      attempt=0
      while [ "$attempt" -lt 100 ]; do
        if noctalia msg wallpaper-set "${wallpaperPath}"; then
          exit 0
        fi

        attempt=$((attempt + 1))
        sleep 0.1
      done

      exit 1
    '';
  };
  lockScreen = pkgs.writeShellScript "lock-screen" ''
    ${pkgs._1password-gui}/bin/1password --lock &
    ${noctaliaPkg}/bin/noctalia msg session lock
  '';
  displayLaptop = pkgs.writeShellApplication {
    name = "display-laptop";
    runtimeInputs = [ pkgs.hyprland ];
    text = ''
      hyprctl keyword monitor Virtual-1,1920x1200@59.885,auto,1.5
    '';
  };
  displayStudio = pkgs.writeShellApplication {
    name = "display-studio";
    runtimeInputs = [ pkgs.hyprland ];
    text = ''
      hyprctl keyword monitor Virtual-1,3840x2160@60,auto,1.5
    '';
  };
  displayProfile = pkgs.writeShellApplication {
    name = "display-profile";
    runtimeInputs = [
      displayLaptop
      displayStudio
      pkgs.fuzzel
    ];
    text = ''
      choice="$(printf 'Laptop\nStudio Display\n' | fuzzel --dmenu --prompt='Display profile: ' --lines=2 --width=28)" || exit 0

      case "$choice" in
        Laptop)
          exec display-laptop
          ;;
        "Studio Display")
          exec display-studio
          ;;
      esac
    '';
  };
  restoreWindowFocus = pkgs.writeShellApplication {
    name = "restore-window-focus";
    runtimeInputs = [ pkgs.hyprland ];
    text = ''
      hyprctl dispatch 'hl.dsp.focus({ window = hl.get_active_workspace().last_window })'
    '';
  };
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    systemd.enable = false;
    validateConfig = false;
  };

  systemd.user.services = {
    noctalia-wallpaper = {
      Unit = {
        Description = "Apply the managed Noctalia wallpaper";
        After = [ "noctalia-hyprland.service" ];
        Wants = [ "noctalia-hyprland.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${noctaliaWallpaper}/bin/noctalia-wallpaper";
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };
    noctalia-hyprland = {
      Unit = {
        Description = "Noctalia shell for the Hyprland session";
        PartOf = [ "hyprland-session.target" ];
      };
      Service = {
        ExecStart = lib.getExe noctaliaPkg;
        Restart = "on-failure";
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };
    onepassword-hyprland = {
      Unit = {
        Description = "1Password for the Hyprland session";
        After = [ "hyprland-session.target" ];
        PartOf = [ "hyprland-session.target" ];
      };
      Service.ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
      Install.WantedBy = [ "hyprland-session.target" ];
    };
  };

  xdg.configFile = {
    "noctalia/config.toml".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${
        if host == "sansa-vm" then noctaliaHostConfigDir else noctaliaConfigDir
      }/config.toml"
    );
    "noctalia/settings.json".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${noctaliaConfigDir}/settings.json"
    );
    "noctalia/colors.json".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${noctaliaConfigDir}/colors.json"
    );
    "noctalia/plugins.json".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${noctaliaConfigDir}/plugins.json"
    );
    "noctalia/assets/nixos.svg".source =
      "${noctaliaPkg}/share/noctalia/assets/images/distros/nixos.svg";
  };

  home.file = {
    ".local/bin/lock-screen".source = lockScreen;
    ".local/share/wallpapers/wallpaper.png".source = ./wallpaper.png;
    ".local/state/noctalia/settings.toml" = {
      force = true;
      source = lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${noctaliaConfigDir}/settings.toml");
    };
  };

  home.packages = [
    displayLaptop
    displayProfile
    displayStudio
    noctaliaPkg
    restoreWindowFocus
    pkgs.grim
    pkgs.slurp
    pkgs.wl-clipboard
  ];

  home.activation.noctaliaWallpaperSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cacheFile="$HOME/.cache/noctalia/wallpapers.json"
    mkdir -p "$HOME/.cache/noctalia"
    cacheTempFile="$(mktemp "$HOME/.cache/noctalia/wallpapers.json.XXXXXX")"
    cat > "$cacheTempFile" << 'EOF'
    {
      "defaultWallpaper": "${wallpaperPath}",
      "usedRandomWallpapers": {},
      "wallpapers": {
        "": {
          "dark": "${wallpaperPath}",
          "light": "${wallpaperPath}"
        }
      }
    }
    EOF
    mv "$cacheTempFile" "$cacheFile"
  '';

  home.activation.noctaliaWallpaperLive = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
    ${pkgs.systemd}/bin/systemctl --user start noctalia-wallpaper.service || true
  '';

  home.activation.noctaliaGithubFeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.config/noctalia/plugins/github-feed"
        if command -v op &> /dev/null && op account list &> /dev/null; then
          TOKEN=$(op read "op://Personal/Noctalia GH Notifier PAT/password" 2>/dev/null || echo "")
          if [ -n "$TOKEN" ]; then
            cat > "$HOME/.config/noctalia/plugins/github-feed/settings.json" << EOF
    {
      "username": "jwilger",
      "token": "$TOKEN",
      "refreshInterval": 1800,
      "maxEvents": 50,
      "showStars": true,
      "showForks": true,
      "showPRs": true,
      "showRepoCreations": true,
      "showMyRepoStars": true,
      "showMyRepoForks": true,
      "openInBrowser": true
    }
    EOF
          fi
        fi
  '';
}
