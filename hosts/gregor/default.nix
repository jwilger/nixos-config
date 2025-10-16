{ pkgs, username, lib, ... }:
let
  cosmicAskpass = pkgs.writeShellApplication {
    name = "cosmic-sudo-askpass";
    runtimeInputs = [ pkgs.yad ];
    text = ''
      set -euo pipefail

      response="$(${pkgs.yad}/bin/yad \
        --entry \
        --hide-text \
        --title="Administrator Access Required" \
        --text="Enter your password to continue." \
        --image=dialog-password \
        --button=gtk-cancel:1 \
        --button=gtk-ok:0 \
        --center \
        --on-top \
        --skip-taskbar \
        --borders=16 \
        --geometry=360x160 \
        --window-icon=dialog-password \
      )"
      status=$?
      if [ "$status" -ne 0 ]; then
        exit "$status"
      fi

      printf "%s" "$response"
    '';
  };
  run0Bin = lib.getExe' pkgs.systemd "run0";
in
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    ./../../modules/desktop
  ];

  powerManagement.cpuFreqGovernor = "performance";

  networking = {
    hostName = "gregor";
    firewall = {
      allowedTCPPorts = [
        22
        80
        443
        4070  # Spotify Connect TCP port
      ];
      # allow DNS over UDP and Spotify Connect discovery
      allowedUDPPorts = [ 
        53    # DNS
        5353  # mDNS (multicast DNS) - required for Spotify Connect discovery
        57621 # Spotify Connect
      ];
    };
  };
  # Ensure filesystem checks (fsck) occur at boot for root
  fileSystems."/".noCheck = false;

  hardware = {
    graphics = {
      enable = true;
    };
  };

  # Blacklist noisy, unused sensor driver
  boot.blacklistedKernelModules = [ "hid_sensor_rotation" ];

  # Enable AMD redistributable firmware
  hardware.enableRedistributableFirmware = true;

  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.pulseaudio.enable = false;

  # BcacheFS scrub service & timer
  systemd.services.bcachefs-scrub = {
    description = "Scrub BcacheFS filesystems";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.bcachefs-tools}/bin/bcachefs"
        "scrub"
        "/"
      ];
    };
    wantedBy = [ "multi-user.target" ];
  };
  systemd.timers.bcachefs-scrub = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 03:00";
      Persistent = true;
    };
  };

  environment.systemPackages = with pkgs; [
    bcachefs-tools
    fuse-overlayfs
    linux-firmware
    docker-compose
    libimobiledevice
    ifuse
    cosmicAskpass
  ];

  environment.variables.SUDO_ASKPASS = "${cosmicAskpass}/bin/cosmic-sudo-askpass";

  time.timeZone = "America/Los_Angeles";

  boot.initrd.luks.devices = { };

  home-manager.users.${username}.imports = [ ./../../modules/home/desktop ];

  # Add user to libvirtd group
  users.users.${username}.extraGroups = [ "docker" ];

  # Manage the virtualisation services
  virtualisation = {
    docker = {
      enable = true;
      daemon.settings = {
        storage-driver = "vfs";
      };
      rootless = {
        enable = false;
      };
    };
  };

  services.usbmuxd.enable = true;

  programs.zsh.shellAliases = {
    sudo = run0Bin;
  };

  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults env_keep += "SUDO_ASKPASS DISPLAY WAYLAND_DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS"
      Defaults timestamp_timeout=0
    '';
  };

  systemd.services.hotplug-monitor = {
    description = "Trigger DRM hotplug and rescan";
    serviceConfig.Type = "oneshot";
    path = [ pkgs.systemd ];
    script = ''
      udevadm trigger --subsystem-match=drm --action=change
    '';
  };

  services.udev.extraRules = lib.mkAfter ''
    ACTION=="change", SUBSYSTEM=="drm", KERNEL=="card0", RUN+="${pkgs.systemd}/bin/systemctl start hotplug-monitor.service"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{product}=="Studio Display", RUN+="${pkgs.systemd}/bin/systemctl start hotplug-monitor.service"
  '';
}
