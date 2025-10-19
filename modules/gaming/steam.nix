{ pkgs, lib, ... }:

# Steam Multi-Seat Gaming Module
#
# This module creates a complete Steam gaming "seat" on the system:
# - Dedicated steam user with auto-login on tty8 ONLY
# - Gamescope compositor for headless 4K@60Hz rendering
# - Steam with Remote Play for streaming to SteamLink/AppleTV
# - Independent audio/video from primary user session
# - Home directory: /home/steam-library (Steam stores games in ~/.local/share/Steam/)
#
# The gaming session runs concurrently with the primary user's desktop
# environment, allowing true simultaneous operation (workstation + gaming).
#
# IMPORTANT: Auto-login is scoped ONLY to tty8. The primary desktop
# (cosmic-greeter on tty1) is unaffected and requires manual login.

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
  };

  # Override getty@tty8 specifically for steam user auto-login
  # This ONLY affects tty8 - all other ttys (including tty1 with cosmic-greeter) are unaffected
  systemd.services."getty@tty8" = {
    wantedBy = [ "multi-user.target" ]; # Enable auto-start on boot
    overrideStrategy = "asDropin";
    serviceConfig = {
      # Auto-login the steam user on tty8 only
      ExecStart = [
        "" # Clear the default
        "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${pkgs.shadow}/bin/login --autologin steam --noclear %I $TERM"
      ];
    };
  };

  # Auto-start gamescope session when steam user logs in on tty8
  # Create .bash_profile via activation script (runs as root during rebuild)
  system.activationScripts.steamBashProfile = ''
        cat > /home/steam-library/.bash_profile << 'EOF'
    # Auto-launch Steam in gamescope on tty8
    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty8" ]; then
      exec /etc/steam-gamescope-session
    fi
    EOF
        chown steam:steam /home/steam-library/.bash_profile
        chmod 644 /home/steam-library/.bash_profile
  '';

  # Enable Steam with all necessary features
  programs.steam = {
    enable = true;

    # Enable Remote Play for streaming to SteamLink devices
    remotePlay.openFirewall = true;

    # Enable dedicated server support
    dedicatedServer.openFirewall = true;

    # Enable gamescope session support
    gamescopeSession.enable = true;

    # Additional packages for Steam ecosystem
    extraCompatPackages = with pkgs; [
      proton-ge-bin # GE-Proton for better game compatibility
    ];
  };

  # Enable gamescope compositor
  programs.gamescope = {
    enable = true;

    # Gamescope with hardware acceleration
    capSysNice = true; # Allow niceness adjustment for better performance

    # Environment variables for optimal performance
    env = {
      # Force AMD GPU usage
      DRI_PRIME = "1";

      # Enable Vulkan layers
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";

      # Gamescope-specific optimizations
      GAMESCOPE_LIMITER_FILE = "/tmp/gamescope-limiter";
    };
  };

  # Gamescope package with args for the steam user's session
  # These will be used by the autologin script
  environment.systemPackages = with pkgs; [
    gamescope
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

  # Create wrapper script for launching Steam in gamescope
  environment.etc."steam-gamescope-session" = {
    text = ''
      #!/usr/bin/env bash
      # Steam Gamescope Session Launcher (Headless Mode)
      #
      # This script launches Steam in gamescope headless mode for 4K@60Hz streaming
      # to SteamLink/AppleTV. Headless mode uses GPU render nodes (no DRM master needed),
      # allowing simultaneous operation with COSMIC desktop on the same GPU.

      set -euo pipefail

      # Gamescope configuration
      GAMESCOPE_WIDTH=3840
      GAMESCOPE_HEIGHT=2160
      GAMESCOPE_REFRESH=60

      # Performance settings
      export ENABLE_VKBASALT=0
      export MANGOHUD=1
      export MANGOHUD_CONFIG="fps,frametime,gpu_temp,cpu_temp"

      # Launch gamescope in headless mode with Steam in Big Picture mode
      # --backend headless: Use render nodes only (no DRM connector, no conflict with COSMIC)
      # --prefer-vk-device: Explicit AMD GPU selection
      # -e: Enable Steam integration for Remote Play
      # -pipewire -pipewire-dmabuf: Enable PipeWire capture for streaming
      exec ${pkgs.gamescope}/bin/gamescope \
        --backend headless \
        --prefer-vk-device /dev/dri/renderD128 \
        -w "$GAMESCOPE_WIDTH" \
        -h "$GAMESCOPE_HEIGHT" \
        -r "$GAMESCOPE_REFRESH" \
        -e \
        --adaptive-sync \
        --force-grab-cursor \
        --steam \
        -- ${pkgs.steam}/bin/steam -bigpicture -pipewire -pipewire-dmabuf
    '';
    mode = "0755";
  };

  # Firewall configuration for Steam Remote Play
  networking.firewall = {
    allowedTCPPorts = [
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
