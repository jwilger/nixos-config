{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Script to lock screen and schedule monitor power-off after 60 seconds
  # Uses systemd-run for reliable timer management
  lockAndSchedulePowerOff = pkgs.writeShellScript "lock-and-power-off" ''
    # Cancel any existing power-off timer AND service (both must be stopped)
    ${pkgs.systemd}/bin/systemctl --user stop screen-power-off.timer 2>/dev/null || true
    ${pkgs.systemd}/bin/systemctl --user stop screen-power-off.service 2>/dev/null || true
    ${pkgs.systemd}/bin/systemctl --user reset-failed screen-power-off.service 2>/dev/null || true

    # Lock the screen
    ${noctaliaPkg}/bin/noctalia-shell ipc call lockScreen lock

    # Schedule monitor power-off in 60 seconds using a transient systemd timer
    # RemainAfterElapse=no ensures the timer is cleaned up after firing
    ${pkgs.systemd}/bin/systemd-run --user \
      --unit=screen-power-off \
      --on-active=60s \
      --timer-property=AccuracySec=1s \
      --timer-property=RemainAfterElapse=no \
      ${pkgs.niri}/bin/niri msg action power-off-monitors
  '';

  # Script to cancel the power-off timer (called when user becomes active)
  cancelPowerOffTimer = pkgs.writeShellScript "cancel-power-off-timer" ''
    ${pkgs.systemd}/bin/systemctl --user stop screen-power-off.timer 2>/dev/null || true
    ${pkgs.systemd}/bin/systemctl --user stop screen-power-off.service 2>/dev/null || true
  '';

  # Screen dimmer overlay using GTK4 + layer-shell
  # Shows a dark transparent overlay with warning text that fades in
  # Cancellable on ANY user input (keyboard, mouse, touch) with smooth fade-out
  # CRITICAL: ctypes.CDLL must load gtk4-layer-shell BEFORE any gi imports
  # This is because gtk4-layer-shell uses symbol interposition to shim libwayland
  screenDimmerPython = pkgs.writeText "screen-dimmer.py" ''
    # MUST be first - load gtk4-layer-shell before gi imports (symbol interposition requirement)
    import ctypes
    import os
    import sys
    # Use RTLD_GLOBAL to make symbols available to subsequently loaded libraries
    ctypes.CDLL(os.environ.get("GTK4_LAYER_SHELL_PATH", "libgtk4-layer-shell.so"), mode=ctypes.RTLD_GLOBAL)

    import gi
    gi.require_version("Gtk", "4.0")
    gi.require_version("Gtk4LayerShell", "1.0")
    from gi.repository import Gtk, Gtk4LayerShell, GLib, Gdk

    class ScreenDimmer(Gtk.Application):
        def __init__(self, duration_ms=30000, target_opacity=0.7):
            super().__init__(application_id="org.niri.screendimmer")
            self.duration_ms = duration_ms
            self.target_opacity = target_opacity
            self.current_opacity = 0.0
            self.cancelled = False

        def do_activate(self):
            win = Gtk.ApplicationWindow(application=self)

            # Set up layer shell - fullscreen overlay on all monitors
            Gtk4LayerShell.init_for_window(win)
            Gtk4LayerShell.set_layer(win, Gtk4LayerShell.Layer.OVERLAY)
            Gtk4LayerShell.set_anchor(win, Gtk4LayerShell.Edge.TOP, True)
            Gtk4LayerShell.set_anchor(win, Gtk4LayerShell.Edge.BOTTOM, True)
            Gtk4LayerShell.set_anchor(win, Gtk4LayerShell.Edge.LEFT, True)
            Gtk4LayerShell.set_anchor(win, Gtk4LayerShell.Edge.RIGHT, True)
            Gtk4LayerShell.set_exclusive_zone(win, -1)  # Don't reserve space, cover everything
            
            # CRITICAL: Enable keyboard input for cancellation detection
            # ON_DEMAND allows us to receive input without permanently stealing focus
            Gtk4LayerShell.set_keyboard_mode(win, Gtk4LayerShell.KeyboardMode.ON_DEMAND)

            # Input event controllers for cancellation on ANY input
            key_controller = Gtk.EventControllerKey()
            key_controller.connect("key-pressed", self.on_cancel_input)
            win.add_controller(key_controller)
            
            motion_controller = Gtk.EventControllerMotion()
            motion_controller.connect("motion", self.on_cancel_input)
            win.add_controller(motion_controller)
            
            click_controller = Gtk.GestureClick()
            click_controller.connect("pressed", self.on_cancel_input)
            win.add_controller(click_controller)

            # UI layout with warning and cancellation hint
            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
            box.set_halign(Gtk.Align.CENTER)
            box.set_valign(Gtk.Align.CENTER)
            
            warning_label = Gtk.Label(label="⚠ Screen locking in 30 seconds")
            warning_label.add_css_class("warning-text")
            
            hint_label = Gtk.Label(label="Move mouse or press any key to cancel")
            hint_label.add_css_class("hint-text")
            
            box.append(warning_label)
            box.append(hint_label)
            win.set_child(box)

            # Styling - Catppuccin Mocha colors with prominent warning
            css = Gtk.CssProvider()
            css.load_from_string("""
                window { 
                    background-color: rgba(0, 0, 0, 0.7); 
                }
                .warning-text {
                    color: #f38ba8;
                    font-size: 48px;
                    font-weight: bold;
                    text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.8);
                }
                .hint-text {
                    color: #cdd6f4;
                    font-size: 24px;
                    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.6);
                }
            """)
            Gtk.StyleContext.add_provider_for_display(
                Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )

            # Start fully transparent and fade in
            win.set_opacity(0.0)
            win.present()
            self.win = win

            # Fade in over 2 seconds (100 steps, 20ms each)
            self.fade_steps = 100
            self.fade_interval = 20
            GLib.timeout_add(self.fade_interval, self.fade_in_step)

            # Auto-quit after 30s if not cancelled (lock will happen at 300s anyway)
            GLib.timeout_add(self.duration_ms, self.auto_quit)

        def fade_in_step(self):
            """Fade in animation - stops if cancelled"""
            if self.cancelled:
                return False
            self.current_opacity = min(
                self.current_opacity + (self.target_opacity / self.fade_steps),
                self.target_opacity
            )
            self.win.set_opacity(self.current_opacity)
            return self.current_opacity < self.target_opacity

        def on_cancel_input(self, *args):
            """Called on ANY input event (keyboard, mouse, touch) - cancel and fade out"""
            if not self.cancelled:
                self.cancelled = True
                # Start smooth fade-out animation
                GLib.timeout_add(16, self.fade_out_step)
            return True

        def fade_out_step(self):
            """Fade out animation over ~400ms (25 steps, 16ms each)"""
            self.current_opacity = max(self.current_opacity - 0.04, 0.0)
            self.win.set_opacity(self.current_opacity)
            if self.current_opacity <= 0.0:
                self.quit()
                return False
            return True

        def auto_quit(self):
            """Auto-quit after timeout if not cancelled"""
            if not self.cancelled:
                self.quit()
            return False

    app = ScreenDimmer()
    sys.exit(app.run(None))
  '';

  # Wrapper script - passes gtk4-layer-shell path via environment variable
  # The Python script uses ctypes.CDLL with RTLD_GLOBAL for proper symbol interposition
  # CRITICAL: GI_TYPELIB_PATH must include BOTH gtk4 AND gtk4-layer-shell typelib directories
  lockWarning = pkgs.writeShellScript "lock-warning" ''
    export GTK4_LAYER_SHELL_PATH="${pkgs.gtk4-layer-shell}/lib/libgtk4-layer-shell.so"
    export GI_TYPELIB_PATH="${pkgs.gtk4}/lib/girepository-1.0:${pkgs.gtk4-layer-shell}/lib/girepository-1.0:''${GI_TYPELIB_PATH:-}"
    exec ${pkgs.python3.withPackages (ps: [ ps.pygobject3 ])}/bin/python3 ${screenDimmerPython}
  '';

  # Script to cancel the warning (kill the dimmer process)
  cancelWarning = pkgs.writeShellScript "cancel-warning" ''
    # Kill the screen dimmer if running
    ${pkgs.procps}/bin/pkill -f "screen-dimmer.py" 2>/dev/null || true

    # Also cancel power-off timer and service if running
    ${pkgs.systemd}/bin/systemctl --user stop screen-power-off.timer 2>/dev/null || true
    ${pkgs.systemd}/bin/systemctl --user stop screen-power-off.service 2>/dev/null || true
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

          # Lock screen (Mod+Escape) - locks and schedules monitor power-off in 60s
          "${mod}+Escape".action.spawn = "${lockAndSchedulePowerOff}";

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
    swaylock
    swayidle
    libnotify # For lock warning notifications
  ];

  # Swayidle configuration for screen locking and DPMS
  #
  # How it works:
  # 1. At 270s idle: Show fullscreen dimmer overlay with "Screen locking soon" message
  # 2. At 300s idle: Lock screen via noctalia-shell + start 60s systemd timer for monitor power-off
  # 3. 60s after lock: Monitors power off via systemd-run transient timer
  # 4. On activity during warning: Dimmer killed, timer cancelled, normal operation resumes
  # 5. On activity after monitors off: Wayland auto-wakes monitors
  #
  # For manual lock: use Mod+Escape keybinding (same behavior as idle lock)
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        # Show notification warning 30 seconds before lock
        timeout = 270;
        command = "${lockWarning}";
        # Kill dimmer overlay and cancel power-off timer if user becomes active
        resumeCommand = "${cancelWarning}";
      }
      {
        # Lock screen after 5 minutes of idle, schedule power-off 60s later
        timeout = 300;
        command = "${lockAndSchedulePowerOff}";
      }
    ];
    events = {
      # Lock before sleep (use the script so monitors also turn off after sleep)
      before-sleep = "${lockAndSchedulePowerOff}";
      # Also lock on systemd lock signal (e.g., loginctl lock-session)
      lock = "${lockAndSchedulePowerOff}";
    };
  };

  # Swaylock - just enable it, let catppuccin handle theming
  programs.swaylock.enable = true;

  # Systemd user service for monitor power-off (alternative to systemd-run transient timer)
  # This provides better observability and reliability compared to transient timers
  # To use this instead of transient timers, modify lockAndSchedulePowerOff to use:
  #   systemctl --user start screen-power-off.timer
  # instead of systemd-run
  systemd.user.services.screen-power-off = {
    Unit = {
      Description = "Power off monitors after screen lock";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.niri}/bin/niri msg action power-off-monitors";
      RemainAfterExit = false;
    };
  };

  systemd.user.timers.screen-power-off = {
    Unit = {
      Description = "Timer for monitor power-off after lock (60 seconds)";
    };

    Timer = {
      OnActiveSec = "60s";
      AccuracySec = "1s";
    };

    Install = {
      WantedBy = [ ]; # Not auto-started, only triggered by lock script
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
