{ pkgs, lib, ... }:

# Steam Multi-Seat Gaming Module
#
# This module creates a complete Steam gaming "seat" on the system:
# - Dedicated steam user running as systemd service
# - Sway compositor in headless mode for 4K@60Hz rendering
# - wayvnc provides VNC server for Steam UI display (critical for rendering)
# - Steam with Remote Play for streaming to SteamLink/AppleTV
# - Independent audio/video from primary user session
# - Home directory: /home/steam-library (Steam stores games in ~/.local/share/Steam/)
#
# Based on: https://not.just-paranoid.net/steam-streaming-on-a-headless-linux-machine-with-wayland/
#
# The gaming session runs concurrently with the primary user's desktop
# environment via systemd services, allowing true simultaneous operation
# (workstation + gaming) without TTY login requirements.
#
# VNC Access (optional): Connect to port 5900 to see/control the Steam UI
#
# Initial SteamLink PIN Pairing:
#   1. sudo systemctl stop steam-gaming.service
#   2. sudo -u steam DISPLAY=$DISPLAY steam
#   3. Complete PIN pairing in Steam interface
#   4. Quit Steam
#   5. sudo systemctl start steam-gaming.service

{
  # Create dedicated steam user for gaming
  users.groups.steam = {
    gid = 985;
  };

  users.users.steam = {
    isSystemUser = true;
    description = "Steam Gaming User";
    uid = 987;
    group = "steam";

    # Essential groups for gaming functionality
    extraGroups = [
      "video" # GPU access
      "audio" # Audio devices
      "input" # Game controllers
      "pipewire" # Modern audio system
      "render" # DRM render nodes
    ];

    # Use existing steam-library directory as home
    # Steam will store games in /home/steam-library/.local/share/Steam/steamapps/
    home = "/home/steam-library";
    createHome = true;

    # Use bash for script execution
    shell = pkgs.bash;

    # Lock account - no password-based login allowed
    # Auto-login via getty doesn't require password
    # Admin can access via: sudo -u steam
    hashedPassword = "!";

    # Enable linger to keep user services (PipeWire) running persistently
    # Required for Steam Remote Play desktop capture in headless session
    linger = true;
  };

  # Systemd service for Steam gaming session with Sway + VNC
  # Runs as steam user, starts automatically on boot
  systemd.services.steam-gaming = {
    description = "Steam Gaming Session (Headless Sway + VNC)";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "systemd-user-sessions.service"
      "getty@tty1.service" # Wait for graphics initialization
    ];

    # Service configuration
    serviceConfig = {
      Type = "simple";
      User = "steam";
      Group = "steam";
      # Wrap with dbus-run-session to create session bus
      ExecStart = "${pkgs.dbus}/bin/dbus-run-session --dbus-daemon=${pkgs.dbus}/bin/dbus-daemon /etc/steam-sway-vnc-session";
      Restart = "on-failure";
      RestartSec = "10s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;

      # Resource limits
      LimitNOFILE = 1048576;

      # Systemd will create /run/user/987 automatically with proper permissions
      RuntimeDirectory = "user/987";
      RuntimeDirectoryMode = "0700";

      # Environment
      Environment = [
        "HOME=/home/steam-library"
        "XDG_RUNTIME_DIR=/run/user/987"
        "PATH=/run/current-system/sw/bin"
      ];
    };
  };

  # Enable Steam with all necessary features
  programs.steam = {
    enable = true;

    # Enable Remote Play for streaming to SteamLink devices
    remotePlay.openFirewall = true;

    # Enable dedicated server support
    dedicatedServer.openFirewall = true;

    # Additional packages for Steam ecosystem
    extraCompatPackages = with pkgs; [
      proton-ge-bin # GE-Proton for better game compatibility
    ];
  };

  # Sway and utilities for headless gaming session with VNC
  environment.systemPackages = with pkgs; [
    sway # Wayland compositor with headless backend support
    wayvnc # VNC server for Wayland - provides display for Steam UI
    lxterminal # Terminal for Sway session
    steam
    steam-run

    # Additional gaming utilities
    mangohud # Performance overlay
    gamemode # CPU governor optimization
  ];

  # Environment variables for Steam
  environment.sessionVariables = {
    # Point Steam to custom library location
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/steam-library/compatibilitytools.d";
  };

  # Sway configuration for headless output with VNC
  environment.etc."sway-headless-config" = {
    text = ''
      # Sway headless configuration for Steam Remote Play
      # Sets 4K@60Hz output resolution
      output HEADLESS-1 {
        resolution 3840x2160@60Hz
        scale 1
      }

      # Disable automatic dpms/screen blanking
      output * dpms on

      # Auto-start Steam in Big Picture mode
      exec steam -bigpicture
    '';
    mode = "0644";
  };

  # Create wrapper script for launching Sway headless + VNC + Steam
  environment.etc."steam-sway-vnc-session" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      # Steam Sway VNC Session Launcher
      #
      # Uses Sway headless + wayvnc to provide display for Steam UI
      # Based on: https://not.just-paranoid.net/steam-streaming-on-a-headless-linux-machine-with-wayland/

      set -euo pipefail

      # Start PipeWire for audio capture in background
      # Steam Remote Play requires PipeWire for audio streaming
      ${pkgs.pipewire}/bin/pipewire &
      PIPEWIRE_PID=$!

      # Start WirePlumber session manager in background
      ${pkgs.wireplumber}/bin/wireplumber &
      WIREPLUMBER_PID=$!

      # Start PipeWire PulseAudio compatibility in background
      ${pkgs.pipewire}/bin/pipewire-pulse &
      PIPEWIRE_PULSE_PID=$!

      # Wait for PipeWire to be ready
      for i in {1..30}; do
        if ${pkgs.pipewire}/bin/pw-cli info 0 &>/dev/null; then
          echo "PipeWire ready"
          break
        fi
        sleep 0.5
      done

      # Performance settings
      export MANGOHUD=1
      export MANGOHUD_CONFIG="fps,frametime,gpu_temp,cpu_temp"

      # Sway headless backend configuration
      export WLR_BACKENDS=headless
      export WLR_LIBINPUT_NO_DEVICES=1

      # Start Sway in background
      ${pkgs.sway}/bin/sway -c /etc/sway-headless-config &
      SWAY_PID=$!

      # Wait for Sway to be ready
      for i in {1..30}; do
        if [ -S "$XDG_RUNTIME_DIR/sway-ipc.sock" ]; then
          echo "Sway ready"
          break
        fi
        sleep 0.5
      done

      # Export Wayland display for Steam
      export WAYLAND_DISPLAY="$(ls -t "$XDG_RUNTIME_DIR"/wayland-* 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "wayland-0")"

      # Start wayvnc to provide VNC display for Steam UI
      # This allows Steam's UI to render (fixes black screen issue)
      exec ${pkgs.wayvnc}/bin/wayvnc 0.0.0.0
    '';
    mode = "0755";
  };

  # Firewall configuration for Steam Remote Play and VNC
  networking.firewall = {
    allowedTCPPorts = [
      5900 # VNC (wayvnc)
      27036 # Steam Remote Play
      27037 # Steam Remote Play
    ];
    allowedUDPPorts = [
      27031 # Steam Remote Play
      27036 # Steam Remote Play
    ];
  };

  # Enable GameMode for CPU governor optimization
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10; # Nice value for games
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  # Graphics and performance optimizations
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for 32-bit games
  };

  # Ensure required kernel modules for gaming
  boot.kernelModules = [ "uinput" ]; # For controller emulation

  # Allow uinput access for Steam Input
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  # Enable necessary services
  services.dbus.enable = true;
  security.polkit.enable = true;

  # Enable PipeWire for audio (required for Steam Remote Play)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Explicitly deny power management for steam user (security hardening)
  # Prevents remote gaming session from shutting down the workstation
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user == "steam" &&
          (action.id == "org.freedesktop.login1.power-off" ||
           action.id == "org.freedesktop.login1.reboot" ||
           action.id == "org.freedesktop.login1.suspend" ||
           action.id == "org.freedesktop.login1.hibernate")) {
        return polkit.Result.NO;
      }
    });
  '';
}
