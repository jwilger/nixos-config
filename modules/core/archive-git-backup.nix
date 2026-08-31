{ pkgs, ... }:
let
  source = "/home/jwilger/projects";
  target = "/archive/git-mirrors/jwilger/projects";
in
{
  # Project working trees are intentionally excluded from the daily home
  # snapshot. Keep one current, Git-aware copy of their committed history on
  # the archive pool instead. Bare mirrors contain all current local refs, but
  # never uncommitted edits or generated working-tree files.
  systemd.services.archive-project-git-mirrors = {
    description = "Archive committed Git history from ~/projects";
    after = [
      "archive.mount"
      "home.mount"
    ];
    requires = [
      "archive.mount"
      "home.mount"
    ];
    path = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.git
    ];
    unitConfig.RequiresMountsFor = [
      source
      target
    ];
    serviceConfig = {
      PrivateTmp = true;
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      ReadWritePaths = [ "/archive" ];
      Type = "oneshot";
      UMask = "0077";
    };
    script = ''
      set -euo pipefail

      install -d -m 0700 ${target}
      repository_list="$(mktemp)"
      trap 'rm -f "$repository_list"' EXIT

      ${pkgs.findutils}/bin/find ${source} \
        \( -type d \( \
          -name .claude -o \
          -name .codex -o \
          -name .dependencies -o \
          -name .worktrees -o \
          -name _build -o \
          -name deps -o \
          -name node_modules \
        \) -prune \) -o \
        \( -type d -name .git -print0 \) > "$repository_list"

      failures=0
      while IFS= read -r -d $'\0' git_directory; do
        repository="''${git_directory%/.git}"
        relative="''${repository#${source}/}"
        mirror=${target}/"$relative".git

        if ! install -d -m 0700 "$(dirname "$mirror")"; then
          echo "Cannot create archive directory for $repository" >&2
          failures=1
          continue
        fi

        if [ -d "$mirror" ]; then
          if ! ${pkgs.git}/bin/git -C "$mirror" remote set-url origin "$repository" \
            || ! ${pkgs.git}/bin/git -C "$mirror" remote update --prune; then
            echo "Cannot update Git mirror for $repository" >&2
            failures=1
            continue
          fi
        elif ! ${pkgs.git}/bin/git clone --mirror --no-local "$repository" "$mirror"; then
          echo "Cannot create Git mirror for $repository" >&2
          failures=1
          continue
        fi

        if ! ${pkgs.git}/bin/git -C "$mirror" fsck --full --no-dangling; then
          echo "Git mirror verification failed for $repository" >&2
          failures=1
        fi
      done < "$repository_list"

      exit "$failures"
    '';
  };

  systemd.timers.archive-project-git-mirrors = {
    description = "Daily Git archive mirror refresh";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:30:00";
      Persistent = true;
    };
  };
}
