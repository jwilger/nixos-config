{ lib, ... }:
{
  # Daily btrbk run takes read-only snapshots of /home and replicates them
  # incrementally to /archive (the HDD pool). /home is the only thing
  # backed up here — /nix/store is regenerable from the flake, /var/log
  # has its own journal-archive timer (see system.nix), /etc/nixos is in
  # git, /var/lib/docker is on its own filesystem so it isn't part of any
  # snapshot of /home.
  #
  # Manual restore reference:
  #   ls /archive/snapshots/home/                   # list available snapshots
  #   sudo btrfs send /archive/snapshots/home/<ts> | sudo btrfs receive /tmp/restore
  #   # …or just `cp` files out of the snapshot tree directly (it mounts r/o).
  services.btrbk = {
    instances.gregor = {
      # 03:30 local — after the journal-archive timer (00:00 + up to 30m)
      # has settled, well clear of nix-gc.
      onCalendar = "*-*-* 03:30:00";
      settings = {
        # 2026-04-29T03:30 style timestamps — sortable, human-readable.
        timestamp_format = "long";

        # Always keep the two most recent snapshots regardless of any
        # ladder rule, so an immediate "oh no I rm'd that" is always
        # recoverable.
        snapshot_preserve_min = "2d";
        target_preserve_min = "2d";

        # Retention ladder: 14 dailies, 8 weeklies, 12 monthlies.
        # Same ladder on both source and target.
        snapshot_preserve = "14d 8w 12m";
        target_preserve = "14d 8w 12m";

        # /archive is already mounted with compress=zstd:15, so don't
        # also compress the send stream — that just burns CPU twice for
        # no gain.
        stream_compress = "no";

        # Source: /home (the toplevel of the home-pool). Snapshots live
        # in /home/.snapshots/<timestamp>/ until pruned. Target: the
        # /archive/snapshots/home directory pre-created by tmpfiles in
        # system.nix.
        volume."/home" = {
          snapshot_dir = ".snapshots";
          subvolume = ".";
          target = "/archive/snapshots/home";
        };
      };
    };
  };

  # btrbk's source snapshot directory (/home/.snapshots) needs to exist
  # before the first run; tmpfiles handles it. Mode 0700 because these
  # snapshots are full read-only views of /home — restrict to root.
  systemd.tmpfiles.rules = [
    "d /home/.snapshots 0700 root root -"
  ];

  # Make the backup yield to interactive work. `idle` I/O class only
  # gets disk time when nothing else wants it; `Nice=19` does the same
  # for CPU. The send/receive will take longer in wall-clock terms but
  # won't compete with the user's foreground work — important both for
  # the long initial run and for ongoing nightly incrementals.
  # mkForce because the upstream btrbk module sets a default
  # IOSchedulingClass of "best-effort"; we want to override, not merge.
  systemd.services."btrbk-gregor".serviceConfig = {
    IOSchedulingClass = lib.mkForce "idle";
    Nice = lib.mkForce 19;
  };
}
