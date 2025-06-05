{ pkgs, username, ... }:
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
      ];
      # allow DNS over UDP
      allowedUDPPorts = [ 53 ];
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
  ];

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
}
