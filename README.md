<h1 align="center">
   <img src="./.github/assets/logo/nixos-logo.png  " width="100px" />
   <br>
      jwilger's Flakes
   <br>
      <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="600px" /> <br>
</h1>

> *"Though this be madness, yet there is method in't."*
> — Hamlet, Act 2, Scene 2

*Credit to [Frost-Phoenix](https://github.com/Frost-Phoenix/nixos-config) for a great starting point from which to create this flake for my Nix machines.*

## Development containers

Gregor uses rootless Podman rather than a rootful Docker daemon. Existing
Compose projects can use `docker compose up` through the compatibility command;
`podman compose up` is the explicit equivalent. Containers inherit only the
login user's filesystem access, so root-only backup snapshots are unavailable
to development workloads.

## Backups

Gregor retains daily Btrfs snapshots on the root-only `/archive` filesystem and
sends an encrypted restic copy of the newest replicated home snapshot to the
private `gregor-restic-backups` Backblaze B2 bucket. The B2 and repository
credentials are SOPS-encrypted; inspect backups with `sudo restic-backblaze
snapshots` and restore into a temporary directory with `sudo restic-backblaze
restore latest --target /path/to/restore`.
