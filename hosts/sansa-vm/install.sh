#!/usr/bin/env bash
set -euo pipefail

ROOT_DEV="${ROOT_DEV:-/dev/vda2}"
BOOT_DEV="${BOOT_DEV:-/dev/vda1}"
FLAKE_REF="${FLAKE_REF:-github:jwilger/nixos-config#sansa-vm}"

QUICKSHELL_SUBSTITUTER="https://quickshell.cachix.org"
QUICKSHELL_KEY="quickshell.cachix.org-1:OJszzthtpAEkFkBD35pIqjL8NlZ1y/I1O5wP9XFml2s="

mountpoint -q /mnt || sudo mount "$ROOT_DEV" /mnt
sudo mkdir -p /mnt/boot
mountpoint -q /mnt/boot || sudo mount "$BOOT_DEV" /mnt/boot

sudo nixos-install \
  --flake "$FLAKE_REF" \
  --option extra-substituters "$QUICKSHELL_SUBSTITUTER" \
  --option extra-trusted-public-keys "$QUICKSHELL_KEY"
