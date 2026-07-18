{
  config,
  host,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  noctaliaConfigDir = "/etc/nixos/modules/home/desktop/niri/noctalia";
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
  terminal = "wezterm";

  # Manual & idle-driven lock command. Locks 1Password in addition to
  # activating noctalia's session lock — noctalia by itself blocks the
  # desktop but doesn't tell other apps to drop their unlocked state.
  # Used by the Mod+Escape keybind and by noctalia's idle service
  # (idle.behavior.lock.command in config.toml).
  lockScreen = pkgs.writeShellScript "lock-screen" ''
    ${pkgs._1password-gui}/bin/1password --lock &
    ${noctaliaPkg}/bin/noctalia msg session lock
  '';

  sudoAskpass = pkgs.writeShellScript "sudo-askpass" ''
    ${lib.getExe pkgs.zenity} --password \
      --title="Authentication required" \
      --text="''${1:-Password required}" \
      --width=360
  '';
  displayLaptop = pkgs.writeShellApplication {
    name = "display-laptop";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.niri
    ];
    text = ''
      if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        hyprctl keyword monitor Virtual-1,1920x1200@59.885,auto,1.5
      else
        niri msg output Virtual-1 mode 1920x1200@59.885
        niri msg output Virtual-1 scale 1.5
      fi
    '';
  };
  displayStudio = pkgs.writeShellApplication {
    name = "display-studio";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.niri
    ];
    text = ''
      if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        hyprctl keyword monitor Virtual-1,3840x2160@60,auto,1.5
      else
        niri msg output Virtual-1 mode 3840x2160@60
        niri msg output Virtual-1 scale 1.5
      fi
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

