{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Lock state sentinel file
  lockStateFile = "$XDG_RUNTIME_DIR/hyprlock.lock";

  # Lock screen with grace period - hyprlock allows dismissing within grace period
  lockWithGrace = pkgs.writeShellScript "lock-with-grace" ''
    # Don't lock if already locked (prevents timer accumulation bug)
    [ -f ${lockStateFile} ] && exit 0

    # Lock 1password first
    ${pkgs._1password-gui}/bin/1password --lock &

    # Create lock state file before locking
    touch ${lockStateFile}

    # Only start hyprlock if not already running
    if ! pidof hyprlock >/dev/null 2>&1; then
      ${pkgs.hyprlock}/bin/hyprlock --grace 30
      # Remove lock state file when hyprlock exits (user unlocked)
      rm -f ${lockStateFile}
    fi
  '';

  # Lock without grace period (for manual lock or before-sleep)
  lockImmediate = pkgs.writeShellScript "lock-immediate" ''
    # Don't lock if already locked
    [ -f ${lockStateFile} ] && exit 0

    ${pkgs._1password-gui}/bin/1password --lock &

    # Create lock state file before locking
    touch ${lockStateFile}

    if ! pidof hyprlock >/dev/null 2>&1; then
      ${pkgs.hyprlock}/bin/hyprlock
      # Remove lock state file when hyprlock exits (user unlocked)
      rm -f ${lockStateFile}
    fi
  '';

in
{
  # Import noctalia home-manager module
  imports = [
    inputs.noctalia.homeModules.default
  ];

  # Enable noctalia-shell with declarative settings
  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;

    # Color scheme (Catppuccin Mocha)
    colors = {
      mError = "#f38ba8";
      mHover = "#94e2d5";
      mOnError = "#11111b";
      mOnHover = "#11111b";
      mOnPrimary = "#11111b";
      mOnSecondary = "#11111b";
      mOnSurface = "#cdd6f4";
      mOnSurfaceVariant = "#a3b4eb";
      mOnTertiary = "#11111b";
      mOutline = "#4c4f69";
      mPrimary = "#cba6f7";
      mSecondary = "#fab387";
      mShadow = "#11111b";
      mSurface = "#1e1e2e";
      mSurfaceVariant = "#313244";
      mTertiary = "#94e2d5";
    };

    # Main settings
    settings = {
      appLauncher = {
        autoPasteClipboard = false;
        enableClipPreview = true;
        enableClipboardHistory = true;
        iconMode = "tabler";
        position = "center";
        showCategories = true;
        showIconBackground = false;
        sortByMostUsed = true;
        terminalCommand = "kitty -e";
        viewMode = "list";
      };

      audio = {
        externalMixer = "pwvucontrol || pavucontrol";
        preferredPlayer = "spotify";
        visualizerType = "linear";
        volumeStep = 5;
      };

      bar = {
        backgroundOpacity = 0.93;
        capsuleOpacity = 1;
        density = "default";
        exclusive = true;
        floating = false;
        position = "top";
        showCapsule = false;
        showOutline = false;
        outerCorners = false;
        widgets = {
          center = [
            {
              id = "Clock";
              formatHorizontal = "HH:mm ddd, MMM dd";
              tooltipFormat = "HH:mm ddd, MMM dd";
            }
            {
              id = "MediaMini";
              showProgressRing = true;
              showArtistFirst = true;
              maxWidth = 145;
              scrollingMode = "hover";
            }
            { id = "plugin:privacy-indicator"; }
          ];
          left = [
            {
              id = "Launcher";
              icon = "rocket";
            }
            {
              id = "Workspace";
              labelMode = "index+name";
              showLabelsOnlyWhenOccupied = true;
              hideUnoccupied = false;
              iconScale = 0.8;
            }
            {
              id = "ActiveWindow";
              maxWidth = 145;
              scrollingMode = "hover";
              showIcon = true;
            }
          ];
          right = [
            { id = "ScreenRecorder"; }
            {
              id = "Tray";
              colorizeIcons = true;
              drawerEnabled = true;
            }
            {
              id = "NotificationHistory";
              hideWhenZero = true;
              showUnreadBadge = true;
            }
            {
              id = "Battery";
              displayMode = "onhover";
              showPowerProfiles = true;
              warningThreshold = 30;
            }
            {
              id = "Volume";
              displayMode = "onhover";
            }
            { id = "plugin:github-feed"; }
            { id = "plugin:todo"; }
            { id = "plugin:simple-notes"; }
            {
              id = "SystemMonitor";
              compactMode = true;
              showCpuUsage = true;
              showCpuTemp = true;
              showMemoryUsage = true;
              showMemoryAsPercent = true;
              showDiskUsage = true;
              diskPath = "/home"; # Monitor /home instead of /
              showNetworkStats = true;
              showLoadAverage = true;
              useMonospaceFont = true;
            }
            {
              id = "ControlCenter";
              icon = "noctalia";
              useDistroLogo = true;
              enableColorization = true;
              colorizeSystemIcon = "primary";
            }
          ];
        };
      };

      brightness = {
        brightnessStep = 5;
        enableDdcSupport = true;
        enforceMinimum = true;
      };

      colorSchemes = {
        darkMode = true;
        predefinedScheme = "Catppuccin";
        useWallpaperColors = false;
        schedulingMode = "off";
      };

      controlCenter = {
        position = "close_to_bar_button";
        cards = [
          {
            id = "profile-card";
            enabled = true;
          }
          {
            id = "shortcuts-card";
            enabled = true;
          }
          {
            id = "audio-card";
            enabled = true;
          }
          {
            id = "brightness-card";
            enabled = false;
          }
          {
            id = "weather-card";
            enabled = true;
          }
          {
            id = "media-sysmon-card";
            enabled = true;
          }
        ];
        shortcuts = {
          left = [
            { id = "Network"; }
            { id = "Bluetooth"; }
            { id = "ScreenRecorder"; }
            { id = "WallpaperSelector"; }
          ];
          right = [
            { id = "Notifications"; }
            { id = "PowerProfile"; }
            { id = "KeepAwake"; }
            { id = "NightLight"; }
          ];
        };
      };

      dock.enabled = false;
      desktopWidgets.enabled = false;

      general = {
        avatarImage = "/home/jwilger/.face";
        animationDisabled = false;
        animationSpeed = 1;
        enableShadows = true;
        lockOnSuspend = true;
        showScreenCorners = false;
        dimmerOpacity = 0.2;
      };

      location = {
        name = "Forest Grove, OR, USA";
        useFahrenheit = true;
        use12hourFormat = false;
        weatherEnabled = true;
        weatherShowEffects = true;
        showCalendarEvents = true;
        showCalendarWeather = true;
      };

      nightLight = {
        enabled = true;
        autoSchedule = true;
        dayTemp = "6500";
        nightTemp = "4000";
      };

      notifications = {
        enabled = true;
        location = "top_right";
        backgroundOpacity = 1;
        normalUrgencyDuration = 10;
        lowUrgencyDuration = 3;
        criticalUrgencyDuration = 30;
        respectExpireTime = true;
        storeLowPriority = false;
        sounds = {
          enabled = true;
          excludedApps = "discord,firefox,chrome,chromium,edge,slack";
          volume = 1;
        };
      };

      osd = {
        enabled = true;
        location = "top_right";
        autoHideMs = 2000;
      };

      screenRecorder = {
        directory = "/home/jwilger/Videos";
        frameRate = 60;
        quality = "high";
        videoCodec = "hevc"; # h264 max is 4096x4096, but Studio Display is 5120x2880
        audioCodec = "opus";
        audioSource = "both";
        showCursor = true;
      };

      sessionMenu = {
        position = "center";
        enableCountdown = true;
        countdownDuration = 10000;
        showHeader = true;
        powerOptions = [
          {
            action = "lock";
            enabled = true;
            countdownEnabled = false;
          }
          {
            action = "suspend";
            enabled = false;
            countdownEnabled = true;
          }
          {
            action = "hibernate";
            enabled = false;
            countdownEnabled = true;
          }
          {
            action = "reboot";
            enabled = true;
            countdownEnabled = true;
          }
          {
            action = "logout";
            enabled = true;
            countdownEnabled = true;
          }
          {
            action = "shutdown";
            enabled = false;
            countdownEnabled = true;
          }
        ];
      };

      templates = {
        gtk = true;
        qt = true;
        kitty = false; # Disable - home-manager manages kitty config with transparency
        fuzzel = true;
        niri = true;
        yazi = true;
        code = true;
        kcolorscheme = true;
      };

      ui = {
        fontDefault = "JetBrainsMono Nerd Font Mono";
        fontFixed = "JetBrainsMono Nerd Font Mono";
        panelBackgroundOpacity = 0.93;
        panelsAttachedToBar = true;
        tooltipsEnabled = true;
      };

      wallpaper = {
        enabled = true;
        directory = "${config.home.homeDirectory}/.local/share/wallpapers";
        fillMode = "crop";
        setWallpaperOnAllMonitors = true;
        transitionType = "random";
        transitionDuration = 1500;
      };
    };
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
      outputs = { };

      # Prefer server-side decorations (niri draws window borders, not apps)
      prefer-no-csd = true;

      # Layout configuration
      layout = {
        gaps = 4;
        struts = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };
        center-focused-column = "never";
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
              app-id = "^firefox$";
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
            { app-id = "^ksshaskpass$"; }
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
          "${mod}+Return".action.spawn = "kitty";
          "${mod}+Space".action.spawn-sh = "noctalia-shell ipc call launcher toggle";
          "${mod}+E".action.spawn = "nautilus";
          "${mod}+Shift+E".action.spawn-sh = "noctalia-shell ipc call sessionMenu toggle";
          "${mod}+Shift+Slash".action.show-hotkey-overlay = [ ];

          # Lock screen (Mod+Escape) - immediate lock, no grace period
          "${mod}+Escape".action.spawn = "${lockImmediate}";

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
          "XF86AudioPlay".action.spawn-sh = "playerctl play-pause";
          "XF86AudioNext".action.spawn-sh = "playerctl next";
          "XF86AudioPrev".action.spawn-sh = "playerctl previous";
          "XF86MonBrightnessUp".action.spawn-sh = "brightnessctl set +5%";
          "XF86MonBrightnessDown".action.spawn-sh = "brightnessctl set 5%-";

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
        XDG_CURRENT_DESKTOP = "niri";
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "niri";
        # Cursor settings for XWayland apps
        XCURSOR_SIZE = "24";
        XCURSOR_THEME = "Vanilla-DMZ";
      };
    };
  };

  # Additional packages for niri session
  home.packages = with pkgs; [
    noctaliaPkg
    wl-clipboard
    grim
    slurp
    hyprlock
    hypridle
  ];

  # Hypridle configuration for screen locking and DPMS
  # Better integration with hyprlock than swayidle, prevents re-locking bugs
  #
  # How it works:
  # 1. At 300s idle: Lock screen with 30s grace period (can dismiss with any input)
  # 2. At 360s idle: Monitors power off (60s after lock)
  # 3. Hypridle properly tracks hyprlock state, preventing timer accumulation
  #
  # For manual lock: use Mod+Escape keybinding (immediate lock, no grace)
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || ${lockImmediate}";
        before_sleep_cmd = "${lockImmediate}";
        after_sleep_cmd = "${pkgs.niri}/bin/niri msg action power-on-monitors";
        ignore_dbus_inhibit = false;
      };
      listener = [
        {
          # Lock screen after 5 minutes of idle, with 30s grace period to dismiss
          timeout = 300;
          on-timeout = "${lockWithGrace}";
        }
        {
          # Power off monitors 60s after lock (360s total)
          timeout = 360;
          on-timeout = "${pkgs.niri}/bin/niri msg action power-off-monitors";
          on-resume = "${pkgs.niri}/bin/niri msg action power-on-monitors";
        }
      ];
    };
  };

  # Hyprlock configuration - Riced-out Catppuccin Mocha theme with FIDO support
  xdg.configFile."hypr/hyprlock.conf".text = ''
    # Catppuccin Mocha colors
    ''$base = rgb(1e1e2e)
    ''$mantle = rgb(181825)
    ''$crust = rgb(11111b)
    ''$surface0 = rgb(313244)
    ''$surface1 = rgb(45475a)
    ''$surface2 = rgb(585b70)
    ''$text = rgb(cdd6f4)
    ''$subtext0 = rgb(a6adc8)
    ''$subtext1 = rgb(bac2de)
    ''$lavender = rgb(b4befe)
    ''$mauve = rgb(cba6f7)
    ''$pink = rgb(f5c2e7)
    ''$maroon = rgb(eba0ac)
    ''$red = rgb(f38ba8)
    ''$peach = rgb(fab387)
    ''$yellow = rgb(f9e2af)
    ''$green = rgb(a6e3a1)
    ''$teal = rgb(94e2d5)
    ''$sky = rgb(89dceb)
    ''$sapphire = rgb(74c7ec)
    ''$blue = rgb(89b4fa)

    general {
      disable_loading_bar = false
      hide_cursor = true
      grace = 0  # Grace is set via command line
      no_fade_in = false
      no_fade_out = false
    }

    # Smooth, elegant animations
    animations {
      enabled = true
      bezier = smoothOut, 0.36, 0, 0.66, -0.56
      bezier = smoothIn, 0.25, 1, 0.5, 1
      bezier = overshot, 0.05, 0.9, 0.1, 1.1

      animation = fadeIn, 1, 8, smoothIn
      animation = fadeOut, 1, 5, smoothOut
    }

    # Background with enhanced effects
    background {
      monitor =
      path = ${config.home.homeDirectory}/.local/share/wallpapers/wallpaper.png
      color = ''$base
      blur_passes = 4
      blur_size = 7
      noise = 0.0117
      contrast = 1.0
      brightness = 0.7
      vibrancy = 0.3
      vibrancy_darkness = 0.2
    }

    # --- TOP LEFT: System Info ---

    # Hostname/System label
    label {
      monitor =
      text = cmd[update:3600000] echo " $(hostname)"
      color = ''$lavender
      font_size = 18
      font_family = JetBrainsMono Nerd Font
      shadow_passes = 2
      shadow_size = 3
      shadow_color = ''$crust

      position = 30, -30
      halign = left
      valign = top
    }

    # Uptime
    label {
      monitor =
      text = cmd[update:60000] echo " $(uptime -p | sed 's/up //')"
      color = ''$subtext0
      font_size = 12
      font_family = JetBrainsMono Nerd Font

      position = 30, -65
      halign = left
      valign = top
    }

    # CPU Temperature (if available)
    label {
      monitor =
      text = cmd[update:5000] if [ -f /sys/class/thermal/thermal_zone0/temp ]; then echo " $(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))°C"; fi
      color = ''$peach
      font_size = 12
      font_family = JetBrainsMono Nerd Font

      position = 30, -95
      halign = left
      valign = top
    }

    # --- TOP RIGHT: Date & Weather ---

    # Current weather (from noctalia or wttr.in)
    label {
      monitor =
      text = cmd[update:1800000] curl -sf "wttr.in/Forest+Grove+OR?format=%c+%t" || echo "󰼱 Weather unavailable"
      color = ''$sky
      font_size = 16
      font_family = JetBrainsMono Nerd Font
      shadow_passes = 2
      shadow_size = 3

      position = -30, -30
      halign = right
      valign = top
    }

    # Date
    label {
      monitor =
      text = cmd[update:60000] echo "󰃭 $(date '+%A, %B %d, %Y')"
      color = ''$subtext1
      font_size = 14
      font_family = JetBrainsMono Nerd Font

      position = -30, -65
      halign = right
      valign = top
    }

    # --- CENTER: Time (HERO) ---

    # Main time display - HUGE and centered
    label {
      monitor =
      text = cmd[update:1000] echo "<b>$(date +'%H:%M')</b>"
      color = ''$mauve
      font_size = 160
      font_family = JetBrainsMono Nerd Font
      shadow_passes = 4
      shadow_size = 8
      shadow_color = ''$crust
      shadow_boost = 1.5

      position = 0, 160
      halign = center
      valign = center
    }

    # Seconds - small, subtle
    label {
      monitor =
      text = cmd[update:1000] echo "$(date +'%S')"
      color = ''$subtext0
      font_size = 32
      font_family = JetBrainsMono Nerd Font

      position = 0, 80
      halign = center
      valign = center
    }

    # Greeting message
    label {
      monitor =
      text = Welcome back, ''$USER
      color = ''$text
      font_size = 20
      font_family = JetBrainsMono Nerd Font

      position = 0, 20
      halign = center
      valign = center
    }

    # --- CENTER: Authentication ---

    # Password input field with enhanced styling
    input-field {
      monitor =
      size = 350, 60
      outline_thickness = 4
      dots_size = 0.25
      dots_spacing = 0.25
      dots_center = true
      dots_rounding = -1
      outer_color = rgba(203, 166, 247, 0.8)
      inner_color = rgba(49, 50, 68, 0.9)
      font_color = ''$text
      fade_on_empty = true
      fade_timeout = 1000
      placeholder_text = <span foreground="##''$subtext0FF"><i>󰌾 Enter PIN, then touch YubiKey...</i></span>
      hide_input = false
      rounding = 20
      check_color = ''$green
      fail_color = ''$red
      fail_text = <span foreground="##''$redFF"><i>󰗖 ''$FAIL</i> <b>(''$ATTEMPTS)</b></span>
      fail_timeout = 2000
      fail_transition = 300
      capslock_color = ''$yellow
      numlock_color = -1
      bothlock_color = -1
      invert_numlock = false
      swap_font_color = false

      position = 0, -80
      halign = center
      valign = center
    }

    # FIDO/YubiKey hint
    label {
      monitor =
      text = 󰌆 FIDO2: Enter PIN → Touch Device
      color = ''$lavender
      font_size = 13
      font_family = JetBrainsMono Nerd Font

      position = 0, -170
      halign = center
      valign = center
    }

    # --- BOTTOM LEFT: Media Player Info ---

    # Album art / Now playing
    label {
      monitor =
      text = cmd[update:1000] playerctl metadata --format '󰝚 {{ artist }} - {{ title }}' 2>/dev/null | head -c 50 || echo ""
      color = ''$pink
      font_size = 13
      font_family = JetBrainsMono Nerd Font
      shadow_passes = 1

      position = 30, 80
      halign = left
      valign = bottom
    }

    # Media status
    label {
      monitor =
      text = cmd[update:1000] playerctl status 2>/dev/null | sed 's/Playing/ Playing/' | sed 's/Paused/ Paused/' || echo ""
      color = ''$subtext0
      font_size = 11
      font_family = JetBrainsMono Nerd Font

      position = 30, 50
      halign = left
      valign = bottom
    }

    # --- BOTTOM RIGHT: Battery & Power ---

    # Battery percentage
    label {
      monitor =
      text = cmd[update:10000] if [ -f /sys/class/power_supply/BAT0/capacity ]; then echo " $(cat /sys/class/power_supply/BAT0/capacity)%"; fi
      color = ''$green
      font_size = 14
      font_family = JetBrainsMono Nerd Font

      position = -30, 80
      halign = right
      valign = bottom
    }

    # Power state
    label {
      monitor =
      text = cmd[update:10000] if [ -f /sys/class/power_supply/BAT0/status ]; then cat /sys/class/power_supply/BAT0/status | sed 's/Charging/ Charging/' | sed 's/Discharging/ On Battery/' | sed 's/Full/ Fully Charged/' | sed 's/Not charging/ Plugged In/'; fi
      color = ''$subtext0
      font_size = 11
      font_family = JetBrainsMono Nerd Font

      position = -30, 50
      halign = right
      valign = bottom
    }

    # Lock screen message at very bottom
    label {
      monitor =
      text = 󰌾 Screen locked due to inactivity
      color = ''$surface2
      font_size = 10
      font_family = JetBrainsMono Nerd Font

      position = 0, 15
      halign = center
      valign = bottom
    }
  '';

  # Wallpaper managed by Nix
  home.file.".local/share/wallpapers/wallpaper.png".source = ../wallpaper.png;

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
      "showStars": false,
      "showForks": false,
      "showPRs": false,
      "showRepoCreations": false,
      "showMyRepoStars": false,
      "showMyRepoForks": false,
      "openInBrowser": true
    }
    EOF
          fi
        fi
  '';
}
