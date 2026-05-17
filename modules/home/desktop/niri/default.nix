{
  pkgs,
  lib,
  ...
}:
let
  wallpaper = ../wallpaper.png;

  # Catppuccin Mocha-themed screen locker. Also locks 1Password so it
  # drops its unlocked state — swaylock alone only blanks the session.
  # Used by the Mod+Escape keybind and by swayidle (idle + before-sleep).
  lockScreen = pkgs.writeShellScript "lock-screen" ''
    ${pkgs._1password-gui}/bin/1password --lock &
    ${pkgs.procps}/bin/pidof swaylock >/dev/null || exec ${pkgs.swaylock}/bin/swaylock -f \
      --ignore-empty-password \
      --indicator-radius 100 \
      --indicator-thickness 8 \
      --color 1e1e2e \
      --inside-color 1e1e2e \
      --inside-clear-color 1e1e2e \
      --inside-ver-color 1e1e2e \
      --inside-wrong-color 1e1e2e \
      --ring-color cba6f7 \
      --ring-clear-color f9e2af \
      --ring-ver-color a6e3a1 \
      --ring-wrong-color f38ba8 \
      --key-hl-color f5c2e7 \
      --text-color cdd6f4 \
      --text-clear-color cdd6f4 \
      --text-ver-color cdd6f4 \
      --text-wrong-color cdd6f4 \
      --line-color 00000000 \
      --separator-color 00000000
  '';

  sudoAskpass = pkgs.writeShellScript "sudo-askpass" ''
    ${lib.getExe pkgs.zenity} --password \
      --title="Authentication required" \
      --text="''${1:-Password required}" \
      --width=360
  '';

  # Native idle handling (replaces noctalia's IdleService): lock after
  # 5 min, power monitors off after 6 min, and lock before suspend.
  idleService = pkgs.writeShellScript "idle-service" ''
    exec ${pkgs.swayidle}/bin/swayidle -w \
      timeout 300 '${lockScreen}' \
      timeout 360 'niri msg action power-off-monitors' \
        resume 'niri msg action power-on-monitors' \
      before-sleep '${lockScreen}'
  '';
in
{
  # ashell status bar config. ashell watches this file and hot-reloads on
  # change. It is launched via niri's spawn-at-startup (see programs.niri).
  xdg.configFile."ashell/config.toml".text = ''
    log_level = "warn"
    position = "Top"
    outputs = "All"
    # en-US region => imperial units (Fahrenheit) for the weather widget.
    region = "en-US"

    [modules]
    left = [ "AppLauncher", "Workspaces", "WindowTitle" ]
    center = [ "Tempo", "MediaPlayer" ]
    right = [ "SystemInfo", [ "Tray", "Privacy", "Notifications", "Settings" ] ]

    [[CustomModule]]
    name = "AppLauncher"
    type = "Button"
    icon = ""
    command = "fuzzel"

    [workspaces]
    visibility_mode = "All"
    group_by_monitor = false
    enable_workspace_filling = true

    [window_title]
    mode = "Title"
    truncate_title_after_length = 30

    [tempo]
    clock_format = "%H:%M %a, %b %d"
    weather_location = { Coordinates = [ 45.5198, -123.1107 ] }
    weather_indicator = "IconAndTemperature"

    [system_info]
    indicators = [ "Cpu", "Memory", "Temperature" ]
    interval = 5

    [system_info.cpu]
    warn_threshold = 80
    alert_threshold = 90

    [system_info.memory]
    warn_threshold = 80
    alert_threshold = 90

    [system_info.temperature]
    warn_threshold = 80
    alert_threshold = 90
    sensor = "coretemp Package id 0"

    [notifications]
    format = "%H:%M"
    show_timestamps = true
    show_bodies = true
    toast = true
    toast_position = "top_right"
    toast_timeout = 5000
    toast_limit = 5

    [settings]
    lock_cmd = "${lockScreen}"
    audio_sinks_more_cmd = "pwvucontrol"
    audio_sources_more_cmd = "pwvucontrol"
    indicators = [ "IdleInhibitor", "PowerProfile", "Audio", "Microphone", "Bluetooth", "Network" ]

    [osd]
    enabled = true
    timeout = 2000

    [animations]
    enabled = true

    [appearance]
    font_name = "JetBrainsMono Nerd Font Mono"
    style = "Solid"
    opacity = 0.8
    success_color = "#a6e3a1"
    warning_color = "#f9e2af"
    danger_color = "#f38ba8"
    text_color = "#cdd6f4"
    workspace_colors = [ "#cba6f7" ]

    [appearance.primary_color]
    base = "#cba6f7"
    text = "#11111b"

    [appearance.background_color]
    base = "#1e1e2e"
    weak = "#313244"
    strong = "#45475a"
    text = "#cdd6f4"

    [appearance.menu]
    opacity = 0.8
    backdrop = 0.3
  '';

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
        {
          command = [
            "${pkgs.swaybg}/bin/swaybg"
            "-i"
            "${wallpaper}"
            "-m"
            "fill"
          ];
        }
        { command = [ "${pkgs.ashell}/bin/ashell" ]; }
        { command = [ "${idleService}" ]; }
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
          "${mod}+Return".action.spawn = "kitty";
          "${mod}+Space".action.spawn = "fuzzel";
          "${mod}+E".action.spawn = "nautilus";
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

          # Media keys — routed through ashell so its OSD overlay appears
          "XF86AudioRaiseVolume".action.spawn-sh = "ashell msg volume-up";
          "XF86AudioLowerVolume".action.spawn-sh = "ashell msg volume-down";
          "XF86AudioMute".action.spawn-sh = "ashell msg volume-toggle-mute";
          "${mod}+M".action.spawn-sh = "ashell msg microphone-toggle-mute"; # Toggle microphone mute
          "XF86AudioPlay".action.spawn-sh = "playerctl play-pause";
          "XF86AudioNext".action.spawn-sh = "playerctl next";
          "XF86AudioPrev".action.spawn-sh = "playerctl previous";
          "XF86MonBrightnessUp".action.spawn-sh = "ashell msg brightness-up";
          "XF86MonBrightnessDown".action.spawn-sh = "ashell msg brightness-down";

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

  # Additional packages for the niri session.
  home.packages = with pkgs; [
    ashell # Status bar / shell
    swaylock # Screen locker
    swayidle # Idle daemon (auto-lock + DPMS)
    swaybg # Wallpaper
    fuzzel # Application launcher
    pwvucontrol # Audio mixer (opened from ashell settings panel)
    wl-clipboard
    grim
    slurp
  ];
}
