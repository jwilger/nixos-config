{
  config,
  lib,
  pkgs,
  ...
}:
let
  sopsFile = ./../../secrets/backblaze.yaml;
  sourceMount = "/run/restic-backups-backblaze/source";
in
{
  sops.secrets = {
    "backblaze/key-id" = { inherit sopsFile; };
    "backblaze/application-key" = { inherit sopsFile; };
    "backblaze/restic-password" = { inherit sopsFile; };
  };

  sops.templates."backblaze-restic.env" = {
    mode = "0400";
    content = ''
      AWS_ACCESS_KEY_ID=${config.sops.placeholder."backblaze/key-id"}
      AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."backblaze/application-key"}
      AWS_DEFAULT_REGION=us-west-004
      RESTIC_REPOSITORY=s3:https://s3.us-west-004.backblazeb2.com/gregor-restic-backups/restic
      RESTIC_PASSWORD=${config.sops.placeholder."backblaze/restic-password"}
    '';
  };

  services.restic.backups.backblaze = {
    environmentFile = config.sops.templates."backblaze-restic.env".path;
    initialize = true;
    inhibitsSleep = true;
    paths = [ sourceMount ];
    extraBackupArgs = [
      "--host=gregor"
      "--tag=btrbk-home"
    ];
    timerConfig = {
      OnCalendar = "*-*-* 05:00:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
    backupPrepareCommand = ''
      set -euo pipefail

      snapshot="$(${pkgs.findutils}/bin/find /archive/snapshots/home \
        -mindepth 1 -maxdepth 1 -type d -name 'home.*' -print \
        | ${pkgs.coreutils}/bin/sort \
        | ${pkgs.coreutils}/bin/tail -n 1)"

      if [ -z "$snapshot" ]; then
        echo "No replicated home snapshot exists under /archive/snapshots/home" >&2
        exit 1
      fi

      snapshot_stamp="''${snapshot##*.}"
      if ! snapshot_epoch="$(${pkgs.coreutils}/bin/date --date="''${snapshot_stamp:0:4}-''${snapshot_stamp:4:2}-''${snapshot_stamp:6:2} ''${snapshot_stamp:9:2}:''${snapshot_stamp:11:2}" +%s)"; then
        echo "Cannot parse snapshot timestamp from $snapshot" >&2
        exit 1
      fi

      snapshot_age=$(($(${pkgs.coreutils}/bin/date +%s) - snapshot_epoch))
      if [ "$snapshot_age" -lt 0 ] || [ "$snapshot_age" -gt 86400 ]; then
        echo "Newest home snapshot is not within the last 24 hours: $snapshot" >&2
        exit 1
      fi

      if [ "$(${pkgs.btrfs-progs}/bin/btrfs property get -ts "$snapshot" ro)" != "ro=true" ]; then
        echo "Newest home snapshot is not read-only: $snapshot" >&2
        exit 1
      fi

      received_uuid="$(${pkgs.btrfs-progs}/bin/btrfs subvolume show "$snapshot" \
        | ${pkgs.gnused}/bin/sed -n 's/^[[:space:]]*Received UUID:[[:space:]]*//p')"
      if [ -z "$received_uuid" ] || [ "$received_uuid" = "-" ]; then
        echo "Newest home snapshot is not a completed btrfs receive: $snapshot" >&2
        exit 1
      fi

      if ${pkgs.util-linux}/bin/mountpoint -q ${sourceMount}; then
        echo "Refusing to stack a backup mount on the existing ${sourceMount}" >&2
        exit 1
      fi

      ${pkgs.coreutils}/bin/install -d -m 0700 ${sourceMount}
      ${pkgs.util-linux}/bin/mount --bind "$snapshot" ${sourceMount}
      ${pkgs.util-linux}/bin/mount -o remount,bind,ro ${sourceMount}
    '';
    backupCleanupCommand = ''
      if ${pkgs.util-linux}/bin/mountpoint -q ${sourceMount}; then
        ${pkgs.util-linux}/bin/umount --recursive ${sourceMount} \
          || ${pkgs.util-linux}/bin/umount --lazy ${sourceMount}
      fi
    '';
  };

  services.restic.backups.backblaze-maintenance = {
    environmentFile = config.sops.templates."backblaze-restic.env".path;
    paths = [ ];
    pruneOpts = [
      "--keep-daily=14"
      "--keep-weekly=8"
      "--keep-monthly=12"
    ];
    runCheck = true;
    timerConfig = {
      OnCalendar = "Sun *-*-* 07:00:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  systemd.services.restic-backups-backblaze = {
    after = [ "btrbk-gregor.service" ];
    serviceConfig = {
      PrivateTmp = lib.mkForce false;
      RuntimeDirectoryMode = "0700";
    };
    unitConfig.RequiresMountsFor = [ "/archive" ];
  };
}
