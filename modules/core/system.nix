{ pkgs, inputs, ...}: 
{
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  nixpkgs = {
    overlays = [
      inputs.nur.overlays.default
      (self: super: {
        xkeyboard-config = super.xkeyboard-config.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or []) ++ [ ./patches/xkeyboard-config-kinesis.patch ];
        });
      })
    ];
  };

  environment.systemPackages = with pkgs; [
    wget
    git
    bcachefs-tools
    # OverlayFS support
    fuse-overlayfs
    # System firmware blobs
    linux-firmware
  ];

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.11";
  # Enable automatic NixOS upgrades to reduce drift
  system.autoUpgrade.enable = true;

  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "lavender";
  };

  # (Removed) Legacy fsck-at-boot option no longer exists; investigate new fsck options if needed
  # Enable kernel module for ZRAM
  boot.kernelModules = [ "zram" ];
  # Disable LUKS probes for non-LUKS root to silence initrd errors
  # (Empty attribute set replaces deprecated list syntax)
  boot.initrd.luks.devices = {};
}
