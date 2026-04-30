{ pkgs, ... }:
{
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      extra-substituters = [
        "https://noctalia.cachix.org"
      ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };

  boot.tmp.cleanOnBoot = true;

  # Periodic data-integrity scrub for all btrfs filesystems on this box.
  # Catches silent bit-rot; auto-corrects on RAID1 mirrors when a checksum
  # mismatch is found and a good copy exists.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [
      "/"
      "/home"
      "/archive"
    ];
  };

  # SMART monitoring for all attached drives. `wall` notifications are
  # broadcast to logged-in TTYs; switch to mail when an SMTP relay is
  # configured.
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications = {
      test = false;
      wall.enable = true;
    };
  };

  # Pre-create directories used as targets on /archive (cold-tier
  # snapshots, archived journals). /var/lib/docker is provisioned as a
  # dedicated btrfs subvolume on the home pool — see fileSystems entry
  # in hosts/gregor/hardware-configuration.nix — so it's not a tmpfiles
  # concern.
  systemd.tmpfiles.rules = [
    "d /archive/snapshots 0700 root root -"
    "d /archive/snapshots/home 0700 root root -"
    "d /archive/snapshots/root 0700 root root -"
    "d /archive/journal-archive 0700 root root -"
  ];

  # Cap the live journal so /var/log doesn't accumulate on the NVMe, and
  # rotate aggressively (daily) so the archive timer below has fresh
  # sealed files to copy off before the cap purges them.
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxRetentionSec=2week
    MaxFileSec=1day
  '';

  # Cold-tier journal retention: copy sealed (rotated) journal files
  # from /var/log/journal -> /archive/journal-archive once a day. Sealed
  # files are immutable, so cp -n is idempotent. Active files (without
  # '@' in the name) are skipped because journald is still writing them.
  # Read archived logs later with:
  #   sudo journalctl --directory=/archive/journal-archive/<machine-id>
  systemd.services.journal-archive = {
    description = "Archive sealed systemd journal files to /archive";
    after = [
      "systemd-journald.service"
      "archive.mount"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "journal-archive" ''
        set -euo pipefail
        live=/var/log/journal
        dest=/archive/journal-archive
        [ -d "$live" ] || exit 0
        ${pkgs.findutils}/bin/find "$live" -type f \
          \( -name 'system@*.journal' -o -name 'user-*@*.journal' \) \
          -print0 \
          | while IFS= read -r -d "" f; do
              rel="''${f#$live/}"
              target="$dest/$rel"
              ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$target")"
              ${pkgs.coreutils}/bin/cp -n "$f" "$target"
            done
      '';
    };
  };
  systemd.timers.journal-archive = {
    description = "Daily archive of sealed systemd journal files";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    git
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.11";
  system.autoUpgrade.enable = true;

  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "lavender";
  };
}
