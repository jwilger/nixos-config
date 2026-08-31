{ lib, pkgs, ... }:
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

        # Keep only the newest source snapshot on the performance pool.
        # The archive target carries the actual recovery history; retaining
        # additional source snapshots would pin deleted development data.
        snapshot_preserve_min = "latest";
        target_preserve_min = "2d";

        # Retention ladder: 14 dailies, 8 weeklies, 12 monthlies on the
        # /archive target — that's where the real backup history lives.
        # The /home source keeps no retention ladder beyond its latest
        # snapshot. History stays safe on /archive.
        snapshot_preserve = "no";
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
  #
  # The `v` rules create nested btrfs subvolumes for regenerable data
  # we deliberately keep OUT of the snapshots: a btrfs snapshot does not
  # recurse into child subvolumes, so anything living under one of these
  # is excluded from the daily backup to /archive. ~/.cache is XDG cache
  # data; ~/.build holds the retired shared Cargo target until its cleanup
  # timer removes it. Workspace-local Rust targets live under the projects
  # subvolume. tmpfiles only creates a subvolume when the path is missing;
  # existing ones are left as-is.
  systemd.tmpfiles.rules = [
    "d /home/.snapshots 0700 root root -"
    "v /home/jwilger/.cache 0755 jwilger jwilger -"
    "v /home/jwilger/.build 0755 jwilger jwilger -"
    "v /home/jwilger/projects 0755 jwilger jwilger -"
    "v /home/jwilger/.local/share/containers 0755 jwilger jwilger -"
    "v /home/jwilger/.npm 0755 jwilger jwilger -"
    "v /home/jwilger/.m2/repository 0755 jwilger jwilger -"
    "v /home/jwilger/.gradle/caches 0755 jwilger jwilger -"
    "v /home/jwilger/.gradle/daemon 0755 jwilger jwilger -"
    "v /home/jwilger/.cargo/registry 0755 jwilger jwilger -"
    "v /home/jwilger/.cargo/git 0755 jwilger jwilger -"
    "v /home/jwilger/.cargo/advisory-db 0755 jwilger jwilger -"
    "v /home/jwilger/.cargo/advisory-dbs 0755 jwilger jwilger -"
    "v /home/jwilger/.rustup/toolchains 0755 jwilger jwilger -"
    "v /home/jwilger/go/pkg 0755 jwilger jwilger -"
    "v /home/jwilger/.local/share/pnpm/store 0755 jwilger jwilger -"
    "v /home/jwilger/.local/share/uv/python 0755 jwilger jwilger -"
    "v /home/jwilger/.local/share/uv/tools 0755 jwilger jwilger -"
  ];

  # This service is deliberately not enabled by a target: it moves project
  # data and discards disposable rootless-container and package-cache state.
  # Run it once during a maintenance window, after closing project tools:
  #   sudo systemctl start home-development-state-migration.service
  systemd.services.home-development-state-migration = {
    description = "Move development state out of home snapshots";
    after = [ "home.mount" ];
    requires = [ "home.mount" ];
    path = [
      pkgs.btrfs-progs
      pkgs.coreutils
      pkgs.podman
      pkgs.util-linux
    ];
    unitConfig = {
      ConditionPathExists = "!/var/lib/home-development-state-migration.done";
      RequiresMountsFor = [ "/home" ];
    };
    serviceConfig = {
      RemainAfterExit = true;
      Type = "oneshot";
      UMask = "0077";
    };
    script = ''
      set -euo pipefail

      owner=jwilger
      projects=/home/$owner/projects
      stage=/home/$owner/.projects-subvolume-migration
      previous=/home/$owner/.projects-pre-subvolume

      is_subvolume() {
        btrfs subvolume show "$1" >/dev/null 2>&1
      }

      recreate_disposable_subvolume() {
        path="$1"
        if is_subvolume "$path"; then
          return
        fi

        rm -rf "$path"
        parent="$(dirname "$path")"
        install -d -m 0755 "$parent"
        chown $owner:$owner "$parent"
        btrfs subvolume create "$path"
        chown $owner:$owner "$path"
      }

      if ! is_subvolume "$projects"; then
        if [ -e "$stage" ] || [ -e "$previous" ]; then
          echo "Project migration staging path already exists; refusing to overwrite it" >&2
          exit 1
        fi

        btrfs subvolume create "$stage"
        chown $owner:$owner "$stage"
        cp --archive --reflink=auto "$projects/." "$stage/"

        mv "$projects" "$previous"
        if ! mv "$stage" "$projects"; then
          mv "$previous" "$projects"
          exit 1
        fi
        rm -rf "$previous"
      fi

      # Rootless Podman storage, including development database volumes, is
      # disposable. Refuse to proceed unless the user's runtime is available
      # so Podman can tear down its own state before the storage is recreated.
      containers=/home/$owner/.local/share/containers
      if ! is_subvolume "$containers"; then
        if [ ! -d /run/user/1000 ]; then
          echo "The jwilger user runtime is unavailable; log in before migrating Podman storage" >&2
          exit 1
        fi
        runuser -u $owner -- env XDG_RUNTIME_DIR=/run/user/1000 podman system reset --force
        recreate_disposable_subvolume "$containers"
      fi

      for path in \
        /home/$owner/.npm \
        /home/$owner/.m2/repository \
        /home/$owner/.gradle/caches \
        /home/$owner/.gradle/daemon \
        /home/$owner/.cargo/registry \
        /home/$owner/.cargo/git \
        /home/$owner/.cargo/advisory-db \
        /home/$owner/.cargo/advisory-dbs \
        /home/$owner/.rustup/toolchains \
        /home/$owner/go/pkg \
        /home/$owner/.local/share/pnpm/store \
        /home/$owner/.local/share/uv/python \
        /home/$owner/.local/share/uv/tools; do
        recreate_disposable_subvolume "$path"
      done

      install -d -m 0700 /var/lib
      date +%s > /var/lib/home-development-state-migration.done
    '';
  };

  # Return the project subvolume to the user's home after removing the
  # dedicated Codex account. Run once after a rebuild, with project tools
  # closed:
  #   sudo systemctl start restore-projects-home-location.service
  systemd.services.restore-projects-home-location = {
    description = "Move the project subvolume back into the user home";
    after = [ "home.mount" ];
    requires = [ "home.mount" ];
    path = [
      pkgs.acl
      pkgs.btrfs-progs
      pkgs.coreutils
      pkgs.findutils
    ];
    unitConfig.RequiresMountsFor = [ "/home" ];
    serviceConfig = {
      Type = "oneshot";
      UMask = "0022";
    };
    script = ''
      set -euo pipefail

      source=/home/projects
      target=/home/jwilger/projects

      if [ -L "$target" ]; then
        if [ "$(readlink --canonicalize "$target")" != "$source" ]; then
          echo "$target is a symlink to another location" >&2
          exit 1
        fi
      elif btrfs subvolume show "$target" >/dev/null 2>&1; then
        if [ ! -e "$source" ]; then
          exit 0
        fi
        echo "$target is already a Btrfs subvolume while $source still exists" >&2
        exit 1
      elif [ -e "$target" ]; then
        echo "$target exists and is not the expected compatibility symlink" >&2
        exit 1
      fi

      if ! btrfs subvolume show "$source" >/dev/null 2>&1; then
        echo "$source is not an existing Btrfs subvolume" >&2
        exit 1
      fi

      if [ -L "$target" ]; then
        unlink "$target"
      fi

      codex_gid="$(stat --format=%g "$source")"
      mv "$source" "$target"

      while IFS= read -r -d $'\0' path; do
        setfacl --remove "group:$codex_gid" "$path" 2>/dev/null || true
      done < <(find "$target" -xdev \( -type d -o -type f \) -print0)
      find "$target" -xdev -type d -exec setfacl --remove-default {} +
      find "$target" -xdev \( -type d -o -type f \) -exec chgrp jwilger {} +
      find "$target" -xdev -type d -exec chmod g-s {} +
      chmod 0755 "$target"
    '';
  };

  # This is the explicit final step of the one-time migration. It removes only
  # pre-migration source snapshots after btrbk has sent a newer, read-only
  # snapshot to /archive. The archive copy is verified before any local
  # snapshot is deleted.
  systemd.services.home-post-migration-snapshot-prune = {
    description = "Prune pre-migration home snapshots after archive verification";
    wantedBy = [ "btrbk-gregor.service" ];
    after = [
      "archive.mount"
      "home.mount"
      "btrbk-gregor.service"
    ];
    requires = [
      "archive.mount"
      "home.mount"
    ];
    path = [
      pkgs.btrfs-progs
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnused
    ];
    unitConfig = {
      ConditionPathExists = "/var/lib/home-development-state-migration.done";
      RequiresMountsFor = [
        "/archive"
        "/home"
      ];
    };
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
    };
    script = ''
      set -euo pipefail

      marker=/var/lib/home-development-state-migration.done
      snapshots=/home/.snapshots
      archive_snapshots=/archive/snapshots/home
      migration_epoch="$(cat "$marker")"
      latest="$(${pkgs.findutils}/bin/find "$snapshots" \
        -mindepth 1 -maxdepth 1 -type d -name 'home.*' -printf '%f\n' \
        | ${pkgs.coreutils}/bin/sort | ${pkgs.coreutils}/bin/tail -n 1)"

      if [ -z "$latest" ]; then
        echo "No local home snapshot exists" >&2
        exit 1
      fi

      stamp="''${latest#home.}"
      snapshot_epoch="$(${pkgs.coreutils}/bin/date \
        --date="''${stamp:0:4}-''${stamp:4:2}-''${stamp:6:2} ''${stamp:9:2}:''${stamp:11:2}" \
        +%s)"
      if [ "$snapshot_epoch" -le "$migration_epoch" ]; then
        echo "Newest local snapshot predates the migration; run btrbk first" >&2
        exit 1
      fi

      archive_snapshot="$archive_snapshots/$latest"
      if [ ! -d "$archive_snapshot" ] \
        || [ "$(btrfs property get -ts "$archive_snapshot" ro)" != "ro=true" ]; then
        echo "Newest local snapshot is not a verified read-only archive replica" >&2
        exit 1
      fi

      local_uuid="$(btrfs subvolume show "$snapshots/$latest" \
        | sed -n 's/^[[:space:]]*UUID:[[:space:]]*//p')"
      received_uuid="$(btrfs subvolume show "$archive_snapshot" \
        | sed -n 's/^[[:space:]]*Received UUID:[[:space:]]*//p')"
      if [ -z "$local_uuid" ] \
        || [ -z "$received_uuid" ] \
        || [ "$received_uuid" = "-" ] \
        || [ "$received_uuid" != "$local_uuid" ]; then
        echo "Newest archive snapshot is not a verified replica of the local snapshot" >&2
        exit 1
      fi

      while IFS= read -r -d $'\0' snapshot; do
        [ "$snapshot" = "$snapshots/$latest" ] || btrfs subvolume delete "$snapshot"
      done < <(${pkgs.findutils}/bin/find "$snapshots" \
        -mindepth 1 -maxdepth 1 -type d -name 'home.*' -print0)
    '';
  };

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