in
{
  # Import noctalia home-manager module
  imports = [
    inputs.noctalia.homeModules.default
  ];

  # Enable Noctalia v5. The upstream module defaults to the package from the
  # Noctalia flake input, which we keep on its Cachix-backed branch to avoid
  # local rebuilds. Niri launches the shell directly instead of using the
  # module's systemd user service.
  programs.noctalia = {
    enable = true;
    systemd.enable = false;
    validateConfig = false;
  };

  systemd.user.services.noctalia-wallpaper = {
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

  systemd.user.services.noctalia-hyprland = {
    Unit = {
      Description = "Noctalia shell for the Hyprland session";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = lib.getExe noctaliaPkg;
      Restart = "on-failure";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  systemd.user.services.onepassword-hyprland = {
    Unit = {
      Description = "1Password for the Hyprland session";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service.ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  # Keep Noctalia's GUI-editable config outside the Nix store. These symlinks
  # let v5's settings UI write changes that persist across future
  # Home Manager/NixOS activations.
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

  # Noctalia v5 also overlays ~/.local/state/noctalia/settings.toml after the
  # config dir. Manage that file too so GUI overrides are visible in this repo
  # instead of silently taking precedence over config.toml.
  home.file.".local/state/noctalia/settings.toml" = {
    force = true;
    source = lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${noctaliaConfigDir}/settings.toml");
  };

  # Niri configuration via niri-flake home-manager module
  programs.niri = {
    settings = {
      # Startup applications
      spawn-at-startup = [
        { command = [ "xwayland-satellite" ]; }
        {
          command = [
            "${pkgs._1password-gui}/bin/1password"
            "--silent"
          ];
        }
        { command = [ "${noctaliaPkg}/bin/noctalia" ]; }
        { command = [ "${noctaliaWallpaper}/bin/noctalia-wallpaper" ]; }
      ];

      # Input configuration
      input = {
        keyboard = {
          xkb = {
            layout = "us";
          };
        };
        touchpad = {
          tap = true;
          natural-scroll = true;
        };
        mouse = {
          natural-scroll = true;
        };
      };

      # Output/display configuration
      outputs = lib.optionalAttrs (host == "sansa-vm") {
        "Virtual-1" = {
          mode = {
            width = 1920;
            height = 1200;
            refresh = 59.885;
          };
          scale = 1.5;
        };
      };

      # Prefer server-side decorations (niri draws window borders, not apps)
      prefer-no-csd = true;

      # Tuple's bundled PipeWire client cannot negotiate Niri's DMA-BUF modifier.
      # Keep screencasting on the Wayland portal while using the compatible
      # invalid modifier path documented by Niri.
      debug."force-pipewire-invalid-modifier" = true;

      # Layout configuration
      layout = {
        gaps = 4;
        struts = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };
        center-focused-column = "on-overflow";
        preset-column-widths = [
          { proportion = 1.0 / 3.0; }
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
        ];
        default-column-width = {
          proportion = 1.0 / 2.0;
        };
        focus-ring = {
          enable = true;
          width = 2;
          active.color = "#cba6f7"; # Catppuccin mauve
          inactive.color = "#45475a"; # Catppuccin surface1
        };
        border = {
          enable = false;
        };
      };

      # Window rules
      window-rules = [
        {
          # Prevent focus ring background from filling transparent windows
          draw-border-with-background = false;
        }
        {
          matches = [ { app-id = "^1Password$"; } ];
          open-floating = true;
        }
        {
          matches = [
            {
              app-id = "^(chromium|google-chrome)$";
              title = "^Picture-in-Picture$";
            }
          ];
          open-floating = true;
        }
        {
          # Float askpass and polkit dialogs
          matches = [
            { app-id = "^lxqt-openssh-askpass$"; }
            { app-id = "^polkit-gnome-authentication-agent-1$"; }
            { app-id = "^org\\.gnome\\.Zenity$"; }
            { app-id = "^ksshaskpass$"; }
            { app-id = "^zenity$"; }
          ];
          open-floating = true;
        }
      ];

      # Keybindings
      binds =
        let
          mod = "Mod";
        in
        {
          # Application launchers
          "${mod}+Return".action.spawn = terminal;
          "${mod}+Space".action.spawn-sh = "noctalia msg panel-toggle launcher";
          "${mod}+E".action.spawn = "nautilus";
          "${mod}+Shift+E".action.spawn-sh = "noctalia msg panel-toggle session";
          "${mod}+Shift+Slash".action.show-hotkey-overlay = [ ];

          # Lock screen (Mod+Escape)
          "${mod}+Escape".action.spawn = "${lockScreen}";

          # Window management
          "${mod}+Q".action.close-window = [ ];
          "${mod}+F".action.maximize-column = [ ];
          "${mod}+Shift+F".action.fullscreen-window = [ ];
          "${mod}+C".action.center-column = [ ];

          # Focus movement
          "${mod}+H".action.focus-column-left = [ ];
          "${mod}+J".action.focus-window-down = [ ];
          "${mod}+K".action.focus-window-up = [ ];
          "${mod}+L".action.focus-column-right = [ ];
          "${mod}+Left".action.focus-column-left = [ ];
          "${mod}+Down".action.focus-window-down = [ ];
          "${mod}+Up".action.focus-window-up = [ ];
          "${mod}+Right".action.focus-column-right = [ ];

          # Window movement
          "${mod}+Shift+H".action.move-column-left = [ ];
          "${mod}+Shift+J".action.move-window-down = [ ];
          "${mod}+Shift+K".action.move-window-up = [ ];
          "${mod}+Shift+L".action.move-column-right = [ ];
          "${mod}+Shift+Left".action.move-column-left = [ ];
          "${mod}+Shift+Down".action.move-window-down = [ ];
          "${mod}+Shift+Up".action.move-window-up = [ ];
          "${mod}+Shift+Right".action.move-column-right = [ ];

          # Workspace management
          "${mod}+1".action.focus-workspace = [ 1 ];
          "${mod}+2".action.focus-workspace = [ 2 ];
          "${mod}+3".action.focus-workspace = [ 3 ];
          "${mod}+4".action.focus-workspace = [ 4 ];
          "${mod}+5".action.focus-workspace = [ 5 ];
          "${mod}+6".action.focus-workspace = [ 6 ];
          "${mod}+7".action.focus-workspace = [ 7 ];
          "${mod}+8".action.focus-workspace = [ 8 ];
          "${mod}+9".action.focus-workspace = [ 9 ];

          "${mod}+Shift+1".action.move-window-to-workspace = [ 1 ];
          "${mod}+Shift+2".action.move-window-to-workspace = [ 2 ];
          "${mod}+Shift+3".action.move-window-to-workspace = [ 3 ];
          "${mod}+Shift+4".action.move-window-to-workspace = [ 4 ];
          "${mod}+Shift+5".action.move-window-to-workspace = [ 5 ];
          "${mod}+Shift+6".action.move-window-to-workspace = [ 6 ];
          "${mod}+Shift+7".action.move-window-to-workspace = [ 7 ];
          "${mod}+Shift+8".action.move-window-to-workspace = [ 8 ];
          "${mod}+Shift+9".action.move-window-to-workspace = [ 9 ];

          # Column width
          "${mod}+R".action.switch-preset-column-width = [ ];
          "${mod}+Minus".action.set-column-width = "-10%";
          "${mod}+Equal".action.set-column-width = "+10%";

          # Window height
          "${mod}+Shift+Minus".action.set-window-height = "-10%";
          "${mod}+Shift+Equal".action.set-window-height = "+10%";

          # Screenshots (using grim/slurp)
          "Print".action.spawn-sh = "grim -g \"$(slurp)\" - | wl-copy";
          "${mod}+Print".action.spawn-sh = "grim - | wl-copy";
          "${mod}+Shift+Print".action.spawn-sh = "grim -g \"$(slurp -d)\" - | wl-copy";

          # Media keys
          "XF86AudioRaiseVolume".action.spawn-sh = "pamixer -i 5";
          "XF86AudioLowerVolume".action.spawn-sh = "pamixer -d 5";
          "XF86AudioMute".action.spawn-sh = "pamixer -t";
          "${mod}+M".action.spawn-sh = "pamixer --default-source -t"; # Toggle microphone mute
          "${mod}+N".action.spawn-sh = "noctalia msg notification-clear-active";
          "${mod}+Shift+N".action.spawn-sh = "noctalia msg notification-dnd-toggle";
          "XF86AudioPlay".action.spawn-sh = "playerctl play-pause";
          "XF86AudioNext".action.spawn-sh = "playerctl next";
          "XF86AudioPrev".action.spawn-sh = "playerctl previous";
          "XF86MonBrightnessUp".action.spawn-sh = "brightnessctl set +5%";
          "XF86MonBrightnessDown".action.spawn-sh = "brightnessctl set 5%-";

          # Voice dictation (push-to-talk toggle)
          "${mod}+D".action.spawn = "voice-dictation";

          # Floating window toggle
          "${mod}+V".action.toggle-window-floating = [ ];
          "${mod}+Shift+V".action.switch-focus-between-floating-and-tiling = [ ];

          # Consume/expel windows from column
          "${mod}+BracketLeft".action.consume-window-into-column = [ ];
          "${mod}+BracketRight".action.expel-window-from-column = [ ];
        };

      # Cursor and animations
      cursor = {
        theme = "Vanilla-DMZ";
        size = 24;
      };

      # Animations
      animations = { };

      # Environment variables for niri session
      environment = {
        DISPLAY = ":0";
        QT_QPA_PLATFORM = "wayland";
        SDL_VIDEODRIVER = "wayland";
        SUDO_ASKPASS = "${sudoAskpass}";
        XDG_CURRENT_DESKTOP = "niri";
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "niri";
        # Cursor settings for XWayland apps
        XCURSOR_SIZE = "24";
        XCURSOR_THEME = "Vanilla-DMZ";
      };
    };
  };

  # Additional packages for niri session.
  # Idle/DPMS/lock are now driven by noctalia's native IdleService
  # (ext-idle-notify-v1 protocol) — no external idle daemon needed.
  home.packages = with pkgs; [
    displayLaptop
    displayProfile
    displayStudio
    noctaliaPkg
    wl-clipboard
    grim
    slurp
  ];

  home.file.".local/bin/lock-screen".source = lockScreen;

  # Wallpaper managed by Nix
  home.file.".local/share/wallpapers/wallpaper.png".source = ../wallpaper.png;

  # Noctalia stores the active wallpaper per-monitor in ~/.cache/noctalia/
  # wallpapers.json. Its bundled image becomes the fallback whenever that state
  # is reset, so replace it on every activation with our global dark/light entry.
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

  # GitHub feed plugin settings - token retrieved from 1Password at activation
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
