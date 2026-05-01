{
  pkgs,
  username,
  lib,
  ...
}:
let
  run0Bin = lib.getExe' pkgs.systemd "run0";
in
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    ./../../modules/desktop
    ./../../modules/hardware/edid-apple-studio-display.nix
    ./../../modules/services/postgres.nix
    ./../../modules/services/forgejo.nix
    ./../../modules/services/caddy.nix
  ];

  powerManagement.cpuFreqGovernor = "performance";

  networking = {
    hostName = "gregor";
    firewall = {
      allowedTCPPorts = [
        22
        80
        443
        2222 # Forgejo SSH
        3000 # Development server
        3001 # Development server
        4070 # Spotify Connect TCP port
      ];
      # allow DNS over UDP and Spotify Connect discovery
      allowedUDPPorts = [
        53 # DNS
        5353 # mDNS (multicast DNS) - required for Spotify Connect discovery
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

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Enable AMD redistributable firmware
  hardware.enableRedistributableFirmware = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 0;
    "vm.swappiness" = 100;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    fuse-overlayfs
    linux-firmware
    docker-compose
    libimobiledevice
    ifuse
    lxqt.lxqt-openssh-askpass # Qt-based askpass matching lxqt-policykit theme
  ];

  environment.variables.SUDO_ASKPASS = "${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass";

  time.timeZone = "America/Los_Angeles";

  boot.initrd.luks.devices = { };

  home-manager.users.${username}.imports = [ ./../../modules/home/desktop ];

  # Add user to groups for Docker and shared Steam library access
  users.users.${username}.extraGroups = [
    "docker"
  ];

  # Manage the virtualisation services
  virtualisation = {
    docker = {
      enable = true;
      daemon.settings = {
        storage-driver = "btrfs";
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
