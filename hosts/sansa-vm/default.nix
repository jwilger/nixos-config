{
  pkgs,
  lib,
  username,
  ...
}:
let
  run0Bin = lib.getExe' pkgs.systemd "run0";
  sudoAskpass = pkgs.writeShellScript "sudo-askpass" ''
    ${lib.getExe pkgs.zenity} --password \
      --title="Authentication required" \
      --text="''${1:-Password required}" \
      --width=360
  '';
in
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    ./../../modules/desktop
    ./../../modules/services/postgres.nix
    ./../../modules/services/caddy.nix
    ./../../modules/services/hindsight.nix
  ];

  networking = {
    hostName = "sansa-vm";
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

  # Apple Silicon VMs run the NixOS aarch64 installer natively.
  nixpkgs.hostPlatform = "aarch64-linux";

  # The generated x86 VM profile uses kvm-intel; this host is arm64.
  boot.kernelModules = lib.mkForce [ ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  boot.loader.efi = {
    canTouchEfiVariables = lib.mkForce false;
    efiSysMountPoint = "/boot";
  };

  # qemu/UTM-style VMs commonly expose the disk as /dev/vda.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.useOSProber = false;

  fileSystems."/".noCheck = false;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 0;
    "vm.swappiness" = 100;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  # Allow local remote access to make it easier to toy around with the system.
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = lib.mkForce true;
    };
  };

  users.users.${username} = {
    initialPassword = "test";
    extraGroups = [
      "docker"
    ];
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.pulseaudio.enable = false;

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  services.smartd.enable = lib.mkForce false;
  services.btrfs.autoScrub.enable = lib.mkForce false;

  systemd.services.journal-archive.enable = lib.mkForce false;
  systemd.timers.journal-archive.enable = lib.mkForce false;

  virtualisation.vmVariant = {
    virtualisation.graphics = true;
    services.timesyncd.enable = lib.mkForce true;
  };

  boot.initrd.luks.devices = { };

  home-manager.users.${username}.imports = [ ./../../modules/home/desktop ];

  systemd.tmpfiles.rules = [
    "L+ /etc/nixos - - - - /home/${username}/nixos-config"
  ];

  virtualisation = {
    docker = {
      enable = true;
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

  environment.variables.SUDO_ASKPASS = sudoAskpass;

  time.timeZone = "America/Los_Angeles";

  environment.systemPackages = with pkgs; [
    fuse-overlayfs
    libimobiledevice
    mesa-demos
    vulkan-tools
    foot
    wezterm
    ifuse
    zenity
  ];
}
