{
  pkgs,
  username,
  lib,
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
    ./../../modules/hardware/edid-apple-studio-display.nix
  ];

  powerManagement.cpuFreqGovernor = "performance";

  networking = {
    hostName = "gregor";
    firewall = {
      allowedTCPPorts = lib.mkForce [ 22 ];
      allowedTCPPortRanges = lib.mkForce [ ];
      allowedUDPPorts = lib.mkForce [ 5353 ];
      allowedUDPPortRanges = lib.mkForce [ ];
    };
  };
  # Ensure filesystem checks (fsck) occur at boot for root
  fileSystems."/".noCheck = false;

  hardware = {
    bluetooth = {
      enable = lib.mkForce false;
      powerOnBoot = lib.mkForce false;
    };
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

  environment.systemPackages = with pkgs; [
    fuse-overlayfs
    linux-firmware
    docker-compose
    libimobiledevice
    ifuse
    zenity
  ];

  environment.variables.SUDO_ASKPASS = sudoAskpass;

  time.timeZone = "America/Los_Angeles";

  boot.initrd.luks.devices = { };

  # Gregor is retained only as an SSH-accessible file source while its work
  # moves to sansa-vm. Keep core networking, mDNS, storage maintenance, and
  # SSH protection, but suppress workstation services inherited from core.
  home-manager.users.${username}.imports = [ ./../../modules/home ];
  programs.dconf.enable = lib.mkForce false;
  security.polkit.enable = true;
  security.rtkit.enable = lib.mkForce false;
  services.avahi.allowInterfaces = [ "eno1" ];
  services.avahi.enable = lib.mkForce true;
  services.avahi.publish.addresses = true;
  services.avahi.publish.enable = true;
  services.blueman.enable = lib.mkForce false;
  services.gvfs.enable = lib.mkForce false;
  services.neo4j.enable = lib.mkForce false;
  services.pcscd.enable = lib.mkForce false;
  services.printing.enable = lib.mkForce false;
  services.udisks2.enable = lib.mkForce false;
  services.upower.enable = lib.mkForce false;
  systemd.services.neo4j.enable = lib.mkForce false;
  users.users.${username}.linger = false;

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

}
