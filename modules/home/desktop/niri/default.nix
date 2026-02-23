{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Lock screen using noctalia-shell
  lockScreen = pkgs.writeShellScript "lock-screen" ''
    # Lock 1password first
    ${pkgs._1password-gui}/bin/1password --lock &

    # Lock screen via noctalia-shell
    ${noctaliaPkg}/bin/noctalia-shell ipc call lockScreen lock
  '';

  # Resume script for when monitors power back on (after DPMS off or sleep).
  # Re-issues the lock command so noctalia-shell re-renders its lock screen
  # surface, which can go stale after prolonged monitor-off periods.
  resumeScreen = pkgs.writeShellScript "resume-screen" ''
    ${pkgs.niri}/bin/niri msg action power-on-monitors
    # Give monitors a moment to initialize before re-rendering lock screen
    sleep 1
    ${noctaliaPkg}/bin/noctalia-shell ipc call lockScreen lock
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
      settingsVersion = 40;

      bar = {
        position = "top";
        monitors = [ ];
        density = "default";
        showOutline = false;
        showCapsule = false;
        capsuleOpacity = 1;
        backgroundOpacity = 0.8;
        useSeparateOpacity = true;
        floating = false;
        marginVertical = 4;
        marginHorizontal = 4;
        outerCorners = false;
        exclusive = true;
        hideOnOverview = false;
        widgets = {
          left = [
            {
              id = "Spacer";
              width = 20;
            }
            {
              icon = "rocket";
              id = "Launcher";
              usePrimaryColor = false;
            }
            {
              characterCount = 2;
              colorizeIcons = false;
              enableScrollWheel = true;
              followFocusedScreen = false;
              groupedBorderOpacity = 1;
              hideUnoccupied = false;
              iconScale = 0.8;
              id = "Workspace";
              labelMode = "index+name";
              showApplications = false;
              showLabelsOnlyWhenOccupied = true;
              unfocusedIconsOpacity = 1;
            }
            {
              colorizeIcons = false;
              hideMode = "hidden";
              id = "ActiveWindow";
              maxWidth = 145;
              scrollingMode = "hover";
              showIcon = true;
              useFixedWidth = false;
            }
          ];
          center = [
            {
              defaultSettings = {
                hideBackground = false;
                minimumThreshold = 10;
              };
              id = "plugin:catwalk";
            }
            {
              customFont = "";
              formatHorizontal = "HH:mm ddd, MMM dd";
              formatVertical = "HH mm - dd MM";
              id = "Clock";
              tooltipFormat = "HH:mm ddd, MMM dd";
              useCustomFont = false;
              usePrimaryColor = false;
            }
            {
              compactMode = false;
              compactShowAlbumArt = true;
              compactShowVisualizer = false;
              hideMode = "hidden";
              hideWhenIdle = false;
              id = "MediaMini";
              maxWidth = 145;
              panelShowAlbumArt = true;
              panelShowVisualizer = true;
              scrollingMode = "hover";
              showAlbumArt = true;
              showArtistFirst = true;
              showProgressRing = true;
              showVisualizer = false;
              useFixedWidth = false;
              visualizerType = "linear";
            }
            {
              defaultSettings = {
                hideInactive = false;
                removeMargins = false;
              };
              id = "plugin:privacy-indicator";
            }
          ];
          right = [
            {
              displayMode = "onhover";
              id = "Volume";
              middleClickCommand = "pwvucontrol || pavucontrol";
            }
            {
              displayMode = "onhover";
              id = "Microphone";
              middleClickCommand = "pwvucontrol || pavucontrol";
            }
            {
              defaultSettings = {
                autoStartBreaks = false;
                autoStartWork = false;
                compactMode = false;
                longBreakDuration = 15;
                sessionsBeforeLongBreak = 4;
                shortBreakDuration = 5;
                workDuration = 25;
              };
              id = "plugin:pomodoro";
            }
            {
              hideWhenZero = false;
              hideWhenZeroUnread = true;
              id = "NotificationHistory";
              showUnreadBadge = true;
            }
            {
              defaultSettings = {
                maxEvents = 50;
                openInBrowser = true;
                refreshInterval = 1800;
                showForks = true;
                showMyRepoForks = true;
                showMyRepoStars = true;
                showPRs = true;
                showRepoCreations = true;
                showStars = true;
                token = "";
                username = "";
              };
              id = "plugin:github-feed";
            }
            {
              defaultSettings = {
                audioCodec = "opus";
                audioSource = "default_output";
                colorRange = "limited";
                copyToClipboard = false;
                directory = "";
                filenamePattern = "recording_yyyyMMdd_HHmmss";
                frameRate = "60";
                quality = "very_high";
                resolution = "original";
                showCursor = true;
                videoCodec = "h264";
                videoSource = "portal";
              };
              id = "plugin:screen-recorder";
            }
            {
              defaultSettings = {
                mode = "region";
              };
              id = "plugin:screenshot";
            }
            { id = "KeepAwake"; }
            {
              blacklist = [ ];
              colorizeIcons = true;
              drawerEnabled = true;
              hidePassive = false;
              id = "Tray";
              pinned = [ ];
            }
            {
              id = "Spacer";
              width = 20;
            }
            {
              colorizeDistroLogo = false;
              colorizeSystemIcon = "primary";
              customIconPath = "";
              enableColorization = true;
              icon = "noctalia";
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {
              id = "Spacer";
              width = 20;
            }
          ];
        };
      };

      general = {
        avatarImage = "${./profile-headshot.png}";
        dimmerOpacity = 0.2;
        showScreenCorners = false;
        forceBlackScreenCorners = false;
        scaleRatio = 1;
        radiusRatio = 1;
        iRadiusRatio = 1;
        boxRadiusRatio = 1;
        screenRadiusRatio = 1;
        animationSpeed = 1;
        animationDisabled = false;
        compactLockScreen = false;
        lockOnSuspend = true;
        showSessionButtonsOnLockScreen = false;
        showHibernateOnLockScreen = false;
        enableShadows = true;
        shadowDirection = "bottom_right";
        shadowOffsetX = 2;
        shadowOffsetY = 3;
        language = "";
        allowPanelsOnScreenWithoutBar = true;
        showChangelogOnStartup = true;
        telemetryEnabled = true;
      };

      ui = {
        fontDefault = "JetBrainsMono Nerd Font Mono";
        fontFixed = "JetBrainsMono Nerd Font Mono";
        fontDefaultScale = 1;
        fontFixedScale = 1;
        tooltipsEnabled = true;
        panelBackgroundOpacity = 0.8;
        panelsAttachedToBar = true;
        settingsPanelMode = "attached";
        wifiDetailsViewMode = "grid";
        bluetoothDetailsViewMode = "grid";
        networkPanelView = "wifi";
        bluetoothHideUnnamedDevices = false;
        boxBorderEnabled = false;
      };

      location = {
        name = "Forest Grove, OR, USA";
        weatherEnabled = true;
        weatherShowEffects = true;
        useFahrenheit = true;
        use12hourFormat = false;
        showWeekNumberInCalendar = false;
        showCalendarEvents = true;
        showCalendarWeather = true;
        analogClockInCalendar = false;
        firstDayOfWeek = -1;
        hideWeatherTimezone = false;
        hideWeatherCityName = false;
      };

      calendar = {
        cards = [
          {
            enabled = true;
            id = "calendar-header-card";
          }
          {
            enabled = true;
            id = "calendar-month-card";
          }
          {
            enabled = true;
            id = "weather-card";
          }
        ];
      };

      wallpaper = {
        enabled = true;
        overviewEnabled = false;
        directory = "/home/jwilger/Pictures/Wallpapers";
        monitorDirectories = [ ];
        enableMultiMonitorDirectories = false;
        recursiveSearch = false;
        setWallpaperOnAllMonitors = true;
        fillMode = "crop";
        fillColor = "#000000";
        useSolidColor = false;
        solidColor = "#1a1a2e";
        randomEnabled = false;
        wallpaperChangeMode = "random";
        randomIntervalSec = 300;
        transitionDuration = 1500;
        transitionType = "random";
        transitionEdgeSmoothness = 0.05;
        panelPosition = "follow_bar";
        hideWallpaperFilenames = false;
        useWallhaven = false;
        wallhavenQuery = "";
        wallhavenSorting = "relevance";
        wallhavenOrder = "desc";
        wallhavenCategories = "111";
        wallhavenPurity = "100";
        wallhavenRatios = "";
        wallhavenApiKey = "";
        wallhavenResolutionMode = "atleast";
        wallhavenResolutionWidth = "";
        wallhavenResolutionHeight = "";
      };

      appLauncher = {
        enableClipboardHistory = true;
        autoPasteClipboard = false;
        enableClipPreview = true;
        clipboardWrapText = true;
        position = "center";
        pinnedApps = [ ];
        useApp2Unit = false;
        sortByMostUsed = true;
        terminalCommand = "kitty -e";
        customLaunchPrefixEnabled = false;
        customLaunchPrefix = "";
        viewMode = "list";
        showCategories = true;
        iconMode = "tabler";
        showIconBackground = false;
        ignoreMouseInput = false;
        screenshotAnnotationTool = "";
      };

      controlCenter = {
        position = "close_to_bar_button";
        diskPath = "/";
        shortcuts = {
          left = [
            { id = "Network"; }
            { id = "Bluetooth"; }
            { id = "WallpaperSelector"; }
          ];
          right = [
            { id = "Notifications"; }
            { id = "PowerProfile"; }
            { id = "KeepAwake"; }
            { id = "NightLight"; }
          ];
        };
        cards = [
          {
            enabled = true;
            id = "profile-card";
          }
          {
            enabled = true;
            id = "shortcuts-card";
          }
          {
            enabled = true;
            id = "audio-card";
          }
          {
            enabled = false;
            id = "brightness-card";
          }
          {
            enabled = true;
            id = "weather-card";
          }
          {
            enabled = true;
            id = "media-sysmon-card";
          }
        ];
      };

      systemMonitor = {
        cpuWarningThreshold = 80;
        cpuCriticalThreshold = 90;
        tempWarningThreshold = 80;
        tempCriticalThreshold = 90;
        gpuWarningThreshold = 80;
        gpuCriticalThreshold = 90;
        memWarningThreshold = 80;
        memCriticalThreshold = 90;
        diskWarningThreshold = 80;
        diskCriticalThreshold = 90;
        cpuPollingInterval = 3000;
        tempPollingInterval = 3000;
        gpuPollingInterval = 3000;
        enableDgpuMonitoring = true;
        memPollingInterval = 3000;
        diskPollingInterval = 3000;
        networkPollingInterval = 3000;
        loadAvgPollingInterval = 3000;
        useCustomColors = false;
        warningColor = "";
        criticalColor = "";
        externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
      };

      dock = {
        enabled = false;
        position = "bottom";
        displayMode = "auto_hide";
        backgroundOpacity = 1;
        floatingRatio = 1;
        size = 1;
        onlySameOutput = true;
        monitors = [ ];
        pinnedApps = [ ];
        colorizeIcons = false;
        pinnedStatic = false;
        inactiveIndicators = false;
        deadOpacity = 0.6;
        animationSpeed = 1;
      };

      network = {
        wifiEnabled = false;
        bluetoothRssiPollingEnabled = true;
        bluetoothRssiPollIntervalMs = 10000;
        wifiDetailsViewMode = "grid";
        bluetoothDetailsViewMode = "grid";
        bluetoothHideUnnamedDevices = false;
      };

      sessionMenu = {
        enableCountdown = true;
        countdownDuration = 10000;
        position = "center";
        showHeader = false;
        largeButtonsStyle = false;
        largeButtonsLayout = "grid";
        showNumberLabels = true;
        powerOptions = [
          {
            action = "lock";
            command = "";
            countdownEnabled = false;
            enabled = true;
          }
          {
            action = "suspend";
            command = "";
            countdownEnabled = true;
            enabled = false;
          }
          {
            action = "hibernate";
            command = "";
            countdownEnabled = true;
            enabled = false;
          }
          {
            action = "reboot";
            command = "";
            countdownEnabled = true;
            enabled = true;
          }
          {
            action = "logout";
            command = "";
            countdownEnabled = true;
            enabled = true;
          }
          {
            action = "shutdown";
            command = "";
            countdownEnabled = true;
            enabled = false;
          }
        ];
      };

      notifications = {
        enabled = true;
        monitors = [ ];
        location = "top_right";
        overlayLayer = true;
        backgroundOpacity = 0.8;
        respectExpireTimeout = true;
        lowUrgencyDuration = 3;
        normalUrgencyDuration = 10;
        criticalUrgencyDuration = 30;
        enableKeyboardLayoutToast = true;
        saveToHistory = {
          low = false;
          normal = true;
          critical = true;
        };
        sounds = {
          enabled = true;
          volume = 1;
          separateSounds = true;
          criticalSoundFile = "";
          normalSoundFile = "";
          lowSoundFile = "";
          excludedApps = "discord,firefox,chrome,chromium,edge,slack";
        };
      };

      osd = {
        enabled = true;
        location = "top_right";
        autoHideMs = 2000;
        overlayLayer = true;
        backgroundOpacity = 1;
        enabledTypes = [
          0
          1
          2
          4
        ];
        monitors = [ ];
      };

      audio = {
        volumeStep = 5;
        volumeOverdrive = false;
        cavaFrameRate = 30;
        visualizerType = "linear";
        mprisBlacklist = [ ];
        preferredPlayer = "spotify";
      };

      brightness = {
        brightnessStep = 5;
        enforceMinimum = true;
        enableDdcSupport = true;
      };

      colorSchemes = {
        useWallpaperColors = false;
        predefinedScheme = "Catppuccin";
        darkMode = true;
        schedulingMode = "off";
        manualSunrise = "06:30";
        manualSunset = "18:30";
        matugenSchemeType = "scheme-fruit-salad";
      };

      templates = {
        activeTemplates = [
          {
            enabled = true;
            id = "gtk";
          }
          {
            enabled = true;
            id = "qt";
          }
          {
            enabled = true;
            id = "kcolorscheme";
          }
          {
            enabled = true;
            id = "fuzzel";
          }
          {
            enabled = true;
            id = "code";
          }
          {
            enabled = true;
            id = "yazi";
          }
          {
            enabled = true;
            id = "niri";
          }
          {
            enabled = true;
            id = "discord";
          }
        ];
        enableUserTemplates = false;
      };

      nightLight = {
        enabled = true;
        forced = false;
        autoSchedule = true;
        nightTemp = "4000";
        dayTemp = "6500";
        manualSunrise = "06:30";
        manualSunset = "18:30";
      };

      hooks = {
        enabled = false;
        wallpaperChange = "";
        darkModeChange = "";
        screenLock = "";
        screenUnlock = "";
        performanceModeEnabled = "";
        performanceModeDisabled = "";
        session = "";
      };

      desktopWidgets = {
        enabled = false;
        gridSnap = false;
        monitorWidgets = [ ];
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
    hypridle
  ];

  # Hypridle configuration for screen locking and DPMS
  # Uses noctalia-shell lock screen
  #
  # How it works:
  # 1. At 300s idle: Lock screen via noctalia-shell
  # 2. At 360s idle: Monitors power off (60s after lock)
  #
  # For manual lock: use Mod+Escape keybinding
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${lockScreen}";
        before_sleep_cmd = "${lockScreen}";
        after_sleep_cmd = "${resumeScreen}";
        ignore_dbus_inhibit = false;
      };
      listener = [
        {
          # Lock screen after 5 minutes of idle
          timeout = 300;
          on-timeout = "${lockScreen}";
        }
        {
          # Power off monitors 60s after lock (360s total)
          timeout = 360;
          on-timeout = "${pkgs.niri}/bin/niri msg action power-off-monitors";
          on-resume = "${resumeScreen}";
        }
      ];
    };
  };

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
